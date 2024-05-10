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

local orderedAttributeIds = {
    "strength", "intelligence", "willpower", "agility", "speed", "endurance", "personality", "luck"
}

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
local vMargin = padding(0, 40)

local stretchingLine = {
    template = I.MWUI.templates.horizontalLine,
    external = {
        stretch = 1,
    },
}

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

    local combatBlock = {
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

    local magicBlock = {
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
    }

    local thiefBlock = {
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

    return { combatBlock = combatBlock, magicBlock = magicBlock, thiefBlock = thiefBlock }
end

local function formatPercent(skillVal)
    return string.format("%2s%%", math.floor(skillVal * 100 + 0.5))
end

local function getStatsMenu()
    local decaySkills = decay.decaySkills()
    local decayMem = decay.decayMemory()
    local growthRate = C.getGrowthRate()
    local decayRate = decay.getDecayRate()
    local decayRateNum = C.rateMap()[decayRate]
    local baseStatsMods = C.getBaseStatsModifiers()
    local baseAttrMods = {}
    local hasAttrBaseStatsMods = false
    local hasSkillBaseStatsMods = false
    local maxHealthMod = C.getMaxHealthModifier()

    for attributeId, _ in pairs(Player.stats.attributes) do
        local baseMod = baseStatsMods.attributes[attributeId] or 0
        baseAttrMods[attributeId] = baseMod + C.attributeDiffs()[attributeId]
        if baseAttrMods[attributeId] ~= 0 then
            hasAttrBaseStatsMods = true
        end
    end
    for _, value in pairs(baseStatsMods.skills) do
        if value ~= nil and value ~= 0 then
            hasSkillBaseStatsMods = true
            break
        end
    end

    local hasDecay = decayRateNum > C.rateValues().none

    -- percentage won't update until decay mem is updated and decay memory doesn't adjust after you change the decay rate
    local hasUncapper = S.playerSkillsStorage:get("uncapperEnabled")

    local skillRows = getSkillsRows(function(skillId)
        return ((hasSkillBaseStatsMods and baseStatsMods.skills[skillId]) and (baseStatsMods.skills[skillId] .. " ; ") or "")
                .. ((hasUncapper or Player.stats.skills[skillId](self).base < 100) and formatPercent(C.skillProgress()[skillId]) or "--%")
                .. (hasDecay and (" ; " .. formatPercent(decaySkills[skillId] / decayMem)) or "")
    end)

    local leftHeadBlock = {}
    local rightHeadBlock = {}

    H.insertMultipleInArray(leftHeadBlock, {
        head(L("levelHead")),
        text(tostring(Player.stats.level(self).current)),
        vGap10,
        head(L("levelProgressHead")),
        text(tostring(I.NCGDMW.LevelProgress())),
    })

    H.insertMultipleInArray(rightHeadBlock, {
        head(L("Settings")),
        row(L("growthRate_name"), L(growthRate)),
        row(L("decayRate_name"), L(decayRate)),
    })

    if I.MarksmansEye then
        H.insertMultipleInArray(rightHeadBlock, {
            vGap10,
            head("Marksman's Eye Level"),
            text(I.MarksmansEye.Level()),
        })
    end

    local leftBlock = {}
    local rightBlock = {}

    if maxHealthMod ~= 0 then
        H.insertMultipleInArray(leftBlock, {
            head(L("fortifyHealthHead")),
            text(tostring(maxHealthMod)),
            vGap10,
        })
    end

    if hasAttrBaseStatsMods then
        table.insert(leftBlock, head(L("baseAttrModsHead")))
        for _, attributeId in ipairs(orderedAttributeIds) do
            if baseAttrMods[attributeId] ~= 0 then
                table.insert(leftBlock, row(C.getStatName("attributes", attributeId), tostring(baseAttrMods[attributeId])))
            end
        end
        table.insert(leftBlock, vGap10)
    end

    H.insertMultipleInArray(leftBlock, {
        head(L("skillsHead") .. " "
                .. (hasSkillBaseStatsMods and (L("baseModsHead") .. " ; ") or "")
                .. L("progressHead")
                .. (hasDecay and " ; " .. L("decayHead") or "")),
        vGap10,
    })

    H.insertMultipleInArray(leftBlock, skillRows.combatBlock)

    H.insertMultipleInArray(rightBlock, skillRows.magicBlock)
    table.insert(rightBlock, vGap10)
    H.insertMultipleInArray(rightBlock, skillRows.thiefBlock)

    table.insert(leftHeadBlock, 1, vMargin)
    table.insert(leftBlock, vMargin)
    table.insert(rightHeadBlock, 1, vMargin)
    table.insert(rightBlock, vMargin)

    return menu({
        type = ui.TYPE.Flex,
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            size = v2(260, 50)
                        },
                        content = ui.content(leftHeadBlock)
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            size = v2(30, 50)
                        },
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            size = v2(260, 50)
                        },
                        content = ui.content(rightHeadBlock)
                    },
                }
            },
            vGap10,
            stretchingLine,
            vGap10,
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            size = v2(260, 200)
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
                            size = v2(260, 200)
                        },
                        content = ui.content(rightBlock)
                    },
                }
            }
        }
    }, 640, 200)
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
        -- Update player stats and then show menu
        self:sendEvent('showStatsMenu')
    end
end

local function showStatsMenu()
    local statsMenu = getStatsMenu()

    if ncgdStatsMenu == nil then
        ncgdStatsMenu = ui.create(statsMenu)
    else
        ncgdStatsMenu.layout = statsMenu
        ncgdStatsMenu:update()
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
    showStatsMenu = showStatsMenu,
}
