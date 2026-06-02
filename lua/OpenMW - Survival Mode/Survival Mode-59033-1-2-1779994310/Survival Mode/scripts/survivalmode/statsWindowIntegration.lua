local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')

local l10n = core.l10n('SurvivalMode', 'en')
local gameplaySettings = storage.playerSection('SettingsSurvivalNeedsGameplay')
local hudSettings = storage.playerSection('SettingsSurvivalNeedsHUD')
local hasRegistered = false
local lastAppliedIndent = nil
local lastAppliedIntegrationEnabled = nil

local function isTableLike(value)
    local t = type(value)
    return t == 'table' or t == 'userdata'
end

local BOX_ID = 'SurvivalNeedsNeedsBox'
local SECTION_ID = 'SurvivalNeedsNeedsSection'

local LINE_IDS = {
    hunger = 'SurvivalNeedsLineHunger',
    thirst = 'SurvivalNeedsLineThirst',
    sleep = 'SurvivalNeedsLineSleep',
    temperature = 'SurvivalNeedsLineTemperature',
}

local WEAPON_SKILLS = {
    longblade = true,
    shortblade = true,
    axe = true,
    bluntweapon = true,
    spear = true,
    marksman = true,
    handtohand = true,
}

local MAGIC_SKILLS = {
    destruction = true,
    restoration = true,
    alteration = true,
    illusion = true,
    conjuration = true,
    mysticism = true,
}

local SLEEP_DRAIN_SKILLS = {
    lightarmor = true,
    mediumarmor = true,
    heavyarmor = true,
    unarmored = true,
    block = true,
    sneak = true,
}

local TEMPERATURE_EFFECT_IDS = {
    sn_tmp_penalty_hunger_display = true,
    sn_tmp_penalty_thirst_display = true,
    sn_tmp_penalty_slowness_display = true,
    sn_tmp_penalty_health_display = true,
    weaknesstofire = true,
    weaknesstofrost = true,
}

local STAGE_NAMES = {
    hunger = {
        well_fed = l10n('hunger_stage_well_fed_name'),
        satisfied = l10n('hunger_stage_satisfied_name'),
        peckish = l10n('hunger_stage_peckish_name'),
        hungry = l10n('hunger_stage_hungry_name'),
        famished = l10n('hunger_stage_very_hungry_name'),
        starving = l10n('hunger_stage_starving_name'),
    },
    thirst = {
        well_hydrated = l10n('thirst_stage_well_hydrated_name'),
        hydrated = l10n('thirst_stage_hydrated_name'),
        thirsty = l10n('thirst_stage_thirsty_name'),
        parched = l10n('thirst_stage_parched_name'),
        dehydrated = l10n('thirst_stage_dehydrated_name'),
        severely_dehydrated = l10n('thirst_stage_severely_dehydrated_name'),
    },
    sleep = {
        well_rested = l10n('sleep_stage_well_rested_name'),
        refreshed = l10n('sleep_stage_refreshed_name'),
        drained = l10n('sleep_stage_drained_name'),
        tired = l10n('sleep_stage_tired_name'),
        weary = l10n('sleep_stage_weary_name'),
        debilitated = l10n('sleep_stage_debilitated_name'),
    },
    temperature = {
        freezing = l10n('temperature_stage_freezing_name'),
        very_cold = l10n('temperature_stage_very_cold_name'),
        cold = l10n('temperature_stage_cold_name'),
        chilly = l10n('temperature_stage_chilly_name'),
        neutral = l10n('temperature_stage_neutral_name'),
        warm = l10n('temperature_stage_warm_name'),
        hot = l10n('temperature_stage_hot_name'),
        very_hot = l10n('temperature_stage_very_hot_name'),
        scorching = l10n('temperature_stage_scorching_name'),
    },
}

local STAGE_TOOLTIP_MESSAGES = {
    hunger = {
        [STAGE_NAMES.hunger.well_fed] = l10n('hunger_stage_well_fed_message'),
        [STAGE_NAMES.hunger.satisfied] = l10n('hunger_stage_satisfied_message'),
        [STAGE_NAMES.hunger.peckish] = l10n('hunger_stage_peckish_message'),
        [STAGE_NAMES.hunger.hungry] = l10n('hunger_stage_hungry_message'),
        [STAGE_NAMES.hunger.famished] = l10n('hunger_stage_very_hungry_message'),
        [STAGE_NAMES.hunger.starving] = l10n('hunger_stage_starving_message'),
    },
    thirst = {
        [STAGE_NAMES.thirst.well_hydrated] = l10n('thirst_stage_well_hydrated_message'),
        [STAGE_NAMES.thirst.hydrated] = l10n('thirst_stage_hydrated_message'),
        [STAGE_NAMES.thirst.thirsty] = l10n('thirst_stage_thirsty_message'),
        [STAGE_NAMES.thirst.parched] = l10n('thirst_stage_parched_message'),
        [STAGE_NAMES.thirst.dehydrated] = l10n('thirst_stage_dehydrated_message'),
        [STAGE_NAMES.thirst.severely_dehydrated] = l10n('thirst_stage_severely_dehydrated_message'),
    },
    sleep = {
        [STAGE_NAMES.sleep.well_rested] = l10n('sleep_stage_well_rested_message'),
        [STAGE_NAMES.sleep.refreshed] = l10n('sleep_stage_refreshed_message'),
        [STAGE_NAMES.sleep.drained] = l10n('sleep_stage_drained_message'),
        [STAGE_NAMES.sleep.tired] = l10n('sleep_stage_tired_message'),
        [STAGE_NAMES.sleep.weary] = l10n('sleep_stage_weary_message'),
        [STAGE_NAMES.sleep.debilitated] = l10n('sleep_stage_debilitated_message'),
    },
    temperature = {
        [STAGE_NAMES.temperature.freezing] = l10n('temperature_stage_freezing_message'),
        [STAGE_NAMES.temperature.very_cold] = l10n('temperature_stage_very_cold_message'),
        [STAGE_NAMES.temperature.cold] = l10n('temperature_stage_cold_message'),
        [STAGE_NAMES.temperature.chilly] = l10n('temperature_stage_chilly_message'),
        [STAGE_NAMES.temperature.neutral] = l10n('temperature_stage_neutral_message'),
        [STAGE_NAMES.temperature.warm] = l10n('temperature_stage_warm_message'),
        [STAGE_NAMES.temperature.hot] = l10n('temperature_stage_hot_message'),
        [STAGE_NAMES.temperature.very_hot] = l10n('temperature_stage_very_hot_message'),
        [STAGE_NAMES.temperature.scorching] = l10n('temperature_stage_scorching_message'),
    },
}

local QUICK_LEARNING_TYPES = {
    weapons = l10n('quick_learning_type_weapons'),
    magicka = l10n('quick_learning_type_magicka'),
    armor = l10n('quick_learning_type_armor'),
    persuasion = l10n('quick_learning_type_persuasion'),
}

local function lowerText(value)
    return string.lower(tostring(value or ''))
end

local function containsPlain(haystackLower, needle)
    if type(needle) ~= 'string' or needle == '' then
        return false
    end
    return string.find(haystackLower, lowerText(needle), 1, true) ~= nil
end

local function isSystemEnabled(settingKey)
    local value = gameplaySettings:get(settingKey)
    return value ~= false
end

local function isStatsIndentEnabled()
    return hudSettings:get('statsMenuIndent') == true
end

local function isStatsWindowIntegrationEnabled()
    return hudSettings:get('enableStatsWindowExtenderIntegration') ~= false
end

local function emptyDetectedStages()
    return {
        hunger = nil,
        thirst = nil,
        sleep = nil,
        temperature = nil,
    }
end

local function detectStagesFromSpells()
    local stages = emptyDetectedStages()

    if types.Actor == nil or type(types.Actor.spells) ~= 'function' then
        return stages
    end

    local okSpells, actorSpells = pcall(types.Actor.spells, self)
    if not okSpells or not isTableLike(actorSpells) then
        return stages
    end

    local seenSpellIds = {}

    for _, spell in pairs(actorSpells) do
        if isTableLike(spell) then
            local spellId = lowerText(spell.id)
            if spellId == '' or not seenSpellIds[spellId] then
                if spellId ~= '' then
                    seenSpellIds[spellId] = true
                end

                local spellNameLower = lowerText(spell.name)
                local hasHungerMarker = false
                local hasThirstMarker = false
                local hasSleepMarker = false
                local hasTemperatureMarker = false
                local hasLearningMarker = false

                local effects = spell.effects
                if isTableLike(effects) then
                    for _, effect in pairs(effects) do
                        if isTableLike(effect) then
                            local effectId = lowerText(effect.id)
                            local affectedSkill = lowerText(effect.affectedSkill)

                            if effectId == 'sn_hunger_stamina_drain_display' then
                                hasHungerMarker = true
                            elseif effectId == 'sn_thirst_stamina_regen_penalty_display' then
                                hasThirstMarker = true
                            elseif TEMPERATURE_EFFECT_IDS[effectId] == true then
                                hasTemperatureMarker = true
                            elseif effectId == 'drainskill' then
                                if WEAPON_SKILLS[affectedSkill] then
                                    hasHungerMarker = true
                                end
                                if MAGIC_SKILLS[affectedSkill] then
                                    hasThirstMarker = true
                                end
                                if SLEEP_DRAIN_SKILLS[affectedSkill] then
                                    hasSleepMarker = true
                                end
                            elseif effectId == 'burden' then
                                hasSleepMarker = true
                            elseif effectId == 'sn_quicker_learning' or effectId == 'restorefatigue' then
                                hasLearningMarker = true
                            end
                        end
                    end
                end

                if hasHungerMarker then
                    if containsPlain(spellNameLower, STAGE_NAMES.hunger.starving) then
                        stages.hunger = STAGE_NAMES.hunger.starving
                    elseif containsPlain(spellNameLower, STAGE_NAMES.hunger.famished) then
                        stages.hunger = STAGE_NAMES.hunger.famished
                    elseif containsPlain(spellNameLower, STAGE_NAMES.hunger.hungry) then
                        stages.hunger = STAGE_NAMES.hunger.hungry
                    elseif containsPlain(spellNameLower, STAGE_NAMES.hunger.peckish) then
                        stages.hunger = STAGE_NAMES.hunger.peckish
                    end
                end

                if hasThirstMarker then
                    if containsPlain(spellNameLower, STAGE_NAMES.thirst.severely_dehydrated) then
                        stages.thirst = STAGE_NAMES.thirst.severely_dehydrated
                    elseif containsPlain(spellNameLower, STAGE_NAMES.thirst.dehydrated) then
                        stages.thirst = STAGE_NAMES.thirst.dehydrated
                    elseif containsPlain(spellNameLower, STAGE_NAMES.thirst.parched) then
                        stages.thirst = STAGE_NAMES.thirst.parched
                    elseif containsPlain(spellNameLower, STAGE_NAMES.thirst.thirsty) then
                        stages.thirst = STAGE_NAMES.thirst.thirsty
                    end
                end

                if hasSleepMarker then
                    if containsPlain(spellNameLower, STAGE_NAMES.sleep.debilitated) then
                        stages.sleep = STAGE_NAMES.sleep.debilitated
                    elseif containsPlain(spellNameLower, STAGE_NAMES.sleep.weary) then
                        stages.sleep = STAGE_NAMES.sleep.weary
                    elseif containsPlain(spellNameLower, STAGE_NAMES.sleep.tired) then
                        stages.sleep = STAGE_NAMES.sleep.tired
                    elseif containsPlain(spellNameLower, STAGE_NAMES.sleep.drained) then
                        stages.sleep = STAGE_NAMES.sleep.drained
                    end
                end

                if hasTemperatureMarker then
                    if containsPlain(spellNameLower, STAGE_NAMES.temperature.scorching) then
                        stages.temperature = STAGE_NAMES.temperature.scorching
                    elseif containsPlain(spellNameLower, STAGE_NAMES.temperature.very_hot) then
                        stages.temperature = STAGE_NAMES.temperature.very_hot
                    elseif containsPlain(spellNameLower, STAGE_NAMES.temperature.hot) then
                        stages.temperature = STAGE_NAMES.temperature.hot
                    elseif containsPlain(spellNameLower, STAGE_NAMES.temperature.warm) then
                        stages.temperature = STAGE_NAMES.temperature.warm
                    elseif containsPlain(spellNameLower, STAGE_NAMES.temperature.freezing) then
                        stages.temperature = STAGE_NAMES.temperature.freezing
                    elseif containsPlain(spellNameLower, STAGE_NAMES.temperature.very_cold) then
                        stages.temperature = STAGE_NAMES.temperature.very_cold
                    elseif containsPlain(spellNameLower, STAGE_NAMES.temperature.cold) then
                        stages.temperature = STAGE_NAMES.temperature.cold
                    elseif containsPlain(spellNameLower, STAGE_NAMES.temperature.chilly) then
                        stages.temperature = STAGE_NAMES.temperature.chilly
                    end
                end

                if hasLearningMarker then
                    if containsPlain(spellNameLower, STAGE_NAMES.hunger.well_fed)
                        and containsPlain(spellNameLower, QUICK_LEARNING_TYPES.weapons) then
                        stages.hunger = STAGE_NAMES.hunger.well_fed
                    end

                    if containsPlain(spellNameLower, STAGE_NAMES.thirst.well_hydrated)
                        and containsPlain(spellNameLower, QUICK_LEARNING_TYPES.magicka) then
                        stages.thirst = STAGE_NAMES.thirst.well_hydrated
                    end

                    if containsPlain(spellNameLower, STAGE_NAMES.sleep.well_rested)
                        and (
                            containsPlain(spellNameLower, QUICK_LEARNING_TYPES.armor)
                            or containsPlain(spellNameLower, QUICK_LEARNING_TYPES.persuasion)
                        ) then
                        stages.sleep = STAGE_NAMES.sleep.well_rested
                    end
                end
            end
        end
    end

    return stages
end

local function resolveDisplayedStages()
    local detected = detectStagesFromSpells()

    local hungerEnabled = isSystemEnabled('enableHungerSystem')
    local thirstEnabled = isSystemEnabled('enableThirstSystem')
    local sleepEnabled = isSystemEnabled('enableSleepSystem')
    local temperatureEnabled = isSystemEnabled('enableTemperatureSystem')

    return {
        hunger = detected.hunger
            or (hungerEnabled and STAGE_NAMES.hunger.satisfied or l10n('needs_stage_disabled')),
        thirst = detected.thirst
            or (thirstEnabled and STAGE_NAMES.thirst.hydrated or l10n('needs_stage_disabled')),
        sleep = detected.sleep
            or (sleepEnabled and STAGE_NAMES.sleep.refreshed or l10n('needs_stage_disabled')),
        temperature = detected.temperature
            or (temperatureEnabled and STAGE_NAMES.temperature.neutral or l10n('needs_stage_disabled')),
    }
end

local function getDisplayedStage(needId)
    return resolveDisplayedStages()[needId] or ''
end

local function getDisplayedStageTooltip(needId, needLabel)
    local stage = getDisplayedStage(needId)
    local tooltipByStage = STAGE_TOOLTIP_MESSAGES[needId]
    if isTableLike(tooltipByStage) then
        local stageMessage = tooltipByStage[stage]
        if type(stageMessage) == 'string' and stageMessage ~= '' then
            return stageMessage
        end
    end

    return l10n('needs_stats_tooltip', {
        need = needLabel,
        stage = stage,
    })
end

local function resolveNeedsBoxPlacement(constants)
    local defaultBoxes = isTableLike(constants) and constants.DefaultBoxes or {}
    local placement = isTableLike(constants) and constants.Placement or {}

    local afterType = placement.AFTER

    local attributeTargets = {
        defaultBoxes.ATTRIBUTES_BOX,
        defaultBoxes.ATTRIBUTE_BOX,
        defaultBoxes.PRIMARY_ATTRIBUTES_BOX,
    }
    for _, target in ipairs(attributeTargets) do
        if target ~= nil and afterType ~= nil then
            return {
                type = afterType,
                target = target,
            }
        end
    end

    local identityTargets = {
        defaultBoxes.RACE_CLASS_BOX,
        defaultBoxes.LEVEL_RACE_CLASS_BOX,
        defaultBoxes.IDENTITY_BOX,
        defaultBoxes.CLASS_BOX,
        defaultBoxes.LEVEL_BOX,
    }
    for _, target in ipairs(identityTargets) do
        if target ~= nil and afterType ~= nil then
            return {
                type = afterType,
                target = target,
            }
        end
    end

    if defaultBoxes.HEALTH_BOX ~= nil and afterType ~= nil then
        return {
            type = afterType,
            target = defaultBoxes.HEALTH_BOX,
        }
    end

    return nil
end

local function registerStatsWindow()
    local indentEnabled = isStatsIndentEnabled()
    local integrationEnabled = isStatsWindowIntegrationEnabled()

    if not integrationEnabled and not hasRegistered then
        return
    end

    if hasRegistered
        and lastAppliedIndent == indentEnabled
        and lastAppliedIntegrationEnabled == integrationEnabled then
        return
    end

    local api = interfaces.StatsWindow
    if not isTableLike(api) or type(api.addLineToSection) ~= 'function' then
        return
    end

    local constants = api.Constants
    if not isTableLike(constants) or not isTableLike(constants.DefaultBoxes) then
        return
    end

    if hasRegistered then
        if type(api.modifySection) == 'function' then
            api.modifySection(SECTION_ID, {
                indent = indentEnabled,
                visibleFn = function()
                    return isStatsWindowIntegrationEnabled()
                end,
            })
        end
        lastAppliedIndent = indentEnabled
        lastAppliedIntegrationEnabled = integrationEnabled
        return
    end

    local needsBoxPlacement = resolveNeedsBoxPlacement(constants)

    if type(api.addBoxToPane) == 'function' and isTableLike(constants.Panes) then
        local addBoxOptions = {}
        if needsBoxPlacement ~= nil then
            addBoxOptions.placement = needsBoxPlacement
        end
        api.addBoxToPane(BOX_ID, constants.Panes.LEFT, addBoxOptions)
    end

    if type(api.addSectionToBox) == 'function' then
        api.addSectionToBox(SECTION_ID, BOX_ID, {
            header = l10n('needs_stats_header'),
            indent = indentEnabled,
            visibleFn = function()
                return isStatsWindowIntegrationEnabled()
            end,
        })
    end
    if type(api.modifySection) == 'function' then
        api.modifySection(SECTION_ID, {
            indent = indentEnabled,
            visibleFn = function()
                return isStatsWindowIntegrationEnabled()
            end,
        })
    end

    local tooltipBuilder = isTableLike(api.TooltipBuilders) and api.TooltipBuilders.TEXT or nil

    local function addNeedLine(lineId, labelKey, needId)
        api.addLineToSection(lineId, SECTION_ID, {
            label = l10n(labelKey),
            value = function()
                return { string = getDisplayedStage(needId) }
            end,
            tooltip = type(tooltipBuilder) == 'function'
                and function()
                    return tooltipBuilder({
                        text = getDisplayedStageTooltip(needId, l10n(labelKey)),
                    })
                end
                or nil,
        })
    end

    addNeedLine(LINE_IDS.hunger, 'needs_stats_hunger_label', 'hunger')
    addNeedLine(LINE_IDS.thirst, 'needs_stats_thirst_label', 'thirst')
    addNeedLine(LINE_IDS.sleep, 'needs_stats_tiredness_label', 'sleep')
    addNeedLine(LINE_IDS.temperature, 'needs_stats_temperature_label', 'temperature')

    hasRegistered = true
    lastAppliedIndent = indentEnabled
    lastAppliedIntegrationEnabled = integrationEnabled
end

local function onLoad()
    hasRegistered = false
    lastAppliedIndent = nil
    lastAppliedIntegrationEnabled = nil
    registerStatsWindow()
end

return {
    engineHandlers = {
        onInit = registerStatsWindow,
        onLoad = onLoad,
        onUpdate = registerStatsWindow,
    },
}
