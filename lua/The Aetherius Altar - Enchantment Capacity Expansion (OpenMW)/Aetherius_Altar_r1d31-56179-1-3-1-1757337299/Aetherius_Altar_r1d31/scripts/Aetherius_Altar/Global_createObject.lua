local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')

-- This global list tracks what records ID have been improved
local itemHistoryList = {}

--Need to support weapon, armor, clothing ATLEAST
local function createEnchantObject(data)

    local function contains(list, target)
        for i, value in ipairs(list) do
            if value == target then
                return true  -- Found, return true and the index
            end
        end
        return false  -- Not found
    end

    item = data.item
    soulGems = data.soulGems

    --check if in itemhistory list
    print(item.recordId)
    if contains(itemHistoryList, item.recordId) then
        -- if is in the list, return
        world.players[1]:sendEvent('showPlayerMsg', {msg="This was already improved upon once, use a new item"})
        return
    end

    local originalRecord = item.type.records[item.recordId]
    local itemTable = {enchantCapacity = originalRecord.enchantCapacity * data.enchantCapMult, template = originalRecord}

    --local newRecordDraft = types.Weapon.createRecordDraft(itemTable) --- I HAD FRICKIN {itemTable} instead of ()
    local newRecordDraft = item.type.createRecordDraft(itemTable)

    --add to world
    local newRecord = world.createRecord(newRecordDraft) 
    -- add to list of items
    local upgradedItem = world.createObject(newRecord.id, 1)
    print(upgradedItem.recordId)
    table.insert(itemHistoryList, upgradedItem.recordId)

    --new position
    local xs = item.position.x
    local ys = item.position.y
    local zs = item.position.z
    local position = util.vector3(xs, ys, zs)

    --moves to altar
    upgradedItem:teleport(world.players[1].cell, position, { onGround = false })

    --Removes old item
    item.enabled = false

    -- Removes soulgems
    for i, soulGem in ipairs(soulGems) do
        --If Azuras star, give back empty one
        if (soulGem.recordId == 'misc_soulgem_azura') then
            print("Azuras star!")
            local azuraStarEmpty = world.createObject(soulGem.recordId, 1)
            azuraStarEmpty:teleport(world.players[1].cell, soulGem.position, { onGround = false })
            soulGem.enabled = false

        elseif types.Item.itemData(soulGem).soul ~= nil then
            --remove soul gems
            soulGem.enabled = false
        end
    end

    -- Spawn effect on created item
    local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.RestoreHealth]
    local pos = upgradedItem.position
    local model = types.Static.records[effect.castStatic].model
    world.vfx.spawn(model,position)

end

--creates object from Existing record
local function createObject(data)
    
end

local function spawnVfx(data)
    model = data.model
    position = data.position
    world.vfx.spawn(model,position)
end
  
return {
    eventHandlers = {
        createEnchantObject = createEnchantObject,
        createObject = createObject,
        spawnVfx = spawnVfx
    }
  }