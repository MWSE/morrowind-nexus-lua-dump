local i18n = mwse.loadTranslations("Pirate.QuickKeysHotbarExtended")
local config = require("Pirate.QuickKeysHotbarExtended.config")
local log = mwse.Logger.new()

local LINKS_LIST = {
    {
        text = i18n("mcm.Nexus"),
        url = "https://www.nexusmods.com/morrowind/mods/58426"
    },
    {
        text = i18n("mcm.FullRest"),
        url = "https://www.fullrest.ru/files/rasshirennaya-panel-byistryih-klavish"
    },
    {
        text = i18n("mcm.TESAll"),
        url = "https://tesall.ru/files/modi-dlya-morrowind/interfeis/14472-rasshirennaya-panel-bistrikh-klavish"
    },
}
local CREDITS_LIST = {
    {
        text = i18n("mcm.Pirate"),
        url = "https://next.nexusmods.com/profile/Pirate443?gameId=100",
    },
    {
        text = i18n("mcm.Spammer"),
        url = "https://www.nexusmods.com/profile/Spammer21",
    },
    {
        text = i18n("mcm.Virnetch"),
        url = "https://www.nexusmods.com/profile/Virnetch",
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

    local displayHotBar = page:createCategory{
    label = i18n("mcm.displayHotBar.label"),
    description = i18n("mcm.displayHotBar.desc"),
    }

    displayHotBar:createYesNoButton {
        label = i18n("mcm.HotBar.YesNo.label"),
        description = i18n("mcm.HotBar.YesNo.desc"),
        defaultSetting = config.mcmDefault.HotBarVisible,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "HotBarVisible", table = config.mcm }
    }

    displayHotBar:createDropdown {
        label = i18n("mcm.HotBar.Orient.label"),
        description = i18n("mcm.HotBar.Orient.desc"),
        defaultSetting = config.mcmDefault.HotBarOrientation,
        showDefaultSetting = true,
        options  = {
            { label = i18n("mcm.HotBar.Orient.hor"), value = "horizontal" },
            { label = i18n("mcm.HotBar.Orient.ver"), value = "vertical" },
        },
        variable = mwse.mcm:createTableVariable { id = "HotBarOrientation", table = config.mcm }
    }

    if tes3.isLuaModActive("seph.hudCustomizer") then
        displayHotBar:createYesNoButton {
            label = i18n("mcm.seph.YesNo.label"),
            description = i18n("mcm.seph.YesNo.desc"),
            defaultSetting = config.mcmDefault.sephIntegration,
            showDefaultSetting = true,
            restartRequired = true,
            variable = mwse.mcm.createTableVariable{ id = "sephIntegration", table = config.mcm }
        }
    end

    displayHotBar:createSlider{
        label = i18n("mcm.HotBar.PosX.label") .. " %s%%",
        description = i18n("mcm.HotBar.PosX.desc"),
        defaultSetting = config.mcmDefault.HotBarPositionX,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "HotBarPositionX", table = config.mcm}
    }

    displayHotBar:createSlider{
        label = i18n("mcm.HotBar.PosY.label") .. " %s%%",
        description = i18n("mcm.HotBar.PosY.desc"),
        defaultSetting = config.mcmDefault.HotBarPositionY,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "HotBarPositionY", table = config.mcm}
    }

    displayHotBar:createOnOffButton {
        label = i18n("mcm.BgUpdate.OnOff.label"),
        description = i18n("mcm.BgUpdate.OnOff.desc"),
        defaultSetting = config.mcmDefault.HotBarBgUpdate,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "HotBarBgUpdate", table = config.mcm }
    }

    displayHotBar:createSlider{
        label = i18n("mcm.BgUpdate.Interval.label") .. " %s " .. i18n("mcm.MS"),
        description = i18n("mcm.BgUpdate.Interval.desc"),
        defaultSetting = config.mcmDefault.BgUpdateInterval,
        showDefaultSetting = true,
        min = 10,
        max = 3000,
        step = 1,
        jump = 100,
        variable = mwse.mcm.createTableVariable{id = "BgUpdateInterval", table = config.mcm}
    }

    local category1 = page:createCategory{
    label = i18n("mcm.category1.label"),
    description = i18n("mcm.category1.desc"),
    }

    category1:createSlider{
        label = i18n("mcm.HotBar.Spacing.label"),
        description = i18n("mcm.HotBar.Spacing.desc"),
        defaultSetting = config.mcmDefault.SlotSpacing,
        showDefaultSetting = true,
        min = -1,
        max = 10,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{id = "SlotSpacing", table = config.mcm}
    }

    category1:createSlider{
        label = i18n("mcm.HotBar.iconSize.label"),
        description = i18n("mcm.HotBar.iconSize.desc"),
        defaultSetting = config.mcmDefault.SlotIconSize,
        showDefaultSetting = true,
        min = 20,
        max = 96,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotIconSize", table = config.mcm}
    }

    category1:createSlider{
        label = i18n("mcm.HotBar.equipBorderSize.label"),
        description = i18n("mcm.HotBar.equipBorderSize.desc"),
        defaultSetting = config.mcmDefault.equipBorderSize,
        showDefaultSetting = true,
        min = 1,
        max = 5,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{id = "equipBorderSize", table = config.mcm}
    }

    category1:createSlider{
        label = i18n("mcm.Slot.BgAlpha.label") .. " %s%%",
        description = i18n("mcm.Slot.BgAlpha.desc"),
        defaultSetting = config.mcmDefault.SlotBackgroundAlpha,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotBackgroundAlpha", table = config.mcm}
    }

    category1:createSlider{
        label = i18n("mcm.icon.BgAlpha.label") .. " %s%%",
        description = i18n("mcm.icon.BgAlpha.desc"),
        defaultSetting = config.mcmDefault.iconBackgroundAlpha,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "iconBackgroundAlpha", table = config.mcm}
    }

    category1:createOnOffButton {
        label = i18n("mcm.icon.BgTexture.label"),
        description = i18n("mcm.icon.BgTexture.desc"),
        defaultSetting = config.mcmDefault.iconBackgroundTexture,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "iconBackgroundTexture", table = config.mcm }
    }

    category1:createOnOffButton {
        label = i18n("mcm.StatusBar.OnOff.label"),
        description = i18n("mcm.StatusBar.OnOff.desc"),
        defaultSetting = config.mcmDefault.StatusBar,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "StatusBar", table = config.mcm }
    }

    category1:createSlider{
        label = i18n("mcm.ItemCount.PosX.label") .. " %s",
        --label = "test %s",
        description = i18n("mcm.ItemCount.PosX.desc"),
        defaultSetting = config.mcmDefault.ItemCountPositionX,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "ItemCountPositionX", table = config.mcm}
    }

    category1:createSlider{
        label = i18n("mcm.ItemCount.PosY.label") .. " %s",
        description = i18n("mcm.ItemCount.PosY.desc"),
        defaultSetting = config.mcmDefault.ItemCountPositionY,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "ItemCountPositionY", table = config.mcm}
    }

    category1:createOnOffButton {
        label = i18n("mcm.SlotNumber.OnOff.label"),
        description = i18n("mcm.SlotNumber.OnOff.desc"),
        defaultSetting = config.mcmDefault.SlotNumber,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "SlotNumber", table = config.mcm }
    }

    category1:createSlider{
        label = i18n("mcm.SlotNumber.PosX.label") .. " %s",
        description = i18n("mcm.SlotNumber.PosX.desc"),
        defaultSetting = config.mcmDefault.SlotNumberPositionX,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotNumberPositionX", table = config.mcm}
    }

    category1:createSlider{
        label = i18n("mcm.SlotNumber.PosY.label") .. " %s",
        description = i18n("mcm.SlotNumber.PosY.desc"),
        defaultSetting = config.mcmDefault.SlotNumberPositionY,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotNumberPositionY", table = config.mcm}
    }

    local effectIconCategory = page:createCategory{
    label = i18n("mcm.effectIconCategory.label"),
    description = i18n("mcm.effectIconCategory.desc"),
    }

    effectIconCategory:createOnOffButton {
        label = i18n("mcm.effectIcon.Alchemy.label"),
        description = i18n("mcm.effectIcon.Alchemy.desc"),
        defaultSetting = config.mcmDefault.AlchemyEffectIcons,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "AlchemyEffectIcons", table = config.mcm }
    }

    effectIconCategory:createOnOffButton {
        label = i18n("mcm.effectIcon.Scroll.label"),
        description = i18n("mcm.effectIcon.Scroll.desc"),
        defaultSetting = config.mcmDefault.ScrollEffectIcons,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "ScrollEffectIcons", table = config.mcm }
    }

    effectIconCategory:createOnOffButton {
        label = i18n("mcm.effectIcon.Enchant.label"),
        description = i18n("mcm.effectIcon.Enchant.desc"),
        defaultSetting = config.mcmDefault.EnchantEffectIcons,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "EnchantEffectIcons", table = config.mcm }
    }

    effectIconCategory:createDropdown {
        label = i18n("mcm.effectIcon.Style.label"),
        description = i18n("mcm.effectIcon.Style.desc"),
        defaultSetting = config.mcmDefault.effectIconStyle,
        showDefaultSetting = true,
        options  = {
            { label = i18n("mcm.effectIcon.Style.icon"), value = "icon" },
            { label = i18n("mcm.effectIcon.Style.bigIcon"), value = "bigIcon" },
        },
        variable = mwse.mcm:createTableVariable {
            id    = "effectIconStyle",
            table = config.mcm
        }
    }

    effectIconCategory:createSlider{
        label = i18n("mcm.effectIcon.Size.label") .. " %s%%",
        description = i18n("mcm.effectIcon.Size.desc"),
        defaultSetting = config.mcmDefault.effectIconSize,
        showDefaultSetting = true,
        min = 0,
        max = 50,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "effectIconSize", table = config.mcm}
    }

    effectIconCategory:createSlider{
        label = i18n("mcm.effectIcon.PosX.label") .. " %s",
        description = i18n("mcm.effectIcon.PosX.desc"),
        defaultSetting = config.mcmDefault.effectIconPositionX,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "effectIconPositionX", table = config.mcm}
    }

    effectIconCategory:createSlider{
        label = i18n("mcm.effectIcon.PosY.label") .. " %s",
        description = i18n("mcm.effectIcon.PosY.desc"),
        defaultSetting = config.mcmDefault.effectIconPositionY,
        showDefaultSetting = true,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "effectIconPositionY", table = config.mcm}
    }
    -- page HotBar Extended Settings
    local pageExtended = template:createSideBarPage { label = i18n("mcm.extendedSettings"), showReset = true }
    addSideBar(pageExtended)

    local extendedCategory = pageExtended:createCategory{
    label = i18n("mcm.category2.label"),
    description = i18n("mcm.category2.desc"),
    }

    extendedCategory:createOnOffButton {
        label = i18n("mcm.HotBarExtended.OnOf.label"),
        description = i18n("mcm.HotBarExtended.OnOf.desc"),
        defaultSetting = config.mcmDefault.HotBarExtended,
        showDefaultSetting = true,
        restartRequired = true,
        variable = mwse.mcm.createTableVariable{ id = "HotBarExtended", table = config.mcm }
    }

    extendedCategory:createKeyBinder{
        label = i18n("mcm.modifierKey2.label"),
        description = i18n("mcm.modifierKey2.desc"),
        defaultSetting = config.mcmDefault.modifierKey2,
        showDefaultSetting = true,
        variable = mwse.mcm.createTableVariable{ table = config.mcm, id = "modifierKey2" },
        allowCombinations = false
    }

    extendedCategory:createKeyBinder{
        label = i18n("mcm.modifierKey3.label"),
        description = i18n("mcm.modifierKey3.desc"),
        defaultSetting = config.mcmDefault.modifierKey3,
        showDefaultSetting = true,
        variable = mwse.mcm.createTableVariable{ table = config.mcm, id = "modifierKey3" },
        allowCombinations = false
    }

    extendedCategory:createSlider{
        label = i18n("mcm.numberVisiblePanels.label") .. " %s",
        description = i18n("mcm.numberVisiblePanels.desc"),
        defaultSetting = config.mcmDefault.numberVisiblePanels,
        showDefaultSetting = true,
        min = 1,
        max = 3,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{id = "numberVisiblePanels", table = config.mcm}
    }

    extendedCategory:createSlider{
        label = i18n("mcm.numberVisibleSlot.label") .. " %s",
        description = i18n("mcm.numberVisibleSlot.desc"),
        defaultSetting = config.mcmDefault.numberVisibleSlot,
        showDefaultSetting = true,
        min = 1,
        max = 9,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{id = "numberVisibleSlot", table = config.mcm}
    }

    extendedCategory:createOnOffButton {
        label = i18n("mcm.PanelsInOneLine.label"),
        description = i18n("mcm.PanelsInOneLine.desc"),
        defaultSetting = config.mcmDefault.PanelsInOneLine,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "PanelsInOneLine", table = config.mcm }
    }

    -- page Setting up key binding (QuickKey Outlander)
    local pageKeyBind = template:createSideBarPage { label = i18n("mcm.KeyBindSettings"), showReset = true }
    addSideBar(pageKeyBind)

    local keyBindCategory = pageKeyBind:createCategory{
    label = i18n("mcm.KeyBindCat.label"),
    description = i18n("mcm.KeyBindCat.desc"),
    }

    keyBindCategory:createOnOffButton {
        label = i18n("mcm.BindHoldClick.OnOff.label"),
        description = i18n("mcm.BindHoldClick.OnOff.desc"),
        defaultSetting = config.mcmDefault.BindHoldClick,
        showDefaultSetting = true,
        restartRequired = true,
        variable = mwse.mcm.createTableVariable{ id = "BindHoldClick", table = config.mcm }
    }

    keyBindCategory:createOnOffButton {
        label = i18n("mcm.BindMessage.OnOff.label"),
        description = i18n("mcm.BindMessage.OnOff.desc"),
        defaultSetting = config.mcmDefault.BindMessage,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "BindMessage", table = config.mcm }
    }

    local tooltipCategory = pageKeyBind:createCategory{
    label = i18n("mcm.TooltipCat.label"),
    description = i18n("mcm.TooltipCat.desc"),
    }

    tooltipCategory:createOnOffButton {
        label = i18n("mcm.BindTooltip.OnOff.label"),
        description = i18n("mcm.BindTooltip.OnOff.desc"),
        defaultSetting = config.mcmDefault.BindTooltip,
        showDefaultSetting = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "BindTooltip", table = config.mcm }
    }

    tooltipCategory:createDropdown {
        label = i18n("mcm.BindTooltip.Pos.label"),
        description = i18n("mcm.BindTooltip.Pos.desc"),
        defaultSetting = config.mcmDefault.BindTooltipMode,
        showDefaultSetting = true,
        options  = {
            { label = i18n("mcm.BindTooltip.Pos.Top"), value = 0 },
            { label = i18n("mcm.BindTooltip.Pos.First"), value = 1 },
            { label = i18n("mcm.BindTooltip.Pos.Last"), value = -1 },
        },
        variable = mwse.mcm:createTableVariable { id = "BindTooltipMode", table = config.mcm }
    }

    -- Log Settings
    local miscSetting = page:createCategory{
    label = i18n("mcm.miscSetting.label"),
    description = i18n("mcm.miscSetting.desc"),
    }

    miscSetting:createLogLevelOptions{
        showDefaultSetting = true,
        defaultSetting = config.mcmDefault.logLevel,
        variable = mwse.mcm.createTableVariable{id = "logLevel", table = config.mcm},
        callback = function(self)
            log.level = self.variable.value
        end
    }

end
event.register("modConfigReady", registerMCM)