local M = {

	["g_centurionspider.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["centurion_spider_miner.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["centurion_spider_tower.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["sphere_centurions.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["spherearcher.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["steam_centurions.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["centurion_mace.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["centurion_sword.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["centurion_tank.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["centurion_weapon.nif"] = { hit="Parry", dmg="DmgDwemer" },
--	["fabricant_imperfect.nif"] = { hit="Parry", dmg="DmgDwemer" },

	["cavemudcrab.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
	["mudcrab_king.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
	["mudcrab_titan.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
	["mudcrab_rock.nif"] = { hit="ParryArmorBone", dmg="Dmg" },

	["spriggan.nif"] = { hit="ParryArmorBone", dmg="Dmg" },

	["bonelord.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["liche.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["liche_king.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["lich_elder.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_weak.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_archer.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_warrior.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_champion.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_knight.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_nord.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_pirate.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_pirate_captain.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_berserk.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_mage.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },

	["atronach_fire.nif"] = { hit="HitFire", dmg = "DmgFire" },
	["atronach_frost.nif"] = { hit="HitFrost", dmg = "DmgFrost" },
	["atronach_storm.nif"] = { hit="Parry", dmg="Stone" },
	["atronach_flame_lord.nif"] = { hit="HitFire", dmg = "DmgFire" },
	["atronach_frost_lord.nif"] = { hit="HitFrost", dmg = "DmgFrost" },
	["atronach_storm_lord.nif"] = { hit="Parry", dmg="Stone" },
	["dremora.nif"] = { hit="ParryArmorHeavy", dmg="DmgGhost" },
	["golden saint.nif"] = { hit="ParryArmorHeavy", dmg="Dmg" },

	["dremora_lord.nif"] = { hit="ParryArmorHeavy", dmg="DmgGhost" },
	["dremora_mage.nif"] = { dmg="DmgGhost" },
	["dremora_archer.nif"] = { hit="ParryArmorMedium", dmg="DmgGhost" },


	--	TR
	["tr_dwemer.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["tr_dwe_colos_01.nif"] = { hit="Parry", dmg="DmgDwemer" },

	["tr_seacrab.nif"] = { hit="ParryArmorBone", dmg="Dmg"},

	["tr_liche_greater.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_arg_01.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_arg_02.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_arise01.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_arise02.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_arise03.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_arise04.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_khajiit.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["tr_skeleton_orc.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },

	["tr_dremora.nif"] = { hit="ParryArmorHeavy", dmg="DmgGhost" },
	["tr_dremora_caster.nif"] = { dmg="DmgGhost" },
	["tr_dremora_archer.nif"] = { hit="ParryArmorMedium", dmg="DmgGhost" },
	["tr_storm_tyrant.nif"] = { hit="Parry", dmg="Stone" },

	["sky_skeleton_crip_01.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },

	["pc_auroran.nif"] = { hit="Parry", dmg="DmgDwemer" },
	["pc_remanskel_01.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["pc_remanskel_02.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["pc_remanskel_03.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["pc_remanskel_04.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["pc_skeleton_imp01.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["pc_skeleton_imp02.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["pc_spriggan.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
--[[
	["pc_ghost_01.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
	["pc_ghost_02.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
	["pc_wraith_01.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
	["pc_wraith_02.nif"] = { hit="ParryArmorBone", dmg="Dmg" },
--]]

	--	OAAB
	["cent_sphere_chute.nif"] = { hit="Parry", dmg="DmgDwemer" },

	["liche_ancient.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["liche_ancient2.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_arg01.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_arg00.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },
	["skeleton_arg02.nif"] = { hit="HitSkeleton", dmg="DmgSkeleton" },

	["zombiefresh.nif"] = { hit="Hit", dmg="Dmg"},
	["zombiefresh2.nif"] = { hit="Hit", dmg="Dmg"},
	["zombiefresh3.nif"] = { hit="Hit", dmg="Dmg"},

	["ironatronach.nif"] = { hit="Parry", dmg = "Metal" },
	["atro_storm_monarch.nif"] = { hit="Parry", dmg="Stone" },

	}

return M
