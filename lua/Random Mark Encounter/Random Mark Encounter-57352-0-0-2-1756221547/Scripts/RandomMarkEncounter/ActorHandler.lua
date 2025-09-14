local world = require("openmw.world")
local util = require("openmw.util")
local types = require("openmw.types")
local async = require("openmw.async")

local actorHandler = {engineHandlers = {},eventHandlers={}}
local metMark = false

local cooldownMark=async:registerTimerCallback('cooldownMark',function()
	metMark=false
end)
local destroyMark = async:registerTimerCallback('destroyMark',function(mark)
	mark:remove()
	async:newSimulationTimer(1,cooldownMark)
end)

local function summonMark(player)
	local mark = world.createObject("MarkSpellMark",1)
	mark:teleport(player.cell.name,player.position)
    async:newSimulationTimer(10, destroyMark,mark)
end

function actorHandler.eventHandlers.onCastMark(player)
	if metMark then return end
	metMark=true
	if math.random(1,4)==1 then
		summonMark(player)
	else
		async:newSimulationTimer(2,cooldownMark)
	end
end

return actorHandler
