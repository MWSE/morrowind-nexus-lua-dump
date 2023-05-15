local corpse
local interval = 0.025
local totalDuration = 0.5
local iterations = totalDuration / interval

local beginPosition = tes3vector3.new(160395.438, 89348.180, -5048.607)
local endPosition = tes3vector3.new(160412.672, 89346.953, -5055.976)
local beginOrientation = { 349.3, 351.7, 251.6 }
local endOrientation = { 329.5, 291.2, 278.8 }
local positionOffset = { 17.672, -1.227, -7.369 }
local orientationOffset = { -19.8 / 180, -60.5 / 180, 27.2 / 180 }

local function corpseDown()

	corpse.position = tes3vector3.new(corpse.position.x + positionOffset[1] / iterations, corpse.position.y + positionOffset[2] / iterations,
	                                  corpse.position.z + positionOffset[3] / iterations)
	corpse.orientation = {
		corpse.orientation.x + orientationOffset[1] / iterations,
		corpse.orientation.y + orientationOffset[2] / iterations,
		corpse.orientation.z + orientationOffset[3] / iterations,
	}
end

---@param e activateEventData
local function takeRapier(e)
	if e.activator ~= tes3.player then
		return
	end
	if e.target.baseObject.id ~= "jsmk_rw_we_rapier" then
		return
	end
	corpse = tes3.getReference("jsmk_rw_co_corpse")
	if not corpse then
		return
	end
	event.unregister("activate", takeRapier)
	timer.start({ type = timer.simulate, duration = interval, callback = corpseDown, iterations = iterations })
end
event.register("activate", takeRapier)
