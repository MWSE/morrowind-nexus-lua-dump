local world = require('openmw.world')

return {
    engineHandlers = {},
    eventHandlers = {
		toggleSimulation = function(timeScale)
			world.setSimulationTimeScale(timeScale)
		end,
        
		InspectIt_SetPlayerVisible = function(data)
            local player = world.players[1]
            if not (player and player:isValid()) then return end

            if not data.visible then
																					  
                playerStashedScale = player.scale
                player:setScale(0.01)
                print('[InspectIt Global] Player scale hidden.')
            else
                if playerStashedScale ~= nil then
                    player:setScale(playerStashedScale)
                    playerStashedScale = nil
                    print('[InspectIt Global] Player scale restored.')
                end
            end
        end,	
	
        toggleSimulation = function(timeScale)
            print('[InspectIt Global] Setting simulation time scale to: ' .. timeScale)
            world.setSimulationTimeScale(timeScale)
        end
    }
}
