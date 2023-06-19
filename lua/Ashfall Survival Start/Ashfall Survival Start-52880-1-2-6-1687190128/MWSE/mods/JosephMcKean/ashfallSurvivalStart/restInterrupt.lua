---@param e restInterruptEventData
local function restInterruptCallback(e)
	if tes3.player.data.ass.guar then
		return
	end
	local playerCell = tes3.getPlayerCell()
	local inMasartus = playerCell.id == "Masartus"
	if not inMasartus then
		return
	end
	local guar = tes3.getObject("guar") ---@cast guar tes3creature
	e.creature = guar
	tes3.player.data.ass.guar = true
end
event.register("restInterrupt", restInterruptCallback)
