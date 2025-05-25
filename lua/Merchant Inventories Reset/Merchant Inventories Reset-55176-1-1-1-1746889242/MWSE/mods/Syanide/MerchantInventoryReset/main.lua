local config = require("Syanide.MerchantInventoryReset.config")
local soldItems = mwse.loadConfig("MerchantSoldItems", {})  -- Load previously saved sold items
local timerTriggered = false -- Flag to track if the timer has already run
-- Function to track items sold during barter
local function onBarterOffer(e)
    mwse.log("barterOffer event triggered")
    if e.success then
        mwse.log("Barter offer was successful.")
        local merchant = e.mobile.reference
        local merchantId = merchant.id
        -- Store the items being sold with quantity
        for _, soldItem in ipairs(e.selling) do
            local item = soldItem.item
            local count = soldItem.count or 1
            mwse.log("Player sold %d x %s to merchant: %s", count, item.id, merchantId)
            if not soldItems[merchantId] then
                soldItems[merchantId] = {}
            end
            if not soldItems[merchantId][item.id] then
                soldItems[merchantId][item.id] = 0
            end
            soldItems[merchantId][item.id] = soldItems[merchantId][item.id] + count
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
            for itemId, count in pairs(items) do
                tes3.removeItem({
                    reference = merchant,
                    item = itemId,
                    count = count,
                    playSound = false,
                    reevaluateEquipment = false
                })
                mwse.log("Removed %d x %s from merchant: %s", count, itemId, merchantId)
            end
            if config.notifyPlayer then
                tes3.messageBox({ message = "Merchant Inventories Reset" })
            end
        else
            mwse.log("Reference %s is not an NPC or creature merchant.", merchantId)
        end
    end
    -- Clear the sold items list after processing
    soldItems = {}
    mwse.saveConfig("MerchantSoldItems", soldItems)
end
-- Timer to reset merchant inventory
local function startTimer()
    timer.start({
        duration = config.resetTime,
        callback = function()
            mwse.log("Timer triggered. Removing sold items.")
            removeSoldItems()
            timerTriggered = true
        end,
        iterations = -1,
        type = timer.game
    })
end
-- Function to manually reset the merchant inventory and restart the timer
local function resetMerchantInventory()
    if config.manualReset then
        mwse.log("Manual merchant inventory reset triggered by keybind.")
        removeSoldItems()
        startTimer()
        if config.manualNote then
            tes3.messageBox({ message = "Merchant inventories reset and timer restarted." })
        end
    end
end
-- Bind a key to reset merchant inventory and timer
local function registerKeybind()
    local keybind = config.manualResetKeybind
    event.register("keyDown", function(e)
        if e.keyCode == keybind.keyCode and not e.isAltDown and not e.isControlDown and not e.isShiftDown then
            resetMerchantInventory()
        end
    end)
end
-- Register events and keybind
mwse.log("[Merchant Inventory Reset] Initialized!")
event.register("barterOffer", onBarterOffer)
event.register("loaded", startTimer)
event.register("loaded", registerKeybind)