local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local anim = require("openmw.animation")
local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local camera = require("openmw.camera")
local vfs = require("openmw.vfs")
local storage = require("openmw.storage")

local Actor, ctrls, ST = types.Actor, self.controls, types.Actor.STANCE
local MD = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local cam = camera.getMode()		local debug = false

local equipped = {}
local rings = { default = "meshes/c/c_ring_common05_skins.nif" }

local records = {

	rbody = { first="50", third="RB" },
	slim = { first="50", third="45" },
	glove = { first="50", third="50" },
	mid55 = { first="60", third="55" },
	mid60 = { first="60", third="60" },
	wide = { first="70", third="60" },
	fur_gauntlet_left = { first="70", third="70" },
	fur_gauntlet_right = { first="70", third="70" },
	indoril_mh_guard_gauntlet_l = { first="60", third="55" },
	indoril_mh_guard_gauntlet_r = { first="60", third="55" },
	indoril_almalexia_gauntlet_l = { first="60", third="55" },
	indoril_almalexia_gauntlet_r = { first="60", third="55" },
	}

local L = {
	fallback = {
		{ "bracer", records.rbody },
		{ "chitin", records.glove },
		{ "netch", records.glove },
		{ "daedric", records.glove },
		{ "darkbrotherhood", records.mid55 },
		{ "helsethguard", records.mid55 },
		{ "bear", records.mid55 },
		{ "wolf", records.mid60 },
		{ "_ice_", records.slim },
		{ "nordicmail", records.slim },
		{ "imperial", records.glove },
		{ "indoril", records.mid55 },
		{ "iron", records.mid55 },
		{ "steel", records.wide },
	},

	uiModes = { [I.UI.MODE.Rest] = true, [I.UI.MODE.Training] = true, [I.UI.MODE.Travel] = true }

}

L.getGlove = function(o)
	local sizes
	if o.type ~= types.Armor then
		if debug then print("NOT ARMOR")	end
		sizes = records.glove
		records[o.recordId] = sizes		return sizes
	end
	for _, v in ipairs(L.fallback) do
		local i, j = table.unpack(v)
		if o.recordId:find(i) then sizes = j	break		end
	end
	if not sizes then sizes = records.glove	end
	records[o.recordId] = sizes
--	for k, v in pairs(sizes) do print(k,v) end
	if debug then local view = cam == MD.first and "first" or "third"  print(sizes[view], o)	end
	return sizes
end

L.getRing = function(o)
	local id = o.recordId	local model = o.type.records[id].model:gsub(".nif$", "_skins.nif")
	if not vfs.fileExists(model) then
		if debug then print(model, "NO SKINS")		end
		model = ""
	end
--	print(model)
	rings[o.recordId] = model	return model
end

L.debug = function(m) print(m)	ui.showMessage(m)	end

local settings = storage.playerSection("Settings_tt_visiblerings")
local frameSkip = 20

local function updateSettings()
	frameSkip = settings:get("frameSkip")
	local model = settings:get("defaultModel")
	if type(model) == "string" and vfs.fileExists(model) then
		L.defaultModel = model
	else
		L.defaultModel = nil
	end
end

settings:subscribe(async:callback(updateSettings))
updateSettings()


local function addRingVfx(o, bone, hand)
	local model = rings[o.recordId] or L.getRing(o)
	if model == "" then
		if debug then print(model, "USE DEFAULT")		end
		model = L.defaultModel
		if not model then return	end
	end
	local id = hand and hand.recordId or "rbody"
	local sizes = records[id] or L.getGlove(hand)
	local view = (cam == MD.first and "first") or "third"
--	print(id, cam, MD.first, view, sizes[view])
	bone = bone .. " " .. sizes[view]
	if debug then L.debug(model.." add ring vfx")		end
	anim.addVfx(self, model, {boneName=bone, loop=true, vfxId="visibleItems"})
end

local scanSlots = { Actor.EQUIPMENT_SLOT.LeftRing,
	Actor.EQUIPMENT_SLOT.RightRing,
	Actor.EQUIPMENT_SLOT.LeftGauntlet,
	Actor.EQUIPMENT_SLOT.RightGauntlet,
	}

local function scanInv(force)
	local e, f = Actor.getEquipment(self)		local eq = equipped
	for _, v in ipairs(scanSlots) do
		if eq[v] ~= e[v] then f = true	eq[v] = e[v]		end
	end
	if not f and not force then return		end
	if debug then L.debug("remove rings vfx")	end
	anim.removeVfx(self, "visibleItems")
	local l, r, lG, rG = table.unpack(scanSlots)
	if eq[l] then addRingVfx(eq[l], "Ring L Finger1", eq[lG])		end
	if eq[r] then addRingVfx(eq[r], "Ring R Finger1", eq[rG])		end
end

local counter  = frameSkip	local refresh = false

local function onFrame(dt)
	counter = counter - 1
	if counter > 0 then return end
	counter = frameSkip
	scanInv(refresh)	refresh = false
end

local function onUpdate()
	if cam == camera.getMode() then return		end
	local mode, fp = camera.getMode(), MD.first
	if mode == fp or cam == fp then
		cam = mode	counter = 3 	refresh = true
	end
	cam = mode
end


return {
	engineHandlers = { onUpdate = onUpdate, onFrame = onFrame },
	eventHandlers = { UiModeChanged = function(e)
			if L.uiModes[e.oldMode] then counter = 3 	refresh = true		end
		end
	},
}
