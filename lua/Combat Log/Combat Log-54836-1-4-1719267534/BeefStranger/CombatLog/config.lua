local configPath = "CombatLog"
local bs = require("BeefStranger.CombatLog.common")
local inspect = require("inspect").inspect

---@class bsCombatLog<K, V>: { [K]: V }
local defaults = {
    showPlayerName = false, --Log shows Player Name if true else just "You"
    alpha = 1,              --Transparency amount
    autoShow = true,        --If the menu will auto show on hit/attack
    autoDuration = 5,       --How long autoShow lasts if enabled
    showEffectName = false, --Show effect name in log
    enableMagic = true,     --Enable Magic Logging
    enableCombat = true,    --Enable physical combat logging
    showChance = true,      --Show hit chance %
    maxSaved = 100,         --Max number of messages to save
    color = {               --Colors for each element
        playerHit = bs.rgb.bsPrettyGreen,
        enemyHit = bs.rgb.bsNiceRed,
        blocked = bs.rgb.normalColor,
        reflect = bs.rgb.bsRoyalPurple,
        playerMiss = bs.rgb.bsLightGrey,
        enemyMiss = bs.rgb.focusColor,
        playerMagic = bs.rgb.bsPrettyBlue,
        enemyMagic = bs.rgb.bsNiceRed,
    },
    keycode = { --Keycode to trigger menu
        keyCode = tes3.scanCode.x,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
}

local colorName = {
    playerHit = "bsPrettyGreen",
    enemyHit = "bsNiceRed",
    blocked = "normalColor",
    reflect = "bsRoyalPurple",
    playerMiss = "bsLightGrey",
    enemyMiss = "focusColor",
    playerMagic = "bsPrettyBlue",
    enemyMagic = "bsNiceRed",
}




---From BeefLibrary
local function yesNoB(page, label, id, configTable, options)
    local optionTable = { ---@type mwseMCMYesNoButton
        label = label,
        variable = mwse.mcm.createTableVariable { id = id, table = configTable }
    }
    if options then
        for key, value in pairs(options) do
            optionTable[key] = value
        end
    end
    local yesNo = page:createYesNoButton(optionTable)
    return yesNo
end
---From BeefLibrary
local function templateM(configsPath)
    local mcmTemplate = mwse.mcm.createTemplate({ name = configsPath })
    return mcmTemplate
end
local time ---@type mwseTimer

local function alpha()
    mwse.log("Callback")
    event.trigger("combatLog:showMenu", {visible = true})
    if time then
        mwse.log("Resetting timer")
        time:reset()
    else
        time = timer.start {
            duration = 10,
            type = timer.real,
            callback = function()
                local menu = tes3ui.findMenu("bsCombatLog")
                mwse.log(menu)
                if menu and menu.visible then
                    menu.visible = false
                end
                mwse.log("Timer Done")
            end
        }
    end
end
--------------------Color Setup------------------------------
local function colorTable()
    local colorsOptions = {}
    for name, color in pairs(bs.rgb) do                              --Take every value in rgb table
        table.insert(colorsOptions, { label = name, value = color }) --Make in format for dropDown
    end
    table.sort(colorsOptions, function(a, b)                         --Sort table from A-Z
        return a.label < b.label
    end)
    return colorsOptions --Return the table
end
-------------------Get Colors Name from table------------------------
local function getColorsName(colorValue)
    local colorsName = {}
    --Convert each value into a string
    local function convStr(v)
        return string.format("%.3f, %.3f, %.3f", v[1], v[2], v[3])
    end
    local colorString = convStr(colorValue) --Send colorValue param to convStr
    for k, v in pairs(bs.rgb) do
        local color = convStr(v)            --Convert color table into string
        colorsName[color] = k               --Add color table string to table as key, and add key from rgb as value
    end
    return colorsName[colorString]          --Lookup name of color, based on color table, converted to string
end
----------------------------------------------------
---For loop through children and update colors maybe

local function rgbToString(rgb)
    return string.format("{%f, %f, %f}", rgb[1], rgb[2], rgb[3])
end

---@class bsCombatLog
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = templateM(configPath)

    local settings = template:createPage({ label = "Settings" })

    local toggle = settings:createCategory { paddingBottom = 10, }
    yesNoB(toggle, "Use Players Name in Combat Log", "showPlayerName", config)
    yesNoB(toggle, "Show Effect Name in Combat Log", "showEffectName", config)
    yesNoB(toggle, "Show Hit Chance", "showChance", config)
    yesNoB(toggle, "Enable Auto Show Mode", "autoShow", config)
    yesNoB(toggle, "Enable Magic Logging", "enableMagic", config)
    yesNoB(toggle, "Enable Combat Logging", "enableCombat", config)

    toggle:createSlider({
        variable = mwse.mcm.createTableVariable { id = "autoDuration", table = config },
        label = "Auto Show Time",
        min = 1, max = 60, step = 1, jump = 5,
    })
    ---------------------------------------------------------------------------------

    -----------------------------------Slider-----------------------------------
    settings:createSlider({
        variable = mwse.mcm.createTableVariable { id = "alpha", table = config },
        label = "Transparency",
        min = 0, max = 1, step = 0.01, jump = 0.1, decimalPlaces = 2,
        callback = alpha
    })

    settings:createSlider({
        variable = mwse.mcm.createTableVariable { id = "maxSaved", table = config },
        label = "Max Amount of Messages to Save",
        min = 1, max = 500, step = 10, jump = 50,
    })
    -----------------------------------End Slider-----------------------------------

    settings:createButton({
        buttonText = "Reset Log Position",
        callback = function(self) event.trigger("combatLog:showMenu", {visible = true, resetPos = true}) end
    })

    settings:createKeyBinder({
        label = "Assign Keybind",
        description = "Assign a new keybind.",
        variable = mwse.mcm.createTableVariable { id = "keycode", table = config },
        allowCombinations = false,
    })

    local colors = template:createPage { label = "Colors" }

    --------------------------------DropDown Menus--------------------------------
    local dropOptions = {   --All the different dropdown Options
        playerHit = "Player Hit",
        enemyHit = "Enemy Hit",
        blocked = "Blocked",
        playerMiss = "Player Missed",
        enemyMiss = "Enemy Missed",
        playerMagic = "Player Magic",
        enemyMagic = "Enemy Magic",
        reflect = "Magic Reflected",
    }
    local dropdowns = {} ---@type table|mwseMCMDropdown Where Dropdowns are saved for later access

    --Auto make labels text for color dropdowns
    local function labelText(id, label)
        local selected = getColorsName(config.color[id])
        return string.format("%s : %s", label, selected)
    end

    for id, label in pairs(dropOptions) do
        dropdowns[id] = colors:createDropdown {
            label = label,
            options = colorTable(),
            variable = mwse.mcm.createTableVariable { id = id, table = config.color },
            callback = function(self)
                self.elements.label.color = self.variable.value --Update Label to match selected color
                self.elements.label.text = labelText(id, label)
                event.trigger("combatLog:showMenu", { visible = true })
                -- debug.log(self:convertToLabelValue(self.variable.value))
            end,
            postCreate = function(self)
                self.elements.label.color = config.color[id] --Make sure label matches color when its created
                self.elements.label.text = labelText(id, label)
                -- debug.log(getColorsName(config.color[id]))
            end
        }

        colors:createInfo({
            label = "Default : " .. getColorsName(defaults.color[id]),
            postCreate = function(self)
                self.elements.label.color = defaults.color[id]
            end
        })
    end
    --------------------------------End DropDown Menus--------------------------------
    ---Button to show the log
    -- colors:createButton({
    --     buttonText = "Show Log",
    --     callback = function(self) event.trigger("combatLog:showMenu", {visible = true}) end
    -- })
    ---Button to set all colors to default
    colors:createButton({
        -- label = "Show Log",
        buttonText = "Restore Default Colors",
        callback = function(self)
            -- mwse.log("before %s", inspect(config.color))
            ---Get every id and its corresponding color to update the config to the defaults
            for id, color in pairs(defaults.color) do
                config.color[id] = color
                dropdowns[id].elements.label.color = color
            end
            event.trigger("combatLog:showMenu", {visible = true}) ---Refresh the log to show current colors
        end
    })

    ---Hide and clear the menu on close
    template.onClose = function (modConfigContainer)
        mwse.log("on close---------------------------------")
        event.trigger("combatLog:showMenu", {visible = false})

        mwse.saveConfig(configPath, config)
    end
    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config
