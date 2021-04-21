local C = {["-7-5"]=1,["-7-6"]=1,["-6-4"]=1,["-6-6"]=1,["-6-5"]=1,["-5-4"]=1}
local W = {0,1,2,2,4,4,4,5}		--["clear"] = 0,["cloudy"] = 1,["foggy"] = 2,["rain"] = 4,["thunder"] = 5,		--tes3.player.cell.region.id == "Bitter Coast Region"
local function cellChanged() if not tes3.player.cell.isInterior then local st = tes3.getSimulationTimestamp()	local c = tes3.player.cell.gridX .. tes3.player.cell.gridY		
	if C[c] and st - (tes3.player.data.WEA1 or 0) > 5 then	tes3.player.data.WEA1 = st		local wc = tes3.worldController.weatherController	local w = table.choice(W)
		if wc.currentWeather.index ~= w then wc:switchTransition(w) end		--tes3.messageBox("cell = %s   current = %s   change to %s", c, wc.currentWeather.index, w)
	end
end end		event.register("cellChanged", cellChanged)