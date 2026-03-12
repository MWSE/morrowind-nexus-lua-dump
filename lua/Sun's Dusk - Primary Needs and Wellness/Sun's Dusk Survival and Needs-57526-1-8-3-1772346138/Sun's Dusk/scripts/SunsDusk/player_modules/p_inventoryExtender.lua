async:newUnsavableSimulationTimer(0.1, function()
	
-- check for inventory extender
if not I.InventoryExtender then
	print("[Sun's Dusk] InventoryExtender not found - tooltip integration disabled")
	return
end

local BASE = I.InventoryExtender.Templates.BASE
local constants = I.InventoryExtender.Constants
local TOOLTIP_SHORT_TEXT = false

-- colors for survival values
local FONT_TINT = getColorFromGameSettings("FontColor_color_normal")
local quickLootText = {
 	props = {
 			textColor = FONT_TINT,--util.color.rgba(1, 1, 1, 1),
 			textShadow = true,
 			textShadowColor = util.color.rgba(0,0,0,0.75),
 			--textAlignV = ui.ALIGNMENT.Center,
 			--textAlignH = ui.ALIGNMENT.Center,
			textSize = 14,
 	}
}

local itemFontSize = require('scripts.omw.mwui.constants').textNormalSize or 18
local layerId = ui.layers.indexOf("Modal")
local uiSize = ui.layers[layerId].size
local textSizeMult = 1 --ui.screenSize().y/uiSize.y

local COLORS = {
	FOOD		= util.color.rgb(0.9, 0.7, 0.4),	-- tan
	DRINK		= util.color.rgb(0.4, 0.7, 0.9),	-- blue
	WAKE		= util.color.rgb(0.7, 0.9, 0.5),	-- green
	WARMTH_HOT	= util.color.rgb(0.9, 0.5, 0.3),	-- orange
	WARMTH_COLD	= util.color.rgb(0.5, 0.7, 0.9),	-- blue
	TOXIC		= util.color.rgb(0.8, 0.3, 0.3),	-- red
	GREEN_PACT	= util.color.rgb(0.5, 0.8, 0.4),	-- green
	LABEL		= (constants and constants.Colors and constants.Colors.DISABLED) or util.color.rgb(0.6, 0.6, 0.6),
	HEADER		= (constants and constants.Colors and constants.Colors.DEFAULT_LIGHT) or util.color.rgb(0.85, 0.82, 0.7),
	HEAT_RES	= util.color.rgb(0.95, 0.6, 0.3),	-- orange
	COLD_RES	= util.color.rgb(0.4, 0.65, 0.95),	-- blue
	WET_RES		= util.color.rgb(0.3, 0.8, 0.7),	-- blue
	IMMUNITY	= util.color.rgb(0.95, 0.85, 0.3),
	CHARGES		= util.color.rgb(0.7, 0.7, 0.7),	-- grey
	BACKPACK	= util.color.rgb(0.6, 0.5, 0.35), 	-- ??
	EQUIPPED	= util.color.rgb(0.5, 0.9, 0.5),
	MAGIC		= util.color.rgb(0.7, 0.5, 0.9),	-- purple
	COOKED		= util.color.rgb(0.95, 0.75, 0.4),	-- ??
}

-- format food/drink/wake value
local function formatRawValue(value)
	if not value or value == 0 then return nil end
	local raw = math.floor(value * 200 + 0.5)
	return tostring(raw)
end

-- create compact inline stat (just colored value)
local function createCompactStat(label, value, color)
	return {
		type = ui.TYPE.Flex,
		props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
		content = ui.content {
			{ template = BASE.textNormal, props = { text = label .. " ", textColor = COLORS.LABEL } },
			{ template = BASE.textNormal, props = { text = value, textColor = color } },
		}
	}
end

-- only for ingreds and bevs in my database
I.InventoryExtender.registerTooltipModifier("SunsDusk_SurvivalValues", function(item, layout)
	local recordId = item.recordId
	local foodData = dbConsumables[recordId]
	
	if not foodData then
		return layout
	end
	
	local ok, innerContent = pcall(function()
		return layout.content[1].content[1].content
	end)
	
	if not ok or not innerContent then
		return layout
	end
	
	innerContent:add(BASE.intervalV(8))
	innerContent:add({
		template = I.MWUI.templates.horizontalLine,
		props = { size = v2(200, 2) }
	})
	innerContent:add(BASE.intervalV(2))
	
	-- building sentence
	local restoreParts = {}
	
	local foodStr = formatRawValue(foodData.foodValue)
	if foodStr then
		table.insert(restoreParts, foodStr .. " hunger")
	end
	
	local drinkStr = formatRawValue(foodData.drinkValue)
	if drinkStr then
		table.insert(restoreParts, drinkStr .. " thirst")
	end
	
	local wakeStr = formatRawValue(foodData.wakeValue)
	if wakeStr then
		table.insert(restoreParts, wakeStr .. " tiredness")
	end
	
	-- adds restore to sentence
	if #restoreParts > 0 then
		local restoreSentence = "Restores " .. table.concat(restoreParts, ", ") .. "."
		innerContent:add(BASE.intervalV(2))
		innerContent:add({
			template = BASE.textNormal,
			props = { text = restoreSentence, textColor = COLORS.FOOD }
		})
	end
	
	-- warmth as a separate sentence
	local warmthVal = foodData.warmthValue
	if warmthVal and warmthVal ~= 0 then
		local warmthSentence
		local warmthColor
		if warmthVal > 0 then
			warmthSentence = "Provides " .. math.floor(warmthVal + 0.5) .. " warmth."
			warmthColor = COLORS.WARMTH_HOT
		else
			warmthSentence = "Cools by " .. math.abs(math.floor(warmthVal + 0.5)) .. "."
			warmthColor = COLORS.WARMTH_COLD
		end

		innerContent:add(BASE.intervalV(2))
		innerContent:add({
			template = BASE.textNormal,
			props = { text = warmthSentence, textColor = warmthColor }
		})
	end
	
	-- build flags
	local flags = {}
	
	local category = foodData.consumeCategory
	if category == "raw meat" then
		table.insert(flags, { text = "Raw Meat", color = COLORS.TOXIC })
	elseif category == "corprus" then
		table.insert(flags, { text = "Corprus", color = COLORS.TOXIC })
	end
	
	if foodData.isToxic then
		table.insert(flags, { text = "Toxic", color = COLORS.TOXIC })
	end
	
	if foodData.isGreenPact then
		table.insert(flags, { text = "Green Pact Safe", color = COLORS.GREEN_PACT })
	end
	
	--if foodData.isCookedMeal then
	--	table.insert(flags, { text = "Cooked or Prepared", color = COLORS.FOOD })
	--end
	
	if #flags > 0 then
		innerContent:add(BASE.intervalV(2))
		
		-- build flags as inline flex
		local flagsContent = ui.content {}
		for i, flag in ipairs(flags) do
			if i > 1 then
				flagsContent:add({
					template = BASE.textNormal,
					props = { text = ", ", textColor = COLORS.LABEL }
				})
			end
			flagsContent:add({
				template = BASE.textNormal,
				props = { text = flag.text, textColor = flag.color }
			})
		end
		
		innerContent:add({
			type = ui.TYPE.Flex,
			props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
			content = flagsContent
		})
	end
	
	-- cooking class sentence
	local ingredientClass = foodData.ingredientClass
	if ingredientClass and ingredientClass ~= "" then
		local lowerClass = ingredientClass:lower()
		if lowerClass ~= "dubious" and lowerClass ~= "monster" then
			local firstChar = lowerClass:sub(1, 1)
			local article = (firstChar == "a" or firstChar == "e" or firstChar == "i" or firstChar == "o" or firstChar == "u") and "an" or "a"
			local classSentence = "Can be used as " .. article .. " " .. ingredientClass .. " for cooking."
			innerContent:add(BASE.intervalV(2))
			innerContent:add({
				template = BASE.textNormal,
				props = { text = classSentence, textColor = COLORS.LABEL }
			})
		end
	end
	return layout
end)

-- initialisation
local BASE = I.InventoryExtender.Templates.BASE
local constants = I.InventoryExtender.Constants

-- ═══════════════════════════════════════════════════════════════════════
-- Data Tables for Tooltips
-- ═══════════════════════════════════════════════════════════════════════

local BACKPACK_FEATHER = {
	sd_backpack_satchelblue 	= "by a slight amount", -- 40
	sd_backpack_satchelblack 	= "by a slight amount", -- 40
	sd_backpack_satchelgreen 	= "by a slight amount", -- 40
	sd_pouch 					= "by a slight amount", -- 40
	sd_backpack 				= "by a moderate amount", -- 55 
	sd_backpack_traveler 		= "by a great amount", -- 70
	sd_backpack_adventurer 		= "by a great amount", -- 70
	sd_backpack_velvetblue 		= "by a great amount", -- 70
	sd_backpack_satchelbrown 	= "by a great amount", -- 70
	sd_backpack_adventurerblue 	= "by a great amount", -- 70
	sd_backpack_adventurergreen = "by a great amount", -- 70
	sd_backpack_velvetbrown 	= "by a great amount", -- 70
	sd_backpack_velvetgreen 	= "by a great amount", -- 70
	sd_backpack_velvetpink 		= "by a great amount", -- 70
}

local BACKPACK_BUFFS = {
	sd_backpack					= "+10 Feather",
	sd_backpack_adventurer		= "+15 Feather",
	sd_backpack_adventurerblue	= "+15 Feather",
	sd_backpack_adventurergreen	= "+15 Feather",
	sd_backpack_satchelblack	= "+5 Feather, +2 Speechcraft",
	sd_backpack_satchelblue		= "+5 Feather, +2 Mercantile",
	sd_backpack_satchelbrown	= "+5 Feather, +2 Speechcraft",
	sd_backpack_satchelgreen	= "+5 Feather, +2 Speechcraft",
	sd_backpack_traveler		= "+15 Feather",
	sd_backpack_velvetblue		= "+10 Feather, +3 Mercantile",
	sd_backpack_velvetbrown		= "+10 Feather, +3 Mercantile",
	sd_backpack_velvetgreen		= "+10 Feather, +3 Mercantile",
	sd_backpack_velvetpink		= "+10 Feather, +3 Mercantile",
}

local LIQUID_INFO = {
	{ pattern = "suspicious water", name = "Suspicious Water", color = util.color.rgb(0.6, 0.5, 0.3), drinkValue = 0.15, warning = "If you're desperate..." },
	{ pattern = "saltwater", name = "Saltwater", color = COLORS.TOXIC, drinkValue = -0.2, warning = "Dehydrates" },
	{ pattern = "water", name = "Water", color = COLORS.DRINK, drinkValue = 0.2 },
	{ pattern = "sujamma", name = "Sujamma", color = util.color.rgb(0.7, 0.4, 0.2), drinkValue = -0.1, warmthValue = 3 },
	{ pattern = "flin", name = "Flin", color = util.color.rgb(0.8, 0.6, 0.3), drinkValue = -0.05, warmthValue = 2 },
	{ pattern = "stoneflower tea", name = "Stoneflower Tea", color = util.color.rgb(0.6, 0.5, 0.8), drinkValue = 0.2, warmthValue = 5, wakeRestore = true },
	{ pattern = "heather tea", name = "Heather Tea", color = util.color.rgb(0.7, 0.5, 0.6), drinkValue = 0.2, warmthValue = 4 },
}

local CLOTHING_RESISTANCES = {
	robe = { heat = 2, cold = 2 },
	shirt = { heat = 1, cold = 1 },
	pants = { heat = 1, cold = 1 },
	skirt = { heat = 1, cold = 1 },
}

local CHARGE_MAX = { soap = 5, towel = 8, cloth = 3, bugMusk = 3, bathProduct = 3 }

local instructions = {
	soap = "To use for bathing while in water.",
	towel = "To use for drying off after bathing.",
	bugmusk = "Infused into your bath for a longer but weaker effect.",
	bathproduct = "Use while bathing for luxory.",
	washbasin = "Place on the ground for a place to bathe.",
}

local effectDurations = {
	soap = 600,
	bugmusk = 900,
	bathproduct = 900,
}

-- vessels
local OPEN_VESSEL_KEYWORDS = { "cup", "goblet", "tankard", "mug", "misc_de_glass", "drinkinghorn", "pitcher", "beaker", "de_pot_" }
local CLOSED_VESSEL_KEYWORDS = { "bottle", "canteen", "waterskin" }
local FLASK_KEYWORDS = { "flask" }
local VESSEL_BLACKLIST = { "broken", "paintpot", "inkvial" }

-- tea
local TEACUP_PATTERNS = { "redware_cup", "deceramiccup", "ceramiccup", "teacup" }
local TEAPOT_PATTERNS = { "teapot", "kettle", "pot_redware_03" }

-- foodware
local BOWL_WHITELIST = { "_bowl", "bowl_" }
local BOWL_BLACKLIST = { "bowler", "bowling" }
local PLATE_WHITELIST = { "_plate", "plate_", "_platter", "platter_" }
local PLATE_BLACKLIST = { "template", "armor", "bonemold" }

-- camping
local FIREWOOD_PATTERNS = { "sd_wood_1", "sd_wood_publican", "sd_wood_merchant" }
local BEDROLL_PATTERNS = { "sd_campingitem_bedroll", "sd_campingitem_bedroll_ing" }	

-- torches for temperature
local LIGHT_TEMP_DATA = {
	{ pattern = "torch", temp = 5 },
	{ pattern = "lantern", temp = 2 },
	{ pattern = "candle", temp = 1 },
}

-- ═══════════════════════════════════════════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════════════════════════════════════════

-- Get attribute name using the API
local function getAttributeName(attributeId)
	-- Get the attribute from the API's constants
	local attributes = core.stats.ATTRIBUTE
	
	-- Find the name by comparing the ID with the API constants
	for name, id in pairs(attributes) do
		if id == attributeId then
			return name
		end
	end
	
	return "Unknown Attribute"
end

-- Get skill name using the API
local function getSkillName(skillId)
	-- Get the skill from the API's constants
	local skills = core.stats.SKILL
	
	-- Find the name by comparing the ID with the API constants
	for name, id in pairs(skills) do
		if id == skillId then
			return name
		end
	end
	
	return "Unknown Skill"
end

-- Get magic effect name using the API
local function getMagicEffectName(effectId)
	-- Use the magic effect from the API
	local effect = core.magic.effects.records[effectId]
	--local gm = core.getGMST("sEffect"..effectId)
	--print(effectId,effectId,gm,gm)
	if effectId == "fortifyskill" or effectId == "fortifyattribute" then
		return core.getGMST("sFortify")
	end
	-- If the effect exists, return its name
	if effect then
		return effect.name
	end
	
	return "Unknown Effect"
end

local function getEffects(e, typ)
	typ = typ or "potion"
	local effects = {}
	local shortTexts = TOOLTIP_SHORT_TEXT
	local eff = {}
	for _, effect in pairs(e) do
		local uniqueString = effect.id..(effect.affectedAttribute or "")..(effect.affectedSkill or "")..effect.duration
		eff[uniqueString] = {
			id = effect.id,
			effect = effect.effect,
			affectedSkill = effect.affectedSkill,
			affectedAttribute = effect.affectedAttribute,
			range = effect.range,
			area = effect.area,
			duration = effect.duration,
			magnitudeMin = (eff[uniqueString] and eff[uniqueString].magnitudeMin or 0) + effect.magnitudeMin,
			magnitudeMax = (eff[uniqueString] and eff[uniqueString].magnitudeMax or 0) + effect.magnitudeMax,
		}
	end
		
	for i, effect in pairs(eff) do
		local text = getMagicEffectName(effect.id)
		--for a,b in pairs(core.magic.EFFECT_TYPE) do
		--	if b == effect.id then
		--		print(a)
		--	end
		--end
		if effect.affectedSkill then
			text = text.." "..(core.getGMST("sSkill"..effect.affectedSkill) or "??")
			if shortTexts then
				text = (core.getGMST("sSkill"..effect.affectedSkill) or "??").. " +"
			end
		elseif effect.affectedAttribute then
			text = text.." "..(core.getGMST("sAttribute"..effect.affectedAttribute) or "??")
			if shortTexts then
				if effect.id == core.magic.EFFECT_TYPE.FortifySkill or effect.id == core.magic.EFFECT_TYPE.FortifyAttribute then
					text = (core.getGMST("sAttribute"..effect.affectedAttribute) or "??").. " +"
				elseif effect.id == core.magic.EFFECT_TYPE.DrainAttribute or effect.id == core.magic.EFFECT_TYPE.DrainSkill then
					text = (core.getGMST("sAttribute"..effect.affectedAttribute) or "??").. " -"
				end
			end
		end
		if effect.id == core.magic.EFFECT_TYPE.RestoreHealth and #text > 8 then
			text = "Heal"
		end
		local effectPrototype = core.magic.effects.records[effect.id]
		if effectPrototype.hasMagnitude then
			if effect.id == core.magic.EFFECT_TYPE.FortifyMaximumMagicka then
				if effect.magnitudeMin == effect.magnitudeMax then
					text = text.." "..effect.magnitudeMin/10
				else
					text = text.." "..effect.magnitudeMin/10 .."-"..effect.magnitudeMax/10
				end
				text = shortTexts and (text.."INT") or (text..core.getGMST("sXTimesINT"))
			else
				if effect.magnitudeMin == effect.magnitudeMax then
					text = text.." "..effect.magnitudeMin
				else
					text = text.." "..effect.magnitudeMin.."-"..effect.magnitudeMax
				end
				if effect.id == core.magic.EFFECT_TYPE.Chameleon then
					text = text.."%"
				end
				text =  shortTexts and (text) or (text.." "..core.getGMST("sPoints"))
			end
		end
		if typ ~= "constant" then --enchantmentRecord.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
			if effectPrototype.hasDuration then
				local dur = math.max(1,effect.duration)
				if shortTexts then
					if dur > 1 then
						text = text.." x "..dur
					end
				else
					text = text.." "..core.getGMST("sfor")
					text = text.." "..dur
					if dur == 1 then
						text = text.." "..core.getGMST("ssecond")
					else
						text = text.." "..core.getGMST("sseconds")
					end
				end
			end
			if typ ~= "potion" then
				if shortTexts then
					if effect.range == core.magic.RANGE.Self then
						text = text.." (Self)"
					elseif effect.range == core.magic.RANGE.Target then
						text = text.." (Target)"		
					elseif effect.range == core.magic.RANGE.Touch then
						text = text.." (Touch)"
					end
				else
					text = text.." "..core.getGMST("sonword")
					if effect.range == core.magic.RANGE.Self then
						text = text.." "..core.getGMST("sRangeSelf")
					elseif effect.range == core.magic.RANGE.Target then
						text = text.." "..core.getGMST("sRangeTarget")		
					elseif effect.range == core.magic.RANGE.Touch then
						text = text.." "..core.getGMST("sRangeTouch")
					end
				end
			end
		end
		--if effect.id >= 0 then -- Valid effect
			table.insert(effects, {
				id = effect.id,
				text = text,
			   -- subEffect = effect.subEffect,
				skillId = effect.affectedSkill,
				attributeId = effect.affectedAttribute,
				range = effect.range,
				area = effect.area,
				icon = effect.effect.icon,
				duration = effect.duration,
				magnitude = {
					min = effect.magnitudeMin,
					max = effect.magnitudeMax
				}
			})
		--end
	end
	return effects
end

local function printEffects(effectFlex, effects, isPotion)
	local skill = typesPlayerStatsSelf.alchemy.modified
	--local gmst = core.getGMST("fWortChanceValue")
	
	for i,effect in pairs(effects) do
		--if skill >= i * gmst or not isPotion then
			local effectFlex2 ={
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
				},
				content = ui.content({})
			}
			effectFlex.content:add(effectFlex2)
			effectFlex2.content:add{ props = { size = v2(1, 1) * 5 } }

			effectFlex2.content:add {
				type = ui.TYPE.Image,
				props = {
					resource = getTexture(effect.icon),
					tileH = false,
					tileV = false,
					size = v2(itemFontSize,itemFontSize),
					alpha = 0.7,
				}
			}
			effectFlex2.content:add { 
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = " "..effect.text.." ",
					textSize = itemFontSize*textSizeMult,
					size = v2(0,itemFontSize*textSizeMult),
					textAlignH = ui.ALIGNMENT.Center,
				},
			}
			effectFlex.content:add{ props = { size = v2(1, 1) * 1 } }
		--else
		--	textElement("?")
		--end
	end
end
	
	
local function getInnerContent(layout)
	local ok, result = pcall(function()
		return layout.content[1].content[1].content
	end)
	return ok and result or nil
end

local function getEffectFlex(layout)
	local ok, result = pcall(function()
		return layout.content[1].content[1].content[4]
	end)
	return ok and result or nil
end

local function addSeparator(content)
	content:add(BASE.intervalV(8))
	content:add({ template = I.MWUI.templates.horizontalLine, props = { size = v2(200, 2) } })
	content:add(BASE.intervalV(4))
end

local function addText(content, text, color, spaced)
	if spaced then content:add(BASE.intervalV(2)) end
	content:add({ template = BASE.textNormal, props = { text = text, textColor = color or COLORS.LABEL, multiline = true, textAlignH = ui.ALIGNMENT.Center } })
end

local function matchesAny(recordId, patterns)
	for _, p in ipairs(patterns) do
		if recordId:find(p, 1, true) or recordId:match(p) then return true end
	end
	return false
end

local function getArmorRes(item)
	local recordId = item.recordId
	local name = item.type.record(item).name:lower()
	-- armor resistance check
	for keyword, data in pairs(ARMOR_RESISTANCES) do
		if recordId:find(keyword, 1, true) or name:find(keyword, 1, true) then return data end
	end
	-- clothing resistance check
	for keyword, data in pairs(CLOTHING_RESISTANCES) do
		if recordId:find(keyword, 1, true) or name:find(keyword, 1, true) then return data end
	end
	return nil
end

-- resistance values to wording
local function getResistanceWording(value)
	if not value then return nil end
	local rounded = math.floor(value + 0.5)
	if rounded <= 1 then return "Poor"
	elseif rounded == 2 then return "Moderate"
	elseif rounded == 3 then return "Good"
	else return "Excellent"
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- Cooked Food
-- ═══════════════════════════════════════════════════════════════════════

local function view(t, depth)
	depth = depth or 0
	local depthStr = ""
	for i=1, depth do
		depthStr = depthStr.."   "
	end
	for a,b in pairs(t) do
		local formatted = tostring(b)
		if type(b) == "string" then
			formatted = '"'..b..'"'
		end
		if type(b) == "table" then
			formatted = "table"
		end
		print(depthStr..a.." = "..formatted)
		if type(b) == "table" then
			view(b, depth+1)
		end
	end

end

I.InventoryExtender.registerTooltipModifier("SunsDusk_CookedFood", function(item, layout)
	if not types.Potion.objectIsInstance(item) then return layout end
	
	local record = types.Potion.record(item)
	
	--if not record or not G_stewNames or not G_stewNames[record.name] then return layout end
	if not saveData.registeredConsumables[item.recordId] then return layout end
	local content = getInnerContent(layout)
	if not content then return layout end
	if G_stewNames[record.name] then
		local flex = getEffectFlex(layout) --layout.content[1].content[1].content[4]
		if flex then
			flex.content = ui.content{}
			local potionEffects = getEffects(types.Potion.record(item).effects, "potion")
			printEffects(flex, potionEffects, true)
		end
		--print("====================")
		--view(layout.content[1].content[1].content[4].content)
		--print("====================")
	end
	
	addSeparator(content)
	addText(content, "Cooked Meal", COLORS.COOKED)
	
	local data = saveData.registeredConsumables[item.recordId]
	if data then
		local parts = {}
		if data.foodValue and data.foodValue > 0 then
			table.insert(parts, math.floor(data.foodValue * 200 + 0.5) .. " hunger")
		end
		-- Thirst removed from cooked food display
		if #parts > 0 then
			addText(content, "Restores " .. table.concat(parts, ", ") .. ".", COLORS.FOOD, true)
		end
		if data.warmthValue and data.warmthValue ~= 0 and data.timestamp and ((core.getGameTime() - data.timestamp) / 3600) < 3 then
		-- consume within x time to gain or lose x heat			
			local txt = data.warmthValue > 0 
				and "Provides " .. math.floor(data.warmthValue + 0.5) .. " warmth."
				or "Cools by " .. math.abs(math.floor(data.warmthValue + 0.5)) .. "."
			addText(content, txt, data.warmthValue > 0 and COLORS.WARMTH_HOT or COLORS.WARMTH_COLD, true)
		end
	end
	
	--if record.effects and #record.effects > 0 then
	--	addText(content, #record.effects .. " magical effect" .. (#record.effects > 1 and "s" or "") .. ".", COLORS.MAGIC, true)
	--end
	
	return layout
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Backpacks
-- ═══════════════════════════════════════════════════════════════════════

I.InventoryExtender.registerTooltipModifier("SunsDusk_Backpacks", function(item, layout)
	if not types.Miscellaneous.objectIsInstance(item) then return layout end
	
	local recordId = item.recordId
	local isEquipped = recordId:sub(-3) == "_eq"
	
	if isEquipped then
		recordId = recordId:sub(1,-4)
	end
	
	local feather = BACKPACK_FEATHER[recordId]
	if not feather then return layout end
	
	local content = getInnerContent(layout)
	if not content then return layout end
	addSeparator(content)
	addText(content, isEquipped and "Backpack (Equipped)" or "Backpack (Unequipped)", isEquipped and COLORS.EQUIPPED or COLORS.BACKPACK)

	if isEquipped then
		addText(content, "Reduces encumberance from camping items\n"..feather..".", COLORS.LABEL, true)
	else
		addText(content, "When equipped, reduces encumberance\nfrom camping items "..feather..".", COLORS.LABEL, true)
	end
	
	if BACKPACK_BUFFS[recordId] then
		addText(content, BACKPACK_BUFFS[recordId], COLORS.MAGIC, true)
	end
	
--	addText(content, feather .." reduces camping item weight.", COLORS.LABEL, true)	
--  if not isEquipped then
--  	addText(content, "Use to equip.", COLORS.LABEL, true)
--  end
	
	return layout
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Liquid Vessels
-- ═══════════════════════════════════════════════════════════════════════

I.InventoryExtender.registerTooltipModifier("SunsDusk_DrinkValue", function(item, layout)
	if not types.Potion.objectIsInstance(item) then return layout end
	if not NEEDS_THIRST then return layout end
	if dbConsumables[item.recordId] then return layout end
	
	-- skip cooked food (registered consumables)
	if saveData.registeredConsumables and saveData.registeredConsumables[item.recordId] then return layout end
	
	-- skip bath products
	local recordId = item.recordId
	if recordId:find("bug_musk") then return layout end
	
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	local liquidInfo = nil
	
	if entry and entry.drinkValue and entry.drinkValue ~= 0 then
		liquidInfo = { drinkValue = entry.drinkValue, color = COLORS.DRINK }
	else
		local lowerName = item.type.record(item).name:lower()
		for _, info in ipairs(LIQUID_INFO) do
			if lowerName:find(info.pattern, 1, true) then
				liquidInfo = info
				break
			end
		end
	end
	
	if not liquidInfo or not liquidInfo.drinkValue or liquidInfo.drinkValue == 0 then return layout end
	
	local content = getInnerContent(layout)
	if not content then return layout end
	
	addSeparator(content)
	
	local displayValue = math.floor(liquidInfo.drinkValue * 200 + 0.5)
	local textColor = liquidInfo.color or (displayValue > 0 and COLORS.DRINK or COLORS.TOXIC)
	
	if displayValue > 0 then
		addText(content, "Restores " .. displayValue .. " thirst.", textColor, true)
	elseif displayValue < 0 then
		addText(content, "Increases thirst by " .. math.abs(displayValue) .. ".", textColor, true)
	end
	
	if liquidInfo.warmthValue and liquidInfo.warmthValue ~= 0 then
		addText(content, "Provides " .. liquidInfo.warmthValue .. " warmth.", COLORS.WARMTH_HOT, true) -- does one need to be added for cold ?
	end
	
	if liquidInfo.wakeRestore then
		addText(content, "Reduces tiredness.", COLORS.WAKE, true)
	end
	
	if liquidInfo.warning then
		addText(content, liquidInfo.warning .. ".", COLORS.TOXIC, true)
	end
	
	return layout
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Soap, Towels, Bath Products
-- ═══════════════════════════════════════════════════════════════════════

I.InventoryExtender.registerTooltipModifier("SunsDusk_BathingItems", function(item, layout)
	local category, tooltipName, buffId = G_isBathingItem(item)
	if not category then return layout end
	
	local content = getInnerContent(layout)
	if not content then return layout end
	
	addSeparator(content)
	
	if category == "washbasin" then
		addText(content, instructions[category], COLORS.LABEL)
		return layout
	end
	
	-- max charge display
	local maxCharges
	if category == "soap" then
		maxCharges = CHARGE_MAX.soap
	elseif category == "towel" then
		maxCharges = tooltipName == "Towel" and CHARGE_MAX.towel or CHARGE_MAX.cloth
	elseif category == "bugmusk" then
		maxCharges = CHARGE_MAX.bugMusk
	elseif category == "bathproduct" then
		maxCharges = CHARGE_MAX.bathProduct
	end
	
	local uses = 0
	if saveData and saveData.m_clean and saveData.m_clean.itemUses then
		uses = saveData.m_clean.itemUses[item.recordId] or 0
	end
	local remaining = maxCharges - uses

	addText(content, instructions[category], COLORS.LABEL)
	
	-- show magic effects for soaps + bath products with spells and buffs
	if buffId and tooltips[buffId] then
		content:add(BASE.intervalV(2))
		local effectStr = tooltips[buffId]
		local colonPos = effectStr:find(":")
		if colonPos then
			effectStr = effectStr:sub(colonPos+1, -1)
		end
		if effectDurations[category] then
			effectStr = effectStr.." for "..effectDurations[category].."s"
		end
		addText(content, effectStr, COLORS.MAGIC)
	end
	
	addText(content, remaining .. " use" .. (remaining == 1 and "" or "s") .. " remaining.", COLORS.CHARGES, true)
	
	return layout
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Armor Temperature Resistances
-- ═══════════════════════════════════════════════════════════════════════

I.InventoryExtender.registerTooltipModifier("SunsDusk_ArmorResistances", function(item, layout)
	if not types.Armor.objectIsInstance(item) and not types.Clothing.objectIsInstance(item) then
		return layout
	end
	
	local res = getArmorRes(item)
	if not res then return layout end
	if not res.heat and not res.cold and not res.water and not res.lavaImmune and not res.freezeImmune then
		return layout
	end
	
	local content = getInnerContent(layout)
	if not content then return layout end
	
	addSeparator(content)
	addText(content, "Temperature Properties", COLORS.HEADER)
	
	if res.heat then
		local heatWording = getResistanceWording(res.heat)
		addText(content, "Heat Resistance: " .. heatWording, COLORS.HEAT_RES, true)
	end
	
	if res.cold then
		local coldWording = getResistanceWording(res.cold)
		addText(content, "Cold Resistance: " .. coldWording, COLORS.COLD_RES, true)
	end
	
	if res.water then
		local wetWording = getResistanceWording(res.water)
		addText(content, "Wet Resistance: " .. wetWording, COLORS.WET_RES, true)
	end
	
	if res.heat and res.heat >= 4 and not res.lavaImmune then
		addText(content, "Extreme Heat Protection", COLORS.IMMUNITY, true)
	end
	if res.cold and res.cold >= 4 and not res.freezeImmune then
		addText(content, "Extreme Cold Protection", COLORS.IMMUNITY, true)
	end
	
	if res.lavaImmune then addText(content, "Lava Immunity", COLORS.IMMUNITY, true) end
	if res.freezeImmune then addText(content, "Frozen Water Immunity", COLORS.IMMUNITY, true) end
	
	return layout
end)
	
-- ═══════════════════════════════════════════════════════════════════════
-- Misc stuff (empty vessels, tea, foodware, camping)
-- ═══════════════════════════════════════════════════════════════════════
local function getMiscDescription(item)
	local recordId = item.recordId
	local name = item.type.record(item).name:lower()
	
	-- teacup
	for _, pattern in ipairs(TEACUP_PATTERNS) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "A cup for brewing and drinking tea."
		end
	end
	
	-- teapot
	for _, pattern in ipairs(TEAPOT_PATTERNS) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "A pot for brewing and drinking tea."
		end
	end
	
	-- bowls
	local isBowl = nil
	for _, bl in ipairs(BOWL_BLACKLIST) do
		if recordId:find(bl, 1, true) or name:find(bl, 1, true) then
			isBowl = false
			break
		end
	end
	if isBowl == nil then
		for _, pattern in ipairs(BOWL_WHITELIST) do
			if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
				return "A bowl for preparing cooked meals."
			end
		end
	end
	
	-- plates
	local isPlate = nil
	for _, bl in ipairs(PLATE_BLACKLIST) do
		if recordId:find(bl, 1, true) or name:find(bl, 1, true) then
			isPlate = false
		end
	end
	if isPlate == nil then
		for _, pattern in ipairs(PLATE_WHITELIST) do
			if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
				return "A plate for preparing cooked meals."
			end
		end
	end
	
	-- closed vessels
	for _, pattern in ipairs(CLOSED_VESSEL_KEYWORDS) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "A sealed vessel for drinks.\n"
				 .."Can be refilled from wells and kegs."
		end
	end
	
	-- flasks
	for _, pattern in ipairs(FLASK_KEYWORDS) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "A flask for carrying drinks.\n"
				 .."Can be refilled from water sources."
		end
	end
	
	-- open vessels
	for _, pattern in ipairs(OPEN_VESSEL_KEYWORDS) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "An open vessel for drinks.\n"
				 .."Can be refilled from wells,\n"
				 .."kegs, rivers, lakes, and the ocean."
		end
	end
	
	-- firewood
	for _, pattern in ipairs(FIREWOOD_PATTERNS) do
		if recordId:find(pattern, 1, true) then
			return "Firewood to be used for building a campfire.\n"
				 .."Place on the ground to stack wood a stronger fire."
		end
	end
	
	-- bedroll
	for _, pattern in ipairs(BEDROLL_PATTERNS) do
		if recordId:find(pattern, 1, true) then
			return "A bedroll to be used for sleeping or camping.\n"
				 .."Place on the ground or attack to despawn."
		end
	end
end

I.InventoryExtender.registerTooltipModifier("SunsDusk_Containers", function(item, layout)
	if not types.Miscellaneous.objectIsInstance(item) and not types.Ingredient.objectIsInstance(item) then return layout end
	
	local recordId = item.recordId
	local rec = types.Miscellaneous.records[recordId] or types.Ingredient.records[recordId]
	local name = rec and rec.name and rec.name:lower() or ""
	
	-- blacklisted items
	for _, bl in ipairs(VESSEL_BLACKLIST) do
		if recordId:find(bl, 1, true) or name:find(bl, 1, true) then
			return layout
		end
	end
	
	local description = getMiscDescription(item)
	
	if not description then return layout end
	
	local content = getInnerContent(layout)
	if not content then return layout end
	
	addSeparator(content)
	addText(content, description, COLORS.LABEL)
	
	return layout
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Books and Recipes
-- ═══════════════════════════════════════════════════════════════════════	

I.InventoryExtender.registerTooltipModifier("SunsDusk_Books", function(item, layout)
	local recordId = item.recordId
	local tooltip = inventoryExtenderGenericTooltips[recordId]
	if not tooltip then return layout end
	
	local content = getInnerContent(layout)
	if not content then return layout end
	
	addSeparator(content)
	addText(content, tooltip, COLORS.LABEL)
	if G_cookingRecipes[recordId] then
		if saveData.m_cooking.readRecipes[recordId] then
			addText(content, "Known", COLORS.EQUIPPED)
		else
			addText(content, "Unread", COLORS.TOXIC)
		end
	end
	return layout
end)	

-- ═══════════════════════════════════════════════════════════════════════
-- Torches and Lights
-- ═══════════════════════════════════════════════════════════════════════

I.InventoryExtender.registerTooltipModifier("SunsDusk_Lights", function(item, layout)
	if not types.Light.objectIsInstance(item) then return layout end
	
	local recordId = item.recordId
	local rec = types.Light.record(item)
	local name = rec and rec.name and rec.name:lower() or ""
	
	local tempBonus = nil
	
	for _, data in ipairs(LIGHT_TEMP_DATA) do
		if recordId:find(data.pattern, 1, true) or name:find(data.pattern, 1, true) then
			tempBonus = data.temp
			break
		end
	end
	
	if not tempBonus then return layout end
	
	local content = getInnerContent(layout)
	if not content then return layout end
	
	addSeparator(content)
	addText(content, "Provides +" .. tempBonus .. " warmth.", COLORS.WARMTH_HOT)
	
	return layout
end)

------------------------------------------------------------------------------------------------------------

end)