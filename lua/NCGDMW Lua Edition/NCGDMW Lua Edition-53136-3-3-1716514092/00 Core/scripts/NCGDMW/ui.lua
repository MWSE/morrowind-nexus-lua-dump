local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local self = require('openmw.self')
local ui = require('openmw.ui')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")
local Player = require('openmw.types').Player
local util = require('openmw.util')
local calendar = require('openmw_aux.calendar')

local cfg = require('scripts.NCGDMW.configuration')
local S = require('scripts.NCGDMW.settings')
local C = require('scripts.NCGDMW.common')
local H = require('scripts.NCGDMW.helpers')

local L = core.l10n(S.MOD_NAME)

local ncgdStatsMenu

local orderedAttributeIds = { "strength", "intelligence", "willpower", "agility", "speed", "endurance", "personality", "luck" }

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

local vGap10 = padding(0, 10)
local vMargin = padding(0, 30)

local stretchingLine = {
    template = I.MWUI.templates.horizontalLineThick,
    external = {
        stretch = 1,
    },
}

local textDecayColor = util.color.rgb(96 / 255, 134 / 255, 202 / 255)
local textNormalColor = I.MWUI.templates.textNormal.props.textColor

local function text(str, extraProps)
    local props = { text = str }
    if extraProps then
        for k, v in pairs(extraProps) do
            props[k] = v
        end
    end
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = props,
    }
end

local function textCells(...)
    local texts = { ... }
    local cells = {}
    for _, cell in ipairs(texts) do
        table.insert(cells, {
            type = ui.TYPE.Flex,
            props = { size = util.vector2(cell.width, 0), arrange = ui.ALIGNMENT.End },
            content = ui.content { text(cell.text, cell.props) }
        })
    end
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        content = ui.content {
            table.unpack(cells)
        }
    }
end

local function textCell(width, str, props)
    return { width = width, text = str, props = props }
end

local function row(key, content, isHead)
    local left, right
    if type(key) == "string" then
        left = isHead and head(key) or text(key)
    else
        left = key
    end
    if type(content) == "string" then
        right = isHead and head(content) or text(content)
    else
        right = content
    end
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        external = { stretch = 1 },
        content = ui.content {
            left,
            growingInterval,
            right,
        }
    }
end

local function headRow(key, value)
    return row(key, value, true)
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
        props = { size = v2(width, height) },
        content = ui.content {
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
        }
    })
end

local function getSkillsRows(getSkillValues)
    local combatBlock = {
        head(L("skillsCombatHead")),
    }
    for _, skillId in ipairs(C.skillsBySchool().combat) do
        table.insert(combatBlock, getSkillValues(skillId))
    end

    local magicBlock = {
        head(L("skillsMagicHead")),
    }
    for _, skillId in ipairs(C.skillsBySchool().magic) do
        table.insert(magicBlock, getSkillValues(skillId))
    end

    local thiefBlock = {
        head(L("skillsThiefHead")),
    }
    for _, skillId in ipairs(C.skillsBySchool().stealth) do
        table.insert(thiefBlock, getSkillValues(skillId))
    end

    return { combatBlock = combatBlock, magicBlock = magicBlock, thiefBlock = thiefBlock }
end

local function formatPercent(skillVal)
    return string.format("%s%%", math.floor(skillVal * 100 + 0.5))
end

local menuWidth = 900
local menuHMargin = 40
local menuBlockHGap = 50
local menuHeadHBlockSize = v2((menuWidth - menuBlockHGap * 2 - menuHMargin * 2) / 3, 0)
local menuHBlockSize = v2((menuWidth - menuBlockHGap - menuHMargin * 2) / 2, 0)
local menuHGapSize = v2(menuBlockHGap, 0)
local menuCellWidth = 35
local menuPercentCellWidth = 40

local function getStatsMenu()
    local growthRate = S.attributesStorage:get("growthRate")
    local decayRate = S.skillsStorage:get("decayRate")
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

    local leftHeadBlock = {}
    local centerHeadBlock = {}
    local rightHeadBlock = {}

    H.insertMultipleInArray(leftHeadBlock, {
        head(L("levelHead")),
        text(tostring(Player.stats.level(self).current)),
        vGap10,
        head(L("levelProgressHead")),
        text(tostring(I.NCGDMW.LevelProgress())),
    })

    H.insertMultipleInArray(centerHeadBlock, {
        head(L("Settings")),
        row(L("growthRate_name"), L(growthRate)),
        row(L("decayRate_name"), L(decayRate)),
    })

    if I.MarksmansEye then
        H.insertMultipleInArray(centerHeadBlock, {
            vGap10,
            head(L("marksmansEyeHead")),
            text(I.MarksmansEye.Level()),
        })
    end

    H.insertMultipleInArray(rightHeadBlock, {
        head(L("gameTimeHead")),
        text(calendar.formatGameTime()),
        vGap10,
        head(L("daysPassedHead")),
        text(tostring(math.floor(C.totalGameTimeInHours() / 24))),
    })

    local leftBlock = {}
    local rightBlock = {}

    if maxHealthMod ~= 0 then
        H.insertMultipleInArray(leftBlock, {
            head(L("fortifyHealthHead")),
            text(tostring(maxHealthMod)),
            vGap10,
        })
    end

    H.insertMultipleInArray(leftBlock, {
        headRow(L("attributesHead"),
                (hasAttrBaseStatsMods and (L("statsModifierHead") .. " - ") or "")
                        .. L("attributesGrowthHead") .. " - "
                        .. L("attributesStartHead") .. " - "
                        .. L("statsBaseHead")),
        vGap10
    })

    for _, attributeId in ipairs(orderedAttributeIds) do
        table.insert(leftBlock, row(
                C.getStatName("attributes", attributeId),
                textCells(
                        textCell(
                                menuCellWidth,
                                baseAttrMods[attributeId] ~= 0 and (tostring(baseAttrMods[attributeId])) or ""),
                        textCell(
                                menuCellWidth,
                                tostring(H.round(
                                        Player.stats.attributes[attributeId](self).base - baseAttrMods[attributeId] - C.startAttributes()[attributeId],
                                        1))),
                        textCell(
                                menuCellWidth,
                                tostring(H.round(C.startAttributes()[attributeId], 1))),
                        textCell(
                                menuCellWidth,
                                tostring(Player.stats.attributes[attributeId](self).base))
                )
        ))
    end
    table.insert(leftBlock, vGap10)

    local hasDecay = decayRate ~= "none"
    -- percentage won't update until decay mem is updated and decay memory doesn't adjust after you change the decay rate
    local hasUncapper = S.skillsStorage:get("uncapperEnabled")

    H.insertMultipleInArray(leftBlock, {
        headRow(L("skillsHead"),
                L("skillsProgressHead")
                        .. (hasDecay and " - " .. L("skillsDecayHead") or "")
                        .. (hasSkillBaseStatsMods and (" - " .. L("statsModifierHead")) or "")
                        .. " - " .. L("statsBaseHead")),
        vGap10,
    })

    local skillRows = getSkillsRows(function(skillId)
        local base = Player.stats.skills[skillId](self).base
        local decayPercent = C.decaySkills()[skillId] / cfg.decayTimeBaseInHours
        return row(
                C.getStatName("skills", skillId),
                textCells(
                        textCell(
                                menuPercentCellWidth,
                                (hasUncapper or base < 100) and formatPercent(C.skillProgress()[skillId]) or "--%"),
                        textCell(
                                hasDecay and menuPercentCellWidth or 0,
                                hasDecay and formatPercent(decayPercent) or "",
                                { textColor = H.mixColors(textDecayColor, textNormalColor, decayPercent) }),
                        textCell(
                                hasSkillBaseStatsMods and menuCellWidth or 0,
                                baseStatsMods.skills[skillId] and tostring(baseStatsMods.skills[skillId]) or ""),
                        textCell(
                                menuCellWidth,
                                tostring(base),
                                C.baseSkills()[skillId] < C.maxSkills()[skillId] and { textColor = textDecayColor } or nil)
                )
        )
    end)

    H.insertMultipleInArray(leftBlock, skillRows.combatBlock)

    H.insertMultipleInArray(rightBlock, skillRows.magicBlock)
    table.insert(rightBlock, vGap10)
    H.insertMultipleInArray(rightBlock, skillRows.thiefBlock)

    table.insert(leftHeadBlock, 1, vMargin)
    table.insert(centerHeadBlock, 1, vMargin)
    table.insert(rightHeadBlock, 1, vMargin)

    if not S.globalStorage:get("showMessagesLog") then
        table.insert(leftBlock, vMargin)
        table.insert(rightBlock, vMargin)
    end

    local menuContent = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeadHBlockSize },
                    content = ui.content(leftHeadBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeadHBlockSize },
                    content = ui.content(centerHeadBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeadHBlockSize, arrange = ui.ALIGNMENT.End },
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
                    props = { size = menuHBlockSize },
                    content = ui.content(leftBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHBlockSize },
                    content = ui.content(rightBlock)
                },
            }
        }
    }

    if S.globalStorage:get("showMessagesLog") then
        local messagesBlock = {
            headRow(L("messagesLogTitleHead"), L("messagesLogTimestampHead")),
            vGap10
        }
        for _, log in ipairs(C.messagesLog()) do
            table.insert(messagesBlock, row(log.message, log.time))
        end
        table.insert(messagesBlock, vMargin)
        H.insertMultipleInArray(menuContent, {
            vGap10,
            stretchingLine,
            vGap10,
            {
                type = ui.TYPE.Flex,
                external = { stretch = 1 },
                content = ui.content(messagesBlock)
            }
        })
    end

    return menu({
        type = ui.TYPE.Flex,
        content = ui.content(menuContent)
    }, menuWidth, 0)
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
        return
    end

    if key.code == S.globalStorage:get("statsMenuKey") then
        -- Update player stats and then show menu
        self:sendEvent('showStatsMenu', { create = true })
    end
end

local function showStatsMenu(data)
    local statsMenu = getStatsMenu()

    if ncgdStatsMenu == nil then
        if not data.create then return end
        ncgdStatsMenu = ui.create(statsMenu)
    else
        if data.create then return end
        ncgdStatsMenu.layout = statsMenu
        ncgdStatsMenu:update()
    end
    async:newUnsavableSimulationTimer(
            1,
            function()
                if ncgdStatsMenu ~= nil then
                    self:sendEvent('showStatsMenu', { create = false })
                end
            end)
end

local function onKeyRelease(key)
    if key.code == S.globalStorage:get("statsMenuKey") then
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
