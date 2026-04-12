local core = require("openmw.core")
local world = require("openmw.world")
local types = require("openmw.types")

return {
	eventHandlers = {
		STV_Water_Safe = function()
			world.mwscript.getGlobalVariables()["STV_Sun"] = -1
		end,

		STV_Feed = function(data)
			if types.Actor.activeSpells(data.actor):isSpellActive("STV_Drained") then
				return
			end

			types.Actor.activeSpells(data.actor):add({id = "STV_Drained", effects = {0}})
			if types.Creature.objectIsInstance(data.actor) then
				world.mwscript.getGlobalVariables()["STV_Blood_Meter"] = world.mwscript.getGlobalVariables()["STV_Blood_Meter"]
					+ types.Creature.record(data.actor).soulValue * 1.5
			elseif types.NPC.objectIsInstance(data.actor) then
				world.mwscript.getGlobalVariables()["STV_Blood_Meter"] = world.mwscript.getGlobalVariables()["STV_Blood_Meter"]
					+ 100
			end
		end,
	},
}
