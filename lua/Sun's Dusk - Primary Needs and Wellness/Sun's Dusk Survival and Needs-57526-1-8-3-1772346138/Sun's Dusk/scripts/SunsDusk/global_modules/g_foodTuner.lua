do return end
-- Food Tuner - Adjust individual food positioning and scaling
-- This tunes FOOD offsets (absolute), not foodware adjustments

local cookingRecipeDB = require("scripts.SunsDusk.lib.cooking_recipes").recipes

local recordIDs = {
"sd_food_m_salt",
"sd_food_g",
"sd_food_fruit",
"sd_food_e",
"sd_food_aff_sr",
"sd_food_aff_hs",
"sd_food_meat",
"sd_food_m_fruit",
"sd_food_f_greens_salt",
"sd_food_m",
"sd_food_f",
"sd_food_m_greens_salt",
"sd_food_meat_fish",
"sd_food_aff_rs",
"sd_food_aff_ar",
"sd_food_meat_salt",
"sd_food_m_g",
"sd_food_aff_ms",
"sd_food_m_fish",
"sd_food_aff_yc",
"sd_food_aff_cms",
"sd_food_aff_har",
"sd_food_e_greens_salt",
"sd_food_aff_ssss",
"sd_food_aff_cr",
"sd_food_f_crab_spice",
"sd_food_meat_salt_greens",
"sd_food_fruit_greens_herb",
"sd_food_aff_ss",
"sd_food_aff_sicksoup",
"sd_food_aff_ps",
"sd_food_aff_my",
"sd_food_aff_m",
"sd_food_aff_ks",
"sd_food_meat_greens_herb",
"sd_food_aff_gdm",
"sd_food_aff_cs",
"sd_food_aff_sfst",
"sd_food_m_spice",
"sd_food_meat_spice",
"sd_food_aff_hls",
"sd_food_m_meat",
"sd_food_f_salt",
"sd_food_f_greens_herb",
"sd_food_g_spice",
"sd_food_g_salt",
"sd_food_e_meat",
"sd_food_def_meat",
"sd_food_def_meatsoup",
"sd_food_def_vegan",
"sd_food_def_mixed",
}

recordIDs2 = {
"o_food_ash_zombie",
"o_ingred_ash_yam_slcd",
"o_ingred_cactislice",
"o_ingred_guar_jerky",
"o_ingred_guar_ribs_raw",
"o_ingred_guar_ribs_roasted",
"o_ingred_hamumslice_a",
"o_ingred_hamumslice_b",
"o_ingred_roasted_scrib",
"o_ingred_roll_egg",
"o_ingred_roll_meat",
"o_ingred_roll_mushrm",
"o_ingred_roll_rice",
"o_ingred_slaughtfish_roast",
"o_6th_bloodberry",
"o_6th_corprust_feast",
"o_6th_jam_sandwich",
"o_6th_ribs",
"o_6th_steak",
"o_barnacle_soup",
"o_barnacle_soup_poor",
"o_bgsoup_a",
"o_bgsoup_b",
"o_bogfly_bowl",
"o_boilegg",
"o_bowl_beans",
"o_bowl_meat_sml",
"o_bowl_soup2_sml",
"o_bowl_soup_sml",
"o_cacti_redware",
"o_cacti_stone",
"o_cacti_wood",
"o_cp_broth",
"o_cp_juc_cberry",
"o_crabcake_metal",
"o_crabcake_redware",
"o_crabcake_wood",
"o_cup_rice",
"o_drumpear_paste_wd",
"o_drumstick_big",
"o_drumstick_bucket",
"o_drumstick_small",
"o_feast_kwama_roast",
"o_fish_stew_bittergreen",
"o_fishsoup_sml",
"o_flatbread",
"o_flatbread_ash",
"o_friedegg",
"o_guar_ribs_beans",
"o_imp_cheese_cake_tart",
"o_imp_cheese_comberry",
"o_imp_cheese_fish_yam",
"o_imp_cheesebun",
"o_imp_croquettes_cheese",
"o_imp_fruitplate_a",
"o_imp_wheatbun",
"o_indoril_feast_nectar",
"o_indoril_nectarbowl",
"o_indoril_roastslicenectar_g",
"o_juice_comberry",
"o_kwama_bun",
"o_kwamaeggyolk",
"o_lamprey_bowl",
"o_marrow_stew",
"o_meadowrye_cream",
"o_meat_roast",
"o_ml_2xsandw",
"o_ml_3roll",
"o_ml_alitmeategg_metal",
"o_ml_alittanna",
"o_ml_alittannarice",
"o_ml_ash_roast",
"o_ml_ash_yam_stew",
"o_ml_b_anther_meat",
"o_ml_beanrice",
"o_ml_bowl_cabbage",
"o_ml_bowl_comberries_redware",
"o_ml_bowl_comberries_wood",
"o_ml_cactialit",
"o_ml_cactijerky",
"o_ml_clamsoup_metal",
"o_ml_clamstew",
"o_ml_comberry_fish",
"o_ml_corkbulbsoup_redware",
"o_ml_crab_stew",
"o_ml_crabstew_mt",
"o_ml_dry_stoneflower",
"o_ml_egg_bread",
"o_ml_egg_guar_jerky",
"o_ml_egg_kresh",
"o_ml_fish_ash_yam_bittergreen",
"o_ml_fish_ashyam",
"o_ml_fish_bittergreen_soup_b",
"o_ml_fish_rice",
"o_ml_flatbread_metal",
"o_ml_flatbread_redware",
"o_ml_guar_ribs_ash_yam",
"o_ml_guar_ribs_bread",
"o_ml_gulash",
"o_ml_hammcut_bowl",
"o_ml_hammpaste_big",
"o_ml_hammpaste_small",
"o_ml_hammsoup_big",
"o_ml_hammsoup_small",
"o_ml_hamumrice_metal",
"o_ml_hamumrice_redware",
"o_ml_herbs",
"o_ml_honeyporridge_stone",
"o_ml_honeyporridge_wood",
"o_ml_kogoutirice_r",
"o_ml_kogoutlichen_mt",
"o_ml_kogoutstew_bowl",
"o_ml_kuj_wood",
"o_ml_kujguarjerky_metal",
"o_ml_kwama_bun",
"o_ml_kwama_meat_roast",
"o_ml_meatash",
"o_ml_meatpaste_metal",
"o_ml_meatpaste_redware",
"o_ml_meatpaste_wood",
"o_ml_meatrice",
"o_ml_meatrice_mt",
"o_ml_mmash_wood",
"o_ml_mmashashyam_metal",
"o_ml_mmashashyam_redware",
"o_ml_mtl_egg",
"o_ml_orandaegg_omlette_wood",
"o_ml_orandaegg_teaegg",
"o_ml_roasted_scrib",
"o_ml_scuttlesoup",
"o_ml_sndwich_rolls",
"o_ml_soupcacti",
"o_ml_soupshroom",
"o_ml_templedome_stuffed",
"o_ml_vermilionrice_metal",
"o_ml_yamscut",
"o_muschroom_soup",
"o_mushroom_rat_stew",
"o_netch_jelly",
"o_netch_jelly_bowl",
"o_nord_sausage",
"o_nord_sausagebread_a",
"o_nord_sausagebread_b",
"o_nord_sausageegg",
"o_pie_comberry_metal",
"o_pie_comberry_redware",
"o_ribs_spicy",
"o_rice_porridge",
"o_sandwich_cheese",
"o_sandwich_egg_dbl",
"o_sandwich_eggslice",
"o_sandwich_meat",
"o_sandwich_meat_dbl",
"o_spice_rice",
"o_tanna_cubes_indoril",
"o_tanna_cubes_metal",
"o_tanna_cubes_redware",
"o_tanna_gel_wd",
"o_tanna_paste_stone_small",
"o_tanna_paste_wd_big",
"o_tanna_porridge_wdlight",
"o_tea_bittergreen",
"o_tea_bittergreen_p",
"o_tea_bittergreen_s",
"o_tea_firefern",
"o_tea_goldenkanet",
"o_tea_goldkanet_s",
"o_tea_kanet_milk",
"o_tea_kresh",
"o_tea_kresh_peach",
"o_tea_scathecraw_y",
"o_tea_swamp",
"o_tlv_baked_truffles",
"o_tlv_insect_soup",
"o_tlv_insect_soup_small",
"o_tlv_lumi_soup",
"o_tlv_spore_ribs",
"o_tp_bonemeal_stew",
"o_tp_ml_coda_roast",
"o_wd_soup",
"o_wd_soup2",
"o_wickwheat_gruel_stone",
"o_wickwheat_gruel_wood",
"o_yammeat",
}

local usingFoodware = ("Misc_Imp_Silverware_bowl"):lower()

local NUM_ROWS = 15
local SPACING_X = 25
local SPACING_Z = 25
local OFFSET_Y = 0

-- Track which foodware each food object is using
local foodToFoodware = {}

local function spawnRecordsInGrid(actor)
    local actorPos = actor.position
    local actorRot = actor.rotation
    
    local forward = actorRot * util.vector3(0, 1, 0)
    local right = actorRot * util.vector3(1, 0, 0)
    
    local itemsPerRow = math.ceil(#recordIDs / NUM_ROWS)
    local currentIndex = 1
    
    for row = 0, NUM_ROWS - 1 do
        local itemsInThisRow = math.min(itemsPerRow, #recordIDs - currentIndex + 1)
        local rowStartOffset = -(itemsInThisRow - 1) * SPACING_X / 2
        
        for col = 0, itemsInThisRow - 1 do
            if currentIndex > #recordIDs then break end
            
            local recordID = recordIDs[currentIndex]
            local localX = rowStartOffset + (col * SPACING_X)
            local localZ = (row * SPACING_Z) + 100
            local spawnPos = actorPos + (forward * localZ) + (right * localX) + util.vector3(0, 0, OFFSET_Y)
            
            -- Spawn the foodware
            local foodwareObj = world.createObject(usingFoodware)
            foodwareObj:teleport(actor.cell, spawnPos, {onGround = false})
            
            -- Get recipe data to determine if it's soup
            local recipeData = cookingRecipeDB[recordID]
            local isSoup = recipeData and recipeData.isSoup or false
            
            -- Get base food offset/scale from foodOffsets
            local baseFoodData = foodOffsets[recordID]
            local baseFoodOffset = baseFoodData and baseFoodData.offset or util.vector3(0, 0, 0)
            local baseFoodScale = baseFoodData and baseFoodData.scale or 1.0
            
            -- Get foodware adjustment (use soup table for soups)
            local foodwareOffsetsTable = isSoup and soupFoodwareOffsets or foodwareOffsets
            local foodwareAdjust = foodwareOffsetsTable[usingFoodware]
            local foodwareOffset = foodwareAdjust and foodwareAdjust.offset or util.vector3(0, 0, 0)
            local foodwareScale = foodwareAdjust and foodwareAdjust.scale or 1.0
            
            -- Calculate final position: apply foodware scale to base offset, then add foodware offset
            local finalOffset = baseFoodOffset * foodwareScale + foodwareOffset
            local finalScale = baseFoodScale * foodwareScale
            
            -- Spawn the food
            local foodObj = world.createObject(recordID)
            foodObj:teleport(actor.cell, spawnPos + finalOffset, {onGround = false})
            foodObj:setScale(finalScale)
            
            -- Track association for later adjustment
            foodToFoodware[foodObj.id] = {
                foodwareId = usingFoodware,
                isSoup = isSoup
            }
            
            currentIndex = currentIndex + 1
        end
    end
    
    return (#recordIDs) .. " objects spawned in " .. NUM_ROWS .. " rows"
end

I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
    spawnRecordsInGrid(actor)
end)

local offsetTracker = {}
local scaleStep = 0.01
local teleportStep = 0.1

-- Initialize offset tracking for a food object
-- This tracks ABSOLUTE food position (what goes in foodOffsets table)
local function initOffset(obj)
    local id = obj.recordId
    if not offsetTracker[id] then
        local preset = foodOffsets[id]
        if preset then
            offsetTracker[id] = {
                x = preset.offset.x,
                y = preset.offset.y,
                z = preset.offset.z,
                scale = preset.scale
            }
        else
            offsetTracker[id] = {
                x = 0,
                y = 0,
                z = 0,
                scale = 1.0
            }
        end
    end
    return offsetTracker[id]
end

local function printOffset(obj)
    local id = obj.recordId
    local offset = offsetTracker[id]
    if offset then
        print(string.format("Food: %s", id))
        print(string.format("  Base Position Offset: (%.2f, %.2f, %.2f)", offset.x, offset.y, offset.z))
        print(string.format("  Base Scale: %.2f", offset.scale))
        
        -- Show how this looks on current foodware
        local foodData = foodToFoodware[obj.id]
        if foodData then
            local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
            local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
            if foodwareAdjust then
                local finalOffset = util.vector3(offset.x, offset.y, offset.z) * foodwareAdjust.scale + foodwareAdjust.offset
                local finalScale = offset.scale * foodwareAdjust.scale
                print(string.format("  On %s: offset (%.2f, %.2f, %.2f), scale %.2f", 
                    foodData.foodwareId, finalOffset.x, finalOffset.y, finalOffset.z, finalScale))
            end
        end
    else
        print("Object has no tracked offsets yet")
    end
end

-- Scale functions track absolute scale changes
function scaleUp(obj, amount)
    amount = amount or scaleStep
    local offset = initOffset(obj)
    
    -- Get foodware adjustment to calculate base scale from current scale
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    local currentScale = obj.scale or 1.0
    local newScale = currentScale + amount
    obj:setScale(newScale)
    
    -- Update base scale (what goes in foodOffsets)
    offset.scale = newScale / foodwareScale
    
    print(string.format("Scaled up to %.2f (+%.2f)", newScale, amount))
    printOffset(obj)
end

function scaleDown(obj, amount)
    amount = amount or scaleStep
    local offset = initOffset(obj)
    
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    local currentScale = obj.scale or 1.0
    local newScale = math.max(0.1, currentScale - amount)
    obj:setScale(newScale)
    
    offset.scale = newScale / foodwareScale
    
    print(string.format("Scaled down to %.2f (-%.2f)", newScale, amount))
    printOffset(obj)
end

-- Movement functions track absolute offset changes
function moveUp(obj, amount)
    amount = amount or teleportStep
    local offset = initOffset(obj)
    
    local pos = obj.position
    local newPos = util.vector3(pos.x, pos.y, pos.z + amount)
    obj:teleport(obj.cell, newPos)
    
    -- Calculate base offset change (accounting for foodware scale)
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    offset.z = offset.z + (amount / foodwareScale)
    
    print(string.format("Moved up by %.2f", amount))
    printOffset(obj)
end

function moveDown(obj, amount)
    amount = amount or teleportStep
    local offset = initOffset(obj)
    
    local pos = obj.position
    local newPos = util.vector3(pos.x, pos.y, pos.z - amount)
    obj:teleport(obj.cell, newPos)
    
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    offset.z = offset.z - (amount / foodwareScale)
    
    print(string.format("Moved down by %.2f", amount))
    printOffset(obj)
end

function moveRight(obj, amount)
    amount = amount or teleportStep
    local offset = initOffset(obj)
    
    local pos = obj.position
    local newPos = util.vector3(pos.x + amount, pos.y, pos.z)
    obj:teleport(obj.cell, newPos)
    
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    offset.x = offset.x + (amount / foodwareScale)
    
    print(string.format("Moved right by %.2f", amount))
    printOffset(obj)
end

function moveLeft(obj, amount)
    amount = amount or teleportStep
    local offset = initOffset(obj)
    
    local pos = obj.position
    local newPos = util.vector3(pos.x - amount, pos.y, pos.z)
    obj:teleport(obj.cell, newPos)
    
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    offset.x = offset.x - (amount / foodwareScale)
    
    print(string.format("Moved left by %.2f", amount))
    printOffset(obj)
end

function moveForward(obj, amount)
    amount = amount or teleportStep
    local offset = initOffset(obj)
    
    local pos = obj.position
    local newPos = util.vector3(pos.x, pos.y + amount, pos.z)
    obj:teleport(obj.cell, newPos)
    
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    offset.y = offset.y + (amount / foodwareScale)
    
    print(string.format("Moved forward by %.2f", amount))
    printOffset(obj)
end

function moveBack(obj, amount)
    amount = amount or teleportStep
    local offset = initOffset(obj)
    
    local pos = obj.position
    local newPos = util.vector3(pos.x, pos.y - amount, pos.z)
    obj:teleport(obj.cell, newPos)
    
    local foodData = foodToFoodware[obj.id]
    local foodwareScale = 1.0
    if foodData then
        local foodwareOffsetsTable = foodData.isSoup and soupFoodwareOffsets or foodwareOffsets
        local foodwareAdjust = foodwareOffsetsTable[foodData.foodwareId]
        if foodwareAdjust then
            foodwareScale = foodwareAdjust.scale
        end
    end
    
    offset.y = offset.y - (amount / foodwareScale)
    
    print(string.format("Moved back by %.2f", amount))
    printOffset(obj)
end

function printAllOffsets()
    print("=== All Food Offsets (Lua Table) ===")
    print("-- These are ABSOLUTE food positions for foodOffsets table")
    print("-- Usage: these values go directly into the foodOffsets table")
    print("")
    print("foodOffsets = {")
    local count = 0
    
    for id, preset in pairs(foodOffsets) do
        count = count + 1
        local offset = offsetTracker[id] or {
            x = preset.offset.x,
            y = preset.offset.y,
            z = preset.offset.z,
            scale = preset.scale
        }
        print(string.format('    ["%s"] = {', id))
        print(string.format('        offset = util.vector3(%.2f, %.2f, %.2f),', offset.x, offset.y, offset.z))
        print(string.format('        scale = %.2f', offset.scale))
        print("    },")
    end
    
    for id, offset in pairs(offsetTracker) do
        if not foodOffsets[id] then
            count = count + 1
            print(string.format('    ["%s"] = {', id))
            print(string.format('        offset = util.vector3(%.2f, %.2f, %.2f),', offset.x, offset.y, offset.z))
            print(string.format('        scale = %.2f', offset.scale))
            print("    },")
        end
    end
    
    print("}")
    print(string.format("-- Total: %d food(s)", count))
end

G_eventHandlers.scaleUp = scaleUp
G_eventHandlers.scaleDown = scaleDown
G_eventHandlers.moveUp = moveUp
G_eventHandlers.moveDown = moveDown
G_eventHandlers.moveLeft = moveLeft
G_eventHandlers.moveRight = moveRight
G_eventHandlers.moveForward = moveForward
G_eventHandlers.moveBack = moveBack
G_eventHandlers.printAllOffsets = printAllOffsets