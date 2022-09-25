local common = require("Magicka Regen Suite.common")

local PC_REFRESH_RATE = 0.1
local NPC_REFRESH_RATE = 1

local function actorRegen()
	common.processActors(NPC_REFRESH_RATE)
end

local function playerRegen()
    common.restoreIf(tes3.player, PC_REFRESH_RATE)
end

event.register(tes3.event.initialized, function()
	event.register(tes3.event.loaded, function()
		timer.start({ iterations = -1, duration = NPC_REFRESH_RATE, callback = actorRegen })
		timer.start({ iterations = -1, duration = PC_REFRESH_RATE, callback = playerRegen })
	end)
end)