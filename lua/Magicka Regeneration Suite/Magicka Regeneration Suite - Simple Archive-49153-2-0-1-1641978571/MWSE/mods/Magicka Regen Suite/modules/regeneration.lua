local common = include("Magicka Regen Suite.common")

local PC_REFRESH_RATE = 0.1
local NPC_REFRESH_RATE = 1


local function processActors(secondsPassed)
    for ref in common.getActors(false) do
        if not ref.mobile then return end
        common.restoreIf(ref, secondsPassed)
    end
end

local function actorRegen()
    processActors(NPC_REFRESH_RATE)
end
local function playerRegen()
    common.restoreIf(tes3.player, PC_REFRESH_RATE)
end

event.register("initialized", function()
	event.register("loaded", function()
		timer.start{ iterations = -1, duration = NPC_REFRESH_RATE, callback = actorRegen }
		timer.start{ iterations = -1, duration = PC_REFRESH_RATE, callback = playerRegen }
	end)
end)