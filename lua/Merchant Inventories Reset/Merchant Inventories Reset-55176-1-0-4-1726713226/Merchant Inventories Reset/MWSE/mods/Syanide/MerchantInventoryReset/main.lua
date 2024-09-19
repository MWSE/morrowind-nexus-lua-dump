local config = require("Syanide.MerchantInventoryReset.config")
local soldItems = mwse.loadConfig("MerchantSoldItems", {})  -- Load previously saved sold items
local timerTriggered = false -- Flag to track if the timer has already run

-- Function to track items sold during barter
local function onBarterOffer(e)
    mwse.log("barterOffer event triggered")

    if e.success then
        mwse.log("Barter offer was successful.")
        local merchant = e.mobile.reference

        -- Store the items being sold
        for _, soldItem in ipairs(e.selling) do
            local item = soldItem.item
            mwse.log("Player sold item: %s to merchant: %s", item.id, merchant.id)

            if not soldItems[merchant.id] then
                soldItems[merchant.id] = {}
            end
            table.insert(soldItems[merchant.id], item.id)
        end

        -- Save sold items immediately after each barter transaction
        mwse.saveConfig("MerchantSoldItems", soldItems)
    else
        mwse.log("The barter offer was not successful.")
    end
end

-- Function to remove items from merchant inventory and re-equip original gear
local function removeSoldItems()
    for merchantId, items in pairs(soldItems) do
        local merchant = tes3.getReference(merchantId)
        if merchant and (merchant.object.objectType == tes3.objectType.npc or merchant.object.objectType == tes3.objectType.creature) then
            for _, itemId in ipairs(items) do
                tes3.removeItem({ reference = merchant, item = itemId, playSound = false })
                mwse.log("Removed item: %s from merchant: %s", itemId, merchantId)
                    if config.notifyPlayer then
                        tes3.messageBox({ message = "Merchant Inventories Reset" })
                    end
            end
        else
            mwse.log("Reference %s is not an NPC or creature merchant.", merchantId)
        end
    end
    -- Clear the sold items list after processing
    soldItems = {}
    mwse.saveConfig("MerchantSoldItems", soldItems)  -- Save the cleared list
end

-- Timer to reset merchant inventory
local function startTimer()
    timer.start({
        duration = config.resetTime,
        callback = function()
            mwse.log("Timer triggered. Removing sold items.")
            removeSoldItems()
            timerTriggered = true -- Mark that the timer has run
        end,
        iterations = -1,
        type = timer.game
    })
end

-- Function to manually reset the merchant inventory and restart the timer
local function resetMerchantInventory()
    if config.manualReset then
        mwse.log("Manual merchant inventory reset triggered by keybind.")
        removeSoldItems()  -- Manually remove sold items
        startTimer()       -- Restart the timer
        if config.manualNote then
            tes3.messageBox({ message = "Merchant inventories reset and timer restarted." })
        end
    end
end

-- Bind a key to reset merchant inventory and timer
local function registerKeybind()
    -- Assign keybind (e.g., "K" for reset)
    local keybind = config.manualResetKeybind
    
    event.register("keyDown", function(e)
        if e.keyCode == keybind.keyCode and not e.isAltDown and not e.isControlDown and not e.isShiftDown then
            resetMerchantInventory()  -- Call the function when the key is pressed
        end
    end)
end

local function preventMerchantEquip(e)
    local merchant = e.reference
    -- Check if the reference is an NPC or creature and not the player
    if (merchant.object.objectType == tes3.objectType.npc or merchant.object.objectType == tes3.objectType.creature) and merchant ~= tes3.player then
        -- Check if the NPC is a follower
        local activePackage = merchant.mobile:getActivePackage()
        if activePackage and activePackage.type == tes3.aiPackage.Follow then
            -- The NPC is currently following, so don't block the equip
            return
        end

        -- Get the item being equipped
        local item = e.item
        -- Check if the item is a weapon, armor, or clothing
        if item.objectType == tes3.objectType.weapon or
           item.objectType == tes3.objectType.armor or
           item.objectType == tes3.objectType.clothing then
            -- Cancel the equip event
            e.block = true
            mwse.log("Prevented merchant: %s from equipping item: %s", merchant.id, item.id)
        end
    end
end


-- Register events and keybind
mwse.log("[Merchant Inventory Reset] Initialized!")
event.register("barterOffer", onBarterOffer)
event.register("loaded", startTimer)  -- Starts the timer when the game is loaded
event.register("loaded", registerKeybind)  -- Register the keybind when the game is loaded
event.register("equip", preventMerchantEquip)