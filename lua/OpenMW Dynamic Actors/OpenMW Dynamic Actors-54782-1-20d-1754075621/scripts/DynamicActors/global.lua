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
--[[
      {key = "unpause_dialog",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory2_setting3_name",
	description = "settings_modCategory2_setting3_desc",
      },
--]]
      {key = "unpause_dialog_opt",
	default = "opt_unpaused",
	name = "settings_modCategory2_setting3_name",
	description = "settings_modCategory2_setting3_desc",
	renderer = "select",
	argument = {
		disabled = false,
		l10n = "DynamicActors", 
		items = { "opt_nopause", "opt_delaypause", "opt_alwayspause" },
		},
      },
      {key = "unpause_wanderai",
	default = true,
	renderer = "checkbox",
	name = "Override AI of wandering NPC's",
	description = "During unpaused dialog, wandering NPC's will be blocked from speaking or moving too close.",
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
local openDialog, openTime
local pauseAfter = 7
local activateTarget = nil
local npcList = require("scripts.DynamicActors.blocklist")
local actorsincell = {}
local logging = false

-- legacy settings check
do
	local set = settings:get("unpause_dialog")
	-- print("LEGACY", set, settings:get("unpause_dialog_opt"))
	if set ~= nil and type(set) == "boolean" then
		settings:set("unpause_dialog_opt", set and "opt_nopause" or "opt_alwayspause")
		settings:set("unpause_dialog", nil)
	end
end

local function updateSettings()
--	local d = not settings:get("unpause_dialog")
	I.Settings.updateRendererArgument("Settings_dynamicactors", "npcidles", {disabled=false})
	I.Settings.updateRendererArgument("Settings_dynamicactors", "autoturn", {disabled=false})
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

local function onDialogClosed()
	for _, v in ipairs(world.activeActors) do
		if v.type == types.NPC then
			if v:hasScript("scripts/DynamicActors/npcDialogAI.lua") then
		--		print("REMOVE WANDER SCRIPT")
				v:removeScript("scripts/DynamicActors/npcDialogAI.lua")
			end
			if v ~= actor and v:hasScript("scripts/DynamicActors/npcDialog.lua") then
		--		print("REMOVE DIALOG SCRIPT")
				v:removeScript("scripts/DynamicActors/npcDialog.lua")
			end
		end
	end
	if actor then
		actor:sendEvent("closeNPCdiag")
	--	actor:sendEvent("odarEnabled", true)
	--	actor:sendEvent("odarEvent", {event="odarEnabled", eventData=true})
	end
	openDialog = false
end


I.Activation.addHandlerForType(types.NPC, function(o, actor)
	if actor.type == types.Player then activateTarget = o		end
end)


local function onDialogOpened(data)
	local o = data.arg
	if openDialog and actor ~= o then onDialogClosed()		end
	if activateTarget ~= o and o.type == types.NPC then
		if o.type.records[o.recordId].class == "guard" then
			if world.getPausedTags()["ui"] == nil then world.pause("ui") end
			if logging and player then player:sendEvent("dynUiMessage", "msg_pause") end
			return
		end
	end
	activateTarget = nil		local option = settings:get("unpause_dialog_opt")
	if world.getPausedTags()["ui"] ~= nil and option ~= "opt_alwayspause" then
		world.unpause("ui")
		-- print(world.isWorldPaused(), settings:get("unpause_dialog"))
	elseif world.isWorldPaused() then
		return
	end
	openTime = core.getSimulationTime()
	if option == "opt_delaypause" then
		async:newUnsavableSimulationTimer(pauseAfter, function()
			if openDialog and core.getSimulationTime() - openTime > pauseAfter - 0.5 then
				if not world.getPausedTags()["ui"] then
					world.pause("ui")
				end
			end
		end)
	end
	if types.Actor.isDead(o) or not data.near then		return		end

	--  Check for poseable mannequins
	if string.find(o.type.records[o.recordId].name:lower(), "mannequin") then
		if logging then print("Is a mannequin. Disable animations.")		end
		return
	end

--[[
	local noAI = true
	for _, v in pairs(types.Actor.stats.ai) do
		if v(o).base ~= 0  then noAI = false		end
	end
	if noAI then
		if logging then print("All base AI stats are 0. Assume mannequin")		end
		return
	end
--]]

--[[
	--  Check for blocked mwscript ID
	local script = o.type.records[o.recordId].mwscript
	if script and string.find(script:lower(), "aakarcs_man_") then
		return
	end
--]]

	actor, player = data.arg, data.player
	local block = false
	local file = (o.type.records[o.recordId].model or ""):lower()

	--	bugfix for OMW versions before Nov 19 2024
	file = string.gsub(file, "\\", "/")

	local i, j = string.find(file, "/[^/]*$")
	if i then file = string.sub(file, i+1, j) end
	local groups = npcList.byAnim[file:lower()]

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

	if settings:get("unpause_wanderai") then
		for _, v in ipairs(world.activeActors) do
			if v.type == types.NPC and v ~= actor and not types.Actor.isDead(v) then
		--		print("WANDER", v)
				v:addScript("scripts/DynamicActors/npcDialogAI.lua", actor)
			end
		end
	end

	local auto, reset = settings:get("autoturn"), false
	local idle = settings:get("npcidles") and 5 or 0
	for _, v in pairs(npcList.config) do
		if string.find(actor.recordId:lower(), "^"..v.id) ~= nil then
			if v.turn == false then auto = false		end
			if v.idle and idle > 0 then idle = v.idle	end
			if v.reset == true then reset = true		end
		end
	end
	if block then idle = 0		auto = false		 end

	local plugin
	if vfs.fileExists("scripts/DynamicActors/dialogPlugins/"..actor.recordId..".lua") then
		plugin = "scripts.DynamicActors.dialogPlugins." .. actor.recordId
		if logging then print("Plugin found", plugin)		end
	end
	actor:addScript("scripts/DynamicActors/npcDialog.lua")
--	actor:sendEvent("odarEnabled", false)
--	actor:sendEvent("odarEvent", {event="odarEnabled", eventData=false})
	actor:sendEvent("initNPCdiag", { data.player, auto, reset, idle, logging, plugin, groups=groups })
	openDialog = true

end

time.runRepeatedly(function()
	if not openDialog then		return		end
	actor:sendEvent("shiftPose")
	async:newUnsavableSimulationTimer(6, function()
		if openDialog then actor:sendEvent("shiftPose", "playBase") end
	end)
end, 35 * time.second)

--	Precaution if game was saved during dialogue
core.sendGlobalEvent("dynDialogClosed")


return {
	eventHandlers = {
		dynDialogOpened = onDialogOpened,
		dynDialogClosed = onDialogClosed,
		onCellChangeOlh = resetActors,
		dynRemoveScript = function(data)
	--		print(data.object, "removing", data.script)
			if data.object and data.script and data.object:hasScript(data.script) then
				data.object:removeScript(data.script)
			end
		end,
		dynDialogChange = function()
			if openDialog and world.getPausedTags()["ui"] ~= nil
			and settings:get("unpause_dialog_opt") == "opt_nopause" then
				world.unpause("ui")
			end
		end,
		dynForcePause = function()
			if world.getPausedTags()["ui"] == nil and openDialog then
				world.pause("ui")
				if logging and player then
					player:sendEvent("dynUiMessage", "msg_pause")
				end
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
