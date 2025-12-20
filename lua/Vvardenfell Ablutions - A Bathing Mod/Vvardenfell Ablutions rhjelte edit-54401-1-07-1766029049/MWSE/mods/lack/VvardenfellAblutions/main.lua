local ashfall = include("mer.ashfall.interop")

local confPath = "lack_bath_config"
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.o,
	hours = 30,
	requireNudity = true,
	weatherEffects = true,
	dialogEnabled = true
}

local config = mwse.loadConfig(confPath, configDefault)

-- How often hygiene is updated in seconds
local INTERVAL = 5 

-- Any ID substrings of items the player should be able to use as a water source
local bathObjects = { 
	"waterfall",
 	"bathtub",
	"ex_vivec_p_water",
	"forgetful_pool",
	"pool_01",
	"terrwater",
	"waternarsis",
	"barrelwater",
	"waterflow",
	"waterrapid",
	"watersquare",
	"barrel01water",
	"lwbowlwater",
	"ko_basin",
	"ko_rose_basin",
	"ko_white_basin",
	"clawtub",
	"water_bucket-bathsale",
	"nom_well_",
	"hlaalu_well",
	"ex_redoran_well",
	"ex_t_wellpod",
	"rp_red_well",
	"rp_mh_well",
	"rm_well",
	"ruined_well_",
	"ex_nord_well",
	"furn_well00",
	"act_bm_well",
	"_EG_bath",
	"_EG_tel_bath",
	"ab_ex_velwellfountain",
	"watercircle",
	"waterrect",
	"bucketwater",
	"t_com_furn_basin_01",
	"t_imp_furnr_basin_01",
	"t_imp_furnr_basin_02_w",
	"t_imp_furnr_basin_03_w",
	"nm_well_red",
	"luce_redware_water_basin",
	"bathhalfbarrel",
	"legioncyr_x_well",
	"nor_set_well",
	"poor_x_well",
	"legionsky_x_well",
	"s3_bath_02",
	"S3_bath_04_hlaalu",
	"S3_bath_02",
	"S3_bath_05_molag",
	"S3_bath_01",
	"S3_bath_01gr",
	"S3_bath_03",
	"S3_bath_06_redoran",
	"S3_bath_07",
	"S3_bath_07gr",
	"S3_bath_08_tel",
	"dim_bc_well",
	"_KIL_hlaalu_well01",
    "t_com_var_barrelwater_01",
    "t_glb_terrwater_waterjet_01" ,

    -- Water: Dirty
    "t_com_furn_bath_01",
    "t_com_furn_bathhalfbarrel_01",
    "t_com_furn_bathhalfbarrel_02",
    "t_glb_terrwater_circle1024_01",
    "t_glb_terrwater_circle128_01",
    "t_glb_terrwater_circle2048_01",
    "t_glb_terrwater_circle256_01",
    "t_glb_terrwater_circle512_01",
    "t_glb_terrwater_circle64_01",
    "t_glb_terrwater_curveflw256_01",
    "t_glb_terrwater_curveflw256s_01",
    "t_glb_terrwater_curveflw512_01",
    "t_glb_terrwater_curveflw512s_01",
    "t_glb_terrwater_curverpd256_01",
    "t_glb_terrwater_curverpd256s_01",
    "t_glb_terrwater_curverpd512_01",
    "t_glb_terrwater_curverpd512s_01",
    "t_glb_terrwater_rectflw256_01",
    "t_glb_terrwater_rectflw256_02",
    "t_glb_terrwater_rectflw256_03",
    "t_glb_terrwater_rectrpd256_01",
    "t_glb_terrwater_rectrpd256_02",
    "t_glb_terrwater_rectrpd256_03",
    "t_glb_terrwater_rectstill256_01",
    "t_glb_terrwater_rectstill256_02",
    "t_glb_terrwater_rectstill256_03",
    "t_glb_terrwater_sqrflw1024_01",
    "t_glb_terrwater_sqrflw256_01",
    "t_glb_terrwater_sqrflw512_01",
    "t_glb_terrwater_sqrstill1024_01",
    "t_glb_terrwater_sqrstill256_01",
    "t_glb_terrwater_sqrstill512_01",
    "t_glb_terrwatersew_waterfall_01",
    "t_glb_terrwatersew_waterfall_02",
    "t_glb_terrwatersew_waterfall_03",
    "t_de_sethla_x_watercbnarsis_01",
    "t_de_sethla_x_waternarsis_01",
    "t_de_sethla_x_waternarsis_0",
    "t_de_sethla_x_waternarsis_03",
    "t_imp_furn_bath_01_w",
    "t_imp_furnr_bath_01",
    "t_imp_furnr_bath_02_w",

    -- Water: Wells
        -- High Rock
    "t_bre_setostr_x_well_01",
    "t_bre_setostr_x_well_02",
        -- Morrowind
    "t_com_set_well_02",
    "t_com_set_welldg_01",
    "t_de_sethla_x_well_01",
    "t_de_setind_x_well_01",
    "t_de_setmh_x_well_01",
    "t_de_setred_x_well_01",
    "t_de_setred_x_well_02",
    "t_de_setveloth_x_well_01",
    "t_dwe_dngruin_f_well_01",
        -- Cyrodiil
    "t_ayl_dngruin_x_well_01",
    "t_imp_legioncyr_x_well_01",
    "t_imp_legioncyr_x_well_02",
    "t_imp_legionmw_x_well_01",
    "t_imp_legionmw_x_well_02",
    "t_imp_legionsky_x_well_01",
    "t_imp_legionsky_x_well_02",
    "t_imp_setgcpoor_x_well_01",
    "t_imp_setnord_x_well_01",
    "t_imp_setsky_x_well_01",
    "t_imp_setsky_x_well_02",
    "t_imp_setsky_x_well_03",
        -- Skyrim
    "t_nor_set_well_01",
    "t_nor_set_well_02",
    "t_nor_set_well_03",
    "t_nor_set_well_04",
    "t_nor_set_well_05",
    "T_Nor_SetSkaal_Well_01",
        -- Hammerfell
    "t_rga_setreach_x_pool_01",

	"ex_nord_well_01",
	"ex_nord_well_01a",
	"furn_well00",
	"rm_well",
	"act_bm_well_01",
	"nom_ac_pool",
	"nom_ashland_pool",
	"nom_basin",
	"nom_bc_pool00",
	"nom_bc_pool01",
	"nom_mh_spuot",
	"nom_midevil_well",
	"nom_pump_dunmer",
	"nom_pump_dwemer",
	"nom_pump_imperial",
	"nom_source_ac",
	"nom_source_bc",
	"nom_source_eraben",
	"nom_source_mh",
	"nom_source_strong02",
	"nom_source_strong03",
	"nom_source_urshilaku",
	"nom_source_zainab",
	"nom_strong02_pool",
	"nom_strong03_pool",
	"nom_water_barrel",
	"nom_water_round",
	"nom_water_round_ani",
	"nom_water_spray",
	"nom_water_spray_fab",
	"nom_well_common_01",
	"nom_well_mh_01",
	"nom_well_nord_01",
	"nom_well_nord_colony1",
	"nomni_ex_hlaalu_well",
	"nomni_ex_redoran_well",
	"nomni_ex_t_wellpod",
	"rp_wellpod",
	"nomni_well_common_strong1",
	"tr_m3_oe_plaza_water_uni",
	"mr_hlaalu_fountain",
	"mr_redoran_well",
	"mr_stronhold_well",
	"mr_hlaalu_well_01",
	"mr_imp_well_roofed",
	"_ex_hlaalu_well",
	"izi_hlaalu_well",
	"ex_imp_well_01",
	"ex_s_well_01",
	"bw_ex_hlaalu_well",
	"rp_wooden_well",
	"mr_imp_well_01",
	"ab_ex_velwellfountain",
	"mr_imp_well",
	"nm_well_red",
	"dim_bc_well",
	"_KIL_hlaalu_well01",
}

local warmWaterSource = {
	"bathtub",
	"t_com_furn_bath_01",
	"t_imp_furn_bath_01_w",
    "t_imp_furnr_bath_01",
    "t_imp_furnr_bath_02_w",
	"s3_bath_02",
	"S3_bath_04_hlaalu",
	"S3_bath_02",
	"S3_bath_05_molag",
	"S3_bath_01",
	"S3_bath_01gr",
	"S3_bath_03",
	"S3_bath_06_redoran",
	"S3_bath_07",
	"S3_bath_07gr",
	"S3_bath_08_tel",
}

local warmBath_cellID = {
	"public bath",
	"bath house",
	"healing bath"
}

-- Provides a small personality buff
local florals = { "ingred_heather", "ingred_stoneflower_petals", "ingred_noble_sedge", "ingred_timsa", "ingred_horn", "ingred_gold_kanet", 
"ab_ingflor_bluekanet_01", "t_ingflor_alkanet_01", "t_ingflor_bluekanet_01", "t_ingflor_cornflower_01", "t_ingflor_cowbell_01", "t_ingflor_desrosepetal_01", "t_ingflor_dragynia_01", 
"t_ingflor_fireflower_01", "t_ingflor_flaxflower", "t_ingflor_hibiscus_01", "t_ingflor_honeylily_01", "t_ingflor_oleander_01", "t_ingflor_persarine_01", "t_ingflor_redrosepetal" }

-- Provides a medium personality buff
local soaps = { "soap", "shampoo", "bubblebath", "bodylotion"}

-- Provides a large personality buff
local fragrants = { "bath_oil", "bug_musk", "ko_bath_salts", "luce_bath_salts", "bath_powder", "moonlust", "darkpassion", "eveninghaze", "parfuem", "blood musk", "cologne", "aftershave", "perfume" }

-- Provides magicka resistance + personality
local magicalSalts = { "ingred_void_salt" }

-- Provides fire resistance + personality
local fireSalts = { "ingred_fire_salt" }

-- Provides frost resistance + personality
local frostSalts = { "ingred_frost_salt" }

-- Provides blight resistance + personality
local ashSalts = { "ingred_ash_salt" }

-- These are race names which should be able to lick themselves clean
local lickers = { "khajiit", "ohmes-raht", "ohmes", "suthay", "suthay-raht", "dagi-raht", "cathay-raht", "cathay", "senche-raht", "rishajiit" }

local dirtEffects = { "lack_bath_dirt1", "lack_bath_dirt2", "lack_bath_dirt3", "lack_bath_dirt4", "lack_bath_dirt5" }
local weatherEffects = { "lack_bath_ashy", "lack_bath_blighty" }
local bathBuffs = { "lack_bath_ashsalt", "lack_bath_firey", "lack_bath_floral", "lack_bath_fragrant", "lack_bath_frosty", "lack_bath_magical", "lack_bath_soapy" }

-- strings for reporting dirt levels
local dirtReports = { "It has been a while since you last bathed.", "You feel a little messy.", "You feel dirty.", "You feel filthy.", "You are a disgusting, stinky mess!" }

local soapSound = "drown"
local waterSound = "Swim Left"
local lickSound = "greneat"

local fadeInTimer

local HAIRBALL_CHANCE = 5 -- out of 100, chance of getting a debuff when lick-cleaning

if not config then
    config = { blocked = {} }
end

local keybindButton
local enableButton
local nudityButton
local weatherButton
local dialogButton

local alreadyBathing = false


local function subString(arr, x)
	for _, v in pairs(arr) do
		local s = v:lower()
		if string.find(x, s) then
			return true 
		end
	end
	return false
end

local function validItem(i)
	if i and i.item then
		local s = i.item.id:lower()
		if subString(florals, s) or subString(soaps, s) or subString(fragrants, s) or subString(magicalSalts, s) or subString(fireSalts, s) or subString(frostSalts, s) or subString(ashSalts, s) then
			return true
		else
			return false
		end
	end
end

local function fadeIn()
	tes3.fadeIn()
	alreadyBathing = false
	fadeInTimer:pause()
end

local function startFadeInTimer()

	if not fadeInTimer then
		fadeInTimer = timer.start({ duration = 3, callback = fadeIn, type = timer.simulate, iterations = -1 })
	else
		fadeInTimer:resume()
	end

end

-- Remove all dirtiness effects (not counting weather)
local function clearEffects()
	for _, effect in ipairs(dirtEffects) do
		tes3.removeSpell({ reference = tes3.player, spell = effect })
	end
end

-- Remove ash/blight
local function clearWeatherEffects()
	for _, effect in ipairs(weatherEffects) do
		tes3.removeSpell({ reference = tes3.player, spell = effect })
	end
end

-- Apply the appropriate debuff for our dirtiness level
local function applyEffects()
	clearEffects() -- get rid of previous tier of filth
	local i = ( tes3.player.data.VvardenfellAblutions.currentDirtLevel ) % 6
	local s = dirtEffects[i]
	
	tes3.addSpell({ reference = tes3.player, spell = s })

end

-- Apply an appropriate debuff for the weather
local function applyWeatherEffects(i)

	if ( (i == 6) and (not tes3.player.data.VvardenfellAblutions.ashy) )then
		tes3.player.data.VvardenfellAblutions.ashy = true
		tes3.messageBox("You've been covered with ash.")
		tes3.addSpell({ reference = tes3.player, spell = weatherEffects[1] })
	elseif  ( (i == 7) and (not tes3.player.data.VvardenfellAblutions.blighty) )  then
		tes3.player.data.VvardenfellAblutions.blighty = true
		tes3.messageBox("You've been covered with blighted ash.")
		tes3.addSpell({ reference = tes3.player, spell = weatherEffects[2] })
	end
end

-- reset all dirt values and remove effects
local function clean()
	tes3.player.data.VvardenfellAblutions.hygiene = 0
	tes3.player.data.VvardenfellAblutions.currentDirtLevel = 0
	
	local dirtGlobal = tes3.findGlobal("LACK_bath_filth")
	dirtGlobal.value = 0 -- for dialog filtering
	
	tes3.player.data.VvardenfellAblutions.ashy = false
	tes3.player.data.VvardenfellAblutions.blighty = false
	clearEffects()
	clearWeatherEffects()
end

-- bathing with soap or something
local function cleanWithItem(i)
	local s = i.item.id:lower()
	alreadyBathing = true
	
	if subString( florals, s ) then
		tes3.messageBox("The petals give the water a pleasing fragrance as you bathe.")
		local spell = tes3.getObject("lack_bath_floral")
		tes3.applyMagicSource{reference = tes3.player, source = spell}
		tes3.playSound({ sound = waterSound})
		tes3.fadeOut()
		clean()
		startFadeInTimer()
	elseif subString( soaps, s ) then
		tes3.messageBox("The soapy lather leaves you feeling totally refreshed.")
		local spell = tes3.getObject("lack_bath_soapy")
		tes3.applyMagicSource{reference = tes3.player, source = spell}
		tes3.playSound({ sound = soapSound})
		tes3.fadeOut()
		clean()
		startFadeInTimer()
	elseif subString( fragrants, s ) then
		tes3.messageBox("You take an exceptionally fragrant bath.")
		local spell = tes3.getObject("lack_bath_fragrant")
		tes3.applyMagicSource{reference = tes3.player, source = spell}
		tes3.playSound({ sound = soapSound})
		tes3.fadeOut()
		clean()
		startFadeInTimer()
	elseif subString( magicalSalts, s ) then
		tes3.messageBox("The magicka of the salts gives your bath an invigorating quality.")
		local spell = tes3.getObject("lack_bath_magical")
		tes3.applyMagicSource{reference = tes3.player, source = spell}
		tes3.playSound({ sound = soapSound})
		tes3.fadeOut()
		clean()
		startFadeInTimer()
	elseif subString( fireSalts, s ) then
		tes3.messageBox("You wash yourself with piping hot magically-charged water.")
		local spell = tes3.getObject("lack_bath_firey")
		tes3.applyMagicSource{reference = tes3.player, source = spell}
		tes3.playSound({ sound = waterSound})
		tes3.fadeOut()
		clean()
		startFadeInTimer()
	elseif subString( frostSalts, s ) then
		tes3.messageBox("The salts make your bath ice cold, but strangely bracing.")
		local spell = tes3.getObject("lack_bath_frosty")
		tes3.applyMagicSource{reference = tes3.player, source = spell}
		tes3.playSound({ sound = soapSound})
		tes3.fadeOut()
		clean()
		startFadeInTimer()
	elseif subString( ashSalts, s ) then
		tes3.messageBox("The salts make your bath water cloudy and grey.")
		local spell = tes3.getObject("lack_bath_ashSalt")
		tes3.applyMagicSource{reference = tes3.player, source = spell}
		tes3.playSound({ sound = soapSound})
		tes3.fadeOut()
		clean()
		startFadeInTimer()
	end

	tes3.removeItem({
		reference = tes3.mobilePlayer,
		item = i.item,
		itemData = i.itemData,
		count = 1,
		playSound = false,
	})
	
end

local function reportHygiene()
	local s = dirtReports[tes3.player.data.VvardenfellAblutions.currentDirtLevel]
	tes3.messageBox(s)	
end

-- Check whether the player is meaningfully naked -- counts equipped items other than jewelry, weapons, ammo
local function isNaked()
	-- the slots we care about
	local armorSlots = {0,1,2,3,4,5,6,7,8,9}
	local clothingSlots = {0,1,2,4,5,6,7}

	for _, s in ipairs(armorSlots) do
		if ( tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.armor, slot = s})) then
			return false
		end
	end

	for _, s in ipairs(clothingSlots) do
		if ( tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.clothing, slot = s})) then
			return false
		end
	end

	return true
end
-- Check whether we can bathe in this spot, and wash with water/tongue or open the soap menu
local function bathe(e)

	if ( tes3.menuMode() ) then
		return
	end
	
	if ( alreadyBathing ) then
		return
	end
	
	if ( config.requireNudity and not isNaked() ) then
		tes3.messageBox("You must undress in order to bathe.")
		return
	end
	
	if ( tes3.mobilePlayer.inCombat ) then
		tes3.messageBox("You cannot bathe while in combat!")
		return
	end
	
	local canBatheHere = false
	local currentCells = tes3.getActiveCells()
	local waterLevel
	local playerX = tes3.mobilePlayer.position.z
	local race = string.lower( tes3.mobilePlayer.object.race.name )
	local waterAccess
	local isCat = subString( lickers, race )
	
	-- rhjelte's addition for warm water and ashfall interop
	local warmWater = false
	
	for _, cell in ipairs(currentCells) do
		waterLevel = cell.waterLevel
	end
	
	if ( isCat ) then -- Khajiit can always lick self if no water source
		canBatheHere = true
	end
	
	if ( waterLevel and playerX < waterLevel ) then
		canBatheHere = true
		waterAccess = true -- I'm underwater
	else
		-- try to raycast a close object to see if its a water source 
		local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), maxDistance = 300, ignore = {tes3.player}};

		if rayhit and rayhit.reference then	
			local id = string.lower(rayhit.reference.object.id)
			if ( subString(bathObjects, id) ) then -- We're close to an item with a valid bath id
				canBatheHere = true
				waterAccess = true
			end
			-- rhjelte's addition for warm water and ashfall interop
			-- check if water is warm
			if ( subString(warmWaterSource, id) ) then
				warmWater = true
			end
		end
	end

	-- rhjelte's addition for warm water and ashfall interop
	-- check if you are in a bath house of some kind, which would mean all water is warm
	local cellID = string.lower(tes3.mobilePlayer.cell.id)
	if ( subString(warmBath_cellID, cellID) ) then
		warmWater = true
	end
	
		-- SA Edit: If Ashfall is installed, check if you can bathe in the rain
	local AshfallInstalled = include("mer.ashfall.interop") ~= nil
	if	AshfallInstalled then
	local weather = tes3.getCurrentWeather()
		local raining = weather and
        (weather.index == tes3.weather.rain
            or weather.index == tes3.weather.thunder)
		local lookingUp = tes3.getCameraVector().z > 0.99
		local common = require("mer.ashfall.common.common")
		local uncovered = common.data and not common.data.isSheltered
		local CanBatheInTheRain = (
				raining and
				lookingUp and
				uncovered
				)
			
		if CanBatheInTheRain then
			canBatheHere = true
			waterAccess = true
		end
	end




	if canBatheHere then
		if waterAccess then
			local message = ""
			if e.isAltDown then
					tes3ui.showInventorySelectMenu({
					reference = tes3.player,
					title = "What will you bathe with?",
					noResultsText = "You have no bathing items.",
					callback = cleanWithItem,

					filter = validItem
				})
			else
				alreadyBathing = true
				message = "You wash yourself with water."
				tes3.playSound({ sound = waterSound})
				tes3.fadeOut()
				clean()
				startFadeInTimer()
			end

			-- rhjelte's addition for warm water and ashfall interop
			if warmWater then
				if AshfallInstalled then
					 ashfall.setTemp(30)
					 message = "You feel both clean and warm after a hot bath."
				end
			end

			tes3.messageBox(message)
		else
			tes3.messageBox("You lick yourself clean.")
			alreadyBathing = true
			local hairballRoll = math.random( 100 )
			
			if ( hairballRoll < HAIRBALL_CHANCE ) then
				local spell = tes3.getObject("lack_bath_hairball")
				tes3.applyMagicSource{reference = tes3.player, source = spell}
				tes3.messageBox("You swallowed too much fur, and find yourself retching on a hairball...")
			end
			
			tes3.playSound({ sound = lickSound})
			tes3.fadeOut()
			clean()
			startFadeInTimer()
		end
	else
		tes3.messageBox("You need a water source in order to bathe")
	end

end

-- Timed function to calculate hours passed since last check, and update our "dirtiness level" based on the config's hour setting. Apply weather effects if we are in an Ash/Blight storm.
local function updateHygiene()

	if not config.enabled then
		return
	end
	
	local currDay = tes3.findGlobal("DaysPassed").value
	local currHour = tes3.findGlobal("GameHour").value
		
	local daysInHours = ( currDay - tes3.player.data.VvardenfellAblutions.day ) * 24
	local hours = currHour - tes3.player.data.VvardenfellAblutions.hour
	local hoursPassed
	
	local currentDirtLevel
	
	hoursPassed = daysInHours + hours
	
-- SA Edit: In order to increase the dirtiness level by a factor based on where we have been, we check Ashfall interior temperature, which correlates with the interior type:
	
	-- SA Edit: Initializing the new variables
	local sa_DirtinessIndex = 1
	local sa_DirtinessIndexTable = {
	["-10"] = 1,
	["-20"] = 10,
	["-30"] = 4,
	["-35"] = 4,
	["-40"] = 4,
	["-45"] = 4,
	["-50"] = 6,
	["-65"] = 6,
	}

-- SA Edit: From Ashfall
--this.interiorTempValues = {
--  default = -10,
--  sewer = -20,
--  eggmine = -30,
--  ruin = -35,
--  dungeon = -40,
--	cave = -45,
--	tomb = -50,
--	barrow = -65
-- }
	local AshfallInstalled = include("mer.ashfall.interop") ~= nil
	if	AshfallInstalled and tes3.player.cell.isInterior then
		local common = require("mer.ashfall.common.common")
		if common.data then
		sa_DirtinessIndex = sa_DirtinessIndexTable[tostring(common.data.intWeatherEffect)]
		end
		-- SA edit: If Merlord changes the temperature values and the table returns a nil, lets turn it back to 1.
		if not sa_DirtinessIndex then
		sa_DirtinessIndex = 1
		end

		--tes3.messageBox(sa_DirtinessIndex)
	end
	
	-- SA Edit: Added the sa_DirtinessIndex to the calculations
	tes3.player.data.VvardenfellAblutions.hygiene = hoursPassed*sa_DirtinessIndex + tes3.player.data.VvardenfellAblutions.hygiene
	tes3.player.data.VvardenfellAblutions.day = currDay
	tes3.player.data.VvardenfellAblutions.hour = currHour
	
	currentDirtLevel = math.floor( tes3.player.data.VvardenfellAblutions.hygiene / config.hours )
	if ( currentDirtLevel > 5 ) then
		currentDirtLevel = 5
	end
	
	if ( currentDirtLevel > tes3.player.data.VvardenfellAblutions.currentDirtLevel ) then 
		tes3.player.data.VvardenfellAblutions.currentDirtLevel = currentDirtLevel
		local dirtGlobal = tes3.findGlobal("LACK_bath_filth")
		dirtGlobal.value = currentDirtLevel -- for dialog filtering
		applyEffects()
		reportHygiene()
	end
	
	if config.weatherEffects then
		local weather
		
		for _, cell in ipairs(tes3.getActiveCells()) do
			if cell.region then
				if not weather then 
					weather = tes3.getCurrentWeather().index
				end
			end
		end
		
		if weather then
			applyWeatherEffects(weather)
		end
	end
	--tes3.messageBox("It has been %f hours since you washed. Current dirt level is %f", tes3.player.data.VvardenfellAblutions.hygiene, currentDirtLevel)

end

-- For the MCM
local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, bathe, { filter = config.hotkey } )
	config.hotkey = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, bathe, { filter = config.hotkey } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('Bathe hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

-- Get player bathing data ready and start the timer which keeps track of how long it has been since our last wash
local function startHygieneTimer()

	tes3.player.data.VvardenfellAblutions = tes3.player.data.VvardenfellAblutions or {}
	tes3.player.data.VvardenfellAblutions.hygiene = tes3.player.data.VvardenfellAblutions.hygiene or 0 -- number of hours since bath
	tes3.player.data.VvardenfellAblutions.currentDirtLevel = tes3.player.data.VvardenfellAblutions.currentDirtLevel or 0 -- 5 tiers of debuff
	tes3.player.data.VvardenfellAblutions.ashy = tes3.player.data.VvardenfellAblutions.ashy or false
	tes3.player.data.VvardenfellAblutions.blighty = tes3.player.data.VvardenfellAblutions.blighty or false
	
	local dialogGlobal = tes3.findGlobal("LACK_bath_disableDialog")
	if config.dialogEnabled then
		dialogGlobal.value = 0
	else
		dialogGlobal.value = 1
	end
	
	
	tes3.player.data.VvardenfellAblutions.hour = tes3.player.data.VvardenfellAblutions.hour or tes3.findGlobal("GameHour").value
	tes3.player.data.VvardenfellAblutions.day = tes3.player.data.VvardenfellAblutions.day or tes3.findGlobal("DaysPassed").value
	
	timer.start({ duration = INTERVAL, callback = updateHygiene, type = timer.simulate, iterations = -1 })
end

local function initialized()

	if tes3.isModActive("lack_vvardenfellAblutions.esp") then
		if ( config.enabled) then
			event.register(tes3.event.keyDown, bathe, { filter = config.hotkey } )
			event.register(tes3.event.loaded, startHygieneTimer)
		end
	else
		tes3.messageBox("Enable lack_vvardenfellAblutions.esp to enable bathing mechanics.")
	end
	
	print("[Vvardenfell Ablutions] Vvardenfell Ablutions Initialized")
end

event.register(tes3.event.initialized, initialized)

local function getButtonText(featureString, bool)
	local s
	
	if ( bool ) then
		s = featureString .. " Enabled"
	else
		s = featureString .. " Disabled"
	end
	
	return s
end

local function registerModConfig()

    local mcm = mwse.mcm
    local template = mcm.createTemplate("Vvardenfell Ablutions - Bathing")
    template:saveOnClose(confPath, config)

    local page = template:createSideBarPage{
        sidebarComponents = {
            mcm.createInfo{ 
			text = "Vvardenfell Ablutions\n \nBy AlandroSul\n\nWash yourself by pressing the hotkey while standing in water, or while targeting a nearby waterfall, bathub or basin. \n\nBathe with soaps bath oils, bug musk, perfumes, or flowers for a buff by pressing ALT with your bathe hotkey."},
        }
    }
	
    local category = page:createCategory("Settings")

    enableButton = category:createButton({
	
        buttonText = getButtonText("Mod", config.enabled),
        description = "Toggle the mod's functionality.",
        callback = function(self)
            config.enabled = not config.enabled
			event.unregister(tes3.event.keyDown, bathe, { filter = config.hotkey } )
			
			if ( config.enabled ) then
				event.register(tes3.event.keyDown, bathe, { filter = config.hotkey } )
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
				--tes3.messageBox("Bathing enabled!")
			else
				clearEffects()
				clearWeatherEffects()
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
				--tes3.messageBox("Bathing disabled!")
			end
        end
    })
	
	dialogButton = category:createButton({
	
        buttonText = getButtonText("Hygiene Dialogue", config.dialogEnabled),
        description = "NPCs may comment on your filth at various levels of uncleanliness. Some may refuse to talk to you if you really let yourself go. Default: Enabled",
        callback = function(self)
            config.dialogEnabled = not config.dialogEnabled
			local dialogGlobal = tes3.findGlobal("LACK_bath_disableDialog")
			
			if config.dialogEnabled then
				dialogGlobal.value = 0
			else
				dialogGlobal.value = 1
			end
			
			dialogButton.buttonText = getButtonText("Hygiene Dialogue", config.dialogEnabled)
			dialogButton:setText(getButtonText("Hygiene Dialogue", config.dialogEnabled))
        end
    })
	

    nudityButton = category:createButton({
	
        buttonText = getButtonText("Require Undressing", config.requireNudity),
        description = "Toggle the requirement that the player undress before bathing. Default: Enabled",
        callback = function(self)
            config.requireNudity = not config.requireNudity
			nudityButton.buttonText = getButtonText("Require Undressing", config.requireNudity)
			nudityButton:setText(getButtonText("Require Undressing", config.requireNudity))
        end
    })
	
	weatherButton = category:createButton({
	
        buttonText = getButtonText("Weather Effects", config.weatherEffects),
        description = "Toggle ash/blight effects which make you weaker to disease when caught in those weather types until next bath. Default: Enabled",
        callback = function(self)
            config.weatherEffects = not config.weatherEffects
			weatherButton.buttonText = getButtonText("Weather Effects", config.weatherEffects)
			weatherButton:setText(getButtonText("Weather Effects", config.weatherEffects))
			clearWeatherEffects()
        end
    })
	
	category:createSlider {
		label = "Bathing Hours",
		description = "Amount of time in hours between dirtiness levels. With default value, player will be totally clean for most of a waking day if they wash up in the morning. Default: 12",
		max = 720,
		min = 1,
		step = 1,
		jump = 1,
		variable = mcm:createTableVariable {
			id = "hours",
			table = config
		}
	}
	
	local category2 = page:createCategory("Keybind for bathing")
	
	keybindButton = category2:createButton({
	
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        description = "Choose bathing hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)