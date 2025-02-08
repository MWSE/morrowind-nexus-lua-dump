-- File: potionCrafting.lua
-- Purpose:
--   1) calculatePotionList: determine which potions can be made (synergy lines)
--   2) brewSynergyLine: display potion data in a custom UI

local this = {}
local potionData = require("AlchemyOptimizer.potionData")
local ingredientEffects = require("AlchemyOptimizer.ingredientEffects")

-- Global table to hold ingredient effects loaded from CSV.
local effectsMap = {}

--------------------------------------------
-- 1) Reading CSV & Building Synergy Logic
--------------------------------------------

-- Reads a CSV of effect priorities for potion synergy.
local function readEffectLines()
    local potions = {}
    -- Use the directory of the currently executing Lua script.
    local scriptDir = ingredientEffects.getScriptDirAbsolute()
    local path = scriptDir .. "effectpriorities.csv"
    --mwse.log("[potionCrafting] readEffectLines: Reading CSV from path: " .. path)
    local file = io.open(path, "r")
    if not file then
        tes3.messageBox("Could not find effectpriorities.csv. Ensure it is in the correct directory:\n" .. path)
        --mwse.log("[potionCrafting] readEffectLines: ERROR - File not found: " .. path)
        return potions
    end

    for line in file:lines() do
        if line:match("%S") then
            local columns = {}
            for col in string.gmatch(line, "([^,]+)") do
                local trimmed = col:match("^%s*(.-)%s*$")
                table.insert(columns, trimmed)
            end

            if #columns >= 2 then
                local potionName = columns[1]
                local effectList = {}
                for i = 2, #columns do
                    table.insert(effectList, columns[i])
                end

                table.insert(potions, {
                    potionName = potionName,
                    effects = effectList,
                })
                --mwse.log("[potionCrafting] readEffectLines: Added potion '" .. potionName .. "' with effects count " .. #effectList)
            end
        end
    end

    file:close()
    return potions
end

-- NEW: onLoaded handler to export and load ingredient effects CSV.
local function onLoaded()
    --mwse.log("[potionCrafting] onLoaded: Exporting ingredient effects CSV.")
    if ingredientEffects.exportIngredientEffects() then
        effectsMap = ingredientEffects.loadIngredientEffects()
        local count = 0
        for k,v in pairs(effectsMap) do count = count + 1 end
        --mwse.log("[potionCrafting] onLoaded: Successfully loaded ingredient effects CSV. Count: " .. count)
    else
        mwse.log("[potionCrafting] onLoaded: ERROR - Failed to export ingredient effects CSV.")
    end
end
event.register(tes3.event.loaded, onLoaded)

-- Replacement for the old getIngredientEffects function.
local function getIngredientEffects(id)
    return effectsMap[id] or {}
end

local function buildInventoryMap()
    local blacklist = tes3.player.data.alchemyOptimizer.blacklist or {}
    local inv = {}
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.objectType == tes3.objectType.ingredient then
            local iId = stack.object.id
            local c = stack.count or 0
            if (not blacklist[iId]) and c > 0 then
                inv[iId] = {
                    count = c,
                    effects = getIngredientEffects(iId)
                }
            end
        end
    end
    return inv
end

local function getSharedEffs(ingredientIds, invMap)
    local effCount = {}
    for _, iId in ipairs(ingredientIds) do
        local entry = invMap[iId]
        if entry then
            for _, eName in ipairs(entry.effects) do
                effCount[eName] = (effCount[eName] or 0) + 1
            end
        end
    end

    local ret = {}
    for eN, c in pairs(effCount) do
        if c >= 2 then
            table.insert(ret, eN)
        end
    end
    return ret
end

local function generateAllCombos(invMap)
    local keys = {}
    for id, _ in pairs(invMap) do
        table.insert(keys, id)
    end
    table.sort(keys)

    local combos = {}
    local n = #keys

    local function record(lst)
        local shared = getSharedEffs(lst, invMap)
        if #shared > 0 then
            table.insert(combos, {
                ingredientIds = lst,
                sharedEffects = shared
            })
        end
    end

    for i = 1, n - 1 do
        for j = i + 1, n do
            record({ keys[i], keys[j] })
        end
    end
    for i = 1, n - 2 do
        for j = i + 1, n - 1 do
            for k = j + 1, n do
                record({ keys[i], keys[j], keys[k] })
            end
        end
    end
    for i = 1, n - 3 do
        for j = i + 1, n - 2 do
            for k = j + 1, n - 1 do
                for m = k + 1, n do
                    record({ keys[i], keys[j], keys[k], keys[m] })
                end
            end
        end
    end
    return combos
end

local function comboSupportsAll(c, needed)
    local set = {}
    for _, eN in ipairs(c.sharedEffects) do
        set[eN] = true
    end
    for _, eff in ipairs(needed) do
        if not set[eff] then
            return false
        end
    end
    return true
end

local function computeLinePotions(effects, combos, invMap)
    local localMap = {}
    for k, v in pairs(invMap) do
        localMap[k] = { count = v.count, effects = v.effects }
    end

    local total = 0
    while true do
        local bestCombo
        local bestCount = 0
        for _, c in ipairs(combos) do
            if comboSupportsAll(c, effects) then
                local minVal
                for _, iId in ipairs(c.ingredientIds) do
                    local cval = localMap[iId] and localMap[iId].count or 0
                    if (not minVal) or cval < minVal then
                        minVal = cval
                    end
                end
                local possible = minVal or 0
                if possible > bestCount then
                    bestCount = possible
                    bestCombo = c
                end
            end
        end

        if (not bestCombo) or (bestCount < 1) then
            break
        end

        total = total + bestCount
        for _, iId in ipairs(bestCombo.ingredientIds) do
            localMap[iId].count = localMap[iId].count - bestCount
            if localMap[iId].count < 1 then
                localMap[iId] = nil
            end
        end
    end
    return total
end

function this.calculatePotionList()
    local lines = readEffectLines()
    if #lines == 0 then
        mwse.log("[potionCrafting] calculatePotionList: No effect lines found in CSV effect priorities.")
        return {}
    end

    local invMap = buildInventoryMap()
    local combos = generateAllCombos(invMap)
    local results = {}

    for _, row in ipairs(lines) do
        local count = computeLinePotions(row.effects, combos, invMap)
        if count > 0 then
            table.insert(results, {
                name = row.potionName,
                effectList = row.effects,
                count = count
            })
            --mwse.log("[potionCrafting] calculatePotionList: Added potion '" .. row.potionName .. "' with count " .. count)
        end
    end

    return results
end

local function findOneCombo(effects, combos, invMap)
    local bestC
    local bestCount = 0
    for _, c in ipairs(combos) do
        local set = {}
        for _, eN in ipairs(c.sharedEffects) do
            set[eN] = true
        end

        local match = true
        for _, efx in ipairs(effects) do
            if not set[efx] then
                match = false
                break
            end
        end
        if match then
            local minVal
            for _, iId in ipairs(c.ingredientIds) do
                local cval = invMap[iId] and invMap[iId].count or 0
                if (not minVal) or cval < minVal then
                    minVal = cval
                end
            end
            local possible = minVal or 0
            if possible > bestCount then
                bestCount = possible
                bestC = c
            end
        end
    end
    return bestC, bestCount
end

function this.brewSynergyLine(item)
    local invMap = buildInventoryMap()
    local combos = generateAllCombos(invMap)
    local bestC, bestCount = findOneCombo(item.effectList, combos, invMap)

    if not bestC or bestCount < 1 then
        tes3.messageBox("Cannot brew [%s] right now (no synergy / no ingredients).", item.name)
        return
    end

    potionData.showPotionData(item.name, bestC.ingredientIds, bestCount)
end

return this
