local configUI = {}

configUI.getPackage = function(config)
    local package = {}
    local slider = nil
    local settingLabel = nil

    local function setSettingLabel()
        local value = slider.widget.current / 10
        settingLabel.text = string.format("Current Value: %.1f", value)
    end

    package.onCreate = function(container)
        container:createLabel({text = "Barter Gold Multiplier"})
        slider = container:createSlider({current=config.getBarterMul() * 10, max=100, step=1, jump=10})
        -- slider.setPropertyInt("width",200)
        slider.autoWidth = true
        slider.layoutWidthFraction = 1
        settingLabel = container:createLabel({text = "Temporary"})
        setSettingLabel()
        slider:register("PartScrollBar_changed", setSettingLabel)
    end

    package.onClose = function(container)
        local newValue = slider.widget.current / 10.0
        config.setBarterMul(newValue)
    end
    return package
end

return configUI