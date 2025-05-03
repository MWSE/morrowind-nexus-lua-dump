local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local storage = require('openmw.storage')
local self = require('openmw.self')
local ui = require('openmw.ui')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")
local Player = require('openmw.types').Player
local util = require('openmw.util')
local calendar = require('openmw_aux.calendar')

local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mSettings = require('scripts.NCGDMW.settings')
local mCommon = require('scripts.NCGDMW.common')
local mHelpers = require('scripts.NCGDMW.helpers')

local L = core.l10n(mDef.MOD_NAME)

local ncgdStatsMenu
local ncgdTooltip
local lastTooltipMessage
local isStarwindMode = mCommon.isStarwindMode()

local orderedAttributeIds = { "strength", "intelligence", "willpower", "agility", "speed", "endurance", "personality", "luck" }

local module = {}

local function getDateStr()
    if isStarwindMode then
        return '%I:%M %p, %d %b, %Y BBY'
    else
        return '%I:%M %p'
    end
end

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
local hGap20 = padding(20, 0)
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

local menuWidth = 1100
local menuHMargin = 40
local menuBlockHGap = 40
local menuBlockHGap2 = 20
local menuHeaderHBlock = menuWidth - menuBlockHGap * 3 - menuBlockHGap2 * 2 - menuHMargin * 2
local menuHeaderHBlockSize = v2(menuHeaderHBlock / 4, 0)
local menuHeaderHBlockSize2 = v2(menuHeaderHBlock / 8, 0)
local menuHBlockSize = v2((menuWidth - menuBlockHGap * 2 - menuHMargin * 2) / 3, 0)
local menuHGapSize = v2(menuBlockHGap, 0)
local menuHGapSize2 = v2(menuBlockHGap2, 0)
local menuCellWidth = 35
local menuCellWidth2 = 30
local menuPercentCellWidth = 40

local function getStatsMenu(state)
    local baseStatsMods = mCommon.getBaseStatsModifiers()
    local baseAttrMods = {}
    local baseSkillMods = {}
    local hasAttrBaseStatsMods = false
    local hasAttrGrowth = false
    local hasSkillBaseStatsMods = false
    local hasSkillGrowth = false
    local hasSkillBonus = false

    for attrId, _ in pairs(Player.stats.attributes) do
        local baseMod = baseStatsMods.attributes[attrId] or 0
        baseAttrMods[attrId] = baseMod + state.attrs.diffs[attrId]
        if baseAttrMods[attrId] ~= 0 then
            hasAttrBaseStatsMods = true
        end
        if state.attrs.growth[attrId] ~= 0 then
            hasAttrGrowth = true
        end
    end
    for skillId, _ in pairs(Player.stats.skills) do
        baseSkillMods[skillId] = baseStatsMods.skills[skillId] or 0
        if baseSkillMods[skillId] ~= 0 then
            hasSkillBaseStatsMods = true
        end
        if state.skills.growth[skillId] ~= 0 then
            hasSkillGrowth = true
        end
        if state.skills.books.totalGain[skillId] ~= 0 then
            hasSkillBonus = true
        end
    end

    local leftHeadBlock = {}
    local centerLeftHeadBlock = {}
    local centerRightHeadBlock = {}
    local rightHeadBlock = {}

    local rightCenterHeadBlock = {}
    local leftCenterHeadBlock = {}

    mHelpers.insertMultipleInArray(rightHeadBlock, {
        head(L("gameTimeHead")),
        text(calendar.formatGameTime(getDateStr())),
        vGap10,
        head(L("daysPassedHead")),
        text(tostring(math.floor(mCommon.totalGameTimeInHours() / 24))),
    })

    mHelpers.insertMultipleInArray(leftHeadBlock, {
        head(L("levelHead")),
        text(tostring(Player.stats.level(self).current)),
        vGap10,
        head(L("levelProgressHead")),
        text(tostring(I.NCGDMW.LevelProgress())),
    })

    local decayRate = mSettings.skillsStorage:get("skillDecayRate")
    mHelpers.insertMultipleInArray(centerLeftHeadBlock, {
        head(L("statsAttrSettingsHead")),
        row(L("startAttributesPenalty_name"), tostring(mSettings.attributesStorage:get("startAttributesPenalty"))),
        row(L("attributeGrowthBase_name"), tostring(mSettings.attributesStorage:get("attributeGrowthBase"))),
        row(L("luckReputationGrowthBase_name"), tostring(mSettings.attributesStorage:get("luckReputationGrowthBase"))),
    })
    local gainFactor = mSettings.skillsStorage:get("skillGainFactorRange")
    mHelpers.insertMultipleInArray(centerRightHeadBlock, {
        head(L("statsSkillSettingsHead")),
        row(L("uncapperMaxValue_name"), tostring(mSettings.skillsStorage:get("uncapperMaxValue"))),
        row(L("skillGainFactor"), L("skillGainFactorRange", { from = gainFactor[1], to = gainFactor[2] })),
        row(L("skillDecayRate_name"), L(decayRate)),
    })

    local trainingSessionsBlock = {

    }
    if mSettings.skillsStorage:get("capSkillTrainingLevel") then
        table.insert(trainingSessionsBlock, 1, {
            type = ui.TYPE.Flex,
            props = { arrange = ui.ALIGNMENT.End },
            content = ui.content {
                head(L("trainingSessionsHead")),
                text(tostring(state.skills.training.sessions)),
            }
        })
    end

    mHelpers.insertMultipleInArray(rightCenterHeadBlock, {
        head(L("playerBirthsignHead")),
        text(state.chargen.birthsign),
        vGap10,
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content(trainingSessionsBlock),
        }
    })

    mHelpers.insertMultipleInArray(leftCenterHeadBlock, {
        head(L("playerRaceHead")),
        text(state.chargen.race),
        vGap10,
        head(L("reputationHead")),
        text(tostring(state.reputation)),
    })

    local leftBlock = {}
    local centerBlock = {}
    local rightBlock = {}

    mHelpers.insertMultipleInArray(leftBlock, {
        headRow(L("attributesHead"),
                        L("statsRaceHead") .. "-"
                        .. L("statsStartHead")
                        .. (hasAttrGrowth and ("-" .. L("statsGrowthHead")) or "")
                        .. (hasAttrBaseStatsMods and ("-" .. L("statsModifierHead")) or "")
                        .. "-" .. L("statsBaseHead")),
        vGap10
    })

    for _, attrId in ipairs(orderedAttributeIds) do
        table.insert(leftBlock, row(
                mCommon.getStatName("attributes", attrId),
                textCells(
                        textCell(
                                menuCellWidth,
                                tostring(math.floor(state.attrs.race[attrId])),
                                nil,
                                tooltipEvent(L("raceAttributeValue"))),
                        textCell(
                                menuCellWidth,
                                tostring(math.floor(state.attrs.start[attrId])),
                                nil,
                                tooltipEvent(L("startAttributeValue"))
                        ),
                        textCell(
                                hasAttrGrowth and menuCellWidth or 0,
                                state.attrs.growth[attrId] ~= 0 and (tostring(math.floor(state.attrs.growth[attrId]))) or "",
                                nil,
                                tooltipEvent(L("growthAttributeValue"))),
                        textCell(
                                hasAttrBaseStatsMods and menuCellWidth or 0,
                                baseAttrMods[attrId] ~= 0 and (tostring(baseAttrMods[attrId])) or "",
                                nil,
                                tooltipEvent(L("modifierAttributeValue"))),
                        textCell(
                                menuCellWidth,
                                tostring(math.floor(Player.stats.attributes[attrId](self).base)),
                                nil,
                                tooltipEvent(L("currentAttributeValue")))
                )
        ))
    end
    
    local nameClassBlock = {}
    local favBlock = {}
    local specFavBlock = {}

    mHelpers.insertMultipleInArray(nameClassBlock, {
        head(L("nameHead")),
        text(state.chargen.name),
        vGap10,
        head(L("classHead")),
        text(state.chargen.class)
    })

    for _, attrId in ipairs(orderedAttributeIds) do
        table.insert(favBlock, row(
            state.attrs.favored[attrId] and mCommon.getStatName("attributes", attrId)
        ))
    end

    mHelpers.insertMultipleInArray(specFavBlock, {
        head(L("specializationHead")),
        text(state.chargen.specialization),
        vGap10,
        head(L("favoredHead")),
        {
            type = ui.TYPE.Flex,
            props = { horizontal = false },
            content = ui.content(favBlock),
        }
    })

    local bottomLeftBlock = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize2 },
                    content = ui.content(nameClassBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize2 },
                    content = ui.content(specFavBlock)
                },
            }
        }
    }

    mHelpers.insertMultipleInArray(leftBlock, {
        vGap10,
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content(bottomLeftBlock),
        }
    })

    --[[local maxHealthMod = mCommon.getMaxHealthModifier()
    if maxHealthMod ~= 0 then
        mHelpers.insertMultipleInArray(leftBlock, {
            vGap10,
            head(L("fortifyHealthHead")),
            text(tostring(maxHealthMod)),
        })
    end

    if I.MarksmansEye then
        mHelpers.insertMultipleInArray(leftBlock, {
            vGap10,
            head(L("marksmansEyeHead")),
            text(I.MarksmansEye.Level()),
        })
    end --]]

    local hasDecay = decayRate ~= "skillDecayNone"
    -- percentage won't update until decay mem is updated and decay memory doesn't adjust after you change the decay rate
    local skillsMaxValue = mSettings.skillsStorage:get("uncapperMaxValue")
    local perSkillMaxValues = mSettings.getPerSkillMaxValues()

    local function getSkillsHeader(skillTypeName)
        return {
            headRow(skillTypeName,
                    L("skillsProgressHead")
                            .. (hasDecay and "-" .. L("skillsDecayHead") or "")
                            .. (hasSkillBonus and "-" .. L("skillsBonusExpHead") or "")
                            .. "-" .. L("statsStartHead")
                            .. (hasSkillGrowth and ("-" .. L("statsGrowthHead")) or "")
                            .. (hasSkillBaseStatsMods and ("-" .. L("statsModifierHead")) or "")
                            .. "-" .. L("statsBaseHead")),
            vGap10,
        }
    end

    local skillRows = getSkillsRows(state, getSkillsHeader, function(skillId)
        local base = Player.stats.skills[skillId](self).base
        local decayPercent = state.skills.decay[skillId] / mCfg.decayTimeBaseInHours
        return row(
                mCommon.getStatName("skills", skillId),
                textCells(
                        textCell(
                                menuPercentCellWidth,
                                (state.skills.base[skillId] < (perSkillMaxValues[skillId] or skillsMaxValue)) and formatPercent(state.skills.progress[skillId]) or "--%",
                                nil,
                                tooltipEvent(L("progressSkillValue"))
                        ),
                        textCell(
                                hasDecay and menuPercentCellWidth or 0,
                                hasDecay and formatPercent(decayPercent) or "",
                                { textColor = mHelpers.mixColors(textDecayColor, textNormalColor, decayPercent) },
                                tooltipEvent(L("decaySkillValue"))
                        ),
                        textCell(
                                hasSkillBonus and menuPercentCellWidth or 0,
                                state.skills.books.totalGain[skillId] ~= 0 and tostring(math.floor(state.skills.books.totalGain[skillId]) .. "%") or "",
                                nil,
                                tooltipEvent(L("bonusExpSkillValue"))
                        ),
                        textCell(
                                menuCellWidth2,
                                tostring(state.skills.start[skillId]),
                                nil,
                                tooltipEvent(L("startSkillValue"))
                        ),
                        textCell(
                                hasSkillGrowth and menuCellWidth2 or 0,
                                state.skills.growth[skillId] ~= 0 and (tostring(state.skills.growth[skillId])) or "",
                                nil,
                                tooltipEvent(L("growthSkillValue"))),
                        textCell(
                                hasSkillBaseStatsMods and menuCellWidth2 or 0,
                                baseStatsMods.skills[skillId] and tostring(baseStatsMods.skills[skillId]) or "",
                                nil,
                                tooltipEvent(L("modifierSkillValue"))
                        ),
                        textCell(
                                menuCellWidth2,
                                tostring(base),
                                state.skills.base[skillId] < state.skills.max[skillId] and { textColor = textDecayColor } or nil,
                                tooltipEvent(L("currentSkillValue"))
                        )
                )
        )
    end)

    mHelpers.insertMultipleInArray(centerBlock, skillRows.majorBlock)
    table.insert(centerBlock, vGap10)
    mHelpers.insertMultipleInArray(centerBlock, skillRows.minorBlock)

    mHelpers.insertMultipleInArray(rightBlock, skillRows.miscBlock)

    local menuContent = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize2 },
                    content = ui.content(leftHeadBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize2 },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize2 },
                    content = ui.content(leftCenterHeadBlock)
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
                    props = { size = menuHeaderHBlockSize2, arrange = ui.ALIGNMENT.End },
                    content = ui.content(rightCenterHeadBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize2 },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHeaderHBlockSize2, arrange = ui.ALIGNMENT.End },
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

    if mSettings.globalStorage:get("showMessagesLog") then
        local messagesBlock = {
            headRow(L("messagesLogTitleHead"), L("messagesLogTimestampHead")),
            vGap10
        }
        for _, log in ipairs(state.messagesLog) do
            table.insert(messagesBlock, row(log.message, log.time))
        end
        mHelpers.insertMultipleInArray(menuContent, {
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
    mHelpers.insertMultipleInArray(lines, {
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
module.missingPluginWarning = missingPluginWarning

local function onKeyPress(key)
    -- Prevent the stats menu from rendering over the escape menu
    if mSettings.globalStorage:get("toggleStatsMenu") == true and key.code == mSettings.globalStorage:get("statsMenuKey") and ncgdStatsMenu ~= nil then
        closeMenu()
        return
    end

    if key.code == mSettings.globalStorage:get("statsMenuKey") and ncgdStatsMenu == nil then
        -- Update player stats and then show menu
        self:sendEvent(mDef.events.showStatsMenu, { create = true })
    end

end
module.onKeyPress = onKeyPress

local function onKeyRelease(key)
    if mSettings.globalStorage:get("toggleStatsMenu") == false and key.code == mSettings.globalStorage:get("statsMenuKey") then
        closeMenu()
    end
end
module.onKeyRelease = onKeyRelease

local function showStatsMenu(state, data)
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
module.showStatsMenu = showStatsMenu

return module
