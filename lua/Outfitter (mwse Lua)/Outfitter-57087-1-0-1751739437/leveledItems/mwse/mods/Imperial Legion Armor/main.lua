local ILMediumID = "IL_Medium"
local ILHeavyID = "IL_Heavy"
local ILTemplarID = "IL_Templar"
local ILDukeID = "IL_Duke"

local ILRank = {
    ["recruit"] = 0,
    ["spearman"] = 1,
    ["trooper"] = 2,
    ["agent"] = 3,
    ["champion"] = 4,
    ["knight errant"] = 5,
    ["knight bachelor"] = 6,
    ["knight protector"] = 7,
    ["knight of the garland"] = 8,
    ["knight of the imperial dragon"] = 9,
}

local function clearInventory(mobile)
    if mobile.inventory then
        mwse.log("Starting to clear the inventory of mobile: %s", mobile.id)
        
        for _, itemStack in pairs(mobile.inventory) do
            local item = itemStack.object
            mwse.log("Checking item: %s of type: %s", item.id, item.objectType)
            
            if item and (item.objectType == tes3.objectType.armor or item.objectType == tes3.objectType.weapon) then
                mwse.log("Removing item: %s of type: %s", item.id, item.objectType)
                tes3.removeItem({
                    reference = mobile,
                    item = item,
                    count = itemStack.count
                })
            else
                mwse.log("Item: %s is invalid or not an armor or weapon type.", item.id)
            end
        end
        
        mwse.log("Inventory of mobile %s has been cleared.", mobile.id)
    else
        mwse.log("mobile %s has no inventory.", mobile.id)
    end
end

local function itemExistsInInventory(mobile, itemId)
    mwse.log("Checking if item %s exists in the inventory of mobile %s.", itemId, mobile.id)
    
    for _, itemStack in pairs(mobile.inventory) do
        if itemStack.object.id == itemId then
            mwse.log("Item %s found in the inventory of mobile %s.", itemId, mobile.id)
            return true
        end
    end
    
    mwse.log("Item %s not found in the inventory of mobile %s.", itemId, mobile.id)
    return false
end

local function addLeveledItemsToNpc(mobile)
    if mobile.faction and (mobile.faction.id:lower() == "imperial legion") then
        mwse.log("Adding leveled items to mobile %s of the Imperial Legion.", mobile.id)
        clearInventory(mobile)

        local rank = mobile.factionRank
        local leveledListID

        if rank <= ILRank["spearman"] then
            leveledListID = ILMediumID
        elseif rank > ILRank["spearman"] and rank < ILRank["champion"] then
            leveledListID = ILHeavyID
        elseif rank > ILRank["champion"] and rank < ILRank["knight protector"] then
            leveledListID = ILTemplarID
        elseif rank >= ILRank["knight protector"] then
            leveledListID = ILDukeID
        end

        if leveledListID then
            local leveledList = tes3.getObject(leveledListID)
            
            if leveledList and leveledList.objectType == tes3.objectType.leveledItem then
                mwse.log("Leveled list '%s' found.", leveledListID)
                
                for _, node in pairs(leveledList.list) do
                    local item = node.object
                    if item and not itemExistsInInventory(mobile, item.id) then
                        mobile.inventory:addItem({ item = item, count = 1 })
                        mwse.log("Item %s has been added to %s.", item.id, mobile.id)
                    else
                        mwse.log("Item %s is already in the inventory of mobile %s and will not be added.", item.id, mobile.id)
                    end
                end
            else
                mwse.log("Leveled list '%s' not found or invalid.", leveledListID)
            end
        else
            mwse.log("No valid leveled list ID for mobile %s.", mobile.id)
        end
    else
        mwse.log("mobile %s is not in the Imperial Legion.", mobile.id)
    end
end

local function onInitialized()
    for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do
        local mobile = ref.mobile
        if mobile then
            addLeveledItemsToNpc(mobile)
        end
    end
end

mwse.log("[ImperialLegionUniform] Initialized Version 1.0")

event.register("loaded", onInitialized)
