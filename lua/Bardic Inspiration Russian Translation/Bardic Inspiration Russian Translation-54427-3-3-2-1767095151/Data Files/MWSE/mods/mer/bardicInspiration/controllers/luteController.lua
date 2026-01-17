--[[
    This script finds all vanilla lutes the player may
    come across and converts them into playable lutes.
]]

local common = require("mer.bardicInspiration.common")
local staticData = common.staticData

local logger = common.log


-- Key for storing original misc lute data on weapon itemData
local ORIGINAL_LUTE_KEY = "mer_bi_originalLute"

---Copy itemData fields from one item to another
---@param sourceItemData tes3itemData?
---@param targetItemData tes3itemData
local function copyItemData(sourceItemData, targetItemData)
    -- Copy custom data table
    if sourceItemData and sourceItemData.data then
        targetItemData.data = targetItemData.data or {}
        for key, value in pairs(sourceItemData.data) do
            targetItemData.data[key] = value
        end
    end
end

---Check if an item is a misc lute that should be swapped
---@param item tes3item
---@return boolean
local function isMiscLute(item)
    return staticData.idMapping[item.id:lower()] ~= nil
end

---Get the weapon lute ID for a misc lute
---@param miscLuteId string
---@return string?
local function getWeaponLuteId(miscLuteId)
    return staticData.idMapping[miscLuteId:lower()]
end

---Check if a weapon lute has original misc lute data stored
---@param itemData tes3itemData?
---@return boolean
local function hasOriginalLuteData(itemData)
    return itemData ~= nil
        and itemData.data ~= nil
        and itemData.data[ORIGINAL_LUTE_KEY] ~= nil
end

event.register(tes3.event.equip, function(e)
    -- Check if this is a misc lute
    if not isMiscLute(e.item) then
        return
    end

    logger:debug("Equipping misc lute: %s", e.item.id)

    local weaponLuteId = getWeaponLuteId(e.item.id)
    if not weaponLuteId then
        logger:warn("No weapon lute mapping found for: %s", e.item.id)
        return
    end

    local weaponLute = tes3.getObject(weaponLuteId)
    if not weaponLute then
        logger:error("Weapon lute object not found: %s", weaponLuteId)
        return
    end

    -- Store original misc lute data
    local originalLuteData = {
        id = e.item.id,
    }

    -- Add the weapon lute with stored data
    tes3.addItem{
        reference = tes3.player,
        item = weaponLuteId,
        count = 1,
        playSound = false,
    }
    local addedItemData = tes3.addItemData{
        to = tes3.player,
        item = weaponLuteId,
    }

    -- Store original lute info on the new weapon
    if addedItemData then
        addedItemData.data = addedItemData.data or {}
        addedItemData.data[ORIGINAL_LUTE_KEY] = originalLuteData

        -- Copy itemData from misc lute to weapon lute
        copyItemData(e.itemData, addedItemData)

        logger:debug("Stored original lute data: %s", e.item.id)
    else
        logger:warn("Failed to add itemData to weapon lute: %s", weaponLuteId)
    end

    -- Remove the misc lute
    tes3.removeItem{
        reference = tes3.player,
        item = e.item,
        count = 1,
        playSound = false,
    }

    -- Equip the weapon lute
    tes3.player.mobile:equip{
        item = weaponLute,
    }

    logger:debug("Swapped misc lute %s to weapon lute %s", e.item.id, weaponLuteId)
    return false
end)


---Check if lute weapon with misc ID in data, and swap with mis
---@param item tes3item
---@param itemData tes3itemData
---@return { item: tes3item, itemData: tes3itemData, originalMiscLute: tes3item }|nil
local function processStack(item, itemData)
    -- Only process weapon lutes
    if item.objectType ~= tes3.objectType.weapon then
        return
    end

    -- Check if this weapon has original lute data
    if not hasOriginalLuteData(itemData) then
        return
    end

    local originalData = itemData.data[ORIGINAL_LUTE_KEY]
    logger:debug("Found weapon lute with original misc lute data: %s", originalData.id)

    local miscLuteId = originalData.id
    local miscLute = tes3.getObject(miscLuteId)
    if not miscLute then
        logger:error("Original misc lute object not found: %s", miscLuteId)
        return
    end

    --check if its equipped
    if tes3.player.object:hasItemEquipped(item, itemData) then
        logger:debug("Lute %s is currently equipped, skipping swap back to misc lute", item.id)
        return
    end
    logger:debug("Swapping weapon lute %s back to misc lute %s", item.id, miscLuteId)


    -- Store data to swap later
    return {
        item = item,
        itemData = itemData,
        originalMiscLute = miscLute,
    }
end

local function swapLutesInInventory()
    if common.data.songPlaying then
        logger:debug("Song is playing, skipping lute swap in inventory")
        return
    end
    logger:debug("Swapping weapon lutes back to misc lutes in inventory")
    ---@type { item: tes3item, itemData: tes3itemData, originalMiscLute: tes3item }[]
    local lutesToSwap = {}
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object and stack.variables then
            for _, itemData in ipairs(stack.variables) do
                local swapData = processStack(stack.object, itemData)
                if swapData then
                    table.insert(lutesToSwap, swapData)
                end
            end
        end
    end
    for _, data in ipairs(lutesToSwap) do
        -- Remove the weapon lute
        tes3.removeItem{
            reference = tes3.player,
            item = data.item,
            itemData = data.itemData,
            count = 1,
            playSound = false,
        }

        -- Add the original misc lute back
        tes3.addItem{
            reference = tes3.player,
            item = data.originalMiscLute,
            count = 1,
            playSound = false,
        }
    end
end

event.register(tes3.event.menuEnter, swapLutesInInventory)
event.register(tes3.event.menuExit, swapLutesInInventory)


local function getChildIndexByName(collection, name)
	for i, child in ipairs(collection) do
		if (child and child.name and child.name:lower() == name:lower()) then
			return i - 1
		end
	end
end

local function translateFloorLute(ref)
    local switchNode = ref.sceneNode:getObjectByName("SWITCH_LUTE")
    if switchNode then
        local groundIndex = getChildIndexByName(switchNode.children, "SWITCH_GROUND")
        switchNode.switchIndex = groundIndex
    end
end

--[[
    Check for a vanilla lute placed in the world and switch it
]]
local function positionPlacedLute(e)
    if e.reference then
        local id = e.reference.baseObject.id:lower()
        if  common.staticData.lutes[id] then
            common.log:debug("Switching to floor lute switch node")
            translateFloorLute(e.reference)
        end
    end
end
event.register("referenceActivated", positionPlacedLute)