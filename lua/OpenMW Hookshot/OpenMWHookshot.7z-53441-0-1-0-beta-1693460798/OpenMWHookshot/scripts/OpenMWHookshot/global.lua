local core = require('openmw.core')

local teleportOptions = {
	onGround = false
}

local function teleportHandler(data)
	-- print('current position: ' .. tostring(data.object.position))
	data.object:teleport(data.object.cell.name, data.newPos, {onGround=false})
	-- print('teleporting to: ' .. tostring(data.newPos))
end

return {
	eventHandlers = {
		ragdollTeleport = teleportHandler
	}
}