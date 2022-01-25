this = {}

this.config = mwse.loadConfig("Power Fantasy", {
	knockdownVars = 100,
	knockDownLimit = 6,
	NPCdash = true,
	dashKey = {keyCode = 56},
	creaPerks = true,
	spellProjWiggle = true,
	critSound = true,
	comboMsg = true,
	NPCpowerMsg = true
})

-- MAIN
-------
-- way to check modules; set true, if corresponding esps are active on main.initialized
this.rbs = false
this.skills = false

this.spellBlacklist = {
	["assured balanced armor"] = true,
	["assured deep biting"] = true,
	["assured denial"] = true,
	["assured enterprise"] = true,
	["assured fleetness"] = true,
	["assured fluid evasion"] = true,
	["assured glib speech"] = true,
	["assured hewing"] = true,
	["assured horny fist"] = true,
	["assured impaling thrust"] = true,
	["assured leaping"] = true,
	["assured martial craft"] = true,
	["assured nimble armor"] = true,
	["assured golden wisdom"] = true,
	["assured green wisdom"] = true,
	["assured red wisdom"] = true,
	["assured safekeeping"] = true,
	["assured silver wisdom"] = true,
	["assured smiting"] = true,
	["assured stalking"] = true,
	["assured stolid armor"] = true,
	["assured sublime wisdom"] = true,
	["assured sureflight"] = true,
	["assured swiftblade"] = true,
	["assured transcendant wisdom"] = true,
	["assured transfiguring wisdom"] = true,
	["assured unseen wisdom"] = true,
	["calm creature"] = true,
	["demoralize beast"] = true,
	["demoralize creature"] = true,
	["drain acrobatics"] = true,
	["drain alchemy"] = true,
	["drain alteration"] = true,
	["drain athletics"] = true,
	["drain axe"] = true,
	["drain armorer"] = true,
	["drain block"] = true,
	["drain blunt weapon"] = true,
	["drain conjuration"] = true,
	["drain destruction"] = true,
	["drain enchant"] = true,
	["drain heavy armor"] = true,
	["drain illusion"] = true,
	["drain hand to hand"] = true,
	["drain light armor"] = true,
	["drain long blade"] = true,
	["drain marksman"] = true,
	["drain medium armor"] = true,
	["drain mercantile"] = true,
	["drain mysticism"] = true,
	["drain restoration"] = true,
	["drain short blade"] = true,
	["drain security"] = true,
	["drain sneak"] = true,
	["drain spear"] = true,
	["drain speechcraft"] = true,
	["drain unarmored"] = true,
	["dynamic balanced armor"] = true,
	["dynamic deep biting"] = true,
	["dynamic denial"] = true,
	["dynamic enterprise"] = true,
	["dynamic fleetness"] = true,
	["dynamic fluid evasion"] = true,
	["dynamic glib speech"] = true,
	["dynamic hewing"] = true,
	["dynamic horny fist"] = true,
	["dynamic impaling thrust"] = true,
	["dynamic leaping"] = true,
	["dynamic martial craft"] = true,
	["dynamic nimble armor"] = true,
	["dynamic golden wisdom"] = true,
	["dynamic green wisdom"] = true,
	["dynamic red wisdom"] = true,
	["dynamic safekeeping"] = true,
	["dynamic silver wisdom"] = true,
	["dynamic smiting"] = true,
	["dynamic stalking"] = true,
	["dynamic stolid armor"] = true,
	["dynamic sublime wisdom"] = true,
	["dynamic sureflight"] = true,
	["dynamic swiftblade"] = true,
	["dynamic transcendant wisdom"] = true,
	["dynamic transfiguring wisdom"] = true,
	["dynamic unseen wisdom"] = true,
	["far silence"] = true,
	["fortify acrobatics skill"] = true,
	["fortify alchemy skill"] = true,
	["fortify athletics skill"] = true,
	["fortify armorer skill"] = true,
	["fortify alteration skill"] = true,
	["fortify axe skill"] = true,
	["fortify block skill"] = true,
	["fortify blunt weapon skill"] = true,
	["fortify conjuration skill"] = true,
	["fortify destruction skill"] = true,
	["fortify enchant skill"] = true,
	["fortify hand to hand skill"] = true,
	["fortify heavy armor skill"] = true,
	["fortify light armor skill"] = true,
	["fortify long blade skill"] = true,
	["fortify medium armor skill"] = true,
	["fortify marksman skill"] = true,
	["fortify mercantile skill"] = true,
	["fortify mysticism skill"] = true,
	["fortify restoration skill"] = true,
	["fortify security skill"] = true,
	["fortify short blade skill"] = true,
	["fortify sneak skill"] = true,
	["fortify spear skill"] = true,
	["fortify speechcraft skill"] = true,
	["fortify unarmored skill"] = true,
	["imperial acrobatics skill"] = true,
	["imperial alchemy skill"] = true,
	["imperial athletics skill"] = true,
	["imperial armorer skill"] = true,
	["imperial alteration skill"] = true,
	["imperial axe skill"] = true,
	["imperial block skill"] = true,
	["imperial blunt weapon skill"] = true,
	["imperial conjuration skill"] = true,
	["imperial destruction skill"] = true,
	["imperial enchant skill"] = true,
	["imperial hand to hand skill"] = true,
	["imperial heavy armor skill"] = true,
	["imperial light armor skill"] = true,
	["imperial long blade skill"] = true,
	["imperial medium armor skill"] = true,
	["imperial marksman skill"] = true,
	["imperial mercantile skill"] = true,
	["imperial mysticism skill"] = true,
	["imperial restoration skill"] = true,
	["imperial security skill"] = true,
	["imperial short blade skill"] = true,
	["imperial sneak skill"] = true,
	["imperial spear skill"] = true,
	["imperial speechcraft skill"] = true,
	["imperial unarmored skill"] = true,
	["frenzy beast"] = true,
	["frenzy creature"] = true,
	["masteful red wisdom"] = true,
	["masteful stolid armor"] = true,
	["masterful balanced armor"] = true,
	["masterful deep biting"] = true,
	["masterful denial"] = true,
	["masterful enterprise"] = true,
	["masterful fleetness"] = true,
	["masterful fluid evasion"] = true,
	["masterful glib speech"] = true,
	["masterful hewing"] = true,
	["masterful horny fist"] = true,
	["masterful impaling thrust"] = true,
	["masterful leaping"] = true,
	["masterful martial craft"] = true,
	["masterful nimble armor"] = true,
	["masterful golden wisdom"] = true,
	["masterful green wisdom"] = true,
	["masterful red wisdom"] = true,
	["masterful safekeeping"] = true,
	["masterful silver wisdom"] = true,
	["masterful smiting"] = true,
	["masterful stalking"] = true,
	["masterful stolid armor"] = true,
	["masterful sublime wisdom"] = true,
	["masterful sureflight"] = true,
	["masterful swiftblade"] = true,
	["masterful transcendant wisdom"] = true,
	["masterful transfiguring wisdom"] = true,
	["masterful unseen wisdom"] = true,
	["rally beast"] = true,
	["rally creature"] = true,
	["silence"] = true,
	["soothe the savage beast"] = true,
	["surpassing balanced armor"] = true,
	["surpassing deep biting"] = true,
	["surpassing denial"] = true,
	["surpassing enterprise"] = true,
	["surpassing fleetness"] = true,
	["surpassing fluid evasion"] = true,
	["surpassing glib speech"] = true,
	["surpassing hewing"] = true,
	["surpassing horny fist"] = true,
	["surpassing impaling thrust"] = true,
	["surpassing leaping"] = true,
	["surpassing martial craft"] = true,
	["surpassing nimble armor"] = true,
	["surpassing golden wisdom"] = true,
	["surpassing green wisdom"] = true,
	["surpassing red wisdom"] = true,
	["surpassing safekeeping"] = true,
	["surpassing silver wisdom"] = true,
	["surpassing smiting"] = true,
	["surpassing stalking"] = true,
	["surpassing stolid armor"] = true,
	["surpassing sublime wisdom"] = true,
	["surpassing sureflight"] = true,
	["surpassing swiftblade"] = true,
	["surpassing transcendant wisdom"] = true,
	["surpassing transfiguring wisdom"] = true,
	["touchdrain acrobatics"] = true,
	["touchdrain alchemy"] = true,
	["touchdrain athletics"] = true,
	["touchdrain armorer"] = true,
	["touchdrain alteration"] = true,
	["touchdrain axe"] = true,
	["touchdrain block"] = true,
	["touchdrain blunt weapon"] = true,
	["touchdrain conjuration"] = true,
	["touchdrain destruction"] = true,
	["touchdrain enchant"] = true,
	["touchdrain hand to hand"] = true,
	["touchdrain heavy armor"] = true,
	["touchdrain light armor"] = true,
	["touchdrain long blade"] = true,
	["touchdrain medium armor"] = true,
	["touchdrain marksman"] = true,
	["touchdrain mercantile"] = true,
	["touchdrain mysticism"] = true,
	["touchdrain restoration"] = true,
	["touchdrain security"] = true,
	["touchdrain short blade"] = true,
	["touchdrain sneak"] = true,
	["touchdrain spear"] = true,
	["touchdrain speechcraft"] = true,
	["touchdrain unarmored"] = true,
	["wild fortify acrobatics skill"] = true,
	["wild fortify alchemy skill"] = true,
	["wild fortify athletics skill"] = true,
	["wild fortify armorer skill"] = true,
	["wild fortify alteration skill"] = true,
	["wild fortify axe skill"] = true,
	["wild fortify block skill"] = true,
	["wild fortify blunt weapon skill"] = true,
	["wild fortify conjuration skill"] = true,
	["wild fortify destruction skill"] = true,
	["wild fortify enchant skill"] = true,
	["wild fortify hand to hand skill"] = true,
	["wild fortify heavy armor skill"] = true,
	["wild fortify light armor skill"] = true,
	["wild fortify long blade skill"] = true,
	["wild fortify medium armor skill"] = true,
	["wild fortify marksman skill"] = true,
	["wild fortify mercantile skill"] = true,
	["wild fortify mysticism skill"] = true,
	["wild fortify restoration skill"] = true,
	["wild fortify security skill"] = true,
	["wild fortify short blade skill"] = true,
	["wild fortify sneak skill"] = true,
	["wild fortify spear skill"] = true,
	["wild fortify speechcraft skill"] = true,
	["wild fortify unarmored skill"] = true
}

this.npcData = {
	["Lady"] = {
		[1] = {
			["Alchemist"] = true,
			["Alchemist Service"] = true,
			["Bookseller"] = true,
			["Clothier"] = true,
			["Commoner"] = true,
			["Gardener"] = true,
			["Merchant"] = true,
			["Monk"] = true,
			["Monk Service"] = true,
			["Pawnbroker"] = true,
			["Trader"] = true,
			["Trader Service"] = true
		},
		[2] = {
			["_neph_bs_lad_pssvFervor"] = true,
			["_neph_bs_lad_pssvWisdom"] = true,
			["_neph_bs_lad_pwGift"] = true
		},
		[3] = "_neph_bs_lad_pwGift"
	},
	["Thief"] = {
		[1] = {
			["Acrobat"] = true,
			["Caretaker"] = true,
			["Dreamers"] = true,
			["Hunter"] = true,
			["Rogue"] = true,
			["Savant"] = true,
			["Savant Service"] = true,
			["Sharpshooter"] = true,
			["Thief"] = true,
			["Thief Service"] = true
		},
		[2] = {
			["_neph_bs_thi_pssvPockets"] = true
		},
		[3] = nil
	},
	["Shadow"] = {
		[1] = {
			["Agent"] = true,
			["Assassin"] = true,
			["Assassin Service"] = true,
			["Buoyant Armiger"] = true,
			["Enforcer"] = true,
			["Pauper"] = true
		},
		[2] = {
			["_neph_bs_sha_pssvMoonshadow"] = true,
			["_neph_bs_sha_pwShroud"] = true
		},
		[3] = "_neph_bs_sha_pwShroud"
	},
	["Lover"] = {
		[1] = {
			["Apothecary"] = true,
			["Apothecary Service"] = true,
			["Mabrigash"] = true,
			["Ordinator"] = true,
			["Ordinator Guard"] = true,
			["Queen Mother"] = true,
			["Journalist"] = true,
			["Noble"] = true
		},
		[2] = {
			["_neph_bs_lov_pssvMooncalf"] = true
		},
		[3] = nil
	},
	["Serpent"] = {
		[1] = {
			["Archer"] = true,
			["Smuggler"] = true,
			["Nightblade"] = true,
			["Nightblade Service"] = true
		},
		[2] = {
			["_neph_bs_ser_pssvStarCurse"] = true,
			["_neph_bs_ser_pwFangs"] = true
		},
		[3] = "_neph_bs_ser_pwFangs"
	},
	["Steed"] = {
		[1] = {
			["Barbarian"] = true,
			["Farmer"] = true,
			["Herder"] = true,
			["Scout"] = true,
			["Slave"] = true
		},
		[2] = {
			["_neph_bs_ste_pssvCharioteer"] = true,
			["_neph_bs_ste_pwTrample"] = true
		},
		[3] = "_neph_bs_ste_pwTrample"
	},
	["Tower"] = {
		[1] = {
			["Bard"] = true,
			["Caravaner"] = true,
			["Gondolier"] = true,
			["Miner"] = true,
			["Pilgrim"] = true,
			["Publican"] = true,
			["Shipmaster"] = true
		},
		[2] = {
			["_neph_bs_tow_pssvFortification"] = true
		},
		[3] = nil
	},
	["Atronach"] = {
		[1] = {
			["Battlemage"] = true,
			["Battlemage Service"] = true,
			["Priest"] = true,
			["Priest Service"] = true,
			["Spellsword"] = true,
			["Wise Woman"] = true,
			["Wise Woman Service"] = true
		},  
		[2] = {
			["_neph_bs_atr_pssvWombburn"] = true,
			["_neph_bs_atr_pwOverload"] = true
		},
		[3] = "_neph_bs_atr_pwOverload"
	},
	["Warrior"] = {
		[1] = {
			["Champion"] = true,
			["Drillmaster"] = true,
			["Drillmaster Service"] = true,
			["Guard"] = true,
			["Warrior"] = true
		},
		[2] = {
			["_neph_bs_war_pssvWarwyrd"] = true,
			["_neph_bs_war_pwMight"] = true
		},
		[3] = "_neph_bs_war_pwMight"
	},
	["Lord"] = {
		[1] = {
			["Crusader"] = true,
			["King"] = true,
			["Knight"] = true,
			["Master-at-Arms"] = true,
			["Smith"] = true
		},
		[2] = {
			["_neph_bs_lor_pssvTrollkin"] = true,
			["_neph_bs_lor_pwGuardian"] = true
		},
		[3] = "_neph_bs_lor_pwGuardian"
	},
	["Apprentice"] = {
		[1] = {
			["Enchanter"] = true,
			["Enchanter Service"] = true,
			["Mage"] = true,
			["Mage Service"] = true
		},
		[2] = {
			["_neph_bs_app_pssvElfborn"] = true,
			["_neph_bs_app_pwZeal"] = true
		},
		[3] = "_neph_bs_app_pwZeal"
	},
	["Mage"] = {
		[1] = {
			["Guild Guide"] = true,
			["Healer Service"] = true,
			["Healer"] = true,
			["Warlock"] = true
		},
		[2] = {
			["_neph_bs_mag_pssvFay"] = true,
			["_neph_bs_mag_pwSurge"] = true
		},
		[3] = "_neph_bs_mag_pwSurge"
	},
	["Ritual"] = {
		[1] = {
			["Necromancer"] = true,
			["Shaman"] = true,
			["Sorcerer Service"] = true,
			["Sorcerer"] = true,
			["Witch"] = true,
			["Witchhunter"] = true
		},
		[2] = {
			["_neph_bs_rit_pssvMarasGift"] = true,
			["_neph_bs_rit_pwMark"] = true
		},
		[3] = "_neph_bs_rit_pwMark"
	}
}

this.armorArray = {
	[0] = true,	-- Helmet
	[1] = true,	-- Cuirass
	[2] = true,	-- Left Pauldron
	[3] = true,	-- Right Pauldron
	[4] = true,	-- Greaves
	[5] = true,	-- Boots
	[6] = true,	-- Left Gauntlet
	[7] = true,	-- Right Gauntlet
	[8] = true,	-- Shield
	[9] = true,	-- Left Bracer
	[10] = true	-- Right Bracer
}

this.racePowers = {
	["redguard"]	= "_neph_race_rg_pwAdrenaline",
	["wood elf"]	= "_neph_race_we_pwTongue",
	["argonian"]	= "_neph_race_ar_pwHistCall",
	["breton"]		= "_neph_race_br_pwDragonSkin",
	["high elf"]	= "_neph_race_he_pwRush",
	["imperial"]	= "_neph_race_im_pwVoiceEmp",
	["nord"]		= "_neph_race_no_pwBattleCry",
	["orc"]			= "_neph_race_or_pwBerserk"
	-- Khajiit has Skooma (resource-based "Power")
	-- Dark Elf handled separately
}

this.bsPowers = {	--	power						signature ability
	["Thief"]		= {"_neph_bs_thi_pwHeist",		"_neph_bs_thi_pssvPockets"},
	["Tower"]		= {"_neph_bs_tow_pwKey",		"_neph_bs_tow_pssvFortification"},
	["Warrior"]		= {"_neph_bs_war_pwMight",		"_neph_bs_war_pssvWarwyrd"},
	["Steed"]		= {"_neph_bs_lov_pwTrample",	"_neph_bs_ste_pssvCharioteer"},
	["Atronach"]	= {"_neph_bs_atr_pwOverload",	"_neph_bs_atr_pssvWombburn"},
	["Lady"]		= {"_neph_bs_lad_pwGift",		"_neph_bs_lad_pssvWisdom"},
	["Lover"]		= {"_neph_bs_lov_pwPresence",	"_neph_bs_lov_pssvMooncalf"},
	["Shadow"]		= {"_neph_bs_sha_pwShroud",		"_neph_bs_sha_pssvMoonshadow"},
	["Serpent"]		= {"_neph_bs_ser_pwFangs",		"_neph_bs_ser_pssvStarCurse"},
	["Lord"]		= {"_neph_bs_lor_pwGuardian",	"_neph_bs_lor_pssvTrollkin"},
	["Mage"]		= {"_neph_bs_mag_pwSurge",		"_neph_bs_mag_pssvFay"},
	["Apprentice"]	= {"_neph_bs_app_pwZeal",		"_neph_bs_app_pssvElfborn"},
	["Ritual"]		= {"_neph_bs_rit_pwMark",		"_neph_bs_rit_pssvMarasGift"}
}

this.creaSpells = {
	["scamp"] = {
		["_neph_crea_scamp_fire"] = true
	},
	["lustidrike"] = {
		["_neph_crea_scamp_fire"] = true
	},
	["winged twilight"] = {
		["_neph_crea_twilight_Screech"] = true
	},
	["cliff racer"] = {
		["_neph_crea_cRacer_Spit"] = true
	},
	["atronach_flame"] = {
		["_neph_crea_flameAtro_Cloak"] = true
	},
	["atronach_frost"] = {
		["_neph_crea_frostAtro_Cloak"] = true
	},
	["atronach_storm"] = {
		["_neph_crea_stormAtro_Cloak"] = true
	},
	["fabricant"] = {
		["regenerate [ability]"] = true
	},
	["spriggan"] = {
		["_neph_crea_spriggan_Absorb"] = true
	},
	["daedroth"] = {
		["_neph_crea_daedroth_Dispel"] = true,
		["summon clanfear"] = true
	},
	["golden saint"] = {
		["_neph_crea_gSaint_attackAb"] = true,
		["regenerate"] = true
	},
	["lich"] = {
		["fourth barrier"] = true,
		["summon skeletal minion"] = true
	},
	["bonelord"] = {
		["third barrier"] = true,
		["summon skeletal minion"] = true
	},
	["dagoth_ur"] = {
		["fifth barrier"] = true,
		["_neph_crea_god_healing"] = true
	},
	["vivec_god"] = {
		["fifth barrier"] = true,
		["_neph_crea_god_healing"] = true
	},
	["almalexia"] = {
		["fifth barrier"] = true
	}
}

this.creaLists = {
	[78] = {	-- Frost on hit
		["ancestor"] = true,
		["wraith"] = true,
		["haunt"] = true,
		["spectre"] = true,
		["mezalf"] = true,
		["lich"] = true,
		["bonelord"] = true,
		["atronach_frost"] = true
	},
	[79] = {	-- knockdown on hit
		["fabricant"] = true,
		["hircine"] = true,
		["ogrim"] = true,
		["troll"] = true,
		["frost_giant"] = true,
		["udyrfrykte"] = true,
		["centurion_Mudan"] = true,
		["centurion_steam"] = true,
		["centurion_sphere"] = true,
		["alit"] = true,
		["kagouti"] = true,
		["guar"] = true,
		["clannfear"] = true,
		["durzog"] = true,
		["bear"] = true,
		["boar"] = true,
		["boarmaster"] = true,
		["mounted"] = true
	},
	[80] = {	-- weaken on hit
		["ash"] = true,
		["ancestor"] = true,
		["wraith"] = true,
		["haunt"] = true,
		["spectre"] = true,
		["mezalf"] = true,
		["lich"] = true,
		["bonelord"] = true,
		-- ash vampires
		["araynys"] = true,
		["endus"] = true,
		["gilvoth"] = true,
		["odros"] = true,
		["Tureynul"] = true,
		["uthol"] = true,
		["vemyn"] = true,
		-- ash ghouls
		["fovon"] = true,
		["baler"] = true,
		["girer"] = true,
		["daynil"] = true,
		["ienas"] = true,
		["delnus"] = true,
		["mendras"] = true,
		["drals"] = true,
		["Draven"] = true,
		["muthes"] = true,
		["elam"] = true,
		["nilor"] = true,
		["fervas"] = true,
		["ralas"] = true,
		["soler"] = true,
		["fals"] = true,
		["galmis"] = true,
		["gares"] = true,
		-- found nowhere in vanilla, but might be added by mods:
		["aladus"] = true,
		["mulis"] = true,
		["velos"] = true
	},
	[81] = {	-- bleeding on hit
		["dreugh"] = true,
		["nix-hound"] = true,
		["slaughterfish"] = true,
		["fabricant"] = true,
		["wolf"] = true,	-- includes bonewolf
		["horker"] = true,
		["bear"] = true,
		["boar"] = true, 	-- includes boarmaster
		["mounted"] = true,
		["hircine"] = true,
		["araynys"] = true,
		["endus"] = true,
		["gilvoth"] = true,
		["odros"] = true,
		["Tureynul"] = true,
		["uthol"] = true,
		["vemyn"] = true
	},
	[82] = {	-- poison on hit
		["kwama warrior"] = true,
		["kwama forager"] = true,
		["cliff racer"] = true,
		["hunger"] = true,
		["netch"] = true
	},
	[83] = {	-- extra spell crit chance
		["fandril"] = true,
		["molos"] = true,
		["felmis"] = true,
		["rather"] = true,
		["garel"] = true,
		["reler"] = true,
		["goral"] = true,
		["tanis"] = true,
		["hlevul"] = true,
		["uvil"] = true,
		["malan"] = true,
		["vaner"] = true,
		["ulen"] = true,
		["irvyn"] = true,
		["ascended_sleeper"] = true,
		["daedroth"] = true,
		["atronach"] = true
	},
	[84] = {	-- ascended sleeper aura
		["fandril"] = true,
		["molos"] = true,
		["felmis"] = true,
		["rather"] = true,
		["garel"] = true,
		["reler"] = true,
		["goral"] = true,
		["tanis"] = true,
		["hlevul"] = true,
		["uvil"] = true,
		["malan"] = true,
		["vaner"] = true,
		["ulen"] = true,
		["irvyn"] = true,
		["ascended_sleeper"] = true
	}
}

this.tenaciousCreatures = {
	["dagoth_ur"] = true,
	["vivec"] = true,
	["almalexia"] = true,
	["hircine"] = true,
	["frost_giant"] = true,
	["udyrfrykte"] = true,
	["troll"] = true,
	["ogrim"] = true
}

this.skeletonCreatures = {
	["wolf_bone"] = true,
	["wolf_skeleton"] = true,
	["skeleton"] = true,
	["worm lord"] = true,
	["bonelord"] = true,
	["lich"] = true
}

this.creaArmor = {
	["crab"] = 30,
	["atronach"] = 20,
	["dremora"] = 25,
	["centurion"] = 25,
	["imperfect"] = 25,
	["kwama queen"] = 20,
	["kwama worker"] = 20,
	["kwama warrior"] = 20,
	["fabricant"] = 20,
	["goblin"] = 20,
	["riekling"] = 20,
	["daedroth"] = 15,
	["spriggan"] = 15,
	["alit"] = 15,
	["kagouti"] = 15,
	["guar"] = 15
}

this.GMST = {
	["fEnchantmentChanceMult"]			= 0.3,
	["fEnchantmentMult"]				= 0.065,
	["iSoulAmountForConstantEffect"]	= 500,
	["fMagicItemRechargePerSecond"]		= 0,
	["fDamageStrengthBase"]				= 1,
	["fDamageStrengthMult"]				= 0,
	["fDispWeaponDrawn"]				= -10,
	["fNPCbaseMagickaMult"]				= 1,
	["fElementalShieldMult"]			= 1,
	["fProjectileMaxSpeed"]				= 4000,
	["fProjectileMinSpeed"]				= 1000,
	["fTargetSpellMaxSpeed"]			= 2000,
	["fThrownWeaponMaxSpeed"]			= 2000,
	["fThrownWeaponMinSpeed"]			= 1000,
	["fCombatCriticalStrikeMult"]		= 1,
	["sTargetCriticalStrike"]			= "",
	["sEffectCalmHumanoid"]				= "Calm",
	["sEffectFrenzyHumanoid"]			= "Frenzy",
	["sEffectDemoralizeHumanoid"]		= "Demoralize",
	["sEffectRallyHumanoid"]			= "Rally",
	["sEffectSound"]					= "Noise",
	["sEffectReflect"]					= "Reflect Magic",
	["sEffectDetectAnimal"]				= "Detect Life"
}

this.magicSchool = {-- [ID] = {school change, icon, big icon}
-- commented out effects, which are somehow bugged (no clue why...)
	[0]		= {4,	"pwrFntsy\\tx_s_water_breath.dds",		"pwrFntsy\\b_tx_s_water_breath.dds"},		-- Waterbreathing
	[1]		= {4,	"pwrFntsy\\tx_s_swiftswim.dds",			"pwrFntsy\\b_tx_s_swiftswim.dds"},			-- Swift Swim
	[2]		= {4,	"pwrFntsy\\tx_s_water_walk.dds",		"pwrFntsy\\b_tx_s_water_walk.dds"},			-- Waterwalking
	[3]		= {nil,	"pwrFntsy\\tx_s_shield.dds",			"pwrFntsy\\b_tx_s_shield.dds"},				-- Shield
	[4]		= {0,	"pwrFntsy\\tx_s_fire_shield.dds",		"pwrFntsy\\b_tx_s_fire_shield.dds"},		-- Fire Shield
	[5]		= {nil,	"pwrFntsy\\tx_s_light_shield.dds",		"pwrFntsy\\b_tx_s_light_shield.dds"},		-- Lightning Shield
	[6]		= {nil,	"pwrFntsy\\tx_s_frost_shield.dds",		"pwrFntsy\\b_tx_s_frost_shield.dds"},		-- Frost Shield
	[7]		= {2,	"pwrFntsy\\tx_s_burden.dds",			"pwrFntsy\\b_tx_s_burden.dds"},				-- Burden
	[8]		= {nil,	"pwrFntsy\\tx_s_feather.dds",			"pwrFntsy\\b_tx_s_feather.dds"},			-- Feather
	[9]		= {4,	"pwrFntsy\\tx_s_jump.dds",				"pwrFntsy\\b_tx_s_jump.dds"},				-- Jump
	[10]	= {4,	"pwrFntsy\\tx_s_levitate.dds",			"pwrFntsy\\b_tx_s_levitate.dds"},			-- Levitate
	[11]	= {4,	"pwrFntsy\\tx_s_slowfall.dds",			"pwrFntsy\\b_tx_s_slowfall.dds"},			-- Slowfall
	[12]	= {4,	"pwrFntsy\\tx_s_lock.dds",				"pwrFntsy\\b_tx_s_lock.dds"},				-- Lock
	[13]	= {4,	"pwrFntsy\\tx_s_open.dds",				"pwrFntsy\\b_tx_s_open.dds"},				-- Open
	[14]	= {nil,	"pwrFntsy\\tx_s_fire_damage.dds",		"pwrFntsy\\b_tx_s_fire_damage.dds"},		-- Fire Damage
	[15]	= {nil,	"pwrFntsy\\tx_s_shock_dmg.dds",			"pwrFntsy\\b_tx_s_shock_dmg.dds"},			-- Shock Damage
	[16]	= {nil,	"pwrFntsy\\tx_s_frost_dmg.dds",			"pwrFntsy\\b_tx_s_frost_dmg.dds"},			-- Frost Damage
	[17]	= {nil,	"pwrFntsy\\tx_s_drain_attrib.dds",		"pwrFntsy\\b_tx_s_drain_attrib.dds"},		-- Drain Attribute
	[18]	= {nil,	"pwrFntsy\\tx_s_drain_health.dds",		"pwrFntsy\\b_tx_s_drain_health.dds"},		-- Drain Health
	[19]	= {nil,	"pwrFntsy\\tx_s_drain_magic.dds",		"pwrFntsy\\b_tx_s_drain_magic.dds"},		-- Drain Magicka
	[20]	= {nil,	"pwrFntsy\\tx_s_drain_fati.dds",		"pwrFntsy\\b_tx_s_drain_fati.dds"},			-- Drain Fatigue
	[21]	= {nil,	"pwrFntsy\\tx_s_drain_skill.dds",		"pwrFntsy\\b_tx_s_drain_skill.dds"},		-- Drain Skill
	[22]	= {nil,	"pwrFntsy\\tx_s_dmg_attrib.dds",		"pwrFntsy\\b_tx_s_dmg_attrib.dds"},			-- Damage Attribute
	[23]	= {nil,	"pwrFntsy\\tx_s_dmg_health.dds",		"pwrFntsy\\b_tx_s_dmg_health.dds"},			-- Damage Health
	[24]	= {nil,	"pwrFntsy\\tx_s_dmg_magic.dds",			"pwrFntsy\\b_tx_s_dmg_magic.dds"},			-- Damage Magicka
	[25]	= {nil,	"pwrFntsy\\tx_s_dmg_fati.dds",			"pwrFntsy\\b_tx_s_dmg_fati.dds"},			-- Damage Fatigue
	[26]	= {nil,	"pwrFntsy\\tx_s_dmg_skill.dds",			"pwrFntsy\\b_tx_s_dmg_skill.dds"},			-- Damage Skill
	[27]	= {nil,	"pwrFntsy\\tx_s_poison.dds",			"pwrFntsy\\b_tx_s_poison.dds"},				-- Poison
	[28]	= {nil,	"pwrFntsy\\tx_s_wknstofire.dds",		"pwrFntsy\\b_tx_s_wknstofire.dds"},			-- Weakness to Fire
	[29]	= {nil,	"pwrFntsy\\tx_s_wknstofrost.dds",		"pwrFntsy\\b_tx_s_wknstofrost.dds"},		-- Weakness to Frost
	[30]	= {nil,	"pwrFntsy\\tx_s_wknstoshock.dds",		"pwrFntsy\\b_tx_s_wknstoshock.dds"},		-- Weakness to Shock
	[31]	= {nil,	"pwrFntsy\\tx_s_wknstomagic.dds",		"pwrFntsy\\b_tx_s_wknstomagic.dds"},		-- Weakess to Magicka
	[32]	= {nil,	"pwrFntsy\\tx_s_wknstocomdise.dds",		"pwrFntsy\\b_tx_s_wknstocomdise.dds"},		-- Weakness to Common Disease
--	[33]	= {nil,	"pwrFntsy\\tx_s_wknstoblghtdise.dds",	"pwrFntsy\\b_tx_s_wknstoblghtdise.dds"},	-- Weakness to Blight Disease
	[34]	= {nil,	"pwrFntsy\\tx_s_wknstocpsdise.dds",		"pwrFntsy\\b_tx_s_wknstocpsdise.dds"},		-- Weakness to Corprus Disease
	[35]	= {nil,	"pwrFntsy\\tx_s_wknstopoison.dds",		"pwrFntsy\\b_tx_s_wknstopoison.dds"},		-- Weakness to Poison
	[36]	= {nil,	"pwrFntsy\\tx_s_wknstonmlwpns.dds",		"pwrFntsy\\b_tx_s_wknstonmlwpns.dds"},		-- Weakness to Normal Weapons
	[37]	= {nil,	"pwrFntsy\\tx_s_disintgt_wpn.dds",		"pwrFntsy\\b_tx_s_disintgt_wpn.dds"},		-- Disintegrate Weapon
--	[38]	= {nil,	"pwrFntsy\\tx_s_disintgt_armor.dds",	"pwrFntsy\\b_tx_s_disintgt_armor.dds"},		-- Disintegrate Armor
	[39]	= {nil,	"pwrFntsy\\tx_s_invisible.dds",			"pwrFntsy\\b_tx_s_invisible.dds"},			-- Invisibility
	[40]	= {nil,	"pwrFntsy\\tx_s_chameleon.dds",			"pwrFntsy\\b_tx_s_chameleon.dds"},			-- Chameleon
	[41]	= {4,	"pwrFntsy\\tx_s_light.dds",				"pwrFntsy\\b_tx_s_light.dds"},				-- Light
	[42]	= {0,	"pwrFntsy\\tx_s_sanctuary.dds",			"pwrFntsy\\b_tx_s_sanctuary.dds"},			-- Sanctuary
	[43]	= {4,	"pwrFntsy\\tx_s_nighteye.dds",			"pwrFntsy\\b_tx_s_nighteye.dds"},			-- Nighteye
	[44]	= {nil,	"pwrFntsy\\tx_s_charm.dds",				"pwrFntsy\\b_tx_s_charm.dds"},				-- Charm
	[45]	= {2,	"pwrFntsy\\tx_s_paralyse.dds",			"pwrFntsy\\b_tx_s_paralyse.dds"},			-- Paralyze
	[46]	= {2,	"pwrFntsy\\tx_s_silence.dds",			"pwrFntsy\\b_tx_s_silence.dds"},			-- Silence
	[47]	= {2,	"pwrFntsy\\tx_s_blind.dds",				"pwrFntsy\\b_tx_s_blind.dds"},				-- Blind
	[48]	= {2,	"pwrFntsy\\tx_s_sound.dds",				"pwrFntsy\\b_tx_s_sound.dds"},				-- Noise
	[49]	= {nil,	"pwrFntsy\\tx_s_cm_hunoid.dds",			"pwrFntsy\\b_tx_s_cm_hunoid.dds"},			-- Calm Humanoid
	[50]	= {nil,	"pwrFntsy\\tx_s_cm_crture.dds",			"pwrFntsy\\b_tx_s_cm_crture.dds"},			-- Calm Creature
	[51]	= {nil,	"pwrFntsy\\tx_s_frzy_hunoid.dds",		"pwrFntsy\\b_tx_s_frzy_hunoid.dds"},		-- Frenzy Humanoid
	[52]	= {nil,	"pwrFntsy\\tx_s_frzy_crture.dds",		"pwrFntsy\\b_tx_s_frzy_crture.dds"},		-- Frenzy Creature
	[53]	= {nil,	"pwrFntsy\\tx_s_demorl_hunoid.dds",		"pwrFntsy\\b_tx_s_demorl_hunoid.dds"},		-- Demoralize Humanoid
	[54]	= {nil,	"pwrFntsy\\tx_s_demorl_crture.dds",		"pwrFntsy\\b_tx_s_demorl_crture.dds"},		-- Demoralize Creature
	[55]	= {nil,	"pwrFntsy\\tx_s_rlly_hunoid.dds",		"pwrFntsy\\b_tx_s_rlly_hunoid.dds"},		-- Rally Humanoid
	[56]	= {nil,	"pwrFntsy\\tx_s_rlly_crture.dds",		"pwrFntsy\\b_tx_s_rlly_crture.dds"},		-- Rally Creature
	[57]	= {5,	"pwrFntsy\\tx_s_dispel.dds",			"pwrFntsy\\b_tx_s_dispel.dds"},				-- Dispel
	[58]	= {1,	"pwrFntsy\\tx_s_soultrap.dds",			"pwrFntsy\\b_tx_s_soultrap.dds"},			-- Soultrap
	[59]	= {nil,	"pwrFntsy\\tx_s_telekinesis.dds",		"pwrFntsy\\b_tx_s_telekinesis.dds"},		-- Telekinesis
	[60]	= {nil,	"pwrFntsy\\tx_s_mark.dds",				"pwrFntsy\\b_tx_s_mark.dds"},				-- Mark
	[61]	= {nil,	"pwrFntsy\\tx_s_recall.dds",			"pwrFntsy\\b_tx_s_recall.dds"},				-- Recall
--	[62]	= {nil,	"pwrFntsy\\tx_s_divine_intervt.dds",	"pwrFntsy\\b_tx_s_divine_intervt.dds"},		-- Divine Intervention
	[63]	= {nil,	"pwrFntsy\\tx_s_alm_intervt.dds",		"pwrFntsy\\b_tx_s_alm_intervt.dds"},		-- Almsivi Intervention
	[64]	= {nil,	"pwrFntsy\\tx_s_detect_animal.dds",		"pwrFntsy\\b_tx_s_detect_animal.dds"},		-- Detect Animal
--	[65]	= {nil,	"pwrFntsy\\tx_s_detect_enchtmt.dds",	"pwrFntsy\\b_tx_s_detect_enchtmt.dds"},		-- Detect Enchantment
	[66]	= {nil,	"pwrFntsy\\tx_s_detect_key.dds",		"pwrFntsy\\b_tx_s_detect_key.dds"},			-- Detect Key
	[67]	= {0,	"pwrFntsy\\tx_s_spll_absb.dds",			"pwrFntsy\\b_tx_s_spll_absb.dds"},			-- Spell Absorption
	[68]	= {0,	"pwrFntsy\\tx_s_reflect.dds",			"pwrFntsy\\b_tx_s_reflect.dds"},			-- Reflect Magic
	[69]	= {nil,	"pwrFntsy\\tx_s_cure_comdise.dds",		"pwrFntsy\\b_tx_s_cure_comdise.dds"},		-- Cure Common Disease
	[70]	= {nil,	"pwrFntsy\\tx_s_cure_bghtdise.dds",		"pwrFntsy\\b_tx_s_cure_bghtdise.dds"},		-- Cure Blight Disease
	[71]	= {nil,	"pwrFntsy\\tx_s_cure_corpus.dds",		"pwrFntsy\\b_tx_s_cure_corpus.dds"},		-- Cure Corprus Disease
	[72]	= {nil,	"pwrFntsy\\tx_s_cure_poison.dds",		"pwrFntsy\\b_tx_s_cure_poison.dds"},		-- Cure Poison
	[73]	= {nil,	"pwrFntsy\\tx_s_cure_paralyse.dds",		"pwrFntsy\\b_tx_s_cure_paralyse.dds"},		-- Cure Paralyzation
	[74]	= {nil,	"pwrFntsy\\tx_s_rstor_attrib.dds",		"pwrFntsy\\b_tx_s_rstor_attrib.dds"},		-- Restore Attribute
	[75]	= {nil,	"pwrFntsy\\tx_s_rstor_health.dds",		"pwrFntsy\\b_tx_s_rstor_health.dds"},		-- Restore Health
	[76]	= {nil,	"pwrFntsy\\tx_s_rstor_magic.dds",		"pwrFntsy\\b_tx_s_rstor_magic.dds"},		-- Restore Magicka
	[77]	= {nil,	"pwrFntsy\\tx_s_rstor_fatigue.dds",		"pwrFntsy\\b_tx_s_rstor_fatigue.dds"},		-- Restore Fatigue
	[78]	= {nil,	"pwrFntsy\\tx_s_rstor_skill.dds",		"pwrFntsy\\b_tx_s_rstor_skill.dds"},		-- Restore Skill
	[79]	= {0,	"pwrFntsy\\tx_s_ftfy_attrib.dds",		"pwrFntsy\\b_tx_s_ftfy_attrib.dds"},		-- Fortify Attribute
	[80]	= {0,	"pwrFntsy\\tx_s_ftfy_health.dds",		"pwrFntsy\\b_tx_s_ftfy_health.dds"},		-- Fortify Health
	[81]	= {0,	"pwrFntsy\\tx_s_ftfy_magic.dds",		"pwrFntsy\\b_tx_s_ftfy_magic.dds"},			-- Fortify Magicka
	[82]	= {0,	"pwrFntsy\\tx_s_ftfy_fati.dds",			"pwrFntsy\\b_tx_s_ftfy_fati.dds"},			-- Fortify Fatigue
	[83]	= {0,	"pwrFntsy\\tx_s_ftfy_skill.dds",		"pwrFntsy\\b_tx_s_ftfy_skill.dds"},			-- Fortify Skill
	[84]	= {0,	"pwrFntsy\\tx_s_ftfy_mgcmtplr.dds",		"pwrFntsy\\b_tx_s_ftfy_mgcmtplr.dds"},		-- Fortify Maximum Magicka
	[85]	= {5,	"pwrFntsy\\tx_s_ab_attrib.dds",			"pwrFntsy\\b_tx_s_ab_attrib.dds"},			-- Absorb Attribute
	[86]	= {5,	"pwrFntsy\\tx_s_ab_health.dds",			"pwrFntsy\\b_tx_s_ab_health.dds"},			-- Absorb Health
	[87]	= {5,	"pwrFntsy\\tx_s_ab_magic.dds",			"pwrFntsy\\b_tx_s_ab_magic.dds"},			-- Absorb Magicka
	[88]	= {5,	"pwrFntsy\\tx_s_ab_fati.dds",			"pwrFntsy\\b_tx_s_ab_fati.dds"},			-- Absorb Fatigue
	[89]	= {5,	"pwrFntsy\\tx_s_ab_skill.dds",			"pwrFntsy\\b_tx_s_ab_skill.dds"},			-- Absorb Skill
	[90]	= {0,	"pwrFntsy\\tx_s_rst_fire.dds",			"pwrFntsy\\b_tx_s_rst_fire.dds"},			-- Resist Fire
	[91]	= {0,	"pwrFntsy\\tx_s_rst_frost.dds",			"pwrFntsy\\b_tx_s_rst_frost.dds"},			-- Resist Frost
	[92]	= {0,	"pwrFntsy\\tx_s_rst_shock.dds",			"pwrFntsy\\b_tx_s_rst_shock.dds"},			-- Resist Shock
	[93]	= {0,	"pwrFntsy\\tx_s_rst_magic.dds",			"pwrFntsy\\b_tx_s_rst_magic.dds"},			-- Resist Magicka
	[94]	= {0,	"pwrFntsy\\tx_s_rst_comdise.dds",		"pwrFntsy\\b_tx_s_rst_comdise.dds"},		-- Resist Common Disease
	[95]	= {0,	"pwrFntsy\\tx_s_rst_bghtdise.dds",		"pwrFntsy\\b_tx_s_rst_bghtdise.dds"},		-- Resist Blight Disease
	[96]	= {0,	"pwrFntsy\\tx_s_rst_cpsdise.dds",		"pwrFntsy\\b_tx_s_rst_cpsdise.dds"},		-- Resist Corprus Disease
	[97]	= {0,	"pwrFntsy\\tx_s_rst_poison.dds",		"pwrFntsy\\b_tx_s_rst_poison.dds"},			-- Resist Poison
	[98]	= {0,	"pwrFntsy\\tx_s_rst_nmlwpn.dds",		"pwrFntsy\\b_tx_s_rst_nmlwpn.dds"},			-- Resist Normal Weapons
	[99]	= {0,	"pwrFntsy\\tx_s_rst_plysis.dds",		"pwrFntsy\\b_tx_s_rst_plysis.dds"},			-- Resist Paralysis
	[100]	= {nil,	"pwrFntsy\\tx_s_remcurse.dds",			"pwrFntsy\\b_tx_s_remcurse.dds"},			-- Remove Curse
	[101]	= {5,	"pwrFntsy\\tx_s_turn_undead.dds",		"pwrFntsy\\b_tx_s_turn_undead.dds"},		-- Turn Undead
	[102]	= {nil,	"pwrFntsy\\tx_s_smmn_scamp.dds",		"pwrFntsy\\b_tx_s_smmn_scamp.dds"},			-- Summon Scamp
	[103]	= {nil,	"pwrFntsy\\tx_s_smmn_clnfear.dds",		"pwrFntsy\\b_tx_s_smmn_clnfear.dds"},		-- Summon Clannfear
	[104]	= {nil,	"pwrFntsy\\tx_s_smmn_daedth.dds",		"pwrFntsy\\b_tx_s_smmn_daedth.dds"},		-- Summon Daedroth
	[105]	= {nil,	"pwrFntsy\\tx_s_smmn_drmora.dds",		"pwrFntsy\\b_tx_s_smmn_drmora.dds"},		-- Summon Dremora
	[106]	= {nil,	"pwrFntsy\\tx_s_smmn_anctlght.dds",		"pwrFntsy\\b_tx_s_smmn_anctlght.dds"},		-- Summon Ancestral Ghost
	[107]	= {nil,	"pwrFntsy\\tx_s_smmn_skltlmnn.dds",		"pwrFntsy\\b_tx_s_smmn_skltlmnn.dds"},		-- Summon Skeletal Minion
--	[108]	= {nil,	"pwrFntsy\\tx_s_smmn_lstbnwlkr.dds",	"pwrFntsy\\b_tx_s_smmn_lstbnwlkr.dds"},		-- Summon Bonewalker
--	[109]	= {nil,	"pwrFntsy\\tx_s_smmn_grtrbnwlkr.dds",	"pwrFntsy\\b_tx_s_smmn_grtrbnwlkr.dds"},	-- Summon Greater Bonewalker
	[110]	= {nil,	"pwrFntsy\\tx_s_smmn_bnlord.dds",		"pwrFntsy\\b_tx_s_smmn_bnlord.dds"},		-- Summon Bonelord
--	[111]	= {nil,	"pwrFntsy\\tx_s_smmn_wngtwlght.dds",	"pwrFntsy\\b_tx_s_smmn_wngtwlght.dds"},		-- Summon Winged Twilight
	[112]	= {nil,	"pwrFntsy\\tx_s_smmn_hunger.dds",		"pwrFntsy\\b_tx_s_smmn_hunger.dds"},		-- Summon Hunger
	[113]	= {nil,	"pwrFntsy\\tx_s_smmn_gldsaint.dds",		"pwrFntsy\\b_tx_s_smmn_gldsaint.dds"},		-- Summon Golden Saint
	[114]	= {nil,	"pwrFntsy\\tx_s_smmn_flmatrnh.dds",		"pwrFntsy\\b_tx_s_smmn_flmatrnh.dds"},		-- Summon Flame Atronach
--	[115]	= {nil,	"pwrFntsy\\tx_s_smmn_frstatrnh.dds",	"pwrFntsy\\b_tx_s_smmn_frstatrnh.dds"},		-- Summon Frost Atronach
	[116]	= {nil,	"pwrFntsy\\tx_s_smmn_stmatnh.dds",		"pwrFntsy\\b_tx_s_smmn_stmatnh.dds"},		-- Summon Storm Atronach
	[117]	= {0,	"pwrFntsy\\tx_s_ftfy_attack.dds",		"pwrFntsy\\b_tx_s_ftfy_attack.dds"},		-- Fortify Attack
	[118]	= {3,	"pwrFntsy\\tx_s_cmd_crture.dds",		"pwrFntsy\\b_tx_s_cmd_crture.dds"},			-- Command Creature
	[119]	= {3,	"pwrFntsy\\tx_s_cmd_hunoid.dds",		"pwrFntsy\\b_tx_s_cmd_hunoid.dds"},			-- Command Humanoid
	[120]	= {nil,	"pwrFntsy\\tx_s_bd_dagger.dds",			"pwrFntsy\\b_tx_s_bd_dagger.dds"},			-- Bound Dagger
	[121]	= {nil,	"pwrFntsy\\tx_s_bd_lngswd.dds",			"pwrFntsy\\b_tx_s_bd_lngswd.dds"},			-- Bound Longsword
	[122]	= {nil,	"pwrFntsy\\tx_s_bd_mace.dds",			"pwrFntsy\\b_tx_s_bd_mace.dds"},			-- Bound Mace
	[123]	= {nil,	"pwrFntsy\\tx_s_bd_battleaxe.dds",		"pwrFntsy\\b_tx_s_bd_battleaxe.dds"},		-- Bound Battle Axe
	[124]	= {nil,	"pwrFntsy\\tx_s_bd_spear.dds",			"pwrFntsy\\b_tx_s_bd_spear.dds"},			-- Bound Spear
	[125]	= {nil,	"pwrFntsy\\tx_s_bd_lngbow.dds",			"pwrFntsy\\b_tx_s_bd_lngbow.dds"},			-- Bound Longbow
	[127]	= {nil,	"pwrFntsy\\tx_s_bd_cuirass.dds",		"pwrFntsy\\b_tx_s_bd_cuirass.dds"},			-- Bound Cuirass
	[128]	= {nil,	"pwrFntsy\\tx_s_bd_helm.dds",			"pwrFntsy\\b_tx_s_bd_helm.dds"},			-- Bound Helmet
	[129]	= {nil,	"pwrFntsy\\tx_s_bd_boots.dds",			"pwrFntsy\\b_tx_s_bd_boots.dds"},			-- Bound Boots
	[130]	= {nil,	"pwrFntsy\\tx_s_bd_shield.dds",			"pwrFntsy\\b_tx_s_bd_shield.dds"},			-- Bound Shield
	[131]	= {nil,	"pwrFntsy\\tx_s_bd_gloves.dds",			"pwrFntsy\\b_tx_s_bd_gloves.dds"},			-- Bound Gloves
	[132]	= {nil,	"pwrFntsy\\tx_s_corprus.dds",			"pwrFntsy\\b_tx_s_corprus.dds"},			-- Corprus
	[133]	= {nil,	"pwrFntsy\\tx_s_vampire.dds",			"pwrFntsy\\b_tx_s_vampire.dds"},			-- Vampirism
	[135]	= {nil,	"pwrFntsy\\tx_s_sun_dmg.dds",			"pwrFntsy\\b_tx_s_sun_dmg.dds"},			-- Sun Damage
	[137]	= {nil,	"pwrFntsy\\tx_s_smmn_fabrict.dds",		"pwrFntsy\\b_tx_s_smmn_fabrict.dds"},		-- Summon Fabricant
	[138]	= {nil,	"pwrFntsy\\tx_s_smmn_wolf.dds",			"pwrFntsy\\b_tx_s_smmn_wolf.dds"},			-- Call Wolf
	[139]	= {nil,	"pwrFntsy\\tx_s_smmn_bear.dds",			"pwrFntsy\\b_tx_s_smmn_bear.dds"},			-- Call Bear
	[140]	= {nil,	"pwrFntsy\\tx_s_smmn_bonewolf.dds",		"pwrFntsy\\b_tx_s_smmn_bonewolf.dds"}		-- Summon Bonewolf
}

this.magicDesc = {
	[42] = "Reduces the effectiveness of physical status effects like Slow, Bleeding or Knockdown.",
	[49] = "This effect forces the target to temporarily stop combat with the caster. The effect's magnitude is the maximum level of targets "
		.. "it can control. It will be resisted, if insufficient. Undead, Daedra, and Automatons are not affected by default.",
	[51] = "This effect incites the target to engage in combat with surrounding actors. The effect's magnitude is the maximum "
		.. "level of targets it can control. It will be resisted, if insufficient. Undead, Daedra, and Automatons are not affected by default.",
	[53] = "This effect makes the target flee from combat. The effect's magnitude is the maximum "
		.. "level of targets it can control. It will be resisted, if insufficient. Undead, Daedra, and Automatons are not affected by default.",
	[55] = "This effect makes the target less likely to flee from combat. The effect's magnitude is the maximum "
		.. "level of targets it can control. It will be resisted, if insufficient. Undead, Daedra, and Automatons are not affected by default.",
	[117] = "Reduces damage resistance gained from Endurance or Willpower and the effectiveness of Blind, Noise, Evasion and Critical Damage Reduction.",
	[64] = "The caster of this effect can detect any entity animated by a spirit; they appear on the map as symbols."
		.. " The effect's magnitude is the range in feet from the caster that life is detected."
}

-- COMBAT
---------
this.scriptDmg = {aRef, aMob, tMob, swing, dir, weap} -- data for several scripted damage sources

this.combatStartRacePowers = {
	["_neph_race_br_pwDragonSkin"]	= "Dragon Skin",
	["_neph_race_rg_pwAdrenaline"]	= "Adrenaline Rush",
	["_neph_race_or_pwBerserk"]		= "Berserk Rage"
}

this.combatStartBSPowers = {
	["_neph_bs_war_pwMight"]	= "Might",
	["_neph_bs_lov_pwTrample"]	= "Trample",
	["_neph_bs_lad_pwGift"]		= "Celestial Gift",
	["_neph_bs_sha_pwShroud"]	= "Dark Shroud",
	["_neph_bs_ser_pwFangs"]	= "Fangs of the Serpent",
	["_neph_bs_mag_pwSurge"]	= "Spell Surge",
	["_neph_bs_app_pwZeal"]		= "Zeal"
}

this.weaponSkill = {
	[-1] = 26,
	[0] = 22,
	[1] = 5,
	[2] = 5,
	[3] = 4,
	[4] = 4,
	[5] = 4,
	[6] = 7,
	[7] = 6,
	[8] = 6,
	[9] = 23,
	[10] = 23,
	[11] = 23
}


-- MAGIC
--------
this.hugeSouls = {
	["dagoth"] = true,
	["gwai_uni"] = true,
	["fg_nchur"] = true,
	["menta_unique"] = true,
	["special_fyr"] = true,
	["ttpc"] = true,
	["staada"] = true,
	["twilight_grunda_"] = true,
	["gateway_haunt"] = true,
	["ancestor_mg_wisewoman"] = true,
	["sul_senipul"] = true,
	["ghost_vabdas"] = true,
	["dahrk mezalf"] = true,
	["skeleton_vemynal"] = true,
	["skeleton_aldredaynia"] = true,
	["worm lord"] = true,
	["lich_relvel"] = true,
	["lich_barilzar"] = true,
	["ghost_variner"] = true,
	["ghost_radac"] = true,
	["_icetroll_fg_uni"] = true,
	["_ice_troll_sun"] = true,
	["_horker_swim_"] = true,
	["_riekling_dulk_"] = true,
	["_riekling_krish_"] = true,
	["hircine"] = true,
	["bm_frost_giant"] = true,
	["udyrfrykte"] = true,
	["draugr_aesliip"] = true,
	["_skeleton_pirate_capt"] = true,
	["yagrum bagarn"] = true,
	["dreugh_koal"] = true,
	["netch_giant"] = true,
	["slaughterfish_hr_sfavd"] = true
}

this.summonID = {
	[102] = "Scamp",
	[103] = "Clannfear",
	[104] = "Daedroth",
	[105] = "Dremora",
	[106] = "Ancestral Ghost",
	[107] = "Skeletal Minion",
	[108] = "Bonewalker",
	[109] = "Greater Bonewalker",
	[110] = "Bonelord",
	[111] = "Winged Twilight",
	[112] = "Hunger",
	[113] = "Golden Saint",
	[114] = "Flame Atronach",
	[115] = "Frost Atronach",
	[116] = "Storm Atronach",
	[134] = "Centurion Sphere",
	[137] = "Fabricant",
	[138] = "Wolf",
	[139] = "Bear",
	[140] = "Bonewolf",
	[223] = "Goblin Grunt",
	[224] = "Goblin Officer",
	[225] = "Hulking Fabricant",
	[226] = "Ascended Sleeper",
	[227] = "Draugr",
	[228] = "Lich",
	[252] = "Ogrim",
	[253] = "War Durzog",
	[254] = "Spriggan",
	[255] = "Steam Centurion",
	[256] = "Centurion Archer",
	[257] = "Ash Ghoul",
	[258] = "Ash Zombie",
	[259] = "Ash Slave",
	[260] = "Centurion Spider",
	[261] = "Imperfect",
	[262] = "Goblin Warchief",
	[267] = "Armor Centurion",
	[268] = "Armor Centurion Champion",
	[269] = "Draugr Housecarl",
	[270] = "Draugr Lord",
	[271] = "Dridrea",
	[272] = "Dridrea Monarch",
	[273] = "Frost Lich",
	[274] = "Giant",
	[275] = "Goblin Shaman",
	[276] = "Greater Lich",
	[277] = "Lamia",
	[278] = "Mammoth",
	[279] = "Minotaur",
	[280] = "Mud Golem",
	[281] = "Parastylus",
	[282] = "Plain Strider",
	[283] = "Raki",
	[284] = "Sabre Cat",
	[285] = "Silt Strider",
	[286] = "Sload",
	[287] = "Swamp Troll",
	[288] = "Welkynd Spirit",
	[289] = "Wereboar",
	[290] = "Velk",
	[291] = "Vermai",
	[292] = "Trebataur",
	[311] = "Amanu",
	[326] = "Werewolf",
	[327] = "Alfiq",
	[426] = "Incarnate",
	[427] = "Dark Seducer",
	[7700] = "Ash Golem",
	[7701] = "Bone Golem",
	[7702] = "Crystal Golem",
	[7703] = "Flesh Atronach",
	[7704] = "Iron Golem",
	[7705] = "Swamp Myconid",
	[7706] = "Telvanni Myconid",
	[7800] = "Daedroth"
}

this.boundWeapon = { 	--	= ID,	GMST,						potent base item ID
	["bound_dagger"] 		= {120, "sMagicBoundDaggerID",		"_neph_weap_boundDaggerP"},
	["bound_longsword"] 	= {121, "sMagicBoundLongswordID",	"_neph_weap_boundLongswordP"},
	["bound_mace"]			= {122, "sMagicBoundMaceID",		"_neph_weap_boundMaceP"},
	["bound_battle_axe"]	= {123, "sMagicBoundBattleAxeID",	"_neph_weap_boundBattleAxeP"},
	["bound_spear"]			= {124, "sMagicBoundSpearID",		"_neph_weap_boundSpearP"},
	["bound_longbow"]		= {125, "sMagicBoundLongbowID",		"_neph_weap_boundLongbowP"}
}

this.boundArmor = {
	["bound_cuirass"] = {
		127,						-- effect ID
		"sMagicBoundCuirassID",		-- GMST
		"_neph_spell_bCuirass",		-- NPC base fake enchantment/spell
		"_neph_spell_bCuirassP",	-- NPC potent fake enchantment/spell
		"_neph_armo_pboundCuirass",	-- player base bound item
		"_neph_armo_pboundCuirassP"	-- player potent bound item
	},
	["bound_helm"] = {
		128,
		"sMagicBoundHelmID",
		"_neph_spell_bHelm",
		"_neph_spell_bHelmP",
		"_neph_armo_pboundHelm",
		"_neph_armo_pboundHelmP"
	},
	["bound_boots"] = {
		129,
		"sMagicBoundBootsID",
		"_neph_spell_bBoots",
		"_neph_spell_bBootsP",
		"_neph_armo_pboundBoots",
		"_neph_armo_pboundBootsP"
	},
	["bound_shield"] = {
		130,
		"sMagicBoundShieldID",
		"_neph_spell_bShield",
		"_neph_spell_bShieldP",
		"_neph_armo_pboundShield",
		"_neph_armo_pboundShieldP"
	},
	["bound_gauntlet_left"] = {
		131,
		"sMagicBoundLeftGauntletID",
		"_neph_spell_bGauntlet_l",
		"_neph_spell_bGauntlet_lP",
		"_neph_armo_pboundGauntlet_l",
		"_neph_armo_pboundGauntlet_lP"
	},
	["bound_gauntlet_right"] = {
		131, "sMagicBoundRightGauntletID",
		"_neph_spell_bGauntlet_r",
		"_neph_spell_bGauntlet_rP",
		"_neph_armo_pboundGauntlet_r",
		"_neph_armo_pboundGauntlet_rP"
	}
}

this.MEexists = false -- set to true on main.initialized, if Magicka Expanded's lore-friendly pack is installed

this.MEboundWeapon = {			-- ID,	base ench origin,	potent ench origin,				damage stats (adjusted: base * 0.75)
	["OJ_ME_BoundClaymore"]		= {229, "bound_battle_axe",	"_neph_weap_boundBattleAxeP",	1,	45,	1,	39,	1,	25},
	["OJ_ME_BoundClub"]			= {230, "bound_longsword",	"_neph_weap_boundLongswordP",	8,	9,	3,	6,	3,	6},
	["OJ_ME_BoundDaiKatana"]	= {231, "bound_battle_axe",	"_neph_weap_boundBattleAxeP",	1,	45,	1,	39,	1,	23},
	["OJ_ME_BoundKatana"]		= {232, "bound_longsword",	"_neph_weap_boundLongswordP",	3,	33,	1,	30,	1,	11},
	["OJ_ME_BoundShortsword"]	= {233, "bound_dagger",		"_neph_weap_boundDaggerP",		8,	19,	8,	19,	9,	18},
	["OJ_ME_BoundStaff"]		= {234, "bound_battle_axe",	"_neph_weap_boundBattleAxeP",	2,	12,	3,	12,	1,	9},
	["OJ_ME_BoundTanto"]		= {235, "bound_dagger",		"_neph_weap_boundDaggerP",		7,	15,	7,	15,	7,	15},
	["OJ_ME_BoundWakizashi"]	= {236, "bound_dagger",		"_neph_weap_boundDaggerP",		8,	23,	8,	19,	5,	8},
	["OJ_ME_BoundWarAxe"]		= {237, "bound_longsword",	"_neph_weap_boundLongswordP",	1,	33,	1,	18,	1,	5},
	["OJ_ME_BoundWarhammer"]	= {238, "bound_battle_axe",	"_neph_weap_boundBattleAxeP",	1,	53,	1,	45,	1,	3}
}

this.MEboundArmor = {
	["OJ_ME_BoundGreaves"]			= {239, "_neph_ench_pBgreaves",		"_neph_ench_pBgreavesP",	15},
	["OJ_ME_BoundPauldronLeft"]		= {240, "_neph_ench_pBpauldron_l",	"_neph_ench_pBpauldron_lP",	8},
	["OJ_ME_BoundPauldronRight"]	= {264, "_neph_ench_pBpauldron_r",	"_neph_ench_pBpauldron_rP",	8}
}

this.boundArmorEff = {[127] = true, [128] = true, [129] = true, [130] = true, [131] = true, [239] = true, [240] = true, [264] = true}

this.negativeEffects = { -- excluding attribute and skill stuff
	[7]		= true, [14]	= true, [15]	= true, [16]	= true, [18]	= true, [19]	= true, [20]	= true, [23]	= true, [24]	= true,
	[25]	= true, [27]	= true, [28]	= true, [29]	= true, [30]	= true, [31]	= true, [32]	= true, [33]	= true, [34]	= true,
	[35]	= true, [36]	= true,	[37]	= true, [38]	= true, [45]	= true, [47]	= true, [48]	= true, [51]	= true, [52]	= true,
	[86]	= true, [87]	= true, [88]	= true, [118]	= true,	[119]	= true
}

this.positiveEffects = { -- excluding attribute and skill stuff
	[0]		= true,	[1]		= true,	[2]		= true,	[3]		= true,	[4]		= true,	[5]		= true,	[6]		= true,	[8]		= true,	[9]		= true,
	[10]	= true,	[11]	= true,	[39]	= true,	[40]	= true,	[41]	= true,	[42]	= true,	[46]	= true,	[55]	= true,	[56]	= true,
	[67]	= true,	[68]	= true,	[75]	= true,	[76]	= true,	[77]	= true,	[84]	= true,	[90]	= true,	[91]	= true,	[92]	= true,
	[93] 	= true,	[94]	= true, [95]	= true,	[96]	= true,	[97]	= true,	[98]	= true,	[99]	= true,	[102]	= true,	[103]	= true,
	[104]	= true,	[105]	= true,	[106]	= true,	[107]	= true,	[108]	= true,	[109]	= true,	[110]	= true,	[111]	= true,	[112]	= true, 
	[113]	= true,	[114]	= true,	[115]	= true,	[116]	= true,	[117]	= true,	[120]	= true,	[121]	= true,	[122]	= true,	[123]	= true,
	[124]	= true,	[125]	= true,	[126]	= true,	[127]	= true,	[128]	= true,	[129]	= true,	[130]	= true,	[131]	= true,	[134]	= true,
	[137]	= true,	[138] 	= true,	[139]	= true,	[140]	= true
}

this.illu90Blacklist = {
	["dagoth_ur_1"] = true,
	["dagoth_ur_2"] = true,
	["vivec_god"] = true,
	["BM_hircine_huntaspect"] = true,
	["BM_hircine_spdaspect"] = true,
	["BM_hircine_straspect"] = true,
	["almalexia"] = true,
	["almalexia_warrior"] = true
}

this.apprBlacklist = {
	[0] = true,		[2] = true,		[12] = true,	[13] = true,	[39] = true,	[41] = true,	[45] = true,	[46] = true,	[49] = true,
	[51] = true,	[53] = true,	[55] = true,	[57] = true,	[58] = true,	[60] = true,	[61] = true,	[62] = true,	[63] = true,
	[69] = true,	[70] = true,	[71] = true,	[72] = true,	[73] = true,	[101] = true,	[118] = true,	[119] = true,	[120] = true,
	[121] = true,	[122] = true,	[123] = true,	[124] = true,	[125] = true,	[126] = true,	[127] = true,	[128] = true,	[129] = true,
	[130] = true,	[131] = true
}


-- MISC
-------
-- active block timer (used by combat and magic)
this.blockT = nil

this.stepSound = {	-- used to block vanilla step sounds; doesn't work with certain sound overhauls, but isn't as noticeable there as in vanilla
	["FootHeavyLeft"]	= true, ["FootHeavyRight"]	= true,
	["FootMedLeft"]		= true, ["FootMedRight"]	= true,
	["FootLightLeft"]	= true, ["FootLightRight"]	= true,
	["FootBareLeft"]	= true, ["FootBareRight"]	= true,
	["FootWaterLeft"]	= true, ["FootWaterRight"]	= true
}

this.armo_items = {			--	= {maxCondition, quality}
	["repair_prongs"]			= {20, 1},
	["hammer_repair"]			= {20, 1.6},
	["repair_journeyman_01"]	= {30, 2},
	["repair_master_01"]		= {40, 2.6},
	["repair_grandmaster_01"]	= {50, 3.4},
	["repair_secretmaster_01"]	= {60, 4}
}

this.retorts = {
	["apparatus_a_retort_01"]	= {0.4, 0.6},
	["apparatus_j_retort_01"]	= {0.6, 0.8},
	["apparatus_m_retort_01"]	= {0.8, 1.1},
	["apparatus_g_retort_01"]	= {1, 1.3},
	["apparatus_sm_retort_01"]	= {1.2, 1.5}
}

this.alembics = {
	["apparatus_a_alembic_01"]	= {0.25, 0.4},
	["apparatus_j_alembic_01"]	= {0.5, 0.75},
	["apparatus_m_alembic_01"]	= {0.75, 1},
	["apparatus_g_alembic_01"]	= {1, 1.25},
	["apparatus_sm_alembic_01"]	= {1.25, 1.5}
}

this.secu_items = {
	["skeleton_key"]		= {100, 10},
	["pick_apprentice_01"]	= {50, 2},
	["pick_journeyman_01"]	= {50, 2.2},
	["pick_master"]			= {50, 2.6},
	["pick_grandmaster"]	= {50, 2.8},
	["pick_secretmaster"]	= {50, 3},
	["probe_bent"]			= {10, 0.5},
	["probe_apprentice_01"]	= {50, 1},
	["probe_grandmaster"]	= {50, 1.5},
	["probe_journeyman_01"]	= {50, 2},
	["probe_master"]		= {50, 2.5},
	["probe_secretmaster"]	= {50, 3}
}

return this