local config = require("AttackChance.config")
local logger = require("logging.logger")
local log = logger.new{
    name = "AttackChance",
    logLevel = "DEBUG",
    logToConsole = false,
    includeTimestamp = true,
}

local function sneakAttack(e)
	if not config.enableMod then
		return
	end
	local oldChance = e.hitChance
	local newChance = oldChance
	
	if e.attacker == tes3.player and e.targetMobile and config.changePlayer then 
		if oldChance < config.chancePlayerMin then
			newChance = config.chancePlayerMin
		end
		if oldChance > config.chancePlayerMax then
			newChance = config.chancePlayerMax
		end
	end
	
	if e.attacker ~= tes3.player and e.targetMobile and config.changeNpc then 
		if oldChance < config.chanceNpcMin then
			newChance = config.chanceNpcMin
		end
		if oldChance > config.chanceNpcMax then
			newChance = config.chanceNpcMax
		end
	end
	
	e.hitChance = newChance
	
	if config.enableDebug then
		log:debug(tostring('oldChance "%s" newChance "%s" target "%s" attacker "%s"'):format(oldChance, newChance, e.targetMobile.reference, e.attacker))
	end
end

local function onInitialized()
	event.register("calcHitChance", sneakAttack)
	mwse.log("[AttackChance] Initialized.")
end
event.register("initialized", onInitialized)


local function registerModConfig()
    require("AttackChance.mcm")
end
event.register("modConfigReady", registerModConfig)