local i18n = mwse.loadTranslations("sb_achievements")
local confPath = "sb_achievements"
local defaultConfig = {
            showHiddenAchievements = 0,
            iconSize = 0.7,
            achieveList = "stat",
            achieveKey = {
                keyCode = tes3.scanCode.F3,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false
                    },
            popupPositionHorizontal = "right",
            popupPositionVertical = "top"
        }
---@class mcm
local mcm = { config = mwse.loadConfig(confPath, defaultConfig) }

local modName = i18n("mcm.modname")
local LINKS_LIST = {
    {
        text = i18n("mcm.Nexus"),
        url = "https://www.nexusmods.com/morrowind/mods/51081"
    },
}
local CREDITS_LIST = {
    {
        text = i18n("mcm.Safebox"),
        url = "https://next.nexusmods.com/profile/Safebox?gameId=100",
    },
    {
        text = i18n("mcm.JaceyS"),
        url = "https://www.nexusmods.com/morrowind/mods/49914",
    },
    {
        text = i18n("mcm.Coricus"),
    },
    {
        text = i18n("mcm.Pirate"),
        url = "https://next.nexusmods.com/profile/Pirate443?gameId=100",
    },
}
local function addSideBar(component)
    component.sidebar:createCategory(modName)
    component.sidebar:createInfo{ text = i18n("mcm.modinfo") }

    local linksCategory = component.sidebar:createCategory(i18n("mcm.Links"))
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
        end
    local creditsCategory = component.sidebar:createCategory(i18n("mcm.Credits"))
    for _, credit in ipairs(CREDITS_LIST) do
        if credit.url then
            creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
        else
            creditsCategory:createInfo{ text = credit.text }
        end
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = modName }
    --headerImagePath = "textures/Achiev_header.dds" }
    template:saveOnClose(confPath, mcm.config)
    template:register()
        
    local page = template:createSideBarPage { name = i18n("mcm.Settings") }
    addSideBar(page)
    
    local categoryAchievementsList = page:createCategory{
    label = i18n("mcm.categoryAchievementsList.name"),
    --description = i18n("mcm.categoryAchievementsList.desc")
    }
    categoryAchievementsList:createDropdown{
        label = i18n("mcm.HideSecretAchiev.label"),
        description = i18n("mcm.HideSecretAchiev.desc"),
        options = {
            { label = i18n("mcm.HideSecretAchiev.Author"), value = 0 },
            { label = i18n("mcm.HideSecretAchiev.Hide"), value = 1 },
            { label = i18n("mcm.HideSecretAchiev.Show"), value = 2 },
            { label = i18n("mcm.HideSecretAchiev.Group"), value = 3 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "showHiddenAchievements",
            table = mcm.config
        }
    }

    categoryAchievementsList:createSlider{
        label = i18n("mcm.Iconsize.label"),
        description = i18n("mcm.Iconsize.desc"),
        decimalPlaces = 1,
        min = 0.3,
        max = 1.0,
        step = 0.1,
        jump = 0.1,
        variable = mwse.mcm.createTableVariable{ id = "iconSize", table = mcm.config}
    }

    categoryAchievementsList:createDropdown{
        label = i18n("mcm.AchievListPos.label"),
        description = i18n("mcm.AchievListPos.desc"),
        options = {
            { label = i18n("mcm.AchievListPos.stat"), value = "stat" },
            { label = i18n("mcm.AchievListPos.window"), value = "windows" }
        },
		restartRequired = true,
        variable = mwse.mcm:createTableVariable {
            id    = "achieveList",
            table = mcm.config
        }
    }
	
	categoryAchievementsList:createKeyBinder{
		label = i18n("mcm.Hotkey.label"),
		description = i18n("mcm.Hotkey.desc"),
		variable = mwse.mcm.createTableVariable{ table = mcm.config, id = "achieveKey" },
		allowCombinations = true
	}

    local categoryNotification = page:createCategory{
    label = i18n("mcm.categoryNotification.name"),
    --description = i18n("mcm.categoryNotification.desc")
    }

categoryNotification:createDropdown{
    label = i18n("mcm.PopupHorizontal.label"),
    description = i18n("mcm.PopupHorizontal.desc"),
    options = {
        { label = i18n("mcm.PopupLeft"), value = "left" },
        { label = i18n("mcm.PopupRight"), value = "right" }
    },
    variable = mwse.mcm:createTableVariable {
        id = "popupPositionHorizontal",
        table = mcm.config
    }
}

categoryNotification:createDropdown{
    label = i18n("mcm.PopupVertical.label"),
    description = i18n("mcm.PopupVertical.desc"),
    options = {
        { label = i18n("mcm.PopupTop"), value = "top" },
        { label = i18n("mcm.PopupBottom"), value = "bottom" }
    },
    variable = mwse.mcm:createTableVariable {
        id = "popupPositionVertical",
        table = mcm.config
    }
}
end

function mcm.init()
    event.register("modConfigReady", registerMCM)
end

return mcm