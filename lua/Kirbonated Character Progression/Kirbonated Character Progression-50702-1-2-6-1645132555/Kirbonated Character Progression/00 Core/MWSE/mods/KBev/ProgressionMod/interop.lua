--[[
	Interop Functions for KB Progression Framework
]]
local common = require("KBev.ProgressionMod.common")


local public = {}
public.quest = require("KBev.ProgressionMod.questManager")
common.info("quest Manager Hooked")
public.perk = require("KBev.ProgressionMod.perkFunctions")
common.info("Perk Manager Hooked")
public.playerData = require("KBev.ProgressionMod.player")
common.info("Player Manager Hooked")

local function registerQuest(e)
	if not public.quest then return end
	if not e.id then common.err("registerQuest - No ID was provided") return end
	if e.type == "main" then
		public.quest.registerMainQuest(e.id)
	elseif e.type == "guild" then
		public.quest.registerGuildQuest(e.id)
	elseif e.type == "task" then
		public.quest.registerTaskQuest(e.id)
	elseif e.type == "noXP" then
		public.quest.registerNoXPQuest(e.id)
	else common.err("Attempted to parse unrecognized quest type \"" .. e.type or "nil" .. "\"")
	end
end

local function registerBoss(e)
	if not e.id then common.err("registerBoss - No ID was provided") return end
	public.quest.registerBossMonster(e.id)	
end

--event registers
event.register("KBProgression:registerQuest", registerQuest) --expected params -> {id = ... , type = ...}
event.register("KBProgression:registerBoss", registerBoss) --expected params -> {id = ...}

return public