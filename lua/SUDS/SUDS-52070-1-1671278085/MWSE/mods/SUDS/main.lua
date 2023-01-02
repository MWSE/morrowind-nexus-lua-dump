--SUDS
--Scaling Universal Damage Sponger

--register config file
local config = require("SUDS.config")
local logging = config.logToggle
local blackList = config.blackList

--function to scan blacklist and compare with actor ID. returns true or false
local actorID
local function checkID()
	for _, value in pairs(blackList) do
		if value == actorID then
			return true
		end
	end
	return false
end

local function onCombatStart(e)

	--if player do nothing
	if e.actor == tes3.mobilePlayer then
		return
	end

	--get actor reference and ID
	local ref = e.actor.reference
	actorID = ref.baseObject.id

	if logging == true then
		mwse.log("COMBAT START")
		mwse.log(actorID)
	end

	--if companion do nothing
	if ref.context ~= nil then
		if ref.context.companion then

			if logging == true then
				mwse.log("companion")
			end

			return
		end
	end

	--if blacklisted do nothing
	if checkID() == true then

		if logging == true then
			mwse.log("blacklisted")
		end

		return
	end

	--if already scaled do nothing
	if ref.data.baseHealth then

		if logging == true then
			mwse.log("already scaled")
		end

		return
	end

	--get base health
	local baseHealth = e.actor.health.base

	--get current health damage
	local damage = (e.actor.health.base - e.actor.health.current)

	if logging == true then
		mwse.log("base health %s", baseHealth)
		mwse.log("damaged %s", damage)
	end

	--if basehealth exceeds cap do nothing
	if baseHealth > config.hpCap then

		if logging == true then
			mwse.log("exceeds cap %s", config.hpCap)
		end

		return
	end

	--save user data on reference
	ref.data.baseHealth = ref.data.baseHealth or baseHealth

	--get player level
	local playerLevel = tes3.player.object.level

	if logging == true then
		mwse.log("player level %s", playerLevel)
		mwse.log("multiplier %s", config.hpMultiplier)
	end

	--calculate health bonus
	local extraHealth = ((playerLevel * config.hpMultiplier) * baseHealth)

	if logging == true then
		mwse.log("extra health %s", extraHealth)
	end

	--add health bonus to base health
	e.actor.health.base = (baseHealth + extraHealth)

	--if new health > cap set to cap
	if e.actor.health.base > config.hpCap then
		e.actor.health.base = config.hpCap
	end

	--set current health to max minus damage
	e.actor.health.current = (e.actor.health.base - damage)

	if logging == true then
		mwse.log("new max health %s", e.actor.health.base)
		mwse.log("new current health %s", e.actor.health.current)
		mwse.log("cap %s", config.hpCap)
	end

end
event.register("combatStart", onCombatStart)

--register menu
local function registerModConfig()
	require("SUDS.mcm")
end
event.register("modConfigReady", registerModConfig)