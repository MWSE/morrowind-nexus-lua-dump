local makeBorder = require("scripts.CraftingFramework.ui_makeborder") 
local util = require('openmw.util')
local v2 = util.vector2
local ui = require('openmw.ui')
local self = require("openmw.self")
local core = require('openmw.core')
local types = require('openmw.types')


------------------------------ configuration ------------------------------

-- mirrors quickloot's 'itemTooltip'
local uiElementName = "DisenchantingTooltip"
local OPACITY = 0.8
local TOOLTIP_MELEE_INFO = false
-- options: none, thin, normal, thick, verythick
local BORDER_STYLE = "thin"
-- options: left, right, center
local TOOLTIP_TEXT_ALIGNMENT = "left"
local textSizeMult = 1
-- requires quickloot's special font
local FONT_FIX = true
local SHORT_TEXTS = false
ENCHANTMENT_BAR_COLOR = util.color.hex("cf4123")
local location = {
	anchor = v2(0,0),
	relativePosition = util.vector2(0, 0),
}

------------------------------------------------------------

local background = ui.texture { path = 'black' }
local white = ui.texture { path = 'white' }
local borderOffset = BORDER_STYLE == "verythick" and 4 or BORDER_STYLE == "thick" and 3 or BORDER_STYLE == "normal" and 2 or (BORDER_STYLE == "thin" or BORDER_STYLE == "max performance") and 1 or 0
local borderFile = "thin"
if BORDER_STYLE == "verythick" or BORDER_STYLE == "thick" then
	borderFile = "thick"
end
-- textColor set per-instance so theme toggles take effect
local quickLootText = {
	props = {
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,0.75),
	}
}

local tooltipText = {
	props = {
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,0.75),
		textAlignV = ui.ALIGNMENT.Center,
		textAlignH = ui.ALIGNMENT.Center,
	}
}

local textureCache = {}
local function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

local function formatNumber(num, mode)
	local text = math.floor(num*10)/10
	if mode == "v/w" then
		text = (math.floor(num*10+0.5)/10)
	elseif mode == "weight" then
		text = math.floor(num*10+0.5)/10
	end
	if text >99 or text > 1.2 and (text%1 <=0.1 or text%1 >=0.9) then
		text = math.floor(text)
	end
	infSymbol = false
	if text == 1/0 then
		if FONT_FIX then 
			text = hextoutf8(0x221e)
		else
			text = "-" -- instead of "Inf"
			infSymbol = true
		end
	elseif text >= 10^6-100 then -- >=1m
		text = text/1000
		local e = math.floor(math.log10(text))
		text = text + 10^e*1.005-10^e
		local suffixes = {"K","M","G","T","P","E","Z"}
		local i = 1
		while text >= 1000 do
			text = text/1000
			i=i+1
		end
		-- explicit round, not %f
		text = math.floor(text*100)/100
		text = string.format("%.2f",text)
		if #text == 6 then
			text=text:sub(1,3)
		else
			text = text:sub(1,4)
		end
		text = text.." "..suffixes[i]
	elseif text >= 1000 then
		text = math.floor(text/1000)..(not FONT_FIX and hextoutf8(0x200a)..hextoutf8(0x200a) or "")..string.format("%.3f",math.floor((text%1000)/1000)):sub(3)
	end
	return ""..text
end

-- mirrors the engine's EffectCostMethod::GameEnchantment cost calc
function getMaxEnchantmentCharge(enchantment)
	if not enchantment.autocalcFlag then
		return enchantment.charge
	end
	local cost = 0
	for _, effect in pairs(enchantment.effects) do
		local hasMagnitude = effect.effect.hasMagnitude
		local hasDuration = effect.effect.hasDuration
		local appliedOnce = effect.effect.isAppliedOnce
		local minMagn = hasMagnitude and effect.magnitudeMin or 1
		local maxMagn = hasMagnitude and effect.magnitudeMax or 1
		local duration = hasDuration and effect.duration or 1
		if not appliedOnce then
			duration = math.max(1, duration)
		end
		local costMult = core.getGMST("fEffectCostMult")
		local durationOffset = 0
		local minArea = 0
		local x = 0.5 * (minMagn + maxMagn)
		x = x * (0.1 * effect.effect.baseCost)
		x = x * (durationOffset + duration)
		x = x + (0.05 * math.max(minArea, effect.area or 0) * effect.effect.baseCost)
		if effect.range == core.magic.RANGE.Target then
			x = x * 1.5
		end
		x = math.floor(x * costMult + 0.5)
		cost = cost + x
	end

	if enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
		cost = cost * core.getGMST("iMagicItemChargeOnce")
	elseif enchantment.type == 	core.magic.ENCHANTMENT_TYPE.CastOnUse then
		cost = cost * core.getGMST("iMagicItemChargeUse")
	elseif enchantment.type == 	core.magic.ENCHANTMENT_TYPE.CastOnStrike then
		cost = cost * core.getGMST("iMagicItemChargeStrike")
	elseif enchantment.type == 	core.magic.ENCHANTMENT_TYPE.ConstantEffect then
		cost = cost * core.getGMST("iMagicItemChargeConst")
	end
	return cost or 0
end

local function getWeaponTypeName(typeId)
	if typeId == types.Weapon.TYPE.Arrow then
		return core.getGMST("sSkillMarksman")
	elseif typeId == types.Weapon.TYPE.AxeOneHand then
		return core.getGMST("sSkillAxe")..", "..core.getGMST("sOneHanded")
	elseif typeId == types.Weapon.TYPE.AxeTwoHand then
		return core.getGMST("sSkillAxe")..", "..core.getGMST("sTwoHanded")
	elseif typeId == types.Weapon.TYPE.BluntOneHand then
		return core.getGMST("sSkillBluntweapon")..", "..core.getGMST("sOneHanded")
	elseif typeId == types.Weapon.TYPE.BluntTwoClose then
		return core.getGMST("sSkillBluntweapon")..", "..core.getGMST("sTwoHanded")
	elseif typeId == types.Weapon.TYPE.BluntTwoWide then
		return core.getGMST("sSkillBluntweapon")..", "..core.getGMST("sTwoHanded")
	elseif typeId == types.Weapon.TYPE.Bolt then
		return core.getGMST("sSkillMarksman")
	elseif typeId == types.Weapon.TYPE.LongBladeOneHand then
		return core.getGMST("sSkillLongblade")..", "..core.getGMST("sOneHanded")
	elseif typeId == types.Weapon.TYPE.LongBladeTwoHand then
		return core.getGMST("sSkillLongblade")..", "..core.getGMST("sTwoHanded")
	elseif typeId == types.Weapon.TYPE.MarksmanBow then
		return core.getGMST("sSkillMarksman")
	elseif typeId == types.Weapon.TYPE.MarksmanCrossbow then
		return core.getGMST("sSkillMarksman")
	elseif typeId == types.Weapon.TYPE.MarksmanThrown then
		return core.getGMST("sSkillMarksman")
	elseif typeId == types.Weapon.TYPE.ShortBladeOneHand then
		return core.getGMST("sSkillShortblade")..", "..core.getGMST("sOneHanded")
	elseif typeId == types.Weapon.TYPE.SpearTwoWide then
		return core.getGMST("sSkillSpear")..", "..core.getGMST("sTwoHanded")
	end
	return "Unknown"
end

local function getArmorTypeName(typeId)
	for name, id in pairs(types.Armor.TYPE) do
		if id == typeId then return name end
	end
	return "Unknown Armor Type"
end

local function getClothingTypeName(typeId)
	for name, id in pairs(types.Clothing.TYPE) do
		if id == typeId then return name end
	end
	return "Unknown Clothing Type"
end

local function getMagicEffectName(effectId)
	if effectId == "fortifyskill" or effectId == "fortifyattribute" then
		return core.getGMST("sFortify")
	end
	local effect = core.magic.effects.records[effectId]
	if effect then return effect.name end
	return "Unknown Effect"
end

local function getAttributeName(attributeId)
	for name, id in pairs(core.stats.ATTRIBUTE) do
		if id == attributeId then return name end
	end
	return "Unknown Attribute"
end

local function getSkillName(skillId)
	for name, id in pairs(core.stats.SKILL) do
		if id == skillId then return name end
	end
	return "Unknown Skill"
end

local function getEnchantmentTypeName(typeId)
	local types = {
		[core.magic.ENCHANTMENT_TYPE.CastOnce] = "sItemCastOnce",
		[core.magic.ENCHANTMENT_TYPE.CastOnUse] = "sItemCastWhenUsed",
		[core.magic.ENCHANTMENT_TYPE.CastOnStrike] = "sItemCastWhenStrikes",
		[core.magic.ENCHANTMENT_TYPE.ConstantEffect] = "sItemCastConstant"
	}

	return core.getGMST(types[typeId] or "sMagicEffects")
end


-- read-only overlay: stats fields shadow record; modifier chains set ctx.modified.
local function withStats(record, stats)
	if not stats then return record end
	return setmetatable({}, {__index = function(_, k)
		local v = stats[k]
		if v ~= nil then return v end
		return record[k]
	end})
end

local function getWeaponData(record, stats)
	record = withStats(record, stats)
	return {
		type = record.type,
		typeName = getWeaponTypeName(record.type),
		subtype = record.subtype,
		damage = {
			chopMin = math.min(record.chopMinDamage, record.chopMaxDamage),
			chopMax = record.chopMaxDamage,
			slashMin = math.min(record.slashMinDamage, record.slashMaxDamage),
			slashMax = record.slashMaxDamage,
			thrustMin = math.min(record.thrustMinDamage, record.thrustMaxDamage),
			thrustMax = record.thrustMaxDamage,
		},
		speed = record.speed,
		reach = record.reach,
		durability = {
			current = record.health,
			max = record.health
		},
		enchantCapacity = record.enchantCapacity,
	}
end

local function getArmorData(record, stats)
	record = withStats(record, stats)
	local durabilityCurrent = record.health
	local durabilityMax = record.health
	
	local referenceWeight = 0
	local recordType = record.type
	if recordType == types.Armor.TYPE.Boots then
		referenceWeight = core.getGMST("iBootsWeight")
	elseif recordType == types.Armor.TYPE.Cuirass then
		referenceWeight = core.getGMST("iCuirassWeight")
	elseif recordType == types.Armor.TYPE.Greaves then
		referenceWeight = core.getGMST("iGreavesWeight")
	elseif recordType == types.Armor.TYPE.Helmet then
		referenceWeight = core.getGMST("iHelmWeight")
	elseif recordType == types.Armor.TYPE.LBracer then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.RBracer then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.LPauldron then
		referenceWeight = core.getGMST("iPauldronWeight")
	elseif recordType == types.Armor.TYPE.RPauldron then
		referenceWeight = core.getGMST("iPauldronWeight")
	elseif recordType == types.Armor.TYPE.LGauntlet then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.RGauntlet then
		referenceWeight = core.getGMST("iGauntletWeight")
	elseif recordType == types.Armor.TYPE.Shield then
		referenceWeight = core.getGMST("iShieldWeight")
	end
	local epsilon = 5e-4
	local class = "???"
	local skill = 0
	if record.weight == 0 then
		class = core.getGMST("sSkillUnarmored")
		skill = types.Player.stats.skills.unarmored(self).modified
	elseif record.weight <= referenceWeight * core.getGMST("fLightMaxMod") + epsilon then
		class = core.getGMST("sLight")
		skill = types.Player.stats.skills.lightarmor(self).modified
	elseif record.weight <= referenceWeight * core.getGMST("fMedMaxMod") + epsilon then
		class = core.getGMST("sMedium")
		skill = types.Player.stats.skills.mediumarmor(self).modified
	else
		class = core.getGMST("sHeavy")
		skill = types.Player.stats.skills.heavyarmor(self).modified
	end
	local playerArmor = record.baseArmor * skill / core.getGMST("iBaseArmorSkill")
	return {
		type = recordType,
		typeName = getArmorTypeName(record.type),
		baseArmor = record.baseArmor,
		class = class,
		playerArmor = playerArmor,
		durability = {
			current = durabilityCurrent or 0,
			max = durabilityMax or 0
		},
		enchantCapacity = record.enchantCapacity,
	}
end

local function getClothingData(record, stats)
	record = withStats(record, stats)
	return {
		type = record.type,
		typeName = getClothingTypeName(record.type),
		enchantCapacity = record.enchantCapacity,
	}
end


local function getEffects(eff, type)
	local effects = {}

	for i, effect in ipairs(eff) do
		local text = getMagicEffectName(effect.id)
		if effect.affectedSkill then
			text = text.." "..(core.getGMST("sSkill"..effect.affectedSkill) or "??")
			if SHORT_TEXTS then
				text = (core.getGMST("sSkill"..effect.affectedSkill) or "??").. " +"
			end
		elseif effect.affectedAttribute then
			text = text.." "..(core.getGMST("sAttribute"..effect.affectedAttribute) or "??")
			if SHORT_TEXTS then
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
				text = SHORT_TEXTS and (text.."INT") or (text..core.getGMST("sXTimesINT"))
			else
				if effect.magnitudeMin == effect.magnitudeMax then
					text = text.." "..effect.magnitudeMin
				else
					text = text.." "..effect.magnitudeMin.."-"..effect.magnitudeMax
				end
				if effect.id == core.magic.EFFECT_TYPE.Chameleon then
					text = text.."%"
				end
				text =  SHORT_TEXTS and (text) or (text.." "..core.getGMST("sPoints"))
			end
		end
		if type ~= "constant" then
			if effectPrototype.hasDuration then
				local dur = math.max(1,effect.duration)
				if SHORT_TEXTS then
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
			if type ~= "potion" then
				if SHORT_TEXTS then
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
		table.insert(effects, {
			id = effect.id,
			text = text,
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
	end
	return effects
end

local function getEnchantmentData(record, enchantId, enchantDef)
	local enchantmentRecord
	if enchantDef == "" or enchantDef == 1 then
		-- explicit "no enchantment" sentinel
		return nil
	elseif type(enchantDef) == "string" then
		enchantmentRecord = core.magic.enchantments.records[enchantDef]
		if not enchantmentRecord then return nil end
	elseif type(enchantDef) == "table" and enchantDef.effects and #enchantDef.effects > 0 then
		-- preview path: synthesize record shape, shadow each effect with its MagicEffect
		local effects = {}
		for _, eff in ipairs(enchantDef.effects) do
			local clone = {}
			for k, v in pairs(eff) do clone[k] = v end
			clone.effect = clone.effect or (clone.id and core.magic.effects.records[clone.id])
			effects[#effects+1] = clone
		end
		enchantmentRecord = {
			type = enchantDef.type,
			cost = enchantDef.cost,
			charge = enchantDef.charge,
			autocalcFlag = enchantDef.autocalc,
			effects = effects,
		}
	else
		local enchantment = enchantId and record.enchant ~= "" and record.enchant
		if not enchantment then return nil end
		enchantmentRecord = core.magic.enchantments.records[enchantment]
		if not enchantmentRecord then return nil end
	end

	local maxCharge = getMaxEnchantmentCharge(enchantmentRecord)

	local charge = {
		current = maxCharge,
		max = maxCharge
	}
	
	local effects = getEffects(enchantmentRecord.effects, enchantmentRecord.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect and "constant")
	
	if enchantmentRecord.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
		charge = nil
	elseif enchantmentRecord.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
		charge = nil
	end
	
	
	return {
		type = enchantmentRecord.type,
		typeName = getEnchantmentTypeName(enchantmentRecord.type),
		cost = enchantmentRecord.cost,
		charge = charge,
		effects = effects,
		autocalc = enchantmentRecord.autocalcFlag
	}
end



function getIngredientEffects(record)
	local effects = {}
	for a,effect in pairs(record.effects) do
		local text = getMagicEffectName(effect.id)
		if effect.affectedSkill then
			text = text.." "..(core.getGMST("sSkill"..effect.affectedSkill) or "??")
		elseif effect.affectedAttribute then
			text = text.." "..(core.getGMST("sAttribute"..effect.affectedAttribute) or "??")
		end
		table.insert(effects, {
			id = effect.id,
			text = text,
			skillId = effect.affectedSkill,
			attributeId = effect.affectedAttribute,
			icon = effect.effect.icon,
		})
	end
	return effects
end

local function getItemInfo(record, customName, qualityMult, count, newValue, enchantId, item, stats, enchantDef)
	local recordId = record.id
	record = withStats(record, stats)
	local info = {
		name = customName or record.name,
		id = recordId,
		weight = record.weight,
		value = newValue or record.value,
		description = record.description or "",
		icon = record.icon,
		count = count
	}
	if types["Weapon"].records[recordId] then
		info.type = "weapon"
		info.weaponData = getWeaponData(record, stats)
		info.enchantCapacity = info.weaponData.enchantCapacity
		info.qualityMult = qualityMult
	elseif types["Armor"].records[recordId] then
		info.type = "armor"
		info.armorData = getArmorData(record, stats)
		info.enchantCapacity = info.armorData.enchantCapacity
		info.qualityMult = qualityMult
	elseif types["Clothing"].records[recordId] then
		info.type = "clothing"
		info.clothingData = getClothingData(record, stats)
		info.enchantCapacity = info.clothingData.enchantCapacity
		info.qualityMult = qualityMult
	elseif types["Ingredient"].records[recordId] then
		info.type = "ingredient"
		info.ingredientEffects = getIngredientEffects(record)
	elseif types["Potion"].records[recordId] then
		info.type = "potion"
		info.potionEffects = getEffects(record.effects, "potion")
	elseif types["Apparatus"].records[recordId] then
		info.type = "apparatus"
		info.quality = record.quality
	elseif types["Lockpick"].records[recordId] then
		info.type = "lockpick"
		info.quality = record.quality
		info.uses = record.maxCondition
	elseif types["Probe"].records[recordId] then
		info.type = "probe"
		info.quality = record.quality
		info.uses = record.maxCondition
	elseif types["Repair"].records[recordId] then
		info.type = "repair"
		info.quality = record.quality
		info.uses = record.maxCondition
	elseif types["Miscellaneous"].records[recordId] then
		if recordId == "gold_001" or record.isKey then
			info.value = 0
		end
		if recordId:sub(1, #"misc_soulgem_") == "misc_soulgem_" then
			local soulId = item and item:isValid() and types.Item.itemData(item).soul
			if soulId then
				local creature = types.Creature.records[soulId]
				if creature then
					info.soulName = creature.name
					info.soulValue = creature.soulValue
				end
			end
		end
	end
	-- prefer live condition when an item instance is available
	if item and item:isValid() and info.uses then
		info.currentUses = types.Item.itemData(item).condition
	end
	info.enchantment = getEnchantmentData(record, enchantId, enchantDef)
	if info.enchantCapacity then
		info.enchantCapacity = info.enchantCapacity/0.1*core.getGMST("FEnchantmentMult")
	end
	return info
end

------------------------------ makeTooltip ------------------------------

-- accepts opts table { record, item, value, customName, qualityMult, stats, count, enchantId, enchRemoveColor, recipe }
-- or positional args. returns the layout for the tooltip.
return function (record, newValue, customName, qualityMult, count, enchantId, enchRemoveColor)
	local item
	local customLine
	local stats
	local recipe
	local enchantDef
	if type(record) == "table" and record.record then
		item = record.item
		newValue = record.value or newValue
		customName = record.customName or customName
		qualityMult = record.qualityMult or qualityMult
		stats = record.stats
		count = record.count or count
		enchantId = record.enchantId or enchantId
		enchantDef = record.enchantment
		enchRemoveColor = record.enchRemoveColor or enchRemoveColor
		customLine = record.customLine
		recipe = record.recipe
		record = record.record
	end
	if not record then
		print("INVALID", record)
		return{
			type = ui.TYPE.Text,
			layer = 'Notification',
			name = uiElementName,
			template = borderTemplate,
			props = {
				text = tostring(record).." is invalid",
				textSize = 20,
				textColor = util.color.rgb(1,0,0),
			},
		}
	end
	
	if enchantId == nil then
		enchantId = record.enchant
	end
	if customName == true then
		customName = record.name
	end
	local info = getItemInfo(record, customName, qualityMult, count, newValue, enchantId, item, stats, enchantDef)
	if not info then return end
	local tooltipTextAlignment = ui.ALIGNMENT.Center
	if TOOLTIP_TEXT_ALIGNMENT == "left" then
		tooltipTextAlignment = ui.ALIGNMENT.Start
	elseif TOOLTIP_TEXT_ALIGNMENT == "right" then
		tooltipTextAlignment = ui.ALIGNMENT.End
	end
	local borderTemplate = makeBorder(borderFile, borderColor or nil, borderOffset, {
			type = ui.TYPE.Image,
			props = {
				resource = background,
				relativeSize  = v2(1,1),
				alpha = OPACITY,
			}
		}).borders
	local root ={
		type = ui.TYPE.Container,
		layer = 'Notification',
		name = uiElementName,
		props = {
		},
		content = ui.content {
		}
	}
	
	local flex = {
		type = ui.TYPE.Flex,
		name = 'tooltipFlex',
		props = {
			autoSize = true,
			arrange = tooltipTextAlignment,
		},
		content = ui.content {
		}
	}
	
	root.content:add(flex)

	root.props = location
	local function makeText(str, color)
		return {
			type = ui.TYPE.Text,
			template = tooltipText,
			props = {
				text = ""..str.." ",
				textSize = S_FONT_SIZE*textSizeMult,
				textAlignH = ui.ALIGNMENT.End,
				textColor = color or textColor,
				autoSize = true
			},
		}
	end
	
	local function textElement(str, color)
		flex.content:add(makeText(str, color))
	end
	
	local function statTextElement(str1, str2, color)
		color = color or morrowindGold
		local lineFlex = { 
			type = ui.TYPE.Flex,
			props = {
				horizontal = true
			},
			content = ui.content{}
		}
		flex.content:add (lineFlex)
		lineFlex.content:add { 
			type = ui.TYPE.Text,
			template = tooltipText,
			props = {
				text = ""..str1.."",
				textSize = S_FONT_SIZE*textSizeMult,
				textAlignH = ui.ALIGNMENT.End,
				textColor = color,
				autoSize = true
			},
		}
		lineFlex.content:add {
			type = ui.TYPE.Text,
			template = tooltipText,
			props = {
				text = ""..str2.." ",
				textSize = S_FONT_SIZE*textSizeMult,
				textAlignH = ui.ALIGNMENT.End,
				textColor = textColor,
				autoSize = true
			},
		}
	end
	
	flex.content:add{ props = { size = v2(1, 1) * 1 } }
	
	local name = info.name
	if info.soulName then
		name = name.." ("..info.soulName..")"
	end
	if info.count and info.count > 1 then
		name = name.." ("..info.count..")"
	end

	if customName then
		textElement(name, textColor)
	end

	flex.content:add{ props = { size = v2(1, 1) * 1 } }
	
	if info.uses then
		if info.currentUses then
			statTextElement(core.getGMST("sCondition")..": ", math.floor(info.currentUses).."/"..math.floor(info.uses),morrowindGold)
		else
			statTextElement(core.getGMST("sUses")..": ",math.floor(info.uses),morrowindGold)
		end
	end
	
	if info.quality then
		statTextElement(core.getGMST("sQuality")..": ",math.floor(info.quality*10+0.5)/10,morrowindGold)
	end
	
	if info.type == "armor" then
		statTextElement(core.getGMST("sArmorRating")..": ",math.floor(info.armorData.baseArmor).." (".. math.floor(info.armorData.playerArmor)..")",morrowindGold)
	end
	
	if info.type == "weapon" then
		textElement(info.weaponData.typeName,  textColor)
		if info.weaponData.typeName == core.getGMST("sSkillMarksman") then
			statTextElement(core.getGMST("sAttack")..": ", info.weaponData.damage.chopMin.."-"..info.weaponData.damage.chopMax,morrowindGold)
		else
			statTextElement(core.getGMST("sChop")..": ", info.weaponData.damage.chopMin.."-"..info.weaponData.damage.chopMax,morrowindGold)
			statTextElement(core.getGMST("sSlash")..": ", info.weaponData.damage.slashMin.."-"..info.weaponData.damage.slashMax,morrowindGold)
			statTextElement(core.getGMST("sThrust")..": ", info.weaponData.damage.thrustMin.."-"..info.weaponData.damage.thrustMax,morrowindGold)
		end
	end
	
	local weaponOrArmor = info.weaponData or info.armorData

	if info.enchantCapacity and not info.enchantment then
		statTextElement(core.getGMST("sEnchanting")..": ", math.floor(info.enchantCapacity),morrowindGold)
	end
	if info.type == "weapon" and TOOLTIP_MELEE_INFO then
		statTextElement(core.getGMST("sRange")..": ",(math.floor((info.weaponData.reach*6.05)*10)/10).." "..core.getGMST("sfootarea"),morrowindGold)
		statTextElement(core.getGMST("sAttributeSpeed")..": ",math.floor((info.weaponData.speed)*100+0.5).."%",morrowindGold)
	end
	
	if info.weight and info.weight > 0 then
		local armorClass = info.armorData and info.armorData.class
		if armorClass then
			armorClass = " ("..armorClass..")"
		else
			armorClass = ""
		end
		statTextElement(core.getGMST("sWeight")..": ", formatNumber(info.weight, "weight")..armorClass,morrowindGold)
	end
	
	if info.value and info.value > 0 then
		statTextElement(core.getGMST("sValue")..": ", formatNumber(math.floor(info.value), "value"),morrowindGold)
	end	
	
	if info.qualityMult and info.qualityMult ~= 1 then
		local qColor = info.qualityMult < 1 and util.color.rgb(1, 0.4, 0.4) or morrowindGold
		statTextElement(core.getGMST("sQuality")..": ", math.floor(info.qualityMult * 100 + 0.5) .. "%", qColor)
	end
	
	local function printEffects(effects, isPotion)
		local skill = types.Player.stats.skills.alchemy(self).modified
		local gmst = core.getGMST("fWortChanceValue")
		
		local effectFlex = {
				type = ui.TYPE.Flex,
				props = {
					position = v2(0, 0),
					anchor = v2(0.5,0),
					relativePosition = v2(0.5, 0),
				},
				content = ui.content({})
			}
		flex.content:add(effectFlex)
		for i,effect in pairs(effects) do
			local effectFlex2 ={
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
				},
				content = ui.content({})
			}
			effectFlex.content:add(effectFlex2)
			if skill >= i * gmst or not isPotion then
				effectFlex2.content:add{ props = { size = v2(5, 1) } }
	
				effectFlex2.content:add {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(effect.icon),
						tileH = false,
						tileV = false,
						size = v2(S_FONT_SIZE*textSizeMult-1,S_FONT_SIZE*textSizeMult-1),
						alpha = 0.7,
					}
				}
				effectFlex2.content:add { 
					type = ui.TYPE.Text,
					template = quickLootText,
					props = {
						text = " "..effect.text.." ",
						textSize = S_FONT_SIZE*textSizeMult,
						size = v2(0,S_FONT_SIZE*textSizeMult),
						textAlignH = ui.ALIGNMENT.Center,
						textColor = enchRemoveColor or textColor,
					},
				}
			else
				effectFlex2.content:add{ props = { size = v2(5 + S_FONT_SIZE*textSizeMult-1, 1) } }
				effectFlex2.content:add {
					type = ui.TYPE.Text,
					template = quickLootText,
					props = {
						text = " ? ",
						textSize = S_FONT_SIZE*textSizeMult,
						textAlignH = ui.ALIGNMENT.Center,
						textColor = textColor,
					},
				}
			end
		end
	end

	if info.enchantment then
		textElement(info.enchantment.typeName or "???", enchRemoveColor)
		flex.content:add{ props = { size = v2(1, 1) * 2 } }
		printEffects(info.enchantment.effects)
		if info.enchantment.charge then
			local borderTemplate = borderTemplate
			if enchRemoveColor then
				borderTemplate = makeBorder(borderFile, enchRemoveColor or nil, borderOffset, {
					type = ui.TYPE.Image,
					props = {
						resource = background,
						relativeSize  = v2(1,1),
						alpha = OPACITY,
					}
				}).borders
			end
			flex.content:add{ props = { size = v2(1, 1) * 3 } }
			local progressFlex ={
				type = ui.TYPE.Flex,
				props = {
					position = v2(0, 0),
					size = v2(0,S_FONT_SIZE*textSizeMult),
					anchor = v2(0.5,0),
					relativePosition = v2(0.5, 0),
					horizontal = true,
				},
				content = ui.content({})
			}
			flex.content:add(progressFlex)
			progressFlex.content:add {
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = " "..core.getGMST("sCharges").." ",
					textSize = S_FONT_SIZE*textSizeMult,
					size = v2(0,S_FONT_SIZE*textSizeMult),
					textAlignH = ui.ALIGNMENT.Center,
					textColor = enchRemoveColor or textColor,
				},
			}
			-- charge bar
			local progressBar =
			{
				type = ui.TYPE.Widget,
				props = {
					size = v2(S_FONT_SIZE*textSizeMult*6, S_FONT_SIZE*textSizeMult),
					anchor = v2(0.5,0),
					relativePosition = v2(0.5, 0),
				},
				content = ui.content {}
			}
			progressFlex.content:add(progressBar)
			progressBar.content:add {
				type = ui.TYPE.Image,
				props = {
					resource = background,
					tileH = false,
					tileV = false,
					relativeSize  = v2(1,1),
					relativePosition = v2(0,0),
					alpha = 0.3,
				}
			}
			progressBar.content:add {
				type = ui.TYPE.Image,
				props = {
					resource = white,
					tileH = false,
					tileV = false,
					relativeSize  = v2(math.min(1,info.enchantment.charge.current/info.enchantment.charge.max),1),
					relativePosition = v2(0,0),
					alpha = 0.8,
					color = ENCHANTMENT_BAR_COLOR,
				}
			}
			progressBar.content:add {
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = math.floor(info.enchantment.charge.current).." / "..math.floor(info.enchantment.charge.max),
					textSize = S_FONT_SIZE*textSizeMult,
					size = v2(0,S_FONT_SIZE*textSizeMult),
					relativeSize  = v2(0,1),
					relativePosition = v2(0.5, 0),
					anchor = v2(0.5,0),
					textAlignH = ui.ALIGNMENT.Center,
					textColor = enchRemoveColor or textColor,
				},
			}
			
			progressBar.content:add {
				template = borderTemplate,
				props = {
					relativeSize  = v2(1,1),
					alpha = 0.5,
				}
			}
			progressFlex.content:add{ props = { size = v2(1, 1) * 5 } }
		end
	end
	
	if info.potionEffects then
		flex.content:add{ props = { size = v2(1, 1) * 1 } }
		printEffects(info.potionEffects, true)
	end
	
	if info.ingredientEffects then
		flex.content:add{ props = { size = v2(1, 1) * 1 } }
		local skill = types.Player.stats.skills.alchemy(self).modified
		local gmst = core.getGMST("fWortChanceValue")
		
		for i,effect in pairs(info.ingredientEffects) do
			local effectFlex ={
				type = ui.TYPE.Flex,
				props = {
					position = v2(0, 0),
					horizontal = true,
				},
				content = ui.content({})
			}
			flex.content:add(effectFlex)
			
			if skill >= i * gmst then
				effectFlex.content:add{ props = { size = v2(5, 1) } }
				
				effectFlex.content:add {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(effect.icon),
						tileH = false,
						tileV = false,
						size = v2(S_FONT_SIZE*textSizeMult-1,S_FONT_SIZE*textSizeMult-1),
						alpha = 0.7,
					}
				}
				effectFlex.content:add {
					type = ui.TYPE.Text,
					template = quickLootText,
					props = {
						text = " "..effect.text.." ",
						textSize = S_FONT_SIZE*textSizeMult,
						textAlignH = ui.ALIGNMENT.Center,
						textColor = textColor,
					},
				}
			else
				effectFlex.content:add{ props = { size = v2(5 + S_FONT_SIZE*textSizeMult-1, 1) } }
				effectFlex.content:add {
					type = ui.TYPE.Text,
					template = quickLootText,
					props = {
						text = " ? ",
						textSize = S_FONT_SIZE*textSizeMult,
						textAlignH = ui.ALIGNMENT.Center,
						textColor = textColor,
					},
				}
			end
		end
	end
	if customLine then
		flex.content:add{ props = { size = v2(1, 1) * 5 } }
		textElement(customLine, util.color.rgb(0.5,0.5,0.5))
	end

	-- registered tooltip lines
	if tooltipLineChain then
		local lineCtx = {
			record = record,
			item = item,
			info = info,
			customName = customName,
			qualityMult = qualityMult,
			count = count,
			enchantId = enchantId,
			enchantment = enchantDef,
			stats = stats,
		}
		for _, entry in ipairs(tooltipLineChain.entries) do
			local text = entry.func(recipe, lineCtx)
			if text then
				flex.content:add{ props = { size = v2(1, 1) * 2 } }
				textElement(text, morrowindGold)
			end
		end
	end

	flex.content:add{ props = { size = v2(1+borderOffset, 1+borderOffset) * 2 } }

	-- registered tooltip modifiers
	if tooltipModifierChain then
		local modCtx = {
			root = root,
			flex = flex,
			makeText = makeText,
			textElement = textElement,
			statTextElement = statTextElement,
			record = record,
			item = item,
			info = info,
			customName = customName,
			qualityMult = qualityMult,
			count = count,
			enchantId = enchantId,
			enchantment = enchantDef,
			stats = stats,
		}
		-- thread crafting context for recipe-bound tooltips; mirrors what
		-- the stats/enchantment previews would resolve at this moment
		if recipe then
			local touches = getActiveTouches(recipe)
			modCtx.touches = touches
			modCtx.ingredients = resolveIngredients(recipe, touches)
		end
		for _, entry in ipairs(tooltipModifierChain.entries) do
			if entry.func(recipe, modCtx) == false then break end
		end
	end

	return root
end