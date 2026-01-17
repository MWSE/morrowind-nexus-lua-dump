local ui            = require('openmw.ui')
local async         = require('openmw.async')
local core          = require('openmw.core')
local I             = require('openmw.interfaces')
local util          = require('openmw.util')
local self          = require('openmw.self')
local types         = require('openmw.types')
local RANGED_WEAPON = require('scripts.Loadouts.myLib.myTypes').RANGED_WEAPON
local RANGED_AMMO   = require('scripts.Loadouts.myLib.myTypes').RANGED_AMMO
local sizes         = require('scripts.Loadouts.myLib.myConstants').sizes
local colors        = require('scripts.Loadouts.myLib.myConstants').colors
local gui           = require('scripts.Loadouts.myLib.myGUI')
local myTypes       = require('scripts.Loadouts.myLib.myTypes')
local mouse         = require('scripts.Loadouts.myLib.myUtils').mouse
local myVars        = require('scripts.Loadouts.myLib.myVars')
local PADDING       = 12


local templates = require('scripts.Loadouts.myLib.myTemplates')


local TEXT_BAR_LEN      = 10

local toolTip           = {
        ---@type ui.Element|{}
        element = {},
        ---@type ui.Layout
        layout = {
                name = 'toolTip',
        },
        emptyLayout = {
                name = 'toolTip',
        },
        currentId = nil,
        closed = nil,
}

local enchantmentTypes  = {
        'Once',
        'On Strike',
        'On Use',
        'Constant Effect',
}
local spellRange        = {
        [0] = 'Self',
        [1] = 'Touch',
        [2] = 'Target',
}
local affectedNames     = {
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
        ['agility']      = 'Agility',
        ['endurance']    = 'Endurance',
        ['intelligence'] = 'Intelligence',
        ['luck']         = 'Luck',
        ['personality']  = 'Personality',
        ['speed']        = 'Speed',
        ['strength']     = 'Strength',
        ['willpower']    = 'Willpower',
        ['longblade']    = 'Long Blade',
        ['enchant']      = 'Enchant',
        ['destruction']  = 'Destruction',
        ['alteration']   = 'Alteration',
        ['illusion']     = 'Illusion',
        ['conjuration']  = 'Conjuration',
        ['mysticism']    = 'Mysticism',
        ['restoration']  = 'Restoration',
        ['alchemy']      = 'Alchemy',
        ['unarmored']    = 'Unarmored',
        ['block']        = 'Block',
        ['armorer']      = 'Armorer',
        ['mediumarmor']  = 'Medium Armor',
        ['heavyarmor']   = 'Heavy Armor',
        ['bluntweapon']  = 'Blunt Weapon',
        ['axe']          = 'Axe',
        ['spear']        = 'Spear',
        ['athletics']    = 'Athletics',
        ['security']     = 'Security',
        ['sneak']        = 'Sneak',
        ['lightarmor']   = 'Light Armor',
        ['shortblade']   = 'Short Blade',
        ['marksman']     = 'Marksman',
        ['mercantile']   = 'Mercantile',
        ['speechcraft']  = 'Speechcraft',
        ['acrobatics']   = 'Acrobatics',
        ['handtohand']   = 'Hand-to-hand',

}

local function getStatLayout(statName, statValue)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ################
                external = { grow = 0, stretch = 1 },
                props = {
                        horizontal = true,
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = statName,
                                        textSize = sizes.TOOLTIP_TEXT_SIZE,
                                }
                        },
                        gui.makeInt(10, 0, 1, 0),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = statValue,
                                        textSize = sizes.TOOLTIP_TEXT_SIZE,
                                }
                        },
                }
        }
end

---@param icon string
---@param name string
---@return ui.Layout
local function createNameLayout(icon, name)
        return {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        anchor = util.vector2(0.5, 0.5),
                                        size = util.vector2(sizes.TEXT_SIZE - 4, sizes.TEXT_SIZE - 4),
                                        resource = ui.texture { path = icon }
                                }
                        },
                        gui.makeInt(10, 0),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = name,
                                        textSize = sizes.TOOLTIP_TEXT_SIZE,
                                }
                        }
                }
        }
end

local function createOtherLayout(text)
        return {
                template = I.MWUI.templates.textNormal,
                props = {
                        text = text,
                        textSize = sizes.TOOLTIP_TEXT_SIZE,
                }
        }
end

---@return ui.Layout
local function createHiddenEffectLayout()
        return {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = { text = '?' }
                        }
                }
        }
end

---@param layouts ui.Layout[]
---@return ui.Layout
local function addCol(layouts)
        return {
                type = ui.TYPE.Flex,
                templates = I.MWUI.templates.borders,
                content = ui.content(layouts)
        }
end

---@param effects MagicEffectWithParams[]
local function getEffectsTexts(effects, itemType)
        ---@type ui.Layout[]
        local effectsTextsLayouts = {}

        if itemType == types.Ingredient then
                local playerAlchemy = types.NPC.stats.skills.alchemy(self).modified
                local visibleEffects = math.min(math.floor(playerAlchemy / 15), #effects)

                local nameCol = {}
                for i = 1, #effects do
                        local layout
                        if i > visibleEffects then
                                layout = createHiddenEffectLayout()
                        else
                                local effectWP = effects[i]
                                local affectedThing = effectWP.affectedAttribute or effectWP.affectedSkill
                                local name = affectedThing and
                                    (affectedNames[effectWP.effect.name] .. ' ' .. affectedAttrSkill[affectedThing]) or
                                    effectWP.effect.name
                                layout = createNameLayout(effectWP.effect.icon, name)
                        end

                        table.insert(nameCol, layout)
                end
                table.insert(effectsTextsLayouts, addCol(nameCol))
        else
                local nameCol = {}
                local magCol = {}
                local durCol = {}
                local areaCol = {}
                local rangeCol = {}
                for i = 1, #effects do
                        local effectWP = effects[i]

                        local affectedThing = effectWP.affectedAttribute or effectWP.affectedSkill
                        local name = affectedThing and
                            (affectedNames[effectWP.effect.name] .. ' ' .. affectedAttrSkill[affectedThing]) or
                            effectWP.effect.name


                        table.insert(nameCol, createNameLayout(effectWP.effect.icon, name))

                        local mag = effectWP.magnitudeMin == effectWP.magnitudeMax
                            and effectWP.magnitudeMax .. 'p'
                            or effectWP.magnitudeMin .. ' - ' .. effectWP.magnitudeMax .. 'p'
                        table.insert(magCol, createOtherLayout(mag))

                        local duration = effectWP.duration .. 's'
                        table.insert(durCol, createOtherLayout(duration))
                        local area = (effectWP.area ~= 0) and (effectWP.area .. 'f') or ' - '
                        table.insert(areaCol, createOtherLayout(area))
                        local range = spellRange[effectWP.range]
                        table.insert(rangeCol, createOtherLayout(range))
                end

                table.insert(effectsTextsLayouts, addCol(nameCol))
                table.insert(effectsTextsLayouts, gui.makeInt(20, 0))
                table.insert(effectsTextsLayouts, addCol(magCol))
                table.insert(effectsTextsLayouts, gui.makeInt(20, 0))
                table.insert(effectsTextsLayouts, addCol(durCol))
                table.insert(effectsTextsLayouts, gui.makeInt(20, 0))
                table.insert(effectsTextsLayouts, addCol(areaCol))
                table.insert(effectsTextsLayouts, gui.makeInt(20, 0))
                table.insert(effectsTextsLayouts, addCol(rangeCol))
        end

        return effectsTextsLayouts
end

---@param thing GameObject|Spell
---@param forcePos boolean
toolTip.showToolTip = function(thing, forcePos)
        if not thing or not thing.type then return end
        if not myVars.mainWindow.element.layout then
                return
        end

        toolTip.forcePos = forcePos
        toolTip.currentId = thing.recordId or thing.id


        if thing.effects then
                local allTextEffects = getEffectsTexts(thing.effects)

                local myContent = {
                        type = ui.TYPE.Flex,
                        content = ui.content {
                                gui.makeInt(0, PADDING),
                                {
                                        template = I.MWUI.templates.textHeader,
                                        props = {
                                                text = thing.name,
                                                textSize = sizes.TOOLTIP_TEXT_SIZE,
                                        }
                                },
                                gui.makeInt(0, 10),
                                {
                                        type = ui.TYPE.Flex,
                                        props = {
                                                horizontal = true
                                        },
                                        content = ui.content(allTextEffects)
                                },
                                gui.makeInt(0, PADDING),
                        }
                }

                if toolTip.element.layout then
                        toolTip.element:destroy()
                end

                toolTip.element = ui.create {
                        layer = "Windows",
                        type = ui.TYPE.Flex,
                        template = templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                        external = { grow = 1, stretch = 1, },
                        props = {
                                relativePosition = util.vector2(0.5, 0.5),
                                anchor = util.vector2(0.5, 0.5),
                                horizontal = true,
                        },
                        content = ui.content({
                                gui.makeInt(PADDING, 0),
                                myContent,
                                gui.makeInt(PADDING, 0),
                        }),
                        events = {
                                mouseMove = async:callback(function()
                                        toolTip.currentId = nil
                                        return true
                                end)
                        }
                }

                return
        end



        ---@type Record
        local record = thing.type.record(thing)

        ---@type ItemData
        local data = thing.type.itemData(thing)


        local allStatsLayouts = {}

        local nameCol = {}
        local valueCol = {}


        if thing.type == types.Weapon and myTypes.WEAPON_TYPE_TO_TEXT[record.type] then
                table.insert(nameCol, 'Type:')
                table.insert(valueCol, myTypes.WEAPON_TYPE_TO_TEXT[record.type])
        end

        if record.chopMaxDamage then
                if RANGED_WEAPON[record.type] then
                        table.insert(nameCol, 'Attack:')
                        table.insert(valueCol, string.format('%d - %d', record.chopMinDamage, record.chopMaxDamage))
                        table.insert(nameCol, 'Speed:')
                        table.insert(valueCol, string.format('%.2f', record.speed))
                elseif RANGED_AMMO[record.type] then
                        table.insert(nameCol, 'Attack:')
                        table.insert(valueCol, string.format('%d - %d', record.chopMinDamage, record.chopMaxDamage))
                else
                        table.insert(nameCol, 'Chop:')
                        table.insert(valueCol, string.format('%d - %d', record.chopMinDamage, record.chopMaxDamage))

                        table.insert(nameCol, 'Slash:')
                        table.insert(valueCol, string.format('%d - %d', record.slashMinDamage, record.slashMaxDamage))


                        table.insert(nameCol, 'Thrust:')
                        table.insert(valueCol, string.format('%d - %d', record.thrustMinDamage, record.thrustMaxDamage))


                        table.insert(nameCol, 'Range:')
                        table.insert(valueCol, string.format('%.2f', record.reach))


                        table.insert(nameCol, 'Speed:')
                        table.insert(valueCol, string.format('%.2f', record.speed))
                end
        end

        if record.baseArmor then
                table.insert(nameCol, 'Rating:')
                table.insert(valueCol, string.format('%d', record.baseArmor))
        end

        if data.condition then
                local value = data.condition
                local max = record.maxCondition or record.health or record.duration

                table.insert(nameCol, 'Condition:')
                table.insert(valueCol, string.format('%s %d / %d',
                        gui.makeTextBar(value, max, TEXT_BAR_LEN, false),
                        data.condition, max
                ))
        end

        -- if record.text then
        --         local newText = string.gsub(record.text, "<.->", "")
        --         local spaceIndex = string.find(newText, ' ', sizes.BOOK_PREVIEW_LENGTH)
        --         if spaceIndex ~= nil then
        --                 newText = string.sub(newText, 1, spaceIndex)
        --         else
        --                 newText = string.sub(newText, 1, sizes.BOOK_PREVIEW_LENGTH + 2)
        --         end
        --         local pattern = '%%(%S[^.{}<>, \n\t%s]*)'
        --         newText = newText:gsub(pattern, toolTip.gv)
        --         newText = breakText(newText, sizes.BOOK_PREVIEW_WORDS_PER_LINE)
        --         if record.text:len() > sizes.BOOK_PREVIEW_LENGTH then
        --                 table.insert(allTexts, '%s............')
        --         else
        --                 table.insert(allTexts, '%s')
        --         end
        --         table.insert(valueFormat, newText)
        -- end

        if record.quality then
                table.insert(nameCol, 'Quality:')
                table.insert(valueCol, string.format('%.2f', record.quality))
        end

        if record.weight then
                table.insert(nameCol, 'Weight:')
                table.insert(valueCol, string.format('%.2f', record.weight))
        end

        if record.value then
                table.insert(nameCol, 'Value:')
                table.insert(valueCol, string.format('%d', record.value))
        end

        local nameColLayouts = {}
        for i = 1, #nameCol do
                table.insert(nameColLayouts, createOtherLayout(nameCol[i]))
        end

        local valueColLayouts = {}
        for i = 1, #valueCol do
                table.insert(valueColLayouts, createOtherLayout(valueCol[i]))
        end

        table.insert(allStatsLayouts, addCol(nameColLayouts))
        table.insert(allStatsLayouts, gui.makeInt(10, 0))
        table.insert(allStatsLayouts, addCol(valueColLayouts))

        ---@type ui.Layout[]
        local allEffectsTexts = {}

        local chargeLayout

        local enchType
        if record.enchant then
                ---@type Enchantment
                local enchantment = core.magic.enchantments.records[record.enchant]

                if enchantment.type ~= core.magic.ENCHANTMENT_TYPE.CastOnce
                    and enchantment.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
                        local value = data.enchantmentCharge or 0
                        local max = enchantment.charge

                        local cRow = {}

                        table.insert(cRow, addCol({ createOtherLayout('Charge:') }))
                        table.insert(cRow, gui.makeInt(10, 0))
                        table.insert(cRow, addCol({ createOtherLayout(string.format('%s %d / %d',
                                gui.makeTextBar(value, max, TEXT_BAR_LEN, false), value, max)) }))

                        chargeLayout = {
                                type = ui.TYPE.Flex,
                                props = { horizontal = true },
                                content = ui.content(cRow)
                        }
                end

                enchType = enchantment.type

                --- EFFECTS
                local effects = enchantment.effects
                allEffectsTexts = getEffectsTexts(effects, thing.type)
        elseif record.effects then
                allEffectsTexts = getEffectsTexts(record.effects, thing.type)
        end

        local myContent = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.bordersThick, --- ################
                external = { grow = 1, stretch = 1, },
                props = {
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        -- gui.makeInt(0, 8),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = record.name,
                                        textColor = colors.header,
                                        textSize = sizes.TOOLTIP_TEXT_SIZE
                                }
                        },
                        gui.makeInt(0, 8),

                        {
                                type = ui.TYPE.Flex,
                                props = { horizontal = true },
                                -- template = I.MWUI.templates.borders, --- ################
                                content = ui.content(allStatsLayouts)
                        },
                        enchType and gui.makeInt(0, 8) or {},
                        enchType and {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = enchantmentTypes[enchType + 1],
                                        textColor = colors.header,
                                        textSize = sizes.TOOLTIP_TEXT_SIZE
                                }
                        } or {},
                        #allEffectsTexts > 0 and gui.makeInt(0, 8) or {},
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true
                                },
                                content = ui.content(allEffectsTexts)
                        },
                        chargeLayout and gui.makeInt(0, 8) or {},
                        chargeLayout or {},
                }
        }

        local content = {
                gui.makeInt(0, PADDING),
                {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders, --- ################
                        external = { grow = 1, stretch = 1, },
                        props = {
                                horizontal = true,
                                -- align = ui.ALIGNMENT.Center,
                                -- arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                                gui.makeInt(PADDING, 0),
                                myContent,
                                gui.makeInt(PADDING, 0),
                        }
                },
                gui.makeInt(0, PADDING),
        }

        if toolTip.element.layout then
                toolTip.element:destroy()
        end

        toolTip.element = ui.create {
                layer = "Windows",
                type = ui.TYPE.Flex,
                template = templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                external = { grow = 1, stretch = 1, },
                props = {
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                },
                content = ui.content(content),
                events = {
                        mouseMove = async:callback(function()
                                toolTip.currentId = nil
                                return true
                        end)
                }
        }
end


local OFFSET = 16

toolTip.update = function()
        if not toolTip.element.layout then return end

        if not toolTip.currentId then
                toolTip.element:destroy()
                return
        end

        if toolTip.closed then
                toolTip.element:destroy()
                return
        end



        if toolTip.forcePos ~= true then
                local hw = myVars.res.x / 2
                local hh = myVars.res.y / 2
                local anchorX
                local anchorY
                local offsetX
                local offsetY
                if mouse.x > hw then
                        anchorX = 1
                        offsetX = -OFFSET
                else
                        anchorX = 0
                        offsetX = OFFSET
                end

                if mouse.y > hh then
                        anchorY = 1
                        offsetY = -OFFSET
                else
                        anchorY = 0
                        offsetY = OFFSET
                end

                local ttx = mouse.x + offsetX
                local tty = mouse.y + offsetY

                toolTip.element.layout.props.relativePosition = nil
                toolTip.element.layout.props.anchor = util.vector2(anchorX, anchorY)
                toolTip.element.layout.props.position = util.vector2(ttx, tty)
                toolTip.element:update()
        end
end

return toolTip
