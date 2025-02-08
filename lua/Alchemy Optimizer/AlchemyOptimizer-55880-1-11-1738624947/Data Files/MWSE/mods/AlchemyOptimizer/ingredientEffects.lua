-- File: ingredientEffects.lua
-- Purpose: Export ingredient effect data to a CSV file and load it back into a Lua table.
local ingredientEffects = {}
local lfs = require("lfs")

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------
-- effectsScale controls how quickly ingredient effects are revealed:
--   1.0 = Vanilla progression (1 effect at level 15, 2 at 30, 3 at 45, 4 at 60)
--   0.5 = Half as quickly (you need a higher alchemy level to reveal effects)
--   2.0 = Twice as quickly (more effects appear at lower alchemy levels)
--   0.0 = No filtering (export all effects regardless of alchemy skill)
local effectsScale = 1.0

--------------------------------------------------------------------------------
-- FUNCTION: getScriptDirAbsolute
-- Returns the full absolute directory path (ending with a forward slash)
-- of the currently executing script.
--------------------------------------------------------------------------------
local function getScriptDirAbsolute()
    local source = debug.getinfo(1, "S").source
    if source:sub(1, 1) == "@" then
        source = source:sub(2)  -- Remove the "@" character.
    end
    local dir = source:match("(.+[/\\])")
    if not dir then
        return lfs.currentdir() .. "/"
    end
    if dir:sub(1, 1) == "." then
        local cwd = lfs.currentdir()
        if cwd:sub(-1) ~= "/" then
            cwd = cwd .. "/"
        end
        dir = cwd .. dir:sub(2)
    end
    dir = dir:gsub("[/\\]+", "/")
    return dir
end

-- Export the function so that other modules can use it.
ingredientEffects.getScriptDirAbsolute = getScriptDirAbsolute

-- Define the CSV file path in the same directory as this Lua file.
local csvFilename = getScriptDirAbsolute() .. "known_ingredient_effects.csv"

--------------------------------------------------------------------------------
-- Function: exportIngredientEffects
-- Scans the player's inventory and writes a CSV file with two columns:
--   Column 1: ingredient id
--   Column 2: effect name (only the first visibleCount effects, as determined by alchemy level)
--------------------------------------------------------------------------------
function ingredientEffects.exportIngredientEffects()
    mwse.log("[ingredientEffects] exportIngredientEffects: Called. CSV path: " .. csvFilename)
    local csvData = { {"id", "effect"} }
    local player = tes3.player
    if not (player and player.object and player.object.inventory) then
        mwse.log("[ingredientEffects] ERROR: Player inventory not available.")
        return false
    end

    -- Loop over player's inventory.
    for _, stack in pairs(player.object.inventory) do
        if stack and stack.object and stack.object.objectType == tes3.objectType.ingredient then
            local ing = stack.object
            local ingId = ing.id
            if ing.effects then
                local exportCount = 0
                local visibleCount = 4  -- default: show all effects
                if effectsScale > 0 then
                    local skill = tes3.mobilePlayer.alchemy.current
                    local gmst = tes3.findGMST(tes3.gmst.fWortChanceValue)
                    visibleCount = math.floor((skill / gmst.value) * effectsScale)
                    if visibleCount < 0 then visibleCount = 0 end
                    if visibleCount > 4 then visibleCount = 4 end
                    mwse.log("[ingredientEffects] exportIngredientEffects: For ingredient " .. ingId .. ", calculated visibleCount = " .. visibleCount)
                end
                for _, effectId in ipairs(ing.effects) do
                    if type(effectId) == "number" and effectId > 0 then
                        if effectsScale > 0 and exportCount >= visibleCount then
                            mwse.log("[ingredientEffects] exportIngredientEffects: Reached visibleCount for ingredient " .. ingId)
                            break
                        end
                        local effectRecord = tes3.getMagicEffect(effectId)
                        if effectRecord then
                            local effectName = effectRecord.name
                            table.insert(csvData, { ingId, effectName })
                            mwse.log("[ingredientEffects] Exporting: " .. ingId .. " -> " .. effectName)
                            exportCount = exportCount + 1
                        else
                            mwse.log("[ingredientEffects] WARNING: No effect record for effect id: " .. tostring(effectId))
                        end
                    end
                end
            else
                mwse.log("[ingredientEffects] WARNING: Ingredient " .. ingId .. " has no effects table.")
            end
        end
    end

    local file, err = io.open(csvFilename, "w")
    if not file then
        mwse.log("[ingredientEffects] ERROR writing CSV: " .. tostring(err))
        tes3.messageBox("Error writing ingredient effects CSV: " .. tostring(err))
        return false
    end

    for _, row in ipairs(csvData) do
        file:write(table.concat(row, ",") .. "\n")
    end
    file:close()
    mwse.log("[ingredientEffects] exportIngredientEffects: CSV file written successfully.")
    return true
end

--------------------------------------------------------------------------------
-- Function: loadIngredientEffects
-- Reads the CSV file and builds a table mapping ingredient id to a list of effect names.
--------------------------------------------------------------------------------
function ingredientEffects.loadIngredientEffects()
    mwse.log("[ingredientEffects] loadIngredientEffects: Called. Attempting to read CSV: " .. csvFilename)
    local effectsMap = {}
    local file = io.open(csvFilename, "r")
    if not file then
        mwse.log("[ingredientEffects] ERROR reading CSV. File not found: " .. csvFilename)
        return effectsMap
    end

    for line in file:lines() do
        if line:match("%S") then
            local cols = {}
            for col in string.gmatch(line, "([^,]+)") do
                table.insert(cols, col:match("^%s*(.-)%s*$"))
            end
            if #cols >= 2 and cols[1] ~= "id" then
                local ingId = cols[1]
                local effect = cols[2]
                if not effectsMap[ingId] then
                    effectsMap[ingId] = {}
                end
                table.insert(effectsMap[ingId], effect)
                mwse.log("[ingredientEffects] Loaded: " .. ingId .. " -> " .. effect)
            end
        end
    end
    file:close()
    local count = 0
    for k,v in pairs(effectsMap) do count = count + 1 end
    mwse.log("[ingredientEffects] loadIngredientEffects: Completed. Total ingredients loaded: " .. count)
    return effectsMap
end

return ingredientEffects
