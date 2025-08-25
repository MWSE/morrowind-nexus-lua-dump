local config = require("Candle Smoke.config")
local supported = require("Candle Smoke.data").supported

local util = {}

---@return mwseColorTable
function util.getEmissiveColorFromConfig()
	return {
		r = config.intensity,
		g = config.intensity,
		b = config.intensity
	}
end

---@param node niNode
function util.updateNode(node)
	node:update()
	node:updateEffects()
	node:updateProperties()
end

---@param node niNode
---@param color mwseColorTable
function util.updateNodeEmissive(node, color)
	---@param object niNode|niTriShape
	for object in table.traverse({ node }) do
		if object:isInstanceOfType(ni.type.NiTriShape) then
			---@cast object niTriShape
			local material = object.materialProperty
			material.emissive = niColor.new(color.r, color.g, color.b)
		end
	end
end

-- Let's strip the beginning "l\"
---@param meshPath string
function util.sanitizeMesh(meshPath)
	return string.sub(string.lower(meshPath), 3)
end

-- Compatibility with Midnight Oil
---@param reference tes3reference
function util.isLightOff(reference)
	return reference.supportsLuaData and reference.data.lightTurnedOff
end

---@param ref tes3reference
function util.isLanternValid(ref)
	-- Make sure not to include disabled/deleted lights. These frequently
	-- result from light toggling on/off with Midnight Oil.
	if ref.disabled or ref.deleted then
		return false
	end

	local light = ref.object
	if light.objectType ~= tes3.objectType.light then
		return false
	end
	---@cast light tes3light
	if config.disableCarriable and light.canCarry then
		return false
	end

	if light.isOffByDefault then
		return false
	end

	-- Compatibility with Midnight Oil
	if util.isLightOff(ref) then
		return false
	end

	local mesh = util.sanitizeMesh(light.mesh)
	if not supported[mesh] then
		return false
	end

	return true
end

function util.getLights()
	---@type tes3reference[]
	local candles = {}
	for _, cell in ipairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences() do
			local object = ref.object

			-- Make sure not to include disabled/deleted lights. These frequently
			-- result from light toggling on/off with Midnight Oil.
			if object.objectType == tes3.objectType.light and not object.isOffByDefault
				and not ref.disabled and not ref.deleted then
				local mesh = util.sanitizeMesh(object.mesh)
				if supported[mesh] then
					table.insert(candles, ref)
				end
			end
		end
	end
	return candles
end

return util
