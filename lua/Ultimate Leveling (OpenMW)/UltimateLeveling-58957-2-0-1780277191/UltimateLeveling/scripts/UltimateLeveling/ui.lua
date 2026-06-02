local core = require('openmw.core')
local async = require('openmw.async')
local self = require('openmw.self')
local ui = require('openmw.ui')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")
local Actor = require('openmw.types').Actor
local NPC = require('openmw.types').NPC
local util = require('openmw.util')
local calendar = require('openmw_aux.calendar')
--local ambient = require('openmw.ambient')

local ulDef = require('scripts.UltimateLeveling.definition')
local ulSet = require('scripts.UltimateLeveling.settings')
local ulCom = require('scripts.UltimateLeveling.common')
local ulHpr = require('scripts.UltimateLeveling.helpers')

local L = core.l10n(ulDef.MOD_NAME)

local UltimateLevelingStatsMenu
local UltimateLevelingTooltip
local lastTooltipMessage
local UltimateLevelingLevelupScreen

local orderedAttributeIds = { "strength", "intelligence", "willpower", "agility", "speed", "endurance", "personality", "luck" }

local module = {}

local function setVanillaLevelupScreen(screen)
    UltimateLevelingLevelupScreen = screen
end

local function closeVanillaLevelupScreen()
    if UltimateLevelingLevelupScreen ~= nil then
        UltimateLevelingLevelupScreen:destroy()
        UltimateLevelingLevelupScreen = nil
    end
end

module.setVanillaLevelupScreen = setVanillaLevelupScreen
module.closeVanillaLevelupScreen = closeVanillaLevelupScreen

local function getDateStr()
    --[[if isStarwindMode then
        return '%I:%M %p, %d %b, %Y BBY'
    else--]]
        return '%I:%M %p'
    --end
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

local vGap05 = padding(0, 5)
local vGap10 = padding(0, 10)
local vGap20 = padding(0, 20)
--local hGap20 = padding(20, 0)
local vMargin = padding(0, 30)
local hMargin = padding(30, 0)

local stretchingLine = {
    template = I.MWUI.templates.horizontalLineThick,
    external = { stretch = 1 },
}

--local textDecayColor = util.color.rgb(96 / 255, 134 / 255, 202 / 255)
--local textNormalColor = I.MWUI.templates.textNormal.props.textColor

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

    local customBlock = {
        table.unpack(getSkillsHeader(L("skillsCustomHead"))),
    }
    for _, skillId in ipairs(state.skills.customOrder or {}) do
        table.insert(customBlock, getSkillValues(skillId))
    end

    local miscBlock = {
        table.unpack(getSkillsHeader(L("skillsMiscHead"))),
    }
    for _, skillId in ipairs(state.skills.miscOrder) do
        table.insert(miscBlock, getSkillValues(skillId))
    end

    return { majorBlock = majorBlock, minorBlock = minorBlock, customBlock = customBlock, miscBlock = miscBlock }
end

local function formatPercent(value)
    return string.format("%04.1f%%", value * 100)
end

local function createTooltip(message, position)
    return ui.create(toolTip(text(message, { multiline = true }), position))
end

local function tooltipPosition(mousePosition)
    return util.vector2(mousePosition.x - 20, mousePosition.y + 30)
end

local function closeTooltip()
    if UltimateLevelingTooltip ~= nil then
        UltimateLevelingTooltip:destroy()
        UltimateLevelingTooltip = nil
    end
end

local function closeStatsMenu()
    if UltimateLevelingStatsMenu ~= nil then
        UltimateLevelingStatsMenu:destroy()
        UltimateLevelingStatsMenu = nil
        closeTooltip()
    end
end
module.closeStatsMenu = closeStatsMenu

local function tooltipEvent(message)
    return {
        mouseMove = async:callback(function(mouseEvent, _)
            if UltimateLevelingTooltip == nil then
                UltimateLevelingTooltip = createTooltip(message, tooltipPosition(mouseEvent.position))
            else
                if lastTooltipMessage ~= message then
                    closeTooltip()
                    UltimateLevelingTooltip = createTooltip(message, mouseEvent.position)
                else
                    UltimateLevelingTooltip.layout.props.position = tooltipPosition(mouseEvent.position)
                    UltimateLevelingTooltip:update()
                end
            end
            lastTooltipMessage = message
        end)
    }
end

--local menuWidth = ulSet.globalStorage:get("statsMenuWidth") or 1100
local menuBlockHGap = 40
local menuBlockHGap2 = 20
local menuHGapSize = v2(menuBlockHGap, 0)
local menuHGapSize2 = v2(menuBlockHGap2, 0)
local menuCellWidth = 45
--local menuCellWidth = 30
--local menuPercentCellWidth = 40

local function getMenuWidth()
    return ulSet.globalStorage:get("statsMenuWidth") or 1400
end

--[[local function getLevelupScreenWidth()
    return ulSet.globalStorage:get("levelupScreenWidth") --or 400
end--]]

local vanillaLevelupClasses = {
    acrobat = true,
    agent = true,
    archer = true,
    assassin = true,
    barbarian = true,
    bard = true,
    battlemage = true,
    crusader = true,
    healer = true,
    knight = true,
    mage = true,
    monk = true,
    nightblade = true,
    pilgrim = true,
    rogue = true,
    scout = true,
    sorcerer = true,
    spellsword = true,
    thief = true,
    warrior = true,
    witchhunter = true,
}

local levelupClassesBySpecialization = {
    combat = { "archer", "barbarian", "crusader", "knight", "scout", "warrior" },
    magic = { "battlemage", "healer", "mage", "nightblade", "sorcerer", "spellsword", "witchhunter" },
    stealth = { "acrobat", "agent", "assassin", "bard", "monk", "pilgrim", "rogue", "thief" },
}

local function normalizeClassName(className)
    return string.lower((className or ""):gsub("%s+", ""))
end

local function getLevelupClassImagePath(className, specialization)
    local normalized = normalizeClassName(className)
    if vanillaLevelupClasses[normalized] then
        return "textures/levelup/" .. normalized .. ".bmp"
    end

    local specializationKey = string.lower((specialization or ""):gsub("%s+", ""))
    local candidates = levelupClassesBySpecialization[specializationKey]
    --[[if candidates == nil or #candidates == 0 then
        candidates = { "thief", "mage", "warrior" }
    end--]]

    return "textures/levelup/" .. candidates[math.random(#candidates)] .. ".bmp"
end

--[[local function getVanillaLevelupScreen(state)
    local screenWidth = getLevelupScreenWidth()
    local classImagePath = getLevelupClassImagePath(state.chargen.class, state.chargen.specialization)
    local currentLevel = Actor.stats.level(self).current

    local function attributeRow(attrId)
        local currentBase = Actor.stats.attributes[attrId](self).base
        local displayValue
        if currentLevel >= 3 then
            local previousBase = state.level.attributes[attrId]
            local gain = currentBase - previousBase
            displayValue = string.format("%d (%+d)", currentBase, gain)
        else
            local growth = math.floor(state.attrs.growth[attrId])
            displayValue = string.format("%d (%+d)", currentBase, growth)
        end
        state.level.attributes[attrId] = currentBase

        return row(
            ulCom.getStatName("attributes", attrId),
            text(displayValue)
        )
    end

    local leftAttributes = { "strength", "intelligence", "willpower", "agility" }
    local rightAttributes = { "speed", "endurance", "personality", "luck" }

    local leftBlock = {}
    for _, attrId in ipairs(leftAttributes) do
        table.insert(leftBlock, attributeRow(attrId))
    end

    local rightBlock = {}
    for _, attrId in ipairs(rightAttributes) do
        table.insert(rightBlock, attributeRow(attrId))
    end

    local currentLevel = Actor.stats.level(self).current
    local titleText = text(string.format("You have ascended to Level %d", currentLevel), {
        textAlignH = ui.ALIGNMENT.Center,
        autoSize = false,
        size = v2(screenWidth - 80, 30),
    })

    local messageKey
    if currentLevel >= 2 and currentLevel <= 20 then
        messageKey = "Level_Up_Level" .. currentLevel
    else
        messageKey = "Level_Up_Default"
    end

    local messageText = text(
        core.getGMST(messageKey),
        {
            multiline = true,
            wordWrap = true,
            textAlignH = ui.ALIGNMENT.Center,
            autoSize = false,
            size = v2(screenWidth - 80, 0),
        }
    )

    local okText = {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = "OK",
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            textColor = I.MWUI.templates.textNormal.props.textColor,
            size = v2(80, 30),
            autoSize = false,
        }
    }

    local function parseColorString(colorString)
        if type(colorString) == "string" then
            local r, g, b = string.match(colorString, "%(([%d.]+),%s*([%d.]+),%s*([%d.]+)%)")
            if r and g and b then
                return util.color.rgb(tonumber(r) / 255, tonumber(g) / 255, tonumber(b) / 255)
            end
        end
        return I.MWUI.templates.textNormal.props.textColor
    end

    local overColor = parseColorString(core.getGMST("fontcolor_color_normal_over"))
    local pressedColor = parseColorString(core.getGMST("fontColor_color_normal_pressed"))
    local normalColor = I.MWUI.templates.textNormal.props.textColor

    return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            size = v2(screenWidth, 0),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    vertical = true,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    autoSize = true,
                    size = v2(screenWidth - 20, 0),
                },
                content = ui.content {
                    vGap10,
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture({path = classImagePath}),
                            size = v2(math.min(320, screenWidth - 80), 160),
                            preserveAspectRatio = true,
                        }
                    },
                    vGap10,
                    titleText,
                    vGap05,
                    messageText,
                    vGap20,
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Start,
                            size = v2(screenWidth - 80, 0),
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    size = v2((screenWidth - 100) / 2, 0),
                                    vertical = true,
                                    align = ui.ALIGNMENT.Start,
                                    arrange = ui.ALIGNMENT.Start,
                                },
                                content = ui.content(leftBlock),
                            },
                            {
                                type = ui.TYPE.Flex,
                                props = { size = v2(40, 0) },
                            },
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    size = v2((screenWidth - 100) / 2, 0),
                                    vertical = true,
                                    align = ui.ALIGNMENT.Start,
                                    arrange = ui.ALIGNMENT.Start,
                                },
                                content = ui.content(rightBlock),
                            },
                        }
                    },
                    vGap20,
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.End,
                            arrange = ui.ALIGNMENT.End,
                            size = v2(screenWidth - 80, 40),
                            autoSize = false,
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Container,
                                template = I.MWUI.templates.boxTransparent,
                                props = {
                                    autoSize = false,
                                    size = v2(80, 30),
                                    align = ui.ALIGNMENT.Center,
                                    arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content { okText },
                                events = {
                                    focusGain = async:callback(function(this)
                                        okText.props.textColor = overColor
                                        this:update()
                                    end),
                                    focusLoss = async:callback(function(this)
                                        okText.props.textColor = normalColor
                                        this:update()
                                    end),
                                    mousePress = async:callback(function(this)
                                        ambient.playSound("Menu Click")
                                        okText.props.textColor = pressedColor
                                        this:update()
                                    end),
                                    mouseRelease = async:callback(function(this)
                                        okText.props.textColor = overColor
                                        this:update()
                                        module.closeVanillaLevelupScreen()
                                    end)
                                }
                            }
                        }
                    },
                    vGap10,
                }
            }
        }
    }
end

module.getVanillaLevelupScreen = getVanillaLevelupScreen--]]

local function getMenuHeaderHBlockSize()
    return v2((getMenuWidth() - menuBlockHGap * 3 - menuBlockHGap2 * 2) / 4, 0)
end
local function getMenuHeaderHBlockSize2()
    return getMenuHeaderHBlockSize() / 2
end
local function getMenuHBlock()
    return (getMenuWidth() - menuBlockHGap * 2) / 3
end
local function getMenuHBlockSize()
    return v2(getMenuHBlock(), 0)
end
local function getMenuHBlockSize2()
    return v2((getMenuHBlock() - menuBlockHGap2) / 2, 0)
end

local function getStatsMenu(state)
    local statsAbiMod = ulCom.getStatsAbiMod()
    local attrsAbiMod = {}
    local skillsAbiMod = {}
    local hasAttrAbiMod = false
    local hasAttrExtMods = false
    local hasAttrGrowth = false
    local hasSkillAbiMod = false
    local hasSkillExtMods = false
    local hasSkillGrowth = false

    for attrId in pairs(state.attrs.start) do
        attrsAbiMod[attrId] = statsAbiMod.attributes[attrId] or 0
        if attrsAbiMod[attrId] ~= 0 then
            hasAttrAbiMod = true
        end
        if state.attrs.extMod[attrId] ~= 0 then
            hasAttrExtMods = true
        end
        if state.attrs.growth[attrId] ~= 0 then
            hasAttrGrowth = true
        end
    end
    for skillId in pairs(state.skills.start) do
        skillsAbiMod[skillId] = statsAbiMod.skills[skillId] or 0
        if skillsAbiMod[skillId] ~= 0 then
            hasSkillAbiMod = true
        end
        if state.skills.extMod[skillId] ~= 0 then
            hasSkillExtMods = true
        end
        if state.skills.growth[skillId] ~= 0 then
            hasSkillGrowth = true
        end
    end

    local leftHeadBlock = {}
    local centerLeftHeadBlock = {}
    local centerRightHeadBlock = {}
    local rightHeadBlock = {}

    local rightCenterHeadBlock = {}
    local leftCenterHeadBlock = {}

    ulHpr.insertMultipleInArray(rightHeadBlock, {
        head(L("gameTimeHead")),
        text(calendar.formatGameTime(getDateStr())),
        vGap10,
        head(L("daysPassedHead")),
        text(tostring(math.floor(ulCom.totalGameTimeInHours() / 24))),
    })

    ulHpr.insertMultipleInArray(leftHeadBlock, {
        head(L("levelHead")),
        text(tostring(Actor.stats.level(self).current)),
        vGap10,
        head(L("levelProgressHead")),
        text(Actor.stats.level(self).current < ulSet.uncapperStorage:get("levelMaxValueUncapper") and formatPercent(state.level.progress) or "--.-%"),
    })

    ulHpr.insertMultipleInArray(centerLeftHeadBlock, {
        head(L("statsLevelSettingsHead")),
        vGap05,
        row(L("majorSkillLevelImpactFactor_name"), tostring(ulSet.levelStorage:get("majorSkillLevelImpactFactor"))),
        row(L("minorSkillLevelImpactFactor_name"), tostring(ulSet.levelStorage:get("minorSkillLevelImpactFactor"))),
        row(L("miscSkillLevelImpactFactor_name"), tostring(ulSet.levelStorage:get("miscSkillLevelImpactFactor"))),
    })

    ulHpr.insertMultipleInArray(centerRightHeadBlock, {
        head(L("statsAttrSettingsHead")),
        vGap05,
        row(L("attributeStartPenalty_name"), tostring(ulSet.gameStartStorage:get("attributeStartPenalty"))),
        row(L("attributeGrowthBase_name"), tostring(ulSet.attributesStorage:get("attributeGrowthBase"))),
        row(L("luckReputationGrowthBase_name"), tostring(ulSet.attributesStorage:get("luckReputationGrowthBase"))),
    })

    ulHpr.insertMultipleInArray(rightCenterHeadBlock, {
        head(L("playerBirthsignHead")),
        text(state.chargen.birthsign),
        vGap10,
    })

    if ulSet.levelStorage:get("trainingLevelCapper") then
        table.insert(rightCenterHeadBlock, {
            type = ui.TYPE.Flex,
            props = { arrange = ui.ALIGNMENT.End },
            content = ui.content {
                head(L("trainingSessionsHead")),
                text(tostring(state.level.training.remaining)),
            }
        })
    end

    ulHpr.insertMultipleInArray(leftCenterHeadBlock, {
        head(L("playerRaceHead")),
        text(state.chargen.race),
        vGap10,
        head(L("reputationHead")),
        text(tostring(state.attrs.reputation)),
    })

    local leftBlock = {}
    local centerBlock = {}
    local rightBlock = {}

    ulHpr.insertMultipleInArray(leftBlock, {
        headRow(L("attributesHead"),
                        L("statsProgressHead") .. " - "
                        .. L("statsRaceHead") .. " - "
                        .. (hasAttrExtMods and (L("statsExternalHead")) .. " - " or "")
                        .. L("statsStartHead")
                        .. (hasAttrGrowth and (" - " .. L("statsGrowthHead")) or "")
                        .. (hasAttrAbiMod and (" - " .. L("statsAbilityHead")) or "")
                        .. " - " .. L("statsCurrentHead")),
        vGap05,
    })

    local attributeMaxValue = ulSet.uncapperStorage:get("attributeMaxValueUncapper")
    local perAttributeMaxValue = ulSet.getPerAttributeMaxValue()

    for _, attrId in ipairs(orderedAttributeIds) do
        local maxValueBase = (perAttributeMaxValue[attrId] or attributeMaxValue)
        table.insert(leftBlock, row(
                ulCom.getStatName("attributes", attrId),
                textCells(
                        textCell(
                                menuCellWidth,
                                state.attrs.base[attrId] < maxValueBase and formatPercent(state.attrs.progress[attrId]) or "--.-%",
                                nil,
                                tooltipEvent(L("progressAttributeValue"))
                        ),
                        textCell(
                                menuCellWidth,
                                tostring(math.floor(state.attrs.race[attrId])),
                                nil,
                                tooltipEvent(L("raceAttributeValue"))),
                        textCell(
                                hasAttrExtMods and menuCellWidth or 0,
                                state.attrs.extMod[attrId] ~= 0 and (tostring(state.attrs.extMod[attrId])) or "",
                                nil,
                                tooltipEvent(L("externalModifierAttributeValue"))),
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
                                hasAttrAbiMod and menuCellWidth or 0,
                                attrsAbiMod[attrId] ~= 0 and (tostring(attrsAbiMod[attrId])) or "",
                                nil,
                                tooltipEvent(L("abilityModifierAttributeValue"))),
                        textCell(
                                menuCellWidth,
                                tostring(math.floor(Actor.stats.attributes[attrId](self).base)),
                                nil,
                                tooltipEvent(L("currentAttributeValue")))
                )
        ))
    end
    
    local nameClassBlock = {}
    local specFavBlock = {}

    ulHpr.insertMultipleInArray(nameClassBlock, {
        head(L("nameHead")),
        text(state.chargen.name),
        vGap10,
        head(L("classHead")),
        text(state.chargen.class)
    })

    ulHpr.insertMultipleInArray(specFavBlock, {
        head(L("specializationHead")),
        text(state.chargen.specialization),
        vGap10,
        head(L("favoredHead")),
    })

    for _, attrId in ipairs(state.attrs.favoredOrder) do
        table.insert(specFavBlock, text(ulCom.getStatName("attributes", attrId)))
    end

    local menuHBlockSize2 = getMenuHBlockSize2()

    local bottomLeftBlock = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHBlockSize2 },
                    content = ui.content(nameClassBlock)
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHGapSize2 },
                },
                {
                    type = ui.TYPE.Flex,
                    props = { size = menuHBlockSize2, arrange = ui.ALIGNMENT.End },
                    content = ui.content(specFavBlock)
                },
            }
        }
    }

    ulHpr.insertMultipleInArray(leftBlock, {
        vGap10,
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content(bottomLeftBlock),
        }
    })

    local function getSkillsHeader(skillTypeName)
        return {
            headRow(skillTypeName,
                    L("statsProgressHead")
                            .. (hasSkillExtMods and " - " .. L("statsExternalHead") or "")
                            .. " - " .. L("statsStartHead")
                            .. (hasSkillGrowth and (" - " .. L("statsGrowthHead")) or "")
                            .. (hasSkillAbiMod and (" - " .. L("statsAbilityHead")) or "")
                            .. " - " .. L("statsCurrentHead")),
            vGap05,
        }
    end

    local skillMaxValue = ulSet.uncapperStorage:get("skillMaxValueUncapper")
    local perSkillMaxValue = ulSet.getPerSkillMaxValue()

    local skillRows = getSkillsRows(state, getSkillsHeader, function(skillId)
        local skillStat = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId) or NPC.stats.skills[skillId](self)
        local maxValueBase = perSkillMaxValue[skillId] or skillMaxValue
        return row(
                ulCom.getStatName("skills", skillId),
                textCells(
                        textCell(
                                menuCellWidth,
                                state.skills.base[skillId] < maxValueBase and formatPercent(skillStat.progress) or "--.-%",
                                nil,
                                tooltipEvent(L("progressSkillValue"))
                        ),
                        textCell(
                                hasSkillExtMods and menuCellWidth or 0,
                                state.skills.extMod[skillId] ~= 0 and (tostring(state.skills.extMod[skillId])) or "",
                                nil,
                                tooltipEvent(L("externalModifierSkillValue"))
                        ),
                        textCell(
                                menuCellWidth,
                                tostring(state.skills.start[skillId]),
                                nil,
                                tooltipEvent(L("startSkillValue"))
                        ),
                        textCell(
                                hasSkillGrowth and menuCellWidth or 0,
                                state.skills.growth[skillId] ~= 0 and (tostring(state.skills.growth[skillId])) or "",
                                nil,
                                tooltipEvent(L("growthSkillValue"))),
                        textCell(
                                hasSkillAbiMod and menuCellWidth or 0,
                                skillsAbiMod[skillId] ~= 0 and (tostring(skillsAbiMod[skillId])) or "",
                                nil,
                                tooltipEvent(L("abilityModifierSkillValue"))
                        ),
                        textCell(
                                menuCellWidth,
                                tostring(skillStat.base),
                                nil,
                                tooltipEvent(L("currentSkillValue"))
                        )
                )
        )
    end)

    ulHpr.insertMultipleInArray(centerBlock, skillRows.majorBlock)
    table.insert(centerBlock, vGap10)
    ulHpr.insertMultipleInArray(centerBlock, skillRows.minorBlock)
    if next(state.skills.customOrder) then
        table.insert(centerBlock, vGap10)
        ulHpr.insertMultipleInArray(centerBlock, skillRows.customBlock)
    end

    ulHpr.insertMultipleInArray(rightBlock, skillRows.miscBlock)

    local menuHeaderHBlockSize = getMenuHeaderHBlockSize()
    local menuHeaderHBlockSize2 = getMenuHeaderHBlockSize2()
    local menuHBlockSize = getMenuHBlockSize()

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

    if ulSet.globalStorage:get("showMessagesLog") then
        local messagesBlock = {
            headRow(L("messagesLogTitleHead"), L("messagesLogTimestampHead")),
            vGap05
        }
        for _, log in ipairs(state.messagesLog) do
            table.insert(messagesBlock, row(log.message, log.time))
        end
        ulHpr.insertMultipleInArray(menuContent, {
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
    ulHpr.insertMultipleInArray(lines, {
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

local function showStatsMenu(state, data)
    local statsMenu = getStatsMenu(state)

    if UltimateLevelingStatsMenu == nil then
        if not data.create then return end
        UltimateLevelingStatsMenu = ui.create(statsMenu)
    else
        if data.create then return end
        UltimateLevelingStatsMenu.layout = statsMenu
        UltimateLevelingStatsMenu:update()
    end
    async:newUnsavableSimulationTimer(1, function()
        if UltimateLevelingStatsMenu ~= nil then
            self:sendEvent(ulDef.events.showStatsMenu, { create = false })
        end
    end)
end
module.showStatsMenu = showStatsMenu

local function isStatsMenu()
    if UltimateLevelingStatsMenu then
        return true
    else
        return false
    end
end
module.isStatsMenu = isStatsMenu

return module
