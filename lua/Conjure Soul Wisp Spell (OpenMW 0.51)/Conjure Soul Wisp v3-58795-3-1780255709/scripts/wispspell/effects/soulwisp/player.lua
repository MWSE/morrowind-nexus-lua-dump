local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local common = require('scripts.wispspell.common')

local activeSpells = types.Actor.activeSpells(self)
local playerSpells = types.Player.spells(self)

local state = {
    handled = {},
    nextScan = 0,
    payloads = {},
    removedSpells = {},
}

local function ensureStarterSpell()
    if not playerSpells[common.spellId] then
        playerSpells:add(common.spellId)
    end
end

local function requestPayloadSplit()
    core.sendGlobalEvent('RT_ProcessSoulWispSpells', { target = self.object })
end

local function effectId(effect)
    return effect and (effect.id or (effect.effect and effect.effect.id))
end

local function isControlEffect(effect)
    return common.lower(effectId(effect)) == common.effectId
end

local function splitSpellEffects(record)
    if not record or not record.effects then return nil, {} end

    local control = nil
    local payload = {}
    local afterControl = false

    for _, effect in ipairs(record.effects) do
        if afterControl then
            local copied = common.copyEffect(effect)
            if copied and common.lower(copied.id) ~= common.effectId then
                table.insert(payload, copied)
            end
        elseif isControlEffect(effect) then
            control = common.copyEffect(effect)
            afterControl = true
        end
    end

    return control, payload
end

local function activeSpellControl(activeSpell)
    if not activeSpell or not activeSpell.effects then return nil end
    for _, effect in pairs(activeSpell.effects) do
        if isControlEffect(effect) then
            return common.copyEffect(effect)
        end
    end
    return nil
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

local function payloadIdsForSpell(spellId)
    return normalisePayloadIds(state.payloads and state.payloads[spellId])
end

local function spawnPosition()
    local transform = util.transform.move(self.position) * util.transform.rotateZ(self.rotation:getYaw())
    return transform * util.vector3(0, 180, 0)
end

local function removeControlSpell(activeSpell)
    if activeSpell and activeSpell.activeSpellId then
        activeSpells:remove(activeSpell.activeSpellId)
    end
end

local function activeSpellKey(index, activeSpell)
    return tostring(activeSpell and activeSpell.activeSpellId or '') .. ':' .. tostring(activeSpell and activeSpell.id or '') .. ':' .. tostring(index)
end

local function handleActiveSpell(index, activeSpell)
    local key = activeSpellKey(index, activeSpell)
    if state.handled[key] then return end

    local activeControl = activeSpellControl(activeSpell)
    if not activeControl then return end
    state.handled[key] = true

    local record = core.magic.spells.records[activeSpell.id]
    local payloadSpellIds = payloadIdsForSpell(activeSpell.id)
    local recordControl, fallbackPayload = splitSpellEffects(record)
    local control = recordControl or activeControl

    -- Remove the temporary control effect. This does not stop vanilla payload
    -- effects in an unsplit spell from launching, which is why we split spells
    -- as soon as spellmaking closes.
    removeControlSpell(activeSpell)

    if not payloadSpellIds and #fallbackPayload == 0 then
        ui.showMessage('Conjure Soul Wisp needs at least one spell effect below it.')
        requestPayloadSplit()
        return
    end

    local magnitude = common.averageMagnitude(control)
    core.sendGlobalEvent('RT_CreateSoulWisp', {
        caster = self.object,
        sourceSpellId = record and record.id or activeSpell.id,
        sourceSpellName = record and record.name or activeSpell.name or 'Soul Wisp Spell',
        payloadSpellIds = payloadSpellIds,
        -- Fallback for old/unsplit saves. Newly made spells should use payloadSpellIds.
        payloadEffects = payloadSpellIds and nil or fallbackPayload,
        duration = math.max(1, tonumber(control.duration) or common.defaultDuration),
        fadeOutTime = common.fadeOutTime,
        interval = common.intervalFromMagnitude(magnitude),
        magnitude = magnitude,
        targetRadius = common.defaultRadius,
        position = spawnPosition(),
    })
end

local function scanActiveSpells()
    for index, activeSpell in pairs(activeSpells) do
        handleActiveSpell(index, activeSpell)
    end
end

local function removeOldOriginalSpells()
    for _, id in ipairs(state.removedSpells or {}) do
        if playerSpells[id] then
            playerSpells:remove(id)
        end
    end
end

local function onPayloadsUpdated(data)
    data = data or {}
    state.payloads = data.payloads or state.payloads or {}
    state.removedSpells = data.removedSpells or state.removedSpells or {}
    removeOldOriginalSpells()
end

return {
    onInit = function()
        ensureStarterSpell()
        requestPayloadSplit()
    end,
    onLoad = function(save)
        state = save or state
        state.handled = state.handled or {}
        state.nextScan = state.nextScan or 0
        state.payloads = state.payloads or {}
        state.removedSpells = state.removedSpells or {}
        ensureStarterSpell()
        requestPayloadSplit()
    end,
    onSave = function()
        return state
    end,
    onActive = function()
        ensureStarterSpell()
        requestPayloadSplit()
        removeOldOriginalSpells()
    end,
    onUiModeChanged = function(oldMode)
        if oldMode == 'SpellCreation' then
            requestPayloadSplit()
        end
    end,
    onUpdate = function()
        local now = core.getSimulationTime()
        if now < state.nextScan then return end
        state.nextScan = now + common.scanInterval
        scanActiveSpells()
    end,
    eventHandlers = {
        RT_SoulWispPayloadsUpdated = onPayloadsUpdated,
    },
}
