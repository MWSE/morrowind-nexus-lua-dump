local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require("openmw.util")
local l10n = core.l10n('eemlua')
local omwl10n = core.l10n('Interface')

local lineHeight = I.MWUI.templates.textNormal.props.textSize
local skillsWidth = 250
local attributesWidth = 150
local tooltipWidth = 500
local tooltipOffset = util.vector2(lineHeight, lineHeight)

local spacer = {
    external = { grow = 1 }
}

local leftArrow = {
    type = ui.TYPE.Image,
    props = {
        size = util.vector2(lineHeight, lineHeight),
        resource = ui.texture({ path = 'textures/omw_menu_scroll_left.dds' })
    }
}

local rightArrow = {
    type = ui.TYPE.Image,
    props = {
        size = util.vector2(lineHeight, lineHeight),
        resource = ui.texture({ path = 'textures/omw_menu_scroll_right.dds' })
    }
}

local coin = {
    type = ui.TYPE.Image,
    props = {
        size = util.vector2(lineHeight, lineHeight),
        resource = ui.texture({ path = 'icons/tx_goldicon.dds' })
    }
}

local function padded(element)
    return {
        template = I.MWUI.templates.padding,
        content = ui.content({ element })
    }
end

local function padding(size)
    return {
        props = {
            size = util.vector2(size, size)
        }
    }
end

local function row(width, content, events)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = util.vector2(width, lineHeight)
        },
        content = ui.content(content),
        events = events
    }
end

local function createSkillLine(skill, player, onClick, showSkill)
    local text = padded({
        template = I.MWUI.templates.textEditLine,
        name = 'value',
        props = {
            text = tostring(0),
            readOnly = true,
            size = util.vector2(lineHeight, lineHeight),
            textAlignH = ui.ALIGNMENT.Center,
        }
    })
    return row(skillsWidth, {
        padded({
            template = I.MWUI.templates.textNormal,
            props = {
                text = skill.name,
            }
        }),
        spacer,
        padded({
            template = I.MWUI.templates.textNormal,
            props = {
                text = tostring(types.Player.stats.skills[skill.id](player).base),
                textAlignH = ui.ALIGNMENT.End,
                size = util.vector2(lineHeight * 3, lineHeight * 3),
            }
        }),
        padding(5),
        {
            template = I.MWUI.templates.padding,
            content = ui.content({ leftArrow }),
            events = {
                mouseClick = async:callback(function()
                    onClick(skill, -1, text.content.value)
                end)
            }
        },
        padding(2),
        text,
        padding(2),
        {
            template = I.MWUI.templates.padding,
            content = ui.content({ rightArrow }),
            events = {
                mouseClick = async:callback(function()
                    onClick(skill, 1, text.content.value)
                end)
            }
        },
        padding(5)
    }, {
        mouseMove = async:callback(function(e)
            showSkill(skill, e.position)
            return false
        end)
    })
end

local function createAttributeLine(attribute, player, onClick, data)
    local holder = {}
    local base = types.Player.stats.attributes[attribute.id](player).base
    local value = padded({
        template = I.MWUI.templates.textNormal,
        name = 'value',
        props = {
            text = tostring(base),
            textAlignH = ui.ALIGNMENT.End,
            size = util.vector2(lineHeight * 3, lineHeight * 3)
        }
    })
    data.attributeValues[attribute.id] = value.content.value
    local line = row(attributesWidth, {
        padded({
            template = I.MWUI.templates.textNormal,
            props = {
                text = attribute.name
            },
            events = {
                mouseClick = async:callback(function()
                    onClick(attribute.id, holder.coin)
                end)
            }
        }),
        {
            template = I.MWUI.templates.padding,
            name = 'coin',
            props = {
                alpha = 0
            },
            content = ui.content({
                padding(5),
                coin
            })
        },
        spacer,
        value,
        padding(5)
    }, {
        mouseMove = async:callback(function(e)
            data.tooltip.showAttribute(attribute, e.position)
            return false
        end)
    })
    holder.coin = line.content.coin
    return line
end

local function createSkillsHeader(data)
    local value = padded({
        template = I.MWUI.templates.textHeader,
        name = 'value',
        props = {
            text = tostring(data.skillPoints)
        }
    })
    data.skillHeader = value.content.value
    return {
        row(skillsWidth, {
            padded({
                template = I.MWUI.templates.textNormal,
                props = {
                    text = l10n('skillsPointsLeft')
                }
            }),
            spacer,
            value,
            padding(5)
        }),
        padding(10)
    }
end

local function getCoins(data)
    local coins = { spacer }
    for i = 1, data.attributePoints do
        table.insert(coins, padded(coin))
        table.insert(coins, spacer)
    end
    return coins
end

local function createAttributesHeader(data)
    data.attributeHeader = row(attributesWidth, getCoins(data))
    return {
        data.attributeHeader,
        padding(10)
    }
end

local function button(text, events)
    return {
        type = ui.TYPE.Flex,
        template = I.MWUI.templates.bordersThick,
        events = events,
        content = ui.content({
            padding(3),
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true
                },
                content = ui.content({
                    padding(5),
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text
                        }
                    },
                    padding(15)
                })
            },
            padding(13)
        })
    }
end

local function createTooltip(data)
    local icon = padded({
        type = ui.TYPE.Image,
        name = 'icon',
        props = {
            size = util.vector2(32, 32),
            resource = nil
        }
    })
    local function setIcon(path)
        icon.content.icon.props.resource = ui.texture({ path = path })
    end
    local title = padded({
        template = I.MWUI.templates.textHeader,
        name = 'name',
        props = {
            multiline = true,
            text = nil
        }
    })
    local function setTitle(text)
        title.content.name.props.text = text
    end
    local subtitle = padded({
        template = I.MWUI.templates.textNormal,
        name = 'name',
        props = {
            multiline = true,
            text = nil
        }
    })
    local function setSubtitle(text)
        subtitle.content.name.props.text = text
    end
    local description = padded({
        template = I.MWUI.templates.textParagraph,
        name = 'text',
        props = {
            size = util.vector2(tooltipWidth, 0),
            textAlignV = ui.ALIGNMENT.Center,
            wordWrap = true,
            multiline = true,
            text = nil
        }
    })
    local function setDescription(text)
        description.content.text.props.text = text
    end
    local tooltip = ui.create({
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Popup',
        props = {
            visible = false
        },
        content = ui.content({
            padded({
                type = ui.TYPE.Flex,
                content = ui.content({
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true
                        },
                        content = ui.content({
                            icon,
                            {
                                type = ui.TYPE.Flex,
                                content = ui.content({
                                    title,
                                    subtitle
                                })
                            }
                        })
                    },
                    description
                })
            })
        })
    })
    local function show(pos)
        tooltip.layout.props.position = pos + tooltipOffset
        tooltip.layout.props.visible = true
        tooltip:update()
    end
    return {
        destroy = function()
            tooltip:destroy()
        end,
        hide = function()
            tooltip.layout.props.visible = false
            tooltip:update()
        end,
        showSkill = function(skill, pos)
            local attribute = core.stats.Attribute.record(skill.attribute).name
            setTitle(skill.name)
            setSubtitle(l10n('governingAttribute') .. ': ' .. attribute)
            setIcon(skill.icon)
            setDescription(skill.description)
            show(pos)
        end,
        showAttribute = function(attribute, pos)
            setTitle(attribute.name)
            setSubtitle(nil)
            setIcon(attribute.icon)
            setDescription(attribute.description)
            show(pos)
        end
    }
end

local function getStatColumns(skills, attributes, levelUp)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true
        },
        content = ui.content({
            {
                template = I.MWUI.templates.borders,
                type = ui.TYPE.Flex,
                content = ui.content(skills)
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    size = util.vector2(attributesWidth, 0)
                },
                external = {
                    stretch = 1
                },
                content = ui.content({
                    {
                        template = I.MWUI.templates.borders,
                        type = ui.TYPE.Flex,
                        content = ui.content(attributes)
                    },
                    {
                        template = I.MWUI.templates.borders,
                        type = ui.TYPE.Flex,
                        props = {
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Center,
                            size = util.vector2(attributesWidth, lineHeight)
                        },
                        external = {
                            grow = 1
                        },
                        content = ui.content({
                            button(omwl10n('OK'), {
                                mouseClick = async:callback(levelUp)
                            })
                        })
                    }
                })
            }
        })
    }
end

local function createLevelUpWindow(player, onLevelUp)
    local data = {
        skillPoints = 12,
        skills = {},
        attributePoints = 3,
        attributes = {},
        attributeValues = {},
        attributeIncreases = {},
        window = nil,
        skillHeader = nil,
        attributeHeader = nil
    }

    local function levelUp()
        if data.skillPoints > 0 or data.attributePoints > 0 then
            ui.showMessage(l10n('distributePoints'))
            return
        end
        local attributes = {}
        for id, value in pairs(data.attributeIncreases) do
            attributes[id] = value
        end
        for id, increased in pairs(data.attributes) do
            if increased then
                attributes[id] = (attributes[id] or 0) + 1
            end
        end
        onLevelUp(attributes, data.skills)
        I.UI.setMode()
    end

    local function setAttributeValue(attribute, increase)
        data.attributeValues[attribute].props.text = tostring(types.Player.stats.attributes[attribute](player).base + increase)
        if increase > 0 then
            data.attributeValues[attribute].template = I.MWUI.templates.textHeader
        else
            data.attributeValues[attribute].template = I.MWUI.templates.textNormal
        end
    end

    local function modSkill(skill, d, content)
        if data.skillPoints - d < 0 then
            return
        end
        local value = (data.skills[skill.id] or 0) + d
        if value > 3 or value < 0 then
            return
        end
        if value == 0 then
            data.skills[skill.id] = nil
        else
            data.skills[skill.id] = value
        end
        data.skillPoints = data.skillPoints - d
        content.props.text = tostring(value)
        data.skillHeader.props.text = tostring(data.skillPoints)
        local attribute = skill.attribute
        local increase = 0
        for id, points in pairs(data.skills) do
            if core.stats.Skill.record(id).attribute == attribute then
                increase = increase + points
            end
        end
        increase = math.floor(increase / 2)
        if data.attributeIncreases[attribute] ~= increase then
            data.attributeIncreases[attribute] = increase
            if data.attributes[attribute] then
                increase = increase + 1
            end
            setAttributeValue(attribute, increase)
        end
        data.window:update()
    end

    data.tooltip = createTooltip(data)

    local skills = createSkillsHeader(data)
    for i, skill in pairs(core.stats.Skill.records) do
        table.insert(skills, createSkillLine(skill, player, modSkill, data.tooltip.showSkill))
    end
    table.insert(skills, padding(5))

    local function clickAttribute(attribute, coin)
        local d = data.attributeIncreases[attribute] or 0
        if data.attributes[attribute] then
            data.attributes[attribute] = nil
            data.attributePoints = data.attributePoints + 1
            coin.props.alpha = 0
        elseif data.attributePoints > 0 then
            data.attributes[attribute] = true
            data.attributePoints = data.attributePoints - 1
            coin.props.alpha = 1
            d = d + 1
        else
            return
        end
        data.attributeHeader.content = ui.content(getCoins(data))
        setAttributeValue(attribute, d)
        data.window:update()
    end

    local attributes = createAttributesHeader(data)
    for i, attribute in pairs(core.stats.Attribute.records) do
        table.insert(attributes, createAttributeLine(attribute, player, clickAttribute, data))
    end
    table.insert(attributes, padding(5))

    data.window = ui.create({
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Windows',
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5)
        },
        events = {
            mouseMove = async:callback(function()
                data.tooltip.hide()
            end)
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                content = ui.content({
                    {
                        template = I.MWUI.templates.borders,
                        type = ui.TYPE.Flex,
                        external = {
                            stretch = 1
                        },
                        content = ui.content({
                            {
                                type = ui.TYPE.Flex,
                                external = {
                                    stretch = 1
                                },
                                props = {
                                    horizontal = true
                                },
                                content = ui.content({
                                    padded({
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                            text = l10n('reachedLevel')
                                        }
                                    }),
                                    spacer,
                                    padded({
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                            text = tostring(types.Player.stats.level(player).current + 1)
                                        }
                                    }),
                                    padding(5)
                                })
                            },
                            padding(5)
                        })
                    },
                    getStatColumns(skills, attributes, levelUp)
                })
            }
        })
    })
    return data
end

local function register(player, canLevelUp, onLevelUp)
    local data
    I.UI.registerWindow('LevelUpDialog', function()
        if not data then
            data = createLevelUpWindow(player, onLevelUp)
        end
    end, function()
        if data then
            data.window:destroy()
            data.tooltip.destroy()
            data = nil
            core.sendGlobalEvent('EE_MLua_FinishLevel', { player = player.object, hasLevel = canLevelUp() })
        end
    end)
end

return { registerLevelUp = register }
