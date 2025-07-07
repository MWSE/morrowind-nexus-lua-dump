local common = common
local types = common.openmw.types
local core = common.openmw.core
local world = common.openmw.world
local util = common.openmw.util

local vectors = require("scripts.DynamicVisuals.configCandleSmoke")
local phase = 1

local self = { common = common }

local player = common.player		local devMode = false


local function addSmoke(o, candle, phase)
	local origin, position = o.position
	local multi = candle.mV		local offset = vectors.offset	local g = common.glow
	local opt = { useAmbientLight=false }
	if not multi then
		position = o.rotation:apply(candle.V * o.scale + offset) + origin
		world.vfx.spawn("meshes/e/taitech/candlesmoke"..g.."_"..phase..".nif", position, opt)
--		if devMode then print(o.recordId.." "..g)		end
		if devMode then player:sendEvent("showMessage", o.recordId.." "..g)		end
		return
	end
	phase = 1	local count = 0
	for i = 1, #multi do
		position = o.rotation:apply(multi[i] * o.scale + offset) + origin
		world.vfx.spawn("meshes/e/taitech/candlesmoke"..g.."_"..phase..".nif", position, opt)
		count = count + 1	phase = phase + 1	if phase > 3 then phase = 1	end
	end
--	if devMode then print(o.recordId.." "..g.." "..count)		end
	if devMode then player:sendEvent("showMessage", o.recordId.." "..g.." "..count)		end
end


function self.onPlayerAdded(e)
	if not e then		return			end
	player = e
end

function self.onObjectActive(o, force)
--	print(o.recordId)
	if not o.cell.isExterior and not force then		return		end
	local r = o.type.records[o.recordId]
	if r.isOffByDefault or (common.noCarry and r.isCarriable) then return		end
	local model = r.model or ""

	-- bugfix for OMW versions before Nov 19 2024
	model = model:lower()		model = string.gsub(model, "\\", "/")

	local v = vectors[model]
	if not v then
		local i, j
		i, j = string.find(model, "/[^/]*$")
		if i then model = string.sub(model, i+1, j)	v = vectors[model]	end
	end
	if v then
		addSmoke(o, v, phase)	phase = phase + 1	if phase > 3 then phase = 1	end
	end
end

function self.refreshVfx(e)
	for i = 1, #e do	self.onObjectActive(e[i], true)		end
end


return self

