local util = require('openmw.util')
local playerRef
local wispRef
local dummyRef
local shine
return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor and actor.recordId == "aaa_kindi_light_laaeet" then
				wispRef = actor
				actor:addScript("wispy_light/wisplocal.lua")
            end
        end,
		onPlayerAdded = function(player) playerRef = player player:addScript("wispy_light/player.lua") end,
		onSave = function() return { wisp = wispRef, dummy = dummyRef, isShine = shine } end,
		onLoad = function(data) wispRef = data.wisp dummyRef = data.dummy shine = data.isShine if wispRef then print("Wisp loaded") end end
    },

	eventHandlers = {
	getDummy = function(data)
		if not dummyRef then
		dummyRef = unpack(data)
		end
	end,

	warpToPlayer = function()
		if playerRef.inventory:countOf("kindi_book_of_laaeet") > 0 then
		wispRef:teleport(playerRef.cell.name, playerRef.position)
		end
		if shine then
		dummyRef:teleport(playerRef.cell.name, playerRef.position)
		end
	end,
	warpToVoid = function()
		wispRef:teleport("Mournhold", util.vector3(0, 0, 0))
	end,
	onOffAi = function(data)
		wispRef:sendEvent("onOffAi", data)
	end,
	shineOrDim = function(data)
		if not dummyRef then return end
		if data.enable then
		shine = true
		dummyRef:teleport(playerRef.cell.name, playerRef.position)
		else
		shine = false
		dummyRef:teleport("Mournhold", util.vector3(0, 0, 0))
		end
	end
	}
}
