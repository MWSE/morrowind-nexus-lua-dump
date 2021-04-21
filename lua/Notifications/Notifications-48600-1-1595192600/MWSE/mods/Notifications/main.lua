local config = require("Notifications.config")
local function onDeath(e)
	if config.deathnote then
		tes3.messageBox("%s has died." , e.reference.object.name)
	end
end
local function onCrimeWitnessed(e)
	if config.crimenote then
		tes3.messageBox({ message = e.witness.object.name .. " witnessed " .. e.type })
	end
end
local function onCombatStart(e)
	if config.fightnote then
		tes3.messageBox({ message = e.actor.object.name .. " attacked " .. e.target.object.name })
	end
end
local function onCellChanged(e)
	if config.cellnote then
		if (e.previousCell == nil) then
			return
		end
		local NewCell = e.cell.name or e.cell.id
		local PrevCell = e.previousCell.name or e.previousCell.id
		if NewCell ~= PrevCell then
			tes3.messageBox("Entering %s" , NewCell )
		end
	end
end
local function initialized()
	event.register("death", onDeath)
	event.register("crimeWitnessed", onCrimeWitnessed)
	event.register("combatStart", onCombatStart)
	event.register("cellChanged", onCellChanged)
end
event.register("initialized", initialized)
local function registerModConfig()
	require("Notifications.mcm")
end
event.register("modConfigReady", registerModConfig)