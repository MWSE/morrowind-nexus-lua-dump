local function teleportHandler(data)
	if data.rotation then
		data.object:teleport(data.object.cell.name, data.newPos, data.rotation)
	else
		data.object:teleport(data.object.cell.name, data.newPos)
	end
end

return {
	eventHandlers = {
		TK_Teleport = teleportHandler
	}
}