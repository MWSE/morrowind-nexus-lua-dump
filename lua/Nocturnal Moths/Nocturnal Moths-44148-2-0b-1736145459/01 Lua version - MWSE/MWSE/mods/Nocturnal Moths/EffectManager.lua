local log = require("logging.logger").getLogger("Nocturnal Moths") --[[@as mwseLogger]]

local Class = require("Nocturnal Moths.Class")
local config = require("Nocturnal Moths.config")
local lanterns = require("Nocturnal Moths.data")
local util = require("Nocturnal Moths.util")


local attachNodeName = "AttachLight"
local path = "R0\\e\\moths_lntrn.NIF"


-- In seconds
local updateDuration = 15

---@class NocturnalMoths.EffectManager.UpdateState
---@field isNiceWeather boolean True if the weather was nice on last update
---@field isNight boolean True if it was night during the last update

---@class NocturnalMoths.EffectManager
---@field activeEffects table<tes3reference, niNode> A table of lanterns with attached moths effect
---@field nextUpdateTimestamp number In seconds
---@field lastUpdateState NocturnalMoths.EffectManager.UpdateState
local EffectManager = Class:new()

--- @return NocturnalMoths.EffectManager
function EffectManager:new()
	local t = Class:new()
	setmetatable(t, self)

	t.activeEffects = {}
	t.nextUpdateTimestamp = -1
	t.lastUpdateState = {}

	self.__index = self
	return t
end


-- Sets appCulled state of moths node on given reference.
-- Will also play/stop moths sound.
---@private
---@param reference tes3reference
---@param culled boolean
function EffectManager:setMothsAppCulled(reference, culled)
	local mothsNode = self.activeEffects[reference]
	if not mothsNode then return end
	mothsNode.appCulled = culled

	if culled then
		util.stopSound(reference)
	else
		util.playSound(reference)
	end
	util.updateNode(mothsNode.parent)
end

local offsets = {
	-- Light_De_streetlight_01.nif has no AttachLight. Other lanterns with no AttachLight like the ashlander ones etc
	-- work fine with the origin point.
	["l\\light_de_streetlight_01.nif"] = tes3vector3.new(0, 0, -23)
}

-- Attaches the moths node to light's "AttachLight" node or to worldVFXRoot if it's not found.
---@private
---@param light tes3reference
function EffectManager:spawnVFX(light)
	log:debug("Spawning vfx for %q.", light.id)

	local mesh = tes3.loadMesh(path):clone() --[[@as niNode]]
	local parent = light.sceneNode:getObjectByName(attachNodeName)
	if not parent then
		log:trace("No %s on %s. Attaching moths to light origin.", attachNodeName, light.object.mesh)
		parent = light.sceneNode
		local meshPath = string.lower(light.object.mesh)
		local offset = offsets[meshPath]
		if offset then
			mesh.translation = offset
		end
	end

	parent:attachChild(mesh)
	if util.isLightOff(light) then
		self:setMothsAppCulled(light, true)
	end
	util.updateNode(parent)
	self.activeEffects[light] = mesh
end

-- Attaches moths to given light. Does all the needed checks and also starts the moths sound.
---@param reference tes3reference
---@return boolean mothsSpawned
function EffectManager:applyMothEffect(reference)
	-- Don't apply the effect twice.
	if self.activeEffects[reference] then
		return false
	end

	local mesh = string.lower(reference.object.mesh)
	if not (lanterns[mesh] or config.whitelist[mesh]) then
		return false
	end

	util.playSound(reference)
	self:spawnVFX(reference)
	return true
end

-- Detaches moths mesh from given light.
---@param light tes3reference
function EffectManager:detachMothEffect(light)
	local effect = self.activeEffects[light]
	if not effect then return end
	log:debug("Detaching moth mesh from: %q.", light.id)
	local parent = effect.parent
	parent:detachChild(effect)
	util.updateNode(parent)
	util.stopSound(light)
	self.activeEffects[light] = nil
end

---@private
function EffectManager:cullAllMoths()
	for reference, _ in pairs(self.activeEffects) do
		self:setMothsAppCulled(reference, true)
	end
end

---@private
function EffectManager:uncullAllMoths()
	for reference, _ in pairs(self.activeEffects) do
		-- Compatibility with Midnight Oil
		if not util.isLightOff(reference) then
			self:setMothsAppCulled(reference, false)
		end
	end
end

-- Usually called on simulate event.
function EffectManager:update()
	local timestamp = tes3.getSimulationTimestamp() * 3600
	if timestamp < self.nextUpdateTimestamp then return end

	self.nextUpdateTimestamp = timestamp + updateDuration

	local isNight = util.isNight()
	local isNiceWeather = util.isNiceWeather()
	if self.lastUpdateState.isNight == isNight and self.lastUpdateState.isNiceWeather == isNiceWeather then
		return
	end

	self.lastUpdateState.isNight = isNight
	self.lastUpdateState.isNiceWeather = isNiceWeather

	if not isNight
	or not isNiceWeather then
		self:cullAllMoths()
	else
		self:uncullAllMoths()
	end
end

-- Usually called on itemDropped event.
---@param e itemDroppedEventData
function EffectManager:onItemDropped(e)
	local reference = e.reference
	local object = reference.object
	if object.objectType ~= tes3.objectType.light or object.isOffByDefault then return end
	self:applyMothEffect(reference)
end

---@private
function EffectManager:applyMothsOnAllLanterns()
	-- We only attach moths to lanterns in exterior and interiors behaving as exteriors.
	if not tes3.player.cell.isOrBehavesAsExterior then return end
	for _, light in ipairs(util.getLights()) do
		self:applyMothEffect(light)
	end
end

-- Usually called on cellChanged event.
function EffectManager:onCellChanged()
	self:applyMothsOnAllLanterns()
	if not util.isNiceWeather()
	or not util.isNight() then
		self:cullAllMoths()
	end
end

return EffectManager
