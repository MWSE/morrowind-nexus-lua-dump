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

local def = require('scripts.NCGDMW.definition')
local cfg = require('scripts.NCGDMW.configuration')
local S = require('scripts.NCGDMW.settings')
local C = require('scripts.NCGDMW.common')
local H = require('scripts.NCGDMW.helpers')

local L = core.l10n(def.MOD_NAME)

local ncgdStatsMenu
local ncgdTooltip
local lastTooltipMessage

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
local vGap20 = padding(0, 20)
local vMargin = padding(0, 30)
local hMargin = padding(30, 0)

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
            content = ui.content { text(cell.text, cell.props) },
            events = cell.events,
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

local function textCell(width, str, props, events)
    return { width = width, text = str, props = props, events = events }
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

local function centerWindow(content)
    return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content { content }
    }
end

local function toolTip(content, position)
    return {
        layer = "Notification",
        template = I.MWUI.templates.boxTransparent,
        props = { position = position },
        content = ui.content {
            padding(0, 5),
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    padding(5, 0),
                    content,
                    padding(5, 0),
                }
            },
            padding(0, 5),
        }
    }
end

local function menu(content)
    return centerWindow({
        type = ui.TYPE.Flex,
        content = ui.content {
            vMargin,
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                external = { stretch = 1 },
                content = ui.content {
                    hMargin,
                    content,
                    hMargin,
                }
            },
            vMargin,
        }
    })
end

local function getSkillsRows(getSkillValues)
    local combatBlock = {
        head(L("skillsCombatHead")),
    }
    for _, skillId in ipairs(def.skillsBySchool[def.skillTypes.combat]) do
        table.insert(combatBlock, getSkillValues(skillId))
    end

    local magicBlock = {
        head(L("skillsMagicHead")),
    }
    for _, skillId in ipairs(def.skillsBySchool[def.skillTypes.magic]) do
        table.insert(magicBlock, getSkillValues(skillId))
    end

    local thiefBlock = {
        head(L("skillsThiefHead")),
    }
    for _, skillId in ipairs(def.skillsBySchool[def.skillTypes.stealth]) do
        table.insert(thiefBlock, getSkillValues(skillId))
    end

    return { combatBlock = combatBlock, magicBlock = magicBlock, thiefBlock = thiefBlock }
end

local function formatPercent(skillVal)
    return string.format("%s%%", math.floor(skillVal * 100 + 0.5))
end

local function createTooltip(message, position)
    return ui.create(toolTip(text(message, { multiline = true }), position))
end

local function tooltipPosition(mousePosition)
    return util.vector2(mousePosition.x - 20, mousePosition.y + 30)
end

local function closeTooltip()
    if (ncgdTooltip ~= nil) then
        ncgdTooltip:destroy()
        ncgdTooltip = nil
    end
end

local function closeMenu()
    if ncgdStatsMenu ~= nil then
        ncgdStatsMenu:destroy()
        ncgdStatsMenu = nil
        closeTooltip()
    end
end

local function tooltipEvent(message)
    return {
        mouseMove = async:callback(function(mouseEvent, _)
            if (ncgdTooltip == nil) then
                ncgdTooltip = createTooltip(message, tooltipPosition(mouseEvent.position))
            else
                if lastTooltipMessage ~= message then
                    closeTooltip()
                    ncgdTooltip = createTooltip(message, mouseEvent.position)
                else
                    ncgdTooltip.layout.props.position = tooltipPosition(mouseEvent.position)
                    ncgdTooltip:update()
                end
            end
            lastTooltipMessage = message
        end)
    }
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
                                baseAttrMods[attributeId] ~= 0 and (tostring(baseAttrMods[attributeId])) or "",
                                nil,
                                tooltipEvent(L("modifierAttributeValue"))),
                        textCell(
                                menuCellWidth,
                                tostring(H.round(
                                        Player.stats.attributes[attributeId](self).base - baseAttrMods[attributeId] - C.startAttributes()[attributeId],
                                        1)),
                                nil,
                                tooltipEvent(L("growthAttributeValue"))),
                        textCell(
                                menuCellWidth,
                                tostring(H.round(C.startAttributes()[attributeId], 1)),
                                nil,
                                tooltipEvent(L("startAttributeValue"))
                        ),
                        textCell(
                                menuCellWidth,
                                tostring(Player.stats.attributes[attributeId](self).base),
                                nil,
                                tooltipEvent(L("currentAttributeValue")))
                )
        ))
    end
    table.insert(leftBlock, vGap10)

    local hasDecay = decayRate ~= "none"
    -- percentage won't update until decay mem is updated and decay memory doesn't adjust after you change the decay rate
    local skillsMaxValue = S.skillsStorage:get("uncapperMaxValue")
    local perSkillMaxValues = S.getPerSkillMaxValues()

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
                                (base < (perSkillMaxValues[skillId] or skillsMaxValue)) and formatPercent(C.skillProgress()[skillId]) or "--%",
                                nil,
                                tooltipEvent(L("progressSkillValue"))
                        ),
                        textCell(
                                hasDecay and menuPercentCellWidth or 0,
                                hasDecay and formatPercent(decayPercent) or "",
                                { textColor = H.mixColors(textDecayColor, textNormalColor, decayPercent) },
                                tooltipEvent(L("decaySkillValue"))
                        ),
                        textCell(
                                hasSkillBaseStatsMods and menuCellWidth or 0,
                                baseStatsMods.skills[skillId] and tostring(baseStatsMods.skills[skillId]) or "",
                                tooltipEvent(L("modifierSkillValue"))
                        ),
                        textCell(
                                menuCellWidth,
                                tostring(base),
                                C.baseSkills()[skillId] < C.maxSkills()[skillId] and { textColor = textDecayColor } or nil,
                                tooltipEvent(L("currentSkillValue"))
                        )
                )
        )
    end)

    H.insertMultipleInArray(leftBlock, skillRows.combatBlock)

    H.insertMultipleInArray(rightBlock, skillRows.magicBlock)
    table.insert(rightBlock, vGap10)
    H.insertMultipleInArray(rightBlock, skillRows.thiefBlock)

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
        content = ui.content(menuContent),
        events = { mouseMove = async:callback(closeTooltip) },
    })
end

local function missingPluginWarning(message, plugins)
    local lines = {
        head(L("pluginError0")),
        vGap20,
        text(L("pluginError1")),
        vGap20,
        text(message),
        vGap20
    }
    for _, plugin in ipairs(plugins) do
        table.insert(lines, text(plugin))
    end
    H.insertMultipleInArray(lines, {
        vGap20,
        text(L("pluginError2")),
        text(L("pluginError3")),
        vGap20,
        text(L("pluginError4")),
    })
    return menu({
        type = ui.TYPE.Flex,
        content = ui.content(lines)
    })
end

local function onKeyPress(key)
    -- Chargen isn't done enough
    if not C.charGenDone() then return end

    -- Prevent the stats menu from rendering over the escape menu
    if key.code == input.KEY.Escape then
        closeMenu()
        return
    end

    if key.code == S.globalStorage:get("statsMenuKey") then
        -- Update player stats and then show menu
        self:sendEvent(def.events.showStatsMenu, { create = true })
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
                    self:sendEvent(def.events.showStatsMenu, { create = false })
                end
            end)
end

local function onKeyRelease(key)
    if key.code == S.globalStorage:get("statsMenuKey") then
        closeMenu()
    end
end

return {
    missingPluginWarning = missingPluginWarning,
    onKeyPress = onKeyPress,
    onKeyRelease = onKeyRelease,
    showStatsMenu = showStatsMenu,
}
