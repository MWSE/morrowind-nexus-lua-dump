local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")

local MOD_NAME = "NCGDMW"
local L = core.l10n(MOD_NAME)

local function padding(horizontal, vertical)
	return { props = { size = v2(horizontal, vertical) } }
end

local function head(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = { text = text }
    }
end

local function text(str)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = { text = str }
    }
end

local function centerWindow(content)
	return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content {content}
    }
end

local function menu(content, width, height)
    return centerWindow(
        {
            type = ui.TYPE.Flex,
            props = {
                position = v2(75, 0),
                size = v2(width, height)
            },
            content = ui.content(content)
        }
    )
end

local function row(key, value)
	return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            text(string.format("%s: ", key)),
            text(value)
        }
    }
end

local function decayStatsMenu(skills, decayMem, starwindNames)
    local width, height = 475, 380
    local gap20 = padding(0, 20)
    local gap10 = padding(0, 10)

    local function decayPercent(skillVal)
        return string.format("%s%%", math.floor(skillVal / decayMem * 100))
    end

    -- Support for Starwind skill names
    local Alchemy = "Alchemy"
    local Alteration = "Alteration"
    local Armorer = "Armorer"
    local Conjuration = "Conjuration"
    local Destruction = "Destruction"
    local Enchant = "Enchant"
    local Illusion = "Illusion"
    local Mysticism = "Mysticism"
    local Restoration = "Restoration"
    local Spear = "Spear"
    if starwindNames == true then
        Alchemy = "Bartending"
        Alteration = "Gray Force Powers"
        Armorer = "Mechanics"
        Conjuration = "Engineering"
        Destruction = "Dark Force Powers"
        Enchant = "Modifications"
        Illusion = "Mind Force Powers"
        Mysticism = "Psionic Force Powers"
        Restoration = "Light Force Powers"
        Spear = "Staff"
    end

    local leftBlock = {
        head(L("decayMenuHead")),
        gap10,
        head(L("combatHead")),
        row("Block", decayPercent(skills["block"])),
        row(Armorer, decayPercent(skills["armorer"])),
        row("Medium Armor", decayPercent(skills["mediumarmor"])),
        row("Heavy Armor", decayPercent(skills["heavyarmor"])),
        row("Blunt Weapon", decayPercent(skills["bluntweapon"])),
        row("Long Blade", decayPercent(skills["longblade"])),
        row("Axe", decayPercent(skills["axe"])),
        row(Spear, decayPercent(skills["spear"])),
        row("Athletics", decayPercent(skills["athletics"])),
        gap10,
        head(L("magicHead")),
        row(Enchant, decayPercent(skills["enchant"])),
        row(Destruction, decayPercent(skills["destruction"])),
        row(Alteration, decayPercent(skills["alteration"])),
        row(Illusion, decayPercent(skills["illusion"])),
        row(Conjuration, decayPercent(skills["conjuration"])),
        row(Mysticism, decayPercent(skills["mysticism"])),
        row(Restoration, decayPercent(skills["restoration"])),
        row(Alchemy, decayPercent(skills["alchemy"])),
        row("Unarmored", decayPercent(skills["unarmored"]))
    }

    local rightBlock = {
        gap20,
        padding(0, 6),
        head(L("thiefHead")),
        row("Security", decayPercent(skills["security"])),
        row("Sneak", decayPercent(skills["sneak"])),
        row("Acrobatics", decayPercent(skills["acrobatics"])),
        row("Light Armor", decayPercent(skills["lightarmor"])),
        row("Short Blade", decayPercent(skills["shortblade"])),
        row("Marksman", decayPercent(skills["marksman"])),
        row("Mercantile", decayPercent(skills["mercantile"])),
        row("Speechcraft", decayPercent(skills["speechcraft"])),
        row("Hand To Hand", decayPercent(skills["handtohand"])),
        gap10,
        head(L("lvlMenuHead")),
        text(string.format("%s", I.NCGDMW.LevelProgress())),
        gap10,
        head(L("Settings")),
        row(L("growthRate"), I.NCGDMW.GrowthRate(nil, true)),
        row(L("decayRate"), I.NCGDMW.DecayRate(nil, true))
    }

    if I.MarksmansEye then
        table.insert(rightBlock, gap10)
        table.insert(rightBlock, head("Marksman's Eye Level"))
        table.insert(rightBlock, text(I.MarksmansEye.Level()))
    end

    return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    position = v2(75, 20),
                    size = v2(width, height)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    position = v2(75, 0),
                                    size = v2(200, 200)
                                },
                                content = ui.content(leftBlock)
                            },
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    position = v2(75, 0),
                                    size = v2(200, 200)
                                },
                                content = ui.content(rightBlock)
                            }
                        }
                    }
                }
            }
        }
    }
end

local function levelStatsMenu()
    local width, height = 275, 75
    local content = {
        padding(0, 20),
        head(L("lvlMenuHead")),
        text(string.format("%s", I.NCGDMW.LevelProgress()))
    }

    if I.MarksmansEye then
        height = 125
        table.insert(content, padding(0, 20))
        table.insert(content, head("Marksman's Eye Level"))
        table.insert(content, text(I.MarksmansEye.Level()))
    end

    --TODO: show settings here too..

    return menu(content, width, height)
end

local function missingPluginWarning()
    return menu(
        {
            padding(0, 20),
            head(L("noPluginError0")),
            padding(0, 20),
            text(L("noPluginError1")),
            padding(0, 20),
            text(L("noPluginError2")),
            text(L("noPluginError3")),
            padding(0, 20),
            text("ncgdmw.omwaddon"),
            text("ncgdmw_alt_start.omwaddon"),
            text("ncgdmw_starwind.omwaddon"),
            padding(0, 20),
            text(L("noPluginError4")),
            text(L("noPluginError5")),
            padding(0, 20),
            text(L("noPluginError6"))
        },
        475, 300
    )
end

local function initSettings()
    -- THANKS:
    -- https://gitlab.com/urm-openmw-mods/camerahim/-/blob/1a12e3f8c902291d5629f2d8cc8649eac315533a/Data%20Files/scripts/CameraHIM/settings.lua#L23-35
    I.Settings.registerRenderer(
        'NCGDMW_hotkey', function(value, set)
            return {
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = value and input.getKeyName(value) or '',
                },
                events = {
                    keyPress = async:callback(function(e)
                            set(e.code)
                    end)
                }
            }
    end)

    I.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description"
    }

    I.Settings.registerGroup {
        key = "SettingsPlayer" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "settingsTitle",
        page = MOD_NAME,
        description = "settingsDesc",
        permanentStorage = false,
        settings = {
            {
                key = "statsMenuKey",
                name = "statsMenuKey",
                default = nil,
                renderer = "NCGDMW_hotkey"
            },
            {
                key = "decayRate",
                name = "decayRate",
                default = "fast",
                argument = {
                    l10n = MOD_NAME,
                    items = {"fast", "standard", "slow", "none"}
                },
                renderer = "select"
            },
            {
                key = "growthRate",
                name = "growthRate",
                default = "slow",
                argument = {
                    l10n = MOD_NAME,
                    items = {"fast", "standard", "slow"}
                },
                renderer = "select"
            },
            {
                key = "starwindNames",
                name = "Use Starwind Skill Names",
                default = false,
                renderer = "checkbox"
            }
        }
    }
end

return {
    initSettings = initSettings,
    decayStatsMenu = decayStatsMenu,
    levelStatsMenu = levelStatsMenu,
    missingPluginWarning = missingPluginWarning
}
