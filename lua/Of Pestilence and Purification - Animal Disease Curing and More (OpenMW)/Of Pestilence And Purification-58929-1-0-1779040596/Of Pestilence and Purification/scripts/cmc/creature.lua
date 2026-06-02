local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local AI = require('openmw.interfaces').AI
local time = require('openmw_aux.time')
local cfg = require('scripts.cmc.config')

local friendly = false
local ally = false
local allyOwner = nil
local allyExpiresAt = nil
local allyOwnerRequestAt = -100000
local tick = 0
local EFFECT_SCAN_INTERVAL = tonumber(cfg.thresholds.effectScanInterval or 0.50) or 0.50
local SPECIES_FRIENDSHIP_POLL_INTERVAL = tonumber(cfg.thresholds.speciesFriendshipPollInterval or 10.0) or 10.0

local effectScanTimer = math.random() * EFFECT_SCAN_INTERVAL
local friendlinessCheckTimer = 0.50 + math.random() * math.min(2.0, SPECIES_FRIENDSHIP_POLL_INTERVAL)
local processedEffectKeys = {}
local pendingActiveSpellRemovals = {}

local idleTable = {
    idle2 = 60,
    idle3 = 50,
    idle4 = 40,
    idle5 = 30,
    idle6 = 20,
    idle7 = 10,
    idle8 = 0,
    idle9 = 25,
}


local function requestAllyOwner()
    local now = core.getSimulationTime()
    if now - allyOwnerRequestAt < 1.0 then return end
    allyOwnerRequestAt = now
    core.sendGlobalEvent('cmcRequestAllyOwner', { target = self.object })
end

local function ensureAllyOwner()
    if allyOwner and allyOwner:isValid() then return allyOwner end
    requestAllyOwner()
    return nil
end

local function randomAllyDuration()
    local minHours = tonumber(cfg.thresholds.allyFollowMinHours or 2) or 2
    local maxHours = tonumber(cfg.thresholds.allyFollowMaxHours or minHours) or minHours
    if maxHours < minHours then maxHours = minHours end

    local minSeconds = math.max(1, math.floor(minHours * time.hour))
    local maxSeconds = math.max(minSeconds, math.floor(maxHours * time.hour))
    return math.random(minSeconds, maxSeconds)
end

local function remainingAllyDuration()
    if not allyExpiresAt then return math.max(1, math.floor(24 * time.hour)) end
    return math.max(1, math.floor(allyExpiresAt - core.getSimulationTime()))
end

local function startPeacefulWander()
    pcall(function()
        AI.removePackages('Combat')
        AI.startPackage({
            type = 'Wander',
            distance = 512,
            duration = 24 * time.hour,
            idle = idleTable,
            isRepeat = true,
        })
    end)
end


local function startAllyFollow()
    if not ally then return end
    local owner = ensureAllyOwner()
    if not owner or not owner:isValid() then return end
    pcall(function()
        local pkg = AI.getActivePackage()
        if pkg and pkg.type == 'Combat' then return end
        AI.startPackage({
            type = 'Follow',
            target = owner,
            distance = 192,
            duration = remainingAllyDuration(),
            isRepeat = false,
        })
    end)
end

local function applyAllyBuff()
    pcall(function()
        local health = types.Actor.stats.dynamic.health(self)
        health.current = math.min(health.current + 25, health.current + 25)
    end)
    pcall(function()
        local fight = types.Actor.stats.ai.fight(self)
        fight.base = math.max(fight.base, 65)
    end)
end

local function enforceFriendly()
    if not friendly or not self:isValid() then return end

    pcall(function()
        local fight = types.Actor.stats.ai.fight(self)
        if ally then
            fight.base = math.max(fight.base, 65)
        else
            fight.base = 0
            if fight.modifier > 0 then fight.modifier = 0 end
        end

        local alarm = types.Actor.stats.ai.alarm(self)
        alarm.base = 0
        if alarm.modifier > 0 then alarm.modifier = 0 end
    end)

    pcall(function()
        local pkg = AI.getActivePackage()
        if pkg and pkg.type == 'Combat' and not ally then
            AI.removePackages('Combat')
            startPeacefulWander()
        elseif ally and (not pkg or (pkg.type ~= 'Combat' and pkg.type ~= 'Follow')) then
            startAllyFollow()
        end
    end)

    if not ally then
        -- A short visible calm effect helps break existing combat immediately.
        pcall(function()
            if not types.Actor.activeSpells(self):isSpellActive('calm creature') then
                types.Actor.activeSpells(self):add({
                    id = 'calm creature',
                    effects = { 0 },
                    stackable = false,
                    quiet = true,
                })
            end
        end)
    end
end

local function getCaster(activeSpell)
    if activeSpell and activeSpell.caster and activeSpell.caster:isValid() then
        return activeSpell.caster
    end
    return nil
end

local function effectMagnitude(activeSpell, eff)
    if eff and eff.magnitude then return eff.magnitude end
    if eff and eff.magnitudeMax then return eff.magnitudeMax end
    if activeSpell and activeSpell.id then
        local spellId = cfg.lowerId(activeSpell.id)
        local amount = cfg.resistScaledDamage and cfg.resistScaledDamage[spellId]
        if amount then return amount end
        amount = cfg.antiBlightDamage and cfg.antiBlightDamage[spellId]
        if amount then return amount end
    end
    return 25
end

local function queueActiveSpellRemoval(activeSpell)
    local asId = activeSpell and activeSpell.activeSpellId
    if asId ~= nil then pendingActiveSpellRemovals[tostring(asId)] = asId end
end

local function scanMagicEffects()
    if types.Actor.isDead(self) then return end

    local activeSpells = types.Actor.activeSpells(self)
    local seen = {}

    for _, activeSpell in pairs(activeSpells) do
        local spellId = cfg.lowerId(activeSpell and activeSpell.id)
        local spellKey = tostring(spellId or activeSpell.activeSpellId or '')
        local handledSpread = {}
        local handledDamage = {}
        local handledAnti = false
        local handledCure = {}

        if activeSpell.effects then
            for _, eff in pairs(activeSpell.effects) do
                local effectId = cfg.lowerId(eff.id)
                local key = spellKey .. ':effect:' .. tostring(effectId or '')
                seen[key] = true

                if not processedEffectKeys[key] then
                    local spreadKind = cfg.isSpreadEffect(effectId)
                    if spreadKind then
                        processedEffectKeys[key] = true
                        handledSpread[spreadKind] = true
                        queueActiveSpellRemoval(activeSpell)
                        core.sendGlobalEvent('cmcApplySpread', {
                            actor = getCaster(activeSpell),
                            target = self.object,
                            kind = spreadKind,
                            spellId = spellId,
                        })
                    else
                        local scaledKind = cfg.isResistScaledDamageEffect(effectId)
                        if scaledKind then
                            processedEffectKeys[key] = true
                            handledDamage[scaledKind] = true
                            queueActiveSpellRemoval(activeSpell)
                            core.sendGlobalEvent('cmcApplyResistScaledDamage', {
                                actor = getCaster(activeSpell),
                                target = self.object,
                                kind = scaledKind,
                                spellId = spellId,
                                magnitude = effectMagnitude(activeSpell, eff),
                            })
                        elseif cfg.isAntiBlightEffect(effectId) then
                            processedEffectKeys[key] = true
                            handledAnti = true
                            queueActiveSpellRemoval(activeSpell)
                            core.sendGlobalEvent('cmcApplyAntiBlightDamage', {
                                actor = getCaster(activeSpell),
                                target = self.object,
                                spellId = spellId,
                                magnitude = effectMagnitude(activeSpell, eff),
                            })
                        else
                            local cureKind = cfg.isCureEffect(effectId)
                            if cureKind then
                                processedEffectKeys[key] = true
                                handledCure[cureKind] = true
                                queueActiveSpellRemoval(activeSpell)
                                core.sendGlobalEvent('cmcApplyCure', {
                                    actor = getCaster(activeSpell),
                                    target = self.object,
                                    kind = cureKind,
                                })
                            end
                        end
                    end
                else
                    local spreadKind = cfg.isSpreadEffect(effectId)
                    if spreadKind then handledSpread[spreadKind] = true end
                    local scaledKind = cfg.isResistScaledDamageEffect(effectId)
                    if scaledKind then handledDamage[scaledKind] = true end
                    if cfg.isAntiBlightEffect(effectId) then handledAnti = true end
                    local cureKind = cfg.isCureEffect(effectId)
                    if cureKind then handledCure[cureKind] = true end
                end
            end
        end

        -- Spell-level fallback for OpenMW builds/load orders that expose cloned
        -- effects under generic engine ids. Process spread and damage separately
        -- so compound AoE spells can do both parts from one cast.
        local spellSpreadKind = cfg.isSpreadSpell(spellId)
        if spellSpreadKind and not handledSpread[spellSpreadKind] then
            local key = spellKey .. ':spellspread:' .. tostring(spellSpreadKind)
            seen[key] = true
            if not processedEffectKeys[key] then
                processedEffectKeys[key] = true
                queueActiveSpellRemoval(activeSpell)
                core.sendGlobalEvent('cmcApplySpread', {
                    actor = getCaster(activeSpell),
                    target = self.object,
                    kind = spellSpreadKind,
                    spellId = spellId,
                })
            end
        end

        local spellDamageKind = cfg.isResistScaledDamageSpell(spellId)
        if spellDamageKind and not handledDamage[spellDamageKind] then
            local key = spellKey .. ':spelldamage:' .. tostring(spellDamageKind)
            seen[key] = true
            if not processedEffectKeys[key] then
                processedEffectKeys[key] = true
                queueActiveSpellRemoval(activeSpell)
                core.sendGlobalEvent('cmcApplyResistScaledDamage', {
                    actor = getCaster(activeSpell),
                    target = self.object,
                    kind = spellDamageKind,
                    spellId = spellId,
                    magnitude = effectMagnitude(activeSpell, nil),
                })
            end
        end

        if cfg.isAntiBlightSpell(spellId) and not handledAnti then
            local key = spellKey .. ':spellanti:antiBlight'
            seen[key] = true
            if not processedEffectKeys[key] then
                processedEffectKeys[key] = true
                queueActiveSpellRemoval(activeSpell)
                core.sendGlobalEvent('cmcApplyAntiBlightDamage', {
                    actor = getCaster(activeSpell),
                    target = self.object,
                    spellId = spellId,
                    magnitude = effectMagnitude(activeSpell, nil),
                })
            end
        end

        -- Spell-level fallback for cure spells. Some OpenMW load orders expose
        -- custom Cure Common/Blight carriers through their native template effect
        -- ids, so the effect-id pass may not see cmc_purify_* directly.
        -- Purify Beast intentionally carries both cure kinds; handling both here
        -- lets a common-diseased or blighted animal resolve correctly.
        local cureKinds = cfg.cureKindsForSpell(spellId)
        if cureKinds then
            for _, cureKind in ipairs(cureKinds) do
                if not handledCure[cureKind] then
                    local key = spellKey .. ':spellcure:' .. tostring(cureKind)
                    seen[key] = true
                    if not processedEffectKeys[key] then
                        processedEffectKeys[key] = true
                        queueActiveSpellRemoval(activeSpell)
                        core.sendGlobalEvent('cmcApplyCure', {
                            actor = getCaster(activeSpell),
                            target = self.object,
                            kind = cureKind,
                            spellId = spellId,
                        })
                    end
                end
            end
        end
    end

    if next(pendingActiveSpellRemovals) then
        for _, asId in pairs(pendingActiveSpellRemovals) do
            pcall(function() activeSpells:remove(asId) end)
        end
        pendingActiveSpellRemovals = {}
    end

    -- Clear keys after an active spell disappears so future casts can be handled.
    for key in pairs(processedEffectKeys) do
        if not seen[key] then processedEffectKeys[key] = nil end
    end
end

local function requestSpeciesFriendliness()
    if friendly or types.Actor.isDead(self) then return end
    core.sendGlobalEvent('cmcRequestFriendlySpecies', { target = self.object })
end

local function takeBlightDamage(data)
    if not data then return end
    local amount = tonumber(data.amount or 0) or 0
    if amount <= 0 then return end
    pcall(function()
        local health = types.Actor.stats.dynamic.health(self)
        health.current = math.max(0, health.current - amount)
    end)
end

local function expireAllyIfNeeded()
    if not ally or not allyExpiresAt then return false end
    if core.getSimulationTime() < allyExpiresAt then return false end

    ally = false
    allyOwner = nil
    allyExpiresAt = nil
    pcall(function() AI.removePackages('Follow') end)
    enforceFriendly()
    startPeacefulWander()
    return true
end

return {
    eventHandlers = {
        cmcMakeFriendly = function()
            friendly = true
            ally = false
            allyOwner = nil
            allyExpiresAt = nil
            pcall(function() AI.removePackages('Follow') end)
            enforceFriendly()
            startPeacefulWander()
        end,
        cmcMakeAlly = function(data)
            friendly = true
            ally = true
            allyOwner = data and data.owner or nil
            allyExpiresAt = data and data.untilTime or (core.getSimulationTime() + randomAllyDuration())
            if not allyOwner or not allyOwner:isValid() then requestAllyOwner() end
            applyAllyBuff()
            enforceFriendly()
            startAllyFollow()
        end,
        cmcSetAllyOwner = function(data)
            if data and data.owner and data.owner:isValid() then
                allyOwner = data.owner
                if ally then startAllyFollow() end
            end
        end,
        cmcTakeBlightDamage = takeBlightDamage,
    },
    engineHandlers = {
        onUpdate = function(dt)
            effectScanTimer = effectScanTimer + dt
            if effectScanTimer >= EFFECT_SCAN_INTERVAL then
                effectScanTimer = 0
                scanMagicEffects()
            end

            if not friendly then
                friendlinessCheckTimer = friendlinessCheckTimer + dt
                if friendlinessCheckTimer >= SPECIES_FRIENDSHIP_POLL_INTERVAL then
                    friendlinessCheckTimer = 0
                    requestSpeciesFriendliness()
                end
            end

            if not friendly then return end
            expireAllyIfNeeded()
            tick = tick + dt
            if tick >= 1 then
                tick = 0
                enforceFriendly()
            end
        end,
        onSave = function()
            return { friendly = friendly, ally = ally, allyExpiresAt = allyExpiresAt }
        end,
        onLoad = function(saved)
            friendly = saved and saved.friendly or false
            ally = saved and saved.ally or false
            allyExpiresAt = saved and saved.allyExpiresAt or nil
            if ally and allyExpiresAt and core.getSimulationTime() >= allyExpiresAt then
                ally = false
                allyExpiresAt = nil
            end
            if ally and (not allyOwner or not allyOwner:isValid()) then requestAllyOwner() end
            processedEffectKeys = {}
            pendingActiveSpellRemovals = {}
            allyOwnerRequestAt = -100000
            effectScanTimer = math.random() * EFFECT_SCAN_INTERVAL
            friendlinessCheckTimer = 0.50 + math.random() * math.min(2.0, SPECIES_FRIENDSHIP_POLL_INTERVAL)
            if friendly then
                enforceFriendly()
                if ally then startAllyFollow() else startPeacefulWander() end
            else
                requestSpeciesFriendliness()
            end
        end,
        onInit = function()
            requestSpeciesFriendliness()
            if ally and (not allyOwner or not allyOwner:isValid()) then requestAllyOwner() end
        end,
    },
}
