local inspect = require("inspect")
local log = require("logging.logger").getLogger("Candle Smoke") --[[@as mwseLogger]]

local Class = require("Candle Smoke.Class")
local config = require("Candle Smoke.config").config
local smokeOffset = require("Candle Smoke.data").smokeOffset
local util = require("Candle Smoke.util")


local BASEPATH = "e\\taitech\\candlesmoke%d_%d.nif"
local MAX_SMOKE_DISTANCE = 8192 * 1.5 -- Cell and a half
local OFFSET = tes3vector3.new(0, 0, -2)

-- A cache of loaded smoke effect meshes
--- @type table<string, niNode>
local smokeEffects = {}


---@class CandleSmoke.EffectManager
---@field activeEffects table<tes3reference, niNode[]>
---@field phase integer
local EffectManager = Class:new()

--- @return CandleSmoke.EffectManager
function EffectManager:new()
	local t = Class:new()
	setmetatable(t, self)

	t.activeEffects = {}
	t.phase = 1

	self.__index = self
	return t
end

---@private
---@return integer newPhase
function EffectManager:incrementPhase()
	self.phase = self.phase + 1
	if self.phase > 3 then
		self.phase = 1
	end
	return self.phase
end

---@private
---@param light tes3reference
---@param offsets tes3vector3[]
---@param updateRoot boolean?
function EffectManager:spawnSmokeVFX(light, offsets, updateRoot)
	local origin = light.position:copy()
	local root = tes3.worldController.vfxManager.worldVFXRoot

	for _, offset in ipairs(offsets) do
		local rotation = tes3matrix33.new()
		rotation:fromEulerXYZ(light.orientation.x, light.orientation.y, light.orientation.z)
		local position = rotation * (offset + OFFSET) + origin
		log:debug("Spawning vfx for %q at %s.", light.id, position)

		local path = string.format(BASEPATH, config.smokeIntensity, self:incrementPhase())
		local effect = smokeEffects[path]
		if not effect then
			smokeEffects[path] = tes3.loadMesh(path) --[[@as niNode]]
			effect = smokeEffects[path]
			effect.name = path
		end

		effect = effect:clone() --[[@as niNode]]
		effect.translation = position
		root:attachChild(effect)
		if not self.activeEffects[light] then
			self.activeEffects[light] = {}
		end
		table.insert(self.activeEffects[light], effect)
	end
	if not updateRoot then return end
	util.updateVFXRoot()
end

---@private
---@param reference tes3reference
---@param updateRoot boolean?
---@return boolean spawnedSmoke
function EffectManager:applyCandleSmokeEffect(reference, updateRoot)
	local light = reference.object --[[@as tes3light]]
	if config.disableCarriable and light.canCarry then
		return false
	end

	local mesh = util.sanitizeMesh(light.mesh)
	local offsets = smokeOffset[mesh]
	self:spawnSmokeVFX(reference, offsets, updateRoot)
	return true
end

---@private
function EffectManager:applySmokeOnAllCandles()
	for _, light in ipairs(util.getLights() or {}) do
		self:applyCandleSmokeEffect(light)
	end
	util.updateVFXRoot()
end


---@param light tes3reference
---@param updateRoot boolean?
function EffectManager:detachSmokeEffect(light, updateRoot)
	local effects = self.activeEffects[light]
	if not effects then return end
	log:debug("Detaching smoke from: %q.", light.id)
	for _, effect in ipairs(effects) do
		tes3.worldController.vfxManager.worldVFXRoot:detachChild(effect)
	end
	self.activeEffects[light] = nil
	if not updateRoot then return end
	util.updateVFXRoot()
end

---@private
function EffectManager:detachAllSmokeEffects()
	for light, _ in pairs(self.activeEffects) do
		self:detachSmokeEffect(light)
	end
	util.updateVFXRoot()
end

function EffectManager:onCellChange()
	log:trace("cellEffectsUpdate: before activeEffects = %s", inspect(self.activeEffects))
	-- New cell is an interior? It's enough to remove all the smoke from candles
	-- in the previous cell and apply smoke to candles in this cell.
	if tes3.player.cell.isInterior then
		self:detachAllSmokeEffects()
	else
		-- When transitioning exterior -> exterior cell, we disable smoke effect based on distance.
		for light, _ in pairs(self.activeEffects) do
			if light.position:distanceXY(tes3.player.position) > MAX_SMOKE_DISTANCE then
				self:detachSmokeEffect(light)
			end
		end
	end

	self:applySmokeOnAllCandles()
	util.updateVFXRoot()

	log:trace("cellEffectsUpdate: after activeEffects = %s", inspect(self.activeEffects))
end

-- Apply smoke effect if the player dropped a candle
---@param e itemDroppedEventData
function EffectManager:onItemDropped(e)
	local ref = e.reference
	local object = ref.object
	if object.objectType ~= tes3.objectType.light then return end
	self:applyCandleSmokeEffect(ref, true)
end

return EffectManager
