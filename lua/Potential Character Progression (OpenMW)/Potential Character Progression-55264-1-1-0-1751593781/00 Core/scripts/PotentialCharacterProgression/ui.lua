-- All code pertaining to this mod's level menu
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local Player = types.Player

local info = require('scripts.PotentialCharacterProgression.info')
local myui = require('scripts.' .. info.name .. '.myui')

local L = core.l10n(info.name)

local v2 = util.vector2

local function contains(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end

local function capital(text)
    return text:gsub('^%l', string.upper)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Mod settings

local modSettings = {
    basic = storage.playerSection('SettingsPlayer' .. info.name .. 'Basic'),
    balance = storage.playerSection('SettingsPlayer' .. info.name .. 'Balance'),
    debug = storage.playerSection('SettingsPlayer' .. info.name .. 'Debug')
}

local attributeCapMethod
local sharedAttributeCap
local favoredAttributeCap
local unfavoredAttributeCap
local uniqueAttributeCaps
local debugMode
local expCostTable

-- Game settings

local ascendText = core.getGMST('sLevelUpMenu1')
local levelUpTextDefault = core.getGMST('Level_Up_Default')
local okayText = core.getGMST('sOK')
local levelText = core.getGMST('sLevel')
local levelProgressText = core.getGMST('sLevelProgress')
local skillUpsPerLevel = core.getGMST('iLevelupTotal')

-- Data

local playerClassRecord

-- Menu constants

local rowHeight = 23
local maxCoins = 30

-- Menu resources

local resources = {
    buttonDec = ui.texture{path = 'icons/menu_number_dec.dds'},
    buttonInc = ui.texture{path = 'icons/menu_number_inc.dds'},
    classArt = ui.texture{path = 'textures/levelup/acrobat.dds'},
    coin = ui.texture{path = 'icons/tx_goldicon.dds'},
    barColor = ui.texture{path = 'textures/menu_bar_gray.dds'},
}

for _, attributeRecord in ipairs(core.stats.Attribute.records) do
    resources[attributeRecord.id] = ui.texture{path = attributeRecord.icon}
end

-- Menu variables

local uiAttributes = {}
local uiExperience = 0
local uiConfirmed = true
local uiDistributed = false

-- Menu elements

local menu

local expFlex

local uiColumns = {}

local potentialFlex

local autoButton
local confirmButton

local tooltip







-- Pre-defined layouts -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Tooltip layouts/functions

local tooltipSizes = {
    strength = v2(tonumber(L('TooltipStrengthSizeX')), tonumber(L('TooltipStrengthSizeY'))),
    intelligence = v2(tonumber(L('TooltipIntelligenceSizeX')), tonumber(L('TooltipIntelligenceSizeY'))),
    willpower = v2(tonumber(L('TooltipWillpowerSizeX')), tonumber(L('TooltipWillpowerSizeY'))),
    agility = v2(tonumber(L('TooltipAgilitySizeX')), tonumber(L('TooltipAgilitySizeY'))),
    speed = v2(tonumber(L('TooltipSpeedSizeX')), tonumber(L('TooltipSpeedSizeY'))),
    endurance = v2(tonumber(L('TooltipEnduranceSizeX')), tonumber(L('TooltipEnduranceSizeY'))),
    personality = v2(tonumber(L('TooltipPersonalitySizeX')), tonumber(L('TooltipPersonalitySizeY'))),
    luck = v2(tonumber(L('TooltipLuckSizeX')), tonumber(L('TooltipLuckSizeY')))
}

local tooltipLayout = {
    name = 'tooltip',
    layer = 'Popup',
    type = ui.TYPE.Container,
    template = I.MWUI.templates.boxSolid,
    props = {anchor = v2(0.5, 0), visible = false},
    content = ui.content {
        {
            name = 'padding',
            type = ui.TYPE.Container,
            template = myui.padding(6,6),
            props = {}
        }
    }
}

local attributeTooltipFlex = {
    name = 'mainFlex',
    type = ui.TYPE.Flex,
    props = {},
    content = ui.content {
        {
            name = 'headingFlex',
            type = ui.TYPE.Flex,
            props = {horizontal = true, arrange = ui.ALIGNMENT.Center},
            content = ui.content {
                {
                    name = 'icon',
                    type = ui.TYPE.Image,
                    props = {resource = resources.strength, size = v2(32, 32)}
                },
                myui.padWidget(8,0),
                {
                    name = 'name',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = '', textColor = myui.textColors.positive}
                }
            }
        },
        myui.padWidget(0, 8),
        {
            name = 'description',
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = '', wordWrap = true, autoSize = false, size = v2(0,0)}
        }
    }
}

local expTooltipFlex = {
    name = 'mainFlex',
    type = ui.TYPE.Flex,
    props = {horizontal = true},
    content = ui.content {
        {
            name = 'coin',
            type = ui.TYPE.Image,
            props = {resource = resources.coin, size = v2(16,16)}
        },
        {
            name = 'text',
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = L('MenuCount') .. uiExperience}
        }
    }
}

local levelTooltipFlex = {
    name = 'mainFlex',
    type = ui.TYPE.Flex,
    props = {arrange = ui.ALIGNMENT.Center},
    content = ui.content {
        {
            name = 'text',
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = levelProgressText, textColor = myui.textColors.positive}
        }
    }
}

local function createAttributeTooltip(attributeId)
    attributeTooltipFlex.content.headingFlex.content.name.props.text = core.stats.Attribute.record(attributeId).name
    attributeTooltipFlex.content.description.props.text = core.stats.Attribute.record(attributeId).description
    if tooltipSizes[attributeId] then
        attributeTooltipFlex.content.description.props.size = tooltipSizes[attributeId]
    else
        attributeTooltipFlex.content.description.props.size = v2(400, 64)
    end
    attributeTooltipFlex.content.headingFlex.content.icon.props.resource = resources[attributeId]
    tooltip.layout.content.padding.content = ui.content{attributeTooltipFlex}
    tooltip.layout.props.visible = true
end

local function createExpTooltip()
    expTooltipFlex.content.text.props.text = L('MenuCount') .. uiExperience
    tooltip.layout.content.padding.content = ui.content{expTooltipFlex}
    tooltip.layout.props.visible = true
end

local function createLevelTooltip()
    tooltip.layout.content.padding.content = ui.content{levelTooltipFlex}
    tooltip.layout.props.visible = true
end

local function moveTooltip(mouseEvent, data)
    tooltip.layout.props.anchor = v2(mouseEvent.position.x / ui.screenSize().x, 0)
    tooltip.layout.props.position = mouseEvent.position + v2(0, 35)
    tooltip:update()
end

local function destroyTooltip()
    tooltip.layout.props.visible = false
    tooltip:update()
end

-- Layouts containing level-up art and text

local levelUpArt = {
    name = 'levelUpArt',
    type = ui.TYPE.Image,
    props = { resource = resources.classArt, size = v2(256, 128) }
}

local levelUpLayout = {
    name = 'padFlex',
    type = ui.TYPE.Flex,
    props = {horizontal = true},
    content = ui.content {
        {
            name = 'levelFlex',
            type = ui.TYPE.Flex,
            props = {arrange = ui.ALIGNMENT.Center},
            content = ui.content {
                {
                    name = 'artOutline',
                    type = ui.TYPE.Container,
                    template = I.MWUI.templates.box,
                    content = ui.content {
                        {
                            name = 'artPadding',
                            type = ui.TYPE.Container,
                            template = myui.padding(2,2),
                            content = ui.content {
                                levelUpArt
                            }
                        }
                    },
                    props = {}
                },
                myui.padWidget(0,14),
                {
                    name = 'ascendText',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = ascendText}
                },
                myui.padWidget(0,14),
                {
                    name = 'levelUpText',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = levelUpTextDefault, wordWrap = true, autoSize = false, size = v2(272, 128)}
                }
            }
        },
        myui.padWidget(10,0)
    }
}

-- Current level info
local levelInfoFlex = {
    name = 'levelInfoFlex',
    type = ui.TYPE.Flex,
    props = {horizontal = true, arrange = ui.ALIGNMENT.Center},
    content = ui.content {
        {
            name = 'textFlex',
            type = ui.TYPE.Flex,
            props = {horizontal = true, size = v2(70, 16), autoSize = false},
            content = ui.content {
                {
                    name = 'text',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = levelText, textColor = myui.textColors.positive}
                },
                myui.padWidget(8,0),
                {
                    name = 'value',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = tostring(Player.stats.level(self).current)}
                }
            }
        },
        myui.padWidget(10,0),
        {
            name = 'progressBar',
            type = ui.TYPE.Container,
            template = I.MWUI.templates.box,
            props = {},
            events = {
                focusGain = async:callback(function()
                    createLevelTooltip()
                end),
                focusLoss = async:callback(function()
                    destroyTooltip()
                end),
                mouseMove = async:callback(function(mouseEvent, data)
                    moveTooltip(mouseEvent, data)
                end)
            },
            content = ui.content {
                {
                    name = 'color',
                    type = ui.TYPE.Image,
                    props = {resource = resources.barColor, color = myui.textColors.health, size = v2(130, 16)}
                },
                {
                    name = 'progress',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = '0/0', textAlignH = ui.ALIGNMENT.Center, textAlignV = ui.ALIGNMENT.Center, autoSize = false, size = v2(130, 16), position = v2(0, -2)}
                }
            }
        }
    }
}

local rowsFlex = {
    name = 'rowsFlex',
    type = ui.TYPE.Flex,
    props = {horizontal = true},
}

local actionsFlex = {
    name = 'actionsFlex',
    type = ui.TYPE.Flex,
    props = {horizontal = true, arrange = ui.ALIGNMENT.Center}
}

-- Menu main layout
local menuLayout = {
    layer = 'Windows',
    name = 'menuContainer',
    type = ui.TYPE.Container,
    template = I.MWUI.templates.boxTransparentThick,
    props = {anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5)},
    content = ui.content {
        {
            name = 'padding',
            type = ui.TYPE.Container,
            template = myui.padding(8,8),
            content = ui.content {
                {
                    name = 'mainFlex',
                    type = ui.TYPE.Flex,
                    props = {horizontal = true},
                    content = ui.content {
                        {},
                        {
                            name = 'interactiveFlex',
                            type = ui.TYPE.Flex,
                            props = {arrange = ui.ALIGNMENT.End},
                            content = ui.content {
                                rowsFlex,
                                myui.padWidget(0,15),
                                {},
                                myui.padWidget(0,15),
                                {
                                    name = 'unusedText',
                                    type = ui.TYPE.Text,
                                    template = I.MWUI.templates.textNormal,
                                    props = {text = L('MenuUnused'), wordWrap = true, autoSize = false, size = v2(214, 32)}
                                },
                                myui.padWidget(0,12),
                                actionsFlex
                            }
                        }
                    }
                }
            }
        }
    }
}





-- Update/calculation functions -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Takes favored/over booleans, returns cost of attribute increase
local function expCost(isFavored, isOver)
    if debugMode then
        return 0
    end

    local favoredKey = 'notFavored'
    local overKey = 'notOver'
    if isFavored then
        favoredKey = 'favored'
    end
    if isOver then
        overKey = 'over'
    end
    return expCostTable[favoredKey][overKey]
end

-- Change and update EXP flex, don't bother if debug mode is enabled
local function updateExperience(prevExperience)
    if not debugMode then
        prevExperience = math.min(math.max(prevExperience, uiExperience), maxCoins)
        local coinCount = uiExperience
        if coinCount > maxCoins then
            coinCount = 1
            expFlex.layout.content.coinContainer.content.count.props.alpha = 1
            expFlex.layout.content.coinContainer.content.count.props.text = L('MenuCount') .. uiExperience
        else
            expFlex.layout.content.coinContainer.content.count.props.alpha = 0
        end
        for i=1, prevExperience, 1 do
            if i > coinCount then
                expFlex.layout.content.coinContainer.content['coin' .. i].props.alpha = 0
            else
                expFlex.layout.content.coinContainer.content['coin' .. i].props.alpha = 1
            end
        end
        expFlex:update()
    end
end

-- Update specified columns
local function updateAttributeRows(changed)
    local map = {
        exp = uiColumns.attributeExp,
        dec = uiColumns.attributeDecs,
        num = uiColumns.attributeNums,
        inc = uiColumns.attributeIncs,
        pot = potentialFlex
    }
    for k, _ in pairs(changed) do
        map[k]:update()
    end
end

-- Modify content of attribute row, return list of changed columns
local function modifyAttributeRow(attributeId, isOrigin)
    local changed = {}
    local attribute = uiAttributes[attributeId]
    -- If this row caused its own change
    if isOrigin then
        -- Change value, experience
        uiColumns.attributeNums.layout.content[attributeId].content[attributeId].props.text = tostring(attribute.base + attribute.ups)
        uiColumns.attributeExp.layout.content[attributeId].content[attributeId].props.alpha = 0
        if attribute.experience > 0 then
            uiColumns.attributeExp.layout.content[attributeId].content[attributeId].content.value.props.text = L('MenuCount') .. attribute.experience
            uiColumns.attributeExp.layout.content[attributeId].content[attributeId].props.alpha = 1
        end
        changed.num = true
        changed.exp = true

        -- Color attribute potential, don't bother if debug mode is enabled or base is already above cap
        if not (debugMode or (attribute.cap > 0 and attribute.base > attribute.cap)) then
            local diff = math.floor(attribute.potential) - attribute.ups

            local potentialColor = myui.interactiveTextColors.normal.default
            if diff < 0 then
                potentialColor = myui.textColors.negative
            elseif diff >= 1 then
                potentialColor = myui.interactiveTextColors.active.default
            end

            if potentialColor ~= uiColumns.attributePotsInt.content[attributeId].content[attributeId].props.textColor then
                uiColumns.attributePotsInt.content[attributeId].content[attributeId].props.textColor = potentialColor
                uiColumns.attributePotsFrac.content[attributeId].content[attributeId].props.textColor = potentialColor
                changed.pot = true
            end
        end

        -- Enable/disable attribute decrement button
        if (attribute.base + attribute.ups <= 0 or (not debugMode and attribute.ups <= 0)) and not uiColumns.attributeDecs.layout.content[attributeId].content[attributeId].userData.isDisabled then
            myui.disableWidget(uiColumns.attributeDecs.layout.content[attributeId].content[attributeId])
            changed.dec = true
        elseif ((debugMode == true and attribute.base + attribute.ups > 0) or attribute.ups > 0) and uiColumns.attributeDecs.layout.content[attributeId].content[attributeId].userData.isDisabled then
            myui.enableWidget(uiColumns.attributeDecs.layout.content[attributeId].content[attributeId])
            changed.dec = true
        end
    end

    -- Enable/disable attribute increment button
    local cost = expCost(attribute.isFavored, attribute.ups + 1 > attribute.potential)
    if (cost > uiExperience or (attribute.cap > 0 and attribute.base + attribute.ups + 1 > attribute.cap)) and not uiColumns.attributeIncs.layout.content[attributeId].content[attributeId].userData.isDisabled then
        myui.disableWidget(uiColumns.attributeIncs.layout.content[attributeId].content[attributeId])
        changed.inc = true
    elseif cost <= uiExperience and (attribute.cap == 0 or attribute.base + attribute.ups + 1 <= attribute.cap) and uiColumns.attributeIncs.layout.content[attributeId].content[attributeId].userData.isDisabled then
        myui.enableWidget(uiColumns.attributeIncs.layout.content[attributeId].content[attributeId])
        changed.inc = true
    end
    return changed
end

-- Increment/decrement button functions
--local function modUiAttribute(data)
local function modUiAttribute(attributeId, value)
    local prevExperience = uiExperience
    attribute = uiAttributes[attributeId]
    attribute.ups = attribute.ups + value
    local cost = value * expCost(attribute.isFavored, attribute.ups - math.min(value, 0) > attribute.potential)
    uiExperience = uiExperience - cost 
    attribute.experience = attribute.experience + cost
    local changed = modifyAttributeRow(attributeId, true)
    for iterid, _ in pairs(uiAttributes) do
        if iterid ~= attributeId then
            if modifyAttributeRow(iterid).inc then
                changed.inc = true
            end
        end
    end
    updateAttributeRows(changed)
    updateExperience(prevExperience)
    uiDistributed = false
end

-- Clear all attribute increases and distributed experience, return list of cleared attributes
local function clearAttributeRows()
    local sum = 0
    local cleared = {}
    for attributeId, attribute in pairs(uiAttributes) do
        if attribute.ups > 0 then
            sum = sum + attribute.experience
            attribute.experience = 0
            attribute.ups = 0
            cleared[attributeId] = true
        end
    end
    uiExperience = uiExperience + sum
    return cleared
end

-- Automatically distribute experience to attributes with potential
local function autoDistribute(data)
    local touched = clearAttributeRows()
    local prevExperience = uiExperience
    if not uiDistributed then
        uiDistributed = true
        local isSpent = false
        while isSpent == false do
            isSpent = true
            for attributeId, attribute in pairs(uiAttributes) do
                local cost = expCost(attribute.isFavored, false)
                if attribute.ups + 1 <= attribute.potential and uiExperience >= cost then
                    touched[attributeId] = true
                    attribute.ups = attribute.ups + 1
                    attribute.experience = attribute.experience + cost
                    uiExperience = uiExperience - cost
                    isSpent = false
                end
            end
        end
    else
        uiDistributed = false
    end
    if next(touched) ~= nil then
        local changed = {}
        for attributeId, attribute in pairs(uiAttributes) do
            for k, _ in pairs(modifyAttributeRow(attributeId, touched[attributeId])) do
                changed[k] = true
            end
        end
        updateAttributeRows(changed)
        updateExperience(prevExperience)
    end
end







-- Menu creation/destruction -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Close the menu, forwarding changes to the main script
local function confirmMenu()
    -- Prevents duplicate confirm events if the player clicks very fast
    if uiConfirmed then return end
    uiConfirmed = true
    self:sendEvent(info.name .. 'FinishMenu', {uiAttributes = uiAttributes, uiExperience = uiExperience, debugMode = debugMode})
end

local function hideMenu()
    menu:destroy()
    tooltip:destroy()
    tooltipLayout.props.visible = false
end

-- Use the same height value for every row, special handling to cut off button textures
local function sizeRow(layout, size)
    local properties = {horizontal = true, arrange = ui.ALIGNMENT.Center}
    local padHeight = rowHeight
    if size then
        properties = {autoSize = false, size = v2(size.x, rowHeight)}
        padHeight = (rowHeight - size.y) * 0.5
    end
    local rowLayout = {
        name = layout.name,
        type = ui.TYPE.Flex,
        props = properties,
        content = ui.content {
            myui.padWidget(0, padHeight),
            layout
        }
    }
    return rowLayout
end

-- UI creation function called from the main script
local function createMenu(levelUpData, attributeData, experience)
    uiExperience = experience

    uiConfirmed = false
    uiDistributed = false

    -- Can't read this when the script first loads if the player doesn't have a class yet
    -- Also accounts for the player changing their class mid-session with console commands
    playerClassRecord = Player.classes.record(Player.record(self).class)

    -- Set these at menu creation so settings can update mid-session

    attributeCapMethod = modSettings.basic:get('AttributeCapMethod')
    sharedAttributeCap = modSettings.basic:get('SharedAttributeCap')
    favoredAttributeCap = modSettings.basic:get('FavoredAttributeCap')
    unfavoredAttributeCap = modSettings.basic:get('UnfavoredAttributeCap')
    uniqueAttributeCaps = modSettings.basic:get('UniqueAttributeCapValues')

    debugMode = modSettings.debug:get('DebugMode')

    expCostTable = {
        notFavored = {
            notOver = modSettings.balance:get('ExperienceCost'),
            over = modSettings.balance:get('ExperienceCostOver')
        },
        favored = {
            notOver = modSettings.balance:get('ExperienceCostFavored'),
            over = modSettings.balance:get('ExperienceCostFavoredOver')
        }
    }

    uiAttributes = {}

    -- Create the interactive parts of the UI

    -- Create UI columns
    uiColumns = {
        attributeExp = ui.create{name = 'attributeExp', type = ui.TYPE.Flex, content = ui.content{myui.padWidget(44,0)}},
        attributeNames = {name = 'attributeNames', type = ui.TYPE.Flex, content = ui.content{}},
        attributeDecs = ui.create{name = 'attributeDecs', type = ui.TYPE.Flex, content = ui.content{}},
        attributeNums = ui.create{name = 'attributeNums', type = ui.TYPE.Flex, props = {arrange = ui.ALIGNMENT.End }, content = ui.content{myui.padWidget(32,0)}},
        attributeIncs = ui.create{name = 'attributeIncs', type = ui.TYPE.Flex, content = ui.content{}},
        attributePotsInt = {name = 'attributePotsInt', type = ui.TYPE.Flex, props = {arrange = ui.ALIGNMENT.End}, content = ui.content{}},
        attributePotsFrac = {name = 'attributePotsFrac', type = ui.TYPE.Flex, content = ui.content{}}
    }

    -- Iterate over attributes to populate UI columns
    for i, attributeRecord in ipairs(core.stats.Attribute.records) do
        uiAttributes[attributeRecord.id] = {}
        local attributeId = attributeRecord.id
        local attribute = uiAttributes[attributeId]

        attribute.isFavored = contains(playerClassRecord.attributes, attributeId)

        if attributeCapMethod == 'SharedCap' then
            attribute.cap = sharedAttributeCap
        elseif attributeCapMethod == 'FavoredCap' then
            if attribute.isFavored then
                attribute.cap = favoredAttributeCap
            else
                attribute.cap = unfavoredAttributeCap
            end
        elseif attributeCapMethod == 'UniqueCap' then
            attribute.cap = uniqueAttributeCaps[attributeId]
        else
            attribute.cap = 100
        end

        attribute.experience = 0
        attribute.base = Player.stats.attributes[attributeId](self).base
        attribute.potential = attributeData[attributeRecord.id].potential
        if attribute.cap > 0 then
            attribute.potential = math.min(attribute.potential, attribute.cap - attribute.base)
        end
        attribute.ups = 0

        -- EXP spent indicator
        uiColumns.attributeExp.layout.content:add(sizeRow{
            name = attributeId,
            type = ui.TYPE.Flex,
            props = {horizontal = true, alpha = 0.0},
            content = ui.content {
                {
                    name = 'coin',
                    type = ui.TYPE.Image,
                    props = {resource = resources.coin, size = v2(16, 16)}
                },
                {
                    name = 'value',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = L('MenuCount') .. '0'}
                }
            }
        })

        -- Attribute name
        local nameLayout = {
            name = attributeId,
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = core.getGMST('sAttribute' .. capital(attributeId))},
            events = {
            focusGain = async:callback(function()
                createAttributeTooltip(attributeId) 
            end),
            focusLoss = async:callback(function() 
                destroyTooltip() 
            end),
            mouseMove = async:callback(function(mouseEvent, data) 
                moveTooltip(mouseEvent, data) 
            end)
            }
        }
        if attribute.isFavored then
            nameLayout.props.textColor = myui.textColors.positive
        end
        uiColumns.attributeNames.content:add{name = 'nameflex', type = ui.TYPE.Flex, props = {horizontal = true, arrange = ui.ALIGNMENT.Center}, content = ui.content { myui.padWidget(6,rowHeight), nameLayout, myui.padWidget(10,rowHeight)}}

        -- Decrement button
        local decLayout = myui.createImageButton(uiColumns.attributeDecs, attributeId, {resource = resources.buttonDec, anchor = v2(0.5, 0.5), size = v2(32, 32)}, modUiAttribute, {attributeId, -1})
        uiColumns.attributeDecs.layout.content:add(sizeRow(decLayout, v2(10, 18)))

        -- Increment button
        local incLayout = myui.createImageButton(uiColumns.attributeIncs, attributeId, {resource = resources.buttonInc, anchor = v2(0.5, 0.5), size = v2(32, 32)}, modUiAttribute, {attributeId, 1})
        uiColumns.attributeIncs.layout.content:add(sizeRow(incLayout, v2(10, 18)))

        -- Attribute value
        local numLayout = {
            name = attributeId,
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = tostring(attribute.base)}
        }
        uiColumns.attributeNums.layout.content:add{name = attributeId, type = ui.TYPE.Flex, props = {horizontal = true, arrange = ui.ALIGNMENT.Center}, content = ui.content {myui.padWidget(4, rowHeight), numLayout, myui.padWidget(4, rowHeight)}}

        local potString = tostring(attribute.potential + attribute.base)

        -- Potential whole number, split to align at decimal point
        local potInt = potString:sub(potString:find('^%d+'))
        uiColumns.attributePotsInt.content:add(sizeRow{
            name = attributeId,
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = potInt}
        })

        -- Potential decimal, split to align at decimal point
        local potFrac = potString:gsub('^%d+', ''):sub(1, 5)
        uiColumns.attributePotsFrac.content:add(sizeRow{
            name = attributeId,
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = potFrac, textColor = potentialColor}
        })

        modifyAttributeRow(attributeId, true)
    end

    -- Remaining EXP indicator
    expFlex = ui.create{
        name = 'expFlex',
        type = ui.TYPE.Flex,
        props = {horizontal = true},
        events = {
            focusGain = async:callback(function()
                if uiExperience <= maxCoins and uiExperience > 0 then
                    createExpTooltip()
                end
            end),
            focusLoss = async:callback(function()
                if uiExperience <= maxCoins and uiExperience > 0 then
                    destroyTooltip()
                end
            end),
            mouseMove = async:callback(function(mouseEvent, data)
                if uiExperience <= maxCoins and uiExperience > 0 then
                    moveTooltip(mouseEvent, data)
                end
            end)
        },
        content = ui.content {
            {
                name = 'expText',
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {text = L('MenuExperience')}
            },
            {
                name = 'coinContainer',
                type = ui.TYPE.Container,
                props = {size = v2(140, 16)},
                content = ui.content {
                    {
                        name = 'count',
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {text = L('MenuCount') .. uiExperience, position = v2(16, 0), alpha = 0}
                    }
                }
            }
        }
    }

    -- Visible coins equal to maxCoins, after which just display a number
    local coinCount = math.min(uiExperience, maxCoins)
    local offset = math.min(math.floor(120 / (coinCount - 1)), 16)
    for i=1, coinCount, 1 do
        expFlex.layout.content.coinContainer.content:add{
            name = 'coin' .. i,
            type = ui.TYPE.Image,
            props = {resource = resources.coin, size = v2(16, 16), position = v2((i-1) * offset, 0), alpha = 1}
        }
    end

    -- All columns, except those pertaining to potential
    local attributeFlex = {
        name = 'attributeFlex',
        type = ui.TYPE.Flex,
        props = {},
        content = ui.content {
            expFlex,
            myui.padWidget(0,12),
            {
                name = 'rows',
                type = ui.TYPE.Flex,
                props = {horizontal = true},
                content = ui.content {
                    uiColumns.attributeExp,
                    uiColumns.attributeNames,
                    uiColumns.attributeDecs,
                    uiColumns.attributeNums,
                    uiColumns.attributeIncs
                }
            }
        }
    }

    -- Column(s) pertaining to potential
    potentialFlex = ui.create{
        name = 'potentialFlex',
        type = ui.TYPE.Flex,
        props = {arrange = ui.ALIGNMENT.Center},
        content = ui.content {
            {
                name = 'potentialLabel',
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {text = L('MenuPotential')}
            },
            myui.padWidget(0,12),
            {
                name = 'rows',
                type = ui.TYPE.Flex,
                props = {horizontal = true},
                content = ui.content {
                    uiColumns.attributePotsInt,
                    uiColumns.attributePotsFrac
                }
            }
        }
    }

    -- Confirm and auto-distribute buttons
    confirmButton = ui.create{}
    autoButton = ui.create{}
    confirmButtonSize = v2(tonumber(L('ButtonConfirmSizeX')), tonumber(L('ButtonConfirmSizeY')))
    autoButtonSize = v2(tonumber(L('ButtonAutoSizeX')), tonumber(L('ButtonAutoSizeY')))
    confirmButton.layout = myui.createTextButton(confirmButton, okayText, 'normal', 'confirmButton', {}, confirmButtonSize, confirmMenu)
    autoButton.layout = myui.createTextButton(autoButton, L('MenuDistribute'), 'normal', 'autoButton', {}, autoButtonSize, autoDistribute)
    if debugMode then
        autoButton.layout.props.visible = false
    end

    updateExperience(uiExperience)  
    updateAttributeRows{dec = true, num = true, inc = true, pot = true}

    autoButton:update()
    confirmButton:update()

    local progress = Player.stats.level(self).progress
    levelInfoFlex.content.progressBar.content.progress.props.text = progress .. '/' .. skillUpsPerLevel
    levelInfoFlex.content.progressBar.content.color.props.size = v2(130 * math.min(progress / skillUpsPerLevel, 1), 16)
    levelInfoFlex.content.textFlex.content.value.props.text = tostring(Player.stats.level(self).current)

    -- Show level-up art and text if player has leveled up
    if levelUpData then
        menuLayout.content.padding.content.mainFlex.content.interactiveFlex.content[3] = {}
        levelUpLayout.content.levelFlex.content.ascendText.props.text = ascendText .. levelUpData.level
        local levelUpText = core.getGMST('Level_Up_Level' .. levelUpData.level)
        if levelUpText ~= nil then
            levelUpLayout.content.levelFlex.content.levelUpText.props.text = levelUpText
        else
            levelUpLayout.content.levelFlex.content.levelUpText.props.text = levelUpTextDefault
        end
        resources.classArt = ui.texture{path = 'textures/levelup/' .. levelUpData.class .. '.dds'}
        levelUpArt.props.resource = resources.classArt
        menuLayout.content.padding.content.mainFlex.content[1] = levelUpLayout
    else
        menuLayout.content.padding.content.mainFlex.content.interactiveFlex.content[3] = levelInfoFlex
        menuLayout.content.padding.content.mainFlex.content[1] = {}
    end

    rowsFlex.content = ui.content {attributeFlex, potentialFlex}
    actionsFlex.content = ui.content {autoButton, myui.padWidget(4, 0), confirmButton}

    -- Create the menu
    menu = ui.create(menuLayout)

    -- Create the attribute tooltip
    tooltip = ui.create(tooltipLayout)
end

return {
    createMenu = createMenu,
    hideMenu = hideMenu
}