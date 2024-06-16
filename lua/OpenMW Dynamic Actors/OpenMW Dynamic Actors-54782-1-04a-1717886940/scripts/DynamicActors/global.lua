local world = require("openmw.world")
local core = require("openmw.core")
local vfs = require('openmw.vfs')
local async = require('openmw.async')
local types = require("openmw.types")
local I = require("openmw.interfaces")
local ai = require("openmw.interfaces").AI
local storage = require("openmw.storage")
local time = require("openmw_aux.time")


I.Settings.registerGroup({
   key = "Settings_dynamicactors",
   page = "dynamicactors",
   l10n = "dynamicactors",
   name = "Gameplay Settings",
   permanentStorage = true,
   settings = {
      {
         key = "npcidles",
         default = true,
         renderer = "checkbox",
         name = "Add extra idle animations to NPC actors when in Dialogue.",
      },
      {key = "autoturn",
	default = true,
	renderer = "checkbox",
	name = "Make NPC actors turn to face you during Dialogue.",
	description = "Disable this if there are conflicts with other mods that animate NPC actors."
      },
      {key = "unpause_dialog",
	default = true,
	renderer = "checkbox",
	name = "Prevent game pausing when in Dialogue with NPC actors.",
	description = "If this is not enabled, Dynamic Actors camera control and Actor idle animations during Dialogue will be unavailable." 
      },
      {
         key = "debuglog",
         default = false,
         renderer = "checkbox",
         name = "Print debug messages in game log.",
      },
   },
})

local settings = storage.globalSection("Settings_dynamicactors")
local actor = nil
local openDialog = false
local npcList = require("scripts.DynamicActors.blocklist")
local actorsincell = { }
local logging = false


local function updateSettings()
	local d = not settings:get("unpause_dialog")
	I.Settings.updateRendererArgument("Settings_dynamicactors", "npcidles", {disabled = d})
	I.Settings.updateRendererArgument("Settings_dynamicactors", "autoturn", {disabled = d})
	logging = settings:get("debuglog")
end

updateSettings()
settings:subscribe(async:callback(updateSettings))


local function debugger(npc)
	if not npc:hasScript("scripts/DynamicActors/npcDialog.lua") then print("script gone") end
end

local function resetActors(data)
	local npc, pos, reset = nil, nil, nil
	for _,v in pairs(actorsincell) do
		npc, cell, pos, reset = v.actor, v.cell, v.pos, v.reset
		if npc.position ~= pos and (pos - npc.position):length() < 100 and npc.cell == cell and reset then
			if logging then print(npc, (pos - npc.position):length(), "reset to", pos) end
			npc:teleport(npc.cell, pos)
		end
	end
	actorsincell = { }
end

local function actorMonitor(data)
	if not I.LuaHelper then return end
	local actor = data.actor
	if actor.id == nil then return end
	local id, pos, reset = actor.id, actor.position, data.reset
	if actorsincell[id] then
		if logging then print("Updating", id, reset) end
		if actorsincell[id].reset then
			if not reset and logging then print("Cancel reset", actor) end
			actorsincell[id].reset = reset
		end
	else
		if logging then print("Track new npc", actor, pos, reset) end
		actorsincell[id] = { actor=actor, cell=actor.cell, pos=pos, reset=reset }
	end
end

local function onDialogClosed(data)
	if actor == nil then return end
	actor:sendEvent("closeNPCdiag")
	openDialog = false
end

local function onDialogOpened(data)
--	for k, v in pairs(world.getPausedTags()) do print(k, v) end
	if world.getPausedTags()["ui"] ~= nil and settings:get("unpause_dialog") then world.unpause("ui") end
	if not settings:get("unpause_dialog") or not data.near then return end
	if openDialog and actor ~= data.arg then onDialogClosed(data) end
	actor = data.arg
	local block = false
	for _, v in pairs(npcList.block) do
		if string.find(actor.recordId:lower(), "^"..v) ~= nil then
			block = true
			break
		end
	end
	if block then
		for _, v in pairs(npcList.allow) do
			if string.find(actor.recordId:lower(), "^"..v) ~= nil then
				block = false
				break
			end
		end
	end
	if block then return end
	local auto, idle, reset = settings:get("autoturn"), 0, false
	if settings:get("npcidles") then idle = 5 end
	for _, v in pairs(npcList.config) do
		if string.find(actor.recordId:lower(), "^"..v.id) ~= nil then
			if v.turn == false then auto = false end
			if v.idle and idle > 0 then idle = v.idle end
			if v.reset == true then reset = true end
		end
	end
	actor:addScript("scripts/DynamicActors/npcDialog.lua")
	actor:sendEvent("initNPCdiag", { data.player, auto, reset, idle, logging })
	openDialog = true
end

time.runRepeatedly(function()
	if not openDialog then return end
	actor:sendEvent("shiftPose")
end, 35 * time.second)

return {
  eventHandlers = {
		dynDialogOpened = onDialogOpened,
		dynDialogClosed = onDialogClosed,
		onCellChangeOlh = resetActors,
		dynRemoveScript = function(data)
	print(data.object, "removing", data.script)
	data.object:removeScript(data.script)
	end,
		actorMonitor = actorMonitor
  },
}
