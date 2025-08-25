local Class = require("Candle Smoke.Class")
local util = require("Candle Smoke.util")


local log = mwse.Logger.new()
local BASEPATH = "e\\taitech\\candlesmoke_%d.nif"
local OFFSET = tes3vector3.new(0, 0, -2)
local parentNodeName = {
	["RedCandleFlame Emitter"] = true,
	["BlueCandleFlame Emitter"] = true,
	["CandleFlame Emitter"] = true
}

-- A cache of loaded smoke effect meshes
--- @type table<string, niNode>
local loadedEffect = {}


---@class candleSmoke.EffectManager
---@field activeEffects table<tes3reference, niNode[]>
---@field phase integer
local EffectManager = Class:new()

--- @return candleSmoke.EffectManager
function EffectManager:new()
	local t = Class:new()
	setmetatable(t, self)

	t.activeEffects = {}
	t.phase = 1

	self.__index = self
	return t
end

--- Used to keep track of which smoke asset (of the 3 available) to spawn.
---@private
---@return integer newPhase
function EffectManager:incrementPhase()
	self.phase = self.phase + 1
	if self.phase > 3 then
		self.phase = 1
	end
	return self.phase
end

---@param color mwseColorTable
function EffectManager:updateEffectMaterial(color)
	-- Update the color of the already spawned vfx.
	for light, effects in pairs(self.activeEffects) do
		for _, effect in ipairs(effects) do
			util.updateNodeEmissive(effect, color)
		end
		util.updateNode(light.sceneNode)
	end

	-- Update the color of the loaded vfx.
	for _, effect in pairs(loadedEffect) do
		util.updateNodeEmissive(effect, color)
	end
end

---@private
---@param light tes3reference
function EffectManager:spawnVFX(light)
	for node in table.traverse({ light.sceneNode }) do
		if parentNodeName[node.name] then
			local path = string.format(BASEPATH, self:incrementPhase())
			local effect = loadedEffect[path]
			if not effect then
				loadedEffect[path] = tes3.loadMesh(path) --[[@as niNode]]
				effect = loadedEffect[path]
				effect.name = path
				-- Update loaded emissive color to the currently selected value.
				util.updateNodeEmissive(effect, util.getEmissiveColorFromConfig())
			end
			effect = effect:clone() --[[@as niNode]]
			effect.translation = OFFSET:copy()
			node:attachChild(effect)
			if not self.activeEffects[light] then
				self.activeEffects[light] = {}
			end
			table.insert(self.activeEffects[light], effect)
		end
	end
	util.updateNode(light.sceneNode)
end

---@param reference tes3reference
---@return boolean spawnedSmoke
function EffectManager:applyCandleSmokeEffect(reference)
	if not util.isLanternValid(reference) then
		return false
	end

	-- Don't apply the effect twice.
	if self.activeEffects[reference] then
		return false
	end

	self:spawnVFX(reference)
	return true
end

function EffectManager:applySmokeOnAllCandles()
	for _, light in ipairs(util.getLights()) do
		self:applyCandleSmokeEffect(light)
	end
end


---@param light tes3reference
function EffectManager:detachSmokeEffect(light)
	local effects = self.activeEffects[light]
	if not effects then return end
	log:debug("Detaching smoke from: %q.", light.id)
	for _, effect in ipairs(effects) do
		effect.parent:detachChild(effect)
	end
	util.updateNode(light.sceneNode)
	self.activeEffects[light] = nil
end

return EffectManager
