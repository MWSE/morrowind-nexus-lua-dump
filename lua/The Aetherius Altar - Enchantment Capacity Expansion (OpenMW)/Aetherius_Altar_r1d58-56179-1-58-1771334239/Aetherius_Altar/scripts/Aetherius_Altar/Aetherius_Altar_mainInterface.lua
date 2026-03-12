local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')

local maxDistance = 400 --items must be inside this threadhold
local enabled = 1
local player --will be found

local function getMaxMult()
    return storage.globalSection("SettingsAetheriusAltar"):get("MaxMult")
end

local function getSoulPointsWeight()
    return storage.globalSection("SettingsAetheriusAltar"):get("SoulPointsWeight")
end



--This fnc gets the nearest enchantable item to the altar to then be converted
-- IT returns the item to be enchanted
local function getNearbyItem2Enchant(isReady2Enchant)
    --variables
    local closest = 0
    local distance = maxDistance

    --Iterate through nearby items to find closest weapon, armor or whatever
    for idx, item in pairs(nearby.items) do

        if (item.type == types.Weapon or item.type == types.Armor or item.type == types.Clothing) then
            local itemDistance = math.abs(self.position.x - item.position.x) + math.abs(self.position.y - item.position.y)
            --This is a very cheap distance calculation, l1 

            if (itemDistance <= distance) then
                closest = idx
                distance = itemDistance
            end
        end
    end
    
    if (distance >= maxDistance) then
        return noItems
    end
    local potential = nearby.items[closest]

    --print(nearby.items[closest])
    return potential
end


-- this looks at nearby items to see if the appropiate items have been given as sacrifices
-- it returns the enchantCap multiplier and true/false
local function isPayed()
    --print("Entering isPayed fnc")

    -- This controls how much the souls contribue to changing enchant cap
    local function calculateEnchantCap(enchantCapMult)
        
        local SoulPointsWeight = getSoulPointsWeight()
        enchantCapMult = enchantCapMult / SoulPointsWeight
        local min = 1.25
        local max = getMaxMult()

        if (enchantCapMult < min) then
            --print("Min: ", min)
            return notEnough

        elseif  (enchantCapMult >= max) then
            --print("Max: ", max)
            return max

        else
            --print("Mult: ", enchantCapMult)
            return enchantCapMult
        end
    end

    -- variables
    local distance = 0 -- inital

    local maxMult = 0 -- default, need to make sure the operation is halted if unchanged

    local soulGems = {}
    
    for idx, item in pairs(nearby.items) do

        -- This is a very cheap distance caluclation, no square root or power of 2. This was done to reduce computation
        distance = math.abs(self.position.x - item.position.x) + math.abs(self.position.y - item.position.y)

        --checks if misc item and is nearby a threshold
        if (item.type == types.Miscellaneous and distance <= maxDistance) then
            
            -- Item has a soul
            local itemData = types.Item.itemData(item)
            local soulId = nil
            local creatureRecord = 0

            soulId = itemData.soul
            if soulId ~= nil then
                creatureRecord = types.Creature.records[soulId]
                maxMult = (creatureRecord.soulValue)*item.count + maxMult
                --add that soulgem to the list
                table.insert(soulGems, item) 
            end
           
        end
    end

    --print("Total maxMult value: " .. tostring(maxMult))

    --get the amount to change enchantcapacity by
    enchantCapMult = calculateEnchantCap(maxMult)
    if enchantCapMult==notEnough then
        return false, 1, {}        
    end

    return true, enchantCapMult, soulGems

end


--fnc creates a draft record on activation to then pass it to a global object to be created
local function aetheriusAltarEnchant()

    -- This tracks if the Altar has recieved the cost/materials for the enchantment
    local isReady2Enchant = false --assumes false
    local enchantCapMult = 1
    local soulGems = {}
    
    isReady2Enchant, enchantCapMult, soulGems = isPayed()

    --print("Is ready to enchant value: " .. tostring(isReady2Enchant))

    if (isReady2Enchant ~= true) then
        print("Not enough sacrifices or payment provided, quiting") 
        player:sendEvent('showPlayerMsg', {source=self.object, msg="The Altar needs sacrifices"})
        return
    end

    local item = getNearbyItem2Enchant()

    --error handling for the above
    if (item == noItems) then
        print("No items found nearby, quiting")
        player:sendEvent('showPlayerMsg', {source=self.object, msg="The Altar is missing a worthy item"})
        return
    elseif item == itemAlreadyUsed then
        print("Closest item was already offered, quiting")
        player:sendEvent('showPlayerMsg', { msg="This item has already been improved upon by the Altar, offer a different item"})
        return
    end

    -- Global interface
    -- passing in altar itself and the nearest enchantable item to it
    core.sendGlobalEvent('createEnchantObject', { source=self.object, item=item, enchantCapMult = enchantCapMult, soulGems=soulGems})
    soulGems=nil
end

return {
    engineHandlers = {
        onActivated = function(actor)
            if ("aetherius_altar_activator" == self.recordId) then
                -- on activated, start process
                player = actor

                if (enabled == 1) then
                    aetheriusAltarEnchant()
                else
                    print("Not enabled  yet")
                    player:sendEvent('showPlayerMsg', {source=self.object, msg="Nothing happens"})
                end
            end
        end
    },
}