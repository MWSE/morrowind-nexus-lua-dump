-- local ui                = require('openmw.ui')
-- local core              = require('openmw.core')
-- local I                 = require('openmw.interfaces')
-- local util              = require('openmw.util')
-- local self              = require('openmw.self')
-- local types             = require('openmw.types')
-- local RANGED_WEAPON     = require('scripts.Loadouts.myLib.myTypes').RANGED_WEAPON
-- local RANGED_AMMO       = require('scripts.Loadouts.myLib.myTypes').RANGED_AMMO
-- local sizes             = require('scripts.Loadouts.myLib.myConstants').sizes
-- local colors            = require('scripts.Loadouts.myLib.myConstants').colors
-- local gui               = require('scripts.Loadouts.myLib.myGUI')
-- local myTypes           = require('scripts.Loadouts.myLib.myTypes')
-- local Res               = ui.screenSize()
-- local Reshw             = Res.x / 2
-- local Reshh             = Res.y / 2
-- local anchorX
-- local PADDING           = 12
-- local toolTip           = {
--         ---@type ui.Element|{}
--         element = {},
--         ---@type ui.Layout
--         layout = {
--                 name = 'toolTip',
--         },
--         emptyLayout = {
--                 name = 'toolTip',
--         }
-- }
-- local enchantmentTypes  = {
--         'Once',
--         'On Strike',
--         'On Use',
--         'Constant Effect',
-- }
-- local spellRange        = {
--         [0] = 'Self',
--         [1] = 'Touch',
--         [2] = 'Target',
-- }
-- local affectedNames     = {
--         ['Fortify Attribute'] = 'Fortify',
--         ['Fortify Skill']     = 'Fortify',

--         ['Restore Attribute'] = 'Restore',
--         ['Restore Skill']     = 'Restore',

--         ['Drain Attribute']   = 'Drain',
--         ['Drain Skill']       = 'Drain',

--         ['Absorb Attribute']  = 'Absorb',
--         ['Absorb Skill']      = 'Absorb',

--         ['Damage Attribute']  = 'Damage',
--         ['Damage Skill']      = 'Damage',
-- }
-- local affectedAttrSkill = {
--         ['agility']      = 'Agility',
--         ['endurance']    = 'Endurance',
--         ['intelligence'] = 'Intelligence',
--         ['luck']         = 'Luck',
--         ['personality']  = 'Personality',
--         ['speed']        = 'Speed',
--         ['strength']     = 'Strength',
--         ['willpower']    = 'Willpower',
--         ['longblade']    = 'Longblade',
--         ['enchant']      = 'Enchant',
--         ['destruction']  = 'Destruction',
--         ['alteration']   = 'Alteration',
--         ['illusion']     = 'Illusion',
--         ['conjuration']  = 'Conjuration',
--         ['mysticism']    = 'Mysticism',
--         ['restoration']  = 'Restoration',
--         ['alchemy']      = 'Alchemy',
--         ['unarmored']    = 'Unarmored',
--         ['block']        = 'Block',
--         ['armorer']      = 'Armorer',
--         ['mediumarmor']  = 'Mediumarmor',
--         ['heavyarmor']   = 'Heavyarmor',
--         ['bluntweapon']  = 'Bluntweapon',
--         ['axe']          = 'Axe',
--         ['spear']        = 'Spear',
--         ['athletics']    = 'Athletics',
--         ['security']     = 'Security',
--         ['sneak']        = 'Sneak',
--         ['lightarmor']   = 'Lightarmor',
--         ['shortblade']   = 'Shortblade',
--         ['marksman']     = 'Marksman',
--         ['mercantile']   = 'Mercantile',
--         ['speechcraft']  = 'Speechcraft',
--         ['acrobatics']   = 'Acrobatics',
--         ['handtohand']   = 'Handtohand',

-- }
-- local maxWidths         = {
--         name      = 0,
--         magnitude = 0,
--         duration  = 0,
--         area      = 0,
--         range     = 0
-- }
-- local affectedThing
-- local name
-- local mag
-- local duration
-- local area
-- local range




-- local function getStatLayout(statName, statValue)
--         return {
--                 type = ui.TYPE.Flex,
--                 -- template = I.MWUI.templates.borders, --- ################
--                 external = { grow = 0, stretch = 0.5 },
--                 props = {
--                         horizontal = true,
--                 },
--                 content = ui.content {
--                         {
--                                 template = I.MWUI.templates.textNormal,
--                                 props = {
--                                         text = statName,
--                                         textSize = sizes.TOOLTIP_TEXT_SIZE,
--                                 }
--                         },
--                         gui.makeInt(1, 0, 1, 1),
--                         {
--                                 template = I.MWUI.templates.textNormal,
--                                 props = {
--                                         text = statValue,
--                                         textSize = sizes.TOOLTIP_TEXT_SIZE,
--                                 }
--                         },
--                 }
--         }
-- end


-- local function estimateTextWidth(text, min)
--         return math.max(#text * 6, min)
-- end

-- local function createTTText(text, width)
--         return {
--                 type = ui.TYPE.Flex,
--                 -- template = I.MWUI.templates.borders,
--                 props = {
--                         size = util.vector2(width + sizes.TOOLTIP_TEXT_SIZE, 20)
--                 },
--                 content = ui.content {
--                         {
--                                 template = I.MWUI.templates.textNormal,
--                                 props = {
--                                         text = text,
--                                         textSize = sizes.TOOLTIP_TEXT_SIZE,

--                                         -- textSize = 12,

--                                 }
--                         }
--                 }
--         }
-- end

-- ---@param info MagicEffectWithParams
-- local function getEffectInfo(info)
--         affectedThing = info.affectedAttribute or info.affectedSkill
--         name = affectedThing and
--             (affectedNames[info.effect.name] .. ' ' .. affectedAttrSkill[affectedThing]) or info.effect.name

--         mag = info.magnitudeMin == info.magnitudeMax
--             and info.magnitudeMax .. 'p'
--             or info.magnitudeMin .. '-' .. info.magnitudeMax .. 'p'

--         duration = info.duration .. 's'
--         area = (info.area ~= 0) and (info.area .. 'f') or ' - '
--         range = spellRange[info.range]
-- end

-- ---@param effects MagicEffectWithParams[]
-- local function getEffectsTexts(effects, itemType)
--         ---@type ui.Layout[]
--         local effectsTextsList = {}
--         for i, _ in pairs(maxWidths) do
--                 maxWidths[i] = 0
--         end

--         for _, info in pairs(effects) do
--                 getEffectInfo(info)
--                 maxWidths.name = math.max(maxWidths.name, estimateTextWidth(name, 165))
--                 maxWidths.magnitude = math.max(maxWidths.magnitude, estimateTextWidth(mag, 46))
--                 maxWidths.duration = math.max(maxWidths.duration, estimateTextWidth(duration, 46))
--                 maxWidths.area = area ~= '' and math.max(maxWidths.area, estimateTextWidth(area, 30)) or 0
--                 maxWidths.range = math.max(maxWidths.range, estimateTextWidth(range, 0))
--         end

--         for _, info in pairs(effects) do
--                 getEffectInfo(info)

--                 local textLayout = {
--                         -- template = I.MWUI.templates.borders,
--                         type = ui.TYPE.Flex,
--                         props = {
--                                 horizontal = true,
--                         },
--                         content = ui.content {
--                                 -- Icon
--                                 {
--                                         type = ui.TYPE.Image,
--                                         props = {
--                                                 -- anchor = util.vector2(0.5, 0.5),
--                                                 size = util.vector2(13, 13),
--                                                 resource = ui.texture { path = info.effect.icon }
--                                         }
--                                 },
--                                 gui.makeInt(10, 0),
--                         }
--                 }

--                 if itemType == types.Ingredient then
--                         textLayout.content:add(createTTText(name, maxWidths.name))
--                 else
--                         textLayout.content:add(createTTText(name, maxWidths.name))
--                         textLayout.content:add(createTTText(mag, maxWidths.magnitude))
--                         textLayout.content:add(createTTText(duration, maxWidths.duration))
--                         textLayout.content:add(createTTText(area, maxWidths.area))
--                         textLayout.content:add(createTTText(range, maxWidths.range))
--                 end

--                 table.insert(effectsTextsList, textLayout)
--         end

--         if itemType == types.Ingredient then
--                 -- base, damage, modified, modifier, progress
--                 ---@type SkillStat
--                 local playerAlchemy = types.NPC.stats.skills.alchemy(self).modified
--                 local visibleEffects = math.min(math.floor(playerAlchemy / 15), #effectsTextsList)
--                 local hidden = #effectsTextsList - visibleEffects

--                 if hidden > 0 then
--                         for i = hidden - 1, 0, -1 do
--                                 effectsTextsList[#effectsTextsList - i].content = ui.content {
--                                         {
--                                                 template = I.MWUI.templates.textNormal,
--                                                 props = { text = '?' }
--                                         }
--                                 }
--                         end
--                 end
--         end

--         return effectsTextsList
-- end

-- toolTip.currentId = nil

-- ---@param thing GameObject
-- toolTip.showToolTip = function(thing)
--         if not thing then
--                 toolTip.layout = {
--                         name = 'toolTip',
--                         type = ui.TYPE.Flex,
--                         props = {
--                                 anchor = util.vector2(0, 0),
--                                 horizontal = false,
--                         },
--                 }
--                 return
--         end

--         toolTip.currentId = thing.recordId

--         ---@type Record
--         local record = thing.type.record(thing)

--         ---@type ItemData
--         local data = thing.type.itemData(thing)


--         local allStatsLayouts = {}


--         if thing.type == types.Weapon and myTypes.WEAPON_TYPE_TO_TEXT[record.type] then
--                 table.insert(allStatsLayouts,
--                         getStatLayout(
--                                 'Type:',
--                                 string.format('%s', myTypes.WEAPON_TYPE_TO_TEXT[record.type])
--                         )
--                 )
--         end

--         if record.chopMaxDamage then
--                 if RANGED_WEAPON[record.type] then
--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Attack:',
--                                         string.format('%d  -%4d', record.chopMinDamage, record.chopMaxDamage)
--                                 )
--                         )

--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Speed:',
--                                         string.format('%.2f', record.speed)
--                                 )
--                         )
--                 elseif RANGED_AMMO[record.type] then
--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Attack:',
--                                         string.format('%d  -%4d', record.chopMinDamage, record.chopMaxDamage)
--                                 )
--                         )
--                 else
--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Chop:',
--                                         string.format('%d  -%4d', record.chopMinDamage, record.chopMaxDamage)
--                                 )
--                         )
--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Slash:',
--                                         string.format('%d  -%4d', record.slashMinDamage, record.slashMaxDamage)
--                                 )
--                         )
--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Thrust:',
--                                         string.format('%d  -%4d', record.thrustMinDamage, record.thrustMaxDamage)
--                                 )
--                         )
--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Range:',
--                                         string.format('%.2f', record.reach)
--                                 )
--                         )
--                         table.insert(allStatsLayouts,
--                                 getStatLayout(
--                                         'Speed:',
--                                         string.format('%.2f', record.speed)
--                                 )
--                         )
--                 end
--         end

--         if record.baseArmor then
--                 table.insert(allStatsLayouts,
--                         getStatLayout(
--                                 'Rating:',
--                                 string.format('%d', record.baseArmor)
--                         )
--                 )
--         end

--         if data.condition then
--                 table.insert(allStatsLayouts,
--                         getStatLayout(
--                                 'Condition:',
--                                 string.format('%-7d/%7d', data.condition,
--                                         record.maxCondition or record.health or record.duration)
--                         )
--                 )
--         end

--         -- if record.text then
--         --         local newText = string.gsub(record.text, "<.->", "")
--         --         local spaceIndex = string.find(newText, ' ', sizes.BOOK_PREVIEW_LENGTH)
--         --         if spaceIndex ~= nil then
--         --                 newText = string.sub(newText, 1, spaceIndex)
--         --         else
--         --                 newText = string.sub(newText, 1, sizes.BOOK_PREVIEW_LENGTH + 2)
--         --         end
--         --         local pattern = '%%(%S[^.{}<>, \n\t%s]*)'
--         --         newText = newText:gsub(pattern, toolTip.gv)
--         --         newText = breakText(newText, sizes.BOOK_PREVIEW_WORDS_PER_LINE)
--         --         if record.text:len() > sizes.BOOK_PREVIEW_LENGTH then
--         --                 table.insert(allTexts, '%s............')
--         --         else
--         --                 table.insert(allTexts, '%s')
--         --         end
--         --         table.insert(valueFormat, newText)
--         -- end

--         if record.quality then
--                 table.insert(allStatsLayouts,
--                         getStatLayout(
--                                 'Quality:',
--                                 string.format('%.2f', record.quality)
--                         )
--                 )
--         end

--         if record.weight then
--                 table.insert(allStatsLayouts,
--                         getStatLayout(
--                                 'Weight:',
--                                 string.format('%d', record.weight)
--                         )
--                 )
--         end

--         if record.value then
--                 table.insert(allStatsLayouts,
--                         getStatLayout(
--                                 'Value:',
--                                 string.format('%d', record.value)
--                         )
--                 )
--         end

--         ---@type ui.Layout[]
--         local allEffectsTexts = {}
--         local charge
--         if record.enchant then
--                 ---@type Enchantment
--                 local enchantment = core.magic.enchantments.records[record.enchant]
--                 local max = enchantment.charge

--                 if enchantment.type ~= core.magic.ENCHANTMENT_TYPE.CastOnce
--                     and enchantment.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
--                         charge = true
--                 end

--                 --- TYPE
--                 table.insert(allStatsLayouts,
--                         gui.makeInt(0, 10)
--                 )
--                 table.insert(allStatsLayouts,
--                         {
--                                 template = I.MWUI.templates.textNormal,
--                                 props = {
--                                         text = enchantmentTypes[enchantment.type + 1],
--                                         textSize = sizes.TOOLTIP_TEXT_SIZE,
--                                 }
--                         }
--                 )

--                 --- EFFECTS
--                 local effects = enchantment.effects
--                 allEffectsTexts = getEffectsTexts(effects, thing.type)
--         elseif record.effects then
--                 allEffectsTexts = getEffectsTexts(record.effects, thing.type)
--         end

--         local myContent = {
--                 type = ui.TYPE.Flex,
--                 -- template = I.MWUI.templates.bordersThick, --- ################
--                 external = { grow = 1, stretch = 1, },
--                 props = {
--                         relativeSize = util.vector2(1, 1),
--                 },
--                 content = ui.content {
--                         gui.makeInt(0, 8),
--                         {
--                                 template = I.MWUI.templates.textNormal,
--                                 props = {
--                                         text = record.name,
--                                         textColor = colors.header,
--                                         textSize = sizes.TOOLTIP_TEXT_SIZE
--                                 }
--                         },
--                         gui.makeInt(0, 8),

--                         {
--                                 type = ui.TYPE.Flex,
--                                 -- template = I.MWUI.templates.borders, --- ################
--                                 external = { grow = 0, stretch = 1, },
--                                 content = ui.content(allStatsLayouts)
--                         },
--                         gui.makeInt(0, 8),

--                         table.unpack(allEffectsTexts),
--                 }
--         }

--         if charge then
--                 myContent.content:add(gui.makeInt(0, 10))
--                 myContent.content:add(
--                         getStatLayout('Charge:',
--                                 string.format('%-7d/%7d', data.enchantmentCharge,
--                                         core.magic.enchantments.records[record.enchant].charge))
--                 )
--         end


--         local content = {
--                 gui.makeInt(0, PADDING),
--                 {
--                         type = ui.TYPE.Flex,
--                         -- template = I.MWUI.templates.borders, --- ################
--                         external = { grow = 1, stretch = 1, },
--                         props = {
--                                 horizontal = true,
--                         },
--                         content = ui.content {
--                                 gui.makeInt(PADDING, 0),
--                                 myContent,
--                                 gui.makeInt(PADDING, 0),
--                         }
--                 },
--                 gui.makeInt(0, PADDING),
--         }

--         toolTip.layout = {
--                 name = 'toolTip',
--                 type = ui.TYPE.Flex,
--                 -- template = I.MWUI.templates.borders, --- ################
--                 external = { grow = 1, stretch = 1, },
--                 content = ui.content(content)
--         }
-- end

-- toolTip.update = function()
-- end

-- return toolTip
