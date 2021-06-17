
-- Checks to see if the mobile actor is one of the player's companions.
local function isPlayerCompanion(target)
	for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if (actor.object == target.object) then
			return true
		end
	end
	return false
end

local function onActivate(e)
	if (e.activator == tes3.player) then -- Activator is the player
		if (e.target.object.objectType == tes3.objectType.npc) then -- Target is an NPC
			if (tes3.player.mobile.isSneaking) then -- The player is sneaking
				if (isPlayerCompanion(e.target)) then -- The target is one of your companions
					tes3.messageBox("You can't pickpocket your companions.")
					return false
				end
			end
		end
	end
end


event.register("initialized", function(e)
	event.register("activate", onActivate)
	mwse.log("[Friends Don't Pickpocket Followers] Enabled")
end)
