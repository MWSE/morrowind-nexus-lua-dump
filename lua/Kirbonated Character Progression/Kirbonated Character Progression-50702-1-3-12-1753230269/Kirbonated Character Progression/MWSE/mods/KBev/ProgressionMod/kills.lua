--manages XP from enemy kills
local common = require("KBev.ProgressionMod.common")
local mcm = require("KBev.ProgressionMod.mcm")
local public = {}

public.registerBossMonster = function(id)
	common.bossMonsters[id] = true
end

public.unregisterBossMonster = function(id)
	common.bossMonsters[id] = nil
end

local function registerBoss(e)
	if not e.id then common.err("registerBoss - No ID was provided") return end
	public.registerBossMonster(e.id)	
end
event.register("KCP:registerBoss", registerBoss) --expected params -> {id = ...}

return public