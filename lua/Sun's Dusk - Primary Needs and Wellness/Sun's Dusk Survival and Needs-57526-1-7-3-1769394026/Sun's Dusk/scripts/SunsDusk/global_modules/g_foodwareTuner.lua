do return end

local cookingRecipeDB = require("scripts.SunsDusk.lib.cooking_recipes").recipes

local mode = 1
local TEST_FOOD_RECIPE = "sd_food_g"

local offsetTracker = {}
local foodToFoodware = {}
local scaleStep = 0.02
local teleportStep = 0.3

local function printOffset(foodObj)
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then
        print("ERROR: Food object not found")
        return
    end
    
    local data = offsetTracker[foodwareId]
    
    print(string.format("Foodware: %s", foodwareId))
    print(string.format("  Base Food Offset: (%.2f, %.2f, %.2f)", data.baseFoodOffset.x, data.baseFoodOffset.y, data.baseFoodOffset.z))
    print(string.format("  Base Food Scale: %.2f", data.baseFoodScale))
    print(string.format("  Foodware Adjustment: (%.2f, %.2f, %.2f)", data.x, data.y, data.z))
    print(string.format("  Foodware Scale Multiplier: %.2f", data.scale))
    print(string.format("  Final Offset: (%.2f, %.2f, %.2f)", 
        data.baseFoodOffset.x + data.x, 
        data.baseFoodOffset.y + data.y, 
        data.baseFoodOffset.z + data.z))
    print(string.format("  Final Scale: %.2f", data.baseFoodScale * data.scale))
end

function scaleUp(foodObj, amount)
    amount = amount or scaleStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local currentScale = foodObj.scale or 1.0
    local newScale = currentScale + amount
    foodObj:setScale(newScale)
    
    data.scale = newScale / data.baseFoodScale
    
    print(string.format("Scaled up to %.2f (+%.2f)", newScale, amount))
    printOffset(foodObj)
end

function scaleDown(foodObj, amount)
    amount = amount or scaleStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local currentScale = foodObj.scale or 1.0
    local newScale = math.max(0.1, currentScale - amount)
    foodObj:setScale(newScale)
    
    data.scale = newScale / data.baseFoodScale
    
    print(string.format("Scaled down to %.2f (-%.2f)", newScale, amount))
    printOffset(foodObj)
end

function moveUp(foodObj, amount)
    amount = amount or teleportStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local pos = foodObj.position
    local newPos = util.vector3(pos.x, pos.y, pos.z + amount)
    foodObj:teleport(foodObj.cell, newPos)
    data.z = data.z + amount
    
    print(string.format("Moved up by %.2f", amount))
    printOffset(foodObj)
end

function moveDown(foodObj, amount)
    amount = amount or teleportStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local pos = foodObj.position
    local newPos = util.vector3(pos.x, pos.y, pos.z - amount)
    foodObj:teleport(foodObj.cell, newPos)
    data.z = data.z - amount
    
    print(string.format("Moved down by %.2f", amount))
    printOffset(foodObj)
end

function moveRight(foodObj, amount)
    amount = amount or teleportStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local pos = foodObj.position
    local newPos = util.vector3(pos.x + amount, pos.y, pos.z)
    foodObj:teleport(foodObj.cell, newPos)
    data.x = data.x + amount
    
    print(string.format("Moved right by %.2f", amount))
    printOffset(foodObj)
end

function moveLeft(foodObj, amount)
    amount = amount or teleportStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local pos = foodObj.position
    local newPos = util.vector3(pos.x - amount, pos.y, pos.z)
    foodObj:teleport(foodObj.cell, newPos)
    data.x = data.x - amount
    
    print(string.format("Moved left by %.2f", amount))
    printOffset(foodObj)
end

function moveForward(foodObj, amount)
    amount = amount or teleportStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local pos = foodObj.position
    local newPos = util.vector3(pos.x, pos.y + amount, pos.z)
    foodObj:teleport(foodObj.cell, newPos)
    data.y = data.y + amount
    
    print(string.format("Moved forward by %.2f", amount))
    printOffset(foodObj)
end

function moveBack(foodObj, amount)
    amount = amount or teleportStep
    local foodwareId = foodToFoodware[foodObj.id]
    if not foodwareId then return end
    
    local data = offsetTracker[foodwareId]
    local pos = foodObj.position
    local newPos = util.vector3(pos.x, pos.y - amount, pos.z)
    foodObj:teleport(foodObj.cell, newPos)
    data.y = data.y - amount
    
    print(string.format("Moved back by %.2f", amount))
    printOffset(foodObj)
end

function printAllOffsets()
    local tableName = mode == 2 and (cookingRecipeDB[TEST_FOOD_RECIPE] and cookingRecipeDB[TEST_FOOD_RECIPE].isSoup and "soupFoodwareOffsets" or "foodwareOffsets") or "foodwareOffsets"
    print("=== All Foodware Adjustments (Lua Table) ===")
    print("-- These are ADJUSTMENTS to base food positions, not absolute positions")
    print("-- Usage: finalOffset = baseFoodOffset + foodwareAdjustment")
    print("--        finalScale = baseFoodScale * foodwareScaleMultiplier")
    if mode == 2 then
        print("-- Recipe type: " .. (cookingRecipeDB[TEST_FOOD_RECIPE] and cookingRecipeDB[TEST_FOOD_RECIPE].isSoup and "SOUP" or "NORMAL"))
    end
    print("")
    print(tableName .. " = {")
    local count = 0
    
    local allFoodwareIds = {}
    for foodwareId, _ in pairs(offsetTracker) do
        allFoodwareIds[foodwareId] = true
    end
    
    local activeTable = mode == 2 and (cookingRecipeDB[TEST_FOOD_RECIPE] and cookingRecipeDB[TEST_FOOD_RECIPE].isSoup and soupFoodwareOffsets or foodwareOffsets) or foodwareOffsets
    for foodwareId, _ in pairs(activeTable) do
        allFoodwareIds[foodwareId] = true
    end
    
    for foodwareId, _ in pairs(allFoodwareIds) do
        local data = offsetTracker[foodwareId]
        if data then
            count = count + 1
            print(string.format('    ["%s"] = {', foodwareId))
            print(string.format('        offset = util.vector3(%.2f, %.2f, %.2f),', data.x, data.y, data.z))
            print(string.format('        scale = %.2f', data.scale))
            print("    },")
        else
            local preset = activeTable[foodwareId]
            if preset then
                count = count + 1
                print(string.format('    ["%s"] = {', foodwareId))
                print(string.format('        offset = util.vector3(%.2f, %.2f, %.2f),', preset.offset.x, preset.offset.y, preset.offset.z))
                print(string.format('        scale = %.2f', preset.scale))
                print("    },")
            end
        end
    end
    
    print("}")
    print(string.format("-- Total: %d foodware item(s) with adjustments", count))
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

local function collectAllFoodware()
    local foodware = {}
    for _, rec in ipairs(types.Miscellaneous.records) do
        local foodwareType = getFoodwareType(rec.id)
        if foodwareType then
            table.insert(foodware, {
                id = rec.id,
                name = rec.name,
                type = foodwareType
            })
        end
    end
    return foodware
end

local foodwareList = collectAllFoodware()
local NUM_ROWS = 15
local SPACING_X = 35
local SPACING_Z = 35
local OFFSET_Y = 0

if mode == "randomized" or mode == 1 then
    
    local recipeCount
    local function randomRecipe()
        if not recipeCount then
            recipeCount = 0
            for _ in pairs(foodOffsets) do
                recipeCount = recipeCount + 1
            end
        end
        local randomIndex = math.random(1, recipeCount)
        local i = 1
        for id in pairs(foodOffsets) do
            if i == randomIndex then
                return id
            end
            i = i + 1
        end
        return next(foodOffsets)
    end
    
    print(string.format("Found %d pieces of foodware", #foodwareList))
    
    local function spawnFoodwareGrid(actor)
        local actorPos = actor.position
        local actorRot = actor.rotation
        
        local forward = actorRot * util.vector3(0, 1, 0)
        local right = actorRot * util.vector3(1, 0, 0)
        
        local itemsPerRow = math.ceil(#foodwareList / NUM_ROWS)
        local currentIndex = 1
        
        for row = 0, NUM_ROWS - 1 do
            local itemsInThisRow = math.min(itemsPerRow, #foodwareList - currentIndex + 1)
            local rowStartOffset = -(itemsInThisRow - 1) * SPACING_X / 2
            
            for col = 0, itemsInThisRow - 1 do
                if currentIndex > #foodwareList then break end
                
                local foodware = foodwareList[currentIndex]
                local localX = rowStartOffset + (col * SPACING_X)
                local localZ = (row * SPACING_Z) + 100
                local spawnPos = actorPos + (forward * localZ) + (right * localX) + util.vector3(0, 0, OFFSET_Y)
                
                local foodwareObj = world.createObject(foodware.id)
                foodwareObj:teleport(actor.cell, spawnPos, {onGround = false})
                
                local recipeId = randomRecipe()
                local recipeData = cookingRecipeDB[recipeId]
                local isSoup = recipeData and recipeData.isSoup or false
                
                local baseFoodData = foodOffsets[recipeId]
                local baseFoodOffset = baseFoodData and baseFoodData.offset or util.vector3(0, 0, 0)
                local baseFoodScale = baseFoodData and baseFoodData.scale or 1.0
                
                local foodwareOffsetsTable = isSoup and soupFoodwareOffsets or foodwareOffsets
                local foodwareAdjust = foodwareOffsetsTable[foodware.id]
                local foodwareOffset = foodwareAdjust and foodwareAdjust.offset or util.vector3(0, 0, 0)
                local foodwareScale = foodwareAdjust and foodwareAdjust.scale or 1.0
                
                local finalOffset = baseFoodOffset * foodwareScale + foodwareOffset
                local finalScale = baseFoodScale * foodwareScale
                
                local foodObj = world.createObject(recipeId)
                foodObj:teleport(actor.cell, spawnPos + finalOffset, {onGround = false})
                foodObj:setScale(finalScale)
                
                if math.random() < 0.1 then
                    local steamObj = world.createObject("sd_food_steam")
                    steamObj:teleport(actor.cell, spawnPos + finalOffset, {onGround = false})
                    steamObj:setScale(finalScale)
                end
                
                foodToFoodware[foodObj.id] = foodware.id
                
                offsetTracker[foodware.id] = {
                    x = foodwareOffset.x,
                    y = foodwareOffset.y,
                    z = foodwareOffset.z,
                    scale = foodwareScale,
                    baseFoodOffset = baseFoodOffset,
                    baseFoodScale = baseFoodScale
                }
                
                currentIndex = currentIndex + 1
            end
        end
        
        return (#foodwareList) .. " foodware items spawned in " .. NUM_ROWS .. " rows"
    end
    
    I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
        spawnFoodwareGrid(actor)
    end)

elseif mode == "fixed" or mode == 2 then
    
    local recipeData = cookingRecipeDB[TEST_FOOD_RECIPE]
    local testRecipeIsSoup = recipeData and recipeData.isSoup or false
    local activeFoodwareOffsets = testRecipeIsSoup and soupFoodwareOffsets or foodwareOffsets
    
    print(string.format("Testing recipe: %s (%s)", TEST_FOOD_RECIPE, testRecipeIsSoup and "SOUP" or "NORMAL"))
    print(string.format("Found %d pieces of foodware", #foodwareList))
    
    local baseFoodData = foodOffsets[TEST_FOOD_RECIPE]
    local baseFoodOffset = baseFoodData and baseFoodData.offset or util.vector3(0, 0, 0)
    local baseFoodScale = baseFoodData and baseFoodData.scale or 1.0
    
    local function spawnFoodwareGrid(actor)
        local actorPos = actor.position
        local actorRot = actor.rotation
        
        local forward = actorRot * util.vector3(0, 1, 0)
        local right = actorRot * util.vector3(1, 0, 0)
        
        local itemsPerRow = math.ceil(#foodwareList / NUM_ROWS)
        local currentIndex = 1
        
        for row = 0, NUM_ROWS - 1 do
            local itemsInThisRow = math.min(itemsPerRow, #foodwareList - currentIndex + 1)
            local rowStartOffset = -(itemsInThisRow - 1) * SPACING_X / 2
            
            for col = 0, itemsInThisRow - 1 do
                if currentIndex > #foodwareList then break end
                
                local foodware = foodwareList[currentIndex]
                local localX = rowStartOffset + (col * SPACING_X)
                local localZ = (row * SPACING_Z) + 100
                local spawnPos = actorPos + (forward * localZ) + (right * localX) + util.vector3(0, 0, OFFSET_Y)
                
                local foodwareObj = world.createObject(foodware.id)
                foodwareObj:teleport(actor.cell, spawnPos, {onGround = false})
                
                local foodwareAdjust = activeFoodwareOffsets[foodware.id]
                local foodwareOffset = foodwareAdjust and foodwareAdjust.offset or util.vector3(0, 0, 0)
                local foodwareScale = foodwareAdjust and foodwareAdjust.scale or 1.0
                
                local finalOffset = baseFoodOffset * foodwareScale + foodwareOffset
                local finalScale = baseFoodScale * foodwareScale
                
                local foodObj = world.createObject(TEST_FOOD_RECIPE)
                foodObj:teleport(actor.cell, spawnPos + finalOffset, {onGround = false})
                foodObj:setScale(finalScale)
                
                if math.random() < 0.1 then
                    local steamObj = world.createObject("sd_food_steam")
                    steamObj:teleport(actor.cell, spawnPos + finalOffset, {onGround = false})
                    steamObj:setScale(finalScale)
                end
                
                foodToFoodware[foodObj.id] = foodware.id
                
                offsetTracker[foodware.id] = {
                    x = foodwareOffset.x,
                    y = foodwareOffset.y,
                    z = foodwareOffset.z,
                    scale = foodwareScale,
                    baseFoodOffset = baseFoodOffset,
                    baseFoodScale = baseFoodScale
                }
                
                currentIndex = currentIndex + 1
            end
        end
        
        return (#foodwareList) .. " foodware items spawned in " .. NUM_ROWS .. " rows"
    end
    
    I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
        spawnFoodwareGrid(actor)
    end)

end