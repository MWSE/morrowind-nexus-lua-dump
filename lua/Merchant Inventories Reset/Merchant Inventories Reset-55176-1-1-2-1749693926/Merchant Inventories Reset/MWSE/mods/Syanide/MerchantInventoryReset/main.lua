local config = require("Syanide.MerchantInventoryReset.config")

-- Per-player save system
local soldItems = {}
local saveKey

-- Replace unsafe filename characters
local function sanitizeFileName(name)
    return name:gsub("[^%w_-]", "_")
end

-- Build a per-character config key
local function getSaveKeyForPlayer()
    local playerName = tes3.player and tes3.player.object.name or "default"
    return "MerchantSoldItems_" .. sanitizeFileName(playerName)
end

-- Load per-character sold item data
local function loadSoldItems()
    saveKey = getSaveKeyForPlayer()
    soldItems = mwse.loadConfig(saveKey) or {}
    mwse.log("[Merchant Inventory Reset] Loaded sold items for '%s'", saveKey)
end

-- Save per-character sold item data
local function saveSoldItems()
    if saveKey then
        mwse.saveConfig(saveKey, soldItems)
        mwse.log("[Merchant Inventory Reset] Saved sold items for '%s'", saveKey)
    end
end

-- Track items sold during barter
local function onBarterOffer(e)
    mwse.log("barterOffer event triggered")
    if e.success then
        mwse.log("Barter offer was successful.")
        local merchant = e.mobile.reference
        local merchantId = merchant.id
        for _, soldItem in ipairs(e.selling) do
            local item = soldItem.item
            local count = soldItem.count or 1
            mwse.log("Player sold %d x %s to merchant: %s", count, item.id, merchantId)
            soldItems[merchantId] = soldItems[merchantId] or {}
            soldItems[merchantId][item.id] = (soldItems[merchantId][item.id] or 0) + count
        end
        saveSoldItems()
    else
        mwse.log("The barter offer was not successful.")
    end
end

-- Remove sold items from merchant inventory
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
    soldItems = {}
    saveSoldItems()
end

-- Timer to reset merchant inventory
local function startTimer()
    timer.start({
        duration = config.resetTime,
        callback = function()
            mwse.log("Timer triggered. Removing sold items.")
            removeSoldItems()
        end,
        iterations = -1,
        type = timer.game
    })
end

-- Manual reset logic
local function resetMerchantInventory()
    if config.manualReset then
        tes3.messageBox{
            message = "Are you sure you want to reset all merchant inventories?",
            buttons = { "Yes", "No" },
            callback = function(e)
                if e.button == 0 then -- "Yes" was pressed
                    mwse.log("Manual merchant inventory reset confirmed by player.")
                    removeSoldItems()
                    startTimer()
                    if config.manualNote then
                        tes3.messageBox({ message = "Merchant inventories reset and timer restarted." })
                    end
                else
                    mwse.log("Manual reset cancelled by player.")
                end
            end
        }
    end
end

-- Keybind setup
local function registerKeybind()
    local keybind = config.manualResetKeybind
    event.register("keyDown", function(e)
        if e.keyCode == keybind.keyCode and not e.isAltDown and not e.isControlDown and not e.isShiftDown then
            resetMerchantInventory()
        end
    end)
end

-- Initialize mod when player is ready
local function initializeMod()
    if not tes3.player then return end
    loadSoldItems()
    startTimer()
    registerKeybind()
    mwse.log("[Merchant Inventory Reset] Initialized for player: %s", tes3.player.object.name)
end

-- Fallback in case player isn't ready at "initialized"
event.register("initialized", function()
    if tes3.player then
        initializeMod()
    else
        event.register("loaded", initializeMod)
    end
end)

event.register("barterOffer", onBarterOffer)