local core = require('openmw.core')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local getSound = require("scripts.OwnlysQuickLoot.ql_getSound")
require("scripts.OwnlysQuickLoot.ql_pickpocket_settings")
local MODNAME = "QLPP"
local playerSection = storage.playerSection('SettingsPlayer'..MODNAME)
--local npcSection = storage.playerSection('QuickLoot_Pickpocket_NPC_DB11')
-- global variable: "savegameData"
local qlpp = {}
qlpp.version = 2

local skipDebugFrame = 0

local function getFatigueTerm(self, target)
	local minMod = playerSection:get("FATIGUE_MIN_MODIFIER")
	local maxMod = playerSection:get("FATIGUE_MAX_MODIFIER")
	
	local selfMax = types.Actor.stats.dynamic.fatigue(target).base
	local selfCurrent = types.Actor.stats.dynamic.fatigue(target).current
	local selfNormalised = math.max(0, selfCurrent / selfMax)
	local selfMod =  minMod + selfNormalised * (maxMod - minMod)
	
	local targetMax = types.Actor.stats.dynamic.fatigue(target).base
	local targetCurrent = types.Actor.stats.dynamic.fatigue(target).current
	local targetNormalised = math.max(0, targetCurrent / targetMax)
	local targetMod =  minMod + targetNormalised * (maxMod - minMod)
	
	return 1*selfMod/targetMod
end

local function tableContains(tbl, item)
	for _, v in pairs(tbl) do
		if v == item then return true end
	end
	return false
end
-- Armor type mapping
local armorTypeMap = {
    [types.Armor.TYPE.Helmet] = types.Actor.EQUIPMENT_SLOT.Helmet,
    [types.Armor.TYPE.Cuirass] = types.Actor.EQUIPMENT_SLOT.Cuirass,
    [types.Armor.TYPE.LPauldron] = types.Actor.EQUIPMENT_SLOT.LeftPauldron,
    [types.Armor.TYPE.RPauldron] = types.Actor.EQUIPMENT_SLOT.RightPauldron,
    [types.Armor.TYPE.Greaves] = types.Actor.EQUIPMENT_SLOT.Greaves,
    [types.Armor.TYPE.Boots] = types.Actor.EQUIPMENT_SLOT.Boots,
    [types.Armor.TYPE.LGauntlet] = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    [types.Armor.TYPE.RGauntlet] = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
    [types.Armor.TYPE.Shield] = types.Actor.EQUIPMENT_SLOT.CarriedLeft,
    [types.Armor.TYPE.LBracer] = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    [types.Armor.TYPE.RBracer] = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
}

-- Clothing type mapping
local clothingTypeMap = {
    [types.Clothing.TYPE.Pants] = types.Actor.EQUIPMENT_SLOT.Pants,
    [types.Clothing.TYPE.Shoes] = types.Actor.EQUIPMENT_SLOT.Boots,
    [types.Clothing.TYPE.Shirt] = types.Actor.EQUIPMENT_SLOT.Shirt,
    [types.Clothing.TYPE.Belt] = types.Actor.EQUIPMENT_SLOT.Belt,
    [types.Clothing.TYPE.Robe] = types.Actor.EQUIPMENT_SLOT.Robe,
    [types.Clothing.TYPE.RGlove] = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
    [types.Clothing.TYPE.LGlove] = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    [types.Clothing.TYPE.Skirt] = types.Actor.EQUIPMENT_SLOT.Skirt,
    [types.Clothing.TYPE.Ring] = types.Actor.EQUIPMENT_SLOT.LeftRing,
    [types.Clothing.TYPE.Amulet] = types.Actor.EQUIPMENT_SLOT.Amulet,
}

-- Weapon type mapping
local weaponTypeMap = {
    [types.Weapon.TYPE.ShortBladeOneHand] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.LongBladeOneHand] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.LongBladeTwoHand] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.BluntOneHand] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.BluntTwoClose] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.BluntTwoWide] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.SpearTwoWide] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.AxeOneHand] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.AxeTwoHand] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.MarksmanBow] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.MarksmanCrossbow] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.MarksmanThrown] = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    [types.Weapon.TYPE.Arrow] = types.Actor.EQUIPMENT_SLOT.Ammunition,
    [types.Weapon.TYPE.Bolt] = types.Actor.EQUIPMENT_SLOT.Ammunition,
}

local function updateFooterText(target)
	local attempts = savegameData[target.id] or 0
	local maxAttempts = qlpp.cache.maxAttempts
	if attempts > maxAttempts+1 then
		qlpp.footerColor = util.color.rgb(0.85,0, 0)
		qlpp.footerText = "caught"
	elseif attempts >= maxAttempts then
		qlpp.footerColor = util.color.rgb(0.85,0, 0)
		qlpp.footerText = attempts.." / "..maxAttempts
	else
		qlpp.footerColor = nil
		qlpp.footerText = attempts.." / "..maxAttempts
	end
end

local function npcMadButNoPunishment(self,target)
	local record = 7
	if math.random() < 0.5 then
		record = 8
	end
	for j, dialogue in ipairs(core.dialogue.voice.records[record].infos) do
		if dialogue.filterActorRace==types.NPC.record(target).race and ((dialogue.filterActorGender=="female" and types.NPC.record(target).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(target).isMale==true))  then
			ambient.playSoundFile(dialogue.sound)
			break
		end
	end
	core.sendGlobalEvent("OwnlysQuickLoot_rotateNpc", {self, target})
	core.sendGlobalEvent("OwnlysQuickLoot_modDisposition", {self, target, -10})
end

local function awardExp(self, target, item, mult, add)
	local mult = mult or 1
	local add = add or 0
	local skillGain =  mult * (qlpp.calcDifficulty(self,target,item) * playerSection:get("EXPERIENCE_MULT") + playerSection:get("EXPERIENCE_ADD"))+add
	if playerSection:get("DEBUG_MODE") then
		print("########################")
		print(" + "..math.floor(skillGain*100)/100 .." exp")
	end
	if playerSection:get("SECURITY_SKILL") then
		I.SkillProgression.skillUsed('security', {skillGain =skillGain, 
												useType = I.SkillProgression.SKILL_USE_TYPES.Security_PickLock, 
												scale = nil})
	else
		I.SkillProgression.skillUsed('sneak', {skillGain = skillGain, 
												useType = I.SkillProgression.SKILL_USE_TYPES.Sneak_PickPocket, 
												scale = nil})
	end
end

local function buildCache(self, target)
	qlpp.cache = {}
	

	local tarSkill = 0.2 * types.Actor.stats.attributes.agility(target).modified
	tarSkill = tarSkill + 0.1 * types.Actor.stats.attributes.luck(target).modified
	tarSkill = tarSkill + types.NPC.stats.skills.security(target).modified
	qlpp.cache.targetSkill = tarSkill * playerSection:get("TARGET_SKILL_MULT")
	
	local selfSkill = 0.2 * types.Actor.stats.attributes.agility(self).modified
	selfSkill = selfSkill + 0.1 * types.Actor.stats.attributes.luck(self).modified
	if playerSection:get("SECURITY_SKILL") then
		qlpp.cache.baseSkill = types.NPC.stats.skills.security(self).modified
	else
		qlpp.cache.baseSkill = types.NPC.stats.skills.sneak(self).modified
	end
	qlpp.cache.selfSkill = (selfSkill + qlpp.cache.baseSkill) * playerSection:get("OWN_SKILL_MULT")
	qlpp.cache.maxAttempts = playerSection:get("MAX_THEFTS_PER_NPC") + math.floor(qlpp.cache.baseSkill / playerSection:get("SKILL_FOR_BONUS_ATTEMPTS"))
	
	qlpp.cache.chanceFatigueMult = getFatigueTerm(self,target)
	
	
	local targetYaw = target.rotation:getYaw()
	local deltaX = self.position.x - target.position.x
	local deltaY = self.position.y - target.position.y
	local playerAngle = math.atan2(deltaX, deltaY)
	local relativeAngle = playerAngle - targetYaw
	while relativeAngle > math.pi do relativeAngle = relativeAngle - 2*math.pi end
	while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2*math.pi end
	local direction
	if math.abs(relativeAngle) < math.pi/4 then
		 qlpp.cache.chanceFacingMult = playerSection:get("FRONT_MODIFIER")
	elseif math.abs(relativeAngle) > 3*math.pi/4 then
		qlpp.cache.chanceFacingMult = playerSection:get("BACK_MODIFIER")
	else
		local mod = (math.abs(relativeAngle)-math.pi/4)/(math.pi/2)
		qlpp.cache.chanceFacingMult = (1-mod)*playerSection:get("FRONT_MODIFIER")+mod * playerSection:get("BACK_MODIFIER")
	end
	
	local npcRecord = types.NPC.record(target.recordId)
	if not npcRecord or not npcRecord.servicesOffered.Barter then
		qlpp.cache.merchantAdd = 0
		qlpp.cache.merchantMult = 1
	else
		qlpp.cache.merchantAdd = playerSection:get("MERCHANT_ADD")
		qlpp.cache.merchantMult = playerSection:get("MERCHANT_MULT")
	end
	
	if  types.Actor.getStance(target) ~= types.Actor.STANCE.Nothing then
		qlpp.cache.inCombatModifier = playerSection:get("IN_COMBAT_MODIFIER") or 50
	else
		qlpp.cache.inCombatModifier = 0
	end
	
	qlpp.cache.lastUpdate = core.getRealTime()
	qlpp.cache.benchResult = qlpp.calcChance(self, target, nil, true)
	updateFooterText(target)
end

qlpp.calcDifficulty = function(self,target,item,dbg,deposit)
	local difficulty = playerSection:get("BASE_DIFFICULTY")
	if dbg then
		print("-----")
		
	end
	if item then
		local record = item.type.record(item)
		local count = item.count or 1
		if dbg then
			print(record.name or record.id)
			print(difficulty)
		end
		
		if deposit and types.Armor.objectIsInstance(item) then
			count = 1
		elseif deposit and types.Weapon.objectIsInstance(item) then
			count = 1
		elseif deposit and types.Clothing.objectIsInstance(item) then
			count = 1
		elseif deposit and types.Potion.objectIsInstance(item) then
			count = 1
			local calculatedCost = 0
			for _, effect in pairs(record.effects) do
				if effect.effect.harmful then
					local hasMagnitude = effect.effect.hasMagnitude
					local hasDuration = effect.effect.hasDuration
					local appliedOnce = effect.effect.isAppliedOnce
					local minMagn = hasMagnitude and effect.magnitudeMin or 1;
					local maxMagn = hasMagnitude and effect.magnitudeMax or 1;
					--if (method == EffectCostMethod::PlayerSpell || method == EffectCostMethod::GameSpell)
						minMagn = math.max(1, minMagn);
						maxMagn = math.max(1, maxMagn);
					-- }
					local duration = hasDuration and effect.duration or 1;
					if (not appliedOnce) then
						duration = math.max(1, duration);
					end
					local fEffectCostMult =  core.getGMST("fEffectCostMult")
					local iAlchemyMod = core.getGMST("iAlchemyMod") 
			
					local durationOffset = 0;
					local minArea = 0;
					local costMult = fEffectCostMult;
					--if playerSpell then
					--	durationOffset = 1;
					--	minArea = 1;
					--end -- elseif GamePotion
					--    minArea = 1;
						costMult = iAlchemyMod;
					-- end
			
					local x = 0.5 * (minMagn + maxMagn)*core.getGMST("fPotionT1MagMult"); -- divisor, so we mult?
					x = x * (0.1 * effect.effect.baseCost);
					x = x * (durationOffset + duration)*core.getGMST("fPotionT1DurMult"); -- divisor, so we mult?
					x = x + (0.05 * math.max(minArea, effect.area) * effect.effect.baseCost);
			
					x = x * costMult;
					--if effect.range == core.magic.RANGE.Target then--  if (effect.mData.mRange == ESM::RT_Target)
					--	x = x * 1.5
					--end
					x= math.max(0,x)
					calculatedCost = calculatedCost + x*playerSection:get("POISON_DIFFICULTY")
				end
			end
			if dbg and calculatedCost > 0 then
				print("+ "..calculatedCost.." (Poison Strength)")
			end
			difficulty = difficulty + calculatedCost
		end
		local value = record.value * count
		local valueAdd = playerSection:get("VALUE_ADD")
		local valueExp = playerSection:get("VALUE_EXP")
		local valueMult = playerSection:get("VALUE_MULT")
		if dbg then		
			print("+ ("..value.." + "..valueAdd..") ^ "..valueExp.." * "..valueMult.. " (="..math.floor((math.max(0,(value + valueAdd)) ^ valueExp) * valueMult*100)/100 .." value)")
		end
		difficulty = difficulty + (math.max(0,(value + valueAdd)) ^ valueExp) * valueMult
		local weight = record.weight * count
		local weightMult = playerSection:get("WEIGHT_MULT")
		difficulty = difficulty + weight * weightMult
		if dbg then 
			print("+ ".. math.floor((weight * weightMult)*100)/100 .." (weight)")
		end
		if types.Actor.hasEquipped(target, item) then
			difficulty = difficulty + playerSection:get("EQUIPPED_MULT")
			if dbg then print("* "..playerSection:get("EQUIPPED_MULT").." (equipped)") end
			if types.Weapon.objectIsInstance(item) then
				difficulty = difficulty + (playerSection:get("EQUIPPED_WEAPON_BONUS"))
				if dbg then print("+ "..playerSection:get("EQUIPPED_WEAPON_BONUS").." (equipped weapon)") end
			elseif types.Clothing.objectIsInstance(item) and (record.type == types.Clothing.TYPE.Ring or record.type == types.Clothing.TYPE.Ring or item.TYPE == types.Clothing.TYPE.Amulet) then
				difficulty = difficulty + (playerSection:get("EQUIPPED_JEWELRY_BONUS"))
				if dbg then print("+ "..playerSection:get("EQUIPPED_JEWELRY_BONUS").." (equipped jewelry)") end
			else--if types.Armor.objectIsInstance(item) then
				difficulty = difficulty + (playerSection:get("EQUIPPED_ARMOR_BONUS"))
				if dbg then print("+ "..playerSection:get("EQUIPPED_ARMOR_BONUS").." (equipped armor)") end
			end
		end
	elseif dbg then
		print(difficulty)
	end
	difficulty = difficulty + qlpp.cache.targetSkill
	if dbg then
		print("+ "..qlpp.cache.targetSkill.." (targetSkill)")
	end
	if dbg and qlpp.cache.merchantAdd ~=0 then
		print("* "..qlpp.cache.merchantMult.." (merchant)")
		print("+ ".. qlpp.cache.merchantAdd.." (merchant)")
	end
	if difficulty > 0 then
		difficulty = difficulty * qlpp.cache.merchantMult
	end
	difficulty = difficulty + qlpp.cache.merchantAdd
	difficulty = difficulty + qlpp.cache.inCombatModifier
	if dbg and qlpp.cache.inCombatModifier > 0 then
		print("+ ".. qlpp.cache.inCombatModifier.."(in combat)")
	end
	return difficulty
end

qlpp.calcChance = function(self, target, item, benchmark, dbg, deposit)
	
	if not qlpp.cache then buildCache(self, target) end
	if not playerSection:get("DEBUG_MODE") then dbg = false end
	if skipDebugFrame > 0 then dbg = false end
	local difficulty = qlpp.calcDifficulty(self,target,item,dbg,deposit)
	local chance = math.max(0,qlpp.cache.selfSkill - difficulty)
	
	if dbg then
		print("= "..math.floor(difficulty*100)/100)
		print(qlpp.cache.selfSkill .." own skill (* "..playerSection:get("OWN_SKILL_MULT")..")")
		print("= "..math.floor(chance*100)/100 .."%")
	end
	
	local maxChance = chance * playerSection:get("BACK_MODIFIER")
	--maxChance = maxChance * playerSection:get("FATIGUE_MAX_MODIFIER")
	
	chance = chance * qlpp.cache.chanceFacingMult
	chance = math.floor(chance * qlpp.cache.chanceFatigueMult+0.5)
	local attempts = savegameData[target.id] or 0
	chance = chance - playerSection:get("USED_ATTEMPT_MODIFIER") *  attempts
	if dbg then
		print("* ".. math.floor(qlpp.cache.chanceFacingMult*100)/100 .."(facing)")
		print("* ".. math.floor(qlpp.cache.chanceFatigueMult*100)/100 .."(fatigue)")
		if attempts > 0 and playerSection:get("USED_ATTEMPT_MODIFIER") > 0 then 
			print("- "..(playerSection:get("USED_ATTEMPT_MODIFIER") *  attempts).."% ("..attempts.." attempts used)")
		end
		print("= "..chance.."%")
	end
	
	
	
	if benchmark then
		return chance
	end
	if item and types.Potion.objectIsInstance(item) then
		local isHarmful = false
		for _, effect in pairs(item.type.record(item).effects) do
			if effect.effect.harmful then
				isHarmful = true
			end
		end
		if isHarmful then
			return chance
		end
	end
	chance = math.min(chance, playerSection:get("MAX_PICKPOCKET_CHANCE"))
	chance = math.max(chance, 0)
	
	
	return math.floor(chance), math.floor(maxChance)
end


qlpp.stealItem = function(self, target, item)
	if not qlpp.cache then buildCache(self, target) end
	
	local pickpocketAttempts = savegameData[target.id] or 0
	if pickpocketAttempts >= qlpp.cache.maxAttempts then
		return false
	end
	
	local chance = qlpp.calcChance(self, target, item)
	if math.random() * 100 < chance then
		pickpocketAttempts = pickpocketAttempts+1
		savegameData[target.id] = pickpocketAttempts
		ambient.playSound(getSound(item))
		core.sendGlobalEvent("OwnlysQuickLoot_take", {self, target, item, true})
		
		updateFooterText(target)
		awardExp(self,target,item)
		skipDebugFrame = 2
		return true
	else
		awardExp(self,target,item, playerSection:get("FAILED_ATTEMPT_EXPERIENCE_MULT")*chance/100)
		local minSkillForNoPunishment = playerSection:get("MIN_SKILL_FOR_NO_PUNISHMENT")
		
		if qlpp.cache.baseSkill < minSkillForNoPunishment then
			core.sendGlobalEvent("OwnlysQuickLoot_commitCrime", {self, target, 0})
		else
			npcMadButNoPunishment(self,target)
			--qlpp.message = "failed but unnoticed"
		end
		
		pickpocketAttempts = pickpocketAttempts + playerSection:get("FAILED_ATTEMPT_COST")
		savegameData[target.id] = pickpocketAttempts
		updateFooterText(target)
		return false
	end
end

qlpp.reversePickpocket = function(self, target, item)
	if not qlpp.cache then buildCache(self, target) end
	
	local pickpocketAttempts = savegameData[target.id] or 0
	if pickpocketAttempts >= qlpp.cache.maxAttempts then
		return false
	end
	
	local chance = qlpp.calcChance(self, target, item, nil, nil, true)
	if math.random() * 100 < chance then
		pickpocketAttempts = pickpocketAttempts+1
		savegameData[target.id] = pickpocketAttempts
		ambient.playSound(getSound(item))
		for a,b in pairs(types.Clothing.TYPE) do
			print(a,b)
		end
		
		for a,b in pairs(types.Weapon.TYPE) do
			print(a,b)
		end
		local tempCount = nil
		local use = false
		if types.Potion.objectIsInstance(item) then
			tempCount = 1
			use = true
			local isHarmful = false
			for _, effect in pairs(item.type.record(item).effects) do
				if effect.effect.harmful then
					isHarmful = true
				end
			end
			if isHarmful and math.random()*100 > chance/2 then
				core.sendGlobalEvent("OwnlysQuickLoot_commitCrime", {self, target, 500, types.Player.OFFENSE_TYPE.Assault})
			end
		elseif types.Weapon.objectIsInstance(item) then
			tempCount = 1
			local slot = weaponTypeMap[item.type.record(item).type]
			if not types.Actor.getEquipment(target)[slot] then
				use = slot
			end
		elseif types.Clothing.objectIsInstance(item) then
			tempCount = 1
			local slot = clothingTypeMap[item.type.record(item).type]
			if not types.Actor.getEquipment(target)[slot] then
				use = slot
			end
		elseif types.Armor.objectIsInstance(item) then
			tempCount = 1
			local slot = armorTypeMap[item.type.record(item).type]
			if not types.Actor.getEquipment(target)[slot] then
				use = slot
			end
		end
		awardExp(self,target,item, 0, 2.5)
		core.sendGlobalEvent("OwnlysQuickLoot_deposit", {self, target, item, true, nil, tempCount, use})
		qlpp.filteredItems = nil
		updateFooterText(target)
		skipDebugFrame = 2
		return true
	else
		awardExp(self,target,item, playerSection:get("FAILED_ATTEMPT_EXPERIENCE_MULT")*chance/100)
		local minSkillForNoPunishment = playerSection:get("MIN_SKILL_FOR_NO_PUNISHMENT")
		
		if qlpp.cache.baseSkill < minSkillForNoPunishment then
			core.sendGlobalEvent("OwnlysQuickLoot_commitCrime", {self, target, 0})
		else
			npcMadButNoPunishment(self,target)
			--qlpp.message = "failed but unnoticed"
		end
		
		pickpocketAttempts = pickpocketAttempts + playerSection:get("FAILED_ATTEMPT_COST")
		savegameData[target.id] = pickpocketAttempts
		updateFooterText(target)
		return false
	end
end

qlpp.validateTarget = function(self, target, input)
	if target.type ~= types.NPC or types.Actor.isDead(target) then
		return false
	end
	
	if not self.controls.sneak then
		return false
	end
	
	local inCombat = types.Actor.getStance(target) ~= types.Actor.STANCE.Nothing
	if inCombat then
		local requiredSkill = playerSection:get("SKILL_FOR_IN_COMBAT")
		local selfSkill
		
		if playerSection:get("SECURITY_SKILL") then
			selfSkill = types.NPC.stats.skills.security(self).modified
		else
			selfSkill = types.NPC.stats.skills.sneak(self).modified
		end
		
		if selfSkill < requiredSkill then
			--qlpp.message = "skill too low for in combat"
			return false
		end
	end
	--local pickpocketAttempts = savegameData[target.id] or 0
	--local maxAttempts = playerSection:get("MAX_THEFTS_PER_NPC")
	--if pickpocketAttempts >= maxAttempts then
	--	--qlpp.message = "already pickpocketed this npc"
	--	return false
	--end
	
	return true
end

qlpp.closeHud = function(self)
	qlpp.filteredItems = nil
	qlpp.message = nil
	qlpp.showContents = false
	qlpp.cache = nil
	qlpp.footerColor = nil
	qlpp.footerText = nil
end


qlpp.filterItems = function(self, target, containerItems)
	if not qlpp.cache then buildCache(self, target) end
	local tempContainerItems = {}
	
	local revealChance = qlpp.calcChance(self, target)
	
	if qlpp.showContents or qlpp.cache.baseSkill >= playerSection:get("SKILL_TO_BYPASS_SKILL_CHECK") or revealChance >= 100 then
		qlpp.showContents = true
		
		if not qlpp.filteredItems then
			qlpp.undisplayedItems = 0
			qlpp.filteredItems = {}
			
			local visibilityChance = playerSection:get("ITEM_VISIBILITY_MULT") / qlpp.cache.baseSkill

			
			for _, item in pairs(containerItems) do
				local _, maxItemChance = qlpp.calcChance(self, target, item)
				if maxItemChance < playerSection:get("ONLY_SHOW_ABOVE_CHANCE") or math.random() > visibilityChance then
					qlpp.undisplayedItems = qlpp.undisplayedItems + 1
				else
					table.insert(qlpp.filteredItems, item)
				end
			end
		end
		
		for _, item in pairs(containerItems) do
			if tableContains(qlpp.filteredItems, item) then
				table.insert(tempContainerItems, item)
			end
		end
		
		if qlpp.undisplayedItems > 0 then
			if #tempContainerItems == 0 then
				qlpp.message = qlpp.undisplayedItems .. " items"
				local minDifficulty = 99999999
				for _, item in pairs(containerItems) do
					minDifficulty = math.min(minDifficulty, qlpp.calcDifficulty(self,target,item))
				end
				--qlpp.message = qlpp.message .." (min. "..math.floor((minSkill+1+playerSection:get("ONLY_SHOW_ABOVE_CHANCE"))/qlpp.cache.chanceFacingMult).." skill)"
				qlpp.message = qlpp.message .." (min. "..math.ceil(playerSection:get("ONLY_SHOW_ABOVE_CHANCE")/ playerSection:get("BACK_MODIFIER")+minDifficulty).." skill)"
			else
				qlpp.message = "and " .. qlpp.undisplayedItems .. " more items"
			end
		else
			qlpp.message = nil
		end
	else
		local attempts = savegameData[target.id] or 0
		local maxAttempts = qlpp.cache.maxAttempts
		if attempts >= maxAttempts then
			qlpp.message = "all attempts already used"
		else
			qlpp.message = "reveal pocket contents (" .. revealChance .. "%)"
		end
	end
	
	return tempContainerItems
end


qlpp.activate = function(self, target, input)
	if not qlpp.validateTarget(self, target, input) then return false end
	if qlpp.showContents then return false end
	if not qlpp.cache then buildCache(self, target) end
	local attempts = savegameData[target.id] or 0
	local maxAttempts = qlpp.cache.maxAttempts
	if attempts >= maxAttempts then
		return false
	end
	local chance = qlpp.calcChance(self, target)
	
	if math.random() * 100 > chance then
		awardExp(self, target, nil, 0, 1)
		local minSkillForNoPunishment = playerSection:get("MIN_SKILL_FOR_NO_PUNISHMENT")
		
		if qlpp.cache and qlpp.cache.baseSkill < minSkillForNoPunishment then
			core.sendGlobalEvent("OwnlysQuickLoot_commitCrime", {self, target, 0})
		else
			npcMadButNoPunishment(self,target)
		end
		savegameData[target.id] = attempts + 1
		updateFooterText(target)
		--qlpp.message = "Failed to look into pockets"
	else
		awardExp(self,target,nil,0.2+(100-chance)/100)
		qlpp.showContents = true
		qlpp.message = nil
	end
	
	return true
end


qlpp.scroll = function(self, target, input)
	if not qlpp.validateTarget(self, target, input) then return false end
	if qlpp.showContents then return false end
	if not qlpp.cache then buildCache(self, target) end
	
	local attempts = savegameData[target.id] or 0
	local maxAttempts = qlpp.cache.maxAttempts
	if attempts >= maxAttempts then		
		return false
	end
	local chance = qlpp.calcChance(self, target,nil,nil,true)
	
	if math.random() * 100 > chance then
		awardExp(self, target, nil, 0, 1)
		local minSkillForNoPunishment = playerSection:get("MIN_SKILL_FOR_NO_PUNISHMENT")

		if qlpp.cache and qlpp.cache.baseSkill < minSkillForNoPunishment then
			core.sendGlobalEvent("OwnlysQuickLoot_commitCrime", {self, target, 0})
		else
			npcMadButNoPunishment(self,target)
		end
		savegameData[target.id] = attempts + 1
		updateFooterText(target)
		--qlpp.message = "Failed to look into pockets"
	else
		awardExp(self,target,nil,0.2+(100-chance)/100)
		qlpp.showContents = true
		qlpp.message = nil
	end
	
	return true
end


qlpp.getTooltipText1 = function(self, target, item, deposit)
	if playerSection:get("DEBUG_MODE") then
		return " (" .. qlpp.calcChance(self, target, item, nil, true, deposit) .. "%)"
	else
		return ""
	end
end


qlpp.getColumnText = function(self, target, item, deposit)
	return qlpp.calcChance(self, target, item, nil, nil, deposit) .. "%"
end


qlpp.onFrame = function(self, target, item, drawUI)
	skipDebugFrame = skipDebugFrame - 1
	if qlpp.cache and qlpp.cache.lastUpdate < core.getRealTime() - 1 then
		local lastBench = qlpp.cache.benchResult
		buildCache(self, target)
		if math.abs(lastBench - qlpp.cache.benchResult) > 1 then
			drawUI()
		end
	end
end

return qlpp