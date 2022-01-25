local common = include("Magicka Regen Suite.common")


local timeBeforeTravel


-- Regenerate magicka for Player during traveling, no regen for NPCs and Creatures this time
-- because the Player has entered a new cell -> NPCs from last destination were unloaded.
-- Player's companions do get regeneration if the player has any. 
local function travelMagicka(e)
	if (not tes3.mobilePlayer.travelling) then    -- Get time before travelling
		timeBeforeTravel = tes3.getSimulationTimestamp()
	end

	if tes3.mobilePlayer.traveling then	-- Travel finished
		local hoursPassed = tes3.getSimulationTimestamp() - timeBeforeTravel
		timeBeforeTravel = nil

        common.restoreIf(tes3.player, hoursPassed * 3600, true)

        if e.companions then
            for ref in e.companions do
                common.restoreIf(ref, hoursPassed * 3600, true)
            end
        end
	end
end

event.register("initialized", function()		
	event.register("calcTravelPrice", travelMagicka)
end)