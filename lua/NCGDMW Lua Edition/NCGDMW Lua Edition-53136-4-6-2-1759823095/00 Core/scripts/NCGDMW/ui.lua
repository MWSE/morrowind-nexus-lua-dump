local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local storage = require('openmw.storage')
local self = require('openmw.self')
local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local util = require('openmw.util')
local calendar = require('openmw_aux.calendar')

local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mS = require('scripts.NCGDMW.settings')
local mCore = require('scripts.NCGDMW.core')
local mC = require('scripts.NCGDMW.common')
local mH = require('scripts.NCGDMW.helpers')

local Attributes = core.stats.Attribute.records
local L = core.l10n(mDef.MOD_NAME)

local ncgdStatsMenu
local ncgdTooltip
local lastTooltipMessage
local isStarwindMode = mCore.isStarwindMode()
local hudLayerSize = ui.layers[ui.layers.indexOf("HUD")].size
local notifs = {}
local notifCount = 0
local lastFrameTime = core.getRealTime()

local module = {}

local textDecayColor = util.color.rgb(96 / 255, 134 / 255, 202 / 255)
local textNormalColor = I.MWUI.templates.textNormal.props.textColor

local function padding(horizontal, vertical)
    return { props = { size = util.vector2(horizontal, vertical) } }
end

local vGap10 = padding(0, 10)
local vGap20 = padding(0, 20)
local hGap20 = padding(20, 0)
local vMargin = padding(0, 30)
local hMargin = padding(30, 0)

local function getDateStr()
    if isStarwindMode then
        return '%H:%M day %d of %b %Y BBY'
    else
        return '%H:%M day %d of %b %Y'
    end
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

local stretchingLine = {
    template = I.MWUI.templates.horizontalLineThick,
    external = { stretch = 1 },
}

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

module.notify = function(message)
    notifCount = notifCount + 1
    local center = hudLayerSize / 2
    center = util.vector2(center.x, center.y + 40 * (notifCount % 10 - 5))
    local notif = {
        layer = "Notification",
        template = I.MWUI.templates.boxTransparent,
        props = {
            position = center,
            anchor = util.vector2(1, 1)
        },
        content = ui.content {
            padding(0, 20),
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    padding(10, 0),
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = { text = message, multiline = true, textSize = 16, textAlignH = ui.ALIGNMENT.Center },
                    },
                    padding(10, 0),
                }
            },
            padding(0, 20),
        }
    }
    local notifUi = ui.create(notif)
    table.insert(notifs, { time = 0, pos = notifUi.layout.props.position, ui = notifUi })
end

local function centerWindow(content)
    return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = util.vector2(.5, .5),
            anchor = util.vector2(.5, .5)
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
                content = ui.content { hMargin, content, hMargin }
            },
            vMargin,
        }
    })
end

local function getSkillsRows(state, getSkillsHeader, getSkillValues)
    local majorBlock = {
        table.unpack(getSkillsHeader(L("skillsMajorHead"))),
    }
    for _, skillId in ipairs(state.skills.majorOrder) do
        table.insert(majorBlock, getSkillValues(skillId))
    end

    local minorBlock = {
        table.unpack(getSkillsHeader(L("skillsMinorHead"))),
    }
    for _, skillId in ipairs(state.skills.minorOrder) do
        table.insert(minorBlock, getSkillValues(skillId))
    end

    local miscBlock = {
        table.unpack(getSkillsHeader(L("skillsMiscHead"))),
    }
    for _, skillId in ipairs(state.skills.miscOrder) do
        table.insert(miscBlock, getSkillValues(skillId))
    end

    return { majorBlock = majorBlock, minorBlock = minorBlock, miscBlock = miscBlock }
end

local function formatPercent(skillVal)
    return string.format("%s%%", util.round(skillVal * 100))
end

local function createTooltip(message, position)
    return ui.create(toolTip(text(message, { multiline = true }), position))
end

local function tooltipPosition(mousePosition)
    return util.vector2(mousePosition.x - 20, mousePosition.y + 30)
end

local function closeTooltip()
    if ncgdTooltip ~= nil then
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
            if ncgdTooltip == nil then
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

local menuBlockHGap = 40
local menuHGapSize = util.vector2(menuBlockHGap, 0)
local menuCellWidth = 35
local menuPercentCellWidth = 40

local function getMenuWidth()
    return mS.globalStorage:get("statsMenuWidth")
end
local function getMenuHeaderHBlockSize()
    return util.vector2((getMenuWidth() - menuBlockHGap * 3) / 4, 0)
end
local function getMenuHBlockSize()
    return util.vector2((getMenuWidth() - menuBlockHGap * 2) / 3, 0)
end

local function getStatsMenu(state)
    local baseStatsMods = mC.getBaseStatsModifiers()
    local baseAttrMods = {}
    local hasAttrBaseStatsMods = false
    local hasSkillBaseStatsMods = false

    for attrId, _ in pairs(T.Actor.stats.attributes) do
        local baseMod = baseStatsMods.attributes[attrId] or 0
        baseAttrMods[attrId] = baseMod + state.attrs.diffs[attrId]
        if baseAttrMods[attrId] ~= 0 then
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
    local centerLeftHeadBlock = {}
    local centerRightHeadBlock = {}
    local rightHeadBlock = {}

    mH.insertMultipleInArray(leftHeadBlock, {
        head(L("levelHead")),
        text(tostring(mC.self.level.current)),
        vGap10,
        head(L("levelProgressHead")),
        text(tostring(util.round(state.lvlProg)) .. "%"),
    })

    local decayRate = mS.skillsStorage:get("skillDecayRate")
    mH.insertMultipleInArray(centerLeftHeadBlock, {
        head(L("statsAttrSettingsHead")),
        row(L("startValuesRatio_name"), L(mS.attributesStorage:get("startValuesRatio"))),
        row(L("attributeGrowthRate_name"), L(mS.attributesStorage:get("attributeGrowthRate"))),
    })
    local gainFactor = mS.skillsStorage:get("skillGainFactorRange")
    mH.insertMultipleInArray(centerRightHeadBlock, {
        head(L("statsSkillSettingsHead")),
        row(L("skillGainFactor"), L("skillGainFactorRange", { from = gainFactor[1], to = gainFactor[2] })),
        row(L("skillDecayRate_name"), L(decayRate)),
    })

    local dayDeathBlock = {
        hGap20,
        {
            type = ui.TYPE.Flex,
            props = { arrange = ui.ALIGNMENT.End },
            content = ui.content {
                head(L("daysPassedHead")),
                text(tostring(math.floor(mCore.totalGameTimeInHours() / 24))),
            }
        }
    }

    if mS.healthStorage:get("deathCounter") then
        table.insert(dayDeathBlock, 1, {
            type = ui.TYPE.Flex,
            props = { arrange = ui.ALIGNMENT.End },
            content = ui.content {
                head(L("deathCount")),
                text(tostring(storage.playerSection(state.profileId):get("deathCount"))),
            }
        })
    end

    mH.insertMultipleInArray(rightHeadBlock, {
        head(L("gameTimeHead")),
        text(calendar.formatGameTime(getDateStr())),
        vGap10,
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content(dayDeathBlock),
        }
    })

    local leftBlock = {}
    local centerBlock = {}
    local rightBlock = {}

    mH.insertMultipleInArray(leftBlock, {
        headRow(L("attributesHead"),
                (hasAttrBaseStatsMods and (L("statsModifierHead") .. " - ") or "")
                        .. L("attributesGrowthHead") .. " - "
                        .. L("attributesStartHead") .. " - "
                        .. L("statsCurrentHead")),
        vGap10
    })

    for _, attr in ipairs(Attributes) do
        table.insert(leftBlock, row(
                mCore.getStatName("attributes", attr.id),
                textCells(
                        textCell(
                                menuCellWidth,
                                baseAttrMods[attr.id] ~= 0 and (tostring(baseAttrMods[attr.id])) or "",
                                nil,
                                tooltipEvent(L("modifierAttributeValue"))),
                        textCell(
                                menuCellWidth,
                                tostring(T.Actor.stats.attributes[attr.id](self).base
                                        - baseAttrMods[attr.id] - state.attrs.start[attr.id]),
                                nil,
                                tooltipEvent(L("growthAttributeValue"))),
                        textCell(
                                menuCellWidth,
                                tostring(state.attrs.start[attr.id]),
                                nil,
                                tooltipEvent(L("startAttributeValue"))
                        ),
                        textCell(
                                menuCellWidth,
                                tostring(T.Actor.stats.attributes[attr.id](self).base),
                                nil,
                                tooltipEvent(L("currentAttributeValue")))
                )
        ))
    end

    local maxHealthMod = mCore.getMaxHealthModifier(self)
    if maxHealthMod ~= 0 then
        mH.insertMultipleInArray(leftBlock, {
            vGap10,
            head(L("fortifyHealthHead")),
            text(tostring(maxHealthMod)),
        })
    end

    if I.MarksmansEye then
        mH.insertMultipleInArray(leftBlock, {
            vGap10,
            head(L("marksmansEyeHead")),
            text(I.MarksmansEye.Level()),
        })
    end

    local hasDecay = decayRate ~= "skillDecayNone"
    -- percentage won't update until decay mem is updated and decay memory doesn't adjust after you change the decay rate
    local skillsMaxValue = mS.skillsStorage:get("uncapperMaxValue")
    local perSkillMaxValues = mS.getPerSkillMaxValues()

    local function getSkillsHeader(skillTypeName)
        return {
            headRow(skillTypeName,
                    L("skillsProgressHead")
                            .. (hasDecay and " - " .. L("skillsDecayHead") or "")
                            .. (hasSkillBaseStatsMods and (" - " .. L("statsModifierHead")) or "")
                            .. " - " .. L("statsCurrentHead")),
            vGap10,
        }
    end

    local skillRows = getSkillsRows(state, getSkillsHeader, function(skillId)
        local base = state.skills.base[skillId] + (baseStatsMods.skills[skillId] or 0)
        local decayPercent = state.skills.decay[skillId] / mCfg.decayTimeBaseInHours
        return row(
                mCore.getStatName("skills", skillId),
                textCells(
                        textCell(
                                menuPercentCellWidth,
                                (base < (perSkillMaxValues[skillId] or skillsMaxValue)) and formatPercent(state.skills.progress[skillId]) or "--%",
                                nil,
                                tooltipEvent(L("progressSkillValue"))
                        ),
                        textCell(
                                hasDecay and menuPercentCellWidth or 0,
                                hasDecay and formatPercent(decayPercent) or "",
                                { textColor = mH.mixColors(textDecayColor, textNormalColor, decayPercent) },
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
                                state.skills.base[skillId] < state.skills.max[skillId] and { textColor = textDecayColor } or nil,
                                tooltipEvent(L("currentSkillValue"))
                        )
                )
        )
    end)

    mH.insertMultipleInArray(centerBlock, skillRows.majorBlock)
    table.insert(centerBlock, vGap10)
    mH.insertMultipleInArray(centerBlock, skillRows.minorBlock)

    mH.insertMultipleInArray(rightBlock, skillRows.miscBlock)

    local menuHeaderHBlockSize = getMenuHeaderHBlockSize()
    local menuHBlockSize = getMenuHBlockSize()

    local menuContent = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize },
                    content = ui.content(leftHeadBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize },
                    content = ui.content(centerLeftHeadBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize },
                    content = ui.content(centerRightHeadBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize, arrange = ui.ALIGNMENT.End },
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
                    content = ui.content(centerBlock)
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

    if mS.globalStorage:get("showMessagesLog") then
        local messagesBlock = {
            headRow(L("messagesLogTitleHead"), L("messagesLogTimestampHead")),
            vGap10
        }
        for _, log in ipairs(state.messagesLog) do
            table.insert(messagesBlock, row(log.message, log.time))
        end
        mH.insertMultipleInArray(menuContent, {
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

module.missingPluginWarning = function(message, plugins)
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
    mH.insertMultipleInArray(lines, {
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

module.onKeyPress = function(key)
    -- Prevent the stats menu from rendering over the escape menu
    if key.code == input.KEY.Escape then
        closeMenu()
        return
    end

    if key.code == mS.globalStorage:get("statsMenuKey") then
        -- Update player stats and then show menu
        self:sendEvent(mDef.events.showStatsMenu, { create = true })
    end
end

module.onKeyRelease = function(key)
    if key.code == mS.globalStorage:get("statsMenuKey") then
        closeMenu()
    end
end

module.showStatsMenu = function(state, data)
    local statsMenu = getStatsMenu(state)

    if ncgdStatsMenu == nil then
        if not data.create then return end
        ncgdStatsMenu = ui.create(statsMenu)
    else
        if data.create then return end
        ncgdStatsMenu.layout = statsMenu
        ncgdStatsMenu:update()
    end
    async:newUnsavableSimulationTimer(1, function()
        if ncgdStatsMenu ~= nil then
            self:sendEvent(mDef.events.showStatsMenu, { create = false })
        end
    end)
end

module.onFrame = function()
    local frameTime = core.getRealTime()
    local deltaTime = frameTime - lastFrameTime
    lastFrameTime = frameTime
    local i = 1
    while i <= #notifs do
        local notif = notifs[i]
        notif.time = notif.time + deltaTime
        notif.ui.layout.props.position = util.vector2(notif.pos.x - (100 * notif.time), notif.ui.layout.props.position.y)
        notif.ui:update()
        if notif.ui.layout.props.position.x < 0 then
            table.remove(notifs, i)
            notif.ui:destroy()
        else
            i = i + 1
        end
    end
end

return module
