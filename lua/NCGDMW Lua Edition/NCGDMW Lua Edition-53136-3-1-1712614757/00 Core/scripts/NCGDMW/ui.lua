local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local ui = require('openmw.ui')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")
local Player = require('openmw.types').Player

local S = require('scripts.NCGDMW.settings')
local C = require('scripts.NCGDMW.common')
local H = require('scripts.NCGDMW.helpers')
local decay = require('scripts.NCGDMW.decay')

local L = core.l10n(S.MOD_NAME)

local ncgdStatsMenu
local progressStatsMenu

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

local growingInterval = {
    external = { grow = 1 }
}

local hGap10 = padding(10, 0)
local vGap10 = padding(0, 10)
local vGap20 = padding(0, 20)

local function text(str)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = { text = str }
    }
end

local function row(key, value)
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        external = { stretch = 1 },
        content = ui.content {
            text(string.format("%s: ", key)),
            growingInterval,
            text(value),
            hGap10,
        }
    }
end

local boxTemplate = I.MWUI.templates.boxTransparent
if S.isLuaApiRecentEnough then
    boxTemplate = I.MWUI.templates.boxTransparentThick
end

local function centerWindow(content)
    return {
        layer = "Windows",
        template = boxTemplate,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content {
            growingInterval,
            content,
            growingInterval,
        }
    }
end

local function menu(content, width, height)
    return centerWindow({
        type = ui.TYPE.Flex,
        props = {
            size = v2(width, height)
        },
        content = ui.content {
            growingInterval,
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                external = { stretch = 1 },
                content = ui.content {
                    growingInterval,
                    content,
                    growingInterval,
                }
            },
            growingInterval,
        }
    })
end

local function getSkillsRows(getSkillValue)
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
    if S.playerGlobalStorage:get("starwindNames") then
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
        head(L("combatHead")),
        row("Block", getSkillValue("block")),
        row(Armorer, getSkillValue("armorer")),
        row("Medium Armor", getSkillValue("mediumarmor")),
        row("Heavy Armor", getSkillValue("heavyarmor")),
        row("Blunt Weapon", getSkillValue("bluntweapon")),
        row("Long Blade", getSkillValue("longblade")),
        row("Axe", getSkillValue("axe")),
        row(Spear, getSkillValue("spear")),
        row("Athletics", getSkillValue("athletics")),
    }

    local rightBlock = {
        head(L("magicHead")),
        row(Enchant, getSkillValue("enchant")),
        row(Destruction, getSkillValue("destruction")),
        row(Alteration, getSkillValue("alteration")),
        row(Illusion, getSkillValue("illusion")),
        row(Conjuration, getSkillValue("conjuration")),
        row(Mysticism, getSkillValue("mysticism")),
        row(Restoration, getSkillValue("restoration")),
        row(Alchemy, getSkillValue("alchemy")),
        row("Unarmored", getSkillValue("unarmored")),
        vGap10,
        padding(0, 6),
        head(L("thiefHead")),
        row("Security", getSkillValue("security")),
        row("Sneak", getSkillValue("sneak")),
        row("Acrobatics", getSkillValue("acrobatics")),
        row("Light Armor", getSkillValue("lightarmor")),
        row("Short Blade", getSkillValue("shortblade")),
        row("Marksman", getSkillValue("marksman")),
        row("Mercantile", getSkillValue("mercantile")),
        row("Speechcraft", getSkillValue("speechcraft")),
        row("Hand To Hand", getSkillValue("handtohand")),
    }

    return { leftBlock = leftBlock, rightBlock = rightBlock }
end

local function getStatsMenu()
    local skills = decay.decaySkills()
    local decayMem = decay.decayMemory()
    local growthRate = C.rateMap()[C.getGrowthRateNum()]
    local decayRate = decay.getDecayRateNum()
    local rateMap = C.rateMap()[decayRate]

    local hasDecay = decayRate > C.rateValues().none

    -- percentage won't update until decay mem is updated and decay memory doesn't adjust after you change the decay rate
    local function formatPercent(skillVal)
        return string.format("%2s%%", math.floor(skillVal * 100 + 0.5))
    end
    local uncapper = S.playerSkillsStorage:get("uncapperEnabled")

    local skillRows = getSkillsRows(function(skillId)
        return ((not uncapper and Player.stats.skills[skillId](self).base > 99)
                and "--%"
                or formatPercent(C.skillProgress()[skillId]))
                .. (hasDecay and " - " .. formatPercent(skills[skillId] / decayMem) or "")
    end)

    local leftBlock = {
        head(L("lvlMenuHead")),
        text(string.format("%s", I.NCGDMW.LevelProgress())),
        vGap10,
        head(L("Settings")),
        row(L("growthRate_name"), growthRate),
        row(L("decayRate_name"), rateMap),
    }

    if I.MarksmansEye then
        H.insertMultipleInArray(leftBlock, {
            vGap10,
            head("Marksman's Eye Level"),
            text(I.MarksmansEye.Level()),
        })
    end

    H.insertMultipleInArray(leftBlock, {
        vGap20,
        head(L(hasDecay and "progressAndDecayMenuHead" or "progressMenuHead")),
        vGap10,
    })

    H.insertMultipleInArray(leftBlock, skillRows.leftBlock)

    local rightBlock = skillRows.rightBlock

    return menu({
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    size = v2(230, 200)
                },
                content = ui.content(leftBlock)
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    size = v2(30, 200)
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    size = v2(230, 200)
                },
                content = ui.content(rightBlock)
            },
        }
    }, 600, 400)
end

local function missingPluginWarning()
    return menu({
        type = ui.TYPE.Flex,
        content = ui.content {
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
        } }, 450, 325)
end

local function onKeyPress(key)
    -- Chargen isn't done enough
    if not C.hasStats() then return end

    -- Prevent the stats menu from rendering over the escape menu
    if key.code == input.KEY.Escape then
        if ncgdStatsMenu ~= nil then
            ncgdStatsMenu:destroy()
            ncgdStatsMenu = nil
        end
        if progressStatsMenu ~= nil then
            progressStatsMenu:destroy()
            progressStatsMenu = nil
        end
        return
    end

    if key.code == S.playerGlobalStorage:get("statsMenuKey") then
        self:sendEvent('updatePlayerStats')
        local statsMenu = getStatsMenu()

        if ncgdStatsMenu == nil then
            ncgdStatsMenu = ui.create(statsMenu)
        else
            ncgdStatsMenu.layout = statsMenu
            ncgdStatsMenu:update()
        end
    end
end

local function onKeyRelease(key)
    if key.code == S.playerGlobalStorage:get("statsMenuKey") then
        if ncgdStatsMenu ~= nil then
            ncgdStatsMenu:destroy()
            ncgdStatsMenu = nil
        end
    end
end

return {
    missingPluginWarning = missingPluginWarning,
    onKeyPress = onKeyPress,
    onKeyRelease = onKeyRelease,
}
