local ui = require('openmw.ui')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local self = require('openmw.self')
local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt
local mouse = require('scripts.spellsBookmark.lib.myUtils').mouse
local myTemplates = require('scripts.spellsBookmark.lib.myTemplates')
local myVars = require('scripts.spellsBookmark.lib.myVars')

local Res = ui.screenSize()
local Reshw = Res.x / 2
local Reshh = Res.y / 2
local anchorX
local PADDING = 12

local spellRange = {
        [0] = 'Self',
        [1] = 'Touch',
        [2] = 'Target',
}

local affectedNames = {
        ['Fortify Attribute'] = 'Fortify',
        ['Fortify Skill']     = 'Fortify',

        ['Restore Attribute'] = 'Restore',
        ['Restore Skill']     = 'Restore',

        ['Drain Attribute']   = 'Drain',
        ['Drain Skill']       = 'Drain',

        ['Absorb Attribute']  = 'Absorb',
        ['Absorb Skill']      = 'Absorb',

        ['Damage Attribute']  = 'Damage',
        ['Damage Skill']      = 'Damage',
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



local toolTip = {
        ---@type ui.Element|{}
        element = {},
        spellID = nil,
}
local function estimateTextWidth(text, min)
        return math.max(#text * 6, min)
end


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

local function getEffectInfo(info)
        ---
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

local function createTTText(text, width)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,

                props = {
                        size = util.vector2(width, 20)
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = text,
                                        textSize = 12,

                                }
                        }
                }
        }
end
---@params effectsInfos MagicEffectWithParams[]
local function getEffectsLayout(ItemName, effectsInfos)
        for i, _ in pairs(maxWidths) do
                maxWidths[i] = 0
        end

        local allTexts = {}

        for _, info in pairs(effectsInfos) do
                getEffectInfo(info)
                maxWidths.name = math.max(maxWidths.name, estimateTextWidth(name, 165))
                maxWidths.magnitude = math.max(maxWidths.magnitude, estimateTextWidth(mag, 46))
                maxWidths.duration = math.max(maxWidths.duration, estimateTextWidth(duration, 46))
                maxWidths.area = area ~= '' and math.max(maxWidths.area, estimateTextWidth(area, 30)) or 0
                maxWidths.range = math.max(maxWidths.range, estimateTextWidth(range, 0))
        end

        for _, info in pairs(effectsInfos) do
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
                                makeInt(10, 0),

                                createTTText(name, maxWidths.name),
                                createTTText(mag, maxWidths.magnitude),
                                createTTText(duration, maxWidths.duration),
                                createTTText(area, maxWidths.area),
                                createTTText(range, maxWidths.range),
                        }
                }
                table.insert(allTexts, textLayout)
        end

        local myContent = {
                type = ui.TYPE.Flex,
                content = ui.content {
                        { template = I.MWUI.templates.textHeader, props = { text = ItemName } },
                        makeInt(0, PADDING),
                        table.unpack(allTexts),
                }
        }



        return {
                layer = 'Notification',
                type = ui.TYPE.Flex,
                template = myTemplates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                props = {
                        horizontal = false,
                        autoSize = true,
                },

                content = ui.content {
                        makeInt(0, PADDING),
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true

                                },
                                content = ui.content {
                                        makeInt(PADDING, 0),
                                        myContent,
                                        makeInt(PADDING, 0),
                                }
                        },
                        makeInt(0, PADDING),
                }
        }
end

---@param thing Spell|GameObject
---@param forcePos? boolean
toolTip.showToolTip = function(thing, forcePos)
        toolTip.forcePos = forcePos

        local layout
        if thing.effects then
                layout = getEffectsLayout(thing.name, thing.effects)
        else
                ---@type Record
                local itemRecord = thing.type.record(thing)

                ---@type Enchantment
                local enchRecord = core.magic.enchantments.records
                    [itemRecord.enchant]

                layout = getEffectsLayout(itemRecord.name, enchRecord.effects)
        end

        if not toolTip.element.layout then
                toolTip.element = ui.create(layout)
        else
                toolTip.element.layout = layout
        end

        toolTip.spellID = thing.id
end

toolTip.hideToolTip = function()
        if toolTip.element.layout then
                toolTip.element:destroy()
        end
        toolTip.spellID = nil
end

local xOffset
toolTip.update = function()
        if not toolTip.element.layout then return end

        if toolTip.spellID == nil then
                toolTip.hideToolTip()
                return
        end

        if toolTip.forcePos then
                toolTip.element.layout.props.relativePosition = util.vector2(0.5, 0.5)
                toolTip.element.layout.props.anchor = util.vector2(0.5, 0.5)
        else
                if mouse.x > myVars.res.x / 2 then
                        anchorX = 1
                        xOffset = -20
                else
                        anchorX = 0
                        xOffset = 20
                end

                toolTip.element.layout.props.position = util.vector2(
                        mouse.x + xOffset,
                        mouse.y + 10)
                toolTip.element.layout.props.anchor = util.vector2(anchorX, 0)
                toolTip.element:update()
        end
end


return {
        toolTip = toolTip,
}
