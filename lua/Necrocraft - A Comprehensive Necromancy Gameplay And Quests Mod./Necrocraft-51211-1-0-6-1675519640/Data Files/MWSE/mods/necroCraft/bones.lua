local skillModule = require("OtherSkills.skillModule")

local bones = {}

local boneParts = {
    skeletonChampion = {
		{id = "misc_skull00", count = 1},
		{id = "AB_Misc_BoneSkelArmL", count = 1},
		{id = "AB_Misc_BoneSkelArmR", count = 1},
		{id = "AB_Misc_BoneSkelLegL", count = 1},
		{id = "AB_Misc_BoneSkelLegR", count = 1},
		{id = "AB_Misc_BoneSkelTorso", count = 1},
		{id = "AB_Misc_BoneSkelPelvis", count = 1},
	},
	skeletonWarrior = {
		{id = "misc_skull00", count = 1},
		{id = "AB_Misc_BoneSkelArmL", count = 1},
		{id = "AB_Misc_BoneSkelArmR", count = 1},
		{id = "AB_Misc_BoneSkelLegL", count = 1},
		{id = "AB_Misc_BoneSkelLegR", count = 1},
		{id = "AB_Misc_BoneSkelTorso", count = 1},
		{id = "AB_Misc_BoneSkelPelvis", count = 1},
	},
	skeletonCripple = {
		{id = "AB_Misc_BoneSkelSkullNoJaw", count = 1},
		{id = "AB_Misc_BoneSkelArmR", count = 1},
		{id = "AB_Misc_BoneSkelArmUpperL", count = 1},
		{id = "AB_Misc_BoneSkelLegL", count = 1},
		{id = "AB_Misc_BoneSkelLegR", count = 1},
		{id = "AB_Misc_BoneSkelTorsoBroken", count = 1},
		{id = "AB_Misc_BoneSkelPelvis", count = 1},
	},
	bonespider = {
		{id = "misc_skull00", count = 1},
		{id = "AB_Misc_BoneSkelArmUpperR", count = 2},
		{id = "AB_Misc_BoneSkelArmUpperL", count = 2},
		{id = "AB_Misc_BoneSkelArmL", count = 1},
		{id = "AB_Misc_BoneSkelArmR", count = 1},
	},
	bonelord = {
		{id = "AB_Misc_BoneSkelSkullNoJaw", count = 1},
		{id = "AB_Misc_BoneSkelArmL", count = 2},
		{id = "AB_Misc_BoneSkelArmR", count = 2},
	},
	boneoverlord = {
		{id = "AB_Misc_BoneSkelSkullNoJaw", count = 3},
		{id = "AB_Misc_BoneSkelArmL", count = 2},
		{id = "AB_Misc_BoneSkelArmR", count = 2},
		{id = "AB_Misc_BoneSkelArmUpperR", count = 4},
		{id = "AB_Misc_BoneSkelArmUpperL", count = 4},
	}
}

local brokenBone = {
	misc_skull00 = {"AB_Misc_BoneSkelSkullJaw", "AB_Misc_BoneSkelSkullNoJaw"},
	AB_Misc_BoneSkelTorso = {"AB_Misc_BoneSkelTorsoBroken"},
    AB_Misc_BoneSkelArmL = {"AB_Misc_BoneSkelArmUpperL", "AB_Misc_BoneSkelArmWristL", "AB_Misc_BoneSkelHandL"},
    AB_Misc_BoneSkelArmR = {"AB_Misc_BoneSkelArmUpperR", "AB_Misc_BoneSkelArmWristR", "AB_Misc_BoneSkelHandR"},
    AB_Misc_BoneSkelLegL = {"AB_Misc_BoneSkelLegUpperL", "AB_Misc_BoneSkelLegShinL", "AB_Misc_BoneSkelFootL"},
    AB_Misc_BoneSkelLegR = {"AB_Misc_BoneSkelLegUpperR", "AB_Misc_BoneSkelLegShinR", "AB_Misc_BoneSkelFootR"},
}

local function addBrokenBones(broken)
    if broken then
        n = #broken
        local k
        if n == 1 then
            k = 1
        else
            k = math.random(1,math.max(n-1))
        end
        for i, part in pairs(broken) do
            local chance = k/n
            if math.random() < chance then
                tes3.addItem{reference=tes3.player, item=part, count=1, playSound=false}
				k = k-1
            end
			n = n-1
        end
    end
end

local function tryHarvest(bone)
	local skill = skillModule.getSkill("NC:CorpsePreparation").value
	local intelligence = tes3.mobilePlayer.intelligence.current
	local luck = tes3.mobilePlayer.luck.current
	local fatigue = tes3.mobilePlayer.fatigue
	local success = (intelligence/5 + luck/10 + skill) * (fatigue.current / fatigue.base)
	local high = 75
	local medium = 50
	local low = 25
	local rand = math.random()
    local broken = brokenBone[bone]
	if success > rand * high then
		tes3.addItem{reference=tes3.player, item=bone, count=1, playSound=false}
	elseif success > rand * medium and not broken then
		tes3.addItem{reference=tes3.player, item=bone, count=1, playSound=false}
	elseif success > rand * low and brokenBone[bone] then
		addBrokenBones(broken)
	end
end


bones.isBone = function(id)
	if string.startswith(id, "AB_Misc_Bone") or string.startswith(id, "misc_skull") then
		return true
	end
	return false
end

bones.harvest = function(utype)
	if not utype then return end
	local pile = boneParts[utype] and utype or "skeletonWarrior"
	for _, bonePart in ipairs(boneParts[pile]) do
		local bone = bonePart.id
		local count = bonePart.count
        for i = 1, count do
			tryHarvest(bone)
		end
	end
end

return bones