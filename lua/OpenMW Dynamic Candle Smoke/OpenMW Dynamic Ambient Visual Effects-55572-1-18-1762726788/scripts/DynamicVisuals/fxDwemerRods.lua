local common = common
local types = common.openmw.types
local core = common.openmw.core
local util = common.openmw.util
local world = common.openmw.world

local v3 = util.vector3			local player = common.player

local vectors = { ex_dwrv_steamstack00 = v3(-128, 0, 1536) }
local lightning = {}

local noRods = true
local activator, static = types.Activator, types.Static

local debug = common.debug


local self = {}

function self.onPlayerAdded(e)	player = e		end

function self.onObjectActive(o)
	if not vectors[o.recordId] then	return		end
	if not o.cell.isExterior and not o.cell:hasTag("QuasiExterior") then	return		end

	for _, v in ipairs(lightning) do
		if v.ref == o then		return		end
	end

	local _, y, x = o.rotation:getAnglesZYX()
	if math.abs(y) > 0.44 or math.abs(x) > 0.44 then	return		end

	local new = { ref=o, timer = math.random(2, 7),
		pos=o.rotation:apply(vectors[o.recordId]) * o.scale + o.position,
		xyPos = util.vector2(o.position.x, o.position.y)
		}
	if o.cell.isExterior then
		new.x = o.cell.gridX	new.y = o.cell.gridY
	end
	lightning[#lightning + 1] = new
	noRods = false
--	print(o.position, lightning[#lightning].pos)
	debug(o.recordId.." "..#lightning)

end

function self.clearVfx()	lightning = {}		end

local phase = 1

function self.onUpdate(dt)
	if noRods then		return		end
	if not next(lightning) then
		debug("VFX CLEARED")
		noRods = true			return
	end

	local c = common
	if (c.weather < 5 or c.weather > 7) then
		if c.dwemOption == 2 or not c.isNight then
			return
		end
	end
	local cell = player.cell
--	local pos = player.position
--	local xy = util.vector2(pos.x, pos.y)
	local xy = common.posXY
	local ch = c.dwemChance

	for i = #lightning, 1, -1 do
		local v = lightning[i]		local o, inactive = v.ref	v.timer = v.timer - dt
		local d = (v.xyPos - xy):length()
		if v.x and cell.isExterior then
			if (math.abs(v.x - cell.gridX) > 1 or math.abs(v.y - cell.gridY) > 1)
			and d > 14000 then
				debug("INACTIVE "..d)
				inactive = true
			end
		elseif not cell:isInSameSpace(o) then
			inactive = true
		end

		if inactive then
			table.remove(lightning, i)
			debug("REMOVED")
		elseif v.timer < 1 and d < 14000 and math.random(100) < ch then
			c.doStrike = true
			world.vfx.spawn("meshes/e/taitech/lightning_"..phase..".nif", v.pos, { useAmbientLight=false })
			phase = phase + 1	if phase > 3 then phase = 1		end
		end
		if v.timer < 1 then v.timer = math.random(4, 10)	end
	end

end


return self
