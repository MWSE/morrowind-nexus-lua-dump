-- local helpers = require("scripts.OwnlysQuickLoot.ql_helpers")
-- readFont, texText, rgbToHsv, hsvToRgb,fromutf8,toutf8,hextoutf8,formatNumber,tableContains = unpack(helpers) -- (uses formatNumber)
-- MODNAME = "OwnlysQuickLoot"
-- playerSection = storage.playerSection('SettingsPlayer'..MODNAME)
-- background = ui.texture { path = 'black' }
-- white = ui.texture { path = 'white' }
-- util = require('openmw.util')
-- ui = require('openmw.ui')
-- self = require("openmw.self")
-- core = require('openmw.core')
-- types = require('openmw.types')
-- makeBorder = require("scripts.OwnlysQuickLoot.ql_makeborder")
-- borderOffset = BORDER_STYLE == "verythick" and 4 or BORDER_STYLE == "thick" and 3 or BORDER_STYLE == "normal" and 2 or (BORDER_STYLE == "thin" or BORDER_STYLE == "max performance") and 1 or 0
-- uiLoc = v2(X/100,Y/100)
-- uiSize = v2(WIDTH/100,HEIGHT/100)
-- itemFontSize = 20
-- textSizeMult = ui.screenSize().y /1200*(uiSize.y/0.4)
-- quickLootText = {
-- 	props = {
-- 			textColor = FONT_TINT,--util.color.rgba(1, 1, 1, 1),
-- 			textShadow = true,
-- 			textShadowColor = util.color.rgba(0,0,0,0.75),
-- 			--textAlignV = ui.ALIGNMENT.Center,
-- 			--textAlignH = ui.ALIGNMENT.Center,
-- 	}
-- }
-- inspectedContainer
local pickpocket 
if vfs.fileExists("scripts/OwnlysQuickLoot/ql_pickpocket_overhaul.lua") then
	pickpocket = require("scripts.OwnlysQuickLoot.ql_pickpocket_overhaul")
else
	pickpocket = require("scripts.OwnlysQuickLoot.ql_pickpocket")
end
local SOUL_GEM_REBALANCE = true

tooltipText = {
	props = {
			textColor = FONT_TINT,--util.color.rgba(1, 1, 1, 1),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.75),
			textAlignV = ui.ALIGNMENT.Center,
			textAlignH = ui.ALIGNMENT.Center,
	}
}


function getMaxEnchantmentCharge(enchantment)
	if not enchantment.autocalcFlag then
		return enchantment.charge
	end
	local cost = 0
	for _, effect in pairs(enchantment.effects) do
		-- note: EffectCostMethod = EffectCostMethod::GameEnchantment
	
		-- float calcEffectCost(
        -- const ESM::ENAMstruct& effect, const ESM::MagicEffect* magicEffect, const EffectCostMethod method)
		-- {
        -- const MWWorld::ESMStore& store = *MWBase::Environment::get().getESMStore();
		--  if (!magicEffect)
		-- magicEffect = store.get<ESM::MagicEffect>().find(effect.mEffectID);
		local hasMagnitude = effect.effect.hasMagnitude -- bool hasMagnitude = !(magicEffect->mData.mFlags & ESM::MagicEffect::NoMagnitude);
        local hasDuration = effect.effect.hasDuration -- bool hasDuration = !(magicEffect->mData.mFlags & ESM::MagicEffect::NoDuration);
        local appliedOnce = effect.effect.isAppliedOnce -- bool appliedOnce = magicEffect->mData.mFlags & ESM::MagicEffect::AppliedOnce;
		local minMagn = hasMagnitude and effect.magnitudeMin or 1; -- int minMagn = hasMagnitude ? effect.mMagnMin : 1;
		local maxMagn = hasMagnitude and effect.magnitudeMax or 1; -- int maxMagn = hasMagnitude ? effect.mMagnMax : 1;
		--if (method == EffectCostMethod::PlayerSpell || method == EffectCostMethod::GameSpell)
        --{
        --    minMagn = std::max(1, minMagn);
        --    maxMagn = std::max(1, maxMagn);
        --}
		local duration = hasDuration and effect.duration or 1; -- int duration = hasDuration ? effect.mDuration : 1;
		if not appliedOnce then -- if (!appliedOnce)
			duration = math.max(1, duration) -- duration = std::max(1, duration);
		end
		local fEffectCostMult = core.getGMST("fEffectCostMult") -- static const float fEffectCostMult = store.get<ESM::GameSetting>().find("fEffectCostMult")->mValue.getFloat();
		-- static const float iAlchemyMod = store.get<ESM::GameSetting>().find("iAlchemyMod")->mValue.getFloat();
		local durationOffset = 0;            -- int durationOffset = 0;
        local minArea = 0;                   -- int minArea = 0;
        local costMult = fEffectCostMult;  -- float costMult = fEffectCostMult;
		-- if (method == EffectCostMethod::PlayerSpell)
        -- {
        --     durationOffset = 1;
        --     minArea = 1;
        -- }
        -- else if (method == EffectCostMethod::GamePotion)
        -- {
        --     minArea = 1;
        --     costMult = iAlchemyMod;
        -- }
		local x = 0.5 * (minMagn + maxMagn);                                          -- float x = 0.5 * (minMagn + maxMagn);
		x = x * (0.1 * effect.effect.baseCost);                                      -- x *= 0.1 * magicEffect->mData.mBaseCost;
		x = x * (durationOffset + duration);                                               -- x *= durationOffset + duration;
		x = x + (0.05 * math.max(minArea, effect.area) * effect.effect.baseCost);   -- x += 0.05 * std::max(minArea, effect.mArea) * magicEffect->mData.mBaseCost;
		
		if effect.range == core.magic.RANGE.Target then	--if (effect.mData.mRange == ESM::RT_Target)
			x = x * 1.5 -- effectCost *= 1.5;
		end
		x = math.floor(x * costMult + 0.5) -- round here i think (not 100% sure)
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
	-- Use the weapon type from the API's constants
	--local weaponTypes = types.Weapon.TYPE
	--
	---- Find the name by comparing the ID with the API constants
	--for name, id in pairs(weaponTypes) do
	--	if id == typeId then
	--		-- Format the name (convert from e.g. "LongBlade" to "Long Blade")
	--		return name
	--	end
	--end
	
	--return "Unknown Weapon Type"
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

-- Get armor type name using the API
local function getArmorTypeName(typeId)
	-- Use the armor type from the API's constants
	local armorTypes = types.Armor.TYPE
	
	-- Find the name by comparing the ID with the API constants
	for name, id in pairs(armorTypes) do
		if id == typeId then
			return name
		end
	end
	
	return "Unknown Armor Type"
end

-- Get clothing type name using the API
local function getClothingTypeName(typeId)
	-- Use the clothing type from the API's constants
	local clothingTypes = types.Clothing.TYPE
	
	-- Find the name by comparing the ID with the API constants
	for name, id in pairs(clothingTypes) do
		if id == typeId then
			return name
		end
	end
	
	return "Unknown Clothing Type"
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

-- Helper function for enchantment type names
local function getEnchantmentTypeName(typeId)
	local types = {
		[core.magic.ENCHANTMENT_TYPE.CastOnce] = "sItemCastOnce",
		[core.magic.ENCHANTMENT_TYPE.CastOnUse] = "sItemCastWhenUsed",
		[core.magic.ENCHANTMENT_TYPE.CastOnStrike] = "sItemCastWhenStrikes",
		[core.magic.ENCHANTMENT_TYPE.ConstantEffect] = "sItemCastConstant"
	}

	return core.getGMST(types[typeId] or "sMagicEffects")
end


-- Get detailed weapon data
local function getWeaponData(weapon)
	local record = types.Weapon.record(weapon)
   -- local durability = types.Weapon.durability(weapon)
	local durabilityCurrent = types.Item.itemData(weapon).condition
	local durabilityMax = types.Weapon.records[weapon.recordId].health
	
	
	return {
		type = record.type,
		typeName = getWeaponTypeName(record.type),
		subtype = record.subtype,
		damage = {
			chopMin = record.chopMinDamage,
			chopMax = record.chopMaxDamage,
			slashMin = record.slashMinDamage,
			slashMax = record.slashMaxDamage, 
			thrustMin = record.thrustMinDamage,
			thrustMax = record.thrustMaxDamage,
			
		},
		speed = record.speed,
		reach = record.reach,
		--ignoresNormalWeaponResistance = record.ignoresNormalWeaponResistance,
		--silver = record.silver,
		durability = durabilityCurrent and {
			current = durabilityCurrent,
			max = durabilityMax
		}
	}
end

-- Get detailed armor data
local function getArmorData(armor)
	local record = types.Armor.record(armor)
	--local durability = types.Armor.durability(armor)
	local durabilityCurrent = types.Item.itemData(armor).condition
	local durabilityMax = record.health
	--print((durabilityCurrent or "nil").." / "..(durabilityMax or "nil"))
	local baseArmor = record.baseArmor
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
	local playerArmor = baseArmor * skill / core.getGMST("iBaseArmorSkill")
	return {
		type = recordType,
		typeName = getArmorTypeName(record.type),
		baseArmor = baseArmor,
		class = class,
		playerArmor = playerArmor,
		durability = durabilityCurrent and {
			current = durabilityCurrent or 0,
			max = durabilityMax or 0
		}
	}
end

-- Get detailed clothing data
local function getClothingData(clothing)
	local record = types.Clothing.record(clothing)
	
	return {
		type = record.type,
		typeName = getClothingTypeName(record.type),
		enchantCapacity = record.enchantCapacity
	}
end


local function getEffects(eff, type)
	local effects = {}
	local shortTexts = TOOLTIP_SHORT_TEXT
	
	for i, effect in ipairs(eff) do
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
		if type ~= "constant" then --enchantmentRecord.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
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
			if type ~= "potion" then
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


-- Get enchantment data if present
local function getEnchantmentData(item)
	-- Check if item has an enchantment
   --if not types.Enchantment.objectHasRecord(item) then
   --	return nil
   --end
	--core.magic.enchantments.records['marara's boon']
   -- local enchantment = types.Enchantment.record(item)
	local record = item.type.record(item)
	local enchantment = item and (record.enchant or record.enchant ~= "" and record.enchant )
	if not enchantment then return nil end
	
	local enchantmentRecord = core.magic.enchantments.records[enchantment]
	if not enchantmentRecord then return nil end
	
	local maxCharge = getMaxEnchantmentCharge(enchantmentRecord) --enchantmentRecord.charge or 0

	local charge = {
		current = types.Item.itemData(item).enchantmentCharge or 0,
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



function getIngredientEffects(item)
	local effects = {}
	
	
	for a,effect in pairs(types.Ingredient.record(item).effects) do
		local text = getMagicEffectName(effect.id)
		if effect.affectedSkill then
			text = text.." "..(core.getGMST("sSkill"..effect.affectedSkill) or "??")
		elseif effect.affectedAttribute then
			text = text.." "..(core.getGMST("sAttribute"..effect.affectedAttribute) or "??")
		end
		--if effect.id >= 0 then -- Valid effect?
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

local function getItemInfo(item)
	if not item then return nil end
	local record = item.type.records[item.recordId]
	--for a,b in pairs(types) do
	--if b.objectIsInstance(item) then
	--	print(a)
	--end
	--end
	local info = {
		name = record.name,
		id = item.id,
		weight = record.weight,
		value = record.value,
		description = record.description or "",
		icon = record.icon
	}
	
	-- Determine item type and get type-specific data
	if types.Weapon.objectIsInstance(item) then
		info.type = "weapon"
		info.weaponData = getWeaponData(item)
		--core.sendGlobalEvent("OwnlysQuickLoot_test",{self, item})
		
	elseif types.Armor.objectIsInstance(item) then
		info.type = "armor"
		info.armorData = getArmorData(item)
	elseif types.Clothing.objectIsInstance(item) then
		info.type = "clothing"
		info.clothingData = getClothingData(item)
	elseif types.Ingredient.objectIsInstance(item) then
		info.type = "ingredient"
		info.ingredientEffects = getIngredientEffects(item)
	elseif types.Potion.objectIsInstance(item) then
		info.type = "potion"
		info.potionEffects = getEffects(types.Potion.record(item).effects, "potion")
	elseif types.Apparatus.objectIsInstance(item) then
		info.type = "apparatus"
		info.quality = types.Apparatus.record(item).quality
	elseif types.Lockpick.objectIsInstance(item) then
		info.type = "lockpick"
		info.quality = types.Lockpick.record(item).quality
		info.uses =  types.Item.itemData(item).condition
	elseif types.Probe.objectIsInstance(item) then
		info.type = "probe"
		info.quality = types.Probe.record(item).quality
		info.uses =  types.Item.itemData(item).condition
	elseif types.Repair.objectIsInstance(item) then
		info.type = "repair"
		info.quality = types.Repair.record(item).quality
		info.uses =  types.Item.itemData(item).condition
	elseif types.Miscellaneous.objectIsInstance(item) then
		if record.id == "gold_001" or record.isKey then
			info.value = 0
			--return nil
		end
		if record.id:sub(1, #"misc_soulgem_") == "misc_soulgem_" then
			local soulId = types.Item.itemData(item).soul
			if soulId then
				local creature = types.Creature.records[soulId]
				if creature then
					info.soulName = creature.name
					info.soulValue = creature.soulValue
					if SOUL_GEM_REBALANCE then
						info.value = math.floor(0.0001 * info.soulValue ^ 3 + 2 * info.soulValue)
					else
						info.value = math.floor(value * soulValue)
					end
				end
			end
		end
	end
	info.enchantment = getEnchantmentData(item)
	
	return info
end







-- MAIN FUNCTION
return function (item, highlightPosition, isPickpocketing, colorTheme, deposit) --makeTooltip
	local transparency = TRANSPARENCY
	if TOOLTIP_MODE == "off" then
		return
	end

	local itemRecord = item.type.records[item.recordId]
	local info = getItemInfo(item)
	if not info then return end
	local hudLayerSize = ui.layers[ui.layers.indexOf("HUD")].size
	local rootWidth = hudLayerSize.x * uiSize.x
	local rootHeight = hudLayerSize.y * uiSize.y
	local absPos = v2(hudLayerSize.x * uiLoc.x, hudLayerSize.y * uiLoc.y)
	local tooltipTextAlignment = ui.ALIGNMENT.Center
	if TOOLTIP_TEXT_ALIGNMENT == "left" then
		tooltipTextAlignment = ui.ALIGNMENT.Start
	elseif TOOLTIP_TEXT_ALIGNMENT == "right" then
		tooltipTextAlignment = ui.ALIGNMENT.End
	end
	local newBorderColor
	if colorTheme then 
		newBorderColor = util.color.rgba(colorTheme.r,colorTheme.g,colorTheme.b,0.5)
	end
	local borderTemplate = makeBorder(borderFile, newBorderColor or borderColor or nil, borderOffset, {
			type = ui.TYPE.Image,
			props = {
				resource = background,
				relativeSize  = v2(1,1),
				alpha = transparency,
			}
		}).borders

	local root = ui.create({
		type = ui.TYPE.Container,
		layer = 'HUD',
		name = 'itemTooltip',
		template = borderTemplate,
		props = {
		},
		content = ui.content {
		}
	})
	
	local flex = {
		type = ui.TYPE.Flex,
		layer = 'HUD',
		name = 'tooltipFlex',
		props = {
			autoSize = true,
			arrange = tooltipTextAlignment,
		},
		content = ui.content {
		}
	}
	
	root.layout.content:add(flex)
	
	
	-- TOOLTIP LOCATION:
	if TOOLTIP_MODE == "top" then
		root.layout.props = {
			anchor = v2(0.5,1), 
			position = v2(absPos.x, absPos.y-rootHeight/2),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "bottom" then
		local temp = 0
		if FOOTER_HINTS == "Disabled" then
			temp = outerHeaderFooterHeight
		end
		root.layout.props = {
			anchor = v2(0.5,0), 
			position = v2(absPos.x, absPos.y+rootHeight/2+1-temp),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "left" then
		root.layout.props = {
			anchor = v2(1,0), 
			position = v2(absPos.x-rootWidth/2, absPos.y-rootHeight/2+highlightPosition),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "right" then
		root.layout.props = {
			anchor = v2(0,0), 
			position = v2(absPos.x+rootWidth/2, absPos.y-rootHeight/2+highlightPosition),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "left (fixed)" then
		root.layout.props = {
			anchor = v2(1,0.5), 
			position = v2(absPos.x-rootWidth/2, absPos.y),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "left (fixed 2)" then
		root.layout.props = {
			anchor = v2(1,0), 
			position = v2(absPos.x-rootWidth/2, absPos.y-boxHeight/4),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "left (fixed 3)" then
		root.layout.props = {
			anchor = v2(0.5,0), 
			position = v2(math.max(absPos.x-rootWidth*0.9,(absPos.x-rootWidth/2)/2), absPos.y-boxHeight/4),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "right (fixed 2)" then
		root.layout.props = {
			anchor = v2(0,0), 
			position = v2(absPos.x+rootWidth/2, absPos.y-boxHeight/4),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "right (fixed 3)" then
		root.layout.props = {
			anchor = v2(0.5,0), 
			position = v2(math.min(99999999--[[absPos.x+rootWidth*0.9]],(uiWidth+absPos.x+rootWidth/2)/2), absPos.y-boxHeight/4),
			autoSize = true
		}
	elseif TOOLTIP_MODE == "crosshair" then
		root.layout.props = {
			anchor = v2(0.5,0), 
			position = v2(uiWidth/2, uiHeight/2+20),
			autoSize = true
		}
	else --right (fixed)
		root.layout.props = {
			anchor = v2(0,0.5), 
			position = v2(absPos.x+rootWidth/2, absPos.y),
			autoSize = true
		}
	end
	-- /TOOLTIP LOCATION
	
	
	local ench = item and (item.enchant or item.enchant ~= "" and item.enchant )
	local fontWidthMult = TOOLTIP_FONT_WIDTH
	local function textElement(str, color)
		flex.content:add { 
			type = ui.TYPE.Text,
			template = tooltipText,
			props = {
				text = " "..str.." ",
				textSize = itemFontSize*textSizeMult,
				textAlignH = ui.ALIGNMENT.End,
				textColor = color,
				autoSize = true
			},
		}
	end
	
	flex.content:add{ props = { size = v2(1, 1) * 1 } }
	
	local name = info.name
	if item.count and item.count > 1 then
		name = name.." ("..item.count..")"
	end
	if info.soulName then
		name = name.." ("..info.soulName..")"
	end
	if isPickpocketing then-- and  then
		local text = pickpocket.getTooltipText1(self,inspectedContainer, item, deposit)
		if not COLUMN_PICKPOCKET then
			name = name..text
		end
	end
	colorTheme = nil -- uncomment for red colored item name when stealing
	--textElement(fromutf8(name), ICON_TINT)
	textElement(name, colorTheme and util.color.rgba(1,0.05, 0.05, 1) or ICON_TINT)

	flex.content:add{ props = { size = v2(1, 1) * 1 } }
	
	if info.uses then
		textElement(core.getGMST("sUses")..": "..math.floor(info.uses))
	end
	
	if info.quality then
		textElement(core.getGMST("sQuality")..": "..math.floor(info.quality*10+0.5)/10)
	end
	
	if info.type == "armor" then
		textElement(core.getGMST("sArmorRating")..": ".. math.floor(info.armorData.playerArmor))
	end
	
	if info.type == "weapon" then
		textElement(core.getGMST("sType").." ".. info.weaponData.typeName)
		if info.weaponData.typeName == core.getGMST("sSkillMarksman") then
			textElement(core.getGMST("sAttack")..": ".. info.weaponData.damage.chopMin.."-"..info.weaponData.damage.chopMax)
		else
			textElement(core.getGMST("sChop")..": ".. info.weaponData.damage.chopMin.."-"..info.weaponData.damage.chopMax)
			textElement(core.getGMST("sSlash")..": ".. info.weaponData.damage.slashMin.."-"..info.weaponData.damage.slashMax)
			textElement(core.getGMST("sThrust")..": ".. info.weaponData.damage.thrustMin.."-"..info.weaponData.damage.thrustMax)
		end
	end
	
	local weaponOrArmor = info.weaponData or info.armorData
	
	if weaponOrArmor and weaponOrArmor.durability then
		textElement(core.getGMST("sCondition")..": ".. math.floor(weaponOrArmor.durability.current+0.5).."/"..math.floor(weaponOrArmor.durability.max+0.5))
	end
	
	if info.type == "weapon" and TOOLTIP_MELEE_INFO then
		textElement(core.getGMST("sRange")..": "..(math.floor((info.weaponData.reach*6.05)*10)/10).." "..core.getGMST("sfootarea"))
		textElement(core.getGMST("sAttributeSpeed")..": "..math.floor((info.weaponData.speed)*100+0.5).."%")
	end
	
	if info.weight and info.weight > 0 then
		local armorClass = info.armorData and info.armorData.class
		if armorClass then
			armorClass = " ("..armorClass..")"
		else
			armorClass = ""
		end
		textElement(core.getGMST("sWeight")..": ".. formatNumber(info.weight, "weight")..armorClass)
	end
	
	if info.value and info.value > 0 then
		textElement(core.getGMST("sValue")..": ".. formatNumber(info.value, "value"))
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
			if skill >= i * gmst or not isPotion then
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
						size = v2(itemFontSize*textSizeMult-1,itemFontSize*textSizeMult-1),
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
			else
				textElement("?")
			end
		end
	end
	
	if info.enchantment then
		textElement(info.enchantment.typeName or "???")
		flex.content:add{ props = { size = v2(1, 1) * 2 } }
		printEffects(info.enchantment.effects)
		if info.enchantment.charge then
			flex.content:add{ props = { size = v2(1, 1) * 3 } }
			local progressFlex ={
				type = ui.TYPE.Flex,
				props = {
					position = v2(0, 0),
					size = v2(0,itemFontSize*textSizeMult),
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
					textSize = itemFontSize*textSizeMult,
					size = v2(0,itemFontSize*textSizeMult),
					textAlignH = ui.ALIGNMENT.Center,
				},
			}
			-- PROGRESS BAR
			local progressBar = 
			{
				type = ui.TYPE.Widget,
				props = {
					size = v2(itemFontSize*textSizeMult*6, itemFontSize*textSizeMult),
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
					color = util.color.hex("9c2e17"),
				}
			}
			progressBar.content:add { 
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = math.floor(info.enchantment.charge.current).." / "..math.floor(info.enchantment.charge.max),--..hextoutf8(0xd83d)..hextoutf8(0xd83e),--thingName..countText,
					textSize = itemFontSize*textSizeMult,--itemFontSize*textSizeMult,
					size = v2(0,itemFontSize*textSizeMult),
					relativeSize  = v2(0,1),
					relativePosition = v2(0.5, 0),
					anchor = v2(0.5,0),
					textAlignH = ui.ALIGNMENT.Center,
					textColor = color,
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
			if skill >= i * gmst then
				local effectFlex ={
					type = ui.TYPE.Flex,
					props = {
						position = v2(0, 0),
						horizontal = true,
					},
					content = ui.content({})
				}
				flex.content:add(effectFlex)
				
				effectFlex.content:add{ props = { size = v2(1, 1) * 5 } }
				
				effectFlex.content:add {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(effect.icon),
						tileH = false,
						tileV = false,
						size = v2(itemFontSize*textSizeMult-1,itemFontSize*textSizeMult-1),
						alpha = 0.7,
					}
				}
				effectFlex.content:add { 
					type = ui.TYPE.Text,
					template = quickLootText,
					props = {
						text = " "..effect.text.." ",
						textSize = itemFontSize*textSizeMult,
						--size = v2(0,itemFontSize*textSizeMult),
						textAlignH = ui.ALIGNMENT.Center,
					},
				}
			else
				textElement("?")
			end
		end
		
	end
	
	flex.content:add{ props = { size = v2(1+borderOffset, 1+borderOffset) * 2 } }
	return root
end