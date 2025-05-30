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

local cam = camera.getMode()		local devMode = false

local equipped = {}
local items = { default = "meshes/c/c_ring_common05_skins.nif" }

local L = {
	bbody = { first="BB", third="BB" },
	rbody = { first="RB", third="RB" },
	vbody = { first="VB", third="VS" },
	vsbr = { first="VS", third="VS" },
	slim = { first="50", third="45" },
	glove = { first="50", third="50" },
	mid55 = { first="60", third="55" },
	mid60 = { first="60", third="60" },
	wide = { first="70", third="60" },
	wide70 = { first="70", third="70" },
}

local offset = {

	bareHands = { first="50", third="50" },
	["bm bear left gauntlet"] = L.mid55,
	["bm bear right gauntlet"] = L.mid55,
	bm_ice_gauntletl = L.slim,
	bm_ice_gauntletr = L.slim,
	bm_nordicmail_gauntletl = L.slim,
	bm_nordicmail_gauntletr = L.slim,
	["bm wolf left gauntlet"] = L.mid60,
	["bm wolf right gauntlet"] = L.mid60,

	["chitin guantlet - left"] = L.glove,
	["chitin guantlet - right"] = L.glove,
		["bonedancer gauntlet"] = L.glove,
		["boneweave gauntlet"] = L.glove,
		["left gauntlet of the horny fist"] = L.glove,
		["right gauntlet of the horny fist"] = L.glove,

	["darkBrotherhood gauntlet_l"] = L.mid55,
	["darkBrotherhood gauntlet_r"] = L.mid55,

	fur_gauntlet_left = L.wide70,
	fur_gauntlet_right = L.wide70,
		gauntlet_of_glory_left = L.wide70,
		gauntlet_of_glory_right = L.wide70,

	Helsethguard_gauntlet_left = L.mid55,
	Helsethguard_gauntlet_right = L.mid55,
	["imperial left gauntlet"] = L.glove,
	["imperial right gauntlet"] = L.glove,
	iron_gauntlet_left = L.mid55,
	iron_gauntlet_right = L.mid55,
	["indoril left gauntlet"] = L.mid55,
	["indoril right gauntlet"] = L.mid55,
	indoril_mh_guard_gauntlet_l = L.mid55,
	indoril_mh_guard_gauntlet_r = L.mid55,
	indoril_almalexia_gauntlet_l = L.mid55,
	indoril_almalexia_gauntlet_r = L.mid55,

	netch_leather_gauntlet_left = L.glove,
	netch_leather_gauntlet_right = L.glove,
		gauntlet_horny_fist_l = L.glove,
		gauntlet_horny_fist_r = L.glove,

	steel_gauntlet_left = L.wide,
	steel_gauntlet_right = L.wide,

}

for k, v in pairs(L) do offset[k] = v		end

L = {
	fallback = {
		{ "brace", offset.bareHands },
		{ "chitin", offset.glove },
		{ "netch", offset.glove },
		{ "daedric", offset.glove },
		{ "guardtown1", offset.mid55 },
		{ "iron", offset.mid55 },
		{ "steel", offset.wide },
		{ "glove", offset.glove },
--		{ "helsethguard", offset.mid55 },
--		{ "bear", offset.mid55 },
--		{ "wolf", offset.mid60 },
--		{ "_ice_", offset.slim },
--		{ "nordicmail", offset.slim },
--		{ "imperial", offset.glove },
--		{ "indoril", offset.mid55 },
	},

	uiModes = { [I.UI.MODE.Rest] = true, [I.UI.MODE.Training] = true, [I.UI.MODE.Travel] = true },
	vfxItem = {loop=true, useAmbientLight=false, vfxId="visibleItems"},
}

L.getGlove = function(o)
	local sizes
	if o.type ~= types.Armor then
		if devMode then print("NOT ARMOR")	end
		sizes = offset.glove
		offset[o.recordId] = sizes		return sizes
	end
	for _, v in ipairs(L.fallback) do
		local i, j = table.unpack(v)
		if o.recordId:find(i) then sizes = j	break		end
	end
	if not sizes then sizes = offset.glove	end
	offset[o.recordId] = sizes
--	for k, v in pairs(sizes) do print(k,v) end
	return sizes
end

L.getItem = function(o)
	local id = o.recordId		local model = o.type.records[id].model:lower()
	model = model:gsub("_gnd%.nif$", ".nif")
	model = model:gsub("%.nif$", "_skins.nif")
	if not vfs.fileExists(model) then
		if devMode then print("No visible model for "..model)		end
		model = ""
	end
--	print(model)
	items[id] = model	return model
end

local function debug(m)
	if devMode then		print(m)	ui.showMessage(m)	end
end

local settings = storage.playerSection("Settings_tt_visiblerings")
local frameSkip, onlyHands
local counter, refresh

local function updateSettings()
	frameSkip = settings:get("frameSkip") or 20
	onlyHands = settings:get("bareHandsOnly")
	local model = settings:get("defaultModel")
	if type(model) == "string" and vfs.fileExists(model) then
		L.defaultModel = model
	else
		L.defaultModel = nil
	end
	local b, rec = types.NPC.records[self.recordId].isMale and settings:get("bodyReplacer")
		or settings:get("bodyReplacer_f")
	if b == "opt_better" then
		rec = offset.bbody
	elseif b == "opt_robert" then
		rec = offset.rbody
	elseif b =="opt_vsbr" then
		rec = offset.vsbr
	else
		rec = offset.vbody
	end
	offset.bareHands.first = rec.first
	offset.bareHands.third = rec.third
	counter = math.random(3, 20)		refresh = true
end

settings:subscribe(async:callback(updateSettings))
updateSettings()


local function addRingVfx(o, bone, hand)
	local model = items[o.recordId] or L.getItem(o)
	if model == "" then
		if devMode then print(model, "USE DEFAULT")		end
		model = L.defaultModel
		if not model then	return		end
	end
	local id = hand and hand.recordId or "bareHands"
	local sizes = offset[id] or L.getGlove(hand)
	if onlyHands and sizes ~= offset.bareHands then		return		end
	local view = (cam == MD.first and "first") or "third"
	if devMode then print(sizes[view], id)			end
--	print(id, cam, MD.first, view, sizes[view])
	debug(model.." add ring vfx")
	bone = bone .. " " .. sizes[view]
	L.vfxItem.boneName = bone		anim.addVfx(self, model, L.vfxItem)
end

local scanSlots = { Actor.EQUIPMENT_SLOT.LeftRing,
	Actor.EQUIPMENT_SLOT.RightRing,
	Actor.EQUIPMENT_SLOT.LeftGauntlet,
	Actor.EQUIPMENT_SLOT.RightGauntlet,
	Actor.EQUIPMENT_SLOT.Helmet,
	}

local newEquip = false

local function scanInv(reset)
	newEquip = false		refresh = false
	local e, f = Actor.getEquipment(self)		local eq = equipped
	for _, v in ipairs(scanSlots) do
		if eq[v] ~= e[v] then f = true	eq[v] = e[v]		end
	end
	if not f and not reset then return		end
	debug("remove items vfx")
	anim.removeVfx(self, "visibleItems")
	local l, r, lG, rG, h = table.unpack(scanSlots)
	if eq[l] then addRingVfx(eq[l], "Ring L Finger1", eq[lG])		end
	if eq[r] then addRingVfx(eq[r], "Ring R Finger1", eq[rG])		end
	if cam == MD.first then		return		end
	local m = eq[h]
	if m then
		m = items[m.recordId] or L.getItem(m)
		if m ~= "" then
			L.vfxItem.boneName = "Head"		anim.addVfx(self, m, L.vfxItem)
		end
	end
end

local useHelper = false

local function onFrame(dt)
	if newEquip then scanInv(refresh)		end
	counter = counter - 1		if counter > 0 then return end		counter = frameSkip
	if refresh or not useHelper then	scanInv(refresh)	end
end

local function onUpdate(dt)
	if dt == 0 then return				end
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
			if L.uiModes[e.oldMode] then
				counter = 3	 	refresh = true
			end
		end,
		olhInitialized = function()
			if frameSkip ~= 20 then		return		end
			useHelper = true
			I.luaHelper.eventRegister("equipped", function() newEquip = true	end)
			I.luaHelper.eventRegister("unequipped", function() newEquip = true	end)
		end,
		vfxRemoveAll = function() counter = 3		refresh = true		end
	},
}
