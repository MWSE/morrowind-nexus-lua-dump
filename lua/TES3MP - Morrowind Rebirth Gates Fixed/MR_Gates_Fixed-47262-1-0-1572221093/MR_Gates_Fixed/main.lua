local scriptConfig = {}


scriptConfig.openGatesOnDaytime = true -- when the hour shifts to 6 a.m. the city gates will open, else will only unlocked (Default: true)
scriptConfig.lockLevelDay = 1000 -- so players can't use the door (Default: 1000 ; using OnObjectActivate would be safer approach)
scriptConfig.lockLevelNight = 100 -- (Default: 100)
scriptConfig.createTimerCountdown = 1000 -- in miliseconds -> Default: 1 second (1000)
scriptConfig.resetTimerCountdown = 1000 -- in miliseconds -> Default: 1 second (1000)
scriptConfig.lockedGateStart = 22 -- hour when the gate gets closed and locked (Default: 22)
scriptConfig.lockedGateEnd = 6 -- hour when the gate gets unlocked again (Default: 6)



local Methods = {}

local RebirthGates = {"mr_city_gate_01", "mr_city_gate_02", "mr_imp_gate", "mr_portcullis_01", "mr_portcullis_02"}

local function isRebirthGate(refId)

for _, gate in pairs(RebirthGates) do
	if gate == refId then
		return true
	end
end

return false
end

Methods.Timer = tes3mp.CreateTimer("RebirthGates_DayNightCycle", scriptConfig.createTimerCountdown)

function RebirthGates_DayNightCycle()

	if LoadedCells ~= nil then
	
		for cellDesc, _ in pairs(LoadedCells) do
		
			if LoadedCells[cellDesc] ~= nil then
				local cellData = LoadedCells[cellDesc].data
				
				if cellData.packets and cellData.packets.lock then
				
					for _, uniqueIndex in pairs(cellData.packets.lock)do
					
						if isRebirthGate(cellData.objectData[uniqueIndex].refId) then
							tableHelper.insertValueIfMissing(cellData.packets.doorState, uniqueIndex)
							
							if WorldInstance.data.time.hour >= scriptConfig.lockedGateEnd and WorldInstance.data.time.hour < scriptConfig.lockedGateStart then
								
								if scriptConfig.openGatesOnDaytime then
								
									if cellData.objectData[uniqueIndex].doorState == nil or cellData.objectData[uniqueIndex].doorState ~= 1 then
										cellData.objectData[uniqueIndex].doorState = 1
									end
									
																	
									if cellData.objectData[uniqueIndex].lockLevel ~= scriptConfig.lockLevelDay then
										cellData.objectData[uniqueIndex].lockLevel = scriptConfig.lockLevelDay
									end
								
								else 
									
									if cellData.objectData[uniqueIndex].lockLevel ~= 0 then
										cellData.objectData[uniqueIndex].lockLevel = 0
									end
								
								
									LoadedCells[cellDesc]:QuicksaveToDrive()
								
								end
							
							else
								
								if cellData.objectData[uniqueIndex].doorState == nil or cellData.objectData[uniqueIndex].doorState ~= 2 then
									cellData.objectData[uniqueIndex].doorState = 2
								end
								
								if cellData.objectData[uniqueIndex].lockLevel ~= scriptConfig.lockLevelNight then
										cellData.objectData[uniqueIndex].lockLevel = scriptConfig.lockLevelNight
								end
								
								LoadedCells[cellDesc]:QuicksaveToDrive()
							
							end
							
							for pid, _ in pairs(Players) do
								if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
									LoadedCells[cellDesc]:LoadDoorStates(pid, cellData.objectData, cellData.packets.doorState)
									LoadedCells[cellDesc]:LoadObjectsLocked(pid, cellData.objectData, cellData.packets.lock)
								end
							end
						end
					end
				end
			end
		end
	end
	tes3mp.RestartTimer(Methods.Timer, scriptConfig.resetTimerCountdown)
end

Methods.OnServerPostInit = function(EventStatus)

tes3mp.StartTimer(Methods.Timer)

end
					
					
customEventHooks.registerHandler("OnServerPostInit", Methods.OnServerPostInit)

return Methods