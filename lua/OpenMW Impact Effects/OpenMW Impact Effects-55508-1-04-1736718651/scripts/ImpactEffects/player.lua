local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local util = require("openmw.util")
local camera = require("openmw.camera")
local nearby = require("openmw.nearby")
local async = require("openmw.async")
local vfs = require("openmw.vfs")
local storage = require("openmw.storage")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")
local ui = require("openmw.ui")

local Actor = types.Actor

local basePath = "Sound/Fx/impact/"
local scriptPath = "scripts/ImpactEffects/npc.lua"

local matSound = {
	Unknown = "Dirt",
	Dirt = "Dirt",
	Metal = "Metal",
	MetalHeavy = "Metal",
	Stone = "Stone",
	Glass = "Ice",
	Ice = "Ice",
	Carpet = "Dirt",
	Snow = "Dirt",
	Wood = "Wood",
	Water = "Water",
--	Organic = "Dmg",
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
	Dmg = { mesh="meshes/e/impact/bloodSplat.nif" },
	DmgDwemer = { { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_blood_gold.tga" },
		{ mesh="meshes/e/impact/metalSpark.nif" }		},
	DmgFrost = { mesh="meshes/e/impact/cloudLarge.nif", tex="Tx_bm_blizzard_01.tga" },
	DmgGhost = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_blood_white.tga" },
	DmgSkeleton = { mesh="meshes/e/impact/cloudLarge.nif", tex="Tx_blood_white.tga" },
	HitFrost = { mesh="meshes/e/impact/cloudLarge.nif", tex="Tx_bm_blizzard_01.tga" },
	Parry = { mesh="meshes/e/impact/parrySpark.nif" },
	ParryArmorHeavy = { mesh="meshes/e/impact/parrySpark.nif", scale=0.5 },
	ParryArmorBone = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
--	ParryArmorChitin = { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_Ash_Cloud.tga" },
	ParryArmorIce = { { mesh="meshes/e/impact/cloudSmall.nif", tex="Tx_bm_blizzard_01.tga" },
		{ mesh="meshes/e/impact/parrySpark.nif", scale=0.5 }		},
}

local noIso = { DmgDwemer=true, DmgGhost=true, DmgSkeleton=true, Water=true }
local volAdjust = { Water = 3.3, Parry2 = 1.5 }

local L = {FIL = {}}


local oldVfsApi = true
if types.Static.records["ex_de_oar"].model:find("/") then oldVfsApi = false	end

local matModel, M = {}
for i in vfs.pathsWithPrefix("scripts/ImpactEffects/interop/materialModel") do
	if i:find(".lua$") then
		i = string.gsub(i, ".lua", "")
		i = string.gsub(i, "/", ".")
		M = require(i)
		for k, v in pairs(M) do matModel[k:lower()] = v end
	end
end
local matFallback = require("scripts.ImpactEffects.materialFallback")
local matCreature = require("scripts.ImpactEffects.materialCreature")
local filter = { {"^meshes/"}, {"^tr/"}, {"^sky/"}, {"^pc/"}, {"^oaab/"},
		{"/tr_", "/"}, {"/sky_", "/"}, {"/pc_", "/"} }


L.WT = {
	[types.Weapon.TYPE.ShortBladeOneHand] = 1,
	[types.Weapon.TYPE.LongBladeOneHand] = 2,
	[types.Weapon.TYPE.LongBladeTwoHand] = 3,
	[types.Weapon.TYPE.BluntOneHand] = 4,
	[types.Weapon.TYPE.BluntTwoClose] = 4,
	[types.Weapon.TYPE.BluntTwoWide] = 4,
	[types.Weapon.TYPE.SpearTwoWide] = 2,
	[types.Weapon.TYPE.AxeOneHand] = 2,
	[types.Weapon.TYPE.AxeTwoHand] = 3,
	}
local weaponGroups = { weapononehand = true, weapontwohand = true, weapontwowide = true,
	handtohand = true }
local weapons = { fists = { dist=135 * core.getGMST("fHandToHandReach"), iso=0 } }
local equipped = "fists"


local settings = storage.playerSection("Settings_impacteffects")
local disableAll, enableActors, hitMark
local volume = 0.3	local debug = false

local function updateSettings()
	disableAll = not settings:get("enable")
	enableActors = settings:get("enable_npc")
	hitMark = settings:get("enable_hitmark")
	volume = settings:get("volume_mst") / 100
end

settings:subscribe(async:callback(updateSettings))
updateSettings()

local actorHandlers = {}	local objectHandlers = {}


local function pickSound(d)
	local f = L.FIL[d]
	if not f then
		f = {}
		for file in vfs.pathsWithPrefix(basePath .. d) do
			if file:find("wav$") then table.insert(f, file) end
		end
		L.FIL[d] = f
	end
	return f[math.random(#f)]
end

local function playVfx(vfx, hit)
	local opt = { useAmbientLight=false }
	if vfx.tex then opt.particleTextureOverride=vfx.tex	opt.mwMagicVfx=false	end
	if vfx.scale then opt.scale = vfx.scale		end
--	print(vfx, vfx.mesh)
	core.sendGlobalEvent("SpawnVfx", { model=vfx.mesh, position=hit, options=opt })
end

local function getCreature(o, model)
	if not o then return	end
	local id, cr = o.recordId
	if o.type.record(o).type == o.type.TYPE.Undead then
		if types.Actor.activeEffects(o):getEffect("chameleon").magnitude > 49
			or id:find("ghost") or id:find("spectre") then
			cr = { hit="HitGhost", dmg="DmgGhost" }
		elseif id:find("skeleton") or id:find("lich") then
			cr = { hit="HitSkeleton", dmg="DmgSkeleton" }
		end
	elseif id:find("dremora") then
		cr = { dmg="DmgGhost" }
	elseif id:find("dwemer") then
		cr = { hit="Parry", dmg="DmgDwemer" }
	end
	cr = cr or { hit="Unknown", dmg="Dmg" }
	matCreature[model] = cr
--	print(model, cr.hit, cr.dmg)
	return cr
end

local function runHandlers(o, var, res)
	local handlers = objectHandlers
	if o and types.Actor.objectIsInstance(o) then handlers = actorHandlers	end
	for i = #handlers, 1, -1 do
		if handlers[i](o, var, res) == false then return	end
	end
end


local matArmor = {}
local armorTables = {

	class = {
	--	18, 27		9, 13.5		3, 4.5
	[types.Armor.TYPE.Cuirass] =
			{ light = core.getGMST("iCuirassWeight") * core.getGMST("fLightMaxMod") + 0.005,
			medium = core.getGMST("iCuirassWeight") * core.getGMST("fMedMaxMod") + 0.005	},
	[types.Armor.TYPE.Greaves] =
			{ light = core.getGMST("iGreavesWeight") * core.getGMST("fLightMaxMod") + 0.005,
			medium = core.getGMST("iGreavesWeight") * core.getGMST("fMedMaxMod") + 0.005	},
	[types.Armor.TYPE.Helmet] =
			{ light = core.getGMST("iHelmWeight") * core.getGMST("fLightMaxMod") + 0.005,
			medium = core.getGMST("iHelmWeight") * core.getGMST("fMedMaxMod") + 0.005	}
--[[
lightest heavy		29	17	5
heaviest medium		27	13.45	4.5

lightest medium		21	10	3.5
heaviest light		18	9	3
--]]
	},

	fallback = {
		{ "ice_", "ParryArmorIce" },
		{ "adamant", "ParryArmorHeavy" },
		{ "iron", "ParryArmorHeavy" },
		{ "helsethguard", "ParryArmorHeavy" },
		{ "silver", "ParryArmorHeavy" },
		{ "steel", "ParryArmorHeavy" },
		{ "orcish", "ParryArmorHeavy" },
		{ "bear", "Carpet" },
		{ "glass", "Glass" },
		{ "indoril", "ParryArmorBone" },
		{ "chitin", "ParryArmorBone" },
	}

	}


local function getArmorMat(id)
	local rec, mat = types.Armor.records[id]
	if not rec then
		mat = { hit="Unknown" }
		matArmor[id] = mat
		if debug then print("notARMOR "..id.." "..mat.hit)	end
		return mat
	end
	local weight = rec.weight	local class = armorTables.class[rec.type]
	if id:find("bone") then mat = { hit="ParryArmorBone" }
	elseif weight > class.medium then mat = { hit="ParryArmorHeavy" }
	end
	if mat then
		matArmor[id] = mat
		if debug then print(id.." "..mat.hit)		end
		return mat
	end

	local searches = armorTables.fallback
	for i = 1, #searches do
		local k, v = table.unpack(searches[i])
		if id:find(k) then mat = { hit=v }	end
	end

	if not mat and weight > class.light then mat = { hit="ParryArmorMedium" }	end
	mat = mat or { hit="Carpet" }
	matArmor[id] = mat
--	print(weight, rec.type, type.medium)
	if debug then print(id.." "..mat.hit)		end
	return mat
end

local function getNpcArmor(o, hit)
	local npc = types.NPC.record(o)
	local gender = npc.isMale and "male" or "female"
	local height = types.NPC.races.record(npc.race).height[gender] * 128 * o.scale
	local z, slot = (hit.z - o.position.z) / height
	if z > 0.85 then
		slot = Actor.EQUIPMENT_SLOT.Helmet
	elseif z > 0.6 then
		slot = Actor.EQUIPMENT_SLOT.Cuirass
	else
		slot = Actor.EQUIPMENT_SLOT.Greaves		
	end
	local eq = Actor.getEquipment(o, slot)
--	print(eq and eq.recordId or "nil")
	if not eq then return "Unknown" end
	return matArmor[eq.recordId] or getArmorMat(eq.recordId)
end

local function resultRayCast(res, rayStart, rayEnd)
	local hit, hitWater = res.hitPos or rayEnd
	local water, unknown = "Water", "Unknown"	local waterline = self.cell.waterLevel
	if waterline then
		if hit.z < waterline - 5 or (rayStart.z < waterline and rayEnd.z > waterline) then hitWater = true end
	end
	if not res.hitPos and not hitWater then return	end
	local debug = debug
	local o, mat, path, model = res.hitObject	local dmg = weapons[equipped].iso

	if o and types.NPC.objectIsInstance(o) then
		if enableActors then
			if o.type.isDead(o) then mat =  "Dmg"
			elseif hitMark then mat = getNpcArmor(o, hit)["hit"]		end
		end
	elseif o then
		path = o.type.record(o).model:lower()

		--	OMW versions before b6a14611 Nov 19 2024
		if oldVfsApi then path = string.gsub(path, "\\", "/")	end

		local i, j = string.find(path, "/[^/]*$")
		if i then model = string.sub(path, i+1, j) end
		if types.Creature.objectIsInstance(o) then	local cr
			if enableActors then cr = matCreature[model] or getCreature(o, model)	end
--			local cr = matCreature[model] or getCreature(o, model)
			if cr then
				if o.type.isDead(o) then mat = cr.dmg elseif hitMark then mat = cr.hit end
			end
		else
			if o.type.record(o).mwscript then core.sendGlobalEvent("impactRunMwscript", {o, self})	end
			mat = matModel[model]
		end
	else
		mat = "Dirt"
	end

	if not mat and types.Actor.objectIsInstance(o) then
		if not hitWater then return	end
		mat = water
	end
	if not mat then
		local pattern = matFallback
		for i = 1, #filter do
			local v = filter[i]
			path = string.gsub(path, v[1], v[2] or "", 1)
		end
		for i = 1, #pattern do
			local k, v = table.unpack(pattern[i])
			if debug then print(k)	end
			if path:find(k) then mat = v break end
		end
		mat = mat or unknown
		matModel[model] = mat
	end
	if hitWater and not(rayStart.z < waterline and res.hitPos) then
		mat = water
		local mult = ((rayStart.z - waterline) / (rayStart.z - hit.z))
		local delta = (rayEnd - rayStart)
		hit = rayStart + delta * mult
	end
	if debug and self.controls.sneak then print(mat.." "..path, matVfx[mat])	end

	local var = { material=mat, hitPos=hit, from=rayStart, to=rayEnd }
--	if hitWater then var.hitWater = hitPos		end
	runHandlers(o, var, res)

	local dir = matSound[mat] or "Dirt"		dir = dmg > 0 and dir or "Dmg"
	if not noIso[dir] then dir = dir .. dmg		end
	local vol = ( volAdjust[dir] or 1 ) * volume	if vol > 1 then vol = 1 end
--	print(mat, o, hit)	print(mat, dir)
	if vol > 0 and not var.noSound then
		core.sound.playSoundFile3d(pickSound(dir), self, {volume=vol, pitch=math.random(90,110)/100})
	end
	if var.noVfx then return	end
	local vfx = matVfx[mat]
	if not vfx or dmg < 1 then return	end

	if #vfx > 0 then
		for i = 1, #vfx do playVfx(vfx[i], hit)		end
	else
		playVfx(vfx, hit)
	end

end



local function getWeapon(o)
	if not o or o.type ~= types.Weapon then return weapons.fists	end
	local w = weapons[o.recordId]		if w then return w	end
	local iso = L.WT[o.type.record(o).type]
	if not iso then return weapons.fists	end
	w = { dist=135 * o.type.record(o).reach, iso=iso }
	weapons[o.recordId] = w
--	print(w.dist, w.iso)
	return w
end


I.AnimationController.addTextKeyHandler("", function(g, key)
	if not weaponGroups[g] or disableAll then return	end
	if not key:find("min hit$") then return		end
	local rw, w = Actor.getEquipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)

	if not rw and equipped ~= "fists" then equipped = "fists"	end

	if rw and rw.recordId == equipped then
		w = weapons[equipped] or weapons.fists
	else
		w = getWeapon(rw)
		if w.iso > 0 then equipped = rw.recordId else equipped = "fists"	end
	end
	local vec = camera.viewportToWorldVector(util.vector2(0.5,0.5))
	local pos = camera.getPosition() + vec * camera.getThirdPersonDistance()
	local target = pos + vec * w.dist
	nearby.asyncCastRenderingRay(async:callback(function(res) resultRayCast(res, pos, target) end),
		pos, target, { ignore = self })
end)

I.AnimationController.addPlayBlendedAnimationHandler(function (g, options)
	if g ~= "shield" or disableAll then return end
	local first = camera.getMode() == camera.MODE.FirstPerson
	local vfx = first and "metalSpark.nif" or "shieldBlock.nif"
	anim.addVfx(self, "meshes/e/impact/"..vfx, {boneName="Shield Bone"})
end)


return {
	eventHandlers = {
		OMWMusicCombatTargetsChanged = function(e)
--			print(e.actor.recordId)
			if next(e.targets) == nil or not enableActors then return	end
			local o = e.actor
			if o.type == types.Creature and not o.type.record(o).canUseWeapons then return	end
			core.sendGlobalEvent("impactActorUpdate", o)
--			ui.showMessage(o.recordId.." Attacks!")
		end
	},
	interfaceName = "impactEffects",
	interface = {
		version = 0,
		addHitActorHandler = function(m)
			actorHandlers[#actorHandlers + 1] = m
		end,
		addHitObjectHandler = function(m)
			objectHandlers[#objectHandlers + 1] = m
		end
	}
}
