local ui = require('openmw.ui')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local self = require('openmw.self')
local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt
-- local mouse = require('scripts.spellsBookmark.lib.myUtils').mouse
local g = require('scripts.inventoryManager.myLib')


-- local markup = require('openmw.markup')

local Res = ui.screenSize()
local Reshw = Res.x / 2
local Reshh = Res.y / 2
local anchorX
local PADDING = 12

local toolTip = {
        ---@type ui.Element|{}
        element = {},
        spellID = nil,
}
local function estimateTextWidth(text, min)
        -- print('text = ', text, ' len:', #text)
        -- return #text * 7
        return math.max(#text * 6, min)
end


local maxWidths = {
        name = 0,
        magnitude = 0,
        duration = 0,
        area = 0,
        range = 0
}



-- local enchantmentTypes = {
--         'CastOnce',
--         'CastOnStrike',
--         'CastOnUse',
--         'ConstantEffect',
-- }
local enchantmentTypes = {
        'Once',
        'On Strike',
        'On Use',
        'Constant Effect',
}

local spellRange = {
        [0] = 'Self',
        [1] = 'Touch',
        [2] = 'Target',
}

local affectedNames = {
        ['Fortify Attribute'] = 'Fortify',
        ['Restore Attribute'] = 'Restore',
        ['Damage Attribute'] = 'Damage',
        ['Absorb Attribute'] = 'Absorb',
        ['Drain Attribute'] = 'Drain',
        ['Fortify Skill'] = 'Fortify',
        ['Restore Skill'] = 'Restore',
        ['Drain Skill'] = 'Drain',
}

local affectedAttrSkill = {
        ['agility'] = 'Agility',
        ['endurance'] = 'Endurance',
        ['intelligence'] = 'Intelligence',
        ['luck'] = 'Luck',
        ['personality'] = 'Personality',
        ['speed'] = 'Speed',
        ['strength'] = 'Strength',
        ['willpower'] = 'Willpower',
        ['longblade'] = 'Longblade',
        ['enchant'] = 'Enchant',
        ['destruction'] = 'Destruction',
        ['alteration'] = 'Alteration',
        ['illusion'] = 'Illusion',
        ['conjuration'] = 'Conjuration',
        ['mysticism'] = 'Mysticism',
        ['restoration'] = 'Restoration',
        ['alchemy'] = 'Alchemy',
        ['unarmored'] = 'Unarmored',
        ['block'] = 'Block',
        ['armorer'] = 'Armorer',
        ['mediumarmor'] = 'Mediumarmor',
        ['heavyarmor'] = 'Heavyarmor',
        ['bluntweapon'] = 'Bluntweapon',
        ['axe'] = 'Axe',
        ['spear'] = 'Spear',
        ['athletics'] = 'Athletics',
        ['security'] = 'Security',
        ['sneak'] = 'Sneak',
        ['lightarmor'] = 'Lightarmor',
        ['shortblade'] = 'Shortblade',
        ['marksman'] = 'Marksman',
        ['mercantile'] = 'Mercantile',
        ['speechcraft'] = 'Speechcraft',
        ['acrobatics'] = 'Acrobatics',
        ['handtohand'] = 'Handtohand',

}


local maxWidths = {
        name = 0,
        magnitude = 0,
        duration = 0,
        area = 0,
        range = 0
}

local affectedThing
local name
local mag
local duration
local area
local range

local function createTTText(text, width)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,

                props = {
                        size = util.vector2(width + g.sizes.TOOLTIP_TEXT_SIZE, 20)
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = text,
                                        textSize = g.sizes.TOOLTIP_TEXT_SIZE,

                                        -- textSize = 12,

                                }
                        }
                }
        }
end


---@param info MagicEffectWithParams
local function getEffectInfo(info)
        affectedThing = info.affectedAttribute or info.affectedSkill
        name = affectedThing and
            (affectedNames[info.effect.name] .. ' ' .. affectedAttrSkill[affectedThing]) or info.effect.name

        mag = info.magnitudeMin == info.magnitudeMax
            and info.magnitudeMax .. 'p'
            or info.magnitudeMin .. '-' .. info.magnitudeMax .. 'p'

        duration = info.duration .. 's'
        area = (info.area ~= 0) and (info.area .. 'f') or ''
        range = spellRange[info.range]
end

---@param effects MagicEffectWithParams[]
local function getEffectsTexts(effects)
        local effectsTextsList = {}
        for i, _ in pairs(maxWidths) do
                maxWidths[i] = 0
        end

        for _, info in pairs(effects) do
                getEffectInfo(info)
                maxWidths.name = math.max(maxWidths.name, estimateTextWidth(name, 165))
                maxWidths.magnitude = math.max(maxWidths.magnitude, estimateTextWidth(mag, 46))
                maxWidths.duration = math.max(maxWidths.duration, estimateTextWidth(duration, 46))
                maxWidths.area = area ~= '' and math.max(maxWidths.area, estimateTextWidth(area, 30)) or 0
                maxWidths.range = math.max(maxWidths.range, estimateTextWidth(range, 0))
        end

        for _, info in pairs(effects) do
                getEffectInfo(info)

                local textLayout = {
                        -- template = I.MWUI.templates.borders,
                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                        },
                        content = ui.content {
                                -- Icon
                                {
                                        type = ui.TYPE.Image,
                                        props = {
                                                -- anchor = util.vector2(0.5, 0.5),
                                                size = util.vector2(13, 13),
                                                resource = ui.texture { path = info.effect.icon }
                                        }
                                },
                                g.gui.makeInt(10, 0),

                                createTTText(name, maxWidths.name),
                                createTTText(mag, maxWidths.magnitude),
                                createTTText(duration, maxWidths.duration),
                                createTTText(area, maxWidths.area),
                                createTTText(range, maxWidths.range),
                        }
                }
                table.insert(effectsTextsList, textLayout)
        end

        return effectsTextsList
end


toolTip.currentId = nil
local currentThing
local textFormat
local valueFormat
local allTexts
local weight
---@param thing GameObject
toolTip.showToolTip = function(thing)
        if not toolTip.currentId then
                return
        end
        valueFormat = {}
        allTexts = {}
        textFormat = ''

        local record = thing.type.record(thing)

        ---@type ItemData
        local data = thing.type.itemData(thing)

        if record.chopMaxDamage then
                -- table.insert(allTexts, '------------------------')
                table.insert(allTexts, '')

                table.insert(allTexts, 'Chop:       %d - %d')
                table.insert(valueFormat, record.chopMinDamage)
                table.insert(valueFormat, record.chopMaxDamage)

                table.insert(allTexts, 'Slash:       %d - %d')
                table.insert(valueFormat, record.slashMinDamage)
                table.insert(valueFormat, record.slashMaxDamage)

                table.insert(allTexts, 'Thrust:      %d - %d')
                table.insert(valueFormat, record.thrustMinDamage)
                table.insert(valueFormat, record.thrustMaxDamage)

                table.insert(allTexts, 'Range:      %.2f ft')
                table.insert(valueFormat, record.reach * 6)
                table.insert(allTexts, 'Speed:      %.2f')
                table.insert(valueFormat, record.speed)
                -- table.insert(allTexts, '------------------------')
                table.insert(allTexts, '')
        end

        if record.baseArmor then
                table.insert(allTexts, 'Rating:      %-10d')
                table.insert(valueFormat, record.baseArmor)
        end

        if data.condition then
                table.insert(allTexts, 'Condition:   %d / %d')
                table.insert(valueFormat, data.condition)
                local max = record.maxCondition or record.health or record.duration
                table.insert(valueFormat, max)
        end

        if record.text then
                local newText = string.sub(record.text, 1, 700)
                newText = string.gsub(newText, "<.->", "")
                newText = newText:gsub('([.,]) ', '%1\n')
                table.insert(allTexts, '%s............')
                table.insert(valueFormat, newText)
        end

        if record.quality then
                table.insert(allTexts, 'Quality: %.2f')
                table.insert(valueFormat, record.quality)
        end

        ---@type ui.Layout[]
        local allEffectsTexts = {}
        local charge
        if record.enchant then
                table.insert(allTexts, '')
                ---@type Enchantment
                local enchantment = core.magic.enchantments.records[record.enchant]
                local max = enchantment.charge

                --- CHARGE
                -- if max ~= 0 then
                if enchantment.type ~= core.magic.ENCHANTMENT_TYPE.CastOnce and enchantment.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
                        charge = string.format('Charge:      %d / %d', data.enchantmentCharge, max)
                end

                --- TYPE
                table.insert(allTexts, '%s')
                table.insert(valueFormat, enchantmentTypes[enchantment.type + 1])


                --- EFFECTS
                local effects = enchantment.effects

                allEffectsTexts = getEffectsTexts(effects)
        elseif record.effects then
                allEffectsTexts = getEffectsTexts(record.effects)
        end



        textFormat = table.concat(allTexts, '\n')

        local text = string.format(textFormat, table.unpack(valueFormat))

        local myContent = {
                type = ui.TYPE.Flex,
                content = ui.content {
                        g.gui.makeInt(0, 8),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = record.name,
                                        textColor = g.colors.header,
                                        textSize = g.sizes.TOOLTIP_TEXT_SIZE
                                }
                        },
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = text,
                                        multiline = true,
                                        textSize = g.sizes.TOOLTIP_TEXT_SIZE
                                        -- textAlignH = ui.ALIGNMENT.Center

                                }
                        },
                        g.gui.makeInt(0, 8),

                        table.unpack(allEffectsTexts),
                }
        }

        if charge then
                myContent.content:add({
                        template = I.MWUI.templates.textNormal,
                        props = {
                                text = charge,
                                textSize = g.sizes.TOOLTIP_TEXT_SIZE
                        }
                })
        end

        local layout = {
                layer = 'Notification',
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                props = {
                        horizontal = false,
                        -- autoSize = false,
                        -- size = util.vector2(550, 400),
                },

                content = ui.content {
                        g.gui.makeInt(0, PADDING),
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                        -- align = ui.ALIGNMENT.Center,
                                        -- arrange = ui.ALIGNMENT.Center

                                },
                                content = ui.content {
                                        g.gui.makeInt(PADDING, 0),
                                        myContent,
                                        g.gui.makeInt(PADDING, 0),
                                }
                        },
                        g.gui.makeInt(0, PADDING),
                }
        }


        if not toolTip.element.layout then
                toolTip.element = ui.create(layout)
        else
                toolTip.element.layout = layout
        end
end

toolTip.hideToolTip = function()
        if toolTip.element.layout then
                toolTip.element:destroy()
        end
end

local xOffset
toolTip.update = function()
        if not toolTip.element.layout then return end

        if toolTip.currentId == nil then
                toolTip.hideToolTip()
                return
        end


        if g.util.mouse.x > (Reshw / Scale) then
                anchorX = 1
                xOffset = -50
        else
                anchorX = 0
                xOffset = 50
        end

        toolTip.element.layout.props.position = util.vector2(
                g.util.mouse.x + xOffset,
                g.util.mouse.y + 80)
        toolTip.element.layout.props.anchor = util.vector2(anchorX, 0.5)
        toolTip.element:update()
end


return toolTip
