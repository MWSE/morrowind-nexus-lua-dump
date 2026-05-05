local i18n = mwse.loadTranslations("Pirate.HUDEquippedLight")
local config = require("Pirate.HUDEquippedLight.config")

local LINKS_LIST = {
    {
        text = i18n("mcm.Nexus"),
        url = "https://www.nexusmods.com/morrowind/mods/58702"
    },
    {
        text = i18n("mcm.FullRest"),
        url = "https://www.fullrest.ru/files/interfeys-uekipirovannogo-svetilnika"
    },
    {
        text = i18n("mcm.TESAll"),
        url = "https://tesall.ru/files/modi-dlya-morrowind/interfeis/14492-interfeis-ekipirovannogo-svetilnika"
    },
}
local CREDITS_LIST = {
    {
        text = i18n("mcm.Pirate"),
        url = "https://next.nexusmods.com/profile/Pirate443?gameId=100",
    },

}
local function addSideBar(component)
    component.sidebar:createCategory(i18n("mcm.modname")..i18n("mcm.version")..config.modVersion)
    component.sidebar:createInfo{ text = i18n("mcm.ModDescription") }

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
    local template = mwse.mcm.createTemplate{ name = i18n("mcm.modname"),
    --headerImagePath = "textures/headerImageName.dds"
    }

    template:saveOnClose(config.configPath, config.mcm)
    template:register()
        
    local page = template:createSideBarPage { label = i18n("mcm.generalSettings"), showReset = true }
    addSideBar(page)

    local displaySlot = page:createCategory{
    label = i18n("mcm.displaySlot.label"),
    description = i18n("mcm.displaySlot.desc"),
    }

    displaySlot:createYesNoButton {
        label = i18n("mcm.Slot.YesNo.label"),
        description = i18n("mcm.Slot.YesNo.desc"),
        defaultSetting = config.mcmDefault.SlotLightVisible,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "SlotLightVisible", table = config.mcm }
    }

    displaySlot:createYesNoButton {
        label = i18n("mcm.EmptySlot.YesNo.label"),
        description = i18n("mcm.EmptySlot.YesNo.desc"),
        defaultSetting = config.mcmDefault.EmptySlotVisible,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "EmptySlotVisible", table = config.mcm }
    }

    if tes3.isLuaModActive("seph.hudCustomizer") then
        displaySlot:createYesNoButton {
            label = i18n("mcm.seph.YesNo.label"),
            description = i18n("mcm.seph.YesNo.desc"),
            defaultSetting = config.mcmDefault.sephIntegration,
            showDefaultSetting = true,
            restartRequired = true,
            variable = mwse.mcm.createTableVariable{ id = "sephIntegration", table = config.mcm }
        }
    end

    displaySlot:createSlider{
        label = i18n("mcm.Slot.PosX.label") .. " %s%%",
        description = i18n("mcm.Slot.PosX.desc"),
        defaultSetting = config.mcmDefault.SlotPositionX,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotPositionX", table = config.mcm}
    }

    displaySlot:createSlider{
        label = i18n("mcm.Slot.PosY.label") .. " %s%%",
        description = i18n("mcm.Slot.PosY.desc"),
        defaultSetting = config.mcmDefault.SlotPositionY,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotPositionY", table = config.mcm}
    }

    local category1 = page:createCategory{
    label = i18n("mcm.category1.label"),
    description = i18n("mcm.category1.desc"),
    }

    category1:createYesNoButton {
        label = i18n("mcm.LightVisible.YesNo.label"),
        description = i18n("mcm.LightVisible.YesNo.desc"),
        defaultSetting = config.mcmDefault.EquippedLightVisible,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "EquippedLightVisible", table = config.mcm }
    }

    category1:createYesNoButton {
        label = i18n("mcm.ShieldVisible.YesNo.label"),
        description = i18n("mcm.ShieldVisible.YesNo.desc"),
        defaultSetting = config.mcmDefault.EquippedShieldVisible,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "EquippedShieldVisible", table = config.mcm }
    }

    category1:createSlider{
        label = i18n("mcm.SloticonSize.label"),
        description = i18n("mcm.SloticonSize.desc"),
        defaultSetting = config.mcmDefault.SlotIconSize,
        showDefaultSetting = true,
        min = 20,
        max = 96,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotIconSize", table = config.mcm}
    }

end
event.register("modConfigReady", registerMCM)