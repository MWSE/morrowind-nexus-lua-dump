local configPath = "Loot Notification"
local ch = require("BeefStranger.Loot Notifcation.configHelper")
local cfg = {
    dropdown = {},
    slider = {}
}

---@class bsLootNotif<K, V>: { [K]: V }
local defaults = {
    alpha = 0.45,
    maxNotify = 15,
    showDur = 5,
    xPos = 0,
    yPos = 0.45,
    obtainColor = ch.rgb.bsPrettyGreen,
    removeColor = ch.rgb.bsNiceRed,
    zeroColor = ch.rgb.bsGoodGrey
}


---@class bsLootNotif
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath })
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })

    cfg.slider.alpha = settings:createSlider({
        label = "Menu Background Alpha",
        min = 0, max = 1, step = 0.01, jump = 0.10, decimalPlaces = 2,
        variable = ch.tVar{ id ="alpha", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    cfg.slider.maxNotify = settings:createSlider({
        label = "Max Amount of Notifications Displayed at Once",
        min = 0, max = 25, step = 1, jump = 5,
        variable = ch.tVar{ id ="maxNotify", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    cfg.slider.showDur = settings:createSlider({
        label = "Duration to Show Notifications",
        min = 0, max = 30, step = 1, jump = 5,
        variable = ch.tVar{ id ="showDur", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    cfg.slider.xPos = settings:createSlider({
        label = "Menu position X",
        min = 0, max = 1, step = 0.01, jump = 0.05, decimalPlaces = 2,
        variable = ch.tVar{ id ="xPos", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    cfg.slider.yPos = settings:createSlider({
        label = "Menu position Y",
        min = 0, max = 1, step = 0.01, jump = 0.05, decimalPlaces = 2,
        variable = ch.tVar{ id ="yPos", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    cfg.dropdown.obtainColor = settings:createDropdown({
        label = "Item Obtained Color",
        options = ch.colorDropdown(),
        variable = ch.tVar{ id = "obtainColor", table = config},
        callback = function (self)
            ch.inspect(self.variable.value)
            self.elements.label.color = self.variable.value
        end,
        postCreate = function (self)
            self.elements.label.color = config.obtainColor
        end
    })

    cfg.dropdown.removeColor = settings:createDropdown({
        label = "Item Removed Color",
        options = ch.colorDropdown(),
        variable = ch.tVar{ id = "removeColor", table = config},
        callback = function (self)
            ch.inspect(self.variable.value)
            self.elements.label.color = self.variable.value
        end,
        postCreate = function (self)
            self.elements.label.color = config.removeColor
        end
    })

    cfg.dropdown.zeroColor = settings:createDropdown({
        label = "Item Removed Color",
        options = ch.colorDropdown(),
        variable = ch.tVar{ id = "zeroColor", table = config},
        callback = function (self)
            ch.inspect(self.variable.value)
            self.elements.label.color = self.variable.value
        end,
        postCreate = function (self)
            self.elements.label.color = config.zeroColor
        end
    })

    settings:createButton({
        buttonText = "Restore Default Settings",
        callback = function (self)
            for id, setting in pairs(cfg.slider) do
                cfg.restoreSliders(setting)
            end
            for id, setting in pairs(cfg.dropdown) do
                cfg.restoreDropdown(setting)
            end
            event.trigger("bsLootNotif")
        end
    })


    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)


---Add to configHelper?
---@param setting mwseMCMDropdown
function cfg.restoreDropdown(setting)
    for label, value in pairs(defaults) do
        config[label] = value
    end
    setting.elements.label.color = defaults[setting.variable.id]

    -----selectOption() literally does not function, simply will not work 
    -- for key, value in pairs(setting.options) do
    --     if value.value == defaults[setting.variable.id] then
    --         mwse.log("Selecting option for id: " .. setting.variable.id)
    --         mwse.log("Option label: " .. value.label)

    --         setting:selectOption(value)

    --         selected = true
    --         debug.log(selected)

    --     end
    --     if not selected then
    --         mwse.log("No matching option found for id: " .. setting.variable.id)
    --     elseif selected then
    --         mwse.log("updating")
    --         setting:selectOption(value)
    --         setting:update()
    --         selected = false
    --     end
    --     if selected then
    --         setting:selectOption(value)
    --     end
    -- end
    
end


---Add to configHelper?
---@param setting mwseMCMPercentageSlider|mwseMCMSlider
function cfg.restoreSliders(setting)
    for label, value in pairs(defaults) do
        config[label] = value
    end
    setting:updateValueLabel()
    setting:updateWidgetValue()
end

return config