local common = common
local types = common.openmw.types
local core = common.openmw.core
local util = common.openmw.util
local world = common.openmw.world

local v3 = util.vector3			local player = common.player
local debug = common.debug

local vectors = {}

--[[
31003, -100405, 3696
meshes/taitech/ty_ring.nif

28489, -100669, 7672
meshes/x/ty_ring.nif
TY_Prison Ring		Vivec Ghost Ring
TY_ring

--]]

if core.contentFiles.has("baar dau ghost ring.omwaddon") then

vectors.xyPos = util.vector2(31000, -100400)		vectors.radius = 2500
vectors.ty_ring = v3(31000, -100405, 3696)
vectors.model = "meshes/x/ty_ring_045_vfx.nif"	vectors.scale = 1	vectors.timer = 360

elseif core.contentFiles.has("vivec_cos.esp") then

vectors.xyPos = util.vector2(33000, -92300)		vectors.radius = 5000
vectors.ty_ring = v3(33024, -92352, 8640)
vectors.model = "meshes/x/ty_ring_cos_vfx.nif"	vectors.scale = 1	vectors.timer = 360

elseif core.contentFiles.has("baar_dau_cos.esp") then

vectors.xyPos = util.vector2(28500, -100700)		vectors.radius = 5000
vectors.ty_ring = v3(28489.871, -100668.719, 7672.828)
vectors.model = "meshes/x/ty_ring_cos_vfx.nif"	vectors.scale = 1	vectors.timer = 360

elseif core.contentFiles.has("baar dau - ministry of truth.esp") then

vectors.xyPos = util.vector2(31000, -100400)		vectors.radius = 3000
vectors.ty_ring = v3(31003, -100406, 4861)
vectors.model = "meshes/x/ty_ring_vfx.nif"	vectors.scale = 0.60	vectors.timer = 360

elseif core.contentFiles.has("meteorite ministry palace - higher.esp") then

vectors.xyPos = util.vector2(31000, -100400)		vectors.radius = 2500
vectors.ty_ring = v3(31003, -100406, 6630)
vectors.model = "meshes/x/ty_ring_vfx.nif"	vectors.scale = 0.45	vectors.timer = 360

elseif core.contentFiles.has("meteorite ministry temple - higher.esp") then

vectors.xyPos = util.vector2(31000, -100400)		vectors.radius = 2500
vectors.ty_ring = v3(31003, -100406, 6630)
vectors.model = "meshes/x/ty_ring_vfx.nif"	vectors.scale = 0.45	vectors.timer = 360

else

vectors.xyPos = util.vector2(31000, -100400)		vectors.radius = 2500
vectors.ty_ring = v3(31000, -100405, 3696)
vectors.model = "meshes/x/ty_ring_vfx.nif"	vectors.scale = 0.45	vectors.timer = 360

end



local self = {}


function self.onPlayerAdded(e)	player = e		end


local timer = 1

function self.onUpdate(dt)
	if not common.isExterior then
		timer = 1
		return
	end

	local cull
	if (vectors.xyPos - common.posXY):length() + vectors.radius > common.viewDistance then
		cull = true
		if timer <= 1 then	return		end
	end

	timer = timer - dt
	if timer <= 1 and cull then
		debug("CULLED TY_RING")
		return
	end
	if timer >= 1 then	return		end

	timer = vectors.timer
	world.vfx.spawn(vectors.model, vectors.ty_ring, { scale=vectors.scale, useAmbientLight=false })
	debug("SPAWN TY_RING")

end

function self.refreshVfx()
	if common.isExterior then	timer = 1		end
end


return self
