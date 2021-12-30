local common = include("Magicka Regen Suite.common")

local function processActors(secondsPassed, alot)
    for ref in common.getActors(false) do
        if not ref.mobile then return end
		common.restoreIf(ref, secondsPassed, alot)
    end
end

-- Regenerate magicka for Player, NPCs and Creatures in active cells based on time waited
local function waitMagicka(e)
	local hoursPassed = tes3.mobilePlayer.restHoursRemaining

	if e.count > 0 and e.hour > 1 then
        -- The sleep was interrupted
		hoursPassed = hoursPassed - (e.hour - 1)
	end

    processActors(hoursPassed * 3600, true)
	common.restoreIf(tes3.player, hoursPassed * 3600, true)
end

event.register("initialized", function()
	event.register("calcRestInterrupt", waitMagicka)
end)