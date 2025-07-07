local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local world = require("openmw.world")
local vfs = require("openmw.vfs")

local paths = {
	sounds = "Sound/Fx/impact/",
	npc = "scripts/ImpactEffects/npc.lua",
	mods = "scripts/ImpactEffects/interop/mods/",
}

local matSound = {
	Unknown = "Dirt",
	Dirt = "Dirt",
	Metal = "Metal",
	Stone = "Stone",
	Glass = "Ice",
	Ice = "Ice",
	Carpet = "Dirt",
	Snow = "Dirt",
	Wood = "Wood",
	Water = "Water",
	Ceramic = "Ice",
	Fabric = "Dirt",
	Paper = "Dirt",
	Organic = "Dirt",
	MetalHeavy = "Metal",
	Dmg = "Dmg",
	DmgDwemer = "DmgDwemer",
	DmgFire = "Dirt",
	DmgFrost = "Ice",
	DmgGhost = "DmgGhost",
	DmgSkeleton  = "DmgSkeleton",
	Hit = "Dmg",
	HitFire = "Dirt",
	HitFrost = "Ice",
	HitGhost = "DmgGhost",
	HitSkeleton = "Wood",
	Parry = "Parry",
	ParryArmorHeavy = "Parry",
	ParryArmorBone = "Wood",
--	ParryArmorChitin = "Wood",
	ParryArmorIce = "Parry",
	ParryArmorMedium = "Wood",
	}

local matVfx = {
	Stone = { { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
		{ mesh="meshes/e/impact/metalSpark.nif" }		},
	Metal = { mesh="meshes/e/impact/metalSpark.nif" },
	MetalHeavy = { mesh="meshes/e/impact/metalSpark.nif" },
	Wood = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
	Dirt = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
	Water = { mesh="meshes/e/impact/waterSplash.nif" },
	Ice = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_bm_blizzard_01.tga" },
	Snow = { mesh="meshes/e/impact/cloudLarge.nif", tex="Tx_bm_blizzard_01.tga" },
	Ceramic = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
	Dmg = { mesh="meshes/e/impact/bloodSplat.nif" },
	DmgDwemer = { { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_blood_gold.tga" },
		{ mesh="meshes/e/impact/metalSpark.nif" }		},
	DmgFrost = { mesh="meshes/e/impact/cloudLarge.nif", tex="Tx_bm_blizzard_01.tga" },
	DmgGhost = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_blood_white.tga" },
	DmgSkeleton = { mesh="meshes/e/impact/cloudLarge.nif", tex="Tx_blood_white.tga" },
	HitFrost = { mesh="meshes/e/impact/cloudLarge.nif", tex="Tx_bm_blizzard_01.tga" },
	HitSkeleton = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
	Parry = { mesh="meshes/e/impact/parrySpark.nif" },
	ParryArmorHeavy = { mesh="meshes/e/impact/parrySpark.nif", scale=0.5 },
	ParryArmorBone = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
--	ParryArmorChitin = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
	ParryArmorIce = { { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_bm_blizzard_01.tga" },
		{ mesh="meshes/e/impact/parrySpark.nif", scale=0.5 }		},
}

local matModel, M = {}
for i in vfs.pathsWithPrefix("scripts/ImpactEffects/interop/materialModel/") do
	if i:find("%.lua$") then
		i = string.sub(i, 1, -5)
		i = string.gsub(i, "/", ".")
		M = require(i)
		for k, v in pairs(M) do matModel[k:lower()] = v			end
	end
end
local matFallback = require("scripts.ImpactEffects.materialFallback")
local matCreature = require("scripts.ImpactEffects.materialCreature")
local pathFilter = { {"^meshes/"}, {"^tr/"}, {"^sky/"}, {"^pc/"}, {"^hr/"}, {"^oaab/"},
		{"/tr_", "/"}, {"/sky_", "/"}, {"/pc_", "/"} }

local matByTypes = {
    a = {
        [types.Potion] = "Glass",
        [types.Book] = "Paper",
        [types.Clothing] = "Fabric",
        [types.Ingredient] = "Organic",
        [types.Repair] = "Metal",
    },
    b = {
        [types.Apparatus] = "Ceramic",
        [types.Container] = "Wood",
        [types.Door] = "Wood",
        [types.Static] = "Stone",
        [types.Weapon] = "Metal",
        [types.Armor] = "Metal",
    }
}


local function removeLocal(o)
	if types.Actor.isDead(o) or not types.Actor.isInActorsProcessingRange(o) then
		if o:hasScript(paths.npc) then
			o:removeScript(paths.npc)
--			print(o.recordId.." PurgeScript")
		end
	end
end

local function playVfx(vfx, hit)
	local opt = { useAmbientLight=false }
	if vfx.tex then opt.particleTextureOverride=vfx.tex	opt.mwMagicVfx=false	end
	if vfx.scale then opt.scale = vfx.scale		end
--	print(vfx, vfx.mesh)
	world.vfx.spawn(vfx.mesh, hit, opt)
end

local function spawnEffect(m)
	local mat = m.material
	assert(mat and type(mat) == "string", "spawnEffect: material must be string and non-nil")
	assert(m.hitPos, "spawnEffect: hitPos must be non-nil")
	if m.noVfx then		return		end
	local vfx = matVfx[mat]
	if not vfx then		return		end

	if #vfx > 0 then
		for i = 1, #vfx do playVfx(vfx[i], m.hitPos)		end
	else
		playVfx(vfx, m.hitPos)
	end
end

local function getObjectMat(o, path, model)
    local mat = matByTypes.a[o.type]
    if not mat then
        local pattern = matFallback
        for i = 1, #pathFilter do
            local v = pathFilter[i]
            path = string.gsub(path, v[1], v[2] or "", 1)
        end
        for i = 1, #pattern do
            local k, v = table.unpack(pattern[i])
            if debug then print(k)    end
            if path:find(k) then mat = v break    end
        end
    end
    if not mat then mat = matByTypes.b[o.type] or "Unknown"    end

    matModel[model] = mat
    return mat
end

return {
	eventHandlers = {
		impactActorUpdate = function(o)
			if not o:hasScript(paths.npc) then o:addScript(paths.npc)	end
		end,
		impactRunMwscript = function(e)
--			print("MWSCRIPT check")
			local mw = world.mwscript.getLocalScript(e[1], e[2]).variables
			if mw.onpchitme then
				mw.onpchitme = 1	-- e[1]:activateBy(e[2])
			elseif mw.impact_hit then
				mw.impact_hit = 1
			end
		end,
		impactPurgeLocal = function(o)
			async:newUnsavableSimulationTimer(3, function() removeLocal(o) end)
		end,
		impactSound = function(e)
			core.sound.playSoundFile3d(e.sound, e.object, e.options)
		end,
		impactSpawnEffect = spawnEffect
	},
	interfaceName = "impactEffects",
	interface = {
		version = 107,
		registerModelMaterial = function(model, mat)
			assert(type(model) == "string" and type(mat) == "string",
				"model and material must be strings")
			matModel[model] = mat
		end,
		registerFallback = function(pattern, mat)
			assert(type(pattern) == "string" and type(mat) == "string",
				"pattern and material must be strings")
			for i in ipairs(matFallback) do
				if i == pattern then		return		end
			end
			table.insert(matFallback, {pattern, mat})
		end,
		getMaterialByObject = function(o)
			if types.Actor.objectIsInstance(o) then		return "Unknown"	end
			local path, model = o.type.records[o.recordId].model:lower()
			path = string.gsub(path, "\\", "/")
			local i, j = string.find(path, "/[^/]*$")
			local model = string.sub(path, i+1, j)
			if not model or model == "" then	return "Unknown"	end
			return matModel[model] or getObjectMat(o, path, model)
		end,
		spawnEffect = spawnEffect,
	}
}
