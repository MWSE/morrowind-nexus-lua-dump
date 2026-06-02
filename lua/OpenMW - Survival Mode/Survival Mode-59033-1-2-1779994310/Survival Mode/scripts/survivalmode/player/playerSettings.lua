local M = {}

function M.create(deps)
    local hudSettings = assert(deps.hudSettings)
    local settingsSections = assert(deps.settingsSections)
    local playerConfig = assert(deps.playerConfig)
    local defaultHudPosition = assert(deps.defaultHudPosition)
    local normalizeKey = assert(deps.normalizeKey)
    local hbfsSettingKey = assert(deps.hbfsSettingKey)

    local api = {}

    function api.getHudPosition()
        local value = hudSettings:get('position')
        if value ~= nil then
            return value
        end
        return defaultHudPosition
    end

    function api.isHorizontal()
        local orientation = normalizeKey(tostring(hudSettings:get('iconOrientation') or ''))
        if orientation == 'horizontal' then
            return true
        end
        if orientation == 'vertical' then
            return false
        end

        local legacyValue = hudSettings:get('horizontal')
        if legacyValue == nil then
            return true
        end

        return legacyValue == true
    end

    function api.isHudEnabled()
        local value = hudSettings:get('enable')
        if value == nil then
            return true
        end

        return value
    end

    function api.getIconSizeValue()
        local value = hudSettings:get('iconSize')
        if value == nil then
            return tonumber(playerConfig.hud.defaultIconSize) or 32
        end

        return math.max(1, math.floor(value + 0.5))
    end

    function api.getIconSpacingValue()
        local value = hudSettings:get('iconSpacing')
        if value == nil then
            return tonumber(playerConfig.hud.defaultIconSpacing) or 4
        end

        return math.max(0, math.floor(value + 0.5))
    end

    function api.getHudOffsetX()
        local value = hudSettings:get('offsetX')
        if value == nil then
            return 0
        end

        return math.floor(value + 0.5)
    end

    function api.getHudOffsetY()
        local value = hudSettings:get('offsetY')
        if value == nil then
            return 0
        end

        return math.floor(value + 0.5)
    end

    function api.isRawValuesDebugEnabled()
        local value = settingsSections.debug:get('showRawValues')
        if value == nil then
            value = settingsSections.legacyDebug:get('showRawValues')
        end
        if value == nil then
            value = hudSettings:get('showRawValues')
        end
        if value == nil then
            return false
        end

        return value
    end

    function api.isOverlayEnabled(settingKey)
        local value = settingsSections.debug:get(settingKey)
        if value == nil then
            value = settingsSections.legacyDebug:get(settingKey)
        end
        if value == nil then
            value = hudSettings:get(settingKey)
        end
        if value == nil then
            return false
        end

        return value == true
    end

    function api.areProgressBarsEnabled()
        local value = hudSettings:get('showProgressBars')
        if value == nil then
            return false
        end

        return value
    end

    function api.isNeutralImagesSettingEnabled()
        local value = hudSettings:get('enableNeutralImages')
        if value == nil then
            return false
        end

        return value
    end

    function api.isThickerIconFrameEnabled()
        local value = hudSettings:get('enableThickerIconFrame')
        if value == nil then
            return false
        end

        return value
    end

    function api.isTemperatureEffectOverlayEnabled()
        local value = hudSettings:get('enableTemperatureEffectOverlay')
        if value == nil then
            return true
        end

        return value == true
    end

    function api.areStageMessagesEnabled()
        local value = hudSettings:get('enableStageMessages')
        if value == nil then
            return false
        end

        return value
    end

    function api.isHbfsDisableConjurationDrainEnabled()
        local value = settingsSections.debug:get(hbfsSettingKey)
        if value == nil then
            value = settingsSections.legacyDebug:get(hbfsSettingKey)
        end
        if value == nil then
            value = hudSettings:get(hbfsSettingKey)
        end
        if value == nil then
            return true
        end

        return value == true
    end

    function api.isSeasonalTemperatureVariationsEnabled()
        local value = settingsSections.gameplay:get('enableSeasonalTemperatureVariations')
        if value == nil then
            value = hudSettings:get('enableSeasonalTemperatureVariations')
        end
        if value == nil then
            return true
        end

        return value == true
    end

    function api.isTemperatureBasedHealthPenaltiesEnabled()
        local value = settingsSections.gameplay:get('enableTemperatureBasedHealthPenalties')
        if value == nil then
            value = hudSettings:get('enableTemperatureBasedHealthPenalties')
        end
        if value == nil then
            return true
        end

        return value == true
    end

    function api.isNeedSystemSettingEnabled(settingKey)
        local value = settingsSections.gameplay:get(settingKey)
        if value == nil then
            value = hudSettings:get(settingKey)
        end
        if value == nil then
            return true
        end
        return value == true
    end

    function api.isHungerSystemEnabled()
        return api.isNeedSystemSettingEnabled('enableHungerSystem')
    end

    function api.isThirstSystemEnabled()
        return api.isNeedSystemSettingEnabled('enableThirstSystem')
    end

    function api.isSleepSystemEnabled()
        return api.isNeedSystemSettingEnabled('enableSleepSystem')
    end

    function api.isTemperatureSystemEnabled()
        return api.isNeedSystemSettingEnabled('enableTemperatureSystem')
    end

    return api
end

return M
