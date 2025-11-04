local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("messageBox.config")
local log = mwse.Logger.new()
local box = require("messageBox.box")
local func = require("messageBox.common")

local modName = 'Message Box';
local template = EasyMCM.createTemplate { name = modName }
template:saveOnClose(modName, config)
template:register()



local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "                          [Message Box] \n\n" .. func.i18n("msgBox.mcm.description")
    }
    page.sidebar:createHyperLink {
        text = "Made by Kleidium",
        exec = "start https://www.nexusmods.com/users/5374229?tab=user+files",
        postCreate = function(self)
            self.elements.outerContainer.borderAllSides = self.indent
            self.elements.outerContainer.alignY = 1.0
            self.elements.info.layoutOriginFractionX = 0.5
        end,
    }
    return page
end

local settings = createPage(func.i18n("msgBox.mcm.generalSettings"))
local cPage = createPage(func.i18n("msgBox.mcm.colorSettings"))
local iPage = createPage(func.i18n("msgBox.mcm.interopSettings"))



----Global Settings-------------------------------------------------------------------------------------------------------------------------
local cdSettings = settings:createCategory(func.i18n("msgBox.mcm.generalSettings"))

cdSettings:createTextField {
    label = func.i18n("msgBox.mcm.initialWidth"),
    description = func.i18n("msgBox.mcm.initialWidthDescription"),
    variable = mwse.mcm.createTableVariable { id = "width", table = config },
    numbersOnly = true,
    callback = function(self)
        if box.menu then
            if tonumber(self.variable.value) < 237 then
                self.variable.value = "237"
                tes3.messageBox(func.i18n("msgBox.mcm.initialWidthAlert"))
            end
            if config.minSize then
                box.menu.minWidth = tonumber(self.variable.value)
            else
                box.menu.minWidth = 237
            end
            box.menu.width = tonumber(self.variable.value)
            box.pane.width = tonumber(self.variable.value) - 100
            box.menu:updateLayout()
        end
        tes3.messageBox("" .. func.i18n("msgBox.mcm.width") .. ": " .. self.variable.value)
    end
}

cdSettings:createTextField {
    label = func.i18n("msgBox.mcm.initialHeight"),
    description = func.i18n("msgBox.mcm.initialHeightDescription"),
    variable = mwse.mcm.createTableVariable { id = "height", table = config },
    numbersOnly = true,
    callback = function(self)
        if box.menu then
            if tonumber(self.variable.value) < 87 then
                self.variable.value = "87"
                tes3.messageBox(func.i18n("msgBox.mcm.initialHeightAlert"))
            end
            if config.minSize then
                box.menu.minHeight = tonumber(self.variable.value)
            else
                box.menu.minHeight = 87
            end
            box.menu.height = tonumber(self.variable.value)
            box.pane.height = tonumber(self.variable.value) - 50
            box.menu:updateLayout()
        end
        tes3.messageBox("" .. func.i18n("msgBox.mcm.height") .. ": " .. self.variable.value)
    end
}

cdSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.initialSizeIsMinimum"),
    description = func.i18n("msgBox.mcm.initialSizeIsMinimumDescription"),
    variable = mwse.mcm.createTableVariable { id = "minSize", table = config },
    callback = function(self)
        if box.menu then
            if self.variable.value then
                box.menu.minHeight = tonumber(config.height)
                box.menu.minWidth = tonumber(config.width)
            else
                box.menu.minHeight = 87
                box.menu.minWidth = 237
            end
            box.menu:updateLayout()
        end
    end
}

cdSettings:createSlider {
    label = func.i18n("msgBox.mcm.boxOpacity"),
    description = func.i18n("msgBox.mcm.boxOpacityDescription"),
    min = 0.0,
    max = 1.0,
    step = 0.1,
    jump = 0.2,
    decimalPlaces = 1,
    variable = EasyMCM:createTableVariable {
        id = "alpha",
        table = config
    },
    restartRequired = true
}

cdSettings:createDropdown {
    label = func.i18n("msgBox.mcm.initialPosition"),
    description = func.i18n("msgBox.mcm.initialPositionDescription"),
    options = {
        { label = func.i18n("msgBox.mcm.initialPositionTop"), value = "top" },
        { label = func.i18n("msgBox.mcm.initialPositionBottom"), value = "bottom" },
        { label = func.i18n("msgBox.mcm.initialPositionTopLeft"), value = "tLeft" },
        { label = func.i18n("msgBox.mcm.initialPositionTopRight"), value = "tRight" },
    },
    variable = mwse.mcm.createTableVariable { id = "position", table = config }
}

cdSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.vanillaPopups"),
    description = func.i18n("msgBox.mcm.vanillaPopupsDescription"),
    variable = mwse.mcm.createTableVariable { id = "notify", table = config }
}

cdSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.messageTimer"),
    description = func.i18n("msgBox.mcm.messageTimerDescription"),
    variable = mwse.mcm.createTableVariable { id = "msgTimer", table = config },
    restartRequired = true
}

cdSettings:createSlider {
    label = func.i18n("msgBox.mcm.messageTime"),
    description = func.i18n("msgBox.mcm.messageTimeDescription"),
    max = 300,
    min = 3,
	jump = 5,
	step = 1,
    variable = EasyMCM:createTableVariable {
        id = "msgTime",
        table = config
    }
}

cdSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.olderMessages"),
    description = func.i18n("msgBox.mcm.olderMessagesDescription"),
    variable = mwse.mcm.createTableVariable { id = "msgLimit", table = config }
}

cdSettings:createTextField {
    label = func.i18n("msgBox.mcm.messageLimit"),
    description = func.i18n("msgBox.mcm.messageLimitDescription"),
    variable = mwse.mcm.createTableVariable { id = "maxMessages", table = config },
    numbersOnly = true
}

cdSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.showTimestamp"),
    description = func.i18n("msgBox.mcm.showTimestampDescription"),
    variable = mwse.mcm.createTableVariable { id = "timeStamp", table = config }
}

cdSettings:createDropdown {
    label = func.i18n("msgBox.mcm.timestampFormat"),
    description = func.i18n("msgBox.mcm.timestampDescription"),
    options = {
        { label = func.i18n("msgBox.mcm.timestampFormat24Seconds"), value = "%X" },
        { label = func.i18n("msgBox.mcm.timestampFormat24"), value = "%H:%M" },
		{ label = func.i18n("msgBox.mcm.timestampFormat12Seconds"), value = "%I:%M:%S" },
		{ label = func.i18n("msgBox.mcm.timestampFormat12"), value = "%I:%M" },
    },
    variable = mwse.mcm.createTableVariable { id = "timeFormat", table = config }
}

cdSettings:createSlider {
    label = func.i18n("msgBox.mcm.messageOffset"),
    description = func.i18n("msgBox.mcm.messageOffsetDescription"),
    max = 10,
    min = 0,
	jump = 2,
	step = 1,
    variable = EasyMCM:createTableVariable {
        id = "msgOffset",
        table = config
    }
}

cdSettings:createKeyBinder {
    label = func.i18n("msgBox.mcm.messageBoxHotkey"),
    description = func.i18n("msgBox.mcm.messageBoxHotkeyDescription"),
    variable = mwse.mcm.createTableVariable { id = "boxBind", table = config },
    allowCombinations = true
}

cdSettings:createTextField {
    label = func.i18n("msgBox.mcm.boxTitle"),
    description = func.i18n("msgBox.mcm.boxTitleDescription"),
    variable = mwse.mcm.createTableVariable { id = "titleText", table = config },
	restartRequired = true
}

cdSettings:createTextField {
    label = func.i18n("msgBox.mcm.highlightedPhrase"),
    description = func.i18n("msgBox.mcm.highlightedPhraseDescription"),
    variable = mwse.mcm.createTableVariable { id = "highText", table = config }
}

cdSettings:createTextField {
    label = func.i18n("msgBox.mcm.filteredPhrase"),
    description = func.i18n("msgBox.mcm.filteredPhraseDescription"),
    variable = mwse.mcm.createTableVariable { id = "filterText", table = config }
}

cdSettings:createDropdown {
    label = func.i18n("msgBox.mcm.debugLevel"),
    description = func.i18n("msgBox.mcm.debugLevelDescription"),
    options = {
        { label = func.i18n("msgBox.mcm.logLevelTRACE"), value = "TRACE" },
        { label = func.i18n("msgBox.mcm.logLevelDEBUG"), value = "DEBUG" },
        { label = func.i18n("msgBox.mcm.logLevelINFO"), value = "INFO" },
        { label = func.i18n("msgBox.mcm.logLevelERROR"), value = "ERROR" },
        { label = func.i18n("msgBox.mcm.logLevelNONE"), value = "NONE" },
    },
    variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
    callback = function(self)
        log.level = self.variable.value
    end
}


local logSettings = settings:createCategory(func.i18n("msgBox.mcm.logSettings"))

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.explorationLogging"),
    description = func.i18n("msgBox.mcm.explorationLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "cellLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.questLogging"),
    description = func.i18n("msgBox.mcm.questLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "questLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.chatLogging"),
    description = func.i18n("msgBox.mcm.chatLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "chatLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.topicLogging"),
    description = func.i18n("msgBox.mcm.topicLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "showTopic", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.barterLogging"),
    description = func.i18n("msgBox.mcm.barterLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "barterLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.buyLogging"),
    description = func.i18n("msgBox.mcm.buyLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "buyLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.sellLogging"),
    description = func.i18n("msgBox.mcm.sellLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "sellLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.dropLogging"),
    description = func.i18n("msgBox.mcm.dropLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "dropLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.grabLogging"),
    description = func.i18n("msgBox.mcm.grabLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "grabLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.combatLogging"),
    description = func.i18n("msgBox.mcm.combatLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "dmgLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.hitLogging"),
    description = func.i18n("msgBox.mcm.hitLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "hitLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.castLogging"),
    description = func.i18n("msgBox.mcm.castLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "castLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.cChanceLogging"),
    description = func.i18n("msgBox.mcm.cChanceLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "cChanceLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.resistLogging"),
    description = func.i18n("msgBox.mcm.resistLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "resistLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.useLogging"),
    description = func.i18n("msgBox.mcm.useLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "useLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.deathLogging"),
    description = func.i18n("msgBox.mcm.deathLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "deathLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.musicLogging"),
    description = func.i18n("msgBox.mcm.musicLoggingDescription"),
    variable = mwse.mcm.createTableVariable { id = "musicLog", table = config }
}

logSettings:createOnOffButton {
    label = func.i18n("msgBox.mcm.showFullPath"),
    description = func.i18n("msgBox.mcm.showFullPathDescription"),
    variable = mwse.mcm.createTableVariable { id = "musicPath", table = config }
}


--Colors----------------------------------------------------------------------------------------------------------------------------------------------------------------------
local cSettings = cPage:createCategory(func.i18n("msgBox.mcm.defaultColor")) --White

-- Helper: create three RGB sliders for a category.
local function createRGBSliders(category, configIdBase, labelBase, descBase)
    descBase = descBase or ("message box " .. labelBase:lower())
    category:createSlider {
        label = labelBase .. ": " .. func.i18n("msgBox.mcm.red") .. "",
        description = "" .. func.i18n("msgBox.mcm.rgbRED") .. " " .. descBase .. ".",
        max = 1.00,
        min = 0.00,
        jump = 0.10,
        step = 0.01,
        decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable {
            id = configIdBase .. "Red",
            table = config
        }
    }
    category:createSlider {
        label = labelBase .. ": " .. func.i18n("msgBox.mcm.green") .. "",
        description = "" .. func.i18n("msgBox.mcm.rgbGREEN") .. " " .. descBase .. ".",
        max = 1.00,
        min = 0.00,
        jump = 0.10,
        step = 0.01,
        decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable {
            id = configIdBase .. "Green",
            table = config
        }
    }
    category:createSlider {
        label = labelBase .. ": " .. func.i18n("msgBox.mcm.blue") .. "",
        description = "" .. func.i18n("msgBox.mcm.rgbBLUE") .. " " .. descBase .. ".",
        max = 1.00,
        min = 0.00,
        jump = 0.10,
        step = 0.01,
        decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable {
            id = configIdBase .. "Blue",
            table = config
        }
    }
end

createRGBSliders(cSettings, "text", func.i18n("msgBox.mcm.defaultColor"), func.i18n("msgBox.mcm.defaultColorDescription"))

local hSettings = cPage:createCategory(func.i18n("msgBox.mcm.highlightedColor")) --Magenta
createRGBSliders(hSettings, "high", func.i18n("msgBox.mcm.highlightedColor"), func.i18n("msgBox.mcm.highlightedColorDescription"))

local cellSettings = cPage:createCategory(func.i18n("msgBox.mcm.explorationLogColor")) --Green
createRGBSliders(cellSettings, "cell", func.i18n("msgBox.mcm.explorationLogColor"), func.i18n("msgBox.mcm.explorationLogColorDescription"))

local dmgSettings = cPage:createCategory(func.i18n("msgBox.mcm.combatLogColor")) --Red
createRGBSliders(dmgSettings, "dmg", func.i18n("msgBox.mcm.combatLogColor"), func.i18n("msgBox.mcm.combatLogColorDescription"))

local hitSettings = cPage:createCategory(func.i18n("msgBox.mcm.hitLogColor")) --Pink
createRGBSliders(hitSettings, "hit", func.i18n("msgBox.mcm.hitLogColor"), func.i18n("msgBox.mcm.hitLogColorDescription"))

local castSettings = cPage:createCategory(func.i18n("msgBox.mcm.castLogColor")) --Baby Blue
createRGBSliders(castSettings, "cast", func.i18n("msgBox.mcm.castLogColor"), func.i18n("msgBox.mcm.castLogColorDescription"))

local cChanceSettings = cPage:createCategory(func.i18n("msgBox.mcm.cChanceLogColor")) --Cyan
createRGBSliders(cChanceSettings, "cChance", func.i18n("msgBox.mcm.cChanceLogColor"), func.i18n("msgBox.mcm.cChanceLogColorDescription"))

local useSettings = cPage:createCategory(func.i18n("msgBox.mcm.useLogColor")) --Baby Blue also
createRGBSliders(useSettings, "use", func.i18n("msgBox.mcm.useLogColor"), func.i18n("msgBox.mcm.useLogColorDescription"))

local resSettings = cPage:createCategory(func.i18n("msgBox.mcm.resistLogColor")) --Purple
createRGBSliders(resSettings, "res", func.i18n("msgBox.mcm.resistLogColor"), func.i18n("msgBox.mcm.resistLogColorDescription"))

local dedSettings = cPage:createCategory(func.i18n("msgBox.mcm.deathLogColor")) --Orangish
createRGBSliders(dedSettings, "ded", func.i18n("msgBox.mcm.deathLogColor"), func.i18n("msgBox.mcm.deathLogColorDescription"))

local queSettings = cPage:createCategory(func.i18n("msgBox.mcm.questLogColor")) --Neon Blue
createRGBSliders(queSettings, "que", func.i18n("msgBox.mcm.questLogColor"), func.i18n("msgBox.mcm.questLogColorDescription"))

local diaSettings = cPage:createCategory(func.i18n("msgBox.mcm.chatLogColor")) --Yellow
createRGBSliders(diaSettings, "dia", func.i18n("msgBox.mcm.chatLogColor"), func.i18n("msgBox.mcm.chatLogColorDescription"))

local topSettings = cPage:createCategory(func.i18n("msgBox.mcm.topicLogColor")) --Answer Maroon
createRGBSliders(topSettings, "top", func.i18n("msgBox.mcm.topicLogColor"), func.i18n("msgBox.mcm.topicLogColorDescription"))

local buySettings = cPage:createCategory(func.i18n("msgBox.mcm.buyLogColor")) --Dark Gold
createRGBSliders(buySettings, "buy", func.i18n("msgBox.mcm.buyLogColor"), func.i18n("msgBox.mcm.buyLogColorDescription"))

local sellSettings = cPage:createCategory(func.i18n("msgBox.mcm.sellLogColor")) --Light Gold
createRGBSliders(sellSettings, "sell", func.i18n("msgBox.mcm.sellLogColor"), func.i18n("msgBox.mcm.sellLogColorDescription"))

local dropSettings = cPage:createCategory(func.i18n("msgBox.mcm.dropLogColor")) --Mocha
createRGBSliders(dropSettings, "drop", func.i18n("msgBox.mcm.dropLogColor"), func.i18n("msgBox.mcm.dropLogColorDescription"))

local grabSettings = cPage:createCategory(func.i18n("msgBox.mcm.grabLogColor")) --Choccy Milk
createRGBSliders(grabSettings, "grab", func.i18n("msgBox.mcm.grabLogColor"), func.i18n("msgBox.mcm.grabLogColorDescription"))

local musSettings = cPage:createCategory(func.i18n("msgBox.mcm.musicLogColor")) --Minty
createRGBSliders(musSettings, "mus", func.i18n("msgBox.mcm.musicLogColor"), func.i18n("msgBox.mcm.musicLogColorDescription"))

--Interop Colors

local dtSettings = iPage:createCategory(func.i18n("msgBox.mcm.dtLogColor")) --Peach
createRGBSliders(dtSettings, "dt", func.i18n("msgBox.mcm.dtLogColor"), func.i18n("msgBox.mcm.dtLogColorDescription"))

local clSettings = iPage:createCategory(func.i18n("msgBox.mcm.clLogColor")) --Matte Purple
createRGBSliders(clSettings, "cl", func.i18n("msgBox.mcm.clLogColor"), func.i18n("msgBox.mcm.clLogColorDescription"))