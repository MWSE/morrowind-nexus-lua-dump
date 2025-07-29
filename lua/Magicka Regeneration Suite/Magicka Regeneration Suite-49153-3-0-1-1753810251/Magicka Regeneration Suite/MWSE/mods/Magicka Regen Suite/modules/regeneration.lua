local common = require("Magicka Regen Suite.common")

local PC_REGEN_RATE = 0.1
local NPC_REGEN_RATE = 1

local function actorRegen()
	common.processActors(NPC_REGEN_RATE)
end

local function playerRegen()
	common.restoreIf(tes3.player, PC_REGEN_RATE)
end

event.register(tes3.event.loaded, function()
	timer.start({ iterations = -1, duration = NPC_REGEN_RATE, callback = actorRegen })
	timer.start({ iterations = -1, duration = PC_REGEN_RATE, callback = playerRegen })
end)
