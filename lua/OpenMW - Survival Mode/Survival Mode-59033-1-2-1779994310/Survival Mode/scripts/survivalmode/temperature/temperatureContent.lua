local M = {}

function M.createDebugConfig(deps)
    local util = assert(deps.util)
    local temperatureBalanceConfig = assert(deps.temperatureBalanceConfig)
    local temperature = deps.temperature

    local config = {
        settingKey = 'enableTemperatureDebugOverlay',
        textSize = 12,
        lineHeight = 14,
        textWidth = 320,
        spacing = 4,
        textColor = util.color.rgb(0, 1, 0),
        modifierLabels = {
            region = 'Region Modifier',
            interior_base = 'Interior Base Temperature',
            cell = 'Cell Modifier',
            campfire = 'Campfire Modifier',
            weather = 'Weather Modifier',
            well_hydrated = 'Well Hydrated',
            wetness = 'Wetness Modifier',
            armor = 'Armor Modifier',
            clothing = 'Clothing Modifier',
        },
        modifierOrder = {
            'region',
            'interior_base',
            'cell',
            'campfire',
            'weather',
            'well_hydrated',
            'wetness',
            'armor',
            'clothing',
        },
        weatherModifiers = temperatureBalanceConfig.weatherModifiers,
        weathermultiplier = temperatureBalanceConfig.weathermultiplier,
        interiorRegionmultiplier = temperatureBalanceConfig.interiorRegionmultiplier,
        weathermultiplierRequiresDecreasing = {
            rain = true,
            thunder = true,
            snow = true,
            blizzard = true,
        },
        weathermultiplierRequiresIncreasing = {
            ash_storm = true,
            blight = true,
        },
        clothingWarmth = temperatureBalanceConfig.clothingWarmth,
        robeWarmthByRegion = temperatureBalanceConfig.robeWarmthByRegion,
        robeArmorWarmthMultiplierByRegion = temperatureBalanceConfig.robeArmorWarmthMultiplierByRegion,
        robeMediumArmorWarmthMultiplierByRegion = temperatureBalanceConfig.robeMediumArmorWarmthMultiplierByRegion,
        interiorArmorWarmthMultiplierByRegion = temperatureBalanceConfig.interiorArmorWarmthMultiplierByRegion,
        heavyArmorWarmthByRegion = temperatureBalanceConfig.armorWarmthByRegion.heavy,
        lightArmorWarmthByRegion = temperatureBalanceConfig.armorWarmthByRegion.light,
        mediumArmorWarmthByRegion = temperatureBalanceConfig.armorWarmthByRegion.medium,
        armorWeightClassBySlot = (function()
            if temperature ~= nil
                and type(temperature.config) == 'table'
                and type(temperature.config.getArmorWeightClassBySlot) == 'function' then
                local ok, value = pcall(temperature.config.getArmorWeightClassBySlot)
                if ok and type(value) == 'table' then
                    return value
                end
            end

            return {
                boots = { lightMax = 12.0, heavyMinExclusive = 18.0 },
                cuirass = { lightMax = 18.0, heavyMinExclusive = 27.0 },
                greaves = { lightMax = 9.0, heavyMinExclusive = 13.5 },
                helmet = { lightMax = 3.0, heavyMinExclusive = 4.5 },
                gauntlet = { lightMax = 3.0, heavyMinExclusive = 4.5 },
                pauldron = { lightMax = 6.0, heavyMinExclusive = 9.0 },
            }
        end)(),
    }

    assert(type(config.heavyArmorWarmthByRegion) == 'table',
        '[SurvivalMode] temperatureBalanceConfig.armorWarmthByRegion.heavy must be a table.')
    assert(type(config.lightArmorWarmthByRegion) == 'table',
        '[SurvivalMode] temperatureBalanceConfig.armorWarmthByRegion.light must be a table.')
    assert(type(config.mediumArmorWarmthByRegion) == 'table',
        '[SurvivalMode] temperatureBalanceConfig.armorWarmthByRegion.medium must be a table.')
    assert(type(temperatureBalanceConfig.campfire) == 'table',
        '[SurvivalMode] temperatureBalanceConfig.campfire must be a table.')
    assert(type(temperatureBalanceConfig.regionTransition) == 'table',
        '[SurvivalMode] temperatureBalanceConfig.regionTransition must be a table.')
    assert(
        tonumber(temperatureBalanceConfig.campfire.cellInfoRequestIntervalSeconds) ~= nil,
        '[SurvivalMode] temperatureBalanceConfig.campfire.cellInfoRequestIntervalSeconds must be a number.'
    )
    assert(type(temperatureBalanceConfig.wellHydrated) == 'table',
        '[SurvivalMode] temperatureBalanceConfig.wellHydrated must be a table.')
    assert(
        tonumber(temperatureBalanceConfig.wellHydrated.positiveHeatTargetMultiplier) ~= nil,
        '[SurvivalMode] temperatureBalanceConfig.wellHydrated.positiveHeatTargetMultiplier must be a number.'
    )
    assert(type(temperatureBalanceConfig.clothingWarmth) == 'table',
        '[SurvivalMode] temperatureBalanceConfig.clothingWarmth must be a table.')
    assert(
        tonumber(temperatureBalanceConfig.clothingWarmth.default) ~= nil,
        '[SurvivalMode] temperatureBalanceConfig.clothingWarmth.default must be a number.'
    )
    assert(
        tonumber(temperatureBalanceConfig.clothingWarmth.glovesOrShoes) ~= nil,
        '[SurvivalMode] temperatureBalanceConfig.clothingWarmth.glovesOrShoes must be a number.'
    )
    assert(
        tonumber(temperatureBalanceConfig.clothingWarmth.robe) ~= nil,
        '[SurvivalMode] temperatureBalanceConfig.clothingWarmth.robe must be a number.'
    )

    return config
end

function M.createTemperaturemultiplier()
    return {
        active = false,
        source = '',
        targetTemperature = nil,
        direction = 0,
        multiplier = 1.0,
    }
end

function M.hydrateTemperaturemultiplier(savedmultiplier)
    local multiplier = M.createTemperaturemultiplier()
    if type(savedmultiplier) ~= 'table' then
        return multiplier
    end

    multiplier.active = savedmultiplier.active == true
    local sourceText = tostring(savedmultiplier.source or '')
    multiplier.source = string.lower(sourceText:match('^%s*(.-)%s*$'))
    multiplier.targetTemperature = tonumber(savedmultiplier.targetTemperature)
    local direction = tonumber(savedmultiplier.direction) or 0
    if direction > 0 then
        multiplier.direction = 1
    elseif direction < 0 then
        multiplier.direction = -1
    else
        multiplier.direction = 0
    end
    multiplier.multiplier = math.max(1.0, tonumber(savedmultiplier.multiplier) or 1.0)
    return multiplier
end

function M.getTemperatureHealthDrainProfile(temperatureValue, temperatureStage, deps)
    local clamp = assert(deps.clamp)
    local temperature = deps.temperature
    local stage = temperatureStage
    if type(stage) ~= 'table'
        and temperature ~= nil
        and type(temperature.system) == 'table'
        and type(temperature.system.getStageByValue) == 'function' then
        stage = temperature.system.getStageByValue(temperatureValue)
    end
    if type(stage) ~= 'table' then
        return 0, 0
    end

    local drainPerSecond = math.max(0, tonumber(stage.healthDrainPerSecond) or 0)
    if drainPerSecond <= 0 then
        return 0, 0
    end

    local stageId = string.lower(tostring(stage.id or ''))
    local value = tonumber(temperatureValue) or 0
    if temperature ~= nil
        and type(temperature.system) == 'table'
        and type(temperature.system.getEffectiveStageTemperature) == 'function' then
        value = temperature.system.getEffectiveStageTemperature(value)
    end

    local stageMin = tonumber(stage.min)
    local stageMax = tonumber(stage.max)
    local stageProgress = nil
    if stageMin ~= nil and stageMax ~= nil and stageMax > stageMin then
        if value < 0 then
            stageProgress = (stageMax - value) / (stageMax - stageMin)
        else
            stageProgress = (value - stageMin) / (stageMax - stageMin)
        end
        stageProgress = clamp(stageProgress, 0, 1)
    end

    if stageId == 'scorching' then
        if stageProgress ~= nil then
            if value >= stageMax then
                return 75, drainPerSecond
            end
            if stageProgress >= 0.75 then
                return 50, drainPerSecond
            end
            if stageProgress >= 0.25 then
                return 25, drainPerSecond
            end
            return 0, drainPerSecond
        end

        if value >= 400 then
            return 75, drainPerSecond
        end
        if value >= 375 then
            return 50, drainPerSecond
        end
        if value >= 325 then
            return 25, drainPerSecond
        end
        return 0, drainPerSecond
    end
    if stageId == 'very_cold' then
        if stageProgress ~= nil then
            if stageProgress >= 0.75 then
                return 50, drainPerSecond
            end
            return 25, drainPerSecond
        end

        if value <= -275 then
            return 50, drainPerSecond
        end
        return 25, drainPerSecond
    end
    if stageId == 'freezing' then
        if stageProgress ~= nil then
            if value <= stageMin then
                return 95, drainPerSecond
            end
            if stageProgress >= 0.75 then
                return 90, drainPerSecond
            end
            return 75, drainPerSecond
        end

        if value <= -400 then
            return 95, drainPerSecond
        end
        if value <= -375 then
            return 90, drainPerSecond
        end
        return 75, drainPerSecond
    end

    local minLossPct = clamp(tonumber(stage.healthDrainMinLossPct) or 0, 0, 100)
    local maxLossPct = clamp(
        tonumber(stage.healthDrainMaxLossPct) or minLossPct,
        minLossPct,
        100
    )
    if maxLossPct <= minLossPct then
        return maxLossPct, drainPerSecond
    end

    if stageProgress == nil then
        return maxLossPct, drainPerSecond
    end

    local interpolated = minLossPct + ((maxLossPct - minLossPct) * stageProgress)
    return math.floor(interpolated + 0.5), drainPerSecond
end

function M.getTemperatureHealthLossPct(temperatureValue, temperatureStage, deps)
    local healthLossPct = M.getTemperatureHealthDrainProfile(temperatureValue, temperatureStage, deps)
    return healthLossPct
end

function M.resolveDisplayHealthLossPct(stage, healthLossPct, isTemperatureBasedHealthPenaltiesEnabled)
    local stageId = string.lower(tostring(stage ~= nil and stage.id or ''))
    local lossPct = math.max(0, math.floor(tonumber(healthLossPct) or 0))

    if type(isTemperatureBasedHealthPenaltiesEnabled) == 'function'
        and not isTemperatureBasedHealthPenaltiesEnabled() then
        return 0
    end

    if stageId == 'hot' then
        if lossPct >= 25 then
            return 25
        end
        return 0
    elseif stageId == 'scorching' then
        if lossPct >= 75 then
            return 75
        elseif lossPct >= 50 then
            return 50
        elseif lossPct >= 25 then
            return 25
        end
        return 0
    elseif stageId == 'chilly' then
        return 0
    elseif stageId == 'cold' then
        if lossPct >= 25 then
            return 25
        end
        return 0
    elseif stageId == 'very_cold' then
        if lossPct >= 50 then
            return 50
        end
        return 25
    elseif stageId == 'freezing' then
        if lossPct >= 95 then
            return 95
        elseif lossPct >= 90 then
            return 90
        end
        return 75
    end

    return lossPct
end

function M.appendDynamicEffectsForStage(effects, stage, deps)
    local getHealthLossPct = assert(deps.getHealthLossPct)
    local isTemperatureBasedHealthPenaltiesEnabled = assert(deps.isTemperatureBasedHealthPenaltiesEnabled)

    local weaknessFirePct = tonumber(stage.weaknessFirePct) or 0
    if weaknessFirePct > 0 then
        effects[#effects + 1] = {
            id = 'weaknesstofire',
            magnitudeMin = weaknessFirePct,
            magnitudeMax = weaknessFirePct,
            duration = 0,
            range = 'self',
        }
    end

    local weaknessFrostPct = tonumber(stage.weaknessFrostPct) or 0
    if weaknessFrostPct > 0 then
        effects[#effects + 1] = {
            id = 'weaknesstofrost',
            magnitudeMin = weaknessFrostPct,
            magnitudeMax = weaknessFrostPct,
            duration = 0,
            range = 'self',
        }
    end

    local hungerIncreasePct = tonumber(stage.hungerIncreasePct) or 0
    local thirstIncreasePct = tonumber(stage.thirstIncreasePct) or 0
    local slownessPct = tonumber(stage.slownessPct) or 0
    if hungerIncreasePct > 0 then
        effects[#effects + 1] = {
            id = 'sn_tmp_penalty_hunger_display',
            magnitudeMin = 0,
            magnitudeMax = 0,
            duration = 0,
            range = 'self',
        }
    end
    if thirstIncreasePct > 0 then
        effects[#effects + 1] = {
            id = 'sn_tmp_penalty_thirst_display',
            magnitudeMin = 0,
            magnitudeMax = 0,
            duration = 0,
            range = 'self',
        }
    end
    if slownessPct > 0 then
        effects[#effects + 1] = {
            id = 'sn_tmp_penalty_slowness_display',
            magnitudeMin = 0,
            magnitudeMax = 0,
            duration = 0,
            range = 'self',
        }
    end
    local displayHealthLossPct = M.resolveDisplayHealthLossPct(
        stage,
        getHealthLossPct(),
        isTemperatureBasedHealthPenaltiesEnabled
    )
    if displayHealthLossPct > 0 then
        effects[#effects + 1] = {
            id = 'sn_tmp_penalty_health_display',
            magnitudeMin = 0,
            magnitudeMax = 0,
            duration = 0,
            range = 'self',
        }
    end
end

function M.resolveSpellName(stage, normalizedCategory, temperatureMiscVariant, deps)
    local core = assert(deps.core)
    local healthLossPct = tonumber(deps.healthLossPct) or 0
    local isTemperatureBasedHealthPenaltiesEnabled = assert(deps.isTemperatureBasedHealthPenaltiesEnabled)
    local spellName = type(stage.spellName) == 'string' and stage.spellName or nil
    local stageVariantId = nil

    if normalizedCategory == 'temperature_weakness' then
        return stage.weaknessSpellName or spellName, nil
    end

    if temperatureMiscVariant ~= nil then
        local displayHealthLossPct = M.resolveDisplayHealthLossPct(
            stage,
            healthLossPct,
            isTemperatureBasedHealthPenaltiesEnabled
        )
        local hungerIncreasePct = tonumber(stage.hungerIncreasePct) or 0
        local thirstIncreasePct = tonumber(stage.thirstIncreasePct) or 0
        local slownessPct = tonumber(stage.slownessPct) or 0
        local stageName = type(stage.spellName) == 'string' and stage.spellName or ''
        local value = 0
        local fallbackKey = nil

        if temperatureMiscVariant == 'hunger' and hungerIncreasePct > 0 then
            value = hungerIncreasePct
            fallbackKey = 'temperature_penalty_increased_hunger'
        elseif temperatureMiscVariant == 'thirst' and thirstIncreasePct > 0 then
            value = thirstIncreasePct
            fallbackKey = 'temperature_penalty_increased_thirst'
        elseif temperatureMiscVariant == 'slowness' and slownessPct > 0 then
            value = slownessPct
            fallbackKey = 'temperature_penalty_slowness'
        elseif temperatureMiscVariant == 'health' and displayHealthLossPct > 0 then
            value = displayHealthLossPct
            fallbackKey = 'temperature_penalty_reduced_health'
            if type(stage.id) == 'string' and stage.id ~= '' then
                stageVariantId = string.format('%s_%s_hp%d', stage.id, normalizedCategory, displayHealthLossPct)
            end
        end

        if fallbackKey ~= nil then
            if stageName ~= '' then
                return string.format('%s: %d%%', stageName, math.floor((tonumber(value) or 0) + 0.5)), stageVariantId
            end
            return core.l10n('SurvivalMode', 'en')(fallbackKey, { value = value }), stageVariantId
        end

        return nil, stageVariantId
    end

    if type(stage.spellNames) == 'table' then
        local variantSpellName = stage.spellNames[normalizedCategory]
        if type(variantSpellName) == 'string' and variantSpellName ~= '' then
            return variantSpellName, nil
        end
    end

    return spellName, nil
end

function M.shouldIncludeEffect(effectId, includeWeaknessEffects, miscVariant)
    local isWeaknessEffect = effectId == 'weaknesstofire' or effectId == 'weaknesstofrost'
    if includeWeaknessEffects and isWeaknessEffect then
        return true
    end
    if miscVariant ~= nil and not isWeaknessEffect then
        if miscVariant == 'hunger' then
            return effectId == 'sn_tmp_penalty_hunger_display'
        elseif miscVariant == 'thirst' then
            return effectId == 'sn_tmp_penalty_thirst_display'
        elseif miscVariant == 'slowness' then
            return effectId == 'sn_tmp_penalty_slowness_display'
        elseif miscVariant == 'health' then
            return effectId == 'sn_tmp_penalty_health_display'
        end
        return true
    end
    return not includeWeaknessEffects and miscVariant == nil
end

function M.buildDynamicSpellSignature(spellName, effects, deps)
    local trim = assert(deps.trim)
    local normalizeKey = assert(deps.normalizeKey)
    local parts = { trim(tostring(spellName or '')) }
    if type(effects) == 'table' then
        for _, effect in ipairs(effects) do
            if type(effect) == 'table' then
                parts[#parts + 1] = table.concat({
                    normalizeKey(effect.id),
                    normalizeKey(effect.affectedAttribute),
                    normalizeKey(effect.affectedSkill),
                    tostring(tonumber(effect.magnitudeMin) or 0),
                    tostring(tonumber(effect.magnitudeMax) or 0),
                    tostring(tonumber(effect.duration) or 0),
                    normalizeKey(effect.range),
                }, ':')
            end
        end
    end
    local hash = 0
    local text = table.concat(parts, '|')
    for index = 1, #text do
        hash = ((hash * 33) + string.byte(text, index)) % 2147483647
    end
    return tostring(hash)
end

return M
