local config

local logger = require("logging.logger")
local log = logger.new{
    name = "AttackChance",
    logLevel = "DEBUG",
    logToConsole = true,
    includeTimestamp = true,
}

event.register("modConfigReady", function()
    require("attackChance.mcm")
	config  = require("attackChance.config")
end)

-- re-calculate hit chance. For now quadriple it
local function ReCalcHitChance(e)
	if config.modEnabled == false then
		log:debug('Mod is disabled')
		return
	end
	local oldChance = e.hitChance
	local newChance = oldChance
	if e.attacker == tes3.player or config.affectEnemiesToo then
		local weapon = tes3.getObject(e.attackerMobile.readiedWeapon.object.id)
		if weapon.type == tes3.weaponType.bluntTwoClose then
			newChance = newChance + config.bluntTwoClose
		elseif weapon.type == tes3.weaponType.bluntTwoWide then
			newChance = newChance + config.bluntTwoWide
		elseif weapon.type == tes3.weaponType.bluntOneHand then
			newChance = newChance + config.bluntOneHand
		elseif weapon.type == tes3.weaponType.axeTwoHand then
			newChance = newChance + config.axeTwoHand
		elseif weapon.type == tes3.weaponType.axeOneHand then
			newChance = newChance + config.axeOneHand
		elseif weapon.type == tes3.weaponType.spearTwoWide then
			newChance = newChance + config.spearTwoWide
		elseif weapon.type == tes3.weaponType.longBladeTwoClose then
			newChance = newChance + config.longBladeTwoClose
		elseif weapon.type == tes3.weaponType.longBladeOneHand then
			newChance = newChance + config.longBladeOneHand
		elseif weapon.type == tes3.weaponType.shortBladeOneHand then
			newChance = newChance + config.shortBladeOneHand
		elseif weapon.type == tes3.weaponType.marksmanThrown then
			newChance = newChance + config.marksmanThrown
		elseif weapon.type == tes3.weaponType.marksmanBow then
			newChance = newChance + config.marksmanBow
		elseif weapon.type == tes3.weaponType.marksmanCrossbow then
			newChance = newChance + config.marksmanCrossbow
		end
		log:debug(tostring('oldChance "%s" newChance "%s" target "%s" attacker "%s", objectType "%s", Type "%s"'):format(oldChance, newChance, e.targetMobile.reference, e.attacker, e.attackerMobile.readiedWeapon.object.id, weapon.typeName))
    end
	e.hitChance = newChance
end


local function initialized(e)
	if config.modEnabled then
        event.register("calcHitChance", ReCalcHitChance)
		mwse.log("[Attack Chance: Enabled]")
	else
		mwse.log("[Attack Chance: Disabled]")
	end
end

event.register("initialized", initialized)
