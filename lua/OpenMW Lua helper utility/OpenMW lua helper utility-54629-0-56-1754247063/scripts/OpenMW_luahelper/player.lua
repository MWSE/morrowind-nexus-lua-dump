local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local camera = require("openmw.camera")
local nearby = require("openmw.nearby")
local util = require("openmw.util")

local dialogModes = {
	Barter = true,
	Companion = true,
	Dialogue = true,
	Enchanting = true,
	MerchantRepair = true,
	Travel = true,
	Training = true,
	SpellBuying = true,
	SpellCreation = true,
	Persuasion = true,
		}

local dialogTarget = nil
local dialogNearby = false
local maxDist = core.getGMST("iMaxActivateDist")

local eventHandlers = {
	playerTargetChanged = {}, activationTargetChanged = {}, viewSwitch = {},
	onFrame20 = {}, equipped = {}, unequipped = {}, updateInventory = {}
}

local function objectsNearby(k, v)
	local valid = false
	if k.cell.isExterior then valid = (k.position - v.position):length() < 7000
	else valid = k.cell == v.cell end
	return valid
end

local function UiModeChanged(data)
	if dialogModes[data.newMode] and not dialogModes[data.oldMode] and data.arg and dialogTarget ~= data.arg then
		if data.arg ~= nil then
			if objectsNearby(self, data.arg) then dialogNearby = true else dialogNearby = false end
			data["near"], data["player"] = dialogNearby, self
			core.sendGlobalEvent("onDialogOpened", data)
			self:sendEvent("onDialogOpened", data)
			dialogTarget = data.arg
		end
--	elseif dialogModes[data.oldMode] and not dialogModes[data.newMode] and dialogTarget ~= data.arg then
	elseif data.newMode == nil and dialogTarget then
		data["near"] = dialogNearby
		core.sendGlobalEvent("onDialogClosed", data)
		self:sendEvent("onDialogClosed", data)
		dialogTarget = nil
		dialogNearby = false
	end
end

local timer = 0		local counter = 0
local interop = { rayCast={}, activation={ hit=false } }
local equipped = types.Actor.getEquipment(self)
local encumbrance = types.Actor.getEncumbrance(self)	local invCount = 0
local playerTarget

local equipSlots = {}
for _, v in pairs(types.Actor.EQUIPMENT_SLOT) do
	equipSlots[#equipSlots + 1] = v
end

local function onFrame20(dt)
	for _, v in ipairs(eventHandlers.onFrame20) do	v()	end
	local eq = types.Actor.getEquipment(self)	local e = equipped
	for _, v in ipairs(equipSlots) do
		if e[v] ~= eq[v] then
			if e[v] then
--			print("UNEQUIPPED")
				for _, f in ipairs(eventHandlers.unequipped) do	f(e[v], v)	end
			end
			if eq[v] then
--			print("EQUIPPED")
				for _, f in ipairs(eventHandlers.equipped) do	f(eq[v], v)	end
			end
			e[v] = eq[v]
		end
	end
	if encumbrance ~= types.Actor.getEncumbrance(self) then
		encumbrance = types.Actor.getEncumbrance(self)
		local i = types.Actor.inventory(self):getAll()
		if #i ~= invCount then
--			print("INVENTORY", #i)
			invCount = #i
			for _, f in ipairs(eventHandlers.updateInventory) do	f()		end
		end
	end
end

local function onFrame(dt)
	if dialogTarget then
		if dt == 0 and core.API_REVISION < 88 then
			core.sendGlobalEvent("olh_onFrame")
		end
	end
	if counter > 20 then onFrame20(dt)	counter = 0		end
	counter = counter + 1
	timer = timer + dt	if timer < 0.1 then return	end		timer = 0

	local vec = camera.viewportToWorldVector(util.vector2(0.5,0.5))
	local from = camera.getPosition() + vec * camera.getThirdPersonDistance()
	local d = 400			local to = from + vec * d
	local res = nearby.castRenderingRay(from, to, {ignore=self})
	interop.rayCast = res	local h = res.hitPos	local d, a = 400
	if h then d = (h - from):length()		end
	if not h or d > maxDist then
		a = { hit=false }
	else
		a = { hit=true, hitNormal=res.hitNormal, hitObject=res.hitObject,
			hitPos=h, hitDist=d }
	end
	interop.activate = a

	if a.hitObject == playerTarget then return		end
	local o = a.hitObject		playerTarget = o
	for _, v in ipairs(eventHandlers.playerTargetChanged) do	v(o)	end
end

local camMode, camSwitch = camera.getMode()

local function onUpdate(dt)
	if dt == 0 then return		end
	if camSwitch then
		for _, v in ipairs(eventHandlers.viewSwitch) do v(mode, camSwitch)	end
		camSwitch = false
	end
	if camMode == camera.getMode() then return	end
	local first, mode = camera.MODE.FirstPerson, camera.getMode()
	if mode == first or camMode == first then
		camSwitch = true
	end
	camMode = mode
end

self:sendEvent("olhInitialized")

return {
	engineHandlers = { onFrame = onFrame, onUpdate = onUpdate },
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		showMessage = function(e) ui.showMessage(e) end,
		olhInitialized = function()
			print("OpenMW lua helper v0.56 Player script initialized.")
		end
	},
	interfaceName = "luaHelper",
	interface = {
		version = 56,
		eventRegister = function(e, f)
			local h = eventHandlers[e]
			if not h then h = {}	eventHandlers[e] = h		end
			h[#h + 1] = f
		end,
		interop = interop,
		interopTable = function() return interop	end,
		getCache = function() return interop	end
	}
}
