--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Temperature Module									   │
│  Dynamic, vector-based temperature 								   │
╰──────────────────────────────────────────────────────────────────────╯
]]

G_SW_isWet = 0 -- starwind global
G_temperatureWidgetTooltip = ""
local climateTempTooltip1 = ""
local climateTempTooltip2 = {}
local climateTempTooltip3 = ""
require('scripts.SunsDusk.settings.temp_settings')
require('scripts.SunsDusk.lib.temp_climate_sources')
require('scripts.SunsDusk.lib.temp_climates_quasi_exterior')
require('scripts.SunsDusk.lib.temp_widgets')

--- DEBUGS:
--- first digit: 
--- 0 = only print to console if enabled
--- 1 = print to console(if enabled) and tooltip/widget
--- 2 = only print to tooltip/widget
--- second digit:
--- log level ( "Silent", "Quiet", "Chatty", "Deep", "Trace" )
-- tempDbg2.p(level%10,...)
--local TESTING_WIDGET = true

G_wetnessChange = 0 -- how much wetness changed in last second

local armorCache = {}
local tempData
local fireRes, frostRes, fireWeak, frostWeak = 0,0,0,0
local fireShield, frostShield, fireDamage, frostDamage = 0,0,0,0
local campfireBonus, foundCampfire, ignoreMaxTemperature, nearbyLava = 0,nil,nil,nil
G_idealTemperature = 20
local nearbyHotMod = 0   -- Heat sources ignoring max temp
local nearbyWarmMod = 0  -- Heat sources respecting max temp
local nearbyCoolMod = 0  -- Cooling sources respecting min temp
local nearbyColdMod = 0  -- Cooling sources ignoring min temp
local hearthfireMagnitude = 0
local dryingRateTooltip

local waterTemp = 20
G_temperatureRate = 1
G_heatRate = 1
G_coolRate = 1
local isOnRedMountain = 0
local cell

-- Equipment data structure

local equipmentData = {
	heatResistance = 0,	 -- Material-based heat resistance
	coldResistance = 0,	 -- Material-based cold resistance
	baseModifier = 0,	   -- Base temperature modifier
	
	-- Clothing tracking
	hasRobe = false,
	hasShirt = false,
	hasSkirt = false,
	hasPants = false,
	hasUmbrella = 0,
	
	-- Weight class tracking
	weightClassHeatMod = 0,  -- Heat modifier from armor weight
	weightClassColdMod = 0,  -- Cold modifier from armor weight
	
	armorPieces = 0,
	clothingPieces = 0,
	lastUpdate = 0
}

local climateType = "temperate"
local climateTemperature = 20
local lastGametimeUpdate
local lastGametimeUpdate
local clockHour = 0
local secondsPassed = 0
local race = "default"
local racialData = {
		comfortableMin = 15,
		comfortableMax = 25,
		warmMax = 35,
		hotMin = 35,
		heatGainRate = 1.0,
		coldGainRate = 1.0,
	}
	
-- ========================================================================= Constants ==========================================================================

local CRITICAL_COLD_TEMPERATURE = -15
local CRITICAL_HOT_TEMPERATURE = 50
local WORLD_BASE_TEMP = 20

local calculateEnvironmentTemperature

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Fire Tags															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local fireTags = {
	{"light_torch_01", 500, 6, 2}, -- thicc solstheim torch
	{"sd_wood_", 500, 10, 8}, -- this mod's firewood
	{"torch",	150, 5},
	{"firepit",  500, 10, 4},
	{"brazier",  500, 10, 4},
	{"logpile",  500, 10, 5},
	{"pitfire",  500, 10, 8},
	{"incense",  100, 5},
	{"lava_vent", 500, 10},
	{"lava",	 700, 12, nil, true}, -- some mods make lava an activator lol
	{"burner",   400, 9, 6},
	{"tiki",	 350, 7, 6},
	{"forge",	 500, 9, 4},
	{"fire",	 450, 9, 6},
	{"flame",	350, 9, 6},
}

local actorTags = {
	{"flame",	700,  8, nil, true},
	{"fire",	700,  7, nil, true},
	{"frost",	700, -6, nil, true},
	{"ice",	 	700, -5, nil, true},
	-- exclude eldafire here or something
}

--for a,b in pairs(dbStatics) do
--	print(a..": ")
--	if type(b) == "table" then
--		for c,d in pairs(b) do
--			if type(d) == "table" then
--				if tableLength(d) == 0 then
--					print("",c..": {}")
--				else
--					print("",c..": ")
--				end
--				
--				for e,f in pairs(d) do
--					print("","",e,f)
--				end
--			else
--				print("",c,d)
--			end
--		end
--	end
--end

local sourceMaxDistance = 800

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Module State														  │
-- ╰──────────────────────────────────────────────────────────────────────╯
-- unused?
-- local temperatureModule = {
-- 	
-- 	-- Temperature states with default spell IDs
-- 	temperatureStates = {
-- 		{ name = "Freezing",	min = -999, max = -10, spellId = "sd_temp_6" },
-- 		{ name = "Cold",		min = -10,  max = 5,   spellId = "sd_temp_5" },
-- 		{ name = "Chilly",		min = 5,	max = 15,  spellId = "sd_temp_4" },
-- 		{ name = "Comfortable", min = 15,   max = 25,  spellId = "sd_temp_3" },
-- 		{ name = "Warm",		min = 25,   max = 35,  spellId = "sd_temp_2" },
-- 		{ name = "Hot",			min = 35,   max = 45,  spellId = "sd_temp_1" },
-- 		{ name = "Scorching",   min = 45,   max = 999, spellId = "sd_temp_0" },
-- 	},
-- }

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Armor Resistances													│
-- ╰────────────────────────────────────────────────────────────────────╯

local ARMOR_RESISTANCES = {
	-- Light/Dunmer native armors
	chitin =				{ heat = 1,		cold = 1,	water = nil,	name = "Chitin" },
	bonedancer =			{ heat = 2,		cold = nil,	water = nil,	name = "Bonedancer" },
	boneweave =				{ heat = 2,		cold = nil,	water = nil,	name = "Boneweave" },
	the_chiding_cuirass =	{ heat = 3,		cold = nil,	water = nil,	name = "Chiding Cuirass" },
	velothian_helm =		{ heat = 3,		cold = nil,	water = nil,	name = "Chiding Cuirass" },
	netchleather =			{ heat = 2,		cold = nil,	water = nil,	name = "Netch Leather" },
	horny =					{ heat = 3,		cold = 2,	water = nil,	name = "Horny Fists" },
	merisan =				{ heat = 3,		cold = 2,	water = nil,	name = "Merisan" },
	netch =					{ heat = 2,		cold = 2,	water = nil,	name = "Netch" },
	moragtong =				{ heat = 2,		cold = 1.5,	water = nil,	name = "Morag Tong" },
	smt_ =					{ heat = 3,		cold = 1,	water = nil,	name = "SM's Morag Tong" }, -- modded armor
	cephalopod =			{ heat = 1,		cold = nil,	water = nil,	name = "Cephalopod" },
	Molecrab =				{ heat = 1,		cold = nil,	water = nil,	name = "Molecrab" },
	leather =				{ heat = nil,	cold = 1.5,	water = nil,	name = "Leather" },
	scale =					{ heat = nil,	cold = 1,	water = nil,	name = "Scale" },
	hide =					{ heat = nil,	cold = 1,	water = nil,	name = "Hide" },
	studded =				{ heat = nil,	cold = 1.5,	water = nil,	name = "Studded" },
	navy =					{ heat = nil,	cold = 1.5,	water = nil,	name = "Navy" },
	redoran =				{ heat = 4,		cold = 4,	water = nil,	name = "Redoran" }, -- modded armor
	bonemold =				{ heat = 4,		cold = 4,	water = nil,	name = "Bonemold" },

	-- Glass and specialty                                      
	glass =					{ heat = 2,		cold = nil,	water = nil,	name = "Glass" },
	imperial =				{ heat = 2,		cold = 1.5,	water = nil,	name = "Imperial" },
	cyrodiil =				{ heat = 2,		cold = 1.5,	water = nil,	name = "Cyrodiilic" },
	gondolier =				{ heat = 3,		cold = nil,	water = 4,		name = "Gondolier" },
	caravaner =				{ heat = 3,		cold = nil,	water = 4,		name = "Caravaner" },
	wicker =				{ heat = 3,		cold = nil,	water = 4,		name = "Wicker" },
	goggles =				{ heat = 3,		cold = 3,	water = nil,	name = "Goggles" }, -- modded armor
	ashland =				{ heat = 3,		cold = nil,	water = nil,	name = "Ashlander" },
	bug =					{ heat = 3,		cold = nil,	water = nil,	name = "Bug" },
	argonian =				{ heat = 2,		cold = nil,	water = nil,	name = "Argonian" },
	T_Rga_Lamellar_Helm =	{ heat = 3,		cold = nil,	water = nil,	name = "Redguard" },

	-- Fur and cold-weather armors                              
	fur =					{ heat = nil,	cold = 2,	water = 2,		name = "Fur" },
	nordic =				{ heat = nil,	cold = 3,	water = 3,		name = "Nordic" },
	bloodworm =				{ heat = nil,	cold = 4,	water = nil,	name = "Bloodworm" },
	wolf =					{ heat = nil,	cold = 2,	water = nil,	name = "Wolf" },
	bear =					{ heat = nil,	cold = 3,	water = nil,	name = "Bear" },
	ebonweave =				{ heat = nil,	cold = 4,	water = nil,	name = "Ebonweave" },
	ice =					{ heat = nil,	cold = 5,	water = 4,		name = "Stalhrim" },
    scarf =                 { heat = 1,     cold = 3,   water = 4,		name = "Scarf" },	-- modded armor

	-- Heavy/High-tier armors                                   
	dwarven =				{ heat = 4,		cold = nil,	water = nil,	name = "Dwarven" },
	dwemer =				{ heat = 4,		cold = nil,	water = nil,	name = "Dwemer" },
	daedric =				{ heat = 5,		cold = nil,	water = nil,	name = "Daedric" },
	ebony =					{ heat = 4,		cold = nil,	water = nil,	name = "Ebony" },
	indoril =				{ heat = 4,		cold = nil,	water = nil,	name = "Indoril" },
	speaker =				{ heat = 4,		cold = nil,	water = nil,	name = "Speaker" },
	t_dwe =					{ heat = 4,		cold = nil,	water = nil,	name = "Dwemer" },
	sm_dw =					{ heat = 4,		cold = nil,	water = nil,	name = "SM's Dwemer" }, -- modded armor
	_RV_Sacred_ =			{ heat = 4,		cold = nil,	water = nil,	name = "Sacred Necromancer" }, -- modded armor
	wraithguard =			{ heat = 4,		cold = nil,	water = nil,	name = "Wraithguard" },
	bound_ =				{ heat = 4,		cold = nil,	water = nil,	name = "Bound Armor" },

	-- Unique items                                             
	erur_dan_cuirass_unique = { heat = 4,	cold = 4,	water = nil,	name = "Erur Dan Cuirass" },
	wounding =				{ heat = 4,		cold = 4,	water = nil,	name = "Helm of Wounding" },
	mns_bt =				{ heat = 4,		cold = 4,	water = nil,	name = "Boots of Moon and Star" },
	redmas =				{ heat = 4,		cold = 4,	water = nil,	name = "Redoran Master" }, -- modded armor
	["pb_neen-enamor"] =	{ heat = 4,		cold = 4,	water = nil,	name = "Dagoth Bonemold" }, -- modded armor
}

-- ====================================================== Racial Temperatures ======================================================

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Racial Temperature Data								 	          │
-- ╰──────────────────────────────────────────────────────────────────────╯

local RACIAL_TEMPERATURE_DATA = {
	-- Default (for modded races outside of TD or fallback)
	default = {
		comfortableMin = 15,
		comfortableMax = 25,
		warmMax = 35,
		hotMin = 35,
		heatGainRate = 1.0,
		coldGainRate = 1.0,
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- ARGONIAN (farming tools)
	-- ═══════════════════════════════════════════════════════════════════
	argonian = {
		comfortableMin = 15,
		comfortableMax = 25,
		warmMax = 40,  -- can tolerate more heat
		hotMin = 40,
		
		-- Gain rates (cold-blooded - temperature changes faster)
		heatGainRate = 1.25,  -- Warms 25% faster
		coldGainRate = 1.35,  -- Cools 35% faster
		
		-- Climate bonuses/penalties
		climateBonus = {
			tropical = -5,   -- -5°C in tropical/swamp regions
			coastal = -3,	-- -3°C in coastal regions
		},
		climatePenalty = {
			arctic = -5,	-- -5°C in arctic regions
			cold = -3,	  -- -3°C in cold regions
		},
		
		-- wet or swimming
		wetComfortDrift = 15,
		
		-- Wetness persistence
		wetnessTemperatureRate = 0.5,  -- Wetness lasts 50% longer (decays 50% slower)
		
		-- Interior cell bonuses
		cellTypeBonus = {
			isMine = 5,  -- +5°C in mines
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- BRETON - magical resistance gives temperature stability
	-- ═══════════════════════════════════════════════════════════════════
	breton = {
		comfortableMin = 14,  -- Slightly more cold-tolerant
		comfortableMax = 26,
		warmMax = 36,
		hotMin = 36,  -- Takes longer to reach "Hot"
		
		-- Stable temperature changes
		heatGainRate = 1.0,
		coldGainRate = 1.0,
		
		-- Climate bonuses (magically adaptive)
		climateBonus = {},
		climatePenalty = {},
		
		-- Threshold rate modifiers (stable transitions)
		thresholdRates = {
			{ from = 25, to = 36, rate = 0.75 },  -- 25% slower warm -> hot
			{ from = 5, to = 14, rate = 0.75 },   -- 25% slower comfortable -> chilly
			{ from = -10, to = 5, rate = 0.75 },  -- 25% slower chilly -> freezing
		},
		
		-- Magic resistance bonuses
		resistEffectivenessMultiplier = 1.25,  -- Fire/Frost resistance 25% more effective
		weaknessReduction = 0.75,  -- Fire/Frost weakness 25% less effective
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- DARK ELF - under the shadow of Red Mountain
	-- ═══════════════════════════════════════════════════════════════════
	dunmer = {
		comfortableMin = 15,
		comfortableMax = 25,
		warmMax = 40,  -- High heat tolerance
		hotMin = 40,
		
		-- Standard rates
		heatGainRate = 1.0,
		coldGainRate = 1.0,
		
		-- Climate bonuses
		climateBonus = {
			volcanic = -3,   -- -3°C in volcanic regions (Red Mountain natives)
--			ashland = 8,	-- +8°C in ashlands
		},
		climatePenalty = {},
		
		-- Heat source effectiveness (fire worship culture)
		heatSourceMultiplier = 1.2,  -- All fires 20% more effective
		
		-- Twilight bonus (5-6am, 6-7pm)
		twilightComfortDrift = 15,
		
		-- Cold environment penalty (but exempt in ashlands/volcanic)
		coldEnvironmentPenalty = -3,  -- -3°C in cold environments
		coldPenaltyExemptZones = { "ashland", "volcanic" },
		
		-- Threshold rate modifier
		thresholdRates = {
			{ from = 25, to = 40, rate = 0.5 },  -- 50% longer to go from Warm to Hot
		},
		
		-- Interior cell bonuses
		cellTypeBonus = {
			isTomb = 5,	  -- +5°C in ancestral tombs
			isMushroom = 1,  -- +1°C in Telvanni mushroom towers
			isDaedric = 1,   -- +1°C in Daedric shrines
			isDwemer = -3,	-- +1°C in Dwemer ruins (Vvardenfell natives)
		--  isAshlander = 1,
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- HIGH ELF - civilized and delicate, sensitive to extremes
	-- ═══════════════════════════════════════════════════════════════════
	altmer = {
		comfortableMin = 17,  -- Narrower comfort zone when exterior
		comfortableMax = 25,
		warmMax = 33,  -- Gets warm earlier when exterior
		hotMin = 33,
		
		-- More reactive to temperature changes
		heatGainRate = 1.0,  -- 1.2x in exterior
		coldGainRate = 1.0,  -- 1.2x in exterior
		exteriorGainMultiplier = 1.2,  -- 20% faster temperature changes in exteriors
		
		-- Climate bonuses
		climateBonus = {
			temperate = 1,  -- -3°C in temperate zones
			coastal = 2,	-- +3°C in coastal zones
			urban = 3,	  -- -5°C in urban areas (civilized)
		},
		climatePenalty = {},
		
		-- Equipment effectiveness
		armorMultipliers = {
			clothing = 1.5,  -- Clothing 50% more effective
		},
		
		-- More susceptible to heat sources (sensitive)
		heatSourceRadiusMultiplier = 1.25,  -- 25% larger effective radius
		
		-- Interior bonuses
		cellTypeBonus = {
			isHouse = 1,	 -- +5°C in houses (civilized dwellings)
			isCastle = 3,	-- +5°C in castles
			isMushroom = -2,  -- -2°C in Telvanni towers
		},
		interiorComfortDriftMultiplier = 1.5,  -- Move toward comfortable 50% faster indoors
		
		-- Interior thresholds (wider comfort zone indoors)
		interiorThresholds = {
			comfortableMin = 15,  -- Normal comfort zone when interior
			comfortableMax = 25,
			warmMax = 35,
			hotMin = 35,
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- SIMPERIAL - civilised but the empire is everywhere
	-- ═══════════════════════════════════════════════════════════════════
	imperial = {
		comfortableMin = 15,
		comfortableMax = 25,
		warmMax = 37,  -- Slightly more heat tolerant (Cyrodiil jungle)
		hotMin = 37,
		
		-- More stable temperature changes
		heatGainRate = 0.90,  -- 10% slower to heat
		coldGainRate = 0.90,  -- 10% slower to cool
		
		-- Climate bonuses
		climateBonus = {
			urban = -5,	  -- +5°C in urban areas
			tropical = -5,   -- +5°C in tropical zones (Cyrodiil)
		},
		climatePenalty = {},
		
		-- Interior bonuses
		cellTypeBonus = {
			isHouse = 1,   -- +1°C in houses
			isCastle = 3,  -- +5°C in castles (Imperial architecture)
			isDwemer = -2,  -- -3°C in Dwemer ruins (Imperial interest)
		},
		fastInteriorAdaptation = true,  -- 2x adaptation speed when entering interior
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- KHAJIIT - desert-born and nocturnal
	-- ═══════════════════════════════════════════════════════════════════
	khajiit = {
		comfortableMin = 15,
		comfortableMax = 32,  -- Extended heat comfort
		warmMax = 42,  -- Very heat tolerant
		hotMin = 42,
		
		-- Standard rates (modified at night)
		heatGainRate = 1.0,
		coldGainRate = 1.0,
		
		-- Climate bonuses/penalties
		climateBonus = {
			tropical = -5,   -- +5°C in tropical zones
			ashland = -3,	-- +3°C in ashlands
		},
		climatePenalty = {
			urban = 3,	 -- -3°C in urban areas (uncomfortable indoors)
		},
		
		-- Night bonus (implemented later)
		nightColdReduction = 0.6,  -- Cold gain rate 0.8x at night (20:00-6:00)
		
		-- Cold environment penalty
		coldEnvironmentPenalty = -5,  -- -5°C in cold environments
		
		-- Threshold rate modifier
		thresholdRates = {
			{ from = 32, to = 42, rate = 0.75 },  -- 25% longer warm→hot (desert adaptation)
		},
		
		-- Dry equipment bonus (implemented later)
		dryEquipmentBonus = 0.3,  -- +0.3 warmth per piece when not wet
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- NORD - from the land of snow and sorrow
	-- ═══════════════════════════════════════════════════════════════════
	nord = {
		comfortableMin = 0,   -- Comfortable in freezing temps
		comfortableMax = 20,  -- Narrower heat comfort
		warmMax = 30,
		hotMin = 30,
		
		-- Slow to cool, fast to heat
		heatGainRate = 1.25,  -- Warms 25% faster (overheats in heat)
		coldGainRate = 0.5,   -- Cools 50% slower (frost resistance)
		
		-- Climate bonuses/penalties
		climateBonus = {
			arctic = 5,	-- +5°C in arctic regions
			cold = 2,	   -- +2°C in cold regions
			temperate = -1,  -- -1°C in temperate
		},
		climatePenalty = {
			volcanic = -1,  -- -1°C in volcanic regions (too hot)
			tropical = -1,  -- -1°C in tropical regions
		},
		
		-- Equipment effectiveness
		armorMultipliers = {
			heavy = 1.5,  -- Heavy armor 50% more effective
		},
		
		-- Heat source effectiveness
		heatSourceRadiusMultiplier = 1.25,  -- 25% larger warmth radius from fires
		
		-- Interior bonuses
		cellTypeBonus = {
			isIceCave = 8,  -- +8°C in ice caves (native environment)
			isHouse = 2,	-- +3°C in houses
			isCastle = 5,   -- +3°C in castles
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- ORC - mountain resilience
	-- ═══════════════════════════════════════════════════════════════════
	orc = {
		comfortableMin = 12,  -- Wider comfort zone
		comfortableMax = 28,
		warmMax = 35,
		hotMin = 35,
		
		-- Very stable (hardy)
		heatGainRate = 0.85,  -- 15% slower to heat
		coldGainRate = 0.85,  -- 15% slower to cool
		
		-- Climate bonuses (no specific climate preference)
		climateBonus = {},
		climatePenalty = {},
		
		-- Equipment effectiveness
		armorMultipliers = {
			medium = 1.5,  -- Medium armor 50% more effective
		},
		
		-- Interior bonuses
		cellTypeBonus = {
			isDaedric = 1,  -- +3°C in Daedric shrines (Malacath)
			isCave = 3,	 -- +3°C in caves
			isMine = 3,	 -- +3°C in mines
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- REDGUARD - desert warriors
	-- ═══════════════════════════════════════════════════════════════════
	redguard = {
		comfortableMin = 10,
		comfortableMax = 30,  -- Extended comfort zone
		warmMax = 40,  -- Very heat-tolerant
		hotMin = 40,
		
		-- Standard rates
		heatGainRate = 1.0,
		coldGainRate = 1.1,  -- 10% faster to cool (less cold-adapted)
		
		-- Climate bonuses/penalties
		climateBonus = {
			grassland = -5,  -- +5°C in grasslands
			tropical = -3,   -- -3°C in tropical zones
			ashland = -3,	-- +3°C in ashlands (desert-like)
		},
		climatePenalty = {
			arctic = -2,	-- -2°C in arctic
			cold = -1,	  -- -1°C in cold regions
		},
		
		-- Equipment effectiveness
		armorMultipliers = {
			light = 1.5,  -- Light armor 50% more effective
		},
		
		-- Heat source effectiveness
		heatSourceMultiplier = 1.2,  -- All fires 20% more effective
		
		-- Night cooling (implemented later)
		nightCoolingBonus = 1.3,  -- Cool 30% faster at night in hot climates
		
		-- Threshold rate modifier
		thresholdRates = {
			{ from = 30, to = 40, rate = 0.5 },  -- 50% longer warm→hot
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════
	-- WOOD ELF - "Forest-born wanderers"
	-- ═══════════════════════════════════════════════════════════════════
	bosmer = {
		comfortableMin = 12,
		comfortableMax = 28,
		warmMax = 40,  -- Heat-tolerant (Valenwood)
		hotMin = 40,
		
		-- Standard rates
		heatGainRate = 1.0,
		coldGainRate = 1.0,
		
		-- Climate bonuses/penalties
		climateBonus = {
			tropical = -3,	 -- +1°C in tropical regions (Valenwood)
			grassland = -3,	-- +3°C in grasslands
		},
		climatePenalty = {
			arctic = -1,	  -- -1°C in arctic
			cold = -1,		-- -1°C in cold regions
			urban = 2,	   -- -2°C in urban areas (uncomfortable)
		},
		
		-- Equipment effectiveness
		armorMultipliers = {
			light = 1.5,  -- Light armor 50% more effective
		},
		
		-- Interior bonuses
		cellTypeBonus = {
			isMushroom = 3,  -- +3°C in Telvanni mushrooms (forest-like)
		},
		
		-- Wilderness bonus (implemented later)
		wildernessBonus = 0.85,  -- Temperature changes 15% slower in non-urban exteriors
		urbanPenalty = 1.15,	 -- Temperature changes 15% faster in urban/interior
	},
}

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Race Detection Helper									              │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getPlayerRace()
	if not saveData.playerInfo then
		return "default"
	end
	
	-- Check race flags from sd_p.lua
	if saveData.playerInfo.isFarmingTool then return "argonian"
	elseif saveData.playerInfo.isKhajiit then return "khajiit"
	elseif saveData.playerInfo.isNord then return "nord"
	elseif saveData.playerInfo.isBreton then return "breton"
	elseif saveData.playerInfo.isBosmer then return "bosmer"
	elseif saveData.playerInfo.isAltmer then return "altmer"
	elseif saveData.playerInfo.isImperial then return "imperial"
	elseif saveData.playerInfo.isDunmer then return "dunmer"
	elseif saveData.playerInfo.isRedguard then return "redguard"
	elseif saveData.playerInfo.isOrc then return "orc"
	end
	
	return "default"
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Get Racial Temperature Thresholds						              │
-- ╰──────────────────────────────────────────────────────────────────────╯

function getRacialTemperatureThresholds(printDebug)

	-- ═══════════════════════════════════════════════════════════════════
	-- High Elf Thresholds - narrower comfort zone outdoors, wider indoors
	-- ═══════════════════════════════════════════════════════════════════
	local thresholds = {
		comfortableMin = racialData.comfortableMin,
		comfortableMax = racialData.comfortableMax,
		warmMax = racialData.warmMax,
		hotMin = racialData.hotMin,
	}
	
	if racialData.interiorThresholds then
		if not G_cellInfo.isExterior and racialData.interiorThresholds then
			-- use wider thresholds indoors
			thresholds.comfortableMin = racialData.interiorThresholds.comfortableMin
			thresholds.comfortableMax = racialData.interiorThresholds.comfortableMax
			thresholds.warmMax = racialData.interiorThresholds.warmMax
			thresholds.hotMin = racialData.interiorThresholds.hotMin
			if printDebug then
				tempDbg.p(13, string.format("  %s: Interior thresholds: %s-%s", 
					race, formatTemperature(thresholds.comfortableMin), formatTemperature(thresholds.comfortableMax)))
			end
		else
			-- using narrower exterior thresholds
			if printDebug then
				tempDbg.p(13, string.format("  %s: Exterior thresholds: %s-%s comfortable", 
					race, formatTemperature(thresholds.comfortableMin), formatTemperature(thresholds.comfortableMax)))
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════
	-- Vampire and Werewolf Threshold Modifications
	-- ═══════════════════════════════════════════════════════════════
	if NEEDS_TEMP_VW ~= "Disable" then
		-- Vampire: Comfortable from -5 to 20, hot begins at 35
		if saveData.playerInfo.isVampire > 0 then
			thresholds.comfortableMin = -5
			thresholds.comfortableMax = 20
			thresholds.warmMax = 35
			thresholds.hotMin = 35
			
			if NEEDS_TEMP_VW == "Immortal" then
				-- Immortal vampires reach scorching sooner (at 40 instead of 45)
				thresholds.hotMin = 30
				if printDebug then
					tempDbg.p(13, string.format("  Vampire (Immortal): Comfortable %s to %s, Scorching at %s", 
						formatTemperature(thresholds.comfortableMin), formatTemperature(thresholds.comfortableMax), 
						formatTemperature(thresholds.hotMin + 10)))
				end
			else
				if printDebug then
					tempDbg.p(13, string.format("  Vampire (Supernatural): Comfortable %s to %s", 
						formatTemperature(thresholds.comfortableMin), formatTemperature(thresholds.comfortableMax)))
				end
			end
		end
		
		-- Werewolf: Comfortable down to -5
		if saveData.playerInfo.isWerewolf > 0 then
			thresholds.comfortableMin = -5
			if printDebug then
				tempDbg.p(13, string.format("  Werewolf: Comfortable from %s", 
					formatTemperature(thresholds.comfortableMin)))
			end
		end
	end
	
	G_idealTemperature = (thresholds.comfortableMin + thresholds.comfortableMax)/2
	thresholds.race = race
	return thresholds
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Get Climate Zone Modifiers								              │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getRacialClimateModifier(environmentTemp)
	
	if not racialData or not climateType then
		return 0
	end
	
	local totalModifier = 0
	local appliedBonuses = {}
	
	-- apply climate bonus if this climate type has one
	if racialData.climateBonus and racialData.climateBonus[climateType] then
		local bonus = racialData.climateBonus[climateType]
		totalModifier = totalModifier + bonus
		table.insert(appliedBonuses, string.format("  %s (%s)", formatTemperatureModifier(bonus), climateType))
	end
	
	-- apply climate penalty if this climate type has one
	if racialData.climatePenalty and racialData.climatePenalty[climateType] then
		local penalty = racialData.climatePenalty[climateType]
		totalModifier = totalModifier + penalty
		table.insert(appliedBonuses, string.format("  %s (%s)", formatTemperatureModifier(penalty), climateType))
	end
	
	-- Apply cold environment penalty if applicable
	if racialData.coldEnvironmentPenalty and environmentTemp <= 15 then
		local applyPenalty = true
		
		-- Check for exemptions (exp - Dark Elf in ashlands)
		if racialData.coldPenaltyExemptZones then
			for _, exemptType in ipairs(racialData.coldPenaltyExemptZones) do
				if climateType == exemptType then
					applyPenalty = false
					break
				end
			end
		end
		
		if applyPenalty then
			totalModifier = totalModifier + racialData.coldEnvironmentPenalty
			table.insert(appliedBonuses, string.format("  %s (cold env penalty)", formatTemperatureModifier(racialData.coldEnvironmentPenalty)))
		end
	end
	
	-- Debug output
	if #appliedBonuses > 0 then
		tempDbg.p(13, string.format("  %s: climate: %s", race, table.concat(appliedBonuses, ", ")))
	end
	
	return totalModifier
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Get Equipment Type Multiplier							              │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getRacialArmorMultiplier(weightClass)
	
	if not racialData or not racialData.armorMultipliers or not racialData.armorMultipliers[weightClass] then
		return 1.0
	end
	
	tempDbg.p(14, string.format("  %s: clothing mult: %.1f", race, racialData.armorMultipliers[weightClass]))
	return racialData.armorMultipliers[weightClass]
end

-- Get clothing effectiveness multiplier
local function getRacialClothingMultiplier()
	
	if not racialData or not racialData.armorMultipliers or not racialData.armorMultipliers.clothing then
		return 1.0
	end
	tempDbg.p(14, string.format("  %s: clothing mult: %.1f", race, racialData.armorMultipliers.clothing))
	return racialData.armorMultipliers.clothing or 1.0
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Get Heat Source Multipliers								          │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getRacialHeatSourceMultipliers()
	
	local intensityMult = 1.0
	local radiusMult = 1.0
	
	if racialData then
		intensityMult = racialData.heatSourceMultiplier or 1.0
		radiusMult = racialData.heatSourceRadiusMultiplier or 1.0
	end
	
	return intensityMult, radiusMult
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Get Interior Cell Type Bonus							              │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getRacialCellTypeBonus()
	
	if not racialData or not racialData.cellTypeBonus or not G_cellInfo then
		return 0
	end
	
	local totalBonus = 0
	local appliedBonuses = {}
	
	-- Check each cell type flag
	for cellType, bonus in pairs(racialData.cellTypeBonus) do
		if G_cellInfo[cellType] then
			totalBonus = totalBonus + bonus
			-- Convert cellType to readable name (isTomb -> Tomb, isHouse -> House)
			local cellName = cellType:gsub("^is", ""):gsub("(%u)", " %1"):sub(2)
		table.insert(appliedBonuses, string.format("  %s: %s", cellName, formatTemperatureModifier(bonus)))
		end
	end
	
	if #appliedBonuses > 0 then
		tempDbg.p(13, string.format("  %s: Cell bonuses: %s", race, table.concat(appliedBonuses, ", ")))
	end
	
	return totalBonus
end


-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Get Wetness Equipment Bonus								          │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getRacialWetnessEquipmentBonus(equipmentPieces)
	
	-- Only Khajiit has this bonus
	if not racialData.dryEquipmentBonus then
		return 0
	end
	
	-- Only applies when not wet (wetness < 0.1)
	if not tempData.water or tempData.water.wetness >= 0.1 then
		return 0
	end
	if climateTemperature > 20 then
		return 0
	end
	-- Calculate bonus: +0.3°C warmth per equipment piece when dry
	local bonus = equipmentPieces * racialData.dryEquipmentBonus
	
	if bonus > 0 then
		tempDbg.p(13, string.format("  %s: Dry equipment bonus: %s", race, formatTemperatureModifier(bonus)))
	end
	
	return bonus
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Vector-Based Climate Calculation									  │
-- │ Temperature changes based on proximity to climate sources			  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local lastClimateTempUpdate = 0
local function getClimateTempFromPosition(dt)
	if core.getSimulationTime() == lastClimateTempUpdate then return end
	if not cell or not cell.isExterior then 
		if G_cellInfo.isExterior then
			climateType = "urban"
			climateTemperature = 26
			local matchingString = "?"
			local maxPriority = -99999
			--print(cell.id,cell.name,cell.displayName)
			if cell then
				for _, source in pairs(QUASI_EXTERIOR_CLIMATE_SOURCES) do
					if cell.id:find(source.match, 1, true) and source.priority > maxPriority then
						climateType = source.climate
						climateTemperature = source.temperature
						maxPriority = source.priority
						matchingString = source.match
					end
				end
			end
			climateTempTooltip3 = string.format("  QuasiExterior: %s (%s, %s)", matchingString, climateType, formatTemperature(climateTemperature) )
		end
		return 
	end
	
	climateTempTooltip2 = {}
	lastClimateTempUpdate = core.getSimulationTime()
	local pos = self.position
	local additiveIntensity = 0
	local maxIntensity = 0
	local maxIntensityMagnitude = 0
	local smoothValues = {}
	local smoothPower = 8
	
	local dominantType = nil
	local maxInfluence = 0	
	local maxInfluence2 = 0	
	
	--tempDbg.p(15, string.format("Checking climate at position: (%.0f, %.0f, %.0f)", pos.x, pos.y, pos.z))
	climateTempTooltip1 = string.format("  Checking climate at position: (%.0f, %.0f, %.0f)", pos.x, pos.y, pos.z)
	
	isOnRedMountain = 0
	for _, source in ipairs(CLIMATE_SOURCES) do
		-- Calculate distance to this climate source
		local distance = (pos - source.position):length()
		
		-- Calculate influence based on distance
		if distance < source.radius then
			local influence
			local centerRadius = source.centerRadius or 0
			local influence2 = distance/source.radius
			if distance <= centerRadius then
				-- Within center radius: full intensity
				influence = 1
			else
				-- Between center radius and outer radius: calculate falloff
				local effectiveRadius = source.radius - centerRadius
				local effectiveDistance = distance - centerRadius
				influence = (1 - (effectiveDistance / effectiveRadius)) ^ (source.exponent or 1)
			end
			-- Apply square for sharper falloff (default behavior for compatibility)
			-- Can be disabled per-source with squareInfluence = false
			if G_forceSquareFalloff ~= nil then
				if G_forceSquareFalloff then
					influence = influence * influence
				else
					--nothing
				end
			end
			
			
			
			if source.name:lower():find("red mountain") and influence >= 0.1 then
				isOnRedMountain = isOnRedMountain + influence
			end			
			
			local localIntensity = source.intensity * influence
			
			-- Apply blend mode
			if source.blendMode == 2 then
				-- Max: strongest effect wins (by absolute magnitude)
				local magnitude = math.abs(localIntensity)
				if magnitude > maxIntensityMagnitude then
					maxIntensityMagnitude = magnitude
					maxIntensity = localIntensity
				end
			elseif source.blendMode == 3 then
				-- Smooth: blends smoothly using power mean
				table.insert(smoothValues, localIntensity)
			else --if source.blendMode == 1 then
				-- Additive: temperatures stack
				additiveIntensity = additiveIntensity + localIntensity
			end
			
			-- Track dominant climate type (the one with most influence)
			if influence > maxInfluence or influence == maxInfluence and influence2 > maxInfluence2 then
				maxInfluence = influence
				maxInfluence2 = influence2
				dominantType = source.climate
			end
			
			--tempDbg.p(15, string.format("%s (%s, mode=%d): dist=%.0f, influence=%.2f, intensity=%s", 
			--	source.name, source.climate or "none", blendMode or 1, distance, influence, (((localIntensity)>=0) and "+" or "")..formatTemperatureModifier(localIntensity)))
				
			table.insert(climateTempTooltip2,string.format("  %s (%s, mode=%d): dist=%.0f, influence=%.2f, intensity=%s", 
				source.name, source.climate or "none", source.blendMode or 1, distance, influence, formatTemperatureModifier(localIntensity)))
		end
	end
	
	
	-- Calculate smooth blend using signed power mean
	local smoothIntensity = 0
	if #smoothValues > 0 then
		local weightedSum = 0
		local weightSum = 0
		
		for _, val in ipairs(smoothValues) do
			local absVal = math.abs(val)
			local weight = absVal ^ (smoothPower - 1)
			weightedSum = weightedSum + val * weight
			weightSum = weightSum + weight
		end
		
		if weightSum > 0 then
			smoothIntensity = weightedSum / weightSum
		end
	end
	
	-- Combine all blend mode contributions
	local totalIntensity = additiveIntensity + maxIntensity + smoothIntensity
	local finalTemp = WORLD_BASE_TEMP + totalIntensity
	
	--tempDbg.p(13, string.format("Base: %s, Add: %+.1f, Max: %+.1f, Smooth: %+.1f, Final: %s", 
	--	formatTemperature(WORLD_BASE_TEMP), additiveIntensity, maxIntensity, smoothIntensity, formatTemperature(finalTemp)))
	climateTempTooltip3 = string.format("  Base: %s, Add: %+.1f, Max: %+.1f, Smooth: %+.1f, Final: %s", 
		formatTemperature(WORLD_BASE_TEMP), additiveIntensity, maxIntensity, smoothIntensity, formatTemperature(finalTemp))
	
	climateType = dominantType
	climateTemperature = finalTemp
end

--table.insert(G_onFrameJobsSluggish,getClimateTempFromPosition)
table.insert(G_sluggishScheduler, {getClimateTempFromPosition})
G_onFrameJobsSluggish.getClimateTempFromPosition = getClimateTempFromPosition

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Solar Heating														  │
-- │ The sun warms you during the day									  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getSolarHeating(cell, hour)
	if not cell or not G_cellInfo.isExterior then 
		return 0 
	end
	
	-- Solar heating curve: peaks at noon (hr 12), 0 at night
	local timeOfDayFactor = math.sin((hour - 6) / 12 * math.pi) -- shifted by -6 so that it starts at 6am and ends at 6pm
	timeOfDayFactor = math.max(0, timeOfDayFactor) -- only positive during day
	
	-- Maximum solar heating of 9 degrees at noon
	local solarHeat = timeOfDayFactor * 9
	
	-- NIGHT COOLING/WARMING based on climate type
	-- When timeOfDayFactor is 0 (night time), apply climate-specific effects
	if timeOfDayFactor <= 0.1 then -- Night time or near night
		local nightEffect = 0

		if climateType == "ashland" or climateType == "arctic" or climateType == "cold" then
			-- Ashlands get cold at night (desert wasteland)
			nightEffect = -8
			
			tempDbg.p(14, string.format("  %s night cooling: %s", climateType, formatTemperatureModifier(-8)))
			
		elseif climateType == "volcanic" or climateType == "tropical" then
			-- these climates stay warm from heat retention
			nightEffect = 4
			
			tempDbg.p(14, string.format("  %s night warmth: %s", climateType, formatTemperatureModifier(4)))
		
--[[		elseif climateType == "mountain" then
--			-- mountains get colder at night from altitude
--			nightEffect = -5
			tempDbg.p(14, " Mountain night cooling: " .. formatTemperatureModifier(5))
]]
		elseif climateType == "coast" or climateType == "urban" then
			-- Coast has moderate temperature from ocean effect ; urban also moderate temperature bc of population + lights and whatnot
			nightEffect = -2
			
			tempDbg.p(14, string.format("  %s moderate night: %s", climateType, formatTemperatureModifier(-2)))
		else
			-- Grassland, temperate : normal night cooling
			nightEffect = -4
			
			tempDbg.p(14, "  Normal night cooling: " .. formatTemperatureModifier(-4))
		end
		
		solarHeat = solarHeat + nightEffect
	end
	
	
	tempDbg.p(13, string.format("  Solar: hour=%.1f, factor=%.2f, heat=%s, climate=%s", hour, timeOfDayFactor, formatTemperatureModifier(solarHeat), climateType or "temperate"))	
		
	return solarHeat
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Calculate Water Temperature										│
-- ╰────────────────────────────────────────────────────────────────────╯

local function getWaterTemperature(currentEnvironmentTemp)
	-- Water is ALWAYS cooler than air (70-75% of air temp)
	
	local waterTemp
	
	if climateType == "arctic" then
		waterTemp = currentEnvironmentTemp - 20
		
	elseif currentEnvironmentTemp < 10 then
		waterTemp = currentEnvironmentTemp - 3
		
	elseif currentEnvironmentTemp < 15 then
		waterTemp = math.max(0, currentEnvironmentTemp * 0.7)
		
	elseif currentEnvironmentTemp < 25 then
		waterTemp = currentEnvironmentTemp * 0.75
		
	else
		waterTemp = math.min(25, currentEnvironmentTemp * 0.65)
	end
	
	return waterTemp
end

-- ================================================== EQUIPMENT MODIFIERS ==================================================

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Equipment Tag Detection System								  		│
-- │ Basic infrastructure for tracking equipped items					│
-- ╰────────────────────────────────────────────────────────────────────╯

-- Slots to ignore for temperature calculations
local ignoredSlots = {
	[types.Actor.EQUIPMENT_SLOT.CarriedRight] = true,  
	[types.Actor.EQUIPMENT_SLOT.Ammunition] = true,
	[types.Actor.EQUIPMENT_SLOT.RightRing] = true,
	[types.Actor.EQUIPMENT_SLOT.LeftRing] = true,
	[types.Actor.EQUIPMENT_SLOT.Belt] = true,
	[types.Actor.EQUIPMENT_SLOT.Amulet] = true,
	-- Note: CarriedLeft (shield) is NOT ignored - shields affect temperature!
}

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Material Tag Detection												  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function detectMaterialTags(item)
	local recordId = item.recordId
	if recordId:sub(1, 10) ~= "Generated:" then
		local name = item.type.record(item).name:lower()
		local heatRes = nil
		local coldRes = nil 
		local waterRes = nil 
		local materialName = nil
		local materialName2 = nil
		
		-- Check heat-resistant materials
		for tag, data in pairs(ARMOR_RESISTANCES) do
			if recordId:find(tag) or name:find(tag) then
				if data.heat and (not heatRes or data.heat > heatRes) then
					heatRes = data.heat
					materialName = data.name
				end
				if data.cold and (not coldRes or data.cold > coldRes) then
					coldRes = data.cold
					materialName2 = data.name
				end 
				if data.water and (not waterRes or data.water > waterRes) then
					waterRes = data.water
				end
			end
		end
		if materialName and materialName2 then
			materialName = materialName .. "/" .. materialName2
		else
			materialName = materialName or materialName2
		end
		return heatRes, coldRes, waterRes, materialName
	elseif not armorCache[item.recordId] then
		local record = item.type.record(item)
		local model = record.model
		local bestHeatRes = nil
		local bestColdRes = nil
		local bestWaterRes = nil
		local bestMaterialName = nil
		local bestScore = 0
		for _, record in pairs(item.type.records) do
			if record.model == model then
				local recordId = record.id
				local name = record.name:lower()
				local heatRes = nil
				local coldRes = nil 
				local waterRes = nil 
				local materialName = nil
				
				-- Check heat-resistant materials
				for tag, data in pairs(ARMOR_RESISTANCES) do
					if recordId:find(tag) or name:find(tag) then
						if data.heat and (not heatRes or data.heat > heatRes) then
							heatRes = data.heat
							materialName = data.name
						end
						if data.cold and (not coldRes or data.cold > coldRes) then
							coldRes = data.cold
							materialName2 = data.name
						end
						if data.water and (not waterRes or data.water > waterRes) then
							waterRes = data.water
						end
					end
				end
				if materialName and materialName2 then
					materialName = materialName .. "/" .. materialName2
				else
					materialName = materialName or materialName2
				end
				
				if (heatRes or 0) + (coldRes or 0) > bestScore then
					bestScore = (heatRes or 0) + (coldRes or 0)
					bestHeatRes = heatRes
					bestColdRes = coldRes
					bestWaterRes = waterRes
					bestMaterialName = materialName
				end
			end
			armorCache[item.recordId] = {bestHeatRes, bestColdRes, bestWaterRes, bestMaterialName}
		end
	end
	--return heatRes, coldRes, waterRes, materialName
	return armorCache[item.recordId][1],armorCache[item.recordId][2],armorCache[item.recordId][3], armorCache[item.recordId][4]
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Armor Weight Class Detection					  		              │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getArmorWeightClass(armorItem)
	if not armorItem or armorItem.type ~= types.Armor then
		return nil
	end
	
	local record = armorItem.type.record(armorItem)
	local weight = record.weight
	
	-- light  = Glass, Chitin, Netch
	-- medium = Bonemold, Scale, Chain
	-- heavy =  Iron, Steel, Orcish, Daedric, Ebony
	
	return getArmorWeight(record), weight
end

-- Get temperature modifiers based on armor weight class
-- Returns: heatMod, coldMod (positive = warmer, negative = cooler)
local function getArmorWeightModifiers(weightClass, slot)
	if not weightClass then return 0, 0 end
	
	local heatMod = 0
	local coldMod = 0
	local waterMod = 0
	
	-- Heavy armor: worse in heat (traps body heat), better in cold (insulation)
	if weightClass == "heavy" then
		heatMod = -1.5  -- Makes you feel hotter in hot weather
		coldMod = 1.0   -- Makes you feel warmer in cold weather
		waterMod = 2
	-- Medium armor: slight effects both ways
	elseif weightClass == "medium" then
		heatMod = -0.75 -- Slight heat penalty
		coldMod = 0.5   -- Slight cold bonus
		waterMod = 3.5
	-- Light armor: better in heat (breathable), worse in cold (less insulation)
	elseif weightClass == "light" then
		heatMod = 0.5   -- Feels cooler in hot weather
		coldMod = -0.5  -- Feels colder in cold weather
		waterMod = 5
	end
	
	-- Apply racial armor weight class multipliers
	local racialMult = getRacialArmorMultiplier(weightClass)
	if racialMult ~= 1.0 then
		heatMod = heatMod * racialMult
		coldMod = coldMod * racialMult
		waterMod = waterMod * racialMult
		-- Debug output handled in scanEquipment
	end
	
	-- Shields have reduced impact (only one piece)
	-- if slot == types.Actor.EQUIPMENT_SLOT.CarriedLeft then
	-- 	 heatMod = heatMod * 0.4
	-- 	 coldMod = coldMod * 0.4
	-- end
	
	return heatMod, coldMod, waterMod
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Clothing & Layering Effects							              │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- Calculate clothing temperature modifier
-- Robes provide cooling when worn alone, less when layered
-- Calculate clothing temperature modifier
-- Clothing provides insulation that works both ways: keeps heat out OR keeps warmth in
local function getClothingModifier(environmentTemp)
	local modifier = 0
	
	-- Count clothing layers (not including robe)
	local layers = 0
	if equipmentData.hasShirt then layers = layers + 1 end
	if equipmentData.hasSkirt then layers = layers + 1 end
	if equipmentData.hasPants then layers = layers + 1 end
	
	-- HOT ENVIRONMENT (>30°C): Layering provides insulation from heat
	if environmentTemp > 30 then
		-- Robe + layers: Good insulation from external heat
		if equipmentData.hasRobe and layers >= 2 then
			modifier = modifier - 3.0  -- Excellent heat protection
			tempDbg.p(14, string.format("  Robe + %d layers in heat: %s (good insulation)", layers, formatTemperatureModifier(-3.0)))
		
		-- Robe + 1 layer: Good insulation
		elseif equipmentData.hasRobe and layers == 1 then
			modifier = modifier - 2.0  -- Good heat protection
				tempDbg.p(14, "  Robe + 1 layer in heat: " .. formatTemperatureModifier(-2.0))
		
		-- Robe alone: Decent airflow
		elseif equipmentData.hasRobe and layers == 0 then
			modifier = modifier - 1.5  -- Airflow cooling
				tempDbg.p(14, "  Robe alone in heat: " .. formatTemperatureModifier(-1.5) .. " (airflow)")
		
		-- Shirt + Pants (no robe): Moderate heat protection
		elseif equipmentData.hasShirt and equipmentData.hasPants and not equipmentData.hasRobe then
			modifier = modifier - 1.5  -- Decent insulation
				tempDbg.p(14, "  Shirt + Pants in heat: " .. formatTemperatureModifier(-1.5))
		
		-- Shirt + Skirt (no robe): Light protection
		elseif equipmentData.hasShirt and equipmentData.hasSkirt and not equipmentData.hasRobe then
			modifier = modifier - 1.0
				tempDbg.p(14, "  Shirt + Skirt in heat: " .. formatTemperatureModifier(-1.0))
		end
	
	-- COLD ENVIRONMENT (<15°C): Layering traps body heat
	elseif environmentTemp < 15 then
		if tempData.water.wetness < 0.1 then
			-- Robe + layers: Excellent warmth retention
			if equipmentData.hasRobe and layers >= 2 then
				modifier = modifier + 3.0  -- Maximum warmth
					tempDbg.p(14, string.format("  Robe + %d layers in cold: %s (excellent warmth)", layers, formatTemperatureModifier(3.0)))
			
			-- Robe + 1 layer: Good warmth
			elseif equipmentData.hasRobe and layers == 1 then
				modifier = modifier + 2.0
					tempDbg.p(14, "  Robe + 1 layer in cold: " .. formatTemperatureModifier(2.0))
			
			-- Robe alone: Some warmth but not great
			elseif equipmentData.hasRobe and layers == 0 then
				modifier = modifier + 0.5  -- Robes alone aren't warm
					tempDbg.p(14, "  Robe alone in cold: " .. formatTemperatureModifier(0.5) .. " (not ideal)")
			
			-- Shirt + Pants (no robe): Decent warmth
			elseif equipmentData.hasShirt and equipmentData.hasPants and not equipmentData.hasRobe then
				modifier = modifier + 1.5  -- Good layering
					tempDbg.p(14, "  Shirt + Pants in cold: " .. formatTemperatureModifier(1.5))
			
			-- Shirt + Skirt (no robe): Light warmth
			elseif equipmentData.hasShirt and equipmentData.hasSkirt and not equipmentData.hasRobe then
				modifier = modifier + 1.0
					tempDbg.p(14, "  Shirt + Skirt in cold: " .. formatTemperatureModifier(1.0))
			
			-- More layers = more warmth in cold
			elseif layers >= 2 then
				local layerBonus = layers * 0.75
				modifier = modifier + layerBonus
					tempDbg.p(14, string.format("  %d layers in cold: %s", layers, formatTemperatureModifier(layerBonus)))
			end
		end
	-- MODERATE ENVIRONMENT (15-30°C): Minimal effects
	else
		-- In moderate temps, clothing has minimal impact
		if equipmentData.hasRobe then
			modifier = modifier - 0.5  -- Slight cooling from airflow
				tempDbg.p(14, "  Robe in moderate temp: " .. formatTemperatureModifier(-0.5))
		end
	end
	
	-- MAGE BONUS: Wearing only clothing (no armor)
	-- Mages in light robes have mastered temperature regulation
	local effectiveArmorPieces = equipmentData.armorPieces
	if equipmentData.hasHelmet then
		effectiveArmorPieces = effectiveArmorPieces - 1
	end
	if effectiveArmorPieces == 0 and equipmentData.clothingPieces > 0 then
		local mageBonus = 0
		
		if environmentTemp > 30 then
			-- Hot: Mages stay cool in their robes
			mageBonus = -2.5
				tempDbg.p(14, "  Mage bonus (no armor) in heat: " .. formatTemperatureModifier(-2.5))
		
		elseif environmentTemp < 15 then
			-- Cold: Mages stay warm despite light clothing
			mageBonus = 2.5
				tempDbg.p(14, "  Mage bonus (no armor) in cold: " .. formatTemperatureModifier(2.5))
		end
		
		modifier = modifier + mageBonus
	end
	
	-- Apply racial clothing effectiveness multiplier
	local clothingMult = getRacialClothingMultiplier()
	if clothingMult ~= 1.0 then
		modifier = modifier * clothingMult
		-- High Elves get 1.5x clothing effectiveness
	end
	
	return modifier
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Equipment Scanner													  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function scanEquipment()
	local equipment = types.Actor.getEquipment(self)
	
	-- Reset tracking
	equipmentData.waterResistance = 0	
	equipmentData.heatResistance = 0	
	equipmentData.coldResistance = 0
	equipmentData.armorPieces = 0
	equipmentData.clothingPieces = 0
	equipmentData.weightClassHeatMod = 0  -- NEW!
	equipmentData.weightClassColdMod = 0  -- NEW!
	
	local debugOutput = {}
	armorDbg.clear()
	armorDbg.p(15,"==== Equipment Scan ====")
	
	equipmentData.hasRobe =  false
	equipmentData.hasShirt = false
	equipmentData.hasSkirt = false
	equipmentData.hasPants = false
	equipmentData.hasHelmet = false
	equipmentData.hasUmbrella = 0
	equipmentData.hasTorch = nil
	
	-- Scan all equipment
	for slot, item in pairs(equipment) do
		-- Skip ignored slots (O(1) lookup)
		if not ignoredSlots[slot] then
			
			local recordId= item.recordId
			
			local itemRecord = item.type.record(item)
			local itemType = item.type
			local recordType = itemRecord.type
			if slot == types.Actor.EQUIPMENT_SLOT.CarriedLeft then
				local record = item.type.record(item)
				local name = record.name:lower()
				if name:find("parasol") or name:find("umbrella") then
					equipmentData.hasUmbrella = math.max(equipmentData.hasUmbrella, 0.66)
				else
					local recordId = record.id
					if recordId:find("torch") or recordId:find("torch") then
						equipmentData.hasTorch = 2
					elseif recordId:find("lantern") or name:find("lantern") then
						equipmentData.hasTorch = 2
					elseif recordId:find("lamp") or name:find("lamp") then
						equipmentData.hasTorch = 2
					elseif recordId:find("incense") or name:find("incense") then
						equipmentData.hasTorch = 2
					elseif recordId:find("candle") or name:find("candle") then
						equipmentData.hasTorch = 2
					end
				end
			end
			-- Count armor pieces
			if itemType == types.Armor then
				
				if slot == types.Actor.EQUIPMENT_SLOT.Helmet then
					if recordId == "gondolier_helm" then
						equipmentData.hasUmbrella = math.max(equipmentData.hasUmbrella, 0.5)
					elseif recordId:find("shroomhat") then
						equipmentData.hasUmbrella = math.max(equipmentData.hasUmbrella, 0.35)
					end
				end
				equipmentData.armorPieces = equipmentData.armorPieces + 1
				local weightClass, weight = getArmorWeightClass(item)
				local heatMod, coldMod, waterMod = getArmorWeightModifiers(weightClass, slot)
	
				-- Detect heat and cold resistant materials
				local heatRes, coldRes, waterRes, materialName = detectMaterialTags(item)
				if heatRes then
					equipmentData.heatResistance = equipmentData.heatResistance + heatRes
				end
				if coldRes then
					equipmentData.coldResistance = equipmentData.coldResistance + coldRes
				end
				if waterRes then
					equipmentData.waterResistance = equipmentData.waterResistance + waterRes
				else	
					equipmentData.waterResistance = equipmentData.waterResistance + waterMod
				end
				
				-- Detect armor weight class
				-- Special materials (those with heat/cold resistance) are exempt from weight penalties
				
				if not heatRes and not coldRes then
					-- Only apply weight class modifiers to non-special materials
					equipmentData.weightClassHeatMod = equipmentData.weightClassHeatMod + heatMod
					equipmentData.weightClassColdMod = equipmentData.weightClassColdMod + coldMod
				else
					heatMod = 0
					coldMod = 0
					-- Special material - skip weight class penalties
					armorDbg.p(15, string.format("  Special material '%s' exempt from weight penalties", materialName))
				end

				table.insert(debugOutput, string.format(
					"  [Armor] %s (%s, %s, %.1flbs) - Heat:%+d Cold:%+d WeightMod:H%+.1f/C%+.1f",
					item.recordId,
					materialName or "generic",
					weightClass or "unknown",
					weight or 0,
					heatRes or 0,
					coldRes or 0,
					heatMod or 0,
					coldMod or 0
				))
				if (recordType == types.Armor.TYPE.Helmet) then
					equipmentData.hasHelmet = true
				end
			-- Count clothing pieces
			elseif itemType == types.Clothing then
				equipmentData.waterResistance = equipmentData.waterResistance + 1
				equipmentData.clothingPieces = equipmentData.clothingPieces + 1
				table.insert(debugOutput, string.format(
					"  [Clothing] Slot: %s, Item: %s",
					slot, item.recordId
				))
				
				-- elseif (recordType == types.Clothing.TYPE.Amulet) then
				-- elseif (recordType == types.Clothing.TYPE.Belt) then
				-- elseif (recordType == types.Clothing.TYPE.LGlove) then
				-- elseif (recordType == types.Clothing.TYPE.RGlove) then
				-- elseif (recordType == types.Clothing.TYPE.Shoes) then				
				-- elseif (recordType == types.Clothing.TYPE.Ring) then
				
				if (recordType == types.Clothing.TYPE.Skirt) then
					equipmentData.hasSkirt = true
				elseif (recordType == types.Clothing.TYPE.Shirt) then
					equipmentData.hasShirt = true
				elseif (recordType == types.Clothing.TYPE.Robe) then
					equipmentData.hasRobe =  true
				elseif (recordType == types.Clothing.TYPE.Pants) then
					equipmentData.hasPants = true
				end
			end
		end
	end
	
	-- Print debug output
	for _, line in ipairs(debugOutput) do
		armorDbg.p(15, line)
	end
	
	armorDbg.p(15, string.format("Summary - Armor: %d pieces, Clothing: %d pieces", equipmentData.armorPieces, equipmentData.clothingPieces))
		armorDbg.p(15, string.format("Material Resist - Heat: %+d, Cold: %+d", equipmentData.heatResistance, equipmentData.coldResistance))
		armorDbg.p(15, string.format("Weight Class - Heat: %+.1f, Cold: %+.1f", equipmentData.weightClassHeatMod, equipmentData.weightClassColdMod))
		armorDbg.p(15, string.format("Clothing - Robe:%s Shirt:%s Skirt:%s Pants:%s", 
			tostring(equipmentData.hasRobe), tostring(equipmentData.hasShirt), 
			tostring(equipmentData.hasSkirt), tostring(equipmentData.hasPants)))
	armorDbg.p(15,string.format("Heat: %+d, Cold: %+d", 
		equipmentData.heatResistance, equipmentData.coldResistance))
	armorDbg.p(15, "Equipment Scan Results:")
	for a,b in pairs(equipmentData) do
		armorDbg.p(15,a,b)
	end
	equipmentData.lastUpdate = core.getGameTime()
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Calculate Equipment Temperature Modifier							  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getEquipmentTemperatureModifier(environmentTemp)
	local modifier = 0
	
	tempDbg.p(05, string.format("\n=== Equipment Modifier Calculation (Env: %s) ===", formatTemperature(environmentTemp)))
	
	-- Apply material-based resistance
	if environmentTemp > 30 and equipmentData.heatResistance ~= 0 then
		-- Hot environment: heat resistance helps (each point = 0.5°C cooler)
		local heatEffect = equipmentData.heatResistance * 0.45
		modifier = modifier - heatEffect
		tempDbg.p(14, string.format("[Material] Hot environment - Heat resistance: %d * 0.5 = %s", 
		equipmentData.heatResistance, formatTemperatureModifier(-heatEffect)))
	
	elseif environmentTemp < 15 and equipmentData.coldResistance ~= 0 then
		-- Cold environment: cold resistance helps (each point = 0.5°C warmer)
		local coldEffect = equipmentData.coldResistance * 0.5
		modifier = modifier + coldEffect
		tempDbg.p(14, string.format("[Material] Cold environment - Cold resistance: %d * 0.5 = %s", 
		equipmentData.coldResistance, formatTemperatureModifier(coldEffect)))
	end
	
	-- Apply armor weight class effects
	if environmentTemp > 30 and equipmentData.weightClassHeatMod ~= 0 then
		-- Hot: use heat modifiers (negative = hotter)
		modifier = modifier + equipmentData.weightClassHeatMod
		tempDbg.p(14, string.format("[Weight] Hot environment - Weight class modifier: %s", formatTemperatureModifier(equipmentData.weightClassHeatMod)))
		
	elseif environmentTemp < 15 and equipmentData.weightClassColdMod ~= 0 then
		-- Cold: use cold modifiers (positive = warmer)
		modifier = modifier + equipmentData.weightClassColdMod
		tempDbg.p(14, string.format("[Weight] Cold environment - Weight class modifier: %s", formatTemperatureModifier(equipmentData.weightClassColdMod)))
	end
	
	-- Apply clothing and layering effects
	local clothingMod = getClothingModifier(environmentTemp)
	modifier = modifier + clothingMod
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Racial Wetness Equipment Penalty (Khajiit)
	-- ═══════════════════════════════════════════════════════════════════
	
	local totalEquipmentPieces = equipmentData.armorPieces + equipmentData.clothingPieces
	local wetnessBonus = getRacialWetnessEquipmentBonus(totalEquipmentPieces)
	if wetnessBonus > 0 then
		modifier = modifier + wetnessBonus
	end
	if modifier ~= 0 then
		tempDbg.p(12, string.format("Equipment mod: %s", formatTemperatureModifier(modifier)))
	end
	
	return modifier
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Equipment Change Handler											  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function onEquipmentChanged(unequipped, equipped)
	if not NEEDS_TEMP then return end
	tempDbg.clear()
	G_temperatureWidgetTooltip = ""
	
	--log(11, "\n===== Equipment Changed (Phase 2.1) =====")
	--
	--if next(equipped) then
	--	log(11, "Equipped:")
	--	for slot, item in pairs(equipped) do
	--		log(11, string.format("  %s: %s", slot, item.recordId))
	--	end
	--end
	--
	--if next(unequipped) then
	--	log(11, "Unequipped:")
	--	for slot, item in pairs(unequipped) do
	--		log(11, string.format("  %s: %s", slot, item.recordId))
	--	end
	--end
	
	--if not next(equipped) then
	--	equipped = nil
	--end
	
	-- Rescan equipment
	scanEquipment()
	
	-- Recalculate temperature with new equipment
	tempData.targetTemp = calculateEnvironmentTemperature()
	updateTemperatureWidget()
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Interior Temperature												  │
-- │ Default comfortable temperature for interiors						  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getInteriorTemperature(cell)
	-- consider applying solar temp to interiors to make interior temperatures more dynamic
	local temp = 20
	local interiorType = "Unknown, reverting to default interior temperature"
	
	
	if G_cellInfo then
		if G_cellInfo.isIceCave then
			temp = 5
			interiorType = "Ice Cave"
		
		elseif G_cellInfo.isDwemer then
			temp = 30
			interiorType = "Dwemer"
		
		elseif G_cellInfo.isDaedric then
			temp = 27
			interiorType = "Daedric"
		
		elseif G_cellInfo.isCave or G_cellInfo.isCastle or G_cellInfo.isTomb then
			temp = 15
			interiorType = "Castle/Fort, Tomb, or Cave/Dungeon"
		
		elseif G_cellInfo.isMushroom or G_cellInfo.isBath then
			temp = 25
			interiorType = "Telvanni Shroom"
			
		elseif G_cellInfo.isHouse or G_cellInfo.isMine then -- or if not in G_cellInfo ? 
			temp = 20
			if G_cellInfo.isHouse then
				interiorType = "House/Residence"
			elseif G_cellInfo.isMine then
				interiorType = "Mine"
			end
--[[	elseif G_cellInfo.isAshlander then
			temp = 22
			interiorType = "Ashlander"
]]
		-- elseif G_cellInfo.[whatever] then
		--	temp = [insert whatever temp]
		--	interiorType = ""
		
		end
	end

	tempDbg.p(12, string.format("Interior: %s (%s) = %s", 
		cell.name or "Unknown, reverting to default interior temperature", interiorType, formatTemperature(temp)))
	
	return temp
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Campfire & Torch Effects								              │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- Detect nearby campfires using the isHeatSource API from sd_g
-- Heat sources are pre-scanned by sd_g and stored in saveData.G_cellInfo.fires
local function getNearbyHeatSources()
	local heatBonus = 0
	local nearestDistance = 9999
	local nearestSource = nil
	ignoreMaxTemperature = nil
	nearbyLava = nil
	nearbyHotMod = 0   -- Heat sources ignoring max temp
	nearbyWarmMod = 0  -- Heat sources respecting max temp
	nearbyCoolMod = 0  -- Cooling sources respecting min temp
	nearbyColdMod = 0  -- Cooling sources ignoring min temp
	
	-- Get racial heat source multipliers
	local intensityMult, radiusMult = getRacialHeatSourceMultipliers()
	
	-- Get heat sources from G_cellInfo (populated by sd_g.getCellInfo)
	-- Heat sources are pre-scanned when entering a cell and stored in saveData.G_cellInfo.fires
	if not G_cellInfo or not G_cellInfo.fires then
		return heatBonus, nearestSource
	end
	
	local function processHeatSource(sourceObject, sourceTable, isStaticFire)
		if not (sourceObject:isValid() and sourceObject.position) then
			return
		end
		
		local distance = (self.position - sourceObject.position):length()
		if distance >= sourceMaxDistance then
			return
		end
		
		-- Find matching source data
		local matchingDistance = isStaticFire and 400 or 0
		local matchingHeat = isStaticFire and 8 or 0
		local recordId = sourceObject.recordId
		local ignoreTemperatureLimit
		
		if dbStatics[recordId] and dbStatics[recordId].heatsource ~= nil then
			if dbStatics[recordId].heatsource == false then
				return
			end
			matchingDistance = dbStatics[recordId].heatsource.radius or matchingDistance
			matchingHeat = dbStatics[recordId].heatsource.temperatureMod or matchingHeat
			if dbStatics[recordId].heatsource.comfort and distance < matchingDistance/2 then
				hearthfireMagnitude = math.max(hearthfireMagnitude, dbStatics[recordId].heatsource.comfort)
			end
			ignoreTemperatureLimit = dbStatics[recordId].heatsource.ignoresMaxTemp
		else
			for _, sourceData in pairs(sourceTable) do
				if recordId:find(sourceData[1]) then
					matchingDistance = sourceData[2]
					matchingHeat = sourceData[3]
					if sourceData[4] and distance < matchingDistance/2 then
						hearthfireMagnitude = math.max(hearthfireMagnitude, sourceData[4])
					end
					ignoreTemperatureLimit = sourceData[5]
					break
				end
			end
		end
		if matchingDistance == 0 then
			return
		end
		
		-- Apply racial multipliers
		matchingDistance = matchingDistance * radiusMult
		matchingHeat = matchingHeat * intensityMult
		
		if distance < matchingDistance then
			-- Companions never ignore temperature limits
			if not isStaticFire and saveData.companions[sourceObject.id] then
				ignoreTemperatureLimit = false
			end
			
			-- Track for legacy variables
			ignoreMaxTemperature = ignoreMaxTemperature or ignoreTemperatureLimit
			if isStaticFire then
				nearbyLava = nearbyLava or ignoreTemperatureLimit
			end
			
			if distance < nearestDistance then
				nearestDistance = distance
				nearestSource = recordId or "unknown source"
			end
			
			-- Calculate temperature effect
			distance = math.max(0, distance - matchingDistance * 0.1)
			local distanceMod = math.max(0, 1 - (distance / matchingDistance))^1.9
			local tempEffect = distanceMod * matchingHeat
			-- Categorize and accumulate
			if matchingHeat > 0 then
				if ignoreTemperatureLimit then
					nearbyHotMod = math.max(nearbyHotMod, tempEffect)
					tempDbg.p(15, "  - "..recordId.." = "..formatTemperatureModifier((math.floor(tempEffect*100)/100)).." (Hot)")
				else
					nearbyWarmMod = math.max(nearbyWarmMod, tempEffect)
					tempDbg.p(15, "  - "..recordId.." = "..formatTemperatureModifier((math.floor(tempEffect*100)/100)).." (Warm)")
				end
				-- Legacy heatBonus variable - only for heating sources
				heatBonus = math.max(heatBonus, tempEffect)
			elseif matchingHeat < 0 then
				if ignoreTemperatureLimit then
					nearbyColdMod = math.max(nearbyColdMod, -tempEffect)
					tempDbg.p(15, "  - "..recordId.." = "..formatTemperatureModifier((math.floor(tempEffect*100)/100)).." (Cold)")
				else
					nearbyCoolMod = math.max(nearbyCoolMod, -tempEffect)
					tempDbg.p(15, "  - "..recordId.." = "..formatTemperatureModifier((math.floor(tempEffect*100)/100)).." (Cool)")
				end
			end
		end
	end
	
	-- Process static fires
	for _, sourceObject in ipairs(G_cellInfo.fires) do
		processHeatSource(sourceObject, fireTags, true)
	end
	
	-- Process actor-based sources
	for _, sourceObject in ipairs(nearby.actors) do
		if types.Creature.objectIsInstance(sourceObject) or dbStatics[sourceObject.recordId] and dbStatics[sourceObject.recordId].heatsource then
			processHeatSource(sourceObject, actorTags, false)
		end
	end
	
	--if nearestSource then
	--	tempDbg.p(13, string.format("Nearest: '%s' at %.0f units: +%s warmth"..(nearbyLava and " LAVA!" or ""),
	--		nearestSource, nearestDistance, formatTemperatureModifier(heatBonus)))
	--	
	--end
	
	return nearestSource
end

-- Calculate temperature bonus from heat sources (campfires, torches)
local function getHeatSourceModifier(currentTemp)
	-- Check for nearby campfires
	foundCampfire = getNearbyHeatSources()
	-- Apply temperature sources in order: extreme then comfortable
	local effectiveTemp = currentTemp
	
	-- Apply extreme heat sources (ignore max temperature)
	if nearbyHotMod > 0 then
		effectiveTemp = effectiveTemp + nearbyHotMod
		tempDbg.p(12, string.format("Hot sources: %s", formatTemperatureModifier(nearbyHotMod)))
	end
	
	-- Apply extreme cold sources (ignore min temperature)
	if nearbyColdMod > 0 then
		effectiveTemp = effectiveTemp - nearbyColdMod
		tempDbg.p(12, string.format("Cold sources: %s", formatTemperatureModifier(-nearbyColdMod)))
	end
	
	-- Apply comfortable warm sources (only toward ideal, not past it)
	local warmExcess = nearbyWarmMod - nearbyHotMod
	if warmExcess > 0 and effectiveTemp < G_idealTemperature then
		local wouldBeTemp = effectiveTemp + warmExcess
		local overflow = wouldBeTemp - G_idealTemperature
		if overflow > 0 then
			-- Cap at ideal temp
			local toIdeal = warmExcess - overflow
			effectiveTemp = effectiveTemp + toIdeal
			-- Accelerate heating based on overflow
			local rateMult = (overflow / 10)
			G_heatRate = G_heatRate + rateMult
			tempDbg.p(12, string.format("Warm sources: %s, rate +%.1f", formatTemperatureModifier(toIdeal), rateMult))
		else
			effectiveTemp = effectiveTemp + warmExcess
			tempDbg.p(12, string.format("Warm sources: %s", formatTemperatureModifier(warmExcess)))
		end
	elseif warmExcess > 0 and tempData.currentTemp < G_idealTemperature then
		-- Player is cold but effectiveTemp already at ideal - boost heating rate with excess
		local rateMult = (warmExcess / 10)
		G_heatRate = G_heatRate + rateMult
		tempDbg.p(14, string.format("Warm sources at ideal temp, rate +%.1f", rateMult))
	elseif nearbyWarmMod > 0 then
		tempDbg.p(14, "Warm sources but you're already at ideal temperature")
	end
	
	-- Apply comfortable cool sources (only toward ideal, not past it)
	local coolExcess = nearbyCoolMod - nearbyColdMod
	if coolExcess > 0 and effectiveTemp > G_idealTemperature then
		local wouldBeTemp = effectiveTemp - coolExcess
		local overflow = G_idealTemperature - wouldBeTemp
		if overflow > 0 then
			-- Cap at ideal temp
			local toIdeal = coolExcess - overflow
			effectiveTemp = effectiveTemp - toIdeal
			-- Accelerate cooling based on overflow
			local rateMult = (overflow / 10)
			G_coolRate = G_coolRate + rateMult
			tempDbg.p(12, string.format("Cool sources: %s, rate +%.1f", formatTemperatureModifier(-toIdeal), rateMult))
		else
			effectiveTemp = effectiveTemp - coolExcess
			tempDbg.p(12, string.format("Cool sources: %s", formatTemperatureModifier(-coolExcess)))
		end
	elseif coolExcess > 0 and tempData.currentTemp > G_idealTemperature then
		-- Player is hot but effectiveTemp already at ideal - boost cooling rate with excess
		local rateMult = (coolExcess / 10)
		G_coolRate = G_coolRate + rateMult
		tempDbg.p(14, string.format("Cool sources at ideal temp, rate +%.1f", rateMult))
	elseif nearbyCoolMod > 0 then
		tempDbg.p(14, "Cool sources but you're already at ideal temperature")
	end
	
	-- Check for equipped torch
	--local torch = hasEquippedTorch()
	if equipmentData.hasTorch then
		-- Torch provides warmth
		local torchWarmth = equipmentData.hasTorch
		effectiveTemp = effectiveTemp + torchWarmth
			tempDbg.p(12, string.format("Torch equipped: %s", formatTemperatureModifier(torchWarmth)))
	end
	return effectiveTemp - currentTemp
end 

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Detect Magic Resistances								              │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getMagicResistances()
	-- Initialize accumulator variables
	local fireRes = 0	  -- Total fire resistance
	local frostRes = 0	 -- Total frost resistance
	local fireWeak = 0	 -- Total fire weakness
	local frostWeak = 0	-- Total frost weakness
	
	-- Scan ALL active spells on the player
	for _, activeSpell in pairs(types.Actor.activeSpells(self)) do
		
		-- Check each effect in this spell
		for _, effect in pairs(activeSpell.effects) do
			
			-- Get magnitude safely (might be nil)
		   -- local magnitude = effect.magnitudeThisFrame or effect.minMagnitude or 0
			local magnitude = effect.magnitudeThisFrame or 0
			
			-- Check effect type and accumulate
			-- Note: effect IDs are LOWERCASE strings
			
			if effect.id == "resistfire" then
				-- Fire resistance reduces heat gain
				fireRes = fireRes + magnitude
				
			elseif effect.id == "weaknesstofire" then
				-- Fire weakness increases heat gain
				fireWeak = fireWeak + magnitude
				
			elseif effect.id == "resistfrost" then
				-- Frost resistance helps retain warmth
				frostRes = frostRes + magnitude
				
			elseif effect.id == "weaknesstofrost" then
				-- Frost weakness increases cold loss
				frostWeak = frostWeak + magnitude
			end
		end
	end
	
	-- Add temporary debug code at the end of your getMagicResistances():
	-- local fireRes, frostRes, fireWeak, frostWeak = getMagicResistances()
	tempDbg.p(15, string.format("  Fire: %d resist, %d weakness | Frost: %d resist, %d weakness", 
		fireRes, fireWeak, frostRes, frostWeak))
		
	-- Return all four values
	return fireRes, frostRes, fireWeak, frostWeak

end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Detect Shield and Damage Effects						              │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getActiveShieldsAndDamage()
	-- Initialize flags and accumulators
	local fireShield = 0	 -- do we have fire shield?
	local frostShield = 0	-- do we have frost shield?
	--local lightningShield = 0	-- do we have frost shield?
	local fireDamage = 0			-- Total fire damage being taken
	local frostDamage = 0		   -- Total frost damage being taken
	
	-- Scan all active spells
	for _, activeSpell in pairs(types.Actor.activeSpells(self)) do
		for _, effect in pairs(activeSpell.effects) do
		--	if ActiveSpell.fromEquipment or hasduration....
			local magnitude = effect.magnitudeThisFrame or effect.minMagnitude or 0
			local avgMagnitude = ((effect.minMagnitude or 0) + (effect.maxMagnitude or 0)) / 2
			--print(effect.id,effect.minMagnitude or 0, effect.maxMagnitude or 0)
			-- Check for shield effects
			if not effect.durationLeft or effect.durationLeft > 0 then
				if effect.id == "fireshield" then
					fireShield = fireShield + magnitude
				elseif effect.id == "frostshield" then
					frostShield = frostShield + magnitude
					
				--elseif effect.id == "lightningshield" then
				--	-- Lightning shield also counts as cold protection
				--	lightningShield = magnitude
				
				-- Check for damage effects
				elseif effect.id == "firedamage" then
					-- Taking fire damage makes you hot
					fireDamage = fireDamage + avgMagnitude
					
				elseif effect.id == "frostdamage" then
					-- Taking frost damage makes you cold
					frostDamage = frostDamage + avgMagnitude
				end
			end
		end
	end
	
	return fireShield, frostShield, fireDamage, frostDamage
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Calculate Magic Temperature Modifier						          │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getMagicTemperatureModifier(currentTemp, targetTemp)
	local modifier = 0
	local heatingMod = 1
	local coolingMod = 1
	
	local tempFireRes, tempFrostRes = fireRes, frostRes
	
	local comfortDrift = 0
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Dark Elf: Twilight comfort drift (5-6am, 6-7pm)
	-- ═══════════════════════════════════════════════════════════════════
	if racialData.twilightComfortDrift then
		local hour = clockHour
		local isTwilight = ((hour >= 5 and hour < 6) or (hour >= 18 and hour < 19))
		
		if isTwilight then
			comfortDrift = comfortDrift + racialData.twilightComfortDrift
			tempDbg.p(13, string.format("  %s: Twilight comfort drift: +%i resistances and +-%s", 
				race, racialData.twilightComfortDrift, formatTemperatureModifier(racialData.twilightComfortDrift/10)))
			
			tempFrostRes = tempFrostRes + racialData.twilightComfortDrift
			tempFireRes = tempFireRes + racialData.twilightComfortDrift
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Argonian: Wetness/Swimming Comfort Drift (Non-Arctic/Cold)
	-- ═══════════════════════════════════════════════════════════════════
	if racialData.wetComfortDrift then
		local isWetOrSwimming = (tempData.water and tempData.water.wetness > 0.1) or (G_isInWater > 0.5)
		
		if isWetOrSwimming then
			-- Check if NOT in arctic or cold climate
			local inColdClimate = climateType == "arctic" or climateType == "cold"
			
			-- Only drift toward comfort if NOT in cold/arctic and water isn't freezing
			if not inColdClimate and waterTemp > 5 then
				comfortDrift = comfortDrift + racialData.wetComfortDrift
				tempDbg.p(13, string.format("  %s: wet comfort drift: +%i resistances and %s drift to comfortable", 
					race, racialData.wetComfortDrift,formatTemperatureModifier(racialData.wetComfortDrift/10)))
				tempFrostRes = tempFrostRes + racialData.wetComfortDrift
				tempFireRes = tempFireRes + racialData.wetComfortDrift
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Bed comfort drift
	-- ═══════════════════════════════════════════════════════════════════
	if G_currentBed then
		local bedComfortDrift = 30
		if G_currentBed.recordId == "sd_campingobject_bedrolltent" or G_currentBed.recordId == "campingGear_bedroll" then
			bedComfortDrift = 50
		--elseif G_currentBed.recordId == "sd_campingobject_bedroll" then
		--	bedComfortDrift = 30
		end
		comfortDrift = comfortDrift + bedComfortDrift
		tempDbg.p(13, string.format("  %s: bed comfort drift: +%i resistances and %s drift to comfortable", 
			G_currentBed.recordId , bedComfortDrift,formatTemperatureModifier(bedComfortDrift/10)))
		tempFrostRes = tempFrostRes + bedComfortDrift
		tempFireRes = tempFireRes + bedComfortDrift
	end
	
	-- ═══════════════════════════════════════════════════════════════
	-- Vampire/Werewolf Resistance Modifiers
	-- ═══════════════════════════════════════════════════════════════
	if NEEDS_TEMP_VW ~= "Disable" then
		-- Vampires: Extremely resistant to cold (both modes)
		if saveData.playerInfo.isVampire > 0 then
			tempFrostRes = tempFrostRes + 75
			tempDbg.p(13, "  Vampire: +75 frost resistance")
			if G_cellInfo.isDwemer then
				comfortDrift = comfortDrift + 10
			end
		end
		
		-- Werewolves: Good cold resistance
		if saveData.playerInfo.isWerewolf > 0 then
			if saveData.playerInfo.isInWerewolfForm then
				tempFrostRes = tempFrostRes + 50
				tempDbg.p(13, "  Werewolf (Beast Form): +50 frost resistance")
			else
				tempFrostRes = tempFrostRes + 25
				tempDbg.p(13, "  Werewolf (Human Form): +25 frost resistance")
			end
		end
	end

	-- ═══════════════════════════════════════════════════════════════════
	-- Breton Magic Resistance Bonuses
	-- ═══════════════════════════════════════════════════════════════════
	-- Resistances are 25% more effective
	if racialData.resistEffectivenessMultiplier then
		local oldFireRes = tempFireRes
		local oldFrostRes = tempFrostRes
		tempFireRes = tempFireRes * racialData.resistEffectivenessMultiplier
		tempFrostRes = tempFrostRes * racialData.resistEffectivenessMultiplier
		
		if oldFireRes > 0 or oldFrostRes > 0 then
			tempDbg.p(13, string.format("  %s: Magic resist %.0fx effective", race, racialData.resistEffectivenessMultiplier))
		end
	end
	
	-- Weaknesses are 25% less effective
	if racialData.weaknessReduction then
		local oldFireWeak = fireWeak
		local oldFrostWeak = frostWeak
		fireWeak = fireWeak * racialData.weaknessReduction
		frostWeak = frostWeak * racialData.weaknessReduction
		
		if oldFireWeak > 0 or oldFrostWeak > 0 then
			tempDbg.p(13, string.format("  %s: Magic weakness %.0fx reduced", race, racialData.weaknessReduction))
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- SHIELD EFFECTS (Complete protection)
	-- ═══════════════════════════════════════════════════════════════════
	-- Frost Shield negates heat above 25°C
	-- Note: This is a backup mechanism. Primary protection is in module_temp_minute
	-- which prevents targetTemp from rising above 25°C
	if frostShield > 0 and targetTemp > 20 then
		-- If somehow the player is above 25°C with frost shield active,
		-- actively cool them down
		local heatReduction = math.min(frostShield*3, math.max(0, targetTemp - 20))
		modifier = modifier - heatReduction
		
			tempDbg.p(13, string.format("  Frost Shield: %s", formatTemperatureModifier(-heatReduction)))
	end
	
	-- Fire Shield negates cold below 15°C
	-- Note: This is a backup mechanism. Primary protection is in module_temp_minute
	-- which prevents targetTemp from dropping below 15°C
	if fireShield > 0 and targetTemp < 20 then
		-- If somehow the player is below 15°C with fire shield active,
		-- actively warm them up
		local coldReduction = math.min(fireShield*3, math.max(0, 20 - targetTemp))
		modifier = modifier + coldReduction
		
			tempDbg.p(13, string.format("  Fire Shield: %s", formatTemperatureModifier(coldReduction)))
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- RESISTANCE EFFECTS (Gradual protection)
	-- ═══════════════════════════════════════════════════════════════════
	-- Fire Resistance: Only works when HEATING UP in hot areas
	if targetTemp > 25 then
		local netFireRes =tempFireRes - math.min(50, fireWeak)
		
		if netFireRes > 0 then
			-- 75° would be a delta of 50° above 25. so at 100% fire Res we reduce temperature by 20% of that = 10°
			local idealTemperatureDelta = targetTemp - 25
			local modmod = -netFireRes / 500 * idealTemperatureDelta
			modifier = modifier + modmod
			
			local rateMult = 0.5^(netFireRes / 40)
			heatingMod = heatingMod * rateMult
			
			tempDbg.p(14, string.format("  Fire Resist %d%%: x%.1f heat rate and %s", 
				netFireRes, rateMult, formatTemperatureModifier(modmod)))
		end
	end
	
	-- Fire Weakness: Only matters when HEATING UP in hot areas
	if targetTemp > 25 then
		local netFireWeak = math.min(50, fireWeak) - tempFireRes
		
		if netFireWeak > 0 then
			-- 75° would be a delta of 50° above 25. so at 100% fire Weak we increase temperature by 20% of that = 10°
			local idealTemperatureDelta = targetTemp - 25
			local modmod = netFireWeak / 500 * idealTemperatureDelta
			modifier = modifier + modmod
			
			local rateMult = 0.5^(netFireWeak / 40)
			heatingMod = heatingMod / rateMult
			
			tempDbg.p(14, string.format("  Fire Weakness %d%%: x%.1f heat rate and -+%s", 
				netFireWeak, 1/rateMult, formatTemperatureModifier(modmod)))
		end
	end
	
	-- Frost Resistance: Only works when COOLING DOWN in cold areas
	if targetTemp < 15 then
		local netFrostRes = tempFrostRes - math.min(50, frostWeak)
		
		if netFrostRes > 0 then
			-- -35° would be a delta of 50° below 15. so at 100% frost Res we increase temperature by 20% of that = 10°
			local idealTemperatureDelta = 15 - targetTemp
			local modmod = netFrostRes / 500 * idealTemperatureDelta
			modifier = modifier + modmod
			
			local rateMult = 0.5^(netFrostRes / 40)
			coolingMod = coolingMod * rateMult
			
			tempDbg.p(14, string.format("  Frost Resist %d%%: x%.1f cool rate and -+%s", 
				netFrostRes, rateMult, formatTemperatureModifier(modmod)))
		end
	end
	
	-- Frost Weakness: Only matters when COOLING DOWN in cold areas
	if  targetTemp < 15 then
		local netFrostWeak = math.min(50, frostWeak) - tempFrostRes
		
		if netFrostWeak > 0 then
			-- -35° would be a delta of 50° below 15. so at 100% frost Weak we decrease temperature by 20% of that = 10°
			local idealTemperatureDelta = 15 - targetTemp
			local modmod = -netFrostWeak / 500 * idealTemperatureDelta
			modifier = modifier + modmod
			
			local rateMult = 0.5^(netFrostWeak / 40)
			coolingMod = coolingMod / rateMult
			
			tempDbg.p(14, string.format("  Frost Weakness %d%%: x%.1f cool rate and %s", 
				netFrostWeak, 1/rateMult, formatTemperatureModifier(modmod)))
		end
	end

	-- ═══════════════════════════════════════════════════════════════════
	-- DAMAGE EFFECTS (Temporary extreme temperature)
	-- ═══════════════════════════════════════════════════════════════════
	-- Fire Damage: Makes you HOT regardless of environment
	if fireDamage > 0 then
		fireDamage = fireDamage / math.max(0.01, 1-types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.ResistFire).magnitude/100)
		local tempIncrease = math.min(15, fireDamage * 0.5)
		modifier = modifier + tempIncrease
		
		tempDbg.p(12, string.format("  Fire Damage (%.0f): %s (burning!)", 
			fireDamage, formatTemperatureModifier(tempIncrease)))
	end
	
	-- Frost Damage: Makes you COLD regardless of environment
	if frostDamage > 0 then
		frostDamage = frostDamage / math.max(0.01, 1-types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.ResistFrost).magnitude/100)
		local tempDecrease = math.min(15, frostDamage * 0.5)
		modifier = modifier - tempDecrease
		
		tempDbg.p(12, string.format("  Frost Damage (%.0f): %s (frozen!)", 
			frostDamage, formatTemperatureModifier(-tempDecrease)))
	end
	
	
	if comfortDrift > 0 then
		maxMod = comfortDrift/10
		local tempGap = G_idealTemperature - targetTemp
		modifier = math.max(-maxMod, math.min(modifier + tempGap, maxMod))
	end
	
	return modifier, coolingMod, heatingMod
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Water & Swimming Temperature Modifier					              │
-- ╰──────────────────────────────────────────────────────────────────────╯
local function getWaterTemperatureModifier(currentPlayerTemp, currentEnvironmentTemp, fireShieldProtection)
	local modifier = 0
	local exposedFraction = 1 - G_isInWater  -- 1 = fully exposed to air, 0 = fully submerged
	fireShieldProtection = fireShieldProtection or 0  -- 0 = no protection, 1 = full protection
	local fireShieldExposure = 1 - fireShieldProtection  -- multiplier for water/weather effects
	
	-- ═══════════════════════════════════════════════════════════════════
	-- ATMOSPHERIC EFFECTS - Wetness, Wind Chill, Rain (scaled by exposure)
	-- ═══════════════════════════════════════════════════════════════════
	
	-- Constants
	local REGION_HUMIDITY = 0.5
	if G_cellInfo.isExterior then
		if climateType == "volcanic" then
			REGION_HUMIDITY = 0.3
		elseif climateType == "coastal" then
			REGION_HUMIDITY = 0.4
		elseif climateType == "ashland" then
			REGION_HUMIDITY = 0.1
		elseif climateType == "cold" then
			REGION_HUMIDITY = 0.30
		elseif climateType == "arctic" then
			REGION_HUMIDITY = 0.2
		elseif climateType == "tropical" then
			REGION_HUMIDITY = 0.7
		elseif climateType == "temperate" then
			REGION_HUMIDITY = 0.5
		end
		local hour = (core.getGameTime() / 3600) % 24 
		local relativeHour = math.abs((hour + 6) % 24 - 6)
		if relativeHour <= 6 then
			REGION_HUMIDITY = REGION_HUMIDITY * (1.5-relativeHour/12) -- high humidity at midnight, lower at dawn+dusk
		end
		REGION_HUMIDITY = math.min(0.99, REGION_HUMIDITY)
	else
		if G_cellInfo.isDwemer then
			REGION_HUMIDITY = 0.4
		elseif G_cellInfo.isCave and not G_cellInfo.isIceCave and not G_cellInfo.isMine then
			REGION_HUMIDITY = 0.6
		end
	end
	local MOVEMENT_DISTANCE = 0
	local wetness = tempData.water.wetness
	local rainIntensity = saveData.weatherInfo.rainIntensity or 0
	local isInRain = saveData.weatherInfo.isInRain
	if G_currentBed and (G_currentBed.recordId == "sd_campingobject_bedrolltent" or G_currentBed.recordId == "campingGear_bedroll") then
		isInRain = false
	end
	local isInShadow = saveData.weatherInfo.isInShadow
	local sunStrength = saveData.weatherInfo.sunStrength
	local sunVisibility = saveData.weatherInfo.sunVisibility
	local windSpeed = saveData.weatherInfo.windSpeed or 0
	local effectiveWindSpeed = windSpeed
	if secondsPassed > 0 and MOVEMENT_DISTANCE > 0 then
		local movementSpeed = MOVEMENT_DISTANCE / secondsPassed
		effectiveWindSpeed = windSpeed + (movementSpeed * 0.3)
	end
	
	-- Calculate armor coverage
	local armorCoverage = math.min(equipmentData.armorPieces / 8.0, 1.0)
	local baseInsulation = armorCoverage * 0.4
	if equipmentData.hasShirt then baseInsulation = baseInsulation + 0.15 end
	if equipmentData.hasPants then baseInsulation = baseInsulation + 0.15 end
	if equipmentData.hasSkirt then baseInsulation = baseInsulation + 0.1 end
	if equipmentData.hasRobe then baseInsulation = baseInsulation + 0.25 end
	
	-- Convert equipment water resistance (2-5 per piece) to 0-1 scale (max ~40)
	local waterResistance = math.min(1, equipmentData.waterResistance / 45.0)
	
	-- Calculate effective humidity (rain increases it even under shelter)
	local effectiveHumidity = REGION_HUMIDITY
	if rainIntensity > 0 then
		effectiveHumidity = math.min(1.0, effectiveHumidity + rainIntensity * 0.3)
	end
	effectiveHumidity = math.min(0.9, effectiveHumidity)
	tempDbg.p(15, string.format("  Armor Insulation: %.2f | Water resist: %.2f | Wetness: %.2f | Humidity: %.0f%% | Exposed: %.0f%%",
		baseInsulation, waterResistance, wetness, effectiveHumidity * 100, exposedFraction * 100))
	
	-- ═══════════════════════════════════════════════════════════════════
	-- GETTING WET from rain (scaled by exposed fraction)
	-- ═══════════════════════════════════════════════════════════════════
	if isInRain and rainIntensity > 0 and exposedFraction > 0 then
		local robeProtection = equipmentData.hasRobe and 0.3 or 0
		local helmetProtection = equipmentData.hasHelmet and 0.15 or 0
		local skirtProtection = equipmentData.hasSkirt and 0.07 or 0
		local totalWaterProtection = waterResistance + robeProtection + helmetProtection + skirtProtection
		local totalWaterExposure = 1.0 - math.min(0.93, totalWaterProtection)
		totalWaterExposure = totalWaterExposure * (1-equipmentData.hasUmbrella) * fireShieldExposure
		
		local wetnessIncrease = rainIntensity/1000 * totalWaterExposure * secondsPassed * 0.01
		wetnessIncrease = wetnessIncrease * exposedFraction
		wetness = math.min(1.0, wetness + wetnessIncrease)
		
		if wetnessIncrease > 0 then
			tempDbg.p(13, string.format("  Getting wet: +%.4f (protection: %.0f%%)",
				wetnessIncrease/secondsPassed,
				(1 - totalWaterExposure) * 100))
		end
	end
	local dryingRate = 0
	-- ═══════════════════════════════════════════════════════════════════
	-- DRYING when not in rain (scaled by exposed fraction)
	-- ═══════════════════════════════════════════════════════════════════
	if not isInRain and wetness > 0 and exposedFraction > 0 then
		local humidityPenalty = 1- (effectiveHumidity * 0.5)
		tempDbg.p(15, string.format("  %.4f base drying rate", 
					0.001 * humidityPenalty))
		
		dryingRate = dryingRate + 0.001 * humidityPenalty
					
		if windSpeed > 0 then
			tempDbg.p(15, string.format("  %.2f windSpeed: + %.4f drying rate", 
						windSpeed, (windSpeed * 0.0001) * humidityPenalty))
			dryingRate = dryingRate + (windSpeed * 0.0001) * humidityPenalty
		end
		
		if currentEnvironmentTemp > 15 then
			local dryingRateIncrease = (currentEnvironmentTemp - 15) * 0.00005 * humidityPenalty
			tempDbg.p(15, string.format("  %s: + %.4f drying rate", formatTemperature(currentEnvironmentTemp), dryingRateIncrease))
			dryingRate = dryingRate + dryingRateIncrease
		end
		
		
		if sunStrength > 0 and not isInShadow then
			tempDbg.p(15, string.format("  %.2f Sun Strength: + %.4f drying rate", 
					sunStrength, sunStrength * 0.002))
			dryingRate = dryingRate + sunStrength * 0.002
		end
		
		-- Campfire bonus
		local campfireBonus = nearbyHotMod - nearbyColdMod + nearbyWarmMod - nearbyCoolMod
		if campfireBonus > 2 then
			tempDbg.p(15, string.format("  %.2f campfireBonus: + %.4f drying rate", 
					campfireBonus, campfireBonus * 0.0005))
			dryingRate = dryingRate + campfireBonus * 0.0005
		end
		
		-- Torch bonus
		if equipmentData.hasTorch then
			tempDbg.p(15, string.format("  %s Torch: + %.4f drying rate", 
					formatTemperatureModifier(equipmentData.hasTorch), equipmentData.hasTorch * 0.00035))
			dryingRate = dryingRate + equipmentData.hasTorch * 0.00035
		end
		
		if equipmentData.hasRobe then
			dryingRate = dryingRate * 0.9
		end
		
		-- Racial wetness decay modifier
		if racialData and racialData.wetnessTemperatureRate then
			local oldDryRate = dryingRate
			dryingRate = dryingRate * racialData.wetnessTemperatureRate
			
			if racialData.wetnessTemperatureRate ~= 1.0 then
				tempDbg.p(13, string.format("  %s wetness decay: %.2fx (%.4f -> %.4f)", 
					race, racialData.wetnessTemperatureRate, oldDryRate, dryingRate))
			end
		end
		
		-- Scale drying by exposed fraction (submerged parts can't dry)
		dryingRate = dryingRate * exposedFraction
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- EVAPORATIVE COOLING (scaled by exposed fraction)
	-- ═══════════════════════════════════════════════════════════════════
	if wetness > 0.05 and exposedFraction > 0 then
		local humidityFactor = 1.0 - effectiveHumidity
		local windFactor = 1.0 + (effectiveWindSpeed / 10.0)
		
		local temperatureEvapFactor = 1.0
		if currentEnvironmentTemp > 20 then
			temperatureEvapFactor = 1.3
		elseif currentEnvironmentTemp < 5 then
			temperatureEvapFactor = 0.4
		end
		
		local evaporativeCooling = wetness * humidityFactor * windFactor * temperatureEvapFactor * 4.0 + wetness * 2.5
		evaporativeCooling = math.min(evaporativeCooling, 5.5)
		
		-- Scale by exposed fraction (submerged parts don't evaporate to air)
		evaporativeCooling = evaporativeCooling * exposedFraction * fireShieldExposure
		
		if evaporativeCooling > 0.1 then
			tempDbg.p(13, string.format("  Wet clothing: %s (humidity: %.0f%%, wind factor: %.1fx)", 
				formatTemperatureModifier(-evaporativeCooling), effectiveHumidity * 100, windFactor))
		end
		
		modifier = modifier - evaporativeCooling
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- DIRECT RAIN IMPACT (scaled by exposed fraction)
	-- ═══════════════════════════════════════════════════════════════════
	if isInRain and rainIntensity > 0 and exposedFraction > 0 then
		
		-- BODY EXPOSURE (inverse of clothing protection)
		local robeProtection = equipmentData.hasRobe and 0.3 or 0
		local skirtProtection = equipmentData.hasSkirt and 0.07 or 0
		local bodyExposure = 1.0 - math.min(0.9, waterResistance + robeProtection + skirtProtection)
		
		-- HEAD EXPOSURE (inverse of helmet/umbrella protection)
		local headExposure = 1.0
		if equipmentData.hasHelmet then
			headExposure = 0.33  -- 40% protection
		end
		headExposure = headExposure * (1-equipmentData.hasUmbrella)  -- 67% protection
		bodyExposure = bodyExposure * (1-equipmentData.hasUmbrella*0.6)  -- umbrella blocks 60% of body rain too
		
		-- HEAD: Direct exposure, always cools (skin contact)
		-- BODY: Needs wetness to conduct cold through clothes
		local headCooling = headExposure * 0.35
		local bodyCooling = bodyExposure * (0.2 + wetness * 0.8) * 0.65
		
		-- Calculate total rain cooling
		local rainCooling = (rainIntensity / 800) * (headCooling + bodyCooling) * 5.5
		rainCooling = math.min(rainCooling, 6.0)
		
		-- Scale by exposed fraction (only exposed parts get rained on)
		rainCooling = rainCooling * exposedFraction * fireShieldExposure
		
		if rainCooling > 0.1 then
			tempDbg.p(12, string.format("  Rain impact: %s (intensity: %.0f%%, head: %.0f%%, body: %.0f%%)",
				formatTemperatureModifier(-rainCooling), rainIntensity/800 * 100, headExposure * 100, bodyExposure * 100))
		end
		
		modifier = modifier - rainCooling
	end
	
	-- Update wetness
	
	if modifier < 0 then
		tempDbg.p(11, string.format("Wet: %s", 
				formatTemperatureModifier(modifier)))
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- WIND CHILL EFFECT (scaled by exposed fraction)
	-- ═══════════════════════════════════════════════════════════════════
	if saveData.weatherInfo.hasWindCover ~= true and exposedFraction > 0 then
		local windProtection = armorCoverage * 0.4
		if equipmentData.hasRobe then windProtection = windProtection + 0.2 end
		if equipmentData.hasSkirt then windProtection = windProtection + 0.07 end
		if equipmentData.hasHelmet then windProtection = windProtection + 0.15 end
		windProtection = math.min(windProtection, 0.8)
		if currentEnvironmentTemp <= 10 and effectiveWindSpeed > 1.0 then
			-- fire shield (fireShieldExposure) 50% effective
			local effectiveWindExposure = (1-windProtection) * (1+fireShieldExposure)/2
			-- Wind chill for cold conditions
			local windChillTemp = 13.12 + 0.6215 * currentEnvironmentTemp 
							- 11.37 * math.pow(effectiveWindSpeed, 0.16) 
							+ 0.3965 * currentEnvironmentTemp * math.pow(effectiveWindSpeed, 0.16)
			local windChillEffect = currentEnvironmentTemp - windChillTemp
				
			windChillEffect = windChillEffect * effectiveWindExposure
			
			-- Scale by exposed fraction (submerged parts shielded from wind)
			windChillEffect = windChillEffect * exposedFraction
			
			tempDbg.p(12, string.format("Wind chill: %s (wind: %.1f m/s, protection: %.0f%%)", 
				formatTemperatureModifier(windChillEffect), effectiveWindSpeed, (1-effectiveWindExposure) * 100))
			modifier = modifier - windChillEffect
		elseif currentEnvironmentTemp > 10 and currentEnvironmentTemp < 37 and effectiveWindSpeed > 1.0 then
			-- fire shield (fireShieldExposure) 50% effective
			local effectiveWindExposure = (1-windProtection) * (1+fireShieldExposure)/2
			-- Comfortable range: wind provides cooling relief
			local coolingEffect = (37 - currentEnvironmentTemp) * effectiveWindSpeed * 0.02 * effectiveWindExposure
			
			-- Scale by exposed fraction,
			coolingEffect = coolingEffect * exposedFraction
			
			modifier = modifier + coolingEffect
			
			tempDbg.p(12, string.format("Wind cooling: %s (wind: %.1f m/s, protection: %.0f%%)", 
				formatTemperatureModifier(coolingEffect), effectiveWindSpeed, (1-effectiveWindExposure) * 100))
		elseif currentEnvironmentTemp > 37 and effectiveWindSpeed > 1.0 then
			-- High temp wind effects
			local frostShieldExposure = 1
			if frostShield > 0 then
				frostShieldExposure = 1-math.min(1, (1+frostShield)/11)
			end
			local effectiveWindExposure = (1-windProtection) * (1+frostShieldExposure)/2
			local heatEffect = (currentEnvironmentTemp - 37) * effectiveWindSpeed * 0.05 * effectiveWindExposure
			
			-- Scale by exposed fraction
			heatEffect = heatEffect * exposedFraction
			
			modifier = modifier + heatEffect
			tempDbg.p(12, string.format("Wind heating: %s (wind: %.1f m/s, protection: %.0f%%)", 
				formatTemperatureModifier(heatEffect), effectiveWindSpeed, (1-effectiveWindExposure) * 100))
		end
	elseif saveData.weatherInfo.hasWindCover == true then
		tempDbg.p(15, "has wind cover")
	end
	
	if fireDamage > 0 then
		tempDbg.p(15, string.format("  Fire Damage: +%.4f drying rate",
				fireDamage/200))
		dryingRate = dryingRate + fireDamage/200
	end
	
	-- Fire shield drying bonus (scaled by protection)
	if fireShieldProtection > 0 then
		local fireShieldDrying = 0.01 * fireShieldProtection
		dryingRate = dryingRate + fireShieldDrying
		tempDbg.p(12, string.format("  Fire Shield: +%.4f drying rate (%.0f%% protection)",
				0.005 * fireShieldProtection, fireShieldProtection * 100))
	end
	
	local wetnessBefore = wetness
	wetness = math.max(0, wetness - dryingRate * secondsPassed)
	
	if wetnessBefore > 0.1 and wetness < wetnessBefore then
		if TEMP_WETNESS_DEBUFFS then
			dryingRateTooltip = string.format("-%.2f%%/s", dryingRate*100)
		else
			tempDbg.p(12, string.format("Drying rate: %.2f%%/s", dryingRate*100))
		end
	end
	
	if wetness == 1 then
		G_wetnessChange = 0.0001
	else
		G_wetnessChange = (wetness - tempData.water.wetness) / secondsPassed
	end
	tempData.water.wetness = wetness
	
	-- ═══════════════════════════════════════════════════════════════════
	-- IN WATER - Pull Target Toward Water Temperature
	-- ═══════════════════════════════════════════════════════════════════
	if G_isInWater > 0 then
		waterTemp = getWaterTemperature(currentEnvironmentTemp)
		local submersionLevel = math.min(1.0, G_isInWater)
		local effectiveSubmersion = submersionLevel * fireShieldExposure  -- fire shield reduces effective submersion
		
		tempData.water.wetness = math.max(tempData.water.wetness, effectiveSubmersion)
		tempData.water.lastWaterTemp = waterTemp
		tempData.water.timeInWater = tempData.water.timeInWater + secondsPassed * fireShieldExposure
		
		tempDbg.p(13, string.format("  In water: %.0f%% submerged (%.0f%% effective), water: %s, player: %s, air: %s", 
			submersionLevel*100, effectiveSubmersion*100, formatTemperature(waterTemp), formatTemperature(tempData.currentTemp), formatTemperature(currentEnvironmentTemp)))
		
		-- ═══════════════════════════════════════════════════════════════════
		-- THE CORRECTED FORMULA
		-- ═══════════════════════════════════════════════════════════════════
		
		-- Calculate difference between water temp and air temp
		local waterAirDiff = waterTemp - currentEnvironmentTemp
		
		-- Submersion determines how much target moves toward water temp
		-- 100% submerged = target becomes water temp
		-- 50% submerged = target moves halfway toward water temp
		-- 30% submerged = target moves 30% toward water temp
		
		-- Strength multiplier: How "sticky" water temperature is
		-- 1.0 = target exactly matches water at 100% submersion
		-- Higher values = pull stronger toward water (but cap it)
		local waterStrength = math.min(1.2, 0.7 + (effectiveSubmersion * 0.5))
		-- At 0% submersion: 0.7 (shouldn't happen)
		-- At 50% submersion: 0.95
		-- At 100% submersion: 1.2 (capped)
		
		local waterModifier = waterAirDiff * effectiveSubmersion * waterStrength
		local waterRateMult = 1 + effectiveSubmersion * 3
		G_temperatureRate = G_temperatureRate * waterRateMult
		
		-- ═══════════════════════════════════════════════════════════════════
		-- COLD WATER ADDITIONAL PENALTIES (Beyond water temperature)
		-- ═══════════════════════════════════════════════════════════════════
		
		--if waterTemp < 10 and effectiveSubmersion > 0.5 then
		--	-- Hypothermia effect - makes you colder than the water
		--	local hypothermiaPenalty = (10 - waterTemp) * effectiveSubmersion * 0.8
		--	waterModifier = waterModifier - hypothermiaPenalty
		--	
		--	tempDbg.p(11, string.format("  COLD WATER: -%.1f°C hypothermia", hypothermiaPenalty))
		--	
		--	if tempData.water.timeInWater > 20 then
		--		tempDbg.p(11, string.format(" HYPOTHERMIA: %.0f seconds!", 
		--			tempData.water.timeInWater))
		--	end
		--end
		--
		--if waterTemp <= 5 and effectiveSubmersion > 0.3 then
		--	-- Arctic water - extreme additional penalty
		--	local arcticPenalty = (5 - waterTemp + 2) * effectiveSubmersion * 1.2
		--	waterModifier = waterModifier - arcticPenalty
		--	
		--	tempDbg.p(11, string.format("  ARCTIC WATER: -%.1f°C (DEADLY!)", arcticPenalty))
		--	
		--	if effectiveSubmersion > 0.8 then
		--		tempDbg.p(11, "  FULLY SUBMERGED - FREEZING TO DEATH!")
		--	end
		--end
		
		if waterTemp > 22 then
			if waterTemp > 28 then
				local scaldingPenalty = (waterTemp - 28) * submersionLevel * 1.0
				waterModifier = waterModifier + scaldingPenalty
				
					tempDbg.p(13, string.format("  HOT WATER: %s", formatTemperatureModifier(scaldingPenalty)))
			else
					tempDbg.p(14, string.format("  Warm water: %s", formatTemperature(waterTemp)))
			end
		end
		if waterModifier ~= 0 then
			tempDbg.p(12, string.format("Water mod: %s, Rate: x%.2f", formatTemperatureModifier(waterModifier), waterRateMult))
		end
		
		modifier = modifier + waterModifier
	end
	
	return modifier
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Helper to Reset Water Timer										  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function resetWaterTimer()
	if G_isInWater and G_isInWater <= 0.1 then
		-- Just exited water
		if tempData.water.timeInWater > 0 then
			tempDbg.p(13, string.format("Exited water after %.0f seconds", 
				tempData.water.timeInWater))
			tempData.water.timeInWater = 0
		end
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Master Temperature Calculation										  │
-- ╰──────────────────────────────────────────────────────────────────────╯

function calculateEnvironmentTemperature()
	local pos = self.position
	local hour = (core.getGameTime() / 3600) % 24
	
	local temperature = 0
	
	tempDbg.p(02, "		============ Temperature Update ============")
	
	if G_cellInfo.isExterior then
		tempDbg.p(12, "Location: Exterior")
		
		-- 1. Base climate from world coordinates
		--temperature = getClimateTempFromPosition(pos)
		if climateTempTooltip1 ~= "" then
			tempDbg.p(15,climateTempTooltip1)
		end
		for _, out in pairs(climateTempTooltip2) do
			tempDbg.p(15,out)
		end
		--if climateTempTooltip3 ~= "" then
			tempDbg.p(13,climateTempTooltip3)
		--end
		-- 2. Solar heating
		local solarHeat = getSolarHeating(cell, hour)
		temperature = climateTemperature + solarHeat
		local shadowMod = 0
		if saveData.weatherInfo.sunStrength > 0 then
			if saveData.weatherInfo.isInShadow then
				shadowMod = 2
			elseif equipmentData.hasUmbrella > 0 then
				shadowMod = 2 * equipmentData.hasUmbrella
			end
			if shadowMod > 0 then
				local envMod = 1
				if climateType == "arctic"  then
					envMod = 0.5
				elseif climateType == "volcanic" then
					envMod = 1
				elseif climateType == "coastal" or climateType == "cold" then
					envMod = 1.25
				end
			
				shadowMod = saveData.weatherInfo.sunStrength * shadowMod * envMod
				temperature = temperature - shadowMod
				tempDbg.p(14, string.format("In the shadow: %s", formatTemperatureModifier(saveData.weatherInfo.sunStrength*2)))
			end
		end
		
		-- ═══════════════════════════════════════════════════════════════════
		-- Apply Racial Climate Modifiers
		-- ═══════════════════════════════════════════════════════════════════
		-- Use the dominant climate type that's already been calculated
		local racialClimateMod = getRacialClimateModifier( temperature)
		if racialClimateMod ~= 0 then
			temperature = temperature + racialClimateMod
		end
		local debugStr = string.format("Final exterior temp: %s", formatTemperature(temperature))
		G_trueExteriorTempString = formatTemperatureShort(temperature)
		if shadowMod ~= 0 then
			debugStr = debugStr.." (in shadow)"
		end
		tempDbg.p(12, debugStr)
	else
		climateType = "temperate"
		climateTemperature = getInteriorTemperature(cell)
		temperature = climateTemperature
	end

	-- Get current magic effects
	fireRes, frostRes, fireWeak, frostWeak = getMagicResistances()
	fireShield, frostShield, fireDamage, frostDamage = getActiveShieldsAndDamage()
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Apply water & swimming modifiers
	-- ═══════════════════════════════════════════════════════════════════
	local fireShieldProtection = 0
	if fireShield > 0 then
		if NERF_FIRE_SHIELD then
			-- Scaled protection: magnitude 10 = full protection
			fireShieldProtection = math.min(1.0, (1+fireShield) / 11)
		else
			-- Un-nerfed: full protection at any magnitude
			fireShieldProtection = 1.0
		end
	end
	
	local waterMod = getWaterTemperatureModifier(tempData.currentTemp, temperature, fireShieldProtection)
	temperature = temperature + waterMod

	-- Full fire shield protection resets water state (as if not in water)
	if fireShieldProtection >= 1.0 then
		tempData.water.lastWaterTemp = 0
		tempData.water.timeInWater = 0
	end

	-- Reset water timer if exited water
	resetWaterTimer()
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Apply magic resistance and spell effect modifiers
	-- ═══════════════════════════════════════════════════════════════════
	local magicMod, coolingMod, heatingMod = getMagicTemperatureModifier(tempData.currentTemp, temperature)
	temperature = temperature + magicMod
	G_coolRate = G_coolRate * coolingMod
	G_heatRate = G_heatRate * heatingMod
	
	if magicMod ~= 0 or coolingMod ~= 1 or heatingMod ~= 1 then
		local debugStr = "Magic:"
		if magicMod ~= 0 then
			debugStr = debugStr..string.format( " %s", formatTemperatureModifier(magicMod))
		end
		if coolingMod ~= 1 then
			debugStr = debugStr..string.format(" and x%.2f Cool Rate", coolingMod)
		end
		if heatingMod ~= 1 then
			if coolingMod ~= 1 then
				debugStr = debugStr..", "
			else
				debugStr = debugStr.." and "
			end
			debugStr = debugStr..string.format(" x%.2f Heat Rate", heatingMod)
		end
		tempDbg.p(12, debugStr)
	end
	
	-- Apply equipment modifiers
	local equipmentMod = getEquipmentTemperatureModifier(temperature)
	temperature = temperature + equipmentMod
	
	if tempData.stewBonus then
		local coldReduction = math.min(5, math.max(0, 21 - temperature))
		temperature = temperature + coldReduction
		tempData.stewBonus = tempData.stewBonus - secondsPassed
		if tempData.stewBonus <=0 then
			tempData.stewBonus = nil
		else
				tempDbg.p(11, string.format("Stew mod: %s", formatTemperatureModifier(coldReduction)))
		end
	end
	
	-- Apply heat source modifiers (campfires, torches)
	-- Needs to be calculated last because campfires only increase heat to 25
	local heatSourceMod = getHeatSourceModifier(temperature)
	temperature = temperature + heatSourceMod
	
	--if heatSourceMod > 0 then
	--	tempDbg.p(12, string.format("Heat sources: +%.1f°C", heatSourceMod))
	--end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Apply Interior Cell Type Bonuses
	-- ═══════════════════════════════════════════════════════════════════
	if not G_cellInfo.isExterior then
		local cellBonus = getRacialCellTypeBonus()
		if cellBonus ~= 0 then
			temperature = temperature + cellBonus
		end
	end
	return temperature
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Temperature State Determination									  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function getTemperatureState(temp)
	-- Get racial temperature thresholds
	local racialThresholds = getRacialTemperatureThresholds(true)	
	
	-- Create custom temperature states based on racial thresholds
	local states = {
		{ name = "Freezing",	min = -999, max = -10, spellId = "sd_temp_6" },
		{ name = "Cold",		min = -10,  max = 5,   spellId = "sd_temp_5" },
		{ name = "Chilly",		min = 5,	max = racialThresholds.comfortableMin,  spellId = "sd_temp_4" },
		{ name = "Comfortable", min = racialThresholds.comfortableMin, max = racialThresholds.comfortableMax, spellId = "sd_temp_3" }, -- 15
		{ name = "Warm",		min = racialThresholds.comfortableMax, max = racialThresholds.warmMax,  spellId = "sd_temp_2" }, -- 25
		{ name = "Hot",			min = racialThresholds.warmMax, max = racialThresholds.hotMin + 10,  spellId = "sd_temp_1" }, -- 35
		{ name = "Scorching",   min = racialThresholds.hotMin + 10,   max = 999, spellId = "sd_temp_0" }, -- 45
	}
	
	-- Find matching state
	for _, state in ipairs(states) do
		if temp >= state.min and temp < state.max then
			return state
		end
	end
	
	-- Default to comfortable if something goes wrong
	return states[4] -- Comfortable
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Apply Temperature Effects (Buffs/Debuffs)							  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function removeCurrentTempBuff()
	if tempData and tempData.currentTempBuff then
		typesActorSpellsSelf:remove(tempData.currentTempBuff)
		tempDbg.p(04, string.format("Removed old buff: %s", tempData.currentTempBuff))
		tempData.currentTempBuff = nil
	end
end

local function removeCurrentTempSlowDebuff()
	if tempData.currentSlowDebuff then
		typesActorSpellsSelf:remove(tempData.currentSlowDebuff)
		tempData.currentSlowDebuff = nil
	end
end

local function applyTemperatureEffects(state)
	-- vignette and heartbeat sound when approaching damage threshold
	local volume = 0
	G_vignetteColorFlags.temp = nil
	
	if tempData.currentTemp < CRITICAL_COLD_TEMPERATURE+10 then
		volume = math.floor((-tempData.currentTemp+(CRITICAL_COLD_TEMPERATURE+10))/10*20)/20
		if not next(G_vignetteColorFlags) then
			G_vignetteColorFlags.temp = "cold"
		end
	elseif tempData.currentTemp > CRITICAL_HOT_TEMPERATURE-10 then
		volume = math.floor((tempData.currentTemp-(CRITICAL_HOT_TEMPERATURE-10))/10*20)/20
		if not next(G_vignetteColorFlags) then
			G_vignetteColorFlags.temp = "risingHeat"
		end
	end
	G_heartbeatFlashing = 0
	local volume2 = 0
	local debuff
	
	-- ═══════════════════════════════════════════════════════════════════
	-- TEMP_ZELDA: Lava Fire Damage & Freezing Water Damage
	-- ═══════════════════════════════════════════════════════════════════	
	
	if TEMP_ZELDA then
	-- increase ticks/rampup for lava and freezing water
	-- if an item equipped is in HEAT_RESISTANT_TAGS or COLD_RESISTANT_TAGS and has resistance ~> 4 then immune to fire / frost spells
	-- if receiving warmth bonus from lava then take spell damage
	
		-- treat light residual dampness as dry (prevents spurious block)
		local hasFireImmunity = false
		local hasColdImmunity = false	
		
		-- Check for immunity armor (resistance >= 5)
		-- Fire immunity: Bonemold, Dwemer/Dwarven, Daedric, Ebony, Indoril
		-- equipmentData.armorPieces
		if equipmentData.heatResistance >= 4 or frostShield > 0 or fireShield > 0  then
			hasFireImmunity = true
		end
		
		-- Cold immunity: Stahlrim, Bonemold, Ebonweave
		if equipmentData.coldResistance >= 4 or fireShield > 0 or frostShield > 0 then
			hasColdImmunity = true
		end
		
		-- Vampire/Werewolf cold immunity (Immortal mode)
		if NEEDS_TEMP_VW == "Immortal" then
			if saveData.playerInfo.isVampire > 0 then
				hasColdImmunity = true
				tempDbg.p(12, "Vampire (Immortal): Immune to freezing water damage")
			end
			if saveData.playerInfo.isWerewolf > 0 then
				hasColdImmunity = true
				tempDbg.p(12, "Werewolf (Immortal): Immune to freezing water damage")
			end
		end
	
		-- LAVA DAMAGE: If near lava and no fire immunity, apply fire debuff
		if nearbyLava and not hasFireImmunity then
			if tempData.water.wetness < 0.1 then
				debuff = "sd_temp_sp_fire_slow"
				G_vignetteColorFlags.temp = "risingHeat"
				tempDbg.p(11, "NEAR LAVA: Fire damage! (Equip Bonemold, Dwemer, Daedric, Ebony, or Indoril for immunity)")
			else
				tempDbg.p(11, string.format("NEAR LAVA but protected by wetness: %.2f", tempData.water.wetness))
				G_vignetteColorFlags.temp = "risingHeat"
				tempData.water.wetness = tempData.water.wetness - 0.02 * secondsPassed
				if math.random() < 0.3*secondsPassed then
					G_flashVignette = 0.4
					types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - 0.5
				end
			end
		end
		
		-- FREEZING WATER DAMAGE: If in cold water and no cold immunity, apply frost debuff
		-- Water is freezing if submersion > 0.25 and water temp < 5°C
		-- This affects cold regions like Solstheim and Sheogorad
		if G_isInWater and G_isInWater > 0.25 and not hasColdImmunity then
			if waterTemp < 5 then
				debuff = "sd_temp_sp_frost_slow"
				G_vignetteColorFlags.temp = "cold"
				tempDbg.p(12, "FREEZING WATER: Frost damage! (Equip Stahlrim, Bonemold, or Ebonweave for immunity)")
			end
		end
		
		-- RED MOUNTAIN PEAK DAMAGE: If on Red Mountain without fire immunity
		-- Only applies if TEMP_RM setting is enabled
		if G_cellInfo.isExterior and TEMP_RM and isOnRedMountain > 0.26 and not hasFireImmunity then
			debuff = "sd_temp_sp_fire_slow"
			G_vignetteColorFlags.temp = "risingHeat"
			tempDbg.p(11, "RED MOUNTAIN SUMMIT: Extreme heat! (Equip Bonemold, Dwemer, Daedric, Ebony, or Indoril for immunity)")
		end			
		
		-- Apply or remove debuff
		if debuff then
		
			tempDbg.p(03, string.format("Applied TEMP_ZELDA debuff: %s", debuff))
			
			tempData.zeldaDebuffActive = true
			
			-- Apply damage
			tempData.tempDamageThrottle = tempData.tempDamageThrottle + secondsPassed
			tempData.tempDamageSeverityTimer = tempData.tempDamageSeverityTimer + secondsPassed
			local severity = math.min(10, 4 + math.floor(tempData.tempDamageSeverityTimer/5))
			if debuff == "sd_temp_sp_fire_slow" then
				severity = math.min(10, 1 + math.floor(tempData.tempDamageSeverityTimer/5))
			end
			-- Calculate resistance multiplier
			local resistanceMult = 0
			if debuff == "sd_temp_sp_frost_slow" then
				resistanceMult = math.max(0, (100 + frostWeak - frostRes - frostShield) / 100)
			else
				resistanceMult = math.max(0, (100 + fireWeak - fireRes - fireShield) / 100)
			end
			
			-- VFX
			G_heartbeatFlashing = 0.6*(0.5+severity/20)
			volume2 = math.floor(1/3+severity/15*20)/20
			
			tempDbg.p(13, string.format("In extreme environment: %i damage/s", severity))
			
			-- Apply damage
			local maxHealth = types.Actor.stats.dynamic.health(self).base
			local dmg = math.min(maxHealth * 0.2, (0.175+maxHealth * 0.0007) * severity * secondsPassed * resistanceMult)
			if not debug.isGodMode() then
				types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - dmg
			end
		else
			-- TEMP_ZELDA is not active - cleanup if we were the ones who applied the debuff
			if tempData.zeldaDebuffActive then
				removeCurrentTempSlowDebuff()
				tempData.tempDamageSeverityTimer = 0
				tempData.tempDamageThrottle = 0
				G_heartbeatFlashing = 0
				tempData.zeldaDebuffActive = false
				tempDbg.p(03, "Removed TEMP_ZELDA debuff")
			end
		end
	end

	--print("vol",volume, G_vignetteColorFlags.temp, next(G_vignetteColorFlags), tempData.tempDamageSeverityTimer, severity)
	if TEMP_EXTREMES then
		-- determine debuff
		G_heartbeatInterval = 1
		
	-- Check for Vampire/Werewolf cold immunity (Immortal mode)
		local hasVWColdImmunity = false
		if NEEDS_TEMP_VW == "Immortal" then
			if saveData.playerInfo.isVampire > 0 or saveData.playerInfo.isWerewolf > 0 then
				hasVWColdImmunity = true
			end
		end
		
		if tempData.currentTemp <= CRITICAL_COLD_TEMPERATURE + 0.1 and not hasVWColdImmunity then		
			debuff = "sd_temp_sp_frost_slow"
			G_heartbeatInterval = ( 1 + ( - tempData.currentTemp - CRITICAL_COLD_TEMPERATURE ) / 50) ^ 0.7
		elseif tempData.currentTemp >= CRITICAL_HOT_TEMPERATURE - 0.1 then
			debuff = "sd_temp_sp_fire_slow"
		else
			removeCurrentTempSlowDebuff()
		end
		if debuff then
			local severity = math.min(10, 0.5 + volume*1.5)
			G_heartbeatFlashing = 0.6

			local resistanceMult = 0
			if debuff == "sd_temp_sp_frost_slow" then
				resistanceMult = math.max(0, (100 + frostWeak - frostRes - frostShield )/100)
			else
				resistanceMult = math.max(0, (100 + fireWeak - fireRes - fireShield)/100)
			end
			local maxHealth = types.Actor.stats.dynamic.health(self).base
			local dmg = math.min(maxHealth * 0.2, (0.175+maxHealth * 0.0007) * severity * secondsPassed * resistanceMult )
			if not debug.isGodMode() then
				types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - dmg
			end
		end
	elseif not debuff then
		volume = math.min(1, volume) / 2
	end
	if G_preventAddingAnyBuffs then
		debuff = nil
	end
	if tempData.currentSlowDebuff ~= debuff then
		removeCurrentTempSlowDebuff()
		tempData.currentSlowDebuff = debuff
		if debuff then
			typesActorSpellsSelf:add(debuff)
		end
	end
	if debuff then
		tempDbg.p(12, "Slow debuff from extreme environment")
	end
	if math.max(volume, volume2) >= 0.05 then
		G_heartbeatFlags.temp = math.min(1, math.max(volume, volume2))
		G_vignetteFlags.temp = math.min(1, math.max(volume, volume2))/4
	else
		G_heartbeatFlags.temp = nil
		G_vignetteFlags.temp  = nil
	end
		
	-- Apply new temperature buff
	local spellId = state.spellId
	local isBuff = spellId == "sd_temp_2" or spellId == "sd_temp_3"
	if not G_preventAddingAnyBuffs
	and (TEMP_BUFFS_DEBUFFS == "Only buffs" and isBuff
	  or TEMP_BUFFS_DEBUFFS == "Only debuffs" and not isBuff
	  or TEMP_BUFFS_DEBUFFS == "Buffs and debuffs") then
		-- adding buff is ok
	else
		spellId = nil
	end

	if tempData.currentTempBuff ~=spellId then
		removeCurrentTempBuff()
		if spellId then
			typesActorSpellsSelf:add(spellId)
			tempDbg.p(03, string.format("Applied buff: %s (%s)", spellId, state.name))
		end
		tempData.currentTempBuff = spellId
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Update Loop														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function module_temp_minute(c, refreshUi)
	if not NEEDS_TEMP then return end
	clockHour =  c or clockHour -- only getting clockHour on
	
	local nowGT = core.getGameTime()
	local minutesPassed = (nowGT - lastGametimeUpdate) / time.minute
	
	if c and minutesPassed < 30 then -- dont update on regular hourly events, only onFrameSluggish
		return
	end
	secondsPassed = (nowGT - lastGametimeUpdate) /  core.getGameTimeScale()
	if not c and secondsPassed < 0.1 and not refreshUi then
		return
	end
	lastGametimeUpdate = nowGT
	--print(secondsPassed)
	--local prevTime = core.getRealTime()
	--for i=1,1000 do
	G_temperatureWidgetTooltip = ""
	dryingRateTooltip = nil
	tempDbg.clear()
	G_temperatureRate = 1
	G_heatRate = 1
	G_coolRate = 1
	hearthfireMagnitude = 0
	cell = self.cell
	if not cell then return end
	
	-- undo modifier to current temp before temp calculation
	if tempData.heatSourceBonus and tempData.heatSourceBonus > 0 then
		tempData.currentTemp = tempData.currentTemp - tempData.heatSourceBonus
		tempData.heatSourceBonus = 0
	end
	
	-- Calculate target environment temperature
	tempData.targetTemp = calculateEnvironmentTemperature()
	-- Player temperature adjusts gradually toward environment using exponential decay
	-- This formula naturally handles any time scale (1 minute or 480 minutes)
	local tempDiff = tempData.targetTemp - tempData.currentTemp
	
	-- Decay rate: 0.1 per minute (10% of difference closed each minute)
	-- Formula: change = diff * (1 - (1-rate)^minutes)
	-- This prevents extreme changes during rest/wait

	-- ═══════════════════════════════════════════════════════════════════
	-- Apply Racial Gain Rate Multipliers
	-- ═══════════════════════════════════════════════════════════════════
	race = getPlayerRace()
	racialData = RACIAL_TEMPERATURE_DATA[race]
	
	if racialData then
		local heatMult = racialData.heatGainRate or 1.0
		local coldMult = racialData.coldGainRate or 1.0
		G_heatRate = G_heatRate * heatMult
		G_coolRate = G_coolRate * coldMult
		-- only for debug now:
		
		if tempDiff > 0 then  -- Heating up
			if heatMult ~= 1.0 then
				tempDbg.p(13, string.format("  %s: Heat rate: %.2fx", race, heatMult))
			end
		elseif tempDiff < 0 then  -- Cooling down
			if coldMult ~= 1.0 then
				tempDbg.p(13, string.format("  %s: Cold rate: %.2fx", race, coldMult))
			end
		end
		
		-- High Elf exterior multiplier (20% faster temperature changes in exteriors)
		if racialData.exteriorGainMultiplier then
			if G_cellInfo.isExterior and racialData.exteriorGainMultiplier then
				G_temperatureRate = G_temperatureRate * racialData.exteriorGainMultiplier
				tempDbg.p(13, string.format("  %s: Exterior gain: %.2fx", race, racialData.exteriorGainMultiplier))
			end
		end
		
		-- ═══════════════════════════════════════════════════════════════════
		-- Time-Based Effects (Night/Twilight Bonuses)
		-- ═══════════════════════════════════════════════════════════════════
		-- Khajiit: Night cold reduction (20:00-6:00)
		if racialData.nightColdReduction then
			local hour = clockHour
			local isNight = (hour >= 20 or hour < 6)
			G_coolRate = G_coolRate * racialData.nightColdReduction
			if isNight and tempDiff < 0 then  -- Cooling down at night
				tempDbg.p(13, string.format("  %s: Night cold reduction: %.2fx", 
					race, racialData.nightColdReduction))
			end
		end
		
		-- Redguard: Night cooling in hot climates (20:00-6:00)
		if racialData.nightCoolingBonus then
			local hour = clockHour
			local isNight = (hour >= 20 or hour < 6)
			
			if isNight and tempDiff < 0 then  -- Cooling down at night
				-- Check if in hot climate
				local inHotClimate = climateType == "tropical" or climateType == "ashland" or 
									 climateType == "volcanic" or climateType == "grassland"
				
				if inHotClimate then
					G_coolRate = G_coolRate * racialData.nightCoolingBonus
					tempDbg.p(13, string.format("  %s: Night cooling in hot climate: %.2fx", 
						race, racialData.nightCoolingBonus))
				end
			end
		end
		
		-- ═══════════════════════════════════════════════════════════════════
		-- Threshold Rate Modifiers
		-- ═══════════════════════════════════════════════════════════════════
		if racialData.thresholdRates then
			for _, range in ipairs(racialData.thresholdRates) do
				-- Check if currently transitioning through this temperature range
				-- This applies when moving in either direction through the range
				local currentInRange = (tempData.currentTemp >= range.from and tempData.currentTemp <= range.to)
				local targetInRange = (tempData.targetTemp >= range.from and tempData.targetTemp <= range.to)
				local crossingRange = (tempData.currentTemp < range.from and tempData.targetTemp > range.to) or
									  (tempData.currentTemp > range.to and tempData.targetTemp < range.from)
				
				if currentInRange or targetInRange or crossingRange then
					local oldRate = G_temperatureRate
					G_temperatureRate = G_temperatureRate * range.rate
					tempDbg.p(13, string.format("  %s: Threshold modifier (%s-%s): %.2fx (%.3f -> %.3f)", 
						race, formatTemperature(range.from), formatTemperature(range.to), range.rate, oldRate, G_temperatureRate))
					break  -- Only apply one threshold modifier
				end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Imperial Fast Interior Adaptation
	-- ═══════════════════════════════════════════════════════════════════
	-- Track interior transitions
	if not tempData.wasInInterior then
		tempData.wasInInterior = false
	end
	
	local currentlyInInterior = not G_cellInfo.isExterior
	
	-- Check if just entered interior
	if currentlyInInterior and not tempData.wasInInterior then
		if racialData.fastInteriorAdaptation then
			tempData.interiorAdaptationBonus = true
		end
	end
	
	-- Apply Imperial fast adaptation bonus (2x temp rate)
	if tempData.interiorAdaptationBonus then
		G_temperatureRate = G_temperatureRate * 2.0
		tempDbg.p(13, string.format("%s: Fast adaptation rate: 2.00x", race))
		
		-- Remove bonus once target is reached (within 1°C)
		if math.abs(tempData.currentTemp - tempData.targetTemp) < 1.0 then
			tempData.interiorAdaptationBonus = false
		end
	end
	
	-- Update interior tracking
	tempData.wasInInterior = currentlyInInterior
	
	-- ═══════════════════════════════════════════════════════════════════
	-- Wood Elf Urban/Wilderness Modifier
	-- ═══════════════════════════════════════════════════════════════════
	if racialData.urbanPenalty then
		local inUrban = false
		
		-- Check if in interior (always counts as urban)
		if not G_cellInfo.isExterior then
			inUrban = true
		else
			inUrban = climateType == "urban"
		end
		
		if inUrban and racialData.urbanPenalty then
			-- Urban/interior: temperature changes 15% faster (uncomfortable)
			G_temperatureRate = G_temperatureRate * racialData.urbanPenalty
			tempDbg.p(13, string.format("  %s: Urban penalty: %.2fx", 
				race, racialData.urbanPenalty))
		elseif not inUrban and racialData.wildernessBonus then
			-- Wilderness: temperature changes 15% slower (comfortable)
			G_temperatureRate = G_temperatureRate * racialData.wildernessBonus
			tempDbg.p(13, string.format("  %s: Wilderness bonus: %.2fx", 
				race, racialData.wildernessBonus))
		end
	end
	
	local remainingFactor = math.pow(1 - G_temperatureRate/100, secondsPassed)
	local changeAmount = tempDiff * (1 - remainingFactor)
	
	tempData.currentTemp = tempData.currentTemp + changeAmount
	
	if tempData.targetTemp > tempData.currentTemp  then
		G_temperatureRate = G_temperatureRate * G_heatRate
		tempData.currentTemp = math.min(tempData.targetTemp, tempData.currentTemp + 0.02*secondsPassed*G_temperatureRate)
	else
		G_temperatureRate = G_temperatureRate * G_coolRate
		tempData.currentTemp = math.max(tempData.targetTemp, tempData.currentTemp - 0.02*secondsPassed*G_temperatureRate)
	end

	-- Apply persistent +2 to current temp while heat sources are active
	-- This modifier is removed when heat sources become inactive
	local newHeatBonus = math.min(2, math.max(equipmentData.hasTorch or 0, nearbyHotMod, nearbyWarmMod)) -- idk
	
	if newHeatBonus > 0 then
		tempData.currentTemp = tempData.currentTemp + newHeatBonus
		tempData.targetTemp = tempData.targetTemp + newHeatBonus
		
		tempDbg.p(12, string.format("Heat sources active: %s to current temp", formatTemperatureModifier(newHeatBonus)))
	end
	tempData.heatSourceBonus = newHeatBonus
	
	-- Determine state and apply effects
	local state = getTemperatureState(tempData.currentTemp)
	tempDbg.p(1, string.format("%s: %s (target: %s, change: %s, seconds: %.2f, rate: x%.2f)", 
		state.name, formatTemperature(tempData.currentTemp), formatTemperature(tempData.targetTemp), formatTemperatureModifier(changeAmount), secondsPassed, G_temperatureRate))
	tempDbg.p(21, string.format("%s: %s -> %s (Rate: x%.2f)",
		state.name, formatTemperature(tempData.currentTemp), formatTemperature(tempData.targetTemp), G_temperatureRate))
	G_playerCurrentTempString = formatTemperatureShort(tempData.currentTemp)
	G_playerTargetTempString = formatTemperatureShort(tempData.targetTemp)	
	G_playerTempBuffString = state.name

	applyTemperatureEffects(state)
	
	G_temperatureWidgetTooltip = G_temperatureWidgetTooltip.."\n"..(not tempData.currentTempBuff and "" or tooltips[tempData.currentTempBuff] or "ERROR: "..tostring(tempData.currentTempBuff))
		
	-- ═══════════════════════════════════════════════════════════════════
	-- Apply wetness debuff
	-- ═══════════════════════════════════════════════════════════════════
	local newWetnessDebuff = nil
	
	if TEMP_WETNESS_DEBUFFS 
	and not G_preventAddingAnyBuffs 
	and tempData.water.wetness > 0.1
	and G_isInWater <= 0.5
	then
		local temperatureMitigation = math.max(0,(climateTemperature-20)/20)
		local debuffLevel = math.max(1,math.min(5,math.floor((tempData.water.wetness+0.1)*5-temperatureMitigation)))
		--print(tempData.water.wetness+0.1, -temperatureMitigation, climateTemperature)
		newWetnessDebuff = "sd_wet_"..debuffLevel
		G_temperatureWidgetTooltip = G_temperatureWidgetTooltip.."\n\n".. math.floor(tempData.water.wetness*100) .. "% wet:"
		if dryingRateTooltip then
			G_temperatureWidgetTooltip = G_temperatureWidgetTooltip.." ("..dryingRateTooltip..")"
		end
		G_temperatureWidgetTooltip = G_temperatureWidgetTooltip.."\n"..(tooltips[newWetnessDebuff] or "???")
	end
	
	if newWetnessDebuff ~= tempData.water.wetnessDebuff then
		if tempData.water.wetnessDebuff then
			typesActorSpellsSelf:remove(tempData.water.wetnessDebuff)
		end
		if newWetnessDebuff then
			typesActorSpellsSelf:add(newWetnessDebuff)
		end
		tempData.water.wetnessDebuff = newWetnessDebuff
	end
	
	local newHearthfireBuff = nil
	if hearthfireMagnitude >= 2 then
		newHearthfireBuff = "sd_hearthfire_"..math.min(4,math.floor(hearthfireMagnitude/2))
	end
	if newHearthfireBuff ~= tempData.currentHearthfireBuff then
		if tempData.currentHearthfireBuff then
			typesActorSpellsSelf:remove(tempData.currentHearthfireBuff)
		end
		if newHearthfireBuff then
			typesActorSpellsSelf:add(newHearthfireBuff)
		end
		tempData.currentHearthfireBuff = newHearthfireBuff
	end
	
	updateTemperatureWidget()
	
	--end
	--print(core.getRealTime()-prevTime)
end

local function onConsumedWater(liquid, remainingWater)
	if not NEEDS_TEMP then return remainingWater end
	if remainingWater > 0 then
		if remainingWater >=0.99 then
			ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
			tempData.water.wetness = math.min(1,tempData.water.wetness + 0.2)
			if tempData.currentTemp > 10 then
				tempData.currentTemp = math.max(10, tempData.currentTemp - 5)
			end
			messageBox(3, "You pour water on your head")
			module_temp_minute(nil,  0)
			return 0
		else
			messageBox(3, "Your thirst is quenched")
		end
	end
	return remainingWater
end

table.insert(G_onConsumedWaterJobs, #G_onConsumedWaterJobs, onConsumedWater)

local function onConsume(item)
	if not NEEDS_TEMP then return end
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if entry and entry.warmthValue and entry.warmthValue ~= 0 then 
		tempData.currentTemp = math.min(25, tempData.currentTemp + entry.warmthValue)
	elseif item.type.record(item).name:sub(1, 6) == " Stew [" then
		tempData.stewBonus = 60
		if tempData.currentTemp < 25 then
			tempData.currentTemp = math.min(25, tempData.currentTemp + 5)
		end
		module_temp_minute(nil,  0)
	end
end

table.insert(G_onConsumeJobs, onConsume)

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Initialization														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function onLoad()
	if not NEEDS_TEMP then return end
	-- Initialize saved data if needed
	if not saveData.m_temp then
		saveData.m_temp = {
			currentTemp = 20,
			targetTemp = 20,
			currentTempBuff = nil,
		}
	end
	tempData = saveData.m_temp
	if not tempData.water then
		tempData.water = {
			wetness = 0,		 -- How wet you are (0-1)
			lastWaterTemp = 0,   -- Last water temperature
			timeInWater = 0,	 -- Seconds spent in water
		}
	end
	tempData.tempDamageThrottle = 0
	if not tempData.tempDamageSeverityTimer then
		tempData.tempDamageSeverityTimer = 0
	end
	scanEquipment()
	lastGametimeUpdate = core.getGameTime()
	clockHour = math.floor((math.floor(core.getGameTime() / time.minute) / 60 + G_clockOffset))%24
	secondsPassed = 0
	module_temp_minute(nil, 0)
	updateTemperatureWidget()
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Module Exports														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

table.insert(G_perHourJobs,module_temp_minute)

--table.insert(G_onFrameJobsSluggish,module_temp_minute)
table.insert(G_sluggishScheduler[1], module_temp_minute)
G_onFrameJobsSluggish.module_temp_minute = module_temp_minute

table.insert(G_equipmentChangedJobs, onEquipmentChanged)
--table.insert(G_onLoadJobs,onLoad)
G_onLoadJobs[9546] = onLoad

local function settingsChanged(sectionName, setting, oldValue)
	if setting == "NEEDS_TEMP" then
		if oldValue == false then
			onLoad()
		elseif not NEEDS_TEMP then
			removeCurrentTempBuff()
			removeCurrentTempSlowDebuff()
			saveData.m_temp = nil
			G_destroyTemperatureUis()
			--G_vignetteFlags.thirst = nil
		end
	elseif setting == "TEMP_TOTSP" then
		for _, vector in pairs(CLIMATE_SOURCES) do
			if vector.name:lower():find("totsp") then
				if TEMP_TOTSP then
					vector.radius = vector.radius * 10000
				else
					vector.radius = vector.radius / 10000
				end
			end
		end
	elseif setting == "TEMP_BAR_STYLE" then
		G_destroyTemperatureUis()
		--refreshUi()
	elseif setting == "TESTING_WIDGET" then
		if TESTING_WIDGET then
			tempDbg2 	= require("scripts.SunsDusk.ui_debugWidget")("	=============== Temperature ===============")
			armorDbg2 =  require("scripts.SunsDusk.ui_debugWidget")("	===== Armor Equip =====")
			weatherDbg	= require("scripts.SunsDusk.ui_debugWidget")("	=============== Weather ===============")
		elseif tempDbg2 then
			tempDbg2.destroy()
			armorDbg2.destroy()
			weatherDbg.destroy()
			tempDbg2 = nil
			armorDbg2 = nil
			weatherDbg = nil
		end
	end
	if sectionName == "SettingsSunsDuskTEMP" or sectionName == "SettingsSunsDuskTEMP2" then
		G_destroyTemperatureUis()
	end
end
table.insert(G_settingsChangedJobs, settingsChanged)

local function removeTempBuffs()
	if tempData.water.wetnessDebuff then
		typesActorSpellsSelf:remove(tempData.water.wetnessDebuff)
		tempData.water.wetnessDebuff = nil
	end
	if tempData.currentTempBuff then
		typesActorSpellsSelf:remove(tempData.currentTempBuff)
		tempData.currentTempBuff = nil
	end
	if tempData.currentSlowDebuff then
		typesActorSpellsSelf:remove(tempData.currentSlowDebuff)
		tempData.currentSlowDebuff = nil
	end
	if tempData.currentHearthfireBuff then
		typesActorSpellsSelf:remove(tempData.currentHearthfireBuff)
		tempData.currentHearthfireBuff = nil
	end
end
table.insert(G_removeAbilitiesJobs, removeTempBuffs)

--local function test()
--	local file, errorMsg = vfs.open("scripts/SunsDusk/ui_makeButton.lua")
--	if file then
--			--log(5, "[SD] Loading file: " .. filename)
--			local tsvData = file:read("*all")
--			print(tsvData)
--			file:close()
--		
--	end
--end
--table.insert(G_perMinuteJobs, test)