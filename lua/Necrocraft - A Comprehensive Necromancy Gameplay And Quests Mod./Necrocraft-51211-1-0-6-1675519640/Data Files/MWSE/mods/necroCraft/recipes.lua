local strings = require("NecroCraft.strings")

local this = {}

this.bonepiles = {

	broken_ribs = {
		handler = "bonepiles",
        id = "AB_Misc_BoneSkelTorsoBroken",
        description = strings.brokenRibs,
        ingredients = {
			{ id = "AB_Misc_BoneSkelTorso", count = 1 },
        },
        skillReq = 0
	},
	
	ribs = {
		handler = "bonepiles",
        id = "AB_Misc_BoneSkelTorso",
        description = strings.ribs,
        ingredients = {
			{ id = "AB_Misc_BoneSkelTorsoBroken", count = 2 },
        },
        skillReq = 0
	},
	
	broken_skull = {
		handler = "bonepiles",
        id = "AB_Misc_BoneSkelSkullNoJaw",
        description = strings.brokenSkull,
        ingredients = {
			{ id = "misc_skull00", count = 1 },
        },
        skillReq = 0
	},

    skeletonCripple = {
		handler = "bonepiles",
        id = "NC_skeleton_weak_misc",
        description = strings.skeletonWeakDesc,
        ingredients = {
            { id = "AB_Misc_BoneSkelSkullNoJaw", count = 1 },
			{ id = "AB_Misc_Bone", count = 4 },
			{ id = "AB_Misc_BoneSkelTorsoBroken", count = 1 },
			{ id = "AB_Misc_BoneSkelArmL", count = 1 },
			{ id = "AB_Misc_BoneSkelLegL", count = 2 },
			{ id = "AB_Misc_BoneSkelPelvis", count = 1 }
        },
        skillReq = 10
    },
	
    skeletonWarrior = {
		handler = "bonepiles",
        id = "NC_skeleton_war_misc",
        description = strings.skeletonWarDesc,
        ingredients = {
            { id = "misc_skull00", count = 1 },
			{ id = "AB_Misc_Bone", count = 4 },
			{ id = "AB_Misc_BoneSkelTorso", count = 1 },
			{ id = "AB_Misc_BoneSkelArmL", count = 2 },
			{ id = "AB_Misc_BoneSkelLegL", count = 2 },
			{ id = "AB_Misc_BoneSkelPelvis", count = 1 }
        },
        skillReq = 40
    },
	
	skeletonChampion = {
		handler = "bonepiles",
        id = "NC_skeleton_champ_misc",
        description = strings.skeletonChampDesc,
        ingredients = {
            { id = "misc_skull00", count = 1 },
			{ id = "AB_Misc_Bone", count = 4 },
			{ id = "AB_Misc_BoneSkelTorso", count = 1 },
			{ id = "AB_Misc_BoneSkelArmL", count = 2 },
			{ id = "AB_Misc_BoneSkelLegL", count = 2 },
			{ id = "AB_Misc_BoneSkelPelvis", count = 1 }
        },
        skillReq = 70
    },
	
	bonespider = {
		handler = "bonepiles",
        id = "NC_bonespider_misc",
        description = strings.bonespiderDesc,
        ingredients = {
            { id = "misc_skull00", count = 1 },
			{ id = "AB_Misc_Bone", count = 6 },
			{ id = "AB_Misc_BoneSkelArmL", count = 2 },
        },
        skillReq = 5
    },
	
	bonelord = {
		handler = "bonepiles",
        id = "NC_bonelord_misc",
        description = strings.bonelordDesc,
        ingredients = {
            { id = "AB_Misc_BoneSkelSkullNoJaw", count = 1 },
			{ id = "AB_Misc_Bone", count = 4 },
			{ id = "AB_Misc_BoneSkelArmL", count = 4 },
			{ id = "misc_soulgem_common", count = 1 },
        },
        skillReq = 50
    },
	
	boneoverlord = {
		handler = "bonepiles",
        id = "NC_boneoverlord_misc",
        description = strings.bonelordDesc,
        ingredients = {
            { id = "AB_Misc_BoneSkelSkullNoJaw", count = 3 },
			{ id = "AB_Misc_Bone", count = 14 },
			{ id = "AB_Misc_BoneSkelArmL", count = 4 },
			{ id = "misc_soulgem_greater", count = 1 },
        },
        skillReq = 95
    },
	
	--[[shambles = {
		handler = "bonepiles",
        id = "NC_shambles_misc",
        description = strings.shamblesDesc,
        ingredients = {
            { id = "AB_Misc_BoneSkelSkullNoJaw", count = 2 },
			{ id = "AB_Misc_BoneSkelPelvis", count = 2 },
			{ id = "AB_Misc_Bone", count = 10 },
			{ id = "AB_Misc_BoneSkelArmL", count = 6 },
			{ id = "AB_Misc_BoneSkelTorso", count = 1 },
			{ id = "AB_Misc_BoneSkelTorsoBroken", count = 4 },
			{ id = "AB_Misc_BoneSkelLegL", count = 2 },
        },
        skillReq = 95
    },]]
}

this.corpses = {

	bonewalker1 = {
		handler = "corpses",
		image = "NecroCraft/bonewalker.dds",
        id = "NC_bonewalker_corpse",
        description = strings.bonewalkerDesc,
        ingredients = {
			{ id = "misc_soulgem_petty", count = 1 },
        },
        skillReq = 15
	},
	
	bonewalkerGreater1 = {
		handler = "corpses",
        id = "NC_bonewalkerG_corpse",
		image = "NecroCraft/GBonewalker.dds",
        description = strings.bonewalkerGreaterDesc,
        ingredients = {
			{ id = "misc_soulgem_lesser", count = 1 },
        },
        skillReq = 30
	},
	
		bonewalker2 = {
		handler = "corpses",
		image = "NecroCraft/bonewalker.dds",
        id = "NC_bonewalker_corpse",
        description = strings.bonewalkerDesc,
        ingredients = {
			{ id = "misc_soulgem_lesser", count = 1 },
        },
        skillReq = 15
	},
	
	bonewalkerGreater2 = {
		handler = "corpses",
        id = "NC_bonewalkerG_corpse",
		image = "NecroCraft/GBonewalker.dds",
        description = strings.bonewalkerGreaterDesc,
        ingredients = {
			{ id = "misc_soulgem_common", count = 1 },
        },
        skillReq = 30
	},
	
	bonewolf = {
		handler = "wolfCorpses",
		image = "NecroCraft/bonewolf.dds",
        id = "NC_bonewolf_corpse",
        description = strings.bonewalkerDesc,
		ingredients = {},
        skillReq = 40
	},
	
}

return this

