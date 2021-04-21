local config = require("OEA.OEA9 Fail.config")
local formula = require("OEA.OEA9 Fail.formula")

local skills
local AttackState
local AmmoState
local AlchemyState
local EnchantState
local RepairState
local XPSchool

local function AttackTimerEnd()
	if (AttackState == nil) or (AttackState == 0) then
		return
	end

	if (tes3.mobilePlayer.readiedWeapon == nil) then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.handToHand, skills[tes3.skill.handToHand + 1].actions[1] * config.HandMult)
		AttackState = 0
		return
	end

	local Type = tes3.mobilePlayer.readiedWeapon.object.type

	if (Type == nil) then
		Type = -1
	end

	if (Type == 0) then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.shortBlade, skills[tes3.skill.shortBlade + 1].actions[1] * config.WeaponMult)
	elseif (Type == 1) or (Type == 2) then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.longBlade, skills[tes3.skill.longBlade + 1].actions[1] * config.WeaponMult)
	elseif (Type == 3) or (Type == 4) or (Type == 5) then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.bluntWeapon, skills[tes3.skill.bluntWeapon + 1].actions[1] * config.WeaponMult)
	elseif (Type == 6) then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.spear, skills[tes3.skill.spear + 1].actions[1] * config.WeaponMult)
	elseif (Type == 7) or (Type == 8) then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.axe, skills[tes3.skill.axe + 1].actions[1] * config.WeaponMult)
	end

	AttackState = 0
end

local function OnCalcHit(e)
	if (e.attacker ~= nil) and (e.attacker == tes3.player) then
		AttackState = 1
		timer.start({ duration = 0.05, callback = AttackTimerEnd })
	end
end

local function OnDamage(e)
	if (e.attackerReference == nil) or (e.attackerReference ~= tes3.player) then
		return
	end
	
	if (e.magicSourceInstance ~= nil) or (e.magicEffectInstance ~= nil) then
		return
	end

	if (e.projectile == nil) then
		AttackState = 0
	elseif (e.projectile ~= nil) then
		AmmoState = 1
	end
end

local function ProjHit(e)
	if (e.firingReference ~= tes3.player) and (e.firingReference ~= tes3.mobilePlayer) then
		return
	end

	if (e.mobile.spellInstance ~= nil) then
		return
	end

	if (AmmoState == nil) or (AmmoState == 0) then
		tes3.mobilePlayer:exerciseSkill(tes3.skill.marksman, skills[tes3.skill.marksman + 1].actions[1] * config.AmmoMult)
		--mwse.log("[OEA9] progress is now %s", tes3.mobilePlayer.skillProgress[tes3.skill.marksman + 1])
	else
		AmmoState = 0
	end
end

local function OnSpellCast(e)
	if (e.caster ~= tes3.player) then
		return
	end

	XPSchool = e.weakestSchool
end

local function OnSpellFailure(e)
	if (e.caster ~= tes3.player) then
		return
	end

	local schoolSkill = tes3.magicSchoolSkill[e.expGainSchool] or tes3.magicSchoolSkill[XPSchool]
	if (schoolSkill == nil) then
		return
	end

	local EXP = skills[schoolSkill + 1].actions[1] * config.MagicMult
	tes3.mobilePlayer:exerciseSkill(schoolSkill, EXP)
end

local function AlchemyEnter(e)
	AlchemyState = 1
end

local function EnchantEnter(e)
	EnchantState = 1
end

local function RepairEnter(e)
	RepairState = 1
end

local function MenuExit(e)
	AlchemyState = 0
	EnchantState = 0
	RepairState = 0
end

local function Sound(e)
	if (e.sound == tes3.getSound("potion fail")) then
		if (AlchemyState ~= nil) and (AlchemyState == 1) then
			tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, skills[tes3.skill.alchemy + 1].actions[1] * config.AlchMult)
		end	
	end

	if (e.sound == tes3.getSound("Disarm Trap Fail")) and (tes3.menuMode() == false) then
		if (tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.probe }) ~= nil) then
			formula.ProbeFormula()
		end
	end
	if (e.sound == tes3.getSound("Open Lock Fail")) and (tes3.menuMode() == false) then
		if (tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.lockpick }) ~= nil) then
			formula.PickFormula()
		end
	end

	if (e.sound == tes3.getSound("enchant fail")) then
		if (EnchantState ~= nil) and (EnchantState == 1) then
			tes3.mobilePlayer:exerciseSkill(tes3.skill.enchant, skills[tes3.skill.enchant + 1].actions[1] * config.EnchMult)
		end	
	end

	if (e.sound == tes3.getSound("repair fail")) then
		if (RepairState ~= nil) and (RepairState == 1) then
			tes3.mobilePlayer:exerciseSkill(tes3.skill.armorer, skills[tes3.skill.armorer + 1].actions[1] * config.ArmMult)
		end	
	end
end	

local function SpeechLoaded(e)
	skills[tes3.skill.speechcraft + 1].actions[2] = skills[tes3.skill.speechcraft + 1].actions[1] * config.SpeechMult
end

local function Init(e)
	event.register("calcHitChance", OnCalcHit)
	event.register("damage", OnDamage)
	event.register("projectileHitActor", ProjHit)
	event.register("spellCast", OnSpellCast)
	event.register("spellCastedFailure", OnSpellFailure)
	event.register("addSound", Sound)
	event.register("uiActivated", AlchemyEnter, { filter = "MenuAlchemy" })
	event.register("uiActivated", EnchantEnter, { filter = "MenuEnchantment" })
	event.register("uiActivated", RepairEnter, { filter = "MenuRepair" })
	event.register("menuExit", MenuExit)
	event.register("loaded", SpeechLoaded)
	skills = tes3.dataHandler.nonDynamicData.skills
	mwse.log("[Practice Makes Perfect] Initialized.")
end

event.register("initialized", Init)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
	require("OEA.OEA9 Fail.mcm")
end)

