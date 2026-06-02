local core = require('openmw.core')
local util = require('openmw.util')
local world = require('openmw.world')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local common = require('scripts.wispspell.common')

local state = {
    wisps = {},
    -- [castableBaseSpellId] = { payloadSpellIds = { ... }, sourceName = string }
    payloads = {},
    removedSpells = {},
    processedSpells = {},
    -- Short-lived actor combat monitor caches. Keys use object ids to match the
    -- rest of this mod's object comparison style.
    combatTargets = {},
    playerAllies = {},
}

local function valid(object)
    return common.isValid(object)
end

local function removeObject(object)
    if not valid(object) then return end

    -- Some OpenMW object kinds report a zero count even though they are valid
    -- world references. Removing one explicit reference avoids the noisy
    -- "Can't remove 0 of 0 items" path; pcall keeps this idempotent.
    local ok = pcall(function() object:remove(1) end)
    if not ok then pcall(function() object:remove() end) end
end

local function pruneWisps()
    for i = #state.wisps, 1, -1 do
        if not valid(state.wisps[i]) then
            table.remove(state.wisps, i)
        end
    end
end

local function pruneCombatCache()
    state.combatTargets = state.combatTargets or {}
    state.playerAllies = state.playerAllies or {}
    local now = core.getSimulationTime()

    for key, entry in pairs(state.combatTargets) do
        if not entry or not valid(entry.actor) or not valid(entry.target) or (tonumber(entry.expires) or 0) <= now then
            state.combatTargets[key] = nil
        end
    end

    for key, entry in pairs(state.playerAllies) do
        if not entry or not valid(entry.actor) or (tonumber(entry.expires) or 0) <= now then
            state.playerAllies[key] = nil
        end
    end
end

local function updateHostility(data)
    if not data or not valid(data.actor) then return end
    state.combatTargets = state.combatTargets or {}
    state.playerAllies = state.playerAllies or {}

    local key = data.actor.id
    local expires = core.getSimulationTime() + common.hostilityCacheDuration

    if data.isPlayerAlly then
        state.playerAllies[key] = {
            actor = data.actor,
            expires = expires,
        }
    else
        state.playerAllies[key] = nil
    end

    if valid(data.combatTarget) then
        state.combatTargets[key] = {
            actor = data.actor,
            target = data.combatTarget,
            expires = expires,
        }
    else
        state.combatTargets[key] = nil
    end
end

local function playerObject()
    for _, player in ipairs(world.players or {}) do
        if valid(player) then return player end
    end
    return nil
end

local function dispositionToPlayer(actor)
    local player = playerObject()
    if not valid(player) or not valid(actor) or not types.NPC.objectIsInstance(actor) then return nil end

    local ok, value = pcall(types.NPC.getDisposition, actor, player)
    return ok and tonumber(value) or nil
end

local function isLikelyPlayerAllyByDisposition(actor)
    local d = dispositionToPlayer(actor)
    return d ~= nil and d >= common.friendlyNpcDispositionCutoff
end

local function isPlayerSideTarget(target, now)
    if not valid(target) then return false end
    if types.Player.objectIsInstance(target) then return true end

    local ally = state.playerAllies and state.playerAllies[target.id]
    if ally ~= nil and valid(ally.actor) and (tonumber(ally.expires) or 0) > now then
        return true
    end

    -- Some companion mods do not expose a normal Follow/Escort package.  As a
    -- fallback, treat high-disposition NPCs as player-side targets, so an enemy
    -- attacking such a follower can still be selected by the wisp.
    return isLikelyPlayerAllyByDisposition(target)
end

local function querySoulWispHostility(data)
    if not data or not valid(data.wisp) then return end

    pruneCombatCache()

    local now = core.getSimulationTime()
    local hostileActors = {}
    local playerAllies = {}

    for _, actor in ipairs(data.actors or {}) do
        if valid(actor) and isPlayerSideTarget(actor, now) then
            table.insert(playerAllies, actor)
        end

        local entry = valid(actor) and state.combatTargets[actor.id] or nil
        if entry and valid(entry.actor) and valid(entry.target)
            and (tonumber(entry.expires) or 0) > now
            and isPlayerSideTarget(entry.target, now)
        then
            table.insert(hostileActors, entry.actor)
        end
    end

    data.wisp:sendEvent('RT_SoulWispHostilityState', {
        wisp = data.wisp,
        actors = hostileActors,
        allies = playerAllies,
        cacheDuration = common.hostilityCacheDuration,
    })
end

local function createPayloadSpellRecord(effects, sourceName, suffix)
    local payload = {}
    for _, effect in ipairs(effects or {}) do
        local copied = common.asTargetEffect(effect)
        if copied then table.insert(payload, copied) end
    end
    if #payload == 0 then return nil end

    return world.createRecord(core.magic.spells.createRecordDraft({
        name = 'Soul Wisp Payload' .. tostring(suffix or '') .. ': ' .. tostring(sourceName or 'Spell'),
        type = core.magic.SPELL_TYPE.Spell,
        cost = 0,
        starterSpellFlag = false,
        isAutocalc = false,
        effects = payload,
    }))
end

local function createPayloadSpellIds(effects, sourceName)
    local ids = {}

    if common.splitPayloadProjectiles then
        for i, effect in ipairs(effects or {}) do
            local record = createPayloadSpellRecord({ effect }, sourceName, ' ' .. tostring(i))
            if record then table.insert(ids, record.id) end
        end
    else
        local record = createPayloadSpellRecord(effects, sourceName, '')
        if record then table.insert(ids, record.id) end
    end

    if #ids == 0 then return nil end
    return ids
end

local function normalisePayloadIds(value)
    if not value then return nil end
    if type(value) == 'string' then return { value } end
    if type(value) ~= 'table' then return nil end

    if value.payloadSpellIds then
        return normalisePayloadIds(value.payloadSpellIds)
    end
    if value.payloadSpellId then
        return normalisePayloadIds(value.payloadSpellId)
    end

    local ids = {}
    for _, id in ipairs(value) do
        if type(id) == 'string' then table.insert(ids, id) end
    end
    if #ids == 0 then return nil end
    return ids
end

local function splitSoulWispSpellRecord(spell)
    if not spell or not spell.effects then return nil end

    local baseEffects = {}
    local payloadEffects = {}
    local foundControl = false
    local controlEffect = nil

    for _, effect in ipairs(spell.effects) do
        local copied = common.copyEffect(effect)
        if copied then
            if foundControl then
                if common.lower(copied.id) ~= common.effectId then
                    table.insert(payloadEffects, copied)
                end
            else
                table.insert(baseEffects, copied)
                if common.lower(copied.id) == common.effectId then
                    foundControl = true
                    controlEffect = copied
                end
            end
        end
    end

    if not foundControl or #payloadEffects == 0 then return nil end
    return baseEffects, payloadEffects, controlEffect
end

local function processSpell(spell, target)
    if not spell or not spell.id or state.payloads[spell.id] or state.processedSpells[spell.id] then return false end
    state.processedSpells[spell.id] = true

    local baseEffects, payloadEffects = splitSoulWispSpellRecord(spell)
    if not baseEffects or not payloadEffects then return false end

    local payloadSpellIds = createPayloadSpellIds(payloadEffects, spell.name)
    if not payloadSpellIds then return false end

    local newBaseRecord = world.createRecord(core.magic.spells.createRecordDraft({
        template = spell,
        effects = baseEffects,
    }))

    state.payloads[newBaseRecord.id] = {
        payloadSpellIds = payloadSpellIds,
        sourceName = spell.name,
    }
    state.processedSpells[newBaseRecord.id] = true

    local targetSpells = target.type.spells(target)
    targetSpells:remove(spell)
    table.insert(state.removedSpells, spell.id)
    targetSpells:add(newBaseRecord)

    common.log('soulwisp', 'Split spell "' .. tostring(spell.name or spell.id) .. '" into base ' .. tostring(newBaseRecord.id) .. ' and ' .. tostring(#payloadSpellIds) .. ' payload record(s).')
    return true
end

local function sendPayloadState(target)
    if valid(target) then
        target:sendEvent('RT_SoulWispPayloadsUpdated', {
            payloads = state.payloads,
            removedSpells = state.removedSpells,
        })
    end
end

local function processSoulWispSpells(data)
    local target = data and data.target or world.getPlayer()
    if not valid(target) or not target.type or not target.type.spells then return end

    local changed = false
    for _, spell in ipairs(target.type.spells(target)) do
        if processSpell(spell, target) then
            changed = true
        end
    end

    -- Always sync, even if nothing changed; this repopulates the player script after load.
    sendPayloadState(target)
    return changed
end

local function createSoulWisp(data)
    if not data or not valid(data.caster) then return end

    local payloadSpellIds = normalisePayloadIds(data.payloadSpellIds or data.payloadSpellId)
    if not payloadSpellIds and data.payloadEffects then
        payloadSpellIds = createPayloadSpellIds(data.payloadEffects, data.sourceSpellName)
    end
    if not payloadSpellIds then return end

    local cell = data.caster.cell
    if not cell then return end

    local visual = world.createObject(common.visualRecordId, 1)
    visual:teleport(cell, (data.position or data.caster.position) + util.vector3(0, 0, common.visualZOffset))
    visual:setScale(1.0)
    visual:addScript(common.wispScript, {
        caster = data.caster,
        payloadSpellIds = payloadSpellIds,
        payloadSpellId = payloadSpellIds[1], -- compatibility with older saves/scripts
        sourceSpellName = data.sourceSpellName,
        duration = data.duration or common.defaultDuration,
        fadeOutTime = data.fadeOutTime or common.fadeOutTime,
        interval = data.interval or common.intervalFromMagnitude(data.magnitude),
        magnitude = data.magnitude or common.defaultMagnitude,
        projectileSpeed = common.projectileSpeedFromMagnitude(data.magnitude),
        targetRadius = data.targetRadius or common.defaultRadius,
    })

    table.insert(state.wisps, visual)
end

local function targetPoint(target)
    return target.position + util.vector3(0, 0, common.objectHeightOffset(target, 80))
end

local function launchOnePayloadSpell(spellId, data, startPos, direction)
    local spell = core.magic.spells.records[spellId]
    if not spell then return end

    -- attacker = data.caster or world.players[1]
    -- direction = direction:normalize()
    -- if data.targetMode == 'self' then
    --     common.log('data.targetMode = self works')
    --     attacker = data.wisp -- data.target
    --     direction = targetPoint(data.caster) - startPos
    -- end
    if I.MagExp and I.MagExp.launchSpell then
        I.MagExp.launchSpell({
            attacker = data.caster or world.players[1], -- data.caster or world.players[1],
            spellId = spellId,
            spellType = core.magic.RANGE.Target,
            startPos = startPos,
            direction = direction:normalize(), -- direction:normalize(),
            -- hitObject = data.target,
            isFree = false,
            speed = data.projectileSpeed or common.projectileSpeedFromMagnitude(data.magnitude),
            spawnOffset = 35,
            maxLifetime = 6,
        })
    else
        common.log('soulwisp', 'SpellFrameworkPlus interface I.MagExp is not available. Load SPELL_FRAMEWORK_PLUS.omwscripts before Soul Wisp.')
    end
end

local function launchPayload(data)
    if not data or not valid(data.wisp) or not valid(data.target) then return end

    local payloadSpellIds = normalisePayloadIds(data.payloadSpellIds or data.payloadSpellId)
    if not payloadSpellIds then return end

    local attacker = valid(data.caster) and data.caster or world.players[1]
    if not valid(attacker) then return end

    local startPos = data.startPos or (data.wisp.position + util.vector3(0, 0, 40))
    local direction = data.direction or (targetPoint(data.target) - startPos)
    if direction:length2() <= 0.0001 then return end

    for _, spellId in ipairs(payloadSpellIds) do
        launchOnePayloadSpell(spellId, data, startPos, direction)
    end
end

local function setSoulWispScale(data)
    if not data or not valid(data.wisp) then return end
    local scale = tonumber(data.scale)
    if not scale then return end
    scale = util.clamp(scale, 0, 1)
    pcall(function()
        data.wisp:setScale(scale)
    end)
end

local function removeSoulWisp(data)
    if data and data.wisp then removeObject(data.wisp) end
end

local function removeAllWisps()
    for _, wisp in ipairs(state.wisps) do removeObject(wisp) end
    state.wisps = {}
end

return {
    onLoad = function(save)
        state = save or state
        state.wisps = state.wisps or {}
        state.payloads = state.payloads or {}
        state.removedSpells = state.removedSpells or {}
        state.processedSpells = state.processedSpells or {}
        -- This is live combat state, not persistent save data.
        state.hostileToPlayer = {}
    end,
    onSave = function()
        pruneWisps()
        return {
            wisps = state.wisps,
            payloads = state.payloads,
            removedSpells = state.removedSpells,
            processedSpells = state.processedSpells,
        }
    end,
    onUpdate = function()
        pruneWisps()
        pruneHostilityCache()
    end,
    eventHandlers = {
        RT_CreateSoulWisp = createSoulWisp,
        RT_ProcessSoulWispSpells = processSoulWispSpells,
        RT_SoulWispPulse = launchPayload,
        RT_SoulWispHostilityUpdate = updateHostility,
        RT_QuerySoulWispHostility = querySoulWispHostility,
        RT_RemoveSoulWisp = removeSoulWisp,
        RT_RemoveAllSoulWisps = removeAllWisps,
        RT_SetSoulWispScale = setSoulWispScale,
    },
}
