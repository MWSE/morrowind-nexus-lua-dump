customEventHooks.registerHandler("OnPlayerInventory", function(eventStatus, pid)
	if eventStatus.validCustomHandlers then
		for i,item in ipairs(Players[pid].data.inventory) do
			if item.refId == "tes3mp_advance_time_item" then
				
				table.remove(Players[pid].data.inventory, i)
				Players[pid]:LoadInventory()
				Players[pid]:LoadEquipment()
				
				local hour = WorldInstance.data.time.hour + item.count
				while hour >= 24 do
					hour = hour - 24
					WorldInstance:IncrementDay()
				end
				WorldInstance.data.time.hour = hour
				
				WorldInstance:QuicksaveToDrive()
				WorldInstance:LoadTime(pid, true)
				hourCounter = WorldInstance.data.time.hour
				WorldInstance:UpdateFrametimeMultiplier()
				return
				
			end
		end
	end
end)
