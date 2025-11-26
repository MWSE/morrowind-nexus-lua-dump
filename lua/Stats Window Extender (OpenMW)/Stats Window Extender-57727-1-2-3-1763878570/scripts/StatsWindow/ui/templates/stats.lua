local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local omwself = require('openmw.self')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')

local omwConstants = require('scripts.omw.mwui.constants')

local BASE = require('scripts.StatsWindow.ui.templates.base')
local helpers = require('scripts.StatsWindow.util.helpers')
local constants = require('scripts.StatsWindow.util.constants')

local configPlayer = require('scripts.StatsWindow.config.player')

local v2 = util.vector2

local intRe = configPlayer.modIntegration.b_InterfaceReimagined

local Templates = {}

Templates.LEFT_PANE_RATIO = configPlayer.window.f_LeftPaneRatio
Templates.HEADER_HEIGHT = 20
Templates.BORDER_WIDTH_TOTAL = 4 * (intRe and 2 or 4)
Templates.TEXT_SIZE = configPlayer.window.i_FontSize
Templates.LINE_HEIGHT = Templates.TEXT_SIZE + 2
Templates.SECTION_DIVIDER_HEIGHT = Templates.LINE_HEIGHT
Templates.SECTION_INDENT_L = 12
Templates.SECTION_INDENT_R = 4
Templates.BOX_OUTER_PADDING = 8
Templates.BOX_INNER_PADDING = omwConstants.padding
Templates.BORDER_THICKNESS = omwConstants.border
Templates.MIN_LEFT_WIDTH = configPlayer.window.f_LeftPaneMinWidth
Templates.MIN_RIGHT_WIDTH = configPlayer.window.f_RightPaneMinWidth
Templates.MIN_HEIGHT = 4 + 
    Templates.HEADER_HEIGHT + 
    Templates.BORDER_WIDTH_TOTAL + 
    Templates.BOX_OUTER_PADDING * 2 + 
    Templates.BOX_INNER_PADDING * 2 + 
    Templates.LINE_HEIGHT * 3
Templates.TEXTURES = {
    progressBar = ui.texture { path = 'textures/menu_bar_gray.dds' },
}

Templates.active = false
Templates.focusedScrollable = nil
Templates.focusedLabel = nil
Templates.activeTooltip = nil
Templates.updateQueue = {}
local lastMousePos = nil
local storedScrollPos = {}

Templates.labeledValue = function(props)
    props.label = props.label or ''
    props.height = props.height or Templates.LINE_HEIGHT
    props.labelColor = props.labelColor or constants.Colors.DEFAULT
    props.valueColor = props.valueColor or constants.Colors.DEFAULT
    local layout = {
        name = props.name,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = v2(0, props.height),
            relativeSize = v2(1, 0),
        },
        content = ui.content {
            BASE.intervalH(props.indent),
            {
                name = 'label',
                template = BASE.textNormal,
                props = {
                    text = props.label,
                    textSize = Templates.TEXT_SIZE,
                    textColor = props.labelColor,
                },
                external = {
                    grow = 1,
                },
            },
            {
                name = 'value',
                template = BASE.textNormal,
                props = {
                    textSize = Templates.TEXT_SIZE,
                    textColor = props.valueColor,
                }
            }
        },
        userData = {
            type = props.type or constants.LineType.STRING,
            valueFn = props.valueFn,
            tooltipFn = props.tooltipFn,
            visibleFn = props.visibleFn,
        },
    }

    local function absToRel(absPos)
        local layerSize = ui.layers[ui.layers.indexOf('Notification')].size
        return v2(
            absPos.x / layerSize.x,
            absPos.y / layerSize.y
        )
    end

    local function createTooltip(layout)
        if not Templates.active then return end
        Templates.activeTooltip = ui.create(layout.userData.tooltipFn())
        Templates.activeTooltip.layout.name = props.name
        if lastMousePos then
            Templates.activeTooltip.layout.props.anchor = v2(absToRel(lastMousePos).x, 0)
            Templates.activeTooltip.layout.props.position = v2(lastMousePos.x, lastMousePos.y + 32)
        end
        Templates.activeTooltip:update()
        return Templates.activeTooltip
    end

    if props.tooltipFn then
        layout.events = {
            focusLoss = async:callback(function()
                if Templates.activeTooltip and Templates.activeTooltip.layout then
                    Templates.activeTooltip.layout.props.visible = false
                    table.insert(Templates.updateQueue, Templates.activeTooltip)
                end
                return true
            end),
            mouseMove = async:callback(function(e, layout)
                if not Templates.activeTooltip or not Templates.activeTooltip.layout then
                    Templates.activeTooltip = createTooltip(layout)
                elseif Templates.activeTooltip.layout.name ~= props.name then
                    Templates.activeTooltip:destroy()
                    Templates.activeTooltip = createTooltip(layout)
                end
                if Templates.activeTooltip then
                    Templates.activeTooltip.layout.props.visible = true
                    local distToBottom = ui.layers[ui.layers.indexOf('Notification')].size.y - (e.position.y - e.offset.y)
                    if distToBottom < 360 then
                        Templates.activeTooltip.layout.props.anchor = v2(absToRel(e.position).x, 1)
                        Templates.activeTooltip.layout.props.position = v2(e.position.x, e.position.y - 32)
                    else
                        Templates.activeTooltip.layout.props.anchor = v2(absToRel(e.position).x, 0)
                        Templates.activeTooltip.layout.props.position = v2(e.position.x, e.position.y + 32)
                    end
                    Templates.activeTooltip:update()
                    lastMousePos = e.position
                end
                return true
            end),
        }
    end
    return layout
end

Templates.progressBar = function(props)
    props.value = math.floor(props.value or 0)
    props.maxValue = math.floor(props.maxValue or 100)
    props.size = props.size or v2(100, Templates.LINE_HEIGHT)
    props.color = props.color or constants.Colors.RED
    props.textColor = props.textColor or constants.Colors.DEFAULT

    local percentage = props.maxValue ~= 0 and math.min(math.max(props.value / props.maxValue, 0), 1) or 1

    return {
        name = 'value',
        template = I.MWUI.templates.borders,
        props = {
            size = props.size,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = v2(percentage, 1),
                    resource = Templates.TEXTURES.progressBar,
                    color = props.color,
                }
            },
            {
                template = BASE.textNormal,
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    text = props.text or tostring(props.value .. '/' .. props.maxValue),
                    textColor = props.textColor,
                    textSize = Templates.TEXT_SIZE,
                }
            },
        }
    }
end

Templates.tooltip = function(padding, content, name)
    return {
        layer = 'Notification',
        name = name,
        template = BASE.boxSolid,
        props = {
        },
        content = ui.content {
            {
                name = 'padding',
                template = BASE.padding(padding),
                content = content or ui.content {},
            }
        }
    }
end

Templates.headerTooltip = function(title, description, subDescription, name)
    return Templates.tooltip(4, ui.content {
        {
            name = 'tooltip',
            type = ui.TYPE.Flex,
            props = {
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                title and {
                    name = 'header',
                    template = BASE.textHeader,
                    props = {
                        text = title,
                        textAlignH = ui.ALIGNMENT.Center,
                    }
                } or {},
                title and (description or subDescription) and BASE.padding(4) or {},
                description and {
                    name = 'body',
                    template = BASE.textParagraph,
                    props = {
                        size = v2(400, 0),
                        text = description,
                        autoSize = true,
                    }
                } or {},
                description and subDescription and BASE.padding(4) or {},
                subDescription and {
                    name = 'subBody',
                    template = BASE.textNormal,
                    props = {
                        text = subDescription,
                        textAlignH = ui.ALIGNMENT.Center,
                    }
                } or {},
            }
        }
    }, name)
end

Templates.levelTooltip = function()
    local level = omwself.type.stats.level(omwself)
    local skillUpsPerLevel = core.getGMST('iLevelupTotal')
    local attrUps = level.skillIncreasesForAttribute
    local actualAttrUps = {}
    local levelUpMults = {
        [1] = core.getGMST('iLevelUp01Mult'),
        [2] = core.getGMST('iLevelUp02Mult'),
        [3] = core.getGMST('iLevelUp03Mult'),
        [4] = core.getGMST('iLevelUp04Mult'),
        [5] = core.getGMST('iLevelUp05Mult'),
        [6] = core.getGMST('iLevelUp06Mult'),
        [7] = core.getGMST('iLevelUp07Mult'),
        [8] = core.getGMST('iLevelUp08Mult'),
        [9] = core.getGMST('iLevelUp09Mult'),
        [10] = core.getGMST('iLevelUp10Mult'),
    }
    for _, attr in ipairs(core.stats.Attribute.records) do
        if attrUps[attr.id] and attrUps[attr.id] > 0 then
            local mult = levelUpMults[math.min(attrUps[attr.id], 10)]
            if mult > 0 then
                actualAttrUps[attr.id] = mult
            end
        end
    end
    return Templates.tooltip(8, Templates.levelProgressBar(level.progress, skillUpsPerLevel, actualAttrUps), 'level')
end

Templates.iconTooltip = function(props)
    return Templates.tooltip(4, ui.content {
        {
            name = 'tooltip',
            type = ui.TYPE.Flex,
            content = ui.content {
                -- Icon and title
                {
                    name = 'headerRow',
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            name = 'icon',
                            props = {
                                size = v2(32, 32),
                            },
                            content = ui.content {
                                props.icon.bgr and {
                                    name = 'bgr',
                                    type = ui.TYPE.Image,
                                    props = {
                                        relativeSize = v2(1, 1),
                                        resource = ui.texture { path = props.icon.bgr },
                                        color = props.icon.bgrColor or util.color.rgb(1, 1, 1),
                                    }
                                } or {},
                                props.icon.fgr and {
                                    name = 'fgr',
                                    type = ui.TYPE.Image,
                                    props = {
                                        relativeSize = v2(1, 1),
                                        resource = ui.texture { path = props.icon.fgr },
                                        color = props.icon.fgrColor or util.color.rgb(1, 1, 1),
                                    }
                                } or {},
                            }
                        },
                        BASE.padding(4),
                        {
                            name = 'titleFlex',
                            type = ui.TYPE.Flex,
                            props = {
                                grow = 1,
                            },
                            content = ui.content {
                                props.title and {
                                    name = 'title',
                                    template = BASE.textHeader,
                                    props = {
                                        text = props.title,
                                    }
                                } or {},
                                props.subtitle and {
                                    name = 'subtitle',
                                    template = BASE.textNormal,
                                    props = {
                                        text = props.subtitle,
                                    }
                                } or {},
                            }
                        }
                    }
                },
                BASE.padding(4),
                -- Description
                props.description and {
                    template = BASE.textParagraph,
                    props = {
                        size = v2(400, 0),
                        text = props.description,
                        autoSize = true,
                    }
                } or {},
            }
        },
    }, props.title)
end

Templates.skillTooltip = function(props)
    local base = Templates.iconTooltip(props)
    base.content[1].content.tooltip.content:add({
        name = 'progress',
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
        },
        external = {
            stretch = 1,
        },
        content = Templates.skillProgressBar(props.currentValue or 0, props.maxValue or 100, props.progress or 0),
    })
    return base
end

Templates.birthsignTooltip = function(signRecord)
    local spellsList = signRecord.spells or {}
    local spellsByType = { [core.magic.SPELL_TYPE.Ability] = {}, [core.magic.SPELL_TYPE.Power] = {}, [core.magic.SPELL_TYPE.Spell] = {} }
    for _, spellId in ipairs(spellsList) do
        local spell = core.magic.spells.records[spellId]
        if spellsByType[spell.type] then 
            table.insert(spellsByType[spell.type], spell.name) 
        end
    end

    local content = ui.content {
        {
            template = I.MWUI.templates.borders,
            props = { size = v2(263, 137) },
            content = ui.content {
                { type = ui.TYPE.Image, props = { relativeSize = v2(1, 1), resource = ui.texture { path = signRecord.texture } } }
            }
        },
        BASE.padding(4),
        { template = BASE.textHeader, props = { text = signRecord.name } },
        BASE.padding(4),
        { template = BASE.textParagraph, props = { size = v2(400, 0), text = signRecord.description, autoSize = true } }
    }

    for _, spellType in ipairs({core.magic.SPELL_TYPE.Ability, core.magic.SPELL_TYPE.Power, core.magic.SPELL_TYPE.Spell}) do
        local strs = {
            [core.magic.SPELL_TYPE.Ability] = constants.Strings.TYPE_ABILITY,
            [core.magic.SPELL_TYPE.Power] = constants.Strings.TYPE_POWER,
            [core.magic.SPELL_TYPE.Spell] = constants.Strings.TYPE_SPELL
        }
        local header = strs[spellType]

        if #spellsByType[spellType] > 0 then
            content:add(BASE.padding(4))
            content:add({ template = BASE.textHeader, props = { text = header .. ':' } })
            for _, spellName in ipairs(spellsByType[spellType]) do
                content:add({ template = BASE.textNormal, props = { text = spellName } })
            end
        end
    end

    return Templates.tooltip(8, ui.content {
        {
            name = 'tooltip',
            type = ui.TYPE.Flex,
            props = {
                arrange = ui.ALIGNMENT.Center,
            },
            content = content,
        },
    }, signRecord.name)
end

Templates.factionTooltip = function(factionRecord)
    local content = ui.content {
        { template = BASE.textHeader, props = { text = factionRecord.name } },
    }

    if omwself.type.isExpelled(omwself, factionRecord.id) then
        content:add({ template = BASE.textNormal, props = { text = constants.Strings.EXPELLED, textColor = constants.Colors.DAMAGED } })
    else
        local rank = omwself.type.getFactionRank(omwself, factionRecord.id)
        local currRankData = factionRecord.ranks[rank]
        local nextRankData = factionRecord.ranks[rank + 1]

        content:add({ template = BASE.textNormal, props = { text = currRankData.name } })

        if nextRankData then
            content:add(BASE.padding(8))
            content:add({ template = BASE.textHeader, props = { text = constants.Strings.NEXT_RANK .. ' ' .. nextRankData.name } })

            local attrsStrings = {}
            for i, attr in ipairs(factionRecord.attributes) do
                local attrName = core.stats.Attribute.record(attr).name
                table.insert(attrsStrings, attrName .. ': ' .. nextRankData.attributeValues[i])
            end
            if #attrsStrings > 0 then
                content:add({ template = BASE.textParagraph, props = { size = v2(400, 0), text = table.concat(attrsStrings, ', '), autoSize = true } })
            end
            if configPlayer.tweaks.b_ShowFactionRepInTooltip then
                local repCurrent = omwself.type.getFactionReputation(omwself, factionRecord.id)
                local repReq = nextRankData.factionReaction -- yes, this is what the field is called
                content:add({ template = BASE.textParagraph, props = { size = v2(400, 0), text = constants.Strings.REPUTATION .. ': ' .. repCurrent .. '/' .. repReq, autoSize = true } }) 
            end

            if #factionRecord.skills > 0 then
                content:add(BASE.padding(8))
                content:add({ template = BASE.textHeader, props = { text = constants.Strings.FAVORITE_SKILLS } })
                
                local skillsStrings = {}
                for _, skillId in ipairs(factionRecord.skills) do
                    local skillName = core.stats.Skill.record(skillId).name
                    table.insert(skillsStrings, skillName)
                end
                content:add({ template = BASE.textParagraph, props = { size = v2(400, 0), text = table.concat(skillsStrings, ', '), autoSize = true } })
            end

            if nextRankData.primarySkillValue > 0 or nextRankData.favouredSkillValue > 0 then
                content:add(BASE.padding(8))
                local needSkillsStrings = {}
                if nextRankData.primarySkillValue > 0 then
                    table.insert(needSkillsStrings, constants.Strings.NEED_ONE_SKILL .. ' ' .. nextRankData.primarySkillValue)
                end
                if nextRankData.favouredSkillValue > 0 then
                    table.insert(needSkillsStrings, constants.Strings.NEED_TWO_SKILLS .. ' ' .. nextRankData.favouredSkillValue)
                end
                content:add({ template = BASE.textParagraph, props = { size = v2(400, 0), text = table.concat(needSkillsStrings, ' ' .. constants.Strings.AND .. ' '), autoSize = true } })
            end
        end
    end

    return Templates.tooltip(8, ui.content {
        {
            name = 'tooltip',
            type = ui.TYPE.Flex,
            content = content,
        },
    }, factionRecord.name)
end

Templates.sectionDivider = {
    props = {
        relativeSize = v2(1, 0),
        size = v2(0, Templates.SECTION_DIVIDER_HEIGHT),
    },
    content = ui.content {
        {
            template = I.MWUI.templates.horizontalLine,
            props = {
                anchor = v2(0, 0.5),
                relativePosition = v2(0, 0.5),
                size = v2(-Templates.SECTION_INDENT_L - Templates.SECTION_INDENT_R - 4, 2),
                position = v2(Templates.SECTION_INDENT_L, 0),
            },
        }
    }
}

Templates.levelProgressBar = function(curr, req, attrGains)
    local contentInner = ui.content {
        {
            template = BASE.textHeader,
            props = {
                text = constants.Strings.LEVEL_PROGRESS,
            }
        },
        BASE.padding(2),
        Templates.progressBar{
            value = curr,
            maxValue = req,
            size = v2(180, Templates.LINE_HEIGHT + 2),
            color = constants.Colors.BAR_HEALTH,
        }
    }

    local first = true
    for _, attr in ipairs(core.stats.Attribute.records) do
        if attrGains[attr.id] then
            if first then
                contentInner:add(BASE.padding(2))
                first = false
            end
            contentInner:add({
                template = BASE.textNormal,
                props = {
                    text = attr.name .. ' x' .. attrGains[attr.id],
                }
            })
        end
    end

    return ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                arrange = ui.ALIGNMENT.Center,
            },
            content = contentInner,
        }
    }
end

Templates.skillProgressBar = function(value, maxValue, progress)
    if maxValue > 0 and value < maxValue then
        return ui.content {
            BASE.padding(4),
            {
                template = BASE.textHeader,
                props = {
                    text = constants.Strings.SKILL_PROGRESS,
                    textSize = Templates.TEXT_SIZE,
                }
            },
            Templates.progressBar{
                value = progress * 100,
                maxValue = 100,
                size = v2(200, Templates.LINE_HEIGHT),
                color = constants.Colors.BAR_HEALTH,
            }
        }
    else
        return ui.content {
            BASE.padding(4),
            {
                template = BASE.textNormal,
                props = {
                    text = constants.Strings.SKILL_MAX_REACHED,
                    textSize = Templates.TEXT_SIZE,
                }
            }
        }
    end
end

Templates.updateStats = function(layout)
    local anyValChanged, anyVisChanged = false, false

    local title = layout.content.foreground.content.header.content.title
    local playerName = omwself.type.records[omwself.recordId].name
    if title.props.text ~= playerName then
        title.props.text = playerName
        anyValChanged = true
    end

    local function processContent(content)
        for _, child in ipairs(content) do
            local layout = child.layout and child.layout or child
            if layout.userData then
                if layout.userData.visibleFn then
                    local isVisible = layout.userData.visibleFn()
                    if layout.props.visible ~= isVisible then
                        layout.props.visible = isVisible
                        anyVisChanged = true
                    end
                    if not isVisible then
                        goto continue
                    end
                end
                if layout.userData.valueFn then
                    if layout.userData.type == constants.LineType.STRING then
                        local val = layout.userData.valueFn()
                        val.color = val.color or constants.Colors.DEFAULT
                        if not anyValChanged and layout.content.value.props.text ~= val.string or layout.content.value.props.textColor ~= val.color then
                            anyValChanged = true
                        end
                        layout.content.value.props.text = val.string
                        layout.content.value.props.textColor = val.color
                    elseif layout.userData.type == constants.LineType.PROGRESS_BAR then
                        local progressBar = Templates.progressBar(layout.userData.valueFn())
                        if not anyValChanged and not helpers.mapEquals(layout.content.value, progressBar) then
                            anyValChanged = true
                        end
                        layout.content.value = progressBar
                    elseif layout.userData.type == constants.LineType.CUSTOM then
                        local valLayout = layout.userData.valueFn()
                        valLayout.name = 'value'
                        if not anyValChanged and not helpers.mapEquals(layout.content.value, valLayout) then
                            anyValChanged = true
                        end
                        layout.content.value = valLayout
                    end
                end
            end
            if layout.content then
                processContent(layout.content)
            end
            ::continue::
        end
    end

    processContent(layout.content)

    return anyValChanged, anyVisChanged
end

Templates.updateStatsWindow = function(layout)
    local anyValChanged, anyVisChanged = Templates.updateStats(layout)

    local minWidth = Templates.MIN_LEFT_WIDTH + Templates.BORDER_WIDTH_TOTAL + Templates.BOX_OUTER_PADDING * 2

    layout.props.size = util.vector2(
        math.max(layout.props.size.x, minWidth),
        math.max(layout.props.size.y, Templates.MIN_HEIGHT)
    )

    local rightPaneRatio = 1 - Templates.LEFT_PANE_RATIO

    local windowWidth = layout.props.size.x
    local windowHeight = layout.props.size.y
    local innerWidth = windowWidth - Templates.BORDER_WIDTH_TOTAL
    local innerHeight = windowHeight - Templates.BORDER_WIDTH_TOTAL - Templates.HEADER_HEIGHT
    local availableWidth = innerWidth - 2 * Templates.BOX_OUTER_PADDING
    local availableHeight = innerHeight - 2 * Templates.BOX_OUTER_PADDING
    local horizontalRightWidth = math.min((availableWidth - Templates.BOX_OUTER_PADDING) * rightPaneRatio, availableWidth - Templates.BOX_OUTER_PADDING - Templates.MIN_LEFT_WIDTH)

    local paneArrangement = configPlayer.window.s_PaneArrangement
    local stackVertically = paneArrangement == 'Panes_Stacked' or (paneArrangement == 'Panes_Auto' and horizontalRightWidth < Templates.MIN_RIGHT_WIDTH)

    local body = layout.content.foreground.content.body
    local leftPane = body.content[constants.Panes.LEFT]
    local rightPane = body.content[constants.Panes.RIGHT]
    local paneDivider = body.content.paneDivider

    local lastLeftBox = leftPane.content[#leftPane.content]
    local lastRightBox = rightPane.content[#rightPane.content]

    if stackVertically then
        leftPane.props.position = util.vector2(Templates.BOX_OUTER_PADDING, Templates.BOX_OUTER_PADDING)
        leftPane.props.size = util.vector2(availableWidth, leftPane.userData.contentHeight)
        rightPane.props.position = util.vector2(Templates.BOX_OUTER_PADDING, leftPane.props.position.y + leftPane.props.size.y + Templates.BOX_OUTER_PADDING)
        rightPane.props.size = util.vector2(availableWidth, availableHeight - rightPane.props.position.y + Templates.BOX_OUTER_PADDING)
        if lastLeftBox.userData.maxHeight then
            lastLeftBox.props.size = util.vector2(
                0,
                math.min(lastLeftBox.userData.maxHeight, lastLeftBox.userData.contentHeight)
            )
        else
            lastLeftBox.props.size = util.vector2(
                0,
                lastLeftBox.userData.contentHeight
            )
        end
        rightPane.content[#rightPane.content].props.size = util.vector2(
            0,
            availableHeight - rightPane.props.position.y - (rightPane.userData.contentHeight - lastRightBox.userData.contentHeight) + Templates.BOX_OUTER_PADDING
        )

        if intRe then
            paneDivider.props.visible = false
        end
    else
        leftPane.props.position = util.vector2(Templates.BOX_OUTER_PADDING, Templates.BOX_OUTER_PADDING)
        rightPane.props.visible = (windowWidth >= minWidth + Templates.BOX_OUTER_PADDING)
        if not rightPane.props.visible then
            leftPane.props.size = util.vector2(Templates.MIN_LEFT_WIDTH, availableHeight)
            rightPane.props.size = util.vector2(0, availableHeight)
        else
            availableWidth = availableWidth - Templates.BOX_OUTER_PADDING
            if (horizontalRightWidth / availableWidth) < rightPaneRatio - 1e-5 then
                leftPane.props.size = util.vector2(Templates.MIN_LEFT_WIDTH, availableHeight)
            else
                leftPane.props.size = util.vector2(availableWidth * Templates.LEFT_PANE_RATIO, availableHeight)
            end
            
            rightPane.props.position = util.vector2(leftPane.props.position.x + leftPane.props.size.x + Templates.BOX_OUTER_PADDING, Templates.BOX_OUTER_PADDING)
            rightPane.props.size = util.vector2(horizontalRightWidth, availableHeight)
        end

        if intRe then
            paneDivider.props.visible = true
            paneDivider.template = I.MWUI.templates.verticalLine
            paneDivider.props.position = util.vector2(
                leftPane.props.position.x + leftPane.props.size.x + Templates.BOX_OUTER_PADDING / 2,
                0
            )
            paneDivider.props.size = util.vector2(Templates.BORDER_THICKNESS, -Templates.BOX_OUTER_PADDING)
        end

        local leftPaneVisibleHeight = 0
        for _, box in ipairs(leftPane.content) do
            if box ~= lastLeftBox then
                leftPaneVisibleHeight = leftPaneVisibleHeight + box.props.size.y
            end
        end
        local rightPaneVisibleHeight = 0
        for _, box in ipairs(rightPane.content) do
            if box ~= lastRightBox then
                rightPaneVisibleHeight = rightPaneVisibleHeight + box.props.size.y
            end
        end

        lastLeftBox.props.size = util.vector2(
            0,
            availableHeight - leftPaneVisibleHeight
        )
        lastRightBox.props.size = util.vector2(
            0,
            availableHeight - rightPaneVisibleHeight
        )
    end

    lastLeftBox.content[1].layout.userData.update(util.vector2(
        leftPane.props.size.x - (Templates.BORDER_THICKNESS * 2),
        lastLeftBox.props.size.y - (Templates.BOX_INNER_PADDING) * 2
    ))
    lastRightBox.content[1].layout.userData.update(util.vector2(
        rightPane.props.size.x - (Templates.BORDER_THICKNESS * 2),
        lastRightBox.props.size.y - (Templates.BOX_INNER_PADDING) * 2
    ))

    return anyValChanged, anyVisChanged
end

Templates.pane = function(id, content)
    local totalContentHeight = 0
    for _, item in ipairs(content) do
        if item.userData then
            if item.userData.maxHeight then
                totalContentHeight = totalContentHeight + math.min(item.userData.maxHeight, item.userData.contentHeight)
            else
                totalContentHeight = totalContentHeight + item.userData.contentHeight
            end
        else
            totalContentHeight = totalContentHeight + item.props.size.y
        end
    end

    return {
        name = id,
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
        },
        content = content,
        userData = {
            contentHeight = totalContentHeight,
        }
    }
end

Templates.box = function(id, content)
    local totalContentHeight = 0
    for _, item in ipairs(content) do
        item.props.position = v2(0, totalContentHeight)
        totalContentHeight = totalContentHeight + item.props.size.y
    end

    return {
        name = id,
        template = not intRe and I.MWUI.templates.borders or BASE.bordersInvisible,
        props = {
            relativeSize = v2(1, 0),
        },
        content = ui.content {
            {
                name = 'padding',
                props = {
                    position = v2(Templates.BOX_INNER_PADDING, Templates.BOX_INNER_PADDING),
                    size = v2(-Templates.BOX_INNER_PADDING * 2, -Templates.BOX_INNER_PADDING * 2),
                    relativeSize = v2(1, 1),
                },
                content = ui.content {
                    {
                        name = 'body',
                        props = {
                            relativeSize = v2(1, 1),
                        },
                        content = content
                    }
                },
            }
        },
        userData = {
            contentHeight = totalContentHeight + (totalContentHeight > 0 and (Templates.BORDER_THICKNESS + Templates.BOX_INNER_PADDING) * 2 or 0),
        }
    }
end

local function sortSections(sections, recursive)
    local function sortByPlacement(sections)
        for index, section in ipairs(sections) do
            section.originalIndex = index
        end

        table.sort(sections, function(a, b)
            local aPriority = a.placement and a.placement.priority or 100
            local bPriority = b.placement and b.placement.priority or 100
            if aPriority == bPriority then
                return a.originalIndex < b.originalIndex
            end
            return aPriority > bPriority
        end)
    end

    local function resolvePlacement(sections)
        local sortedSections = {}

        for _, section in ipairs(sections) do
            local placement = section.placement or {}
            local type = placement.type or constants.Placement.BOTTOM
            local target = placement.target

            if type == constants.Placement.TOP then
                table.insert(sortedSections, 1, section)
            elseif type == constants.Placement.BOTTOM then
                table.insert(sortedSections, section)
            elseif (type == constants.Placement.AFTER or type == constants.Placement.BEFORE) and target then
                local targetIndex = nil
                for i, s in ipairs(sortedSections) do
                    if s.id == target then
                        targetIndex = i
                        break
                    end
                end

                if targetIndex then
                    if type == constants.Placement.AFTER then
                        table.insert(sortedSections, targetIndex + 1, section)
                    elseif type == constants.Placement.BEFORE then
                        table.insert(sortedSections, targetIndex, section)
                    end
                else
                    table.insert(sortedSections, section)
                end
            else
                table.insert(sortedSections, section)
            end
        end

        return sortedSections
    end

    local function processSections(sections)
        if recursive then
            for _, section in ipairs(sections) do
                if section.sections then
                    section.sections = processSections(section.sections)
                end
            end
        end

        sortByPlacement(sections)
        return resolvePlacement(sections)
    end

    return processSections(sections)
end

local function createSection(data, level)
    level = level or 0
    local totalHeight = 0
    local visibleLines = 0
    local layout = {
        name = data.id,
        props = {
            autoSize = false,
            relativeSize = v2(1, 0),
            visible = true,
        },
        content = ui.content {},
        userData = {
            visibleFn = data.visibleFn,
            divider = data.divider or {},
        }
    }
    layout.userData.divider.before = layout.userData.divider.before ~= false
    layout.userData.divider.after = layout.userData.divider.after ~= false
    if data.visibleFn and not data.visibleFn() then
        layout.props.size = v2(0, 0)
        layout.props.visible = false
        return layout
    end

    local headerIndent = level * Templates.SECTION_INDENT_L
    local lineIndent = (level + 1) * Templates.SECTION_INDENT_L

    if data.header then
        local headerLayout = Templates.labeledValue({ name = nil, indent = headerIndent, label = data.header, labelColor = constants.Colors.DEFAULT_LIGHT })
        if data.onHeaderClick then
            headerLayout.events = headerLayout.events or {}
            headerLayout.events.mouseClick = async:callback(function()
                ambient.playSound('menu click')
                data.onHeaderClick()
                return true
            end)
        end
        layout.content:add(headerLayout)
        totalHeight = totalHeight + Templates.LINE_HEIGHT
    end
    for _, subsection in ipairs(data.sections or {}) do
        local subsectionLayout = createSection(subsection, level + 1)
        subsectionLayout.props.position = v2(0, totalHeight)
        layout.content:add(subsectionLayout)
        if subsectionLayout.props.visible then
            totalHeight = totalHeight + subsectionLayout.props.size.y
            visibleLines = visibleLines + subsectionLayout.userData.visibleLines
        end
    end

    local sortedLines = data.lines or {}
    if data.sort == constants.Sort.LABEL_ASC then
        table.sort(sortedLines, function(a, b) return a.label < b.label end)
    elseif data.sort == constants.Sort.LABEL_DESC then
        table.sort(sortedLines, function(a, b) return a.label > b.label end)
    end

    -- Sort lines with placement logic if placement is defined
    sortedLines = sortSections(sortedLines, false)

    local indent = data.indent and lineIndent or headerIndent
    for _, line in ipairs(sortedLines) do
        local lineLayout = Templates.labeledValue({ name = line.id, indent = indent, label = line.label, labelColor = line.labelColor, type = line.type, valueFn = line.value, tooltipFn = line.tooltip, visibleFn = line.visibleFn })
        lineLayout.props.position = v2(0, totalHeight)
        lineLayout.props.visible = not lineLayout.userData.visibleFn or lineLayout.userData.visibleFn()
        if line.onClick then
            lineLayout.events = lineLayout.events or {}
            lineLayout.events.mouseClick = async:callback(function(e, layout)
                ambient.playSound('menu click')
                line.onClick()
                return true
            end)
        end
        layout.content:add(lineLayout)
        if lineLayout.props.visible then
            visibleLines = visibleLines + 1
            totalHeight = totalHeight + Templates.LINE_HEIGHT
        else
            lineLayout.props.size = v2(0, 0)
        end
    end
    layout.userData.visibleLines = visibleLines
    layout.props.size = v2(0, totalHeight)
    if visibleLines == 0 and not data.showIfNoLines then
        layout.props.size = v2(0, 0)
        layout.props.visible = false
    end
    return layout
end

local function createBox(data)
    local sortedSections = sortSections(data.sections or {}, true)
    local content = ui.content {}
    local lastVisibleSection = nil
    for i, sectionData in ipairs(sortedSections) do
        local section = createSection(sectionData)
        if section.props.visible then
            if lastVisibleSection and lastVisibleSection.userData.divider.after and section.userData.divider.before then
                local divider = auxUi.deepLayoutCopy(Templates.sectionDivider)
                content:add(divider)
            end
            lastVisibleSection = section
        end
        content:add(section)
    end
    local box = Templates.box(data.id, content)
    box.props.size = v2(0, box.userData.contentHeight)
    if data.maxHeightLines and data.maxHeightLines > 0 then
        box.userData.maxHeight = data.maxHeightLines * Templates.LINE_HEIGHT + (Templates.BOX_INNER_PADDING * 2) + (Templates.BORDER_THICKNESS * 2)
        box.props.size = v2(0, math.min(box.userData.maxHeight, box.userData.contentHeight))
    end
    box.props.visible = box.userData.contentHeight > 0
    return box
end

local function createPane(paneId, boxes)
    local sortedBoxes = sortSections(boxes or {}, false)
    local content = ui.content {}
    local lastBoxVisible = false

    for i, boxData in ipairs(sortedBoxes) do
        local box = createBox(boxData)

        if lastBoxVisible and box.props.visible then
            content:add(BASE.intervalV(Templates.BOX_OUTER_PADDING))
            lastBoxVisible = false
        end

        if box.props.visible then
            lastBoxVisible = true
        end

        if i == #sortedBoxes then
            local scrollableName = box.name .. '_scrollable'
            box.content = ui.content {
                BASE.scrollable(
                    v2(0, 0),
                    box.content,
                    v2(0, box.userData.contentHeight - ((Templates.BOX_INNER_PADDING) * 2)),
                    Templates.LINE_HEIGHT * 2,
                    false,
                    function(e) Templates.focusedScrollable = e end,
                    function(e) Templates.focusedScrollable = nil end,
                    storedScrollPos[scrollableName],
                    scrollableName
                )
            }
            box.content[1].layout.props.position = v2(Templates.BOX_INNER_PADDING, Templates.BOX_INNER_PADDING)
        end
        content:add(box)
    end

    return Templates.pane(paneId, content)
end

Templates.statsWindow = function(sections, allowPin, scrollPosList)
    storedScrollPos = scrollPosList or {}

    sections = helpers.deepCopy(sections or {})

    local windowOptions = configPlayer.window

    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size

    local selfRecord = omwself.type.records[omwself.recordId]
    local playerName = selfRecord.name

    local base = BASE.containerWithHeader(playerName, {
        createPane(constants.Panes.LEFT, sections[constants.Panes.LEFT] or {}),
        createPane(constants.Panes.RIGHT, sections[constants.Panes.RIGHT] or {}),
        {
            name = 'paneDivider',
            template = I.MWUI.templates.verticalLine,
            props = {
                visible = intRe,
            },
        }
    })

    base.layer = 'Windows'
    local minWidth = Templates.MIN_LEFT_WIDTH + Templates.BORDER_WIDTH_TOTAL + Templates.BOX_OUTER_PADDING * 2
    base.props = {
        position = util.vector2(
            windowOptions.f_StatsX * layerSize.x,
            windowOptions.f_StatsY * layerSize.y
        ),
        size = util.vector2(
            math.max(windowOptions.f_StatsW * layerSize.x, minWidth),
            math.max(windowOptions.f_StatsH * layerSize.y, Templates.MIN_HEIGHT)
        ),
    }

    if allowPin then
        local pinButton = BASE.pinButton(windowOptions.b_StatsPinned, function(isPinned)
            storage.playerSection('Settings/StatsWindow/2_WindowOptions'):set('b_StatsPinned', isPinned)
        end)
        pinButton.layout.props.anchor = v2(1, 0)
        pinButton.layout.props.relativePosition = v2(1, 0)
        base.content:add(pinButton)
    end

    return base
end

return Templates