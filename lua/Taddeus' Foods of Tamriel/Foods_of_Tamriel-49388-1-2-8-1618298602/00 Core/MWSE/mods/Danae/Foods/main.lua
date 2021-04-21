local ashfall = include("mer.ashfall.interop")
if ashfall then
    ashfall.registerActivators{
		nom_ac_pool = "well",
		nom_ashland_pool = "well",
		nomni_ex_hlaalu_well = "well",
		nom_source_zainab = "well",
		nom_water_round = "well",
		nom_strong03_pool = "well",
		nom_source_ac = "well",
		nom_pump_dwemer = "water",
		nom_pump_dunmer = "well",
    }

    ashfall.registerWaterContainers{
        nom_pot_red = "bottle",
        nom_pot_silver = "bottle",
        nom_waterskin_empty = "bottle",
        nom_cooking_pot = "pot",
    }

    ashfall.registerFoods{
        ab01ingred_alga03 = "vegetable",
        ab01ingred_bird_meat = "meat",
        ab01ingred_egg02 = "meat",
        ab01ingred_turtlemeat = "meat",
        ingred_bear_meat_sa = "meat",
        ingred_dragon_meat_mwa = "meat",
        ingred_mouse_meat_mva = "meat",
        ingred_wolf_meat_sa  = "meat",
        nom_food_a_apple = "food",
        nom_food_a_grapes = "food",
        nom_food_a_lemon = "food",
        nom_food_a_orange = "food",
        nom_food_a_pear = "food",
        nom_food_a_tomato = "vegetable",
        nom_food_ash_yam = "food",
        nom_food_ash_yam_fr = "food",
        nom_food_bittergreen = "food",
        nom_food_bittersweet = "food",
        nom_food_boiled_rice = "food",
        nom_food_boiled_rice2 = "food",
        nom_food_bread_ash = "food",
        nom_food_cabbage = "food",
        nom_food_cheese = "food",
        nom_food_cheese2 = "food",
        nom_food_cheese3 = "food",
        nom_food_cheese4 = "food",
        nom_food_cheese5 = "food",
        nom_food_cheese_pie = "food",
        nom_food_chickenleg1 = "meat",
        nom_food_chickenleg1_breaded = "food",
        nom_food_chickenleg1_cook = "food",
        nom_food_coconut = "food",
        nom_food_corkbulb_roast = "food",
        nom_food_corn = "food",
        nom_food_corn_boil = "food",
        nom_food_corn_roast = "food",
        nom_food_crab_slice = "food",
        nom_food_egg2 = "meat",
        nom_food_egg_boil = "food",
        nom_food_fish = "meat",
        nom_food_fish_fat_01 = "meat",
        nom_food_fish_fat_02 = "meat",
        nom_food_fried_fish = "food",
        nom_food_fruit_salad = "food",
        nom_food_grilled_fish = "food",
        nom_food_guar_rib = "meat",
        nom_food_guar_rib_grill = "food",
        nom_food_guar_rib_succ = "food",
        ["nom_food_hackle-lo"] = "food",
        nom_food_ham = "food",
        nom_food_jerky_guar = "food",
        nom_food_lard = "food",
        nom_food_lemon_fish = "food",
        nom_food_marshmerrow = "food",
        nom_food_meat = "meat",
        nom_food_meat_grilled = "food",
        nom_food_meat_grilled2 = "food",
        nom_food_moon_pudding = "food",
        nom_food_omelette = "food",
        nom_food_omelette_crab = "food",
        nom_food_pie_appl = "food",
        nom_food_pie_comb = "food",
        nom_food_pie_lemon = "food",
        nom_food_pie_oran = "food",
        nom_food_pie_pear = "food",
        nom_food_pie_shep = "food",
        nom_food_racer_morsel = "meat",
        nom_food_rat_pie = "food",
        nom_food_rice_delight = "food",
        nom_food_roasted_fish = "food",
        nom_food_roasted_meat = "food",
        nom_food_salted_fish = "food",
        nom_food_sausage_guar = "food",
        nom_food_sausage_mix = "food",
        nom_food_sausage_sentinel = "food",
        nom_food_skewer_kag = "food",
        nom_food_soup_onion = "food",
        nom_food_soup_rat = "food",
        nom_food_soup_seaweed = "food",
        nom_food_soup_turtle = "food",
        nom_food_sweetroll = "food",
        nom_food_torall = "food",
        nom_salt = "seasoning",
        nom_sltw_food_a_banana = "food",
        nom_sltw_food_a_onion = "food",
        nom_sltw_food_a_watermellon = "food",
        nom_sltw_food_bread_corn = "food",
        nom_sltw_food_cookiebig = "food",
        nom_sltw_food_cookiesmall = "food",
        nom_sugar = "seasoning",
        nom_yeast = "seasoning",
        plx_ingred_kriin_flesh = "meat",
        tr_ingred_bluefoot = "vegetable",
        tr_ingred_bread_01 = "food",
        tr_ingred_bread_01b = "food",
        tr_ingred_bread_02 = "food",
        tr_ingred_bread_03 = "food",
        tr_ingred_cookie_01 = "food",
        tr_ingred_cookie_02 = "food",
        tr_ingred_darkmeat = "meat",
        tr_ingred_dryfish01 = "food",
        tr_ingred_dryfish02 = "food",
        tr_ingred_egg_molecrab = "meat",
        tr_ingred_meat_alit = "meat",
        tr_ingred_meat_boar = "meat",
        tr_ingred_meat_cliffracer = "meat",
        tr_ingred_meat_durzog = "meat",
        tr_ingred_meat_guar = "meat",
        tr_ingred_meat_kagouti = "meat",
        tr_ingred_meat_kwama = "meat",
        tr_ingred_meat_mutton = "meat",
        tr_ingred_meat_nix = "meat",
        tr_ingred_meat_rat = "meat",
        tr_ingred_ornada_egg = "meat",
        tr_ingred_ornada_meat = "meat",
        tr_ingred_parastylus_meat = "meat",
        tr_ingred_scrib_pie = "food",

    }

    ashfall.registerHeatSources{
		  nom_furn_light_logpile10 = 20,
    }
end

local config = require("danae.Foods.config")
local modName = config.modName
local mcmConfig = mwse.loadConfig(modName, config.mcmDefaultValues)
local data

local function debug(message, ...)
    if mcmConfig.debug then
        local output = string.format("[%s] %s", modName, tostring(message):format(...) )
        mwse.log(output)
    end
end

--Container replacement-----------------------

local function rollForReplacement()
    local rand = math.random(100)
    return rand < mcmConfig.replacementChance
end


local function getUniqueCellId(cell)
    if cell.isInterior then
        return cell.id:lower()
    else
        return string.format("%s (%s,%s)",
        cell.id:lower(), 
        cell.gridX, 
        cell.gridY)
    end
end

local function makeReplacement(ref, newItem)
    if not tes3.getObject(newItem) then
        debug("%s does not exist. ESP not loaded?", newItem)
        return
    end
    debug("replacing %s with %s", ref.object.id, newItem)
    local newRef = tes3.createReference {
        object = newItem,
        position = ref.position:copy(),
        orientation = ref.orientation:copy(),
        cell = ref.cell
    }
    newRef.scale = ref.scale
    debug(newRef.scale)
    timer.delayOneFrame(function()
        ref:disable()
        mwscript.setDelete{ reference = ref}
    end)
end

local function processCell(e)
    if not mcmConfig.enabled then return end
    if not data then return end
    local cellId = getUniqueCellId(e.cell)
    --have we added food to this cell already?
    if not data.processedCells[cellId] then
        debug("Adding replacements to %s", cellId)
        data.processedCells[cellId] = true

        ---Look for food to replace
        for ref in e.cell:iterateReferences(tes3.objectType.ingredientItem) do
            local newItem = config.replacements[ref.object.id:lower()]
            if newItem and rollForReplacement() then
                makeReplacement(ref, newItem)
            end
        end
    end
end
event.register("cellChanged", processCell)

--Initialisation
local function initData()
    debug("Init data")
    tes3.player.data.foodsOfTamriel = tes3.player.data.foodsOfTamriel or {}
    data = tes3.player.data.foodsOfTamriel
    data.processedCells = data.processedCells or {}
end
event.register("loaded", initData)

--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(modName, mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = "Enable Random Food Replacements",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = mcmConfig}
    }
    settings:createSlider{
        label = "Replacement Chance",
        description = "The % chance that a food item will be replaced with another.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "replacementChance", table = mcmConfig}
    }
    settings:createOnOffButton{
        label = "Debug Mode",
        description = "Prints debug messages to mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)
