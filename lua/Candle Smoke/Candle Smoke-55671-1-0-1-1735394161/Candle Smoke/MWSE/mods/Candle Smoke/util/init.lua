local smokeOffset = require("Candle Smoke.data").smokeOffset


local util = {}

function util.getLights()
	---@type tes3reference[]
	local candles = {}
	for _, cell in ipairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences() do
			local object = ref.object
			if object.objectType == tes3.objectType.light and not object.isOffByDefault then
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
