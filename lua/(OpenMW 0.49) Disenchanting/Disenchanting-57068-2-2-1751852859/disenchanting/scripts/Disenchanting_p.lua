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
MODNAME = "Disenchanting"
local storage = require('openmw.storage')
globalSection = storage.globalSection('Settings'..MODNAME)
I.Settings.registerPage {
    key = MODNAME,
    l10n = "Disenchanting",
    name = "Disenchanting",
    description = ""
}
local levelGapTimer = nil
local EXPERTISE_MULT = globalSection:get("DISENCHANTING_EXPERTISE_MULT")
local function updateSettings()
	if EXPERTISE_MULT ~= globalSection:get("DISENCHANTING_EXPERTISE_MULT") then
		local expertise = 0
		for eff, knowledge in pairs(saveData.effects) do
			if knowledge > 0 then
				expertise = expertise + knowledge + 4
			end
		end
		print("expertise: "..expertise.." * "..globalSection:get("DISENCHANTING_EXPERTISE_MULT"))
		expertise = math.floor(0.5+expertise*globalSection:get("DISENCHANTING_EXPERTISE_MULT"))
		for a,b in pairs(types.Actor.spells(self)) do
			if b.id:sub(1,#"disenchanting_expertise_") == "disenchanting_expertise_" then
				types.Actor.spells(self):remove(b.id)
			end
		end
		local power = 0
		while expertise > 0 do
			if expertise % 2 == 1 and expertise < 255 then
			types.Actor.spells(self):add("disenchanting_expertise_"..math.floor(2^power))
			end
			expertise = math.floor(expertise / 2)
			power = power + 1
		end
	end
	EXPERTISE_MULT = globalSection:get("DISENCHANTING_EXPERTISE_MULT")
end
globalSection:subscribe(async:callback(updateSettings))

local makeTooltip = require("scripts.Disenchanting_tooltip")
local disenchant = require("scripts.Disenchanting_disenchant")

------------------------------------------------------------------------------------------------ LIBRARIES ------------------------------------------------------------------------------------------------
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

local function getColorFromGameSettings(colorTag)
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

------------------------------------------------------------------------------------------------ UI ------------------------------------------------------------------------------------------------

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




local function disenchantDialogue()
	dialogue = "disenchant"
	local itemName = currentlyDisenchanting.type.record(currentlyDisenchanting).name
	local preview = disenchant(currentlyDisenchanting, true)
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
			{ -- yes clickbox
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
			{ -- no clickbox
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
		--print(saveData.effects[b.id] ,core.magic.spells.records["enchantdummy_"..b.id],newEffects[b.id])
		--local mgef = core.magic.effects.records[core.magic.EFFECT_TYPE[b.id]]
		if (not saveData.effects[b.id] or saveData.effects[b.id] == 0)
		and core.magic.spells.records["enchantdummy_"..b.id]
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
					resource = getTexture("textures\\arrow2.dds"),
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
	tooltip = makeTooltip(currentlyDisenchanting, globalSection:get("VALUE_MULT"), util.color.rgb(1,0,0))

end

local function consumeDialogue()
	dialogue = "consume"
	local itemName = currentlyConsuming.type.record(currentlyConsuming).name
	
	if currentlyConsuming.recordId == "misc_soulgem_azura" then
		itemName = "Soul"
	end
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
					text = "Consume "..itemName.."?",
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
			{ -- yes clickbox
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
			{ -- no clickbox
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
	local skillGain = soulValue^globalSection:get("EXPERIENCE_EXP") * globalSection:get("EXPERIENCE_MULT2") + globalSection:get("EXPERIENCE_ADD2")
	skillGain = skillGain * globalSection:get("CONSUME_MULT")
	local skill = types.Player.stats.skills.enchant(self).base
	skillGain = skillGain*math.min(1,0.5+skill/200)
	local progressRequirement = I.SkillProgression.getSkillProgressRequirement('enchant')
	local progressPct = skillGain/progressRequirement
	local value = record.value
	if globalSection:get("SOUL_PRICE_REBALANCE") then
		value = math.floor(0.0001 * soulValue ^ 3 + 2 * soulValue)
	else
		value = math.floor(value * soulValue)
	end
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
end
------------------------------------------------------------------------------------------------ LOGIC ------------------------------------------------------------------------------------------------

local function onFrame(dt)
	if enchantingFinished and core.getRealTime() > enchantingFinished then
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
							core.sendGlobalEvent("disenchanting_multiplyPaper", {self,newItem,globalSection:get("PAPER_MULT")})
						elseif type ~= wTypes.Arrow and type ~= wTypes.Bolt and type ~= wTypes.MarksmanThrown then
							core.sendGlobalEvent("disenchanting_fixCapacity", {self,newItem,removedRecord.enchantCapacity})
						end
					end
				end
			end
		end
		enchantingFinished = nil
	end
	if levelGapTimer and core.getRealTime() > levelGapTimer then
		types.Player.stats.skills.enchant(self).base = 99 + levelGap
		print("after: level "..(99 + levelGap))
		levelGap = 0
		levelGapTimer = nil
	end
	if not currentlyInInventory then return end
	local newShift = input.isShiftPressed()
	if newShift ~= shiftPressed then
		if globalSection:get("CONSUME_MULT") > 0 then
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
		elseif asyncNo and focus == "no" then
			dia:destroy()
			dia = nil
			currentlyDisenchanting = nil
			currentlyConsuming = nil
			if tooltip then
				tooltip:destroy()
				tooltip = nil
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
		local equippedItem = nil
		for slot, thing in pairs(equippedItems) do
			if previouslyEquippedItems[slot] ~= thing  then
				equippedItem = thing
				break
			end
		end
		if equippedItem then
			local record = equippedItem.type.record(equippedItem)
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
	if skill >= 100 and not globalSection:get("UNCAPPER") then
		return
	end

	levelGap = 0
	if skill >= 100 then
		print("before: level "..skill)
		levelGap = skill - 99
		--print("levelgap",levelGap)
		types.Player.stats.skills.enchant(self).base = 99
	end
	
	skillGain = skillGain*math.min(1,0.5+skill/200)+(saveData.experience or 0)
	saveData.experience = 0
	local levelTotalExp = I.SkillProgression.getSkillProgressRequirement('enchant')
	local realLevelTotalExp = levelTotalExp + levelGap
	local progress = types.Player.stats.skills.enchant(self).progress*levelTotalExp
	--print(f1(progress).."+"..f1(skillGain).." / "..f1(realLevelTotalExp))
	while progress + skillGain > realLevelTotalExp do
		print("+"..f1(realLevelTotalExp-progress).."xp (levelup)")
		I.SkillProgression.skillLevelUp('enchant', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
		skillGain = skillGain - realLevelTotalExp +progress
		
		skill = skill+1
		if skill >= 100 then
			levelGap = levelGap + 1
			types.Player.stats.skills.enchant(self).base = 99
		end
		
		levelTotalExp = I.SkillProgression.getSkillProgressRequirement('enchant')
		realLevelTotalExp = levelTotalExp + levelGap
		progress = types.Player.stats.skills.enchant(self).progress*levelTotalExp
	end
	if levelGap > 0 then
		print("+"..f1(skillGain).."xp stored")
		saveData.experience = (saveData.experience or 0) + skillGain
		--types.Player.stats.skills.enchant(self).base = 99 + levelGap --ON FRAME BECAUSE ASYNC IDK
		levelGapTimer = core.getRealTime()+0.3
	else
		print("+"..f1(skillGain).."xp")
		I.SkillProgression.skillUsed('enchant', {skillGain=skillGain, useType = 2, scale = 1})
		levelGap = nil
	end
	progress = types.Player.stats.skills.enchant(self).progress*levelTotalExp
	--print("now",f1(progress).."+"..f1(saveData.experience or 0).." / "..f1(realLevelTotalExp))
end

local function finishedConsuming(soulValue)
	local skillGain = soulValue^globalSection:get("EXPERIENCE_EXP") * globalSection:get("EXPERIENCE_MULT2") + globalSection:get("EXPERIENCE_ADD2")
	skillGain = skillGain * globalSection:get("CONSUME_MULT")
	print("consumed soulGem ("..string.format("%.2f",soulValue).."), granting "..string.format("%.2f",skillGain).." exp")
	grantExp(skillGain)
	ambient.playSound("sprigganmagic")
	I.UI.setMode()
	I.UI.setMode('Interface')
end

local function usedSoulgem(item) -- also called when ALLOW_SPELLMAKING
	--local expertise = 0
	for eff, knowledge in pairs(saveData.effects) do
		--expertise = expertise + knowledge
		if knowledge > 0 or globalSection:get("OWN_SPELLS_IN_LIBRARY") then
			if core.magic.spells.records["enchantdummy_"..eff] then
				types.Actor.spells(self):add("enchantdummy_"..eff)
			else
				print("disenchanting spell effect not available: "..eff)
			end
		end
	end
	--local skillIncrease = math.floor(expertise/10)
	--if skillIncrease > 0 then
	--	for a,b in pairs(types.Actor.activeSpells(self)) do
	--		print(a,b)
	--	end
	--end
	--types.Actor.activeSpells(self):add({id = "enchantdummy_FortifySkill", effects = { 0 }, name = "Disenchanting Expertise"})
	--types.Actor.activeEffects(self):set(100, "fortifyskill", "enchant")
end

local function removeSpells()
	for eff in pairs(saveData.effects) do
		if core.magic.spells.records["enchantdummy_"..eff] then
			types.Actor.spells(self):remove("enchantdummy_"..eff)
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
		if globalSection:get("ENCHANT_CAPACITY_FIX") then
			enchantingFinished = core.getRealTime() + 0.3
		end
	end
	if globalSection:get("ALLOW_SPELLMAKING") and data.oldMode == "Dialogue" then
		removeSpells()
	end
	if globalSection:get("ALLOW_SPELLMAKING") and data.newMode == "Dialogue" then
		usedSoulgem()
	end
end



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
		if not core.magic.spells.records["enchantdummy_"..eff.id] then
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
	local skillGain = enchPoints^globalSection:get("EXPERIENCE_EXP") * globalSection:get("EXPERIENCE_MULT2") + globalSection:get("EXPERIENCE_ADD2") + wastedEffects
	print("disenchanted item ("..string.format("%.2f",enchPoints).."), granting "..string.format("%.2f",skillGain).." exp")
	grantExp(skillGain)

	local expertise = 0
	for eff, knowledge in pairs(saveData.effects) do
		if knowledge > 0 then
			expertise = expertise + knowledge + 4
		end
	end
	print("expertise: "..expertise.." * "..globalSection:get("DISENCHANTING_EXPERTISE_MULT"))
	expertise = round(expertise*globalSection:get("DISENCHANTING_EXPERTISE_MULT"))
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
	I.UI.setMode()
	I.UI.setMode('Interface')
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
		disenchanting_refreshInventory = refreshInventory,
	}
}