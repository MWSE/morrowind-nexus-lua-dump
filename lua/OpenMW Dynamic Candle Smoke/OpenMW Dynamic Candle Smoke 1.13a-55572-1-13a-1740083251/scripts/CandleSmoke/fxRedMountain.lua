local common = common
local types = common.openmw.types
local core = common.openmw.core
local util = common.openmw.util
local world = common.openmw.world

local v3 = util.vector3			local player = common.player
local devMode = common.devMode

local function rotate(x, y, z)
	local t = util.transform
	return ( t.rotateX(math.rad(x)) * t.rotateY(math.rad(y)) ) * t.rotateZ(math.rad(z))
end

local vectors = true
if core.contentFiles.has("redmountainreborn.esp") then

vectors = {
	-- # 1 7
	{ v3(13363, 63833, 13724), rotate(354, 0, 0), 1 },
	{ v3(14856, 60369, 13444), rotate(354, 11, 135), 1 },
	{ v3(12828, 60093, 12371), rotate(354, 34, 225), 1 },

	-- # 3 7
	{ v3(27821, 61560, 11725), rotate(0, 0, 151), 1 },
	{ v3(26811, 64298, 14532), rotate(354, 359, 135), 1.2 },
	{ v3(22729, 66441, 18121), rotate(354, 359, 337), 0.8 },
	{ v3(18518, 63823, 15873), rotate(354, 359, 135), 1 },
}

vectors.xyPos = util.vector2(20000, 63000)		vectors.radius = 15000
vectors.winds = v3(22415, 70835, 24000)		vectors.smoke = v3(22415, 70835, 24000)

--[[
22415, 70835, 20 (21334)
meshes/f/active_blight_large.nif

--]]

else

vectors = {
	-- # 1 7
	{ v3(13363, 63833, 13724), rotate(354, 0, 0), 1 },
	{ v3(14856, 60369, 13444), rotate(354, 11, 135), 1 },
	{ v3(12828, 60093, 12371), rotate(354, 34, 225), 1 },

	-- # 2 8
	{ v3(22109, 67380, 14221), rotate(11, 0, 125), 1 },
	{ v3(19201, 71624, 13605), rotate(348, 357, 298), 1 },
	{ v3(18431, 69379, 12717), rotate(354, 0, 262), 1 },

	-- # 3 7
	{ v3(27805, 61153, 11745), rotate(0, 0, 171), 1 },
}

vectors.xyPos = util.vector2(20000, 66000)		vectors.radius = 15000
vectors.winds = v3(20864, 68960, 23000)		vectors.smoke = v3(20864, 68960, 17000)

--[[
20864, 68960, 20000 (10816)
meshes/f/active_blight_large.nif

--]]

end


local lightning = {}
for k, v in ipairs(vectors) do
--	print(v[1], v[2])
	lightning[k] = {
		pos = v[2]:apply(v3(-128, 0, 1536)) * v[3] + v[1],
		xy = util.vector2(v[1].x, v[1].y),
		timer = math.random(2, 7)
	}
--	print(v, lightning[k].pos)
end


local noCheck = true		local spawnSmoke = true

local self = {}


function self.onPlayerAdded(e)	player = e		end


local timer = 1			local phase = 1

function self.onUpdate(dt)
	if not player.cell.isExterior then
		timer = 1		spawnSmoke = true
		return
	end
	local pos = player.position	local xy = util.vector2(pos.x, pos.y)
	local distance = common.viewDistance
	if (vectors.xyPos - xy):length() + vectors.radius > distance then
		return
	end
	local c = common
	if c.rmWinds then
		timer = timer - dt
		if timer < 1 then
			world.vfx.spawn("meshes/e/taitech/blightWinds.nif", vectors.winds, { scale=4 })
			timer = 48
			if devMode then player:sendEvent("showMessage", "SPAWN WINDS")		end
		end
	end
	if c.rmSmoke and spawnSmoke then
		spawnSmoke = false
		world.vfx.spawn("meshes/e/taitech/blightSmoke.nif", vectors.smoke, { scale=4 })
		if devMode then player:sendEvent("showMessage", "SPAWN BLIGHT SMOKE")		end
	end
	if not c.rmLightning then		return		end
	if (c.weather < 5 or c.weather > 7) then
		if c.rmOption == 2 or not c.isNight then
			return
		end
	end
	local ch = c.rmChance
	for i = #lightning, 1, -1 do
		local v = lightning[i]		v.timer = v.timer - dt
		if v.timer < 1 then
			local d = (v.xy - xy):length()
			if d < distance and math.random(100) < ch then
				local opt
				if d < 50000 then opt = { useAmbientLight=false }	end
				world.vfx.spawn("meshes/e/taitech/lightning_"..phase..".nif", v.pos, opt)
				phase = phase + 1	if phase > 3 then phase = 1		end
			end
			v.timer = math.random(4, 10)
		end
	end
end

function self.refreshVfx()
	if not player.cell.isExterior then	return		end
	if common.rmWinds then timer = 1		end
	if common.rmSmoke then spawnSmoke = true	end
end


return self
