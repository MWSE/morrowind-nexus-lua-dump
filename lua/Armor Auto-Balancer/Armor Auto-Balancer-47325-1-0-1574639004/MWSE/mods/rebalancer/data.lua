local data = {}


-- the syntax to add new armor is:
	-- [armor id / mesh] = {WEIGHT, VALUE, ENCHANT CAP, HEALTH, RATING, IS ENCHANTED}
-- armor properties are determined with (material base) * (slot multiplier)
-- to leave armor properties as default, only enter the name followed by a comma and new line
-- if the armor is enchanted, but not marked as such (with "true"), the value will be left as default
-- all listings are read through in reverse alphebetical order - add an underscore ( _ ) to ensure a listing is read last
-- keep LIGHT weight under 0.6
-- keep HEAVY weight over 1.45

data = { -- {WEIGHT, VALUE, ENCHANT CAP, HEALTH, RATING, IS ENCHANTED}

		-- ____ SLOT MULTIPLIERS ____ --
	arm_slot = {
		[0] = {10, 25, 12.5, 100, 1}, -- helmet
		{35, 75, 10, 300, 1}, -- cuirass
		{8, 15, 1, 100, 1}, -- left pauldron
		{}, -- right pauldron
		{20, 40, 1.5, 125, 1}, -- greaves
		{15, 20, 4.5, 125, 1}, -- boots
		{5, 12, 10, 75, 1}, -- left gauntlet
		{}, -- right gauntlet
		{18, 45, 25, 250, 1},-- shield
		{4, 10, 10, 60, 1},-- left bracer
		{} -- right bracer
	},

		-- ____ MATERIAL BASE PROPERTIES ____ --
		
	-- __BLACKLIST__ - don't assign value and armor will be left untouched
	gdr_a_dwrv,
	daedrichide,
	
	-- __BASIC ARMOR__ -- 
			-- LIGHT
	fur = {0.2, 0.7, 2.5, 0.8, 8},
	netch = {0.3, 1, 3, 1, 12},
	netch_leather_boiled = {0.3, 1.2, 3, 1.5, 15},
	chitin = {0.2, 2, 10, 2, 20},
	wolf2 = {0.2, 3.5, 24, 2.5, 20, true}, -- (BM)
	darkbrotherhood = {0.2, 12, 20, 3, 30}, -- (TR)
	wolf = {0.2, 100, 50, 5, 32, true}, -- (BM) snow wolf 
	glass = {0.4, 280, 60, 3.5, 40},
	
			-- MEDIUM
	imperial_chain = {0.7, 2, 10, 2.5, 15},
	bonemold = {1.1, 5, 20, 3.5, 25},
	bonemold_armun = {1.1, 6, 24, 4, 28},
	bonemold_chuzei,
	bonemold_gah,
	dragonscale = {0.8, 5, 10, 4, 30},
	bear = {0.6, 5, 28, 3, 30, true}, -- (BM)
	orcish = {1, 32, 60, 5, 35},
	dreugh = {0.7, 35, 40, 5, 44},
	indoril = {1.2, 45, 50, 4.5, 45},
	adamantium = {1.4, 65, 30, 6, 50}, -- (TR)
	bear2 = {0.6, 100, 60, 6, 50, true}, -- (BM) snow bear 
	helsethguard = {1.4, 75, 50, 8, 55}, -- (TR)
	a_ice = {1.3, 100, 50, 10, 60}, -- (BM)
	
			-- HEAVY
	iron = {1.6, 1, 5, 3, 20},
	ancient = {1.6, 18, 5, 2.5, 20},
	_steel = {1.6, 1.5, 10, 4, 25}, -- underscore here forces prioritization of other armors over steel (e.g. ancient steel)
	nordiciron = {1.7, 5, 15, 5, 28},
	imperial = {2, 8, 20, 4.5, 30},
	silver = {1.55, 18, 65, 5.5, 32}, -- imperial silver
	trollbone = {1.7, 8, 20, 5, 32},
	templar = {1.55, 12, 40, 5, 35},
	dwemer = {2, 30, 40, 5, 40},
	ebony = {2.5, 320, 60, 12, 60},
	nordicmail = {2.2, 50, 20, 5, 66}, -- (BM)
	indoril_mh_guard = {2.7, 375, 75, 12, 70}, -- (TR) Her Hand's 
	indoril_almalexia = {2.7, 400, 75, 12, 70, true}, -- (TR) Her Hand's (enchanted)
	_daedric = {3, 560, 80, 15, 80}, -- _ to load after bound
	daedric_fountain_helm,
	daedric_terrifying_helm,
	
	-- __UNIQUE ARMOR__ --
			-- LIGHT --
	fur_colovian = {0.15, 0.4, 2, 0.5, 5},
	wolfwalkers, -- Paws of the Wolf-Runner (BM)
	studded = {0.35, 1.8, 10, 1.5, 18},
	dustadept = {0.2, 5, 24, 1, 12}, -- Telvanni Dust Adept Helm
	molecrab = {0.25, 8, 48, 1.2, 14}, -- Telvanni Mole Crab Helm
	cephalopod = {0.25, 12, 88, 1.5, 18}, -- Telvanni Cephalopod Helm
	watchmans = {0.2, 3, 10, 2.2, 22}, -- Redoran Watchman's Helm
	newtscale = {0.45, 3, 10, 3.5, 25},
	morag_tong = {0.3, 10, 20, 3, 25},
	wolf_shield, -- has wolf in mesh name and not wolf2 - this causes it to read as snow wolf armor, thus the need for an override
	bear_shield, -- same as above
	helmet_heartfang = {0.2, 24, 30, 2.5, 20, true}, -- Helm of the Wolf's Heart
	bound, -- bound armor
	
			-- MEDIUM --
	ringmail = {0.9, 2.5, 10, 3, 20},
	redoran_master = {1.1, 8, 15, 4.5, 30},
	["bear helmet_ber"] = {0.6, 20, 30, 3, 30, true}, -- Helm of Bearkind (BM)
	["bear helmet eddard"] = {0.6, 20, 28, 3, 50, true}, -- Helm of Bear Scent (BM)
	helmet_heartfang = {0.2, 18, 30, 2.5, 20, true},-- Helm of the Wolf's Heart (BM)
	
			-- HEAVY --
	silver_duke = {1.7, 20, 50, 6, 45}, -- Duke's Guard
	frald_uniq, -- Helm of Graff the White; imperial steel
	helm_bearclaw = {1.8, 5000, 160, 9, 90, true}, -- Helm of Oreyn Bearclaw
	slave_bracer =  {1.5, 0.5, 0.2, 0.5, 5, true},
	
	-- __MOD ADDED ARMOR__ --
	
			-- LIGHT
	domina = {0.3, 16, 20, 1.2, 22}, -- (OFFICIAL PLUGIN)
	
			-- MEDIUM			
	gold = {1.35, 50, 75, 3, 40}, -- (OFFICIAL PLUGIN)
	
			-- HEAVY --
	dremora = {3, 100, 60, 15, 50}, -- (RANKED DREMORA)
	
} -- {WEIGHT, VALUE, ENCHANT, HEALTH, AR, ENCHANTED}

-- unique items
data.wolfwalkers = table.copy(data.wolf2)
data.wolfwalkers[2] = 50

data.frald_unique = table.copy(data.imperial)
data.frald_unique[2] = 16
data.frald_unique[6] = true

-- weaker daedric helms
data.daedric_fountain_helm = table.copy(data._daedric)
data.daedric_terrifying_helm = table.copy(data._daedric)
data.daedric_fountain_helm[2] = data._daedric[2] - 80
data.daedric_fountain_helm[4] = data._daedric[4] - 1.5
data.daedric_fountain_helm[5] = data._daedric[5] - 15
data.daedric_terrifying_helm[2] = data._daedric[2] - 40
data.daedric_terrifying_helm[4] = data._daedric[4] - 0.5
data.daedric_terrifying_helm[5] = data._daedric[5] - 5

-- bound weapons
data.bound = table.copy(data._daedric)
data.bound[1] = 0 -- weighs nothing
data.bound[2] = 0 -- worth nothing
data.bound[5] = data.bound[5] * 0.9 -- 90% armor value of daedric
data.bound[6] = true

-- miscellaneous fixes
data.wolf_shield = table.copy(data.wolf2)
data.bear_shield = table.copy(data.bear2)
data.bonemold_chuzei = table.copy(data.bonemold_armun)
data.bonemold_gah = table.copy(data.bonemold_armun)

-- copy left slot values into right
data.arm_slot[3] = data.arm_slot[2] -- right pauldron
data.arm_slot[7] = data.arm_slot[6] -- right gauntlet
data.arm_slot[10] = data.arm_slot[9] -- right bracer

return data