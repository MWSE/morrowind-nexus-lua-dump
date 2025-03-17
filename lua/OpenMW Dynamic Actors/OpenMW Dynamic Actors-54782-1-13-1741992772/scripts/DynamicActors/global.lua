local world = require("openmw.world")
local core = require("openmw.core")
local vfs = require('openmw.vfs')
local async = require('openmw.async')
local types = require("openmw.types")
local I = require("openmw.interfaces")
local ai = require("openmw.interfaces").AI
local storage = require("openmw.storage")
local time = require("openmw_aux.time")
local animation = require("openmw.animation")


I.Settings.registerGroup({
   key = "Settings_dynamicactors",
   page = "dynamicactors",
   l10n = "DynamicActors",
   name = "settings_modCategory2_name",
   permanentStorage = true,
   settings = {
      {
         key = "npcidles",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory2_setting1_name",
      },
      {key = "autoturn",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory2_setting2_name",
	description = "settings_modCategory2_setting2_desc",
      },
      {key = "unpause_dialog",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory2_setting3_name",
	description = "settings_modCategory2_setting3_desc",
      },
      {
         key = "debuglog",
         default = false,
         renderer = "checkbox",
         name = "settings_modCategory2_setting4_name",
      },
   },
})

local settings = storage.globalSection("Settings_dynamicactors")
local actor = nil
local player = nil
local openDialog = false
local activateTarget = nil
local npcList = require("scripts.DynamicActors.blocklist")
local actorsincell = { }
local logging = false


local function updateSettings()
--	local d = not settings:get("unpause_dialog")
	I.Settings.updateRendererArgument("Settings_dynamicactors", "npcidles", {disabled=false})
	I.Settings.updateRendererArgument("Settings_dynamicactors", "autoturn", {disabled=false})
	logging = settings:get("debuglog")
end

updateSettings()
settings:subscribe(async:callback(updateSettings))

local oldVfsApi = true
if types.Static.records["ex_de_oar"].model:find("/") then oldVfsApi = false	end


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
	if not (I.LuaHelper or I.luaHelper) then return end
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


I.Activation.addHandlerForType(types.NPC, function(o, actor)
	if actor.type == types.Player then activateTarget = o end
end)


local function onDialogOpened(data)
	local o = data.arg
	if activateTarget ~= o and o.type == types.NPC then
		if types.NPC.record(o).class == "guard" then
			if world.getPausedTags()["ui"] == nil then world.pause("ui") end
			if logging and player then player:sendEvent("dynUiMessage", "msg_pause") end
			return
		end
	end
	activateTarget = nil
--	for k, v in pairs(world.getPausedTags()) do print(k, v) end
	if world.getPausedTags()["ui"] ~= nil and settings:get("unpause_dialog") then
		world.unpause("ui")
--		print(world.isWorldPaused(), settings:get("unpause_dialog"))
--		for k, v in pairs(world.getPausedTags()) do print(k, v) end
	elseif world.isWorldPaused() or not data.near then
		return
	end
	if openDialog and actor ~= data.arg then onDialogClosed(data) end
	actor, player = data.arg, data.player
	local block = false
	local file
	if actor.type == types.NPC then file = types.NPC.record(actor).model	end
	file = file or ""

	local i, j
	if oldVfsApi then
		--	OMW versions before Nov 19 2024
		i, j = string.find(file, "\\[^\\]*$")
	else
		--	OMW versions past Nov 19 2024
		i, j = string.find(file, "/[^/]*$")
	end

	if i then file = string.sub(file, i+1, j) end
	local groups = npcList.byAnim[file:lower()]
	if groups then
		for _, v in ipairs(groups) do 
			if v == "all" or animation.isPlaying(actor, v) then
				if logging then print(file, v) end
				block = true
				break
			end
		end
	end
	if not block then
		for _, v in pairs(npcList.block) do
			if string.find(actor.recordId:lower(), "^"..v) ~= nil then
				block = true
				break
			end
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
	local plugin = nil
	if vfs.fileExists("scripts/DynamicActors/dialogPlugins/"..actor.recordId..".lua") then
		plugin = "scripts.DynamicActors.dialogPlugins." .. actor.recordId
		if logging then print("Plugin found", plugin) end
	end
	actor:addScript("scripts/DynamicActors/npcDialog.lua")
	actor:sendEvent("initNPCdiag", { data.player, auto, reset, idle, logging, plugin })
	openDialog = true
end

time.runRepeatedly(function()
	if not openDialog then return end
	actor:sendEvent("shiftPose")
	async:newUnsavableSimulationTimer(6, function()
		if openDialog then actor:sendEvent("shiftPose", "playBase") end
	end)
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
		dynDialogChange = function()
	if openDialog and world.getPausedTags()["ui"] ~= nil and settings:get("unpause_dialog") then
		world.unpause("ui")
	end
	end,
		dynForcePause = function()
	if world.getPausedTags()["ui"] == nil and openDialog then
		world.pause("ui")
		if logging and player then player:sendEvent("dynUiMessage", "msg_pause") end
	end
	end,
		dynTogglePause = function()
	for k,v in pairs(world.getPausedTags()) do print(k,v) end
	if world.getPausedTags()["ui"] == nil and openDialog then
		print("pause")
		world.pause("ui")
	elseif openDialog then
		print("unpause")
		world.unpause("ui")
	end
	end,
		actorMonitor = actorMonitor
  },
}
