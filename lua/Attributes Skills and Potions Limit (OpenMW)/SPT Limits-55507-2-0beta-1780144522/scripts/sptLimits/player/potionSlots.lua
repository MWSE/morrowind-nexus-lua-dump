local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local storage = require("openmw.storage")

local config = require("scripts.sptLimits.shared.config")
local settings = require("scripts.sptLimits.player.settings")
local exclusions = require("scripts.sptLimits.shared.exclusions")
local L = core.l10n("sptLimits")

local excludedPotions = exclusions.excludedPotions
local isPotionExcluded = exclusions.isPotionExcluded

local maxSlotIndex = config.maxSlotDisplay

local state = {
    slots = {},
    knownPotionSpellIds = {},
    potionSpellIdsInitialized = false,
}

local lastSent = {
    slotTrackingMode = nil,
    slotCount = nil,
    occupiedSlots = nil,
    overflowOccupied = nil,
    slotKnockedOut = nil,
    slotAllFull = nil,
}

local function resetLastSent()
    lastSent.slotTrackingMode = nil
    lastSent.slotCount = nil
    lastSent.occupiedSlots = nil
    lastSent.overflowOccupied = nil
    lastSent.slotKnockedOut = nil
    lastSent.slotAllFull = nil
    lastSent.slotNormalFull = nil
    for i = 1, maxSlotIndex do
        lastSent["slot" .. i .. "Countdown"] = nil
        lastSent["slot" .. i .. "Icon"] = nil
    end
end

local function clearStorage()
    local section = storage.playerSection("sptLimitsState")
    for i = 1, maxSlotIndex do
        section:set("slot" .. i .. "Countdown", 0)
        section:set("slot" .. i .. "Icon", "")
    end
    section:set("occupiedSlots", 0)
    section:set("overflowOccupied", false)
    section:set("slotCount", 0)
end

local function initSlots()
    local slotCount = settings.get("potionSlotCount")
    state.slots = {}
    for i = 1, slotCount + 1 do
        state.slots[i] = { activeSpellId = nil, countdown = 0, icon = nil }
    end
end

local function getOccupiedNormalCount()
    local slotCount = settings.get("potionSlotCount")
    local count = 0
    for i = 1, slotCount do
        if state.slots[i] and state.slots[i].activeSpellId ~= nil then
            count = count + 1
        end
    end
    return count
end

local function areAllSlotsFull()
    local slotCount = settings.get("potionSlotCount")
    for i = 1, slotCount + 1 do
        if state.slots[i] and state.slots[i].activeSpellId == nil then
            return false
        end
    end
    return true
end

local function isOverflowOccupied()
    local slotCount = settings.get("potionSlotCount")
    local overflow = state.slots[slotCount + 1]
    return overflow ~= nil and overflow.activeSpellId ~= nil
end

local function assignDrinkToSlot(activeSpellId, longestDuration, icon)
    local slotCount = settings.get("potionSlotCount")
    for i = 1, slotCount + 1 do
        if state.slots[i] and state.slots[i].activeSpellId == nil then
            state.slots[i].activeSpellId = activeSpellId
            state.slots[i].countdown = longestDuration
            state.slots[i].icon = icon
            return true
        end
    end
    return false
end

local function triggerOverdoseCollapse(knockedOutRef)
    knockedOutRef.value = true
    types.Actor.stats.dynamic.fatigue(self).current = -1
    ui.showMessage(L("overdose"))
end

local function validateSlots(activeSpellIdSet)
    local slotCount = settings.get("potionSlotCount")
    for i = 1, slotCount + 1 do
        local slot = state.slots[i]
        if slot and slot.activeSpellId ~= nil then
            if not activeSpellIdSet[slot.activeSpellId] then
                slot.activeSpellId = nil
                slot.countdown = 0
                slot.icon = nil
            end
        end
    end
end

local function tickSlots(dt)
    local slotCount = settings.get("potionSlotCount")
    for i = 1, slotCount + 1 do
        local slot = state.slots[i]
        if slot and slot.activeSpellId ~= nil then
            local prevCountdown = slot.countdown
            if prevCountdown > 0 then
                slot.countdown = prevCountdown - dt
                if slot.countdown < 0 then
                    slot.countdown = 0
                end
            end
        end
    end
end

local function writeStorage()
    local slotCount = settings.get("potionSlotCount")
    local section = storage.playerSection("sptLimitsState")
    local occupiedNormal = getOccupiedNormalCount()
    local overflowOcc = isOverflowOccupied()

    if lastSent.slotTrackingMode ~= "slots" then
        section:set("trackingMode", "slots")
        lastSent.slotTrackingMode = "slots"
    end
    if lastSent.slotCount ~= slotCount then
        section:set("slotCount", slotCount)
        lastSent.slotCount = slotCount
    end
    for i = 1, slotCount + 1 do
        local slot = state.slots[i]
        local occupied = slot and slot.activeSpellId ~= nil
        local countdown = occupied and slot.countdown or 0
        if countdown < 0.1 then
            countdown = 0
        end
        local countdownRounded = math.floor(countdown * 10) / 10
        local lastKey = "slot" .. i .. "Countdown"
        local prevRounded = lastSent[lastKey]
        if prevRounded ~= countdownRounded or (not occupied and prevRounded ~= nil and prevRounded ~= 0) then
            section:set(lastKey, countdown)
            lastSent[lastKey] = occupied and countdownRounded or 0
        end
        local icon = occupied and slot.icon or ""
        local iconKey = "slot" .. i .. "Icon"
        if lastSent[iconKey] ~= icon then
            section:set(iconKey, icon)
            lastSent[iconKey] = icon
        end
    end
    if lastSent.occupiedSlots ~= occupiedNormal then
        section:set("occupiedSlots", occupiedNormal)
        lastSent.occupiedSlots = occupiedNormal
    end
    if lastSent.overflowOccupied ~= overflowOcc then
        section:set("overflowOccupied", overflowOcc)
        lastSent.overflowOccupied = overflowOcc
    end
end

local function sendStateEvent(knockedOut)
    local normalFull = (getOccupiedNormalCount() == settings.get("potionSlotCount"))
    local allFull = areAllSlotsFull()
    if
        lastSent.slotKnockedOut ~= knockedOut
        or lastSent.slotAllFull ~= allFull
        or lastSent.slotNormalFull ~= normalFull
    then
        core.sendGlobalEvent("sptLimitsStateUpdate", {
            knockedOut = knockedOut,
            allNormalSlotsFull = normalFull,
            allSlotsFull = allFull,
            potionTrackingMode = "slots",
        })
        lastSent.slotKnockedOut = knockedOut
        lastSent.slotAllFull = allFull
        lastSent.slotNormalFull = normalFull
    end
end

local function detectDrinks(knockedOutRef)
    local currentPotionSpellIds = {}
    local activeSpells = types.Actor.activeSpells(self)
    local excludeSunsDusk = settings.get("excludeSunsDusk")
    for _, spell in pairs(activeSpells) do
        local rok, rec = pcall(types.Potion.record, spell.id)
        if rok and rec then
            if not isPotionExcluded(spell.id, excludeSunsDusk) then
                currentPotionSpellIds[spell.activeSpellId] = spell
            elseif not excludedPotions[spell.id] then
                excludedPotions[spell.id] = true
                core.sendGlobalEvent("sptLimitsExcludePotion", { recordId = spell.id })
            end
        end
    end

    if not state.potionSpellIdsInitialized then
        for activeSpellId, _ in pairs(currentPotionSpellIds) do
            state.knownPotionSpellIds[activeSpellId] = true
        end
        state.potionSpellIdsInitialized = true
    else
        for activeSpellId, spell in pairs(currentPotionSpellIds) do
            if not state.knownPotionSpellIds[activeSpellId] then
                local longestDuration = 0
                local icon = nil
                if spell.effects then
                    for _, effect in pairs(spell.effects) do
                        if effect.duration and effect.duration > longestDuration then
                            longestDuration = effect.duration
                            if effect.id then
                                local mgef = core.magic.effects.records[effect.id]
                                if mgef and mgef.icon then
                                    icon = mgef.icon
                                end
                            end
                        end
                    end
                    if icon == nil then
                        for _, effect in pairs(spell.effects) do
                            if effect.id then
                                local mgef = core.magic.effects.records[effect.id]
                                if mgef and mgef.icon then
                                    icon = mgef.icon
                                    break
                                end
                            end
                        end
                    end
                end
                if not assignDrinkToSlot(activeSpellId, longestDuration, icon) then
                    triggerOverdoseCollapse(knockedOutRef)
                end
                state.knownPotionSpellIds[activeSpellId] = true
            end
        end

        for id, _ in pairs(state.knownPotionSpellIds) do
            if not currentPotionSpellIds[id] then
                state.knownPotionSpellIds[id] = nil
            end
        end
    end

    return currentPotionSpellIds
end

local function onUpdate(dt, knockedOutRef)
    local currentPotionSpellIds = detectDrinks(knockedOutRef)

    tickSlots(dt)

    validateSlots(currentPotionSpellIds)

    if knockedOutRef.value and areAllSlotsFull() then
        types.Actor.stats.dynamic.fatigue(self).base = 0
        types.Actor.stats.dynamic.fatigue(self).current = 0
    end

    writeStorage()
end

local function reset()
    state.slots = {}
    state.knownPotionSpellIds = {}
    state.potionSpellIdsInitialized = false
    resetLastSent()
end

local function onLoad(data, knockedOutRef)
    state.knownPotionSpellIds = {}
    state.potionSpellIdsInitialized = false
    resetLastSent()

    if data and data.slots then
        local slotCount = settings.get("potionSlotCount")
        local targetSize = slotCount + 1

        if type(data.slots) ~= "table" then
            initSlots()
        else
            state.slots = {}
            local sourceLen = #data.slots
            local restoreCount = math.min(sourceLen, targetSize)
            for i = 1, restoreCount do
                local entry = data.slots[i]
                if type(entry) ~= "table" then
                    state.slots[i] = { activeSpellId = nil, countdown = 0, icon = nil }
                else
                    local activeSpellId = entry.activeSpellId
                    local countdown = entry.countdown
                    local icon = entry.icon

                    if activeSpellId ~= nil and type(activeSpellId) ~= "string" then
                        activeSpellId = nil
                    end

                    if type(countdown) ~= "number" then
                        countdown = 0
                    elseif countdown < 0 then
                        countdown = 0
                    end

                    if icon ~= nil and type(icon) ~= "string" then
                        icon = nil
                    end

                    state.slots[i] = { activeSpellId = activeSpellId, countdown = countdown, icon = icon }
                end
            end
            for i = restoreCount + 1, targetSize do
                state.slots[i] = { activeSpellId = nil, countdown = 0, icon = nil }
            end

            local activeSpells = types.Actor.activeSpells(self)
            local activeSpellIdSet = {}
            for _, spell in pairs(activeSpells) do
                activeSpellIdSet[spell.activeSpellId] = true
            end

            for i = 1, targetSize do
                local slot = state.slots[i]
                if slot.activeSpellId ~= nil then
                    if not activeSpellIdSet[slot.activeSpellId] then
                        slot.activeSpellId = nil
                        slot.countdown = 0
                    end
                end
            end

            local allFull = true
            for i = 1, targetSize do
                local slot = state.slots[i]
                if slot.activeSpellId == nil then
                    allFull = false
                    break
                end
            end
            if allFull then
                knockedOutRef.value = true
            end
        end
    else
        initSlots()
    end
end

local function onSave()
    local slotCount = settings.get("potionSlotCount")
    local slotsData = {}
    for i = 1, slotCount + 1 do
        local slot = state.slots[i]
        if slot then
            slotsData[i] = { activeSpellId = slot.activeSpellId, countdown = slot.countdown, icon = slot.icon }
        else
            slotsData[i] = { activeSpellId = nil, countdown = 0, icon = nil }
        end
    end
    return {
        slots = slotsData,
    }
end

return {
    state = state,
    initSlots = initSlots,
    isOverflowOccupied = isOverflowOccupied,
    areAllSlotsFull = areAllSlotsFull,
    getOccupiedNormalCount = getOccupiedNormalCount,
    clearStorage = clearStorage,
    reset = reset,
    resetLastSent = resetLastSent,
    onUpdate = onUpdate,
    onLoad = onLoad,
    onSave = onSave,
    sendStateEvent = sendStateEvent,
}
