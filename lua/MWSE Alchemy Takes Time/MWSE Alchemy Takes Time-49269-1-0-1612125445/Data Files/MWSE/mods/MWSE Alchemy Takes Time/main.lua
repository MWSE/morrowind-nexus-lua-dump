


 local function alchemyTime()

		local gameHour = tes3.getGlobal('GameHour')
		gameHour = gameHour + 0.5
		tes3.setGlobal('GameHour', gameHour)
		print("[MWSE Alchemy Takes Time: INFO] Time Passed")
		end
			
			
			
 -- The function to call on the initialized event.
 local function initialized()
	event.register("potionBrewed", alchemyTime)

     -- Print a "Ready!" statement to the MWSE.log file.
     print("[MWSE Alchemy Takes Time: INFO] MWSE Alchemy Takes Time Initialized")
 end

 -- Register our initialized function to the initialized event.
 event.register("initialized", initialized)