local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local settings = require("scripts.sptLimits.player.settings")
local exclusions = require("scripts.sptLimits.shared.exclusions")
local statChecker = require("scripts.sptLimits.player.statChecker")
local potionCounter = require("scripts.sptLimits.player.potionCounter")
local potionSlots = require("scripts.sptLimits.player.potionSlots")

local training = require("scripts.sptLimits.player.training")
local L = core.l10n("sptLimits")

local excludedPotions = exclusions.excludedPotions
local isPotionExcluded = exclusions.isPotionExcluded

local state = {}

local function restoreFatigue()
    local attrs = types.Actor.stats.attributes
    local baseMax = attrs.strength(self).modified
        + attrs.willpower(self).modified
        + attrs.agility(self).modified
        + attrs.endurance(self).modified
    types.Actor.stats.dynamic.fatigue(self).base = baseMax
    types.Actor.stats.dynamic.fatigue(self).current = 0
end

local function initState()
    state.knockedOut = false
    state.potionTrackingMode = settings.get("potionTrackingMode")

    potionCounter.reset()
    potionSlots.reset()

    if state.potionTrackingMode == "slots" then
        potionSlots.initSlots()
    end
end

local function handleKnockoutRecovery(limitAttribute, limitSkill)
    local anyLimit = limitAttribute or limitSkill or potionCounter.state.overdoseCollapse
    if state.potionTrackingMode == "slots" and potionSlots.areAllSlotsFull() then
        anyLimit = true
    end

    if not state.knockedOut and anyLimit then
        state.knockedOut = true
        types.Actor.stats.dynamic.fatigue(self).base = 0
        types.Actor.stats.dynamic.fatigue(self).current = -1
        local currentMode = interfaces.UI and interfaces.UI.getMode and interfaces.UI.getMode()
        if not currentMode and interfaces.UI and interfaces.UI.setMode then
            interfaces.UI.setMode()
        end
    elseif state.knockedOut and anyLimit then
        types.Actor.stats.dynamic.fatigue(self).base = 0
        types.Actor.stats.dynamic.fatigue(self).current = 0
    elseif state.knockedOut and not anyLimit then
        ui.showMessage(L("recovered"))
        restoreFatigue()
        state.knockedOut = false
        potionCounter.state.overdoseCollapse = false
        potionCounter.state.potionSpellIdsInitialized = false
        potionCounter.state.knownPotionSpellIds = {}
        potionCounter.state.drinkOverdose = false
        potionSlots.state.potionSpellIdsInitialized = false
        potionSlots.state.knownPotionSpellIds = {}
    end
end

local function sendSettingsToGlobal()
    core.sendGlobalEvent("sptLimitsSettingsUpdate", {
        potionLimitEnabled = settings.get("potionLimitEnabled"),
        statLimitEnabled = settings.get("statLimitEnabled"),
        excludeSunsDusk = settings.get("excludeSunsDusk"),
    })
end

local function initKnownPotionSpells()
    local activeSpells = types.Actor.activeSpells(self)
    local excludeSunsDusk = settings.get("excludeSunsDusk")
    local knownIds = {}
    for _, spell in pairs(activeSpells) do
        local rok, rec = pcall(types.Potion.record, spell.id)
        if rok and rec then
            if not isPotionExcluded(spell.id, excludeSunsDusk) then
                knownIds[spell.activeSpellId] = true
            elseif not excludedPotions[spell.id] then
                excludedPotions[spell.id] = true
                core.sendGlobalEvent("sptLimitsExcludePotion", { recordId = spell.id })
            end
        end
    end
    if state.potionTrackingMode == "counter" then
        potionCounter.state.knownPotionSpellIds = knownIds
        potionCounter.state.potionSpellIdsInitialized = true
    else
        potionSlots.state.knownPotionSpellIds = knownIds
        potionSlots.state.potionSpellIdsInitialized = true
    end
end

settings.subscribe(function(key, newValue)
    if training then
        training.onSettingChanged(key, newValue)
    end

    if key == "potionLimitEnabled" or key == "statLimitEnabled" or key == "excludeSunsDusk" then
        if key == "potionLimitEnabled" and newValue then
            potionCounter.state.potionSpellIdsInitialized = false
            potionCounter.state.knownPotionSpellIds = {}
            potionSlots.state.potionSpellIdsInitialized = false
            potionSlots.state.knownPotionSpellIds = {}
        end
        if key == "potionLimitEnabled" and not newValue and state.knockedOut then
            local potionCaused = potionCounter.state.overdoseCollapse
                or (state.potionTrackingMode == "slots" and potionSlots.areAllSlotsFull())
            if potionCaused then
                if state.potionTrackingMode == "slots" then
                    local slotCount = settings.get("potionSlotCount")
                    local overflow = potionSlots.state.slots[slotCount + 1]
                    if overflow then
                        overflow.activeSpellId = nil
                        overflow.countdown = 0
                        overflow.icon = nil
                    end
                end
                restoreFatigue()
                state.knockedOut = false
                potionCounter.state.overdoseCollapse = false
                potionCounter.state.drinkOverdose = false
            end
        elseif key == "statLimitEnabled" and not newValue and state.knockedOut then
            if
                not potionCounter.state.overdoseCollapse
                and not (state.potionTrackingMode == "slots" and potionSlots.areAllSlotsFull())
            then
                restoreFatigue()
                state.knockedOut = false
            end
        end
        sendSettingsToGlobal()
    elseif key == "potionSlotCount" then
        if state.potionTrackingMode == "slots" then
            local wasKnockedOut = state.knockedOut
            state.knockedOut = false
            potionSlots.initSlots()
            potionSlots.state.knownPotionSpellIds = {}
            potionSlots.state.potionSpellIdsInitialized = false
            potionSlots.clearStorage()
            potionSlots.resetLastSent()
            if wasKnockedOut then
                restoreFatigue()
            end
            core.sendGlobalEvent("sptLimitsStateUpdate", {
                knockedOut = false,
                allNormalSlotsFull = false,
                potionTrackingMode = "slots",
            })
        end
    elseif key == "potionTrackingMode" then
        if newValue ~= state.potionTrackingMode then
            local wasKnockedOut = state.knockedOut
            state.potionTrackingMode = newValue
            state.knockedOut = false

            potionCounter.reset()
            potionSlots.reset()

            if newValue == "slots" then
                potionSlots.initSlots()
            end

            if wasKnockedOut then
                restoreFatigue()
            end

            local section = storage.playerSection("sptLimitsState")
            if newValue == "counter" then
                potionSlots.clearStorage()
            else
                section:set("drinkCount", 0)
                section:set("countdown", 0)
            end
            section:set("trackingMode", newValue)

            if newValue == "slots" then
                core.sendGlobalEvent("sptLimitsStateUpdate", {
                    knockedOut = false,
                    allNormalSlotsFull = false,
                    potionTrackingMode = "slots",
                })
            else
                core.sendGlobalEvent("sptLimitsStateUpdate", {
                    knockedOut = false,
                    drinkOverdose = false,
                    potionTrackingMode = "counter",
                })
            end
        end
    end
end)

return {
    engineHandlers = {
        onInit = function()
            settings.registerPage()
            settings.syncToStorage()
            initState()
            sendSettingsToGlobal()
            local section = storage.playerSection("sptLimitsState")
            section:set("trackingMode", state.potionTrackingMode)
            section:set("drinkCount", 0)
            section:set("countdown", 0)
            section:set("potionLimit", settings.get("potionLimit"))
        end,
        onLoad = function(data)
            settings.registerPage()
            if data and data.settings then
                settings.loadAll(data.settings)
            else
                settings.syncToStorage()
            end
            initState()

            if data then
                state.knockedOut = data.knockedOut or false
            end

            training.onLoad(data)

            if state.potionTrackingMode == "counter" then
                potionCounter.onLoad(data)
                potionSlots.clearStorage()
            elseif state.potionTrackingMode == "slots" then
                local knockedOutRef = { value = state.knockedOut }
                potionSlots.onLoad(data, knockedOutRef)
                state.knockedOut = knockedOutRef.value
            end

            initKnownPotionSpells()
            sendSettingsToGlobal()

            local section = storage.playerSection("sptLimitsState")
            section:set("trackingMode", state.potionTrackingMode)
        end,
        onSave = function()
            local saved = {
                knockedOut = state.knockedOut,
                trainCount = training and training.state.trainCount or 0,
                trainLevel = training and training.state.trainLevel or 0,
                settings = settings.saveAll(),
            }

            if state.potionTrackingMode == "slots" then
                local slotData = potionSlots.onSave()
                saved.slots = slotData.slots
            else
                local counterData = potionCounter.onSave()
                saved.drinkCount = counterData.drinkCount
                saved.timer = counterData.timer
                saved.drinkHour = counterData.drinkHour
                saved.overdoseCollapse = counterData.overdoseCollapse
                saved.drinkIcons = counterData.drinkIcons
            end

            return saved
        end,
        onUpdate = function(dt)
            if not types.Player.isCharGenFinished(self) then
                return
            end

            if settings.get("trainingLimitEnabled") then
                training.checkTrainingLevelReset()
            end

            if not settings.get("statLimitEnabled") and not settings.get("potionLimitEnabled") then
                return
            end

            local limitAttribute = false
            local limitSkill = false

            if settings.get("statLimitEnabled") then
                limitAttribute = statChecker.checkAttributes(settings.get("attributeCap"))
                if limitAttribute and not state.knockedOut then
                    ui.showMessage(L("attributeLimit"))
                end

                limitSkill = statChecker.checkSkills(settings.get("skillCap"))
                if limitSkill and not state.knockedOut then
                    ui.showMessage(L("skillLimit"))
                end
            end

            local knockedOutRef = { value = state.knockedOut }

            if settings.get("potionLimitEnabled") and state.potionTrackingMode == "counter" then
                potionCounter.onUpdate(dt, knockedOutRef)
                state.knockedOut = knockedOutRef.value
            end

            if settings.get("potionLimitEnabled") and state.potionTrackingMode == "slots" then
                potionSlots.onUpdate(dt, knockedOutRef)
                potionSlots.sendStateEvent(knockedOutRef.value)
                state.knockedOut = knockedOutRef.value
            end

            handleKnockoutRecovery(limitAttribute, limitSkill)

            if settings.get("potionLimitEnabled") and state.potionTrackingMode == "counter" then
                potionCounter.writeStorage()
                potionCounter.sendStateEvent(state.knockedOut)
            end
        end,
    },
    eventHandlers = {
        sptLimitsShowMessage = function(data)
            if data and data.text then
                ui.showMessage(data.text)
            end
        end,
    },
    interfaceName = "sptLimits",
    interface = {
        version = 1,
        isKnockedOut = function()
            return state.knockedOut
        end,
        excludePotion = function(recordId)
            if recordId then
                excludedPotions[recordId] = true
                core.sendGlobalEvent("sptLimitsExcludePotion", { recordId = recordId })
            end
        end,
        includePotion = function(recordId)
            if recordId then
                excludedPotions[recordId] = nil
                core.sendGlobalEvent("sptLimitsIncludePotion", { recordId = recordId })
            end
        end,
        skipAttribute = function(attributeName)
            if attributeName then
                statChecker.skippedAttributes[attributeName] = true
            end
        end,
        unskipAttribute = function(attributeName)
            if attributeName then
                statChecker.skippedAttributes[attributeName] = nil
            end
        end,
        skipSkill = function(skillName)
            if skillName then
                statChecker.skippedSkills[skillName] = true
            end
        end,
        unskipSkill = function(skillName)
            if skillName then
                statChecker.skippedSkills[skillName] = nil
            end
        end,
    },
}
