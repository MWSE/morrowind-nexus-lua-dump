local utility = require("NecroCraft.utility")

local undead = {}
local undeadTable = {}

local function requiresTwoHands(item)
	if item.objectType == tes3.objectType.armor then
		if item.slot == tes3.armorSlot.shield then
			return true
		end
	elseif item.objectType == tes3.objectType.weapon then
		if item.isTwoHanded or item.weaponType == tes3.weaponType.marksmanBow or item.weaponType == tes3.weaponType.marksmanCrossbow then
			return true
		end
	end
end

undead.getType = function(object)
	if not object then return end
	for key, value in pairs(undeadTable) do
		if value.mesh == object.mesh then
			if key == "skeleton" then
				if object.level >= 10 then
					return "skeletonChampion"
				else
					return "skeletonWarrior"
				end
			else
				return key
			end
		end
	end
	return false
end

undead.handleFollow = function(caster, raised)
	caster = caster.id and caster or tes3.getReference(caster)
	if caster == tes3.player or tes3.player.data.necroCraft.minions.bonelord[caster.id] or tes3.player.data.necroCraft.minions.boneoverlord[caster.id] then
		raised.mobile.fight = 0
		local utype = undead.getType(raised.object)
		tes3.setAIFollow{reference=raised, target=tes3.player}
		tes3.player.data.necroCraft.minions[utype][raised.id] = true
	else
		tes3.setAIFollow{reference=raised, target=caster}
	end
end

undead.isReadyToBeRaised = function(ref)
	if not ( ref and ref.mobile and ref.object and ref.object.baseObject) then 
		return false 
	end
	local id = ref.object.baseObject.id
	if not string.startswith(id, "NC_skeleton") and not string.startswith(id, "NC_bone") then 
		return false 
	end
	if ref.data.necroCraft and ref.data.necroCraft.isBeingRaised then 
		return false
	end
	return string.endswith(id, "_corpse") or string.endswith(id, "_pile")
end

undead.miscToPile = function(ref)
	if not ref then return false end
	local id = ref.id
	if not string.startswith(id, "NC_skeleton") and not string.startswith(id, "NC_bone") then return false end
	if not string.endswith(id, "_misc") then return false end
	return tes3.getObject(string.gsub(id, "_misc", "_pile"))
end

undead.pileToMisc = function(ref)
	if not ref or not ref.mobile or not ref.object or not ref.object.baseObject then return false end
	local id = ref.object.baseObject.id
	if not string.startswith(id, "NC_skeleton") and not string.startswith(id, "NC_bone") then return false end
	if not string.endswith(id, "_pile") then return false end
	return tes3.getObject(string.gsub(id, "_pile", "_misc" ))
end

undead.pileToRaised = function(ref)
	if not ref or not ref.mobile or not ref.object or not ref.object.baseObject then return false end
	local id = ref.object.baseObject.id
	if not string.startswith(id, "NC_skeleton") and not string.startswith(id, "NC_bone") then return false end
	if not string.endswith(id, "_pile") then return false end
	return tes3.getObject(string.sub(id, 1, -6))
end

undead.corpseToRaised = function(ref)
	if not ref or not ref.mobile or not ref.object or not ref.object.baseObject then return false end
	local id = ref.object.baseObject.id
	if not string.startswith(id, "NC_") then return false end
	if not string.endswith(id, "_corpse") then return false end
	return tes3.getObject(string.sub(id, 1, -8))
end

skeletonCrippleVariants = {
	NC_skeleton_weak = true,
	NC_skeleton_weak_pile = true
}

undead.skeletonCrippleDrop = function(reference)
	if not reference.object or not reference.object.baseObject or not skeletonCrippleVariants[reference.object.baseObject.id] then
		return
	end
	timer.start{
		duration = 0.1,
		callback = function()
			for _, stack in pairs(reference.object.inventory) do
				if requiresTwoHands(stack.object) then
					tes3.dropItem{reference = reference, item = stack.object, count = stack.count}
				end
			end
		end
	}
end

undead.skeletonChampRestore = function(reference)
	if reference.object.baseObject.id ~= "NC_skeleton_champ" then
		return
	end
	local restorationChance = 75
	if math.random(1, 100) <= restorationChance then
		tes3.modStatistic{reference = reference, name = "health", current = 150, limit = true}
		tes3.modStatistic{reference = reference, name = "fatigue", current = -1001}
		timer.start{
			duration = 3,
			callback = function()
				tes3.modStatistic{reference = reference, name = "fatigue", current = 5000, limit = true}
			end
		}
	end
end

undead.isRaisedByPlayer = function(reference)
	if not (reference and reference.mobile and reference.object and reference.object.baseObject) then 
		return
	end
	if reference.mobile.isDead then
		return 
	end
	if reference.data.necroCraft and reference.data.necroCraft.isBeingRaised then
		return
	end
	local utype = undead.getType(reference.object)
	if utype then
		return tes3.player.data.necroCraft.minions[utype][reference.id] or false
	end
end

undead.init = function()
	if tes3.player.data.necroCraft == nil then
		tes3.player.data.necroCraft = {}
	end
	if tes3.player.data.necroCraft.minions == nil then 
		tes3.player.data.necroCraft.minions = {}
	end
	if tes3.player.data.necroCraft.minions.skeletonCripple == nil then 
		tes3.player.data.necroCraft.minions.skeletonCripple = {}
	end
	if tes3.player.data.necroCraft.minions.skeletonWarrior == nil then 
		tes3.player.data.necroCraft.minions.skeletonWarrior = {}
	end
	if tes3.player.data.necroCraft.minions.skeletonChampion == nil then 
		tes3.player.data.necroCraft.minions.skeletonChampion = {}
	end
	if tes3.player.data.necroCraft.minions.bonespider == nil then 
		tes3.player.data.necroCraft.minions.bonespider = {}
	end
	if tes3.player.data.necroCraft.minions.bonelord == nil then 
		tes3.player.data.necroCraft.minions.bonelord = {}
	end
	if tes3.player.data.necroCraft.minions.boneoverlord == nil then 
		tes3.player.data.necroCraft.minions.boneoverlord = {}
	end
	if tes3.player.data.necroCraft.minions.zombie == nil then 
		tes3.player.data.necroCraft.minions.zombie = {}
	end
	if tes3.player.data.necroCraft.minions.bonewalker == nil then 
		tes3.player.data.necroCraft.minions.bonewalker = {}
	end
	if tes3.player.data.necroCraft.minions.greaterBonewalker == nil then 
		tes3.player.data.necroCraft.minions.greaterBonewalker = {}
	end
	if tes3.player.data.necroCraft.minions.bonewolf == nil then 
		tes3.player.data.necroCraft.minions.bonewolf = {}
	end
	undeadTable.skeleton = tes3.getObject("skeleton")
	undeadTable.skeletonCripple = tes3.getObject("NC_skeleton_weak")
	undeadTable.bonespider = tes3.getObject("NC_bonespider")
	undeadTable.bonelord = tes3.getObject("bonelord")
	undeadTable.boneoverlord = tes3.getObject("NC_boneoverlord")
	undeadTable.lich = tes3.getObject("lich")
	undeadTable.lichKing = tes3.getObject("lich_barilzar")
	undeadTable.zombie = tes3.getObject("AB_Und_Zombie")
	undeadTable.bonewalker = tes3.getObject("bonewalker")
	undeadTable.greaterBonewalker = tes3.getObject("Bonewalker_Greater")
	undeadTable.bonewolf = tes3.getObject("BM_wolf_skeleton")
end

return undead