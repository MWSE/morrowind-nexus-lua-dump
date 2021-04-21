local config

event.register("modConfigReady", function()
    require("nimbleArmor.mcm")
	config  = require("nimbleArmor.config")
end)

-- 0, 35, 70, 105	
-- heavy: -40 - -2
-- medium: -26 - 12
-- light: -12 - 26 
-- unarmored: 2 - 40

--percentage of armor part contributing to evasion
armorParts = {
	[0] = 0.1,	-- helmet
	[1] = 0.25,	-- cuirass
	[2] = 0.05, -- left pauldron
	[3] = 0.05, -- right pauldron
	[4] = 0.15, -- greaves
	[5] = 0.15, -- boots
	[6] = 0.05, -- left gauntlet
	[7] = 0.05, -- right gauntlet
	[8] = 0.15	-- shield
--	[9] = 0.05, -- left bracer uses the same value as left gauntlet
--	[10] = 0.05 -- right bracer uses the same value as right gauntlet
}

local function onArmorTooltip(e)
	if e.object.objectType ~= tes3.objectType.armor then
		return
	end
	local menu = e.tooltip
	local value
	if e.object.weightClass == 0 then
		value = tes3.mobilePlayer:getSkillValue(tes3.skill.lightArmor) - config.step
	elseif e.object.weightClass == 1 then
		value = tes3.mobilePlayer:getSkillValue(tes3.skill.mediumArmor) - 2*config.step
	elseif e.object.weightClass == 2 then
		value = tes3.mobilePlayer:getSkillValue(tes3.skill.heavyArmor) - 3*config.step
	end
	value = math.floor(value * config.evasion * 0.01) 
	local element = e.tooltip:getContentElement()
	local evasionRating = element:createLabel({id = tes3ui.registerID("HelpMenu_evasionRating"), text = "Evasion Rating: "..tostring(value)})
	local quality = element:findChild(tes3ui.registerID("HelpMenu_qualityCondition"))
	element:reorderChildren(quality, evasionRating, 1)
end

local function updateMenuInventory()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
	if not menu then return end
	local characterBox = menu:findChild(tes3ui.registerID("MenuInventory_character_box"))
	local evasionRating =  characterBox:findChild(tes3ui.registerID("MenuInventory_evasionRating"))
	if evasionRating then
		evasionRating.text = "Evasion: "..tostring(tes3.mobilePlayer.sanctuary)
	else
		characterBox:createLabel({id = tes3ui.registerID("MenuInventory_evasionRating"),  text = "Evasion: "..tostring(tes3.mobilePlayer.sanctuary)})
	end
end

local function onMenuInventory(e)
	updateMenuInventory()
end

local function calcArmorEvasion(reference)
	local evasion = 0
	local mobile = reference.mobile
	local unarmored = 0
	local light = 0
	local heavy = 0
	local medium = 0
	if mobile == nil then -- check for disabled actors
		return 
	end
	for i, value in pairs(armorParts) do
		local stack = tes3.getEquippedItem{actor = reference, objectType = tes3.objectType.armor, slot = i}
		if i == tes3.armorSlot.leftGauntlet or i == tes3.armorSlot.rightGauntlet then	-- if no gloves - check for bracers
			if not stack then stack = tes3.getEquippedItem{actor = reference, objectType = tes3.objectType.armor, slot = i+3} end
		end
		if stack then
			local item = stack.object
			if item.weightClass == 0 then
				light = light + value
			elseif item.weightClass == 1 then
				medium = medium + value
			elseif item.weightClass == 2 then
				heavy = heavy + value
			end
		else
			unarmored = unarmored + value
		end
	end
	unarmored = unarmored * mobile:getSkillValue(tes3.skill.unarmored)
	light = light * ( mobile:getSkillValue(tes3.skill.lightArmor) - config.step)
	medium = medium * ( mobile:getSkillValue(tes3.skill.mediumArmor) - 2*config.step)
	heavy = heavy * ( mobile:getSkillValue(tes3.skill.heavyArmor) - 3*config.step)
	evasion = math.floor((unarmored + light + medium + heavy) * 0.01 * config.evasion)
	--tes3.messageBox("Total evasion: %f\n Heavy: %f\n Medium: %f\n Light: %f\n Unarmored: %f", evasion, heavy, medium, light, unarmored)
	if reference.data.armorEvasion then	-- removing previous value
		mobile.sanctuary = mobile.sanctuary - reference.data.armorEvasion
	end
	mobile.sanctuary = mobile.sanctuary + evasion
	reference.data.armorEvasion = evasion -- remembering new value
	if mobile == tes3.mobilePlayer then
		updateMenuInventory()
	end
end


local function onEquipped(e)
	if e.item.objectType ~= tes3.objectType.armor then
		return
	end
	calcArmorEvasion(e.reference)
end


local function onUnequipped(e)
	if e.item.objectType ~= tes3.objectType.armor then
		return
	end
	calcArmorEvasion(e.reference)
end


-- initial calculation for npcs
local function onMobileActivated(e)
	if e.reference.baseObject.objectType == tes3.objectType.npc then
		calcArmorEvasion(e.reference)
	end
end


-- initial calculation for pc
local function onUiRefreshed(e)
	calcArmorEvasion(tes3.player)
	local gmst = gmst or tes3.findGMST("fUnarmoredBase1").value
	if config.unarmoredProtection then
		tes3.findGMST("fUnarmoredBase1").value = gmst
	else
		tes3.findGMST("fUnarmoredBase1").value = 0
	end
end


local function onSkillRaised(e)
	if skill ~= tes3.skill.lightArmor and skill ~= tes3.skill.mediumArmor and skill ~= tes3.skill.heavyArmor and skill ~= tes3.skill.unarmored then return end
	calcArmorEvasion(tes3.player)
end


-- calculates evasion every frame for actors under armor skills modifing effects
local function onSpellTick(e)
	if e.effectId ~= tes3.effect.fortifySkill and e.effectId ~= tes3.effect.absorbSkill and e.effectId ~= tes3.effect.drainSkill and e.effectId ~= tes3.effect.damageSkill and e.effectId ~= tes3.effect.restoreSkill then
		return
	end
	local skill = e.source.effects[e.effectIndex + 1].skill
	if skill ~= tes3.skill.heavyArmor and skill ~= tes3.skill.mediumArmor and skill ~= tes3.skill.lightArmor and skill ~= tes3.skill.unarmored then return end
	local actor = e.target
	if not actor then actor = e.caster end
	timer.start{
		duration = 0.1, 
		callback = function()
			calcArmorEvasion(actor)
			if e.effectId == tes3.effect.absorbSkill then
				calcArmorEvasion(e.caster)
			end
		end
	}	
end

local function onSkillExercise(e)
	if e.skill == tes3.skill.lightArmor then	-- light armor expirience gain: 2/3 from evasion, 1/3 from being hit
		e.progress = e.progress/3
	elseif e.skill == tes3.skill.mediumArmor then	-- medium armor expirience gain: 2/3 from being hit, 1/3 from evasion
		e.progress = e.progress*2/3
	elseif e.skill == tes3.skill.unarmored then	-- unarmored is practiced only by evasion
		if e.progress < 1000 then
			e.progress = 0
		else
			e.progress = e.progress - 1000
		end
	end
end

local function onAttack(e)
	if e.targetReference ~= tes3.player then return end
	if e.mobile.actionData.physicalDamage > 0 then return end -- missed attack
	local light = 0
	local unarmored = 0
	local medium = 0
	for i, value in pairs(armorParts) do
		local stack = tes3.getEquippedItem{actor = tes3.player, objectType = tes3.objectType.armor, slot = i}
		if i == tes3.armorSlot.leftGauntlet or i == tes3.armorSlot.rightGauntlet then
			if not stack then stack = tes3.getEquippedItem{actor = tes3.player, objectType = tes3.objectType.armor, slot = i+3} end
		end
		if stack then
			local item = stack.object
			if item.weightClass == 0 then
				light = light + value
			elseif item.weightClass == 1 then
				medium = medium + value
			end
		else
			unarmored = unarmored + value
		end
	end
	if unarmored > 0 then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.unarmored, 1000+unarmored)
	end
	if light > 0 then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.lightArmor, 2*light)
	end
	if medium > 0 then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.mediumArmor, medium/2)
	end
end


local function initialized(e)
	if config.modEnabled then
		event.register("equipped", onEquipped)
		event.register("unequipped", onUnequipped)
		event.register("uiRefreshed", onUiRefreshed)
		event.register("mobileActivated", onMobileActivated)
		event.register("skillRaised", onSkillRaised)
		event.register("exerciseSkill", onSkillExercise)
		event.register("spellTick", onSpellTick)
		event.register("attack", onAttack)
		event.register("uiObjectTooltip", onArmorTooltip)
		event.register("uiActivated", onMenuInventory, {filter = "MenuInventory"})
		event.register("menuEnter", onMenuInventory)
		mwse.log("[Nimble Armor: Enabled]")
	else
		mwse.log("[Nimble Armor: Disabled]")
	end
end

event.register("initialized", initialized)