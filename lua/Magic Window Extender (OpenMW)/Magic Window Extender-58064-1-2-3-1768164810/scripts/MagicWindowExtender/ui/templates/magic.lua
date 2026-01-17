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

local BASE = require('scripts.MagicWindowExtender.ui.templates.base')
local helpers = require('scripts.MagicWindowExtender.util.helpers')
local constants = require('scripts.MagicWindowExtender.util.constants')

local configPlayer = require('scripts.MagicWindowExtender.config.player')

local v2 = util.vector2

local intRe = configPlayer.modIntegration.b_InterfaceReimagined

local Templates = {}

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
Templates.MIN_HEIGHT = 4 + 
    Templates.HEADER_HEIGHT + 
    Templates.BORDER_WIDTH_TOTAL + 
    Templates.BOX_OUTER_PADDING * 2 + 
    Templates.BOX_INNER_PADDING * 2 + 
    Templates.LINE_HEIGHT * 3
Templates.MIN_INNER_WIDTH = 60

Templates.active = false
Templates.focusedScrollable = nil
Templates.focusedLabel = nil
Templates.activeTooltip = nil
Templates.linesToProcess = {}
Templates.updateQueue = {}
local lastMousePos = nil
local storedScrollPos = {}
Templates.modalElement = nil

Templates.createTexture = BASE.createTexture

local function getInteractiveTextColor(layout)
    local userData = layout.userData or {}
    if userData.active then
        if userData.pressed then
            return constants.Colors.ACTIVE_PRESSED
        elseif userData.hovering then
            return constants.Colors.ACTIVE_LIGHT
        else
            return constants.Colors.ACTIVE
        end
    elseif userData.disabled then
        if userData.pressed then
            return constants.Colors.DISABLED_PRESSED
        elseif userData.hovering then
            return constants.Colors.DISABLED_LIGHT
        else
            return constants.Colors.DISABLED
        end
    else
        if userData.pressed then
            return constants.Colors.DEFAULT_PRESSED
        elseif userData.hovering then
            return constants.Colors.DEFAULT_LIGHT
        else
            return userData.baseTextColor or constants.Colors.DEFAULT
        end
    end
end

Templates.interactive = function(props, layout)
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

    local element = layout.layout and layout or ui.create(layout)

    element.layout.userData = element.layout.userData or {}
    element.layout.userData.interactive = true

    element.layout.events = element.layout.events or {}
    element.layout.events.mousePress = async:callback(function(e, layout)
        if e.button ~= 1 then
            return false
        end
        if props.onClick then
            element.layout.userData.pressed = true
            ambient.playSound('menu click')
            helpers.forEachInLayout(element.layout, function(l)
                if l.userData and l.userData.colorable then
                    l.props = l.props or {}
                    l.props.textColor = getInteractiveTextColor(layout)
                    l.props.color = getInteractiveTextColor(element.layout)
                end
            end)
            element:update()
            return true
        end
        return false
    end)
    element.layout.events.mouseRelease = async:callback(function(e, layout)
        if e.button ~= 1 then
            return false
        end
        if props.onClick then
            element.layout.userData.pressed = false
            helpers.forEachInLayout(element.layout, function(l)
                if l.userData and l.userData.colorable then
                    l.props = l.props or {}
                    l.props.textColor = getInteractiveTextColor(layout)
                    l.props.color = getInteractiveTextColor(element.layout)
                end
            end)
            props.onClick()
            element:update()
            return true
        end
        return false
    end)
    element.layout.events.focusLoss = async:callback(function()
        element.layout.userData.hovering = false
        if element.layout.userData.tooltipFn then
            if Templates.activeTooltip and Templates.activeTooltip.layout then
                Templates.activeTooltip.layout.props.visible = false
                table.insert(Templates.updateQueue, Templates.activeTooltip)
            end
        end

        if props.onClick then
            helpers.forEachInLayout(element.layout, function(l)
                if l.userData and l.userData.colorable then
                    l.props = l.props or {}
                    l.props.textColor = getInteractiveTextColor(layout)
                    l.props.color = getInteractiveTextColor(element.layout)
                end
            end)
            table.insert(Templates.updateQueue, element)
        end
        return true
    end)
    element.layout.events.focusGain = async:callback(function(e, layout)
        if props.onClick then
            helpers.forEachInLayout(element.layout, function(l)
                if l.userData and l.userData.colorable then
                    l.props = l.props or {}
                    l.props.textColor = getInteractiveTextColor(layout)
                    l.props.color = getInteractiveTextColor(element.layout)
                end
            end)
            table.insert(Templates.updateQueue, element)
        end
        return true
    end)
    element.layout.events.mouseMove = async:callback(function(e, layout)
        element.layout.userData.hovering = true
        if element.layout.userData.tooltipFn then
            if not Templates.activeTooltip or not Templates.activeTooltip.layout then
                Templates.activeTooltip = createTooltip(layout)
            elseif Templates.activeTooltip.layout.name ~= props.name then
                auxUi.deepDestroy(Templates.activeTooltip)
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
        end
    end)
    return element
end

Templates.lineEditControls = function(editInfo)
    local pinned = helpers.deepCopy(I.MagicWindow.getStat(constants.TrackedStats.PINNED) or {})
    local hidden = helpers.deepCopy(I.MagicWindow.getStat(constants.TrackedStats.HIDDEN) or {})

    local isPinned = pinned[editInfo.type] and pinned[editInfo.type][editInfo.id] == true
    local isHidden = hidden[editInfo.type] and hidden[editInfo.type][editInfo.id] == true

    local layout = {
        name = 'editControls',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = v2((Templates.LINE_HEIGHT - 2) * 2 + 4, Templates.LINE_HEIGHT),
        },
        content = ui.content {
            Templates.interactive({
                onClick = function()
                    if isPinned then
                        pinned[editInfo.type][editInfo.id] = nil
                    else
                        pinned[editInfo.type] = pinned[editInfo.type] or {}
                        pinned[editInfo.type][editInfo.id] = true
                    end
                    I.MagicWindow.setStat(constants.TrackedStats.PINNED, pinned)
                end,
            }, {
                type = ui.TYPE.Image,
                props = {
                    resource = BASE.createTexture(isPinned and 'textures/MagicWindowExtender/pinned_true.dds' or 'textures/MagicWindowExtender/pinned_false.dds'),
                    color = isPinned and constants.Colors.WHITE or constants.Colors.DEFAULT,
                    size = v2(Templates.LINE_HEIGHT - 2, Templates.LINE_HEIGHT - 2),
                    propagateEvents = false,
                },
            }),
            Templates.interactive({
                onClick = function()
                    if isHidden then
                        hidden[editInfo.type][editInfo.id] = nil
                    else
                        hidden[editInfo.type] = hidden[editInfo.type] or {}
                        hidden[editInfo.type][editInfo.id] = true
                    end
                    I.MagicWindow.setStat(constants.TrackedStats.HIDDEN, hidden)
                end,
            }, {
                type = ui.TYPE.Image,
                props = {
                    resource = BASE.createTexture(isHidden and 'textures/MagicWindowExtender/hidden_true.dds' or 'textures/MagicWindowExtender/hidden_false.dds'),
                    color = isHidden and constants.Colors.DEFAULT or constants.Colors.DEFAULT_LIGHT,
                    size = v2(Templates.LINE_HEIGHT - 2, Templates.LINE_HEIGHT - 2),
                    propagateEvents = false,
                },
            }),
        }
    }

    return layout
end

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
            {
                name = 'pre',
                template = BASE.intervalH(props.indent),
            },
            {
                name = 'icon',
                type = ui.TYPE.Image,
                props = {
                },
                content = ui.content {}
            },
            {
                name = 'iconPadding',
                props = {},
            },
            {
                name = 'label',
                props = {
                    relativeSize = v2(0, 1),
                },
                external = {
                    grow = 1,
                },
                content = ui.content {
                    {
                        template = BASE.textNormal,
                        props = {
                            text = props.label,
                            textSize = Templates.TEXT_SIZE,
                            textColor = props.labelColor,
                        },
                        userData = { colorable = true },
                    }
                }
            },
            {
                name = 'value',
                template = BASE.textNormal,
                props = {
                    textSize = Templates.TEXT_SIZE,
                    textColor = props.valueColor,
                },
                userData = { colorable = true },
            }
        },
        userData = {
            type = constants.LineType.LABELED_VALUE,
            valueType = props.valueType or constants.ValueType.STRING,
            iconFn = props.iconFn,
            valueFn = props.valueFn,
            tooltipFn = props.tooltipFn,
            visibleFn = props.visibleFn,
            activeFn = props.activeFn,
            disabledFn = props.disabledFn,
        },
    }

    if props.onClick then
        return Templates.interactive(props, layout)
    else 
        return ui.create(layout)
    end
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
                    resource = BASE.createTexture('textures/menu_bar_gray.dds'),
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

Templates.activeEffectTooltip = function(effectId)
    local strings = {}
    for _, spell in pairs(omwself.type.activeSpells(omwself)) do
        for _, effect in pairs(spell.effects) do
            if effect.id == effectId then
                local effectString = helpers.createActiveEffectString(effect, spell.name)
                local textLayout = {
                    template = BASE.textNormal,
                    props = {
                        text = effectString,
                    }
                }
                table.insert(strings, textLayout)
            end
        end
    end

    return Templates.tooltip(6, ui.content {
        {
            name = 'tooltip',
            type = ui.TYPE.Flex,
            props = {
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        Templates.effectIcon(effectId),
                        BASE.intervalH(4),
                        {
                            template = BASE.textHeader,
                            props = {
                                text = core.magic.effects.records[effectId].name,
                            }
                        }
                    }
                },
                BASE.intervalV(4),
                {
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = ui.ALIGNMENT.Start,
                    },
                    content = ui.content {
                        table.unpack(strings)
                    }
                }
            }
        }
    }, effectId)
end

Templates.spellTooltip = function(spellId)
    local spellRecord = core.magic.spells.records[spellId]
    local override = I.MagicWindow.Spells.getCustomSpell(spellId)
    local effectLayouts = {}
    for i, effect in ipairs(override and override.effects or spellRecord.effects) do
        local effectLayout = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                Templates.effectIcon(effect.id),
                BASE.intervalH(4),
                {
                    template = BASE.textNormal,
                    props = {
                        text = helpers.createSpellEffectString(effect),
                    }
                }
            }
        }
        if i ~= 1 then
            table.insert(effectLayouts, BASE.intervalV(8))
        end
        table.insert(effectLayouts, effectLayout)
    end

    local _, effectiveSchool = helpers.getSpellCastChance(spellId)
    local schoolName
    if effectiveSchool then
        schoolName = core.stats.Skill.records[effectiveSchool].name
    end

    return Templates.tooltip(8, ui.content {
        {
            name = 'tooltip',
            type = ui.TYPE.Flex,
            props = {
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    template = BASE.textHeader,
                    props = {
                        text = override and override.name or spellRecord.name,
                    }
                },
                BASE.intervalV(4),
                schoolName and {
                    template = BASE.textNormal,
                    props = {
                        text = constants.Strings.SCHOOL .. ': ' .. schoolName,
                    }
                } or {},
                schoolName and BASE.intervalV(4) or {},
                {
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = ui.ALIGNMENT.Start,
                    },
                    content = ui.content {
                        table.unpack(effectLayouts)
                    }
                }
            }
        }
    }, spellId)
end

Templates.itemTooltip = function(item)
    local itemRecord = item.type.record(item)
    local itemData = types.Item.itemData(item)
    local effectLayouts = {}

    local enchantment
    local castTypeString
    local doCharge
    local maxCharge
    if itemRecord.enchant then
        enchantment = core.magic.enchantments.records[itemRecord.enchant]
        local override = I.MagicWindow.Spells.getCustomSpell(itemRecord.enchant)
        for i, effect in ipairs(override and override.effects or enchantment.effects) do
            local effectLayout = {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    Templates.effectIcon(effect.id),
                    BASE.intervalH(4),
                    {
                        template = BASE.textNormal,
                        props = {
                            text = helpers.createSpellEffectString(effect, enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect),
                        }
                    }
                }
            }
            if i ~= 1 then
                table.insert(effectLayouts, BASE.intervalV(8))
            end
            table.insert(effectLayouts, effectLayout)
        end

        if enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
            castTypeString = constants.Strings.ITEM_CAST_WHEN_STRIKES
            doCharge = true
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
            castTypeString = constants.Strings.ITEM_CAST_WHEN_USED
            doCharge = true
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
            castTypeString = constants.Strings.ITEM_CAST_ONCE
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            castTypeString = constants.Strings.ITEM_CAST_CONSTANT
        end

        if enchantment.autocalcFlag then
            maxCharge = helpers.getEnchantMaxCharge(enchantment)
        else
            maxCharge = enchantment.charge
        end
    end

    local nameString = itemRecord.name
    if item.count > 1 then
        nameString = nameString .. ' (' .. tostring(item.count) .. ')'
    end

    return Templates.tooltip(8, ui.content {
        {
            name = 'tooltip',
            type = ui.TYPE.Flex,
            props = {
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    template = BASE.textHeader,
                    props = {
                        text = nameString,
                    }
                },
                BASE.intervalV(4),
                {
                    template = BASE.textNormal,
                    props = {
                        text = constants.Strings.ITEM_WEIGHT .. ': ' .. helpers.roundToPlaces(itemRecord.weight, 3),
                    }
                },
                {
                    template = BASE.textNormal,
                    props = {
                        text = constants.Strings.ITEM_VALUE .. ': ' .. (itemRecord.value)
                    }
                },
                castTypeString and {
                    template = BASE.textNormal,
                    props = {
                        text = castTypeString,
                    }
                },
                itemRecord.enchant and BASE.intervalV(4) or {},
                itemRecord.enchant and {
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = ui.ALIGNMENT.Start,
                    },
                    content = ui.content {
                        table.unpack(effectLayouts)
                    }
                } or {},
                doCharge and BASE.intervalV(8) or {},
                doCharge and {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            template = BASE.textNormal,
                            props = {
                                text = constants.Strings.CHARGE,
                            }
                        },
                        BASE.intervalH(5),
                        Templates.progressBar {
                            value = itemData.enchantmentCharge or 0,
                            maxValue = maxCharge,
                            size = v2(204, Templates.LINE_HEIGHT),
                            color = constants.Colors.BAR_HEALTH,
                            textColor = constants.Colors.DEFAULT,
                        }
                    }
                } or {},
            }
        }
    }, item.id)
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
                size = v2(-4, 2),
                position = v2(2, 0),
            },
        }
    }
}

Templates.modal = function(content)
    return {
        layer = "Windows",
        props = {
            relativeSize = v2(1, 1), -- Block input for entire layer
        },
        content = ui.content {
            {
                template = BASE.boxSolidThick,
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                },
                content = ui.content(content)
            }
        }
    }
end

Templates.choiceModal = function(headerLayout, choices)
    -- example: choices = { { text = "Yes", onClick = fn }, { text = "No", onClick = fn } }
    local choiceButtons = {}
    for i, choice in ipairs(choices) do
        table.insert(choiceButtons, Templates.interactive({
            onClick = function()
                if Templates.modalElement then
                    auxUi.deepDestroy(Templates.modalElement)
                    Templates.modalElement = nil
                end
                choice.onClick()
            end,
        }, BASE.button(choice.text, choice.onClick)))
        if i ~= #choices then
            table.insert(choiceButtons, BASE.intervalH(8))
        end
    end
    local content = {
        {
            template = BASE.padding(8),
            content = ui.content {
                {
                    name = 'modalContent',
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        headerLayout or {},
                        BASE.intervalV(8),
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                                arrange = ui.ALIGNMENT.Center,
                            },
                            content = ui.content {
                                table.unpack(choiceButtons)
                            }
                        }
                    }
                }
            }
        }
    }
    return Templates.modal(content)
end

local schools = {
    "alteration",
    "conjuration",
    "destruction",
    "illusion",
    "mysticism",
    "restoration",
}
Templates.schoolFilter = function()
    local layout = {
        name = 'schoolFilter',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = v2((Templates.LINE_HEIGHT) * #schools + 2, Templates.LINE_HEIGHT - 2),
        },
        content = ui.content {},
    }
    for i, school in ipairs(schools) do
        local schoolSkill = core.stats.Skill.records[school]
        local isSelected = I.MagicWindow.getStat(constants.TrackedStats.SCHOOL_FILTER) == school
        local name = 'schoolFilter_' .. school
        local path = schoolSkill.icon
        if configPlayer.tweaks.b_ColoredSchoolIcons then
            path = 'icons/MagicWindowExtender/schools/Magic_' .. schoolSkill.id .. '.tga'
        end
        local button = Templates.interactive({
            name = name,
            onClick = function()
                if I.MagicWindow.getStat(constants.TrackedStats.SCHOOL_FILTER) == school then
                    I.MagicWindow.setStat(constants.TrackedStats.SCHOOL_FILTER, nil)
                else
                    I.MagicWindow.setStat(constants.TrackedStats.SCHOOL_FILTER, school)
                end
            end,
        }, {
            type = ui.TYPE.Image,
            props = {
                resource = BASE.createTexture(path),
                alpha = isSelected and 1.0 or 0.5,
                size = v2(Templates.LINE_HEIGHT - 2, Templates.LINE_HEIGHT - 2),
            },
            userData = {
                tooltipFn = function()
                    return Templates.tooltip(8, ui.content {
                        {
                            template = BASE.textNormal,
                            props = {
                                text = core.l10n('MagicWindowExtender')('FilterBySchool', { school = schoolSkill.name } ),
                            },
                        }
                    }, name)
                end,
            }
        })
        layout.content:add(BASE.intervalH(2))
        layout.content:add(button)
        if i == #schools then
            layout.content:add(BASE.intervalH(2))
        end
    end
    return layout
end

Templates.tryDelete = function(spellId)
    local spellRecord = core.magic.spells.records[spellId]
    if not spellRecord then
        return false
    end
    if spellRecord.type ~= core.magic.SPELL_TYPE.Spell then
        ui.showMessage(constants.Strings.DELETE_SPELL_ERROR)
        return false
    end

    local SPELL_TO_INDEX = require('scripts.removeSpellFix.RSF_g').interface.SPELL_TO_INDEX
                
    local customSpellPrefix = "Generated:"
    local isRemovable = SPELL_TO_INDEX[spellId] ~= nil
    local isCustom = string.sub(spellId, 1, #customSpellPrefix) == customSpellPrefix
    if isRemovable or isCustom then
        Templates.modalElement = ui.create(Templates.choiceModal(
            {
                template = BASE.textNormal,
                props = {
                    text = string.format(constants.Strings.DELETE_SPELL_QUESTION, spellRecord.name),
                }
            },
            {
                {
                    text = constants.Strings.YES,
                    onClick = function()
                        -- This is ok for custom spells because you can never re-learn them anyway
                        if isCustom then
                            omwself.type.spells(omwself):remove(spellId)
                            local deletedList = I.MagicWindow.getStat(constants.TrackedStats.DELETED_SPELLS) or {}
                            deletedList[spellId] = true
                            I.MagicWindow.setStat(constants.TrackedStats.DELETED_SPELLS, deletedList)
                        elseif isRemovable then
                            core.sendGlobalEvent('requestSpellRemoval', { spell = spellId })
                        end
                        Templates.modalElement = nil
                    end,
                },
                {
                    text = constants.Strings.NO,
                    onClick = function()
                        Templates.modalElement = nil
                    end,
                }
            }
        ))
        return
    end

    -- Fallback if spell is not custom and not in RSF's list
    local command = string.format('player->removespell "%s"', spellId)
    local modalLayout = Templates.choiceModal(
        {
            type = ui.TYPE.Flex,
            content = ui.content {
                {
                    template = BASE.textNormal,
                    props = {
                        text = core.l10n('MagicWindowExtender')('DeleteSpellInstruction', { spellName = spellRecord.name } ),
                    }
                },
                BASE.intervalV(8),
                {
                    template = BASE.textParagraph,
                    props = {
                        text = command,
                        autoSize = false,
                        size = v2(0, Templates.LINE_HEIGHT),
                        multiline = false,
                        wordWrap = false,
                        readOnly = false, -- needs to be false to allow selection
                        textAlignH = ui.ALIGNMENT.Center,
                    },
                    external = {
                        stretch = 1,
                    },
                    events = {
                        textChanged = async:callback(function(_, layout)
                            -- Prevent editing
                            layout.props.text = command
                            Templates.modalElement:update()
                        end)
                    }
                },
            }
        },
        {
            {
                text = constants.Strings.OK,
                onClick = function()
                    Templates.modalElement = nil
                end,
            }
        }
    )
    Templates.modalElement = ui.create(modalLayout)

    return true
end

Templates.deleteButton = function()
    local base
    if configPlayer.tweaks.b_DeleteButtonIcon then
        base = BASE.imageButton('textures/MagicWindowExtender/delete.dds', v2(Templates.LINE_HEIGHT - 2 * Templates.BORDER_THICKNESS, Templates.LINE_HEIGHT - 2 * Templates.BORDER_THICKNESS))
    else
        base = BASE.button(constants.Strings.DELETE, function() end)
    end
    base.layout.props.propagateEvents = false
    return Templates.interactive({
            onClick = function()
                local selectedSpell = omwself.type.getSelectedSpell(omwself)
                if not selectedSpell then
                    return
                end

                -- modalElement = ui.create(Templates.choiceModal(
                --     string.format(constants.Strings.DELETE_SPELL_QUESTION, selectedSpell.name),
                --     {
                --         {
                --             text = constants.Strings.YES,
                --             onClick = function()
                --                 omwself.type.spells(omwself):remove(selectedSpell.id)
                --                 modalElement:destroy()
                --                 modalElement = nil
                --             end,
                --         },
                --         {
                --             text = constants.Strings.NO,
                --             onClick = function()
                --                 modalElement:destroy()
                --                 modalElement = nil
                --             end,
                --         }
                --     }
                -- ))
                
                -- Currently, deleting spells from Lua is broken due to an engine bug.
                -- Instead, we have to display a console command for the user to copy-paste.

                Templates.tryDelete(selectedSpell.id)
            end
        }, 
        base)
end

local function getMagicName()
    local name = constants.Strings.NONE
    local selected = omwself.type.getSelectedSpell(omwself)
    if selected then
        name = selected.name
    else
        selected = omwself.type.getSelectedEnchantedItem(omwself)
        if selected then
            name = selected.type.record(selected).name
        end
    end
    return name
end

Templates.effectIcon = function(effectId)
    local effectRecord = core.magic.effects.records[effectId] or I.MagicWindow.Spells.getCustomEffect(effectId)
    local layout = {
        type = ui.TYPE.Image,
        props = {
            size = v2(16, 16),
            resource = BASE.createTexture(effectRecord.icon),
        },
        userData = {
            tooltipFn = function()
                return Templates.activeEffectTooltip(effectId)
            end,
        }
    }
    return Templates.interactive({ name = effectId }, layout)
end

Templates.activeSpells = function()
    local layout = {
        name = 'activeSpellList',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {},
    }

    local currentEffects = {}

    for id, params in pairs(omwself.type.activeSpells(omwself)) do
        for _, effect in pairs(params.effects) do
            currentEffects[effect.id] = currentEffects[effect.id] or {}
            table.insert(currentEffects[effect.id], {
                affectedSkill = effect.affectedSkill,
                affectedAttribute = effect.affectedAttribute,
                magnitude = effect.magnitudeThisFrame,
                durationLeft = effect.durationLeft,
            })
        end
    end

    for i, effect in ipairs(core.magic.effects.records) do
        if currentEffects[effect.id] then
            local maxDurationLeft = 0
            for _, instance in ipairs(currentEffects[effect.id]) do
                if not instance.durationLeft then
                    maxDurationLeft = math.huge
                elseif instance.durationLeft > maxDurationLeft then
                    maxDurationLeft = instance.durationLeft
                end
            end
            local icon = Templates.effectIcon(effect.id)
            icon.layout.props.alpha = util.clamp(maxDurationLeft / core.getGMST('fMagicStartIconBlink'), 0.0, 1.0) -- Fade out icon in last 3 seconds
            layout.content:add(icon)
        end
    end

    return layout
end

Templates.updateValues = function(layout)
    local anyValChanged, anyVisChanged = false, false

    local title = layout.content.foreground.content.header.content.title
    local currentName = getMagicName()
    if title.props.text ~= currentName then
        title.props.text = currentName
        anyValChanged = true
    end

    for _, line in ipairs(Templates.linesToProcess) do
        local update = false
        local layout = line.layout and line.layout or line
        if layout.userData then
            if layout.userData.visibleFn then
                local isVisible = layout.userData.visibleFn()
                if layout.props.visible ~= isVisible then
                    layout.props.visible = isVisible
                    anyVisChanged = true
                    update = true
                end
            end
            if layout.userData.type == constants.LineType.CUSTOM and layout.userData.layoutFn then
                if not layout.userData.staticLayout then
                    local newLayout = layout.userData.layoutFn()
                    if not layout.content[1] or not helpers.mapEquals(layout.content[1].layout and layout.content[1].layout or layout.content[1], newLayout.layout and newLayout.layout or newLayout) then
                        update = true
                        auxUi.deepDestroy(layout.content[1])
                        layout.content = ui.content { newLayout }
                    end
                end
            elseif layout.userData.type == constants.LineType.LABELED_VALUE and layout.userData.valueFn then
                if layout.userData.valueType == constants.ValueType.STRING then
                    layout.content.value.userData = layout.content.value.userData or {}
                    local val = layout.userData.valueFn()
                    val.color = val.color or constants.Colors.DEFAULT
                    
                    layout.userData.baseTextColor = val.color
                    if layout.content.value.props.text ~= val.string or layout.userData.baseTextColor ~= val.color then
                        update = true
                    end
                    layout.content.value.props.text = val.string
                elseif layout.userData.valueType == constants.ValueType.CUSTOM then
                    local valLayout = layout.userData.valueFn()
                    valLayout.name = 'value'
                    if not helpers.mapEquals(layout.content.value, valLayout) then
                        update = true
                        auxUi.deepDestroy(layout.content.value)
                        layout.content.value = valLayout
                    end
                end
            end

            if layout.userData.iconFn then
                local iconPath = layout.userData.iconFn()
                if iconPath ~= layout.userData.lastIconPath then
                    update = true
                    if iconPath then
                        layout.content.icon.props.resource = BASE.createTexture(iconPath)
                        layout.content.icon.props.size = v2(Templates.LINE_HEIGHT-2, Templates.LINE_HEIGHT-2)
                        layout.content.iconPadding.props.size = v2(4, 0)
                    else
                        layout.content.icon.props.size = v2(0, 0)
                        layout.content.iconPadding.props.size = v2(0, 0)
                    end
                    layout.userData.lastIconPath = iconPath
                end 
            end
            if layout.userData.activeFn then
                local newActive = layout.userData.activeFn()
                if layout.userData.active ~= newActive then
                    update = true
                end
                layout.userData.active = newActive
            end
            if layout.userData.disabledFn then
                local newDisabled = layout.userData.disabledFn()
                if layout.userData.disabled ~= newDisabled then
                    update = true
                end
                layout.userData.disabled = newDisabled
            end

            if layout.userData.interactive then
                local interactiveColor = getInteractiveTextColor(layout)
                helpers.forEachInLayout(layout, function(l)
                    if l.userData and l.userData.colorable then
                        l.props = l.props or {}
                        if l.props.textColor ~= interactiveColor or l.props.color ~= interactiveColor then
                            update = true
                            l.props.textColor = interactiveColor
                            l.props.color = interactiveColor
                        end
                    end
                end)
            elseif layout.content:indexOf('value') then
                layout.content.value.props.textColor = layout.userData.baseTextColor or constants.Colors.DEFAULT
            end
            if update then
                line:update()
                if layout.userData.parentSection then
                    layout.userData.parentSection:update()
                end
            end
        end
        ::continue::
    end

    return anyValChanged, anyVisChanged
end

Templates.updateMagicWindow = function(layout, updateValues)
    updateValues = updateValues == nil and true or updateValues
    local anyValChanged, anyVisChanged
    if updateValues then
        anyValChanged, anyVisChanged = Templates.updateValues(layout)
    end

    local minWidth = Templates.MIN_INNER_WIDTH + Templates.BORDER_WIDTH_TOTAL + Templates.BOX_OUTER_PADDING * 2

    layout.props.size = util.vector2(
        math.max(layout.props.size.x, minWidth),
        math.max(layout.props.size.y, Templates.MIN_HEIGHT)
    )

    local windowWidth = layout.props.size.x
    local windowHeight = layout.props.size.y
    local innerWidth = windowWidth - Templates.BORDER_WIDTH_TOTAL
    local innerHeight = windowHeight - Templates.BORDER_WIDTH_TOTAL - Templates.HEADER_HEIGHT
    local availableWidth = innerWidth - 2 * Templates.BOX_OUTER_PADDING
    local availableHeight = innerHeight - 2 * Templates.BOX_OUTER_PADDING
    
    local body = layout.content.foreground.content.body
    local mainPane = body.content[constants.Panes.MAIN]

    local nonFixedBoxes = {}

    mainPane.props.position = util.vector2(Templates.BOX_OUTER_PADDING, Templates.BOX_OUTER_PADDING)
    mainPane.props.size = util.vector2(availableWidth, availableHeight)
    local usedHeight = 0
    for _, box in ipairs(mainPane.content) do
        local boxLayout = box.layout and box.layout or box
        if boxLayout.userData and boxLayout.userData.fixedHeight then
            usedHeight = usedHeight + boxLayout.props.size.y
        elseif boxLayout.userData and boxLayout.userData.contentHeight then
            table.insert(nonFixedBoxes, box)
        else
            usedHeight = usedHeight + boxLayout.props.size.y
        end
    end
    for _, box in ipairs(nonFixedBoxes) do
        local boxLayout = box.layout and box.layout or box
        local maxHeight = boxLayout.userData and boxLayout.userData.maxHeight or math.huge
        local calcHeight = math.min(
            math.floor((availableHeight - usedHeight) / #nonFixedBoxes),
            maxHeight
        )
        boxLayout.props.size = util.vector2(
            boxLayout.props.size.x,
            calcHeight
        )
        if type(box) == 'userdata' then box:update() end
        usedHeight = usedHeight + calcHeight
    end
    for _, box in ipairs(mainPane.content) do
        box = box.layout and box.layout or box
        if box.userData and box.userData.scrollable then
            box.content[1].layout.userData.update(util.vector2(
                mainPane.props.size.x,
                box.props.size.y
            ))
        end
    end

    return anyValChanged, anyVisChanged
end

Templates.pane = function(id, content)
    local totalContentHeight = 0
    for _, item in ipairs(content) do
        item = item.layout and item.layout or item
        if item.userData then
            if item.userData.maxHeight then
                totalContentHeight = totalContentHeight + math.min(item.userData.maxHeight, item.userData.totalHeight)
            else
                totalContentHeight = totalContentHeight + item.userData.totalHeight
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

Templates.box = function(id, content, padding, bordered)
    local totalContentHeight = 0
    for _, item in ipairs(content) do
        item = item.layout and item.layout or item
        item.props.position = v2(0, totalContentHeight)
        totalContentHeight = totalContentHeight + item.props.size.y
    end

    local template
    if not bordered then
        template = BASE.bordersEmpty
    elseif not intRe then
        template = I.MWUI.templates.borders
    else
        template = BASE.bordersInvisible
    end
    local borderThickness = bordered and Templates.BORDER_THICKNESS or 0

    return {
        name = id,
        template = template,
        props = {
            relativeSize = v2(1, 0),
        },
        content = ui.content {
            {
                name = 'padding',
                props = {
                    position = v2(padding, padding),
                    size = v2(-padding * 2, -padding * 2),
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
            padding = padding,
            borderThickness = borderThickness,
            contentHeight = totalContentHeight,
            totalHeight = totalContentHeight + (totalContentHeight > 0 and (borderThickness + padding) * 2 or 0),
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
    local section = {
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
    if data.horizontal then
        section.type = ui.TYPE.Flex
        section.props.horizontal = true 
    end
    section.userData.divider.before = section.userData.divider.before ~= false
    section.userData.divider.after = section.userData.divider.after ~= false
    if data.visibleFn and not data.visibleFn() then
        section.props.size = v2(0, 0)
        section.props.visible = false
        return section
    end

    local headerIndent = level * Templates.SECTION_INDENT_L
    local lineIndent = (level + 1) * Templates.SECTION_INDENT_L

    if data.header then
        local header = Templates.labeledValue({ name = nil, indent = headerIndent, label = data.header.label, labelColor = constants.Colors.DEFAULT_LIGHT, valueFn = data.header.value, })
        if data.onHeaderClick then
            header.layout.events = header.layout.events or {}
            header.layout.events.mouseClick = async:callback(function()
                ambient.playSound('menu click')
                data.onHeaderClick()
                return true
            end)
        end
        section.content:add(header)
        table.insert(Templates.linesToProcess, header)
        if data.horizontal then
            section.content:add(BASE.intervalH(4))
            totalHeight = math.max(totalHeight, Templates.LINE_HEIGHT)
        else
            totalHeight = totalHeight + Templates.LINE_HEIGHT + 4
        end
    end

    if not data.horizontal then
        for _, subsection in ipairs(data.sections or {}) do
            local subsectionLayout = createSection(subsection, level + 1)
            subsectionLayout.props.position = v2(0, totalHeight)
            section.content:add(subsectionLayout)
            if subsectionLayout.props.visible then
                totalHeight = totalHeight + subsectionLayout.props.size.y
                visibleLines = visibleLines + subsectionLayout.userData.visibleLines
            end
        end
    end

    local pinned = I.MagicWindow.getStat(constants.TrackedStats.PINNED) or {}
    local hidden = I.MagicWindow.getStat(constants.TrackedStats.HIDDEN) or {}

    local sortedLines = data.lines or {}
    
    -- Separate pinned and unpinned lines, excluding hidden ones
    local pinnedLines = {}
    local unpinnedLines = {}
    
    for _, line in ipairs(sortedLines) do
        -- Skip hidden lines
        if line.editInfo and not line.editInfo.editing and line.editInfo.type and line.editInfo.id and hidden[line.editInfo.type] and hidden[line.editInfo.type][line.editInfo.id] then
            goto continue
        end
        
        -- Separate pinned and unpinned
        if line.editInfo and line.editInfo.type and line.editInfo.id and pinned[line.editInfo.type] and pinned[line.editInfo.type][line.editInfo.id] then
            table.insert(pinnedLines, line)
        else
            table.insert(unpinnedLines, line)
        end
        
        ::continue::
    end
    
    -- Sort each group independently
    local sortFn
    if data.sort == constants.Sort.LABEL_ASC then
        sortFn = function(a, b) return a.label < b.label end
    elseif data.sort == constants.Sort.LABEL_DESC then
        sortFn = function(a, b) return a.label > b.label end
    end
    
    if sortFn then
        table.sort(pinnedLines, sortFn)
        table.sort(unpinnedLines, sortFn)
    end
    
    -- Combine pinned lines at the top, followed by unpinned lines
    sortedLines = {}
    for _, line in ipairs(pinnedLines) do
        line.pinned = true
        table.insert(sortedLines, line)
    end
    for _, line in ipairs(unpinnedLines) do
        table.insert(sortedLines, line)
    end

    -- Sort lines with placement logic if placement is defined
    sortedLines = sortSections(sortedLines, false)

    section = ui.create(section)

    local indent = data.indent and lineIndent or headerIndent
    local lastLinePinned = false
    for i, lineParams in ipairs(sortedLines) do
        local lineType = lineParams.type or constants.LineType.LABELED_VALUE
        local line
        if lineType == constants.LineType.LABELED_VALUE then
            line = Templates.labeledValue({ name = lineParams.id, indent = indent, label = lineParams.label, labelColor = lineParams.labelColor, type = lineParams.type, iconFn = lineParams.icon, valueFn = lineParams.value, tooltipFn = lineParams.tooltip, visibleFn = lineParams.visibleFn, activeFn = lineParams.active, disabledFn = lineParams.disabled, onClick = lineParams.onClick, valueType = lineParams.valueType, })
            if lineParams.editInfo and lineParams.editInfo.editing then
                line.layout.content.pre = Templates.lineEditControls(lineParams.editInfo)
            end
            if lineParams.pinned and configPlayer.tweaks.b_SpellIcons and configPlayer.tweaks.b_PinnedSpellIcons then
                line.layout.content.icon.content:add({
                    type = ui.TYPE.Image,
                    props = {
                        size = v2(8, 8),
                        anchor = v2(1, 0),
                        relativePosition = v2(1, 0),
                        position = v2(-1, -1),
                        resource = BASE.createTexture('textures/MagicWindowExtender/pinned_true.dds'),
                    }
                }) 
            end
        elseif lineType == constants.LineType.CUSTOM then
            line = ui.create {
                name = lineParams.id,
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                },
                content = ui.content {
                    lineParams.layoutFn and lineParams.layoutFn() or {},
                },
                userData = {
                    type = constants.LineType.CUSTOM,
                    layoutFn = lineParams.layoutFn,
                    tooltipFn = lineParams.tooltip,
                    visibleFn = lineParams.visibleFn,
                    activeFn = lineParams.active,
                    disabledFn = lineParams.disabled,
                    onClick = lineParams.onClick,
                    staticLayout = lineParams.staticLayout,
                }
            }
            if lineParams.grow then
                line.layout.props.size = v2(0, lineParams.height or Templates.LINE_HEIGHT)
                line.layout.props.autoSize = false
                line.layout.external = { grow = 1 }
            end
        end
        
        if not data.horizontal then
            if configPlayer.tweaks.b_SeparatePinnedSpells and lastLinePinned and not lineParams.pinned then
                section.layout.content:add({
                    template = Templates.sectionDivider,
                    props = {
                        anchor = v2(0.5, 0),
                        relativePosition = v2(0.5, 0),
                        size = v2(-32, 1),
                        position = v2(0, totalHeight + 3),
                        alpha = 0.5,
                    },
                })
                totalHeight = totalHeight + 8
            end
            line.layout.props.position = v2(0, totalHeight)
        end
        lastLinePinned = lineParams.pinned == true

        line.layout.props.visible = not line.layout.userData.visibleFn or line.layout.userData.visibleFn()
        line.layout.userData.parentSection = section
        if data.horizontal and i ~= 1 and line.layout.props.visible then
            section.layout.content:add(BASE.intervalH(4)) 
        end
        section.layout.content:add(line)
        if line.layout.props.visible then
            visibleLines = visibleLines + 1
            if data.horizontal then
                totalHeight = math.max(totalHeight, lineParams.height or Templates.LINE_HEIGHT)
            else
                totalHeight = totalHeight + (lineParams.height or Templates.LINE_HEIGHT)
            end
        else
            line.layout.props.size = v2(0, 0)
        end

        if not lineParams.noUpdate then
            table.insert(Templates.linesToProcess, line)
        end
    end
    section.layout.userData.visibleLines = visibleLines
    section.layout.props.size = v2(0, totalHeight)
    if visibleLines == 0 and not data.showIfNoLines then
        section.layout.props.size = v2(0, 0)
        section.layout.props.visible = false
    end
    section:update()
    return section
end

local function createBox(data)
    local sortedSections = sortSections(data.sections or {}, true)
    local content = ui.content {}
    local lastVisibleSection = nil
    for i, sectionData in ipairs(sortedSections) do
        local section = createSection(sectionData)
        if section.layout.props.visible then
            if lastVisibleSection and lastVisibleSection.layout.userData.divider.after and section.layout.userData.divider.before then
                local divider = auxUi.deepLayoutCopy(Templates.sectionDivider)
                content:add(divider)
            end
            lastVisibleSection = section
        end
        content:add(section)
    end
    local padding = data.padding or Templates.BOX_INNER_PADDING
    local box = Templates.box(data.id, content, padding, data.border ~= false)
    box.props.size = v2(0, box.userData.totalHeight)
    if data.maxHeightLines and data.maxHeightLines > 0 then
        box.userData.maxHeight = data.maxHeightLines * Templates.LINE_HEIGHT + (box.userData.padding * 2) + (box.userData.borderThickness * 2)
        box.props.size = v2(0, math.min(box.userData.maxHeight, box.userData.totalHeight))
    end
    if data.fixedHeight then
        box.props.size = v2(0, data.fixedHeight)
        box.userData.maxHeight = data.fixedHeight
        box.userData.totalHeight = data.fixedHeight
        box.userData.fixedHeight = true
    end
    box.props.visible = data.showWhenEmpty == true or box.userData.totalHeight > 0

    if data.scrollable then
        local scrollableName = box.name .. '_scrollable'
        box.content.padding.props.position = v2(0, 0)
        box.content.padding.props.size = v2(0, 0)
        box.content = ui.content {
            BASE.scrollable(
                v2(0, 0),
                box.content,
                v2(0, box.userData.contentHeight + box.userData.padding * 2),
                box.userData.padding,
                box.userData.borderThickness,
                Templates.LINE_HEIGHT * 2,
                false,
                function(e) Templates.focusedScrollable = e end,
                function(e) Templates.focusedScrollable = nil end,
                storedScrollPos[scrollableName],
                scrollableName
            )
        }
        box.userData = box.userData or {}
        box.userData.scrollable = true
    end
    return box
end

Templates.remakeBoxes = function(layout, boxIds)
    local mainPane = layout.content.foreground.content.body.content[constants.Panes.MAIN]
    for i, box in ipairs(mainPane.content) do
        if box.layout then
            if boxIds[box.layout.name] then
                auxUi.deepDestroy(box.layout)
                box.layout = createBox(boxIds[box.layout.name])
                box:update()
            end
        end
    end
end

local function createPane(paneId, boxes)
    local sortedBoxes = sortSections(boxes or {}, false)
    local content = ui.content {}
    local lastBoxVisible = false

    for i, boxData in ipairs(sortedBoxes) do
        local box = ui.create(createBox(boxData))

        if lastBoxVisible and box.layout.props.visible then
            content:add(BASE.intervalV(Templates.BOX_OUTER_PADDING))
            lastBoxVisible = false
        end

        if box.layout.props.visible then
            lastBoxVisible = true
        end
        content:add(box)
    end

    return Templates.pane(paneId, content)
end

Templates.magicWindow = function(sections, allowPin, scrollPosList)
    Templates.linesToProcess = {}

    storedScrollPos = scrollPosList or {}

    sections = helpers.deepCopy(sections or {})

    local windowOptions = configPlayer.window

    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size

    local selfRecord = omwself.type.records[omwself.recordId]

    local base = BASE.containerWithHeader(getMagicName(), {
        createPane(constants.Panes.MAIN, sections[constants.Panes.MAIN] or {}),
    })

    base.layer = 'Windows'
    local minWidth = Templates.MIN_INNER_WIDTH + Templates.BORDER_WIDTH_TOTAL + Templates.BOX_OUTER_PADDING * 2
    base.props = {
        position = util.vector2(
            windowOptions.f_MagicWindowX * layerSize.x,
            windowOptions.f_MagicWindowY * layerSize.y
        ),
        size = util.vector2(
            math.max(windowOptions.f_MagicWindowW * layerSize.x, minWidth),
            math.max(windowOptions.f_MagicWindowH * layerSize.y, Templates.MIN_HEIGHT)
        ),
    }

    if allowPin then
        local pinButton = BASE.pinButton(windowOptions.b_MagicWindowPinned, function(isPinned)
            storage.playerSection('Settings/MagicWindowExtender/2_WindowOptions'):set('b_MagicWindowPinned', isPinned)
        end)
        pinButton.layout.props.anchor = v2(1, 0)
        pinButton.layout.props.relativePosition = v2(1, 0)
        base.content:add(pinButton)
    end

    return base
end

return Templates