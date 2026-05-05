I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local core = require('openmw.core')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local v2 = util.vector2
local yesFocus = 0
local noFocus = 0
local asyncYes = nil
local asyncNo = nil
local dialogue = "disenchant"
local currentlyInInventory = false
local previouslyEquippedItems = {}
local currentlyDisenchanting = nil
local inventoryBeforeEnchanting = nil
local shiftPressed = input.isShiftPressed()
local levelGapTimer = nil
local onFrameInitialized = false
onFrameFunctions = {}
---------------------------------------------------------------------------------------------------------------------------------------------- SETTINGS ----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------- SETTINGS ----------------------------------------------------------------------------------------------------------------------------------------------
MODNAME = "Disenchanting"
local Settings = require("scripts.Disenchanting_settings")

-- runtime spell map for custom effects (received by global)
-- vanilla effects use enchantdummy_<id> from the omwaddon
-- only covers generated effects
local enchantSpellMap = {} -- effect.id -> spell.id

local function getEnchantSpellId(effectId)
	-- prefer the baked spell when present (vanilla effects)
	local staticId = "enchantdummy_"..effectId
	if core.magic.spells.records[staticId] then
		return staticId
	end
	return enchantSpellMap[effectId]
end
local EXPERTISE_MULT = S_DISENCHANTING_EXPERTISE_MULT

local function updateSettings()
	if EXPERTISE_MULT ~= S_DISENCHANTING_EXPERTISE_MULT then
		local expertise = 0
		for eff, knowledge in pairs(saveData.effects) do
			if knowledge > 0 then
				expertise = expertise + knowledge + 4
			end
		end
		print("expertise: "..expertise.." * "..S_DISENCHANTING_EXPERTISE_MULT)
		expertise = math.floor(0.5+expertise*S_DISENCHANTING_EXPERTISE_MULT)
		for a,b in pairs(types.Actor.spells(self)) do
			--print(b.id)
			if b.id:sub(1,#"disenchanting_expertise_") == "disenchanting_expertise_" then
				types.Actor.spells(self):remove(b.id)
			end
		end
		expertise = math.min(255,expertise)
		local power = 0
		while expertise > 0 do
			if expertise % 2 == 1 and expertise < 255 then
				local spellId = "disenchanting_expertise_"..math.floor(2^power)
				--print(spellId)
				types.Actor.spells(self):add(spellId)
			end
			expertise = math.floor(expertise / 2)
			power = power + 1
		end
	end
	EXPERTISE_MULT = S_DISENCHANTING_EXPERTISE_MULT
end
Settings.subscribe(updateSettings)


---------------------------------------------------------------------------------------------------------------------------------------------- LIBRARIES ----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------- LIBRARIES ----------------------------------------------------------------------------------------------------------------------------------------------
local makeTooltip = require("scripts.Disenchanting_tooltip")
local disenchant = require("scripts.Disenchanting_disenchant")
local makeBorder = require("scripts.Disenchanting_makeborder")
local BORDER_STYLE = "thin" --"none", "thin", "normal", "thick", "verythick"
local borderOffset = BORDER_STYLE == "verythick" and 4 or BORDER_STYLE == "thick" and 3 or BORDER_STYLE == "normal" and 2 or (BORDER_STYLE == "thin" or BORDER_STYLE == "max performance") and 1 or 0
local borderFile = "thin"
if BORDER_STYLE == "verythick" or BORDER_STYLE == "thick" then
	borderFile = "thick"
end
local borderTemplate = makeBorder(borderFile, borderColor or nil, borderOffset, {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			relativeSize  = v2(1,1),
			alpha = OPACITY,
		}
	}).borders
	
local textureCache = {}

local function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

local function round(num)
	return math.floor(num+0.5)
end

function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        print("UNEXPECTED COLOR: rgb of size=", #rgb)
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end
local fontColor = getColorFromGameSettings("FontColor_color_normal_over")
local darkerFont = util.color.rgb(fontColor.r*0.3,fontColor.g*0.3,fontColor.b*0.3)

---------------------------------------------------------------------------------------------------------------------------------------------- UI ----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------- UI ----------------------------------------------------------------------------------------------------------------------------------------------

local function applyYesColor()
	if yesFocus > 2 then
		--print("error focus")
	elseif yesFocus == 2 then
		dia.layout.content.yesBox.props.color = util.color.rgb(darkerFont.r*0.9,math.min(1,darkerFont.g+0.2),darkerFont.b*0.9)
	elseif yesFocus == 1 then
		dia.layout.content.yesBox.props.color = darkerFont
	else
		dia.layout.content.yesBox.props.color = util.color.rgb(0, 0, 0)
	end
	dia:update()
end

local function applyNoColor()
	if noFocus > 2 then
		--print("error focus")
	elseif noFocus == 2 then
		dia.layout.content.noBox.props.color = util.color.rgb(math.min(1,darkerFont.r+0.2),darkerFont.g*0.9,darkerFont.b*0.9)
	elseif noFocus == 1 then
		dia.layout.content.noBox.props.color = darkerFont
	else
		dia.layout.content.noBox.props.color = util.color.rgb(0, 0, 0)
	end
	dia:update()
end

local function yes()
if not dia then return end
	asyncYes = true
	yesFocus = 0
	applyYesColor()
end

local function no()
if not dia then return end
	asyncNo = true
	noFocus = 0
	applyNoColor()
end

local function yesPress()
--print("yesPress")
focus = "yes"
yesFocus = yesFocus + 1
applyYesColor()
end
local function noPress()
--print("noPress")
focus = "no"
noFocus = noFocus + 1
applyNoColor()
end

local function yesFocusGain()
--print("yesGain")
focus = "yes"
yesFocus = yesFocus + 1
applyYesColor()
end
local function noFocusGain()
--print("noGain")
focus = "no"
noFocus = noFocus +1
applyNoColor()
end

local function yesFocusLoss()
--print("yesLoss")
focus = nil
yesFocus = 0
applyYesColor()
end
local function noFocusLoss()
--print("noLoss")
focus = nil
noFocus = 0
applyNoColor()
end



---------------------------------------------------------------------------------------------------------------------------------------------- DISENCHANT DIALOGUE ----------------------------------------------------------------------------------------------------------------------------------------------

local function disenchantDialogue()
	dialogue = "disenchant"
	local itemName = currentlyDisenchanting.type.record(currentlyDisenchanting).name
	local preview = disenchant(currentlyDisenchanting, true, self)
	local layerId = ui.layers.indexOf("HUD")
	local screenSize = ui.layers[layerId].size
	local containerSize = v2(screenSize.x * 0.15, screenSize.y * 0.1)
	dia = ui.create {
		template = borderTemplate,
		layer = 'Modal',
		props = {
			size = containerSize,
			anchor = util.vector2(0.5, 0),
			position =v2(screenSize.x * 0.5, screenSize.y * 0.45),
		},
		
		userData = {isPressed = false},
		
		content = ui.content {
			{
				name = 'background',
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(1, 1),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = 0.8,
				},
			},
			{
				name = 'questionText',
				type = ui.TYPE.Text,
				props = {
					relativePosition = util.vector2(0.5, 0.1),
					anchor = util.vector2(.5, .5),
					text = "Disenchant?",
					textColor = fontColor,
					textSize = 18,
				}
			},
			{
				name = 'yesBox',
				template = borderTemplate,
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = .75,
				},
			},
			{
				name = 'yesText',
				type = ui.TYPE.Text,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
					text =core.getGMST("sYes"),
					textColor = fontColor,
					textSize = 18,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
				},
			},
			{
				name = 'noBox',
				template = borderTemplate,
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = .75,
				},
			},
			{
				name = 'noText',
				type = ui.TYPE.Text,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
					text = core.getGMST("sNo"),
					textColor = fontColor,
					textSize = 18,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
				},
			},
			{ -- no clickbox
				props = 
				{ 
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
				},
				events = {
					mouseRelease = async:callback(no),
					focusGain = async:callback(noFocusGain),
					focusLoss = async:callback(noFocusLoss),
					mousePress = async:callback(noPress),
				},
			},
			{ -- yes clickbox
				props = 
				{ 
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
				},
				events = {
					mouseRelease = async:callback(yes),
					focusGain = async:callback(yesFocusGain),
					focusLoss = async:callback(yesFocusLoss),
					mousePress = async:callback(yesPress),
				},
			}
		},
	}
	local function makeIcon(enchBackground, icon, innerText, props)

		local iconBox ={
			template = borderTemplate,
			props = props,
			content = ui.content{}
		}
		
		if enchBackground then 
			--ENCHANT ICON
			table.insert(iconBox.content, {
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures\\menu_icon_magic_mini.dds"),
					tileH = false,
					tileV = false,
					relativeSize = v2(1,1),
					alpha = 0.7,
				}
			})			
		end
		-- ITEM ICON
		table.insert(iconBox.content, {
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(icon),
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				alpha = 0.7,
			}
		})
		if innerText then
			table.insert(iconBox.content,{
				type = ui.TYPE.Text,
				name = 'inner',
				props = {
					relativePosition = util.vector2(0, 1),
					relativeSize = util.vector2(1, 0.5),
					anchor = util.vector2(0, 1),
					text = ""..innerText,
					textColor = fontColor,--util.color.rgba(1, 1, 1, 1),
					--textAlignH = ui.ALIGNMENT.Center,
					textSize = 19,
				}
			})
		end
		return iconBox
	end
	local thingRecord = currentlyDisenchanting.type.record(currentlyDisenchanting)
	local icon = thingRecord.icon
	--local ench = currentlyDisenchanting and (currentlyDisenchanting.enchant or thingRecord.enchant ~= "" and thingRecord.enchant )
	--
	--
	--dia.layout.content:add(makeIcon(ench, icon, "", {
	--	position = v2(containerSize.x * 0.25,containerSize.y * 0.45),
	--	size = v2(containerSize.y * 0.4,containerSize.y * 0.4),
	--	anchor = v2(0.5,0.5)
	--}))
	local newEffects = {}
	local countNewEffects = 0
	for a,b in pairs(preview.effects) do
		--print(saveData.effects[b.id] ,getEnchantSpellId(b.id),newEffects[b.id])
		--local mgef = core.magic.effects.records[core.magic.EFFECT_TYPE[b.id]]
		if (not saveData.effects[b.id] or saveData.effects[b.id] == 0)
		and getEnchantSpellId(b.id)
		and not newEffects[b.id]
		then
			newEffects[b.id] = b
			countNewEffects = countNewEffects + 1
		end
	end
	
	if countNewEffects > 0 then
		-- Parameters
		local available_width = containerSize.x * 0.37
		local icon_size = containerSize.y * 0.4
		local num_icons = countNewEffects
		local icon_gap = math.max(3, 10-num_icons*2)
		
		-- Compute total width required without squishing
		local total_gap = icon_gap * (num_icons - 1)
		local total_icon_width = icon_size * num_icons
		local needed_width = total_icon_width + total_gap
		
		-- Adjust icon size if needed
		local final_icon_size = icon_size
		if needed_width > available_width then
			final_icon_size = (available_width - total_gap) / num_icons
		end
		
		-- Compute starting x position to center the icons
		local total_width = final_icon_size * num_icons + icon_gap * (num_icons - 1)
		local start_x = (available_width - total_width) / 2
		
		-- Generate icon positions
		local icon_positions = {}
		for i = 0, num_icons - 1 do
			local x = start_x + i * (final_icon_size + icon_gap)
			table.insert(icon_positions, { x = x, size = final_icon_size })
		end
		
		-- Render icons
		local i = 1
		for id, tbl in pairs(newEffects) do
			dia.layout.content:add(makeIcon(ench, tbl.icon, "", {
				position = v2(icon_positions[i].x+6,containerSize.y * 0.45),
				size = v2(icon_positions[i].size,icon_positions[i].size),
				anchor = v2(0,0.5)
			}))
			i=i+1
		end
	end
	
	dia.layout.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures\\disenchanting\\arrow2.dds"),
					tileH = false,
					tileV = false,
					alpha = 0.9,
					position = v2(containerSize.x * 0.49,containerSize.y * 0.45),
					size = v2(containerSize.y * 0.4,containerSize.y * 0.4),
					anchor = v2(0.5,0.5),
					color = fontColor,
				}
			}
	
	if preview.soulgem and preview.value then
		dia.layout.content:add(makeIcon(nil, icon, math.floor(preview.newCapacity+0.5), {
			position = v2(containerSize.x * 0.7,containerSize.y * 0.45),
			size = v2(containerSize.y * 0.4,containerSize.y * 0.4),
			anchor = v2(0.5,0.5)
		}))
		dia.layout.content:add(makeIcon(nil, types.Miscellaneous.record(preview.soulgem).icon, math.floor(preview.soulSize+0.5), {
			position = v2(containerSize.x * 0.87,containerSize.y * 0.45),
			size = v2(containerSize.y * 0.4,containerSize.y * 0.4),
			anchor = v2(0.5,0.5)
		}))
	elseif preview.value then
		dia.layout.content:add(makeIcon(nil, icon, math.floor(preview.newCapacity+0.5), {
			position = v2(containerSize.x * 0.75,containerSize.y * 0.45),
			size = v2(containerSize.y * 0.4,containerSize.y * 0.4),
			anchor = v2(0.5,0.5)
		}))
	elseif preview.soulgem then
		dia.layout.content:add(makeIcon(nil, types.Miscellaneous.record(preview.soulgem).icon, math.floor(preview.soulSize+0.5), {
			position = v2(containerSize.x * 0.75,containerSize.y * 0.45),
			size = v2(containerSize.y * 0.4,containerSize.y * 0.4),
			anchor = v2(0.5,0.5)
		}))
	end
	tooltip = makeTooltip(currentlyDisenchanting, S_VALUE_MULT, util.color.rgb(1,0,0))

end



---------------------------------------------------------------------------------------------------------------------------------------------- CONSUME DIALOGUE ----------------------------------------------------------------------------------------------------------------------------------------------

-- a filled soulgem with a known creature soul
local function isFilledSoulgem(item)
	if not item or not item.recordId then return false end
	if item.recordId:sub(1, #"misc_soulgem_") ~= "misc_soulgem_" then return false end
	local soul = types.Item.itemData(item).soul
	if not soul then return false end
	return types.Creature.records[soul] ~= nil
end

-- petty/lesser/common gems consume the whole stack
local function shouldStackConsume(item)
	if not item or not item.recordId then return false end
	local id = item.recordId
	return id:sub(1, #"misc_soulgem_petty") == "misc_soulgem_petty"
		or id:sub(1, #"misc_soulgem_lesser") == "misc_soulgem_lesser"
		or id:sub(1, #"misc_soulgem_common") == "misc_soulgem_common"
end

local function consumeDialogue()
	dialogue = "consume"
	local itemName = currentlyConsuming.type.record(currentlyConsuming).name
	
	if currentlyConsuming.recordId == "misc_soulgem_azura" then
		itemName = "Soul"
	end
	-- stack consume mode: petty/lesser/common eat the whole stack at once
	local stackCount = 1
	if shouldStackConsume(currentlyConsuming) and currentlyConsuming.count > 1 then
		stackCount = currentlyConsuming.count
		dialogue = "consumeStack"
	end
	local title = stackCount > 1
		and ("Consume "..stackCount.." "..itemName.."?")
		or ("Consume "..itemName.."?")
	local layerId = ui.layers.indexOf("HUD")
	local screenSize = ui.layers[layerId].size
	local containerSize = v2(screenSize.x * 0.15, screenSize.y * 0.1)
	dia = ui.create {
		template = borderTemplate,
		layer = 'Modal',
		props = {
			size = containerSize,
			anchor = util.vector2(0.5, 0),
			position =v2(screenSize.x * 0.5, screenSize.y * 0.45),
		},
		
		userData = {isPressed = false},
		
		content = ui.content {
			{
				name = 'background',
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(1, 1),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = 0.8,
				},
			},
			{
				name = 'questionText',
				type = ui.TYPE.Text,
				props = {
					relativePosition = util.vector2(0.5, 0.1),
					anchor = util.vector2(.5, .5),
					text = title,
					textColor = fontColor,
					textSize = 18,
				}
			},
			{
				name = 'yesBox',
				template = borderTemplate,
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = .75,
				},
			},
			{
				name = 'yesText',
				type = ui.TYPE.Text,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
					text = core.getGMST("sYes"),
					textColor = fontColor,
					textSize = 18,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
				},
			},
			{
				name = 'noBox',
				template = borderTemplate,
				type = ui.TYPE.Image,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
					resource = ui.texture { path = 'white' },
					color = util.color.rgb(0, 0, 0),
					alpha = .75,
				},
			},
			{
				name = 'noText',
				type = ui.TYPE.Text,
				props = {
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
					text = core.getGMST("sNo"),
					textColor = fontColor,
					textSize = 18,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
				},
			},
			{ -- no clickbox
				props = 
				{ 
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.75,0.85),
					anchor = v2(0.5,0.5),
				},
				events = {
					mouseRelease = async:callback(no),
					focusGain = async:callback(noFocusGain),
					focusLoss = async:callback(noFocusLoss),
					mousePress = async:callback(noPress),
				},
			},
			{ -- yes clickbox
				props = 
				{ 
					relativeSize = util.vector2(0.3, 0.2),
					relativePosition = v2(0.25,0.85),
					anchor = v2(0.5,0.5),
				},
				events = {
					mouseRelease = async:callback(yes),
					focusGain = async:callback(yesFocusGain),
					focusLoss = async:callback(yesFocusLoss),
					mousePress = async:callback(yesPress),
				},
			}
		},
	}
		local function makeIcon(enchBackground, icon, innerText, props)

		local iconBox ={
			template = borderTemplate,
			props = props,
			content = ui.content{}
		}
		
		if enchBackground then 
			--ENCHANT ICON
			table.insert(iconBox.content, {
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures\\menu_icon_magic_mini.dds"),
					tileH = false,
					tileV = false,
					relativeSize = v2(1,1),
					alpha = 0.7,
				}
			})			
		end
		-- ITEM ICON
		table.insert(iconBox.content, {
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(icon),
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				alpha = 0.7,
			}
		})
		if innerText then
			table.insert(iconBox.content,{
				type = ui.TYPE.Text,
				name = 'inner',
				props = {
					relativePosition = util.vector2(0, 1),
					relativeSize = util.vector2(1, 0.5),
					anchor = util.vector2(0, 1),
					text = ""..innerText,
					textColor = fontColor,--util.color.rgba(1, 1, 1, 1),
					--textAlignH = ui.ALIGNMENT.Center,
					textSize = 19,
				}
			})
		end
		return iconBox
	end

	local textSizeMult = ui.screenSize().y /1200*0.7
	local itemFontSize = 19
	local tooltipTextAlignment = ui.ALIGNMENT.Center
	local ICON_TINT = getColorFromGameSettings("FontColor_color_normal_over")
	local FONT_TINT = getColorFromGameSettings("FontColor_color_normal")
	local soul= types.Item.itemData(currentlyConsuming).soul and types.Creature.records[types.Item.itemData(currentlyConsuming).soul]
	if not soul then
		dia:destroy()
		dia = nil
		currentlyConsuming = nil
		return
	end
	local soulValue = soul.soulValue
	if currentlyConsuming.recordId == "misc_soulgem_azura" then
		soulValue = soulValue*0.7
	end
	soul = soul.name


	local record = currentlyConsuming.type.record(currentlyConsuming)
	local icon = record.icon
	local name = record.name.." ("..soul..")"
	local weight = record.weight
	local skillGain = soulValue^S_EXPERIENCE_EXP * S_EXPERIENCE_MULT2 + S_EXPERIENCE_ADD2
	skillGain = skillGain * S_CONSUME_MULT
	local skill = types.Player.stats.skills.enchant(self).base
	skillGain = skillGain*math.min(1,0.5+skill/200)
	local progressRequirement = I.SkillProgression.getSkillProgressRequirement('enchant')
	local progressPct = skillGain/progressRequirement
	local value = record.value
	if S_SOUL_PRICE_REBALANCE then
		value = math.floor(0.0001 * soulValue ^ 3 + 2 * soulValue)
	else
		value = math.floor(value * soulValue)
	end
	-- scale displays by stack size when consuming the whole stack
	value = value * stackCount
	progressPct = progressPct * stackCount
	local flex = {
		type = ui.TYPE.Flex,
		layer = 'HUD',
		name = 'tooltipFlex',
		props = {
			autoSize = true,
			arrange = tooltipTextAlignment,
			relativePosition = v2(0.5,0.43),
			anchor = v2(0.5,0.5),
		},
		content = ui.content {
		}
	}
	dia.layout.content:add(flex)
	local function textElement(str, color)
		flex.content:add { 
			type = ui.TYPE.Text,
			template = {
				props = {
						textColor = FONT_TINT,--util.color.rgba(1, 1, 1, 1),
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,0.75),
						textAlignV = ui.ALIGNMENT.Center,
						textAlignH = ui.ALIGNMENT.Center,
				}
			},
			props = {
				text = " "..str.." ",
				textSize = itemFontSize*textSizeMult,
				textAlignH = ui.ALIGNMENT.End,
				textColor = color,
				autoSize = true
			},
		}
	end
	--textElement(name, ICON_TINT)
	if value and value > 0 and itemName ~= "Soul" then
		textElement(core.getGMST("sValue")..": ".. value)
	end
	textElement(core.getGMST("sSoulGem")..": "..soul.." ("..soulValue..")")
	
	--if weight and weight > 0 then
	--	textElement(core.getGMST("sWeight")..": ".. weight)
	--end
	
	textElement(core.getGMST("sNotifyMessage38").." "..math.floor(progressPct*100).."%")
	
	
	dia.layout.content:add(makeIcon(nil, icon, nil, {
		position = v2(containerSize.x * 0.5,containerSize.y * 0.97),
		size = v2(containerSize.y * 0.27,containerSize.y * 0.27),
		anchor = v2(0.5,1)
	}))
	
	require("scripts.Disenchanting_consumeAllButton")

end

---------------------------------------------------------------------------------------------------------------------------------------------- INVENTORY EXTENDER ----------------------------------------------------------------------------------------------------------------------------------------------

local ieIntegrationDone = false
local ieEnchantMode = false
local icon
local magicBg
local btn
local ctx
local invWin

local function applyButtonVisuals(on)
	if on then
		icon.props.alpha = 0.95
		magicBg.props.alpha = 0.7
	else
		icon.props.alpha = 0.95
		magicBg.props.alpha = 0
	end
end

local function setupInventoryExtenderButton()
	if not I.InventoryExtender or not I.InventoryExtender.getWindow or not I.InventoryExtender.registerRowClickHandler then
		return false
	end
	invWin = I.InventoryExtender.getWindow('Inventory')
	if not invWin or not invWin.infoBar or not invWin.ctx then return false end

	ctx = invWin.ctx

	local function isDisenchantable(item)
		if not item then return false end
		local record = item.type.record(item)
		if item.recordId:lower():find("bound") and record.value == 0 then return false end
		return record.enchant ~= nil and record.enchant ~= ""
	end

	local soulgemRec = types.Miscellaneous.records["misc_soulgem_greater"]
	local soulgemIconPath = soulgemRec and soulgemRec.icon or "icons/m/misc_soulgem_greater.dds"
	local btnSize = 28
	local enchantFrame = ui.texture {
		path = "textures/menu_icon_magic.dds",
		size = v2(40, 40),
		offset = v2(2, 2),
	}
	icon = {
		type = ui.TYPE.Image,
		props = {
			resource = getTexture(soulgemIconPath),
			relativeSize = v2(1, 1),
			alpha = 0.95,
		},
	}
	magicBg = {
		name = "magicBg",
		type = ui.TYPE.Image,
		props = {
			resource = enchantFrame,
			relativeSize = v2(1, 1),
		},
	}
	applyButtonVisuals(false)
	
	btn = {
		props = { size = v2(btnSize, btnSize) },
		content = ui.content {
			magicBg,
			icon,
		},
		events = {
			focusGain = async:callback(function()
				applyButtonVisuals(true)
				ctx.updateQueue[invWin.infoBar] = true
			end),
			focusLoss = async:callback(function()
				-- stay lit while instant-disenchant mode is active
				if ieEnchantMode then return end
				applyButtonVisuals(false)
				ctx.updateQueue[invWin.infoBar] = true
			end),
			mousePress = async:callback(function(e)
				if e.button == 1 then
					ambient.playSound("menu click")
				end
			end),
			mouseRelease = async:callback(function(e)
				if e.button ~= 1 or dia then return end
				local item = ctx.dragAndDrop.draggingObject
				if item then
					-- disenchant dialogue
					if isDisenchantable(item) then
						currentlyDisenchanting = item
						ctx.dragAndDrop:stopDrag()
						disenchantDialogue()
					-- consume dialogue
					elseif isFilledSoulgem(item) then
						currentlyConsuming = item
						ctx.dragAndDrop:stopDrag()
						consumeDialogue()
					end
				else
					-- no drag: toggle instant-action mode.
					ieEnchantMode = not ieEnchantMode
					applyButtonVisuals(ieEnchantMode)
				end
			end),
		},
	}

	invWin.infoBar.layout.userData.addInfoLayout(btn)

	-- ---------- enchant capacity in tooltip ----------
	if I.InventoryExtender.registerTooltipModifier and I.InventoryExtender.Templates and I.InventoryExtender.Templates.BASE then
		local IE_BASE = I.InventoryExtender.Templates.BASE
		local capIcon = IE_BASE.createTexture("textures/menu_icon_magic.dds")
		I.InventoryExtender.registerTooltipModifier("Disenchanting_Capacity", function(item, layout)
			if not S_SHOW_CAPACITY_IN_IE_TOOLTIP == "Never" or S_SHOW_CAPACITY_IN_IE_TOOLTIP == "Hold Shift" and not input.isShiftPressed() then return layout end
			local record = item.type.record(item)
			if not record.enchantCapacity or record.enchantCapacity <= 0 then return layout end
			-- skip already-enchanted items (capacity is irrelevant)
			if record.enchant and record.enchant ~= "" then return layout end
			if S_SHOW_CAPACITY_IN_IE_TOOLTIP == "On Drained" and not saveData.drainedRecords[item.recordId] then return layout end
			local ok, inner = pcall(function() return layout.content.padding.content.tooltip.content end)
			if not ok or not inner then return layout end

			-- displayed capacity in the same units used elsewhere
			local capacity = math.floor(record.enchantCapacity / 0.1 * core.getGMST("FEnchantmentMult"))

			-- condensed mode: append to existing weightValue flex
			if inner:indexOf('weightValue') and inner.weightValue and inner.weightValue.content then
				local flex = inner.weightValue.content
				if #flex > 0 then
					table.insert(flex, 1, IE_BASE.intervalH(4))
				end
				-- capacity value
				table.insert(flex, 1,{
					template = IE_BASE.textNormal,
					props = { text = ' ' .. capacity },
				})
				-- magic icon
				table.insert(flex, 1,{
					type = ui.TYPE.Image,
					props = {
						size = v2(16, 16),
						resource = ui.texture{path = "textures/disenchanting/menu_icon_magic.dds"},
					},
				})
			else
				-- non-condensed: add a separate line after value/weight
				inner:add({
					name = 'enchantCapacity',
					template = IE_BASE.textNormal,
					props = { text = "Capacity: " .. capacity },
				})
			end
			return layout
		end)
	end

	-- in instant-action mode, clicking any inventory row disenchants/consumes the item immediately
	I.InventoryExtender.registerRowClickHandler("disenchanting_instant", function(row, ieCtx)
		if not ieEnchantMode or dia then return end
		-- if the player is mid-drag, let the default drop/take handler run
		if isDisenchantable(row.item) then
			core.sendGlobalEvent("disenchanting_disenchant", { self, row.item })
			return false
		elseif isFilledSoulgem(row.item) then
			core.sendGlobalEvent("disenchanting_deleteSoulgemStack", { self, row.item })
			return false
		end
		
	end)

	return true
end

---------------------------------------------------------------------------------------------------------------------------------------------- LOGIC ----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------- LOGIC ----------------------------------------------------------------------------------------------------------------------------------------------

local function onFrame(dt)
	-- setup inventory extender after 1 frame
	if not ieIntegrationDone then
		ieIntegrationDone = setupInventoryExtenderButton()
	end
	if not onFrameInitialized then
		creatures = {}
		for a,b in pairs(types.Creature.records) do
			if b.name ~= "" and not b.name:lower():find("deprecated") then
				table.insert(creatures, {b.id, b.soulValue})
			end
		end
		table.sort(creatures, function(a,b) return a[2]<b[2] end)
		--for a,b in pairs(creatures) do
		--	print(b[1],b[2])
		--end
		
		bestInSlot = {}
		for _, cat in pairs{
			types.Armor,
			types.Weapon,
			types.Clothing
		} do
			local records = cat.records
			local catString = tostring(cat)
			for _,record in pairs(records) do
				if record.id:sub(1, #"Generated") ~= "Generated" and not record.id:lower():find("_uni") and not record.enchant then --wabbajack fixed t_dae_uni_wabbajack
					bestInSlot[catString.."-"..record.type] = math.max((bestInSlot[catString.."-"..record.type] or 0), record.enchantCapacity)
				end
			end
		end
		onFrameInitialized = true
	end
	if enchantingFinished and core.getRealTime() > enchantingFinished then
		if inventoryBeforeEnchanting then
			local newItems = {}
			local removedItems = {}
			local inventoryAfterEnchanting = {}
			for _,item in pairs(types.Actor.inventory(self):getAll()) do
				inventoryAfterEnchanting[item.id] = item
			end
			for _,tbl in pairs(inventoryBeforeEnchanting) do
				local item = tbl.item
				if (not inventoryAfterEnchanting[item.id] or inventoryAfterEnchanting[item.id].count < tbl.count) and not types.Miscellaneous.objectIsInstance(item) then
					--print("removed "..item.recordId)
					table.insert(removedItems, item)
				end
			end
			for _,item in pairs(types.Actor.inventory(self):getAll()) do
				if not inventoryBeforeEnchanting[item.id] and not types.Miscellaneous.objectIsInstance(item) then
					--print("added "..item.recordId)
					table.insert(newItems, item)
				end
			end
			for _,newItem in pairs(newItems) do
				for _, removedItem in pairs(removedItems) do
					if newItem.type == removedItem.type then
						local newRecord = newItem.type.record(newItem)
						local removedRecord = removedItem.type.record(removedItem)
						local newEnchant = newRecord.enchant and newRecord.enchant ~= ""
						local removedEnchant = removedRecord.enchant and removedRecord.enchant ~= ""
						if newRecord.icon == removedRecord.icon and newRecord.model == removedRecord.model and newEnchant and not removedEnchant then
							print("match: "..removedItem.recordId)
							local type = newRecord.type
							local wTypes = types.Weapon.TYPE
							if removedItem.recordId == "sc_paper plain" then
								core.sendGlobalEvent("disenchanting_multiplyPaper", {self,newItem,S_PAPER_MULT})
							elseif type ~= wTypes.Arrow and type ~= wTypes.Bolt and type ~= wTypes.MarksmanThrown then
								core.sendGlobalEvent("disenchanting_fixCapacity", {self,newItem,removedRecord.enchantCapacity})
							end
						end
					end
				end
			end
		end
		enchantingFinished = nil
	end
	for _, f in pairs(onFrameFunctions) do
		f(dt)
	end
	
	if disenchantingSpellTimer and  core.getRealTime() > disenchantingSpellTimer then
		local cameraPos = camera.getPosition()
		local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
		local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
		local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
		if (telekinesis) then
			activationDistance = activationDistance + (telekinesis.magnitude * 22);
		end
		activationDistance = activationDistance+0.1
		local res = nearby.castRenderingRay(
			cameraPos,
			cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
			{ ignore = self }
		)
		if res.hitObject and types.Item.objectIsInstance(res.hitObject) then
			local record = res.hitObject.type.record(res.hitObject)
			if not (res.hitObject.recordId:lower():find("bound") and record.value == 0) then
				if record.type ~= types.Weapon.TYPE.Bolt and record.type ~= types.Weapon.TYPE.Arrow and record.type ~= types.Weapon.TYPE.MarksmanThrown then
					core.sendGlobalEvent("disenchanting_disenchantWorldItem",{self, res.hitObject})
				end
			end
		end
		disenchantingSpellTimer = nil
	end
	
	
	--if levelGapTimer and core.getRealTime() > levelGapTimer then
	--	types.Player.stats.skills.enchant(self).base = 99 + levelGap
	--	print("after: level "..(99 + levelGap))
	--	levelGap = 0
	--	levelGapTimer = nil
	--end
	if not currentlyInInventory then return end
	local newShift = input.isShiftPressed()
	if newShift ~= shiftPressed then
		if S_CONSUME_MULT > 0 then
			core.sendGlobalEvent("disenchanting_shiftToggled", {self,newShift})
		else
			core.sendGlobalEvent("disenchanting_shiftToggled", {self,false})
		end
		shiftPressed = newShift
	end
	if dia then
		if asyncYes and focus == "yes" then
			if dialogue == "consume" then
				core.sendGlobalEvent("disenchanting_deleteSoulgem", {self,currentlyConsuming})
			elseif dialogue == "consumeStack" then
				core.sendGlobalEvent("disenchanting_deleteSoulgemStack", {self,currentlyConsuming})
			else
				core.sendGlobalEvent("disenchanting_disenchant", {self,currentlyDisenchanting})
			end
			currentlyDisenchanting = nil
			currentlyConsuming = nil
			dia:destroy()
			dia = nil
			if tooltip then
				tooltip:destroy()
				tooltip = nil
			end
			if consumeAllButton then
				consumeAllButton:destroy()
				consumeAllButton = nil
			end
		elseif asyncNo and focus == "no" then
			dia:destroy()
			dia = nil
			currentlyDisenchanting = nil
			currentlyConsuming = nil
			if tooltip then
				tooltip:destroy()
				tooltip = nil
			end
			if consumeAllButton then
				consumeAllButton:destroy()
				consumeAllButton = nil
			end
			-- yes-path refreshes IE via finishedDisenchanting/finishedConsuming; cancel must do it too
			if I.InventoryExtender then
				if I.InventoryExtender.registerRowActivateHandler or I.InventoryExtender.VERSION > 1 then
					self:sendEvent('IE_Update')
				else
					self:sendEvent('MI_Update')
				end
			end
		end
		asyncYes = nil
		asyncNo = nil
	end
	local equippedItems = types.Actor.getEquipment(self)
	--for _, thing in pairs(types.Player.inventory(self):getAll()) do
	--	if types.Actor.hasEquipped(self,thing) then
	--		equippedItems[thing.id] = thing
	--	end
	--end
	if input.isShiftPressed() and not dia then
		--local equippedItem = nil
		--for slot, thing in pairs(equippedItems) do
		--	if previouslyEquippedItems[slot] ~= thing  then
		--		equippedItem = thing
		--		break
		--	end
		--end
		
		local equippedItem = nil
		local currentRings = {equippedItems[12], equippedItems[13]}
		local prevRings = {previouslyEquippedItems[12], previouslyEquippedItems[13]}
		
		for _, ring in ipairs(currentRings) do
			if ring and ring ~= prevRings[1] and ring ~= prevRings[2] then
				equippedItem = ring
				break
			end
		end
		
		if not equippedItem then
			for slot, thing in pairs(equippedItems) do
				if slot ~= 12 and slot ~= 13 and previouslyEquippedItems[slot] ~= thing then
					equippedItem = thing
					break
				end
			end
		end
		
		
		
		if equippedItem then
			local record = equippedItem.type.record(equippedItem)
			if not (equippedItem.recordId:lower():find("bound") and record.value == 0) then
				if record.type ~= types.Weapon.TYPE.Bolt and record.type ~= types.Weapon.TYPE.Arrow and record.type ~= types.Weapon.TYPE.MarksmanThrown then
					local enchantment = equippedItem and (record.enchant or record.enchant ~= "" and record.enchant )
					if enchantment then
						currentlyDisenchanting = equippedItem
						disenchantDialogue()
						types.Actor.setEquipment(self, previouslyEquippedItems)
						equippedItems = previouslyEquippedItems
						I.UI.setMode()
						I.UI.setMode('Interface')
					end
				end
			end
		end
	end

	previouslyEquippedItems = equippedItems
end

local function consumeQuestion(item)
	if input.isShiftPressed() and not dia then
		currentlyConsuming = item
		consumeDialogue()
		--I.UI.setMode()
		--I.UI.setMode('Interface')
	end
end
local function f1(num)
	return string.format("%.1f",num)
end

local function grantExp(skillGain)
	local skill = types.Player.stats.skills.enchant(self).base
	if skill >= 100 and not S_UNCAPPER then
		return
	end
	
	if saveData.experience and saveData.experience > 0 then
		print("(+ "..f1(saveData.experience or 0).." xp from cache)")
		skillGain = skillGain + (saveData.experience or 0)
		saveData.experience = 0
	end
	
	local levelTotalExp = I.SkillProgression.getSkillProgressRequirement('enchant')
	local progress = types.Player.stats.skills.enchant(self).progress * levelTotalExp
	
	while progress + skillGain > levelTotalExp do
		local xpForLevelUp = levelTotalExp - progress
		print("+"..f1(xpForLevelUp).."xp (levelup)")
		
		if skill >= 100 then
			types.Actor.stats.level(self).skillIncreasesForAttribute.intelligence = types.Actor.stats.level(self).skillIncreasesForAttribute.intelligence + 1
			types.Player.stats.skills.enchant(self).base = skill + 1
			ambient.playSound("skillraise")
		else
			I.SkillProgression.skillLevelUp('enchant', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
		end
		
		skillGain = skillGain - xpForLevelUp
		levelTotalExp = I.SkillProgression.getSkillProgressRequirement('enchant')
		
		-- progress does not automatically reset above 100 or with ncgd
		types.Player.stats.skills.enchant(self).progress = 0
		progress = 0
		skill = skill + 1
	end
	
	if skill >= 100 then
		print("+"..f1(skillGain).."xp cached")
		saveData.experience = (saveData.experience or 0) + skillGain
		levelGapTimer = core.getRealTime() + 0.3
	else
		print("+"..f1(skillGain).."xp")
		I.SkillProgression.skillUsed('enchant', {skillGain=skillGain, useType = 2, scale = 1})
	end
	
	progress = types.Player.stats.skills.enchant(self).progress * levelTotalExp
	print("now", f1(progress).."+"..f1(saveData.experience or 0).." / "..f1(levelTotalExp))
end

local function refreshAfterConsume()
	if I.UI.getMode() ~= 'Interface' then return end
	if I.InventoryExtender then
		if I.InventoryExtender.registerRowActivateHandler or I.InventoryExtender.VERSION > 1 then
			self:sendEvent('IE_Update')
		else
			self:sendEvent('MI_Update')
		end
	else
		I.UI.setMode()
		I.UI.setMode('Interface')
	end
end

local function finishedConsuming(soulValue)
	local skillGain = soulValue^S_EXPERIENCE_EXP * S_EXPERIENCE_MULT2 + S_EXPERIENCE_ADD2
	local skill = types.Player.stats.skills.enchant(self).base
	skillGain = skillGain * S_CONSUME_MULT * math.min(1,0.5+skill/200)

	print("consumed soulGem ("..string.format("%.2f",soulValue).."), granting "..string.format("%.2f",skillGain).." exp")
	grantExp(skillGain)
	ambient.playSound("sprigganmagic")
	refreshAfterConsume()
end

local function finishedConsumingStack(data)
	local soulValue = data.soulValue
	local count = data.count or 1
	local perGem = soulValue^S_EXPERIENCE_EXP * S_EXPERIENCE_MULT2 + S_EXPERIENCE_ADD2
	local skill = types.Player.stats.skills.enchant(self).base
	perGem = perGem * S_CONSUME_MULT * math.min(1,0.5+skill/200)
	local total = perGem * count
	print("consumed "..count.." soulGems ("..string.format("%.2f",soulValue).." each), granting "..string.format("%.2f",total).." exp")
	grantExp(total)
	ambient.playSound("sprigganmagic")
	refreshAfterConsume()
end

local function addSpells() -- also called when ALLOW_SPELLMAKING
	for eff, knowledge in pairs(saveData.effects) do
		--expertise = expertise + knowledge
		if knowledge > 0 or S_OWN_SPELLS_IN_LIBRARY then
			local spellId = getEnchantSpellId(eff)
			if spellId then
				types.Actor.spells(self):add(spellId)
			else
				print("disenchanting spell effect not available: "..eff)
			end
		end
	end
end
local function usedSoulgem(item) -- also called when ALLOW_SPELLMAKING
	if S_ALLOW_REENCHANTING then
		addSpells()
	end
end

local function removeSpells()
	for eff in pairs(saveData.effects) do
		local spellId = getEnchantSpellId(eff)
		if spellId then
			types.Actor.spells(self):remove(spellId)
		else
			--print("disenchanting spell effect not available: "..eff)
		end
	end

end

local function UiModeChanged(data)
	if data.oldMode == "SpellBuying" then
		local spells = types.Actor.spells(self)
		for _,spell in pairs(spells) do
			for _, effect in pairs(spell.effects) do
				saveData.effects[effect.id] = saveData.effects[effect.id] or 0
			end
		end
	end
	
	if data.oldMode == "Interface" then
		if icon and ieEnchantMode then
			icon.props.alpha = 0.95
			magicBg.props.alpha = 0
			ieEnchantMode = false
		end
	end
	
	if data.newMode == "Interface" then
		currentlyInInventory = true
		previouslyEquippedItems = types.Actor.getEquipment(self)
	else
		if dia then
			dia:destroy()
			dia = nil
		end
		if tooltip then
			tooltip:destroy()
			tooltip = nil
		end
		if consumeAllButton then
			consumeAllButton:destroy()
			consumeAllButton = nil
		end
		currentlyInInventory = false
		previouslyEquippedItems = {}
		removeSpells()
	end
	if data.newMode == "Enchanting" then
		inventoryBeforeEnchanting = {}
		for a,b in pairs(types.Actor.inventory(self):getAll()) do
			inventoryBeforeEnchanting[b.id]= {count = b.count, item = b}
		end
	end
	if data.oldMode == "Enchanting" or data.oldMode == "Recharge" then
		if S_ENCHANT_CAPACITY_FIX then
			enchantingFinished = core.getRealTime() + 0.3
		end
	end
	if data.newMode == nil and data.oldMode == "Dialogue" then 
		removeSpells()
	end
	if data.oldMode == nil and data.newMode == "Dialogue" and data.arg then
		local record = types.NPC.objectIsInstance(data.arg) and types.NPC.record(data.arg)
		if record then
			if record.servicesOffered.Spellmaking and S_ALLOW_SPELLMAKING then
				addSpells()
			end
			if record.servicesOffered.Enchanting and S_ALLOW_REENCHANTING then
				addSpells()
			end
		end
	end
end


I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if skillId == "mysticism" then
		local spell = types.Player.getSelectedSpell(self)
		if spell then
			for _,effect in pairs(spell.effects) do
				if effect.id == "dispel" then
					disenchantingSpellTimer = core.getRealTime() + 0.05
				end
			end
		end
	end
end)


local function finishedDisenchanting(data)
	local enchPoints = data.enchPoints
	local wastedEffects = 0
	local countEffects = 0
	for _ in pairs(data.effects) do
		countEffects = countEffects + 1
	end
	local divisor = 1
	if countEffects > 5 then
		divisor = 1+(countEffects-5)/5
	end
	for _, eff in pairs(data.effects) do
		if not getEnchantSpellId(eff.id) then
			saveData.effects[eff.id] = (saveData.effects[eff.id] or 0) + 1/divisor
			wastedEffects = wastedEffects + 1/divisor
		elseif saveData.effects[eff.id] then
			saveData.effects[eff.id] = saveData.effects[eff.id] +1/divisor
			wastedEffects = wastedEffects + 1/divisor
		else
			saveData.effects[eff.id] = 1/divisor
		end
	end
	ambient.playSound("enchant success")
	--ambient.playSound("spellmake success")
	--ambient.playSound("sprigganmagic")
	local skill = types.Player.stats.skills.enchant(self).base
	local skillGain = (enchPoints^S_EXPERIENCE_EXP * S_EXPERIENCE_MULT2 + S_EXPERIENCE_ADD2 + wastedEffects) * math.min(1,0.5+skill/200)
	print("disenchanted item ("..string.format("%.2f",enchPoints).."), granting "..string.format("%.2f",skillGain).." exp")
	grantExp(skillGain)

	local expertise = 0
	for eff, knowledge in pairs(saveData.effects) do
		if knowledge > 0 then
			expertise = expertise + knowledge + 4
		end
	end
	print("expertise: "..expertise.." * "..S_DISENCHANTING_EXPERTISE_MULT)
	expertise = round(expertise*S_DISENCHANTING_EXPERTISE_MULT)
	if expertise > 0 then
		local power = 0
		for a,b in pairs(types.Actor.spells(self)) do
			if b.id:sub(1,#"disenchanting_expertise_") == "disenchanting_expertise_" then
				types.Actor.spells(self):remove(b.id)
			end
		end
		while expertise > 0 do
			if expertise % 2 == 1 and expertise < 255 then
			types.Actor.spells(self):add("disenchanting_expertise_"..math.floor(2^power))
			end
			expertise = math.floor(expertise / 2)
			power = power + 1
		end
	end
	if I.UI.getMode() == 'Interface' then
		if I.InventoryExtender then
			if I.InventoryExtender.registerRowActivateHandler or I.InventoryExtender.VERSION > 1 then
				self:sendEvent('IE_Update')
			else
				self:sendEvent('MI_Update')
			end
		else
			I.UI.setMode()
			I.UI.setMode('Interface')
		end
	end
end



local function onSave()
    return {
        saveData = saveData,
    }
end

local function onLoad(data)
	if data then
		saveData = data.saveData or {effects = {}}
		for a,b in pairs(saveData.effects) do
			if b == true then
				saveData.effects[a] = 1
			end
		end
		local spells = types.Actor.spells(self)
		for _,spell in pairs(spells) do
			for _, effect in pairs(spell.effects) do
				saveData.effects[effect.id] = saveData.effects[effect.id] or 0
			end
		end
	else
		saveData = {effects = {}}
		local spells = types.Actor.spells(self)
		for _,spell in pairs(spells) do
			for _, effect in pairs(spell.effects) do
				saveData.effects[effect.id] = saveData.effects[effect.id] or 0
			end
		end
	end
	saveData.drainedRecords = saveData.drainedRecords or {}
	-- ask the global script for the runtime spell map (custom effects).
	-- the response arrives via disenchanting_setSpellMap, populating enchantSpellMap.
	core.sendGlobalEvent("disenchanting_requestSpellMap", self)
end

local function rememberDrained(recordId)
	saveData.drainedRecords[recordId] = true
end

local function setSpellMap(map)
	enchantSpellMap = map or {}
end
local function refreshInventory()
	if I.UI.getMode() == 'Interface' then
		I.UI.setMode()
		I.UI.setMode('Interface')
	end
end

return {
	engineHandlers = { 
		onFrame = onFrame,
		onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		disenchanting_usedSoulgem = usedSoulgem,
		disenchanting_finishedDisenchanting = finishedDisenchanting,
		disenchanting_consumeQuestion = consumeQuestion,
		disenchanting_finishedConsuming = finishedConsuming,
		disenchanting_finishedConsumingStack = finishedConsumingStack,
		disenchanting_refreshInventory = refreshInventory,
		disenchanting_setSpellMap = setSpellMap,
		disenchanting_rememberDrained = rememberDrained,
	}
}