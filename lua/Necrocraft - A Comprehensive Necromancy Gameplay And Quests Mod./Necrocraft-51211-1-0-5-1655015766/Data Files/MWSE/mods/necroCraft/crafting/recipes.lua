local strings = require("NecroCraft.strings")

local recipes = {}

recipes.handler = "Humanoid"

recipes.bonepiles = {
	{
		id = "NC_skeleton_champ_misc",
		description = strings.skeletonChampDesc,
		category = strings.skeletons,
		previewScale = 1.3,
		previewHeight = -20,
		mesh = "NecroCraft\\skel.nif",
		materials = {
			{ material = "nc_skull", count = 1 },
			{ material = "AB_Misc_BoneSkelTorso", count = 1 },
			{ material = "nc_bone_arm", count = 2 },
			{ material = "nc_bone_leg", count = 2 },
			{ material = "AB_Misc_BoneSkelPelvis", count = 1 }
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 70 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},
	{
		id = "NC_skeleton_war_misc",
		mesh = "NecroCraft\\skel.nif",
		description = strings.skeletonWarDesc,
		category = strings.skeletons,
		previewScale = 1.3,
		previewHeight = -20,
		materials = {
			{ material = "nc_skull", count = 1 },
			{ material = "AB_Misc_BoneSkelTorso", count = 1 },
			{ material = "nc_bone_arm", count = 2 },
			{ material = "nc_bone_leg", count = 2 },
			{ material = "AB_Misc_BoneSkelPelvis", count = 1 }
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 40,}
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},
	{
		id = "NC_skeleton_weak_misc",
		mesh = "NecroCraft\\skel_weak.nif",
		description = strings.skeletonWeakDesc,
		category = strings.skeletons,
		previewScale = 1.3,
		previewHeight = -20,
		materials = {
			{ material = "nc_skull2", count = 1 },
			{ material = "AB_Misc_BoneSkelTorso", count = 1 },
			{ material = "nc_bone_arm", count = 1 },
			{ material = "nc_bone", count = 1 },
			{ material = "nc_bone_leg", count = 2 },
			{ material = "AB_Misc_BoneSkelPelvis", count = 1 }
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 10 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},
{
		id = "NC_boneoverlord_misc",
		mesh = "NecroCraft\\bonelord_2n.nif",
		description = strings.boneoverlordDesc,
		category = strings.boneconstructs,
		previewScale = 2,
		previewHeight = -150,
		materials = {
			{ material = "nc_skull2", count = 3 },
			{ material = "nc_bone_arm", count = 4 },
			{ material = "nc_soulgem2", count = 3 },
			{ material = "nc_bone", count = 8 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 95 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},
	{
		id = "NC_bonelord_misc",
		mesh = "NecroCraft\\bonelord_n.nif",
		description = strings.bonelordDesc,
		category = strings.boneconstructs,
		previewScale = 2,
		previewHeight = -150,
		materials = {
			{ material = "nc_skull2", count = 1 },
			{ material = "nc_bone_arm", count = 4 },
			{ material = "nc_soulgem2", count = 1 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 50 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},
	{
		id = "NC_bonespider_misc",
		previewScale = 1.2,
		previewHeight = 50,
		mesh = "NecroCraft\\bone_spider.nif",
		description = strings.bonespiderDesc,
		category = strings.boneconstructs,
		materials = {
			{ material = "nc_skull", count = 1 },
			{ material = "nc_bone_arm", count = 2 },
			{ material = "nc_bone", count = 4 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},

	{
		id = "AB_Misc_BoneSkelArmL",
		previewScale = 1.2,
		--previewHeight = 50,
		rotationAxis = "-y",
		description = strings.bonearm,
		category = strings.boneparts,
		materials = {
			{ material = "AB_Misc_BoneSkelHandL", count = 1 },
			{ material = "AB_Misc_BoneSkelArmWristL", count = 1 },
			{ material = "nc_bone", count = 1 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},

	{
		id = "AB_Misc_BoneSkelArmR",
		previewScale = 1.2,
		--previewHeight = 50,
		rotationAxis = "-y",
		description = strings.bonearm,
		category = strings.boneparts,
		materials = {
			{ material = "AB_Misc_BoneSkelHandR", count = 1 },
			{ material = "AB_Misc_BoneSkelArmWristR", count = 1 },
			{ material = "nc_bone", count = 1 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},

	{
		id = "AB_Misc_BoneSkelLegR",
		previewScale = 1.2,
		--previewHeight = 50,
		rotationAxis = "-y",
		description = strings.boneleg,
		category = strings.boneparts,
		materials = {
			{ material = "AB_Misc_BoneSkelFootR", count = 1 },
			{ material = "AB_Misc_BoneSkelLegShinR", count = 1 },
			{ material = "nc_bone", count = 1 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},

	{
		id = "AB_Misc_BoneSkelLegL",
		previewScale = 1.2,
		--previewHeight = 50,
		rotationAxis = "-y",
		description = strings.boneleg,
		category = strings.boneparts,
		materials = {
			{ material = "AB_Misc_BoneSkelFootL", count = 1 },
			{ material = "AB_Misc_BoneSkelLegShinL", count = 1 },
			{ material = "nc_bone", count = 1 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},

	{
		id = "misc_skull00",
		--previewHeight = 50,
		previewScale = 0.8,
		description = strings.boneskull,
		category = strings.boneparts,
		materials = {
			{ material = "AB_Misc_BoneSkelSkullNoJaw", count = 1 },
			{ material = "AB_Misc_BoneSkelSkullJaw", count = 1 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},

	{
		id = "AB_Misc_BoneSkelTorso",
		previewScale = 1.2,
		--previewHeight = 50,
		rotationAxis = "-y",
		description = strings.boneribs,
		category = strings.boneparts,
		materials = {
			{ material = "AB_Misc_BoneSkelTorsoBroken", count = 2 },
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
	},
}

recipes.corpses = {
	{
		id = "NC_zombie_corpse",
		description = strings.zombieDesc,
		materials = {},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
		previewScale = 2,
		previewHeight = -65,
		category = strings.humanoids,
		customRequirements = {
			{
				getLabel = function ()
					return "Humanoid Corpse"
				end,
				check = function ()
					return recipes.handler == "Humanoid"
				end
			}
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 5 }
		},
		craftCallback = function() event.trigger("Necrocraft:CorpsePrepared") end,
		destroyCallback = function() event.trigger("Necrocraft:CorpseDestroyed") end
	},
	{
		id = "NC_bonewalker_corpse",
		description = strings.bonewalkerDesc,
		materials = {
			{ material = "nc_soulgem1", count = 1 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
		previewScale = 2,
		previewHeight = 20,
		category = strings.humanoids,
		customRequirements = {
			{
				getLabel = function ()
					return "Humanoid Corpse"
				end,
				check = function ()
					return recipes.handler == "Humanoid"
				end
			}
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 25 }
		},
		craftCallback = function() event.trigger("Necrocraft:CorpsePrepared") end,
		destroyCallback = function() event.trigger("Necrocraft:CorpseDestroyed") end
	},
	{
		id = "NC_bonewalkerG_corpse",
		description = strings.bonewalkerGreaterDesc,
		materials = {
			{ material = "nc_soulgem2", count = 1 }
		},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
		previewScale = 2,
		previewHeight = 90,
		category = strings.humanoids,
		customRequirements = {
			{
				getLabel = function ()
					return "Humanoid Corpse"
				end,
				check = function ()
					return recipes.handler == "Humanoid"
				end
			}
		},
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 45 }
		},
		craftCallback = function() event.trigger("Necrocraft:CorpsePrepared") end,
		destroyCallback = function() event.trigger("Necrocraft:CorpseDestroyed") end
	},
	{
		id = "NC_bonewolf_corpse",
		description = strings.bonewolf,
		materials = {},
		knownByDefault = true, --if false, checks `tes3.player.data.craftingFramework.recipes["alchemyTable_misc"].known`
		previewScale = 3,
		--previewHeight = 90,
		customRequirements = {
			{
				getLabel = function ()
					return "Wolf Corpse"
				end,
				check = function ()
					return recipes.handler == "Wolf"
				end
			}
		},
		category = strings.animals,
		skillRequirements = {
			{ skill = "NC:CorpsePreparation", requirement = 50 }
		},
		craftCallback = function() event.trigger("Necrocraft:CorpsePrepared") end,
		--destroyCallback = function() event.trigger("Necrocraft:CorpseDestroyed") end
	}
}

return recipes