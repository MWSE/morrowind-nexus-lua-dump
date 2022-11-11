--[[
	Interop Functions for KB Progression Framework
]]
local common = require("KBev.ProgressionMod.common")


local public = {}
public.quest = require("KBev.ProgressionMod.questManager")
common.info("Quest Manager Hooked")
public.perk = require("KBLib.PerkSystem.perkSystem") --maintained for backwards compatibility
common.info("Perk Manager Hooked")
public.playerData = require("KBev.ProgressionMod.player")
common.info("Player Manager Hooked")
public.enemy = require("KBev.ProgressionMod.kills")
common.info("Enemy Manager Hooked")

return public