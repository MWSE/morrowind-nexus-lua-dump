local types = require("openmw.types")
local world = require("openmw.world")
local core = require("openmw.core")
local lootLoader = require("scripts.lootgenerator.lootloader")

lootLoader.loadLootPatches()
local injected = {}
local allLoot = lootLoader.getLootData()

-- Class to tag mapping 
local classTagMap = {
    ["acrobat"] = {"rogue"},
    ["agent"] = {"rogue"},
    ["archer"] = {"rogue", "warrior"},
    ["assassin"] = {"rogue"},
    ["barbarian"] = {"warrior"},
    ["bard"] = {"rogue", "mage"},
    ["battlemage"] = {"mage", "rogue"},
    ["buoyant armiger"] = {"warrior"},
    ["caravaner"] = {"commoner"},
    ["champion"] = {"warrior"},
    ["clothier"] = {"commoner", "wealthy"},
    ["commoner"] = {"commoner"},
    ["crusader"] = {"warrior", "mage"},
    ["dreamer"] = {"commoner", "rogue"},
    ["drillmaster"] = {"commoner"},
    ["enchanter"] = {"mage", "scholar", "wealthy"},
    ["enforcer"] = {"warrior"},
    ["farmer"] = {"commoner"},
    ["gondolier"] = {"commoner"},
    ["guard"] = {"warrior"},
    ["guild guide"] = {"commoner", "scholar"},
    ["healer"] = {"mage"},
    ["herder"] = {"commoner"},
    ["hunter"] = {"rogue", "warrior"},
    ["knight"] = {"warrior"},
    ["mage"] = {"mage"},
    ["mabrigash"] = {"rogue", "alchemist"},
    ["master-at-arms"] = {"warrior"},
    ["mercenary"] = {"warrior"},
    ["merchant"] = {"commoner", "wealthy"},
    ["miner"] = {"commoner"},
    ["monk"] = {"rogue"},
    ["necromancer"] = {"mage", "alchemist"},
    ["noble"] = {"wealthy"},
    ["nightblade"] = {"rogue", "mage"},
    ["ordinator"] = {"warrior"},
    ["ordinator guard"] = {"warrior"},
    ["pauper"] = {"laborer"},
    ["pilgrim"] = {"rogue", "mage"},
    ["pawnbroker"] = {"commoner", "wealthy"},
    ["priest"] = {"scholar"},
    ["publican"] = {"commoner"},
    ["rogue"] = {"rogue"},
    ["savant"] = {"scholar"},
    ["sharpshooter"] = {"rogue", "warrior"},
    ["shipmaster"] = {"commoner"},
    ["slave"] = {"laborer"},
    ["smith"] = {"commoner"},
    ["smuggler"] = {"rogue"},
    ["sorcerer"] = {"mage"},
    ["spellsword"] = {"warrior", "mage"},
    ["thief"] = {"rogue"},
    ["trader"] = {"commoner"},
    ["warlock"] = {"mage", "alchemist"},
    ["warrior"] = {"warrior"},
    ["witch"] = {"mage", "alchemist"},
    ["witchhunter"] = {"warrior", "mage"},
    ["wise woman"] = {"alchemist"},
}

local goldByTag = {
    laborer = {0, 0},
    commoner = {5, 10},
    scholar = {22, 33},
    alchemist = {15, 25},
    wealthy = {100, 150},
    warrior = {20, 30},
    rogue = {31, 49},
    mage = {18, 32},
}

local function tableContains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

local function getClassTags(npcClass)
    if npcClass and classTagMap[npcClass] then
        return classTagMap[npcClass]
    else
        print("[LootGen] Unknown or nil NPC class '" .. tostring(npcClass) .. "', using 'commoner' tag.")
        return { "commoner" }
    end
end

local function filterMiscByClassTags(miscList, tags, fallbackOnly)
    local filtered = {}

    for _, entry in ipairs(miscList) do
        if type(entry) == "table" and entry.id and entry.tags then
            for _, tag in ipairs(entry.tags) do
                if tableContains(tags, tag) then
                    table.insert(filtered, entry.id)
                    break
                end
            end
        elseif fallbackOnly and type(entry) == "string" then
            table.insert(filtered, entry)
        end
    end

    return filtered
end

local function spawnLoot(obj, loot, category, firstChance, secondChance, sameItemTwice)
    local categoryList = loot[category]

    if not categoryList or #categoryList == 0 then
        print("[LootGen] No items in category: " .. tostring(category))
        return
    end

    if math.random() < firstChance then
        local idx = math.random(#categoryList)
        local selectedItem = categoryList[idx]

        local success, item = pcall(world.createObject, selectedItem, 1)
        if success and item then
            item:moveInto(obj)

            if secondChance and math.random() < secondChance then
                local itemToAdd = selectedItem
                if not sameItemTwice then
                    local altList = {}
                    for _, id in ipairs(categoryList) do
                        if id ~= selectedItem then
                            table.insert(altList, id)
                        end
                    end
                    if #altList > 0 then
                        itemToAdd = altList[math.random(#altList)]
                    end
                end

                local successExtra, extraItem = pcall(world.createObject, itemToAdd, 1)
                if successExtra and extraItem then
                    extraItem:moveInto(obj)
                else
                    print("[LootGen] Failed to create extra object: " .. tostring(itemToAdd))
                end
            end
        else
            print("[LootGen] Failed to create object: " .. tostring(selectedItem))
        end
    end
end

local function calculateGoldAmount(tags)    
	if not tags or #tags == 0 then
        return 0
    end
	
	local minSum, maxSum = 0, 0
    local matched = 0

    for _, tag in ipairs(tags) do
        local range = goldByTag[tag]
        if range then
            minSum = minSum + range[1]
            maxSum = maxSum + range[2]
            matched = matched + 1
        end
    end

    if matched > 0 then
        local avgMin = math.floor(minSum / matched)
        local avgMax = math.floor(maxSum / matched)
        return math.random(avgMin, avgMax)
    end

    return 0
end

local function isStaticCorpse(obj)
    if not types.NPC.objectIsInstance(obj) then return false end
    local clone = world.createObject(obj.recordId, 1)
    if not clone then return false end
    local baseHp = types.Actor.stats.dynamic.health(clone).base
    clone:remove()
    return baseHp <= 0
end

return {
    engineHandlers = {
        onInit = function()
            math.randomseed(os.time())
        end,

        onObjectActive = function(obj)
            if obj and types.NPC.objectIsInstance(obj) and not injected[obj.id] then
                local isCorpse = isStaticCorpse(obj)

                if not isCorpse then
                    spawnLoot(obj, allLoot, "food", 0.8, 0.5, true)
                    spawnLoot(obj, allLoot, "drink", 1.0, 0.2, true)
                end

                local npcClass = types.NPC.record(obj).class
                --print("[LootGen] NPC class detected: " .. tostring(npcClass))

                local tags = getClassTags(npcClass)
                --print("[LootGen] NPC class tags: " .. table.concat(tags, ", "))

                local fallbackOnly = (tags[1] == "commoner" and #tags == 1)
                local filteredMisc = filterMiscByClassTags(allLoot.misc, tags, fallbackOnly)
                spawnLoot(obj, { misc = filteredMisc }, "misc", 1.0, 0.2, false)

                -- Gold based on tags
                local goldAmount = calculateGoldAmount(tags)
                if goldAmount > 0 then
                    local success, gold = pcall(world.createObject, "Gold_001", goldAmount)
                    if success and gold then
                        gold:moveInto(obj)
                    else
                        print("[LootGen] Failed to create gold object")
                    end
                end

                injected[obj.id] = true
            end
        end,

        onSave = function()
            return { injected = injected }
        end,

        onLoad = function(data)
            if data and data.injected then
                injected = data.injected
            end
        end
    }
}