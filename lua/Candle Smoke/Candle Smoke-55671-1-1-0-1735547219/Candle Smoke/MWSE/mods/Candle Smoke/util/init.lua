local smokeOffset = require("Candle Smoke.data").smokeOffset


local util = {}

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
				if smokeOffset[mesh] then
					table.insert(candles, ref)
				end
			end
		end
	end
	return candles
end

function util.updateVFXRoot()
	local root = tes3.worldController.vfxManager.worldVFXRoot
	root:update()
	root:updateEffects()
	root:updateProperties()
end

-- Let's strip the beginning "l\"
---@param meshPath string
function util.sanitizeMesh(meshPath)
	return string.sub(string.lower(meshPath), 3)
end

return util
