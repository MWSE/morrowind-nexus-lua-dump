local core = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local util = require("openmw.util")
local async = require("openmw.async")
local storage = require("openmw.storage")


require("openmw.interfaces").Settings.registerGroup({
   key = "Settings_ODAR_cat10",
   page = "ODAR_main",
   l10n = "DynamicAnimations",
   name = "settings_global_name",
   permanentStorage = true,
   settings = {
      {key = "odarEnabled",
	default = true,
	renderer = "checkbox",
	name = "settings_global_01_name",
      },
      {
         key = "npcAnimations",
         default = true,
         renderer = "checkbox",
	name = "settings_global_02_name",
      },
      {
         key = "npcWander",
         default = true,
         renderer = "checkbox",
	name = "settings_global_03_name",
	description = "settings_global_03_desc",
      },
   },
})


local presets, npcTable, allowModels = table.unpack(require("scripts.DynamicAnimations.configGlobal"))

local filters = {
	guard = { "ordinator", "crusader", "master-at-arms" }
}

for _, filter in pairs(filters) do
	for _, v in ipairs(filter) do		filter[v] = true		end
end

local paths = {
	fixBlend = "scripts.DynamicAnimations.npcBlendMask",
	replacer = "scripts.DynamicAnimations.npcAnimations",
}

local actors = {}		local teleport = { n=0 }
local npcLookup = {}
local noUpdate, player = true

local logLevel = 0
local disabled = false


local settings = storage.globalSection("Settings_ODAR_cat10")
local config = settings:asTable()

config.update = function(_, key)
	if key then
		config[key] = settings:get(key)
		print(key, config[key])
	end
	disabled = config.odarEnabled == false
	presets.odar_config = { anims = config.npcAnimations, move = config.npcWander }
end

config.update()
settings:subscribe(async:callback(config.update))


local function debug(m, level)
	if logLevel >= (level or 1) then print(m)		end
end

local function tableCopy(from, to)
	for k, v in pairs(from) do	to[k] = v	end
end

local function getFaction(o)
	local f = types.NPC.getFactions(o)
	return f[1] ~= nil and f[1] or ""
end

local function getAnimOverride(model)
	local i, j = string.find(model, "/[^/]*$")
	return i and allowedModels[string.sub(model, i+1, j)] or npcTable.odar_ignore
end

local function initStaticActor(o, swaps)
	local t = swaps.settings.teleport
	if t and o.enabled and o.count > 0 and (o.position - t):length() < 128 then
		print(o.enabled, o:isValid(), o.count)
		swaps.odar_ignore = true
		table.insert(teleport, {object=o, position=t, cell=o.cell})
		teleport.n = #teleport
		noUpdate = false
	end
end

local function getSwapByTags(o)
	local npc = { odar_config = presets.odar_config }
	local id = o.recordId
	local rec = types.NPC.records[id]	npcLookup[id] = npc
	if string.find(rec.name:lower(), "mannequin") then
		npc.odar_ignore = true
		return npc
	end
	if npcTable[id] then
		tableCopy(npcTable[id], npc)
		npc.odar_custom = true
	else
		tableCopy(allowedModels[rec.model] or npcTable.odar_ignore, npc)
	end
	if npc.odar_custom then		return npc		end

	if rec.isMale then
		tableCopy(presets.odar_male, npc)
		debug("MALE DEFAULT")
	end

	local class = rec.class			local guard = false
	if rec.id:find("imperial guard") then
		tableCopy(npcTable["odar_guard_imp"], npc)
		guard = true
	elseif class:find("guard") or filters.guard[class] then
		tableCopy(npcTable["odar_guard"], npc)
		guard = true
	elseif getFaction(o) == "imperial legion" and (class:find("warrior") or class:find("battle")) then
		tableCopy(npcTable["odar_guard_imp"], npc)
		guard = true
	end

	if not rec.isMale then
		if rec.class:find("noble") or rec.class:find("merchant") or rec.race == "high elf" then
			tableCopy(presets.odar_noble_f, npc)
		else
			tableCopy(presets.odar_female, npc)
			debug("FEMALE DEFAULT")
		end
	end
	if npc.animKna then
		npc.walkforward_05 = presets.kna05
		npc.walkforward_07 = presets.kna07
		npc.odar_wander = presets.kna
		if npc.idle2 then		npc.idle2.interval = 15			end
		npc.idle = npc.idle or {}	tableCopy(presets.halfSpeed, npc.idle)
	elseif rec.isMale then
		npc.walkforward_05 = npc.walkforward_05 or presets.m05
		npc.walkforward_07 = (guard and presets.march_m07) or npc.walkforward_07 or presets.m07
		npc.odar_wander = guard and presets.march_m or npc.odar_wander or presets.m
	else
		npc.walkforward_05 = npc.walkforward_05 or presets.f05
		npc.walkforward_07 = (guard and presets.march_f07) or npc.walkforward_07 or presets.f07
		npc.odar_wander = guard and presets.march_f or npc.odar_wander or presets.f
	end
	npc.odar_wander.maxSpeed = npc.odar_wander.maxSpeed or (guard and 0.9) or 0.7

--	print("New ODAR entry "..rec.id)
	return npc
end

local function addModule(o, script)
	local a = actors[o.id]		if not a then a = {}	actors[o.id] = a	end
	if not a.scripts then a.scripts = {}		end
	if not a[script] then
		debug(script.." script added")
		table.insert(a.scripts, paths[script])
		a[script] = true
	end
end

local function onActorActive(o)
	if disabled or not types.NPC.objectIsInstance(o) then
		return
	end
	if types.Actor.isDead(o) then			return		end
	local swaps = npcLookup[o.recordId] or getSwapByTags(o)
	if swaps.settings then		initStaticActor(o, swaps)	end
	if swaps.odar_ignore then			return		end

	if actors[o.id] then
		o:sendEvent("odarAddScript", actors[o.id].scripts)
		return
	end

	if next(swaps) then
		addModule(o, "replacer")
		actors[o.id].scripts.initData = swaps
	end
	local rec = types.NPC.records[o.recordId]
	if not rec.isMale and not types.NPC.races.record(rec.race).isBeast then
		addModule(o, "fixBlend")
	end
	o:sendEvent("odarAddScript", actors[o.id].scripts)
end

local timer = 5

local function onUpdate(dt)
	if dt == 0 or noUpdate then		return		end
	for i = teleport.n, 1, -1 do
		local o = teleport[i].object
		if not o.enabled or o.count == 0 then
			table.remove(teleport, i)
			teleport.n = #teleport
			print("INVALID: HELD ACTOR", o.enabled, o:isValid(), o.count)
			timer = -1
		else
			o:teleport(o.cell, teleport[i].position)
		end
	end
	timer = timer - dt	if timer > 0 then	return		end
	timer = 4 + math.random(200) / 100

	local active = {}
	for _, v in ipairs(world.activeActors) do active[v.id] = true		end
	for i = #teleport, 1, -1 do
		local o = teleport[i].object
		if not active[o.id] then
			table.remove(teleport, i)
			print("INACTIVE: HELD ACTOR")
		end
	end
	teleport.n = #teleport
	if teleport.n == 0 then
		noUpdate = true
		print("CLEARED STATIC-ACTOR LIST")
	end
end

return {
	engineHandlers = {
		onActorActive = onActorActive,
		onUpdate = onUpdate,
		onPlayerAdded = function(o) player = o		end
	},
	eventHandlers = {
		sendSwaps = function(o)
			if o then onActorActive(o)		end
		end,
		odar_StaticActor = function(e)
			if e.remove then
				for i = #teleport, 1, -1 do
					if teleport[i].object == e.object then
						table.remove(teleport, i)
					end
				end
			else
				table.insert(teleport, {object=e.object, position=e.position})
				noUpdate = false
			end
		end
	},
	interfaceName = "ODAR",
	interface = {
		version = 100,
		rescanActors = function(o)
			if o then
				onActorActive(o)
			else
				for _, v in ipairs(world.activeActors) do onActorActive(v)		end
			end
		end,
		rebootAI = function(o)
			if o then
				o:sendEvent("odarEvent", { event="rebootAI" })
			else
				for _, v in ipairs(world.activeActors) do
				--	if actors[v.id] then
						v:sendEvent("odarEvent", { event="rebootAI" })
				--	end
				end
			end
		end,
		enabled = function(f, o)
			f = not (f == false)
			if o then
				o:sendEvent("odarEnabled", f)
			else
				local n = 0
				disabled = not f
				for _, v in ipairs(world.activeActors) do
					if v.type == types.NPC then
						v:sendEvent("odarEnabled", f)
						n = n + 1
					end
				end
				print("ODAR "..(f and "enabled" or "disabled"), n, "actors")
			end
		end,
		staticActor = function(e)
			if e.remove then
				for i = #teleport, 1, -1 do
					if teleport[i].object == e.object then
						table.remove(teleport, i)
					end
				end
			else
				table.insert(teleport, {object=e.object, position=e.position})
				noUpdate = false
			end
			teleport.n = #teleport
		end,
		logLevel = function(m)		logLevel = m		end,
--[[
		showSwaps = function()		return npcLookup	end,
		showPresets = function()	return presets		end,
		showConfig = function()		return config		end
--]]
	}
}

