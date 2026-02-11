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
local textures      = require('scripts.Loadouts.myLib.myConstants').textures
local gui           = require('scripts.Loadouts.myLib.myGUI')
local myTypes       = require('scripts.Loadouts.myLib.myTypes')
local mouse         = require('scripts.Loadouts.myLib.myUtils').mouse
local myVars        = require('scripts.Loadouts.myLib.myVars')
local o             = require('scripts.Loadouts.settingsData').o
local PADDING       = 12

local templates     = require('scripts.Loadouts.myLib.myTemplates')

local getGMST       = core.getGMST

-- local redTint = 'aa0000'
-- local redTint       = 'cc331c'

local function gmstWC(str)
        return getGMST(str) .. ':'
end

local toolTip             = {
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

local enchantmentTypes    = {
        getGMST('sItemCastOnce'),
        getGMST('sItemCastWhenStrikes'),
        getGMST('sItemCastWhenUsed'),
        getGMST('sItemCastConstant'),
}
local spellRange          = {
        [0] = getGMST('sRangeSelf'),
        [1] = getGMST('sRangeTouch'),
        [2] = getGMST('sRangeTarget'),
}
local affectedNames       = {
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
local affectedAttrSkill   = {
        ['strength']     = getGMST('sAttributeStrength'),
        ['intelligence'] = getGMST('sAttributeIntelligence'),
        ['willpower']    = getGMST('sAttributeWillpower'),
        ['agility']      = getGMST('sAttributeAgility'),
        ['speed']        = getGMST('sAttributeSpeed'),
        ['endurance']    = getGMST('sAttributeEndurance'),
        ['personality']  = getGMST('sAttributePersonality'),
        ['luck']         = getGMST('sAttributeLuck'),
        ['longblade']    = getGMST('sSkillLongBlade'),
        ['enchant']      = getGMST('sSkillEnchant'),
        ['destruction']  = getGMST('sSkillDestruction'),
        ['alteration']   = getGMST('sSkillAlteration'),
        ['illusion']     = getGMST('sSkillIllusion'),
        ['conjuration']  = getGMST('sSkillConjuration'),
        ['mysticism']    = getGMST('sSkillMysticism'),
        ['restoration']  = getGMST('sSkillRestoration'),
        ['alchemy']      = getGMST('sSkillAlchemy'),
        ['unarmored']    = getGMST('sSkillUnarmored'),
        ['block']        = getGMST('sSkillBlock'),
        ['armorer']      = getGMST('sSkillArmorer'),
        ['mediumarmor']  = getGMST('sSkillMediumArmor'),
        ['heavyarmor']   = getGMST('sSkillHeavyArmor'),
        ['bluntweapon']  = getGMST('sSkillBluntWeapon'),
        ['axe']          = getGMST('sSkillAxe'),
        ['spear']        = getGMST('sSkillSpear'),
        ['athletics']    = getGMST('sSkillAthletics'),
        ['security']     = getGMST('sSkillSecurity'),
        ['sneak']        = getGMST('sSkillSneak'),
        ['lightarmor']   = getGMST('sSkillLightArmor'),
        ['shortblade']   = getGMST('sSkillShortBlade'),
        ['marksman']     = getGMST('sSkillMarksman'),
        ['mercantile']   = getGMST('sSkillMercantile'),
        ['speechcraft']  = getGMST('sSkillSpeechcraft'),
        ['acrobatics']   = getGMST('sSkillAcrobatics'),
        ['handtohand']   = getGMST('sSkillhandtohand'),
}
toolTip.affectedAttrSkill = affectedAttrSkill

local WEAPON_TYPE_TO_TEXT = {
        [0]  = string.format('%s, %s', affectedAttrSkill['shortblade'], getGMST('sOneHanded')),
        [1]  = string.format('%s, %s', affectedAttrSkill['longblade'], getGMST('sOneHanded')),
        [2]  = string.format('%s, %s', affectedAttrSkill['longblade'], getGMST('sTwoHanded')),
        [3]  = string.format('%s, %s', affectedAttrSkill['bluntweapon'], getGMST('sOneHanded')),
        [4]  = string.format('%s, %s', affectedAttrSkill['bluntweapon'], getGMST('sTwoHanded')),
        [5]  = string.format('%s, %s', affectedAttrSkill['bluntweapon'], getGMST('sTwoHanded')),
        [6]  = string.format('%s, %s', affectedAttrSkill['spear'], getGMST('sTwoHanded')),
        [7]  = string.format('%s, %s', affectedAttrSkill['axe'], getGMST('sOneHanded')),
        [8]  = string.format('%s, %s', affectedAttrSkill['axe'], getGMST('sTwoHanded')),
        [9]  = affectedAttrSkill['marksman'],
        [10] = affectedAttrSkill['marksman'],
        [11] = affectedAttrSkill['marksman'],

        -- [0] = 'Short Blade, One Handed',
        -- [1] = 'Long Blade, One Handed',
        -- [2] = 'Long Blade, Two Handed',
        -- [3] = 'Blunt Weapon, One Handed',
        -- [4] = 'Blunt Weapon, Two Handed',
        -- [5] = 'Blunt Weapon, Two Handed',
        -- [6] = 'Spear, Two Handed',
        -- [7] = 'Axe, One Handed',
        -- [8] = 'Axe, Two Handed',
        -- [9] = 'Marksman',
        -- [10] = 'Marksman',
        -- [11] = 'Marksman',
}

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
                                        size = util.vector2(sizes.TEXT_SIZE, sizes.TEXT_SIZE),
                                        resource = ui.texture { path = icon }
                                }
                        },
                        gui.makeGap(10, 0),
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
        if type(text) == "string" then
                return {
                        template = I.MWUI.templates.textNormal,
                        props = {
                                text = text,
                                textSize = sizes.TOOLTIP_TEXT_SIZE,
                                multiline = true,

                        }
                }
        else
                return text
        end
end


---@param text string
---@param n number
---@param onBreak? fun()
---@return string
local function breakText(text, n, onBreak)
        local result = {}
        for section in string.gmatch(text, "([^\n]+)") do
                local count = 0
                local allWords = {}
                for word, whitespace in string.gmatch(section, "(%S+)(%s*)") do
                        count = count + 1
                        table.insert(allWords, word)
                        if count % n == 0 then
                                table.insert(allWords, "\n")
                                if onBreak then
                                        onBreak()
                                end
                        else
                                table.insert(allWords, whitespace)
                        end
                end
                table.insert(result, table.concat(allWords))
        end
        return table.concat(result, "\n")
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
local function getEffectsTexts(effects, itemType, isContant)
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
                            and effectWP.magnitudeMax .. ' ' .. getGMST('spoints')
                            or effectWP.magnitudeMin ..
                            string.format(' %s ', getGMST('sTo')) .. effectWP.magnitudeMax .. ' ' .. getGMST('spoints')
                        table.insert(magCol, createOtherLayout(mag))

                        local secFormat = effectWP.duration > 1 and getGMST('sseconds') or getGMST('ssecond')
                        local duration = (effectWP.duration > 0 and not isContant) and
                            string.format('%s %s %s', getGMST('sfor'), effectWP.duration, secFormat) or ''

                        table.insert(durCol, createOtherLayout(duration))
                        local area = (effectWP.area ~= 0) and
                            (getGMST('sin') .. ' ' .. effectWP.area .. ' ' .. getGMST('sfootarea')) or
                            ''
                        table.insert(areaCol, createOtherLayout(area))
                        local range = getGMST('sonword') .. ' ' .. spellRange[effectWP.range]
                        table.insert(rangeCol, createOtherLayout(range))
                end

                table.insert(effectsTextsLayouts, addCol(nameCol))
                table.insert(effectsTextsLayouts, gui.makeGap(20, 0))
                table.insert(effectsTextsLayouts, addCol(magCol))
                table.insert(effectsTextsLayouts, gui.makeGap(20, 0))
                table.insert(effectsTextsLayouts, addCol(durCol))
                table.insert(effectsTextsLayouts, gui.makeGap(20, 0))
                table.insert(effectsTextsLayouts, addCol(areaCol))
                table.insert(effectsTextsLayouts, gui.makeGap(20, 0))
                table.insert(effectsTextsLayouts, addCol(rangeCol))
        end

        return effectsTextsLayouts
end

---@param content ui.Layout
local function createToolTip(content)
        if toolTip.element.layout then
                toolTip.element:destroy()
        end

        local posX = o.toolTipPosX.value
        local posY = o.toolTipPosY.value
        local ancX = o.toolTipAnchorX.value
        local ancY = o.toolTipAnchorY.value

        toolTip.element = ui.create {
                layer = "Windows",
                type = ui.TYPE.Flex,
                template = templates.getTemplate('thin', { 0, 0, 0, 0 }, textures.black, nil, nil, o.bgAlpha_tooltip.value),
                external = { grow = 1, stretch = 1, },
                props = {
                        relativePosition = util.vector2(posX, posY),
                        anchor = util.vector2(ancX, ancY),
                },
                content = ui.content({
                        content,
                }),
        }
end

---@param thing GameObject|Spell
---@param usingMouse boolean|nil
toolTip.showToolTip = function(thing, usingMouse)
        if not thing or not thing.type then return end
        if not myVars.mainWindow.element.layout then
                return
        end

        --- It was toolTip.forcePos
        toolTip.usingMouse = not usingMouse
        toolTip.currentId = thing.recordId or thing.id


        if thing.effects then
                local allTextEffects = getEffectsTexts(thing.effects)

                local myContent = {

                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                        },
                        content = ui.content {
                                gui.makeGap(PADDING, 0),
                                {

                                        type = ui.TYPE.Flex,
                                        content = ui.content {
                                                gui.makeGap(0, PADDING),
                                                {
                                                        template = I.MWUI.templates.textHeader,
                                                        props = {
                                                                text = thing.name,
                                                                textSize = sizes.TOOLTIP_TEXT_SIZE,
                                                        }
                                                },
                                                gui.makeGap(0, 10),
                                                {
                                                        type = ui.TYPE.Flex,
                                                        props = {
                                                                horizontal = true
                                                        },
                                                        content = ui.content(allTextEffects)
                                                },
                                                gui.makeGap(0, PADDING),
                                        }
                                },
                                gui.makeGap(PADDING, 0),
                        }

                }

                createToolTip(myContent)
                return
        end



        ---@type Record
        local record = thing.type.record(thing)

        ---@type ItemData
        local data = thing.type.itemData(thing)


        local countText = thing.count > 1 and string.format('(%s)', thing.count) or ''
        local nameText = string.format('%s %s', record.name, countText)


        local allStatsLayouts = {}

        local nameCol = {}
        local valueCol = {}

        if record.text and not record.enchant then
                local newText = string.gsub(record.text, "<.->", "")

                local spaceIndex = string.find(newText, ' ', sizes.BOOK_PREVIEW_LENGTH)
                if spaceIndex ~= nil then
                        newText = string.sub(newText, 1, spaceIndex)
                else
                        newText = string.sub(newText, 1, sizes.BOOK_PREVIEW_LENGTH + 2)
                end

                local pattern = '%%(%S[^.{}<>, \n\t%s]*)'

                newText = newText:gsub(pattern, myVars.gv)

                newText = breakText(newText, sizes.BOOK_PREVIEW_WORDS_PER_LINE)

                if record.text:len() > sizes.BOOK_PREVIEW_LENGTH then
                        -- table.insert(allTexts, '%s............')
                        table.insert(valueCol, string.format('%s............', newText))
                else
                        table.insert(valueCol, string.format('%s', newText))
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
                table.insert(allStatsLayouts, gui.makeGap(10, 0))
                table.insert(allStatsLayouts, addCol(valueColLayouts))

                local myContent = {

                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                        },
                        content = ui.content {
                                gui.makeGap(PADDING, 0),
                                {
                                        type = ui.TYPE.Flex,
                                        content = ui.content {
                                                gui.makeGap(0, PADDING / 2),
                                                {
                                                        type = ui.TYPE.Flex,
                                                        props = {
                                                                horizontal = true
                                                        },
                                                        content = ui.content(allStatsLayouts)
                                                },
                                                gui.makeGap(0, PADDING),
                                        }
                                },
                                gui.makeGap(PADDING, 0),
                        }

                }

                createToolTip(myContent)

                return
        end

        if record.text then
                local newText = string.gsub(record.text, "<.->", "")
                table.insert(nameCol, 'Script:')

                newText = breakText(newText, 5, function()
                        table.insert(nameCol, '')
                end)

                table.insert(valueCol, newText)
        end

        if thing.type == types.Weapon and WEAPON_TYPE_TO_TEXT[record.type] then
                table.insert(nameCol, gmstWC('sType'))
                table.insert(valueCol, WEAPON_TYPE_TO_TEXT[record.type])
        end

        if record.chopMaxDamage then
                if RANGED_WEAPON[record.type] then
                        table.insert(nameCol, gmstWC('sAttack'))

                        table.insert(valueCol, string.format('%d - %d', record.chopMinDamage, record.chopMaxDamage))
                        table.insert(nameCol, gmstWC('sAttributeSpeed'))
                        table.insert(valueCol, string.format('%.2f', record.speed))
                elseif RANGED_AMMO[record.type] then
                        table.insert(nameCol, gmstWC('sAttack'))
                        table.insert(valueCol, string.format('%d - %d', record.chopMinDamage, record.chopMaxDamage))
                else
                        table.insert(nameCol, gmstWC('sChop'))
                        table.insert(valueCol, string.format('%d - %d', record.chopMinDamage, record.chopMaxDamage))

                        table.insert(nameCol, gmstWC('sSlash'))
                        table.insert(valueCol, string.format('%d - %d', record.slashMinDamage, record.slashMaxDamage))


                        table.insert(nameCol, gmstWC('sThrust'))

                        table.insert(valueCol, string.format('%d - %d', record.thrustMinDamage, record.thrustMaxDamage))

                        table.insert(nameCol, gmstWC('sRange'))
                        table.insert(valueCol, string.format('%d %s', record.reach * 6, getGMST('sfeet')))

                        table.insert(nameCol, gmstWC('sAttributeSpeed'))
                        table.insert(valueCol, string.format('%d%%', record.speed * 100))
                end
        end

        if record.baseArmor then
                -- table.insert(nameCol, 'Rating:')
                table.insert(nameCol, gmstWC('sArmorRating'))
                table.insert(valueCol, string.format('%d', record.baseArmor))
        end

        if data.condition then
                local value = data.condition
                local max = record.maxCondition or record.health or record.duration

                table.insert(nameCol, gmstWC('sCondition'))
                table.insert(valueCol, gui.makeGUIBar(value, max, 200, 18, colors.redTintHex))
        end

        if record.quality then
                table.insert(nameCol, gmstWC('sQuality'))
                table.insert(valueCol, string.format('%.2f', record.quality))
        end

        if record.weight then
                table.insert(nameCol, gmstWC('sWeight'))
                table.insert(valueCol, string.format('%.2f', record.weight))
        end

        if record.value then
                table.insert(nameCol, gmstWC('sValue'))
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
        table.insert(allStatsLayouts, gui.makeGap(10, 0))
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

                        table.insert(cRow, addCol({ createOtherLayout(getGMST('sCharges')) }))
                        table.insert(cRow, gui.makeGap(10, 0))
                        table.insert(cRow, gui.makeGUIBar(value, max, 200, 18, colors.redTintHex))



                        chargeLayout = {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content(cRow)
                        }
                end

                enchType = enchantment.type

                --- EFFECTS
                local effects = enchantment.effects
                allEffectsTexts = getEffectsTexts(effects, thing.type, enchType == 3)
        elseif record.effects then
                allEffectsTexts = getEffectsTexts(record.effects, thing.type, false)
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
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        -- text = record.name,
                                        text = nameText,
                                        textColor = colors.header,
                                        textSize = sizes.TOOLTIP_TEXT_SIZE
                                }
                        },
                        gui.makeGap(0, 8),

                        {
                                type = ui.TYPE.Flex,
                                props = { horizontal = true },
                                -- template = I.MWUI.templates.borders, --- ################
                                content = ui.content(allStatsLayouts)
                        },
                        enchType and gui.makeGap(0, 8) or {},
                        enchType and {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = enchantmentTypes[enchType + 1],
                                        textColor = colors.header,
                                        textSize = sizes.TOOLTIP_TEXT_SIZE
                                }
                        } or {},
                        #allEffectsTexts > 0 and gui.makeGap(0, 8) or {},
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true
                                },
                                content = ui.content(allEffectsTexts)
                        },
                        chargeLayout and gui.makeGap(0, 8) or {},
                        chargeLayout or {},
                }
        }

        local content = {
                type = ui.TYPE.Flex,
                content = ui.content {

                        gui.makeGap(0, PADDING),
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
                                        gui.makeGap(PADDING, 0),
                                        myContent,
                                        gui.makeGap(PADDING, 0),
                                }
                        },
                        gui.makeGap(0, PADDING),
                }
        }

        createToolTip(content)
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

        if toolTip.usingMouse then
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
