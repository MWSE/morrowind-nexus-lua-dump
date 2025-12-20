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
      {key = "unpause_dialog_opt",
         default = "opt_nopause",
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
         name = "settings_modCategory2_setting4_name",
         description = "settings_modCategory2_setting4_desc",
      },
      {key = "visible_shields",
         default = false,
         renderer = "checkbox",
         name = "settings_modCategory2_setting5_name",
         description = "settings_modCategory2_setting5_desc",
      },
      {
        key = "debuglog",
        default = false,
        renderer = "checkbox",
        name = "settings_modCategory2_setting6_name",
      },
   },
})

local settings = storage.globalSection("Settings_dynamicactors")
local player
local dialogActor
local openTime
local pauseAfter = 7
local activateTarget = nil
local npcList = require("scripts.DynamicActors.userConfig.Dialog NPC Blocklist")
npcList.byAnim, npcList.config = table.unpack(require("scripts.DynamicActors.configAnimations"))
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


local function debug(m)
	if logging then		print(m)		end
end

local events = { removeScript = function(e)
	if e.object and e.script and e.object:hasScript(e.script) then
		debug(("%s removing %s"):format(e.object, e.script))
		e.object:removeScript(e.script)
	end
end }

local function debugger(npc)
	if not npc:hasScript("scripts/DynamicActors/npcDialog.lua") then print("script gone") end
end

local function resetActors(data)
	local npc, pos, reset = nil, nil, nil
	for _,v in pairs(actorsincell) do
		npc, cell, pos, reset = v.actor, v.cell, v.pos, v.reset
		if npc.position ~= pos and (pos - npc.position):length() < 100 and npc.cell == cell and reset then
			debug(("%s %s reset to %s"):format(npc, (pos - npc.position):length(), pos))
			npc:teleport(npc.cell, pos)
		end
	end
	actorsincell = { }
end

local function actorMonitor(data)
	if not (I.LuaHelper or I.luaHelper) then		return		end
	local actor = data.actor
	if actor.id == nil then return end
	local id, pos, reset = actor.id, actor.position, data.reset
	if actorsincell[id] then
		debug(("Updating %s %s"):format(id, reset))
		if actorsincell[id].reset then
			if not reset then debug(("Cancel reset %s"):format(actor))	end
			actorsincell[id].reset = reset
		end
	else
		debug(("Track new npc %s %s %s"):format(actor, pos, reset))
		actorsincell[id] = { actor=actor, cell=actor.cell, pos=pos, reset=reset }
	end
end

function events.onDialogClosed()
	for _, v in ipairs(world.activeActors) do
		if v.type == types.NPC then
			if v:hasScript("scripts/DynamicActors/npcDialogAI.lua") then
		--		debug("REMOVE WANDER SCRIPT")
				v:removeScript("scripts/DynamicActors/npcDialogAI.lua")
			end
			if v ~= dialogActor and v:hasScript("scripts/DynamicActors/npcDialog.lua") then
		--		debug("REMOVE DIALOG SCRIPT")
				v:removeScript("scripts/DynamicActors/npcDialog.lua")
			end
		end
	end
	if dialogActor then
		dialogActor:sendEvent("closeNPCdiag")
	--	actor:sendEvent("odarEnabled", true)
	--	actor:sendEvent("odarEvent", {event="odarEnabled", eventData=true})
	end
	dialogActor = nil
end


I.Activation.addHandlerForType(types.NPC, function(o, actor)
	if actor.type == types.Player then activateTarget = o		end
end)


function events.onDialogOpened(data)
	local o = data.arg
	if dialogActor and dialogActor ~= o then
		events.onDialogClosed()
	end
	if activateTarget ~= o and o.type == types.NPC then
		if o.type.records[o.recordId].class == "guard" then
			data.pause = true
		end
	end
	if data.pause then
		if not world.getPausedTags()["ui"] then		world.pause("ui")		end
		if logging and player then player:sendEvent("dynUiMessage", "msg_pause")	end
		return
	end
	activateTarget = nil		local option = settings:get("unpause_dialog_opt")
	if world.getPausedTags()["ui"] ~= nil and option ~= "opt_alwayspause" then
		world.unpause("ui")
		-- debug(("%s %s"):format(world.isWorldPaused(), settings:get("unpause_dialog")))
	elseif world.isWorldPaused() then
		return
	end
	openTime = core.getSimulationTime()
	if option == "opt_delaypause" then
		async:newUnsavableSimulationTimer(pauseAfter, function()
			if dialogActor and core.getSimulationTime() - openTime > pauseAfter - 0.5 then
				if not world.getPausedTags()["ui"] then
					world.pause("ui")
				end
			end
		end)
	end
	if types.Actor.isDead(o) or not data.near then		return		end

	--  Check for poseable mannequins
	if string.find(o.type.records[o.recordId].name:lower(), "mannequin") then
		print("Is a mannequin. Disable animations.")
		return
	end

	dialogActor, player = data.arg, data.player
	local block, groups
	local file = o.type.records[o.recordId].model or ""
	groups = npcList.byAnim[file]
	if not groups then
		local i, j = string.find(file, "/[^/]*$")
		if i then	 file = string.sub(file, i+1, j)	end
		groups = npcList.byAnim[file]
	end

	local idleLevel = settings:get("npcidles") and 5 or 0
	if not groups then
		idleLevel = 0
		if types.NPC.objectIsInstance(o) and types.Actor.stats.ai.hello(o).modified == 0 then
			block = true
		end
	elseif groups.blockAnims then
		idleLevel = 0
	end

	if not block then
		for _, v in pairs(npcList.block) do
			if string.find(o.recordId, "^"..v) ~= nil then
				block = true
				break
			end
		end
	end
	if block then
		for _, v in pairs(npcList.allow) do
			if string.find(o.recordId, "^"..v) ~= nil then
				block = false
				break
			end
		end
	end

	if settings:get("unpause_wanderai") then
		for _, v in ipairs(world.activeActors) do
			if v.type == types.NPC
				and (v.position - player.position):length() < 2000
				and v ~= o and not types.Actor.isDead(v) then
		--		debug(("WANDER %s"):format(v))
				v:addScript("scripts/DynamicActors/npcDialogAI.lua", player)
			end
		end
	end

	local auto, reset = settings:get("autoturn"), false
	for _, v in ipairs(npcList.config) do
	--	print(o.recordId, "^"..v.id)
		if o.recordId:find("^"..v.id) then
			if v.turn == false then auto = false		end
			if v.idle and idleLevel > 0 then idleLevel = v.idle		end
			if v.reset == true then reset = true		end
		end
	end
	if block then
		idleLevel = 0		auto = false
	end

	local plugin
	if vfs.fileExists("scripts/DynamicActors/dialogPlugins/"..o.recordId..".lua") then
		plugin = "scripts.DynamicActors.dialogPlugins." .. o.recordId
		debug(("Plugin found %s"):format(plugin))
	end
	o:addScript("scripts/DynamicActors/npcDialog.lua")
--	o:sendEvent("odarEnabled", false)
--	o:sendEvent("odarEvent", {event="odarEnabled", eventData=false})
	o:sendEvent("initNPCdiag", {
		player, reset, idleLevel, plugin, isMobile=auto, groups=groups,
		shields=settings:get("visible_shields"), logging=logging
	})
end

time.runRepeatedly(function()
	if not dialogActor then		return		end
	dialogActor:sendEvent("shiftPose")
	async:newUnsavableSimulationTimer(6, function()
		if dialogActor then dialogActor:sendEvent("shiftPose", "playBase")	end
	end)
end, 35 * time.second)

--	Precaution if game was saved during dialogue
core.sendGlobalEvent("dynDialogClosed")


return {
	eventHandlers = {
		dynDialogOpened = events.onDialogOpened,
		dynDialogClosed = events.onDialogClosed,
		onCellChangeOlh = resetActors,
		dynRemoveScript = function(data)
	--		debug(("%s removing %s"):format(data.object, data.script))
			if data.object and data.script and data.object:hasScript(data.script) then
				data.object:removeScript(data.script)
			end
		end,
		dynDialogChange = function()
			if dialogActor and settings:get("unpause_dialog_opt") == "opt_nopause" then
				world.unpause("ui")
			end
		end,
		dynForcePause = function()
			if world.getPausedTags()["ui"] == nil and dialogActor then
				world.pause("ui")
				if logging and player then
					player:sendEvent("dynUiMessage", "msg_pause")
				end
			end
		end,
		dynTogglePause = function()
			for k,v in pairs(world.getPausedTags()) do print(k,v) end
			if world.getPausedTags()["ui"] == nil and dialogActor then
				print("pause")
				world.pause("ui")
			elseif dialogActor then
				print("unpause")
				world.unpause("ui")
			end
		end,
		actorMonitor = actorMonitor,
		dynamicActors = function(e)
			if events[e.event or ""] then		events[e.event](e)		end
		end
	},
}
