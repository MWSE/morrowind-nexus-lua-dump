local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local storage = require("openmw.storage")

local settings = require("scripts.sptLimits.player.settings")
local exclusions = require("scripts.sptLimits.shared.exclusions")
local L = core.l10n("sptLimits")

local excludedPotions = exclusions.excludedPotions
local isPotionExcluded = exclusions.isPotionExcluded

local state = {
    drinkCount = 0,
    timer = 0,
    drinkHour = 0,
    drinkOverdose = false,
    overdoseCollapse = false,
    knownPotionSpellIds = {},
    potionSpellIdsInitialized = false,
    drinkIcons = {},
}

local lastSent = {
    drinkCount = nil,
    countdown = nil,
    potionLimit = nil,
    drinkIcons = nil,
    globalKnockedOut = nil,
    globalOverdose = nil,
}

local function resetLastSent()
    lastSent.drinkCount = nil
    lastSent.countdown = nil
    lastSent.potionLimit = nil
    lastSent.drinkIcons = nil
    lastSent.globalKnockedOut = nil
    lastSent.globalOverdose = nil
end

local function updatePotionTimer(dt)
    if state.drinkCount == 0 then
        return
    end

    local currentHour = core.getGameTime() / 3600

    if (currentHour - state.drinkHour) >= 1 then
        state.drinkCount = 0
        state.timer = 0
        state.overdoseCollapse = false
        state.drinkOverdose = false
        state.potionSpellIdsInitialized = false
        state.knownPotionSpellIds = {}
        state.drinkIcons = {}
        return
    end

    state.timer = state.timer + dt

    if state.timer >= settings.get("potionCooldown") then
        state.drinkCount = 0
        state.timer = 0
        state.overdoseCollapse = false
        state.drinkOverdose = false
        state.potionSpellIdsInitialized = false
        state.knownPotionSpellIds = {}
        state.drinkIcons = {}
    end
end

local function handleDrinkDetected(knockedOutRef)
    state.timer = 0
    state.drinkHour = core.getGameTime() / 3600
    state.drinkCount = state.drinkCount + 1

    if state.drinkCount >= settings.get("potionLimit") + 2 then
        ui.showMessage(L("overdoseDeath"))
        types.Actor.stats.dynamic.health(self).current = 0
        return
    end

    if state.drinkCount >= settings.get("potionLimit") + 1 then
        ui.showMessage(L("overdose"))
        state.overdoseCollapse = true
        knockedOutRef.value = true
        types.Actor.stats.dynamic.fatigue(self).base = 0
        types.Actor.stats.dynamic.fatigue(self).current = -1
    end
end

local function detectDrinks(knockedOutRef)
    local currentIds = {}
    local activeSpells = types.Actor.activeSpells(self)
    local excludeSunsDusk = settings.get("excludeSunsDusk")
    for _, spell in pairs(activeSpells) do
        local rok, rec = pcall(types.Potion.record, spell.id)
        if rok and rec then
            if not isPotionExcluded(spell.id, excludeSunsDusk) then
                currentIds[spell.activeSpellId] = spell
            elseif not excludedPotions[spell.id] then
                excludedPotions[spell.id] = true
                core.sendGlobalEvent("sptLimitsExcludePotion", { recordId = spell.id })
            end
        end
    end

    if not state.potionSpellIdsInitialized then
        state.knownPotionSpellIds = {}
        for id, _ in pairs(currentIds) do
            state.knownPotionSpellIds[id] = true
        end
        state.potionSpellIdsInitialized = true
    else
        for id, spell in pairs(currentIds) do
            if not state.knownPotionSpellIds[id] then
                local icon = nil
                if spell.effects then
                    local longestDuration = 0
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
                state.drinkIcons[#state.drinkIcons + 1] = icon or ""
                handleDrinkDetected(knockedOutRef)
                state.knownPotionSpellIds[id] = true
            end
        end
        for id, _ in pairs(state.knownPotionSpellIds) do
            if not currentIds[id] then
                state.knownPotionSpellIds[id] = nil
            end
        end
    end
end

local function onUpdate(dt, knockedOutRef)
    detectDrinks(knockedOutRef)
    updatePotionTimer(dt)
    state.drinkOverdose = (state.drinkCount >= settings.get("potionLimit"))
end

local function writeStorage()
    local countdown = state.drinkCount > 0 and math.max(0, settings.get("potionCooldown") - state.timer) or 0
    local section = storage.playerSection("sptLimitsState")
    if lastSent.drinkCount ~= state.drinkCount then
        section:set("drinkCount", state.drinkCount)
        lastSent.drinkCount = state.drinkCount
    end
    local countdownRounded = math.floor(countdown * 10) / 10
    if lastSent.countdown ~= countdownRounded then
        section:set("countdown", countdown)
        lastSent.countdown = countdownRounded
    end
    local currentPotionLimit = settings.get("potionLimit")
    if lastSent.potionLimit ~= currentPotionLimit then
        section:set("potionLimit", currentPotionLimit)
        lastSent.potionLimit = currentPotionLimit
    end
    local iconsStr = table.concat(state.drinkIcons, "|")
    if lastSent.drinkIcons ~= iconsStr then
        section:set("drinkIcons", iconsStr)
        lastSent.drinkIcons = iconsStr
    end
end

local function sendStateEvent(knockedOut)
    if lastSent.globalKnockedOut ~= knockedOut or lastSent.globalOverdose ~= state.drinkOverdose then
        core.sendGlobalEvent("sptLimitsStateUpdate", {
            knockedOut = knockedOut,
            drinkOverdose = state.drinkOverdose,
            potionTrackingMode = "counter",
        })
        lastSent.globalKnockedOut = knockedOut
        lastSent.globalOverdose = state.drinkOverdose
    end
end

local function reset()
    state.drinkCount = 0
    state.timer = 0
    state.drinkHour = 0
    state.drinkOverdose = false
    state.overdoseCollapse = false
    state.knownPotionSpellIds = {}
    state.potionSpellIdsInitialized = false
    state.drinkIcons = {}
    resetLastSent()
end

local function onLoad(data)
    if data then
        state.drinkCount = data.drinkCount or 0
        state.timer = data.timer or 0
        state.drinkHour = data.drinkHour or 0
        state.overdoseCollapse = data.overdoseCollapse or false
        state.drinkIcons = data.drinkIcons or {}
    else
        state.drinkCount = 0
        state.timer = 0
        state.drinkHour = 0
        state.overdoseCollapse = false
        state.drinkIcons = {}
    end
    state.drinkOverdose = (state.drinkCount >= settings.get("potionLimit"))
    state.knownPotionSpellIds = {}
    state.potionSpellIdsInitialized = false
    resetLastSent()
end

local function onSave()
    return {
        drinkCount = state.drinkCount,
        timer = state.timer,
        drinkHour = state.drinkHour,
        overdoseCollapse = state.overdoseCollapse,
        drinkIcons = state.drinkIcons,
    }
end

return {
    state = state,
    reset = reset,
    resetLastSent = resetLastSent,
    onUpdate = onUpdate,
    writeStorage = writeStorage,
    sendStateEvent = sendStateEvent,
    onLoad = onLoad,
    onSave = onSave,
}
