--[[
    Allows the player to purchase items directly by activating them.
    - Uses the base barter price for the item (as if they selected the item in trade and didn't attempt to haggle)
    - Requires the player to have enough gold to purchase the item
    - Sneak to steal the item instead
]]

local common = require("mer.shopAround.common")
local messages = common.messages
local logger = common.createLogger("DirectPurchase")

---Open the dialog to purchase an item
---@param itemRef tes3reference
---@param owner tes3mobileNPC
---@param price number
local function openPurchaseMenu(itemRef, owner, price)
    logger:debug("Opening purchase menu for %s", itemRef.object.id)
    local itemName = itemRef.object.name
    local ownerName = owner.object.name
    tes3ui.showMessageMenu{
        message = messages.PurchaseMessage{
            itemName = itemName,
            price = price,
            merchantName = ownerName
        },
        buttons = {
            {
                text = tes3.findGMST(tes3.gmst.sYes).value,
                callback = function()
                    --remove ownership
                    itemRef.itemData.owner = nil
                    --pay
                    tes3.payMerchant{
                        merchant = owner,
                        cost = price
                    }
                    tes3.playSound{ reference = tes3.player, sound = "Item Gold Up" }
                    --pick up
                    common.pickUp(itemRef, true)
                    --Add 1 disposition to NPC
                    owner.object.baseDisposition = owner.object.baseDisposition + 1
                end
            },
        },
        cancels = true,
        cancelText = tes3.findGMST(tes3.gmst.sNo).value,
    }
end

---Check if the player is looking at an item and is in a state where they can purchase it
---@param target tes3reference
---@return boolean
local function canPurchase(target)
    if not common.config.mcm.enableDirectPurchase then
        logger:trace("Cannot purchase - Direct purchase disabled")
        return false end
    if not target then
        logger:trace("Cannot purchase - No target")
        return false
    end
    if tes3.player.mobile.isSneaking then
        logger:trace("Cannot purchase - Player is sneaking")
        return false
    end
    if target.object.isGold then
        logger:trace("Cannot purchase - Target is gold")
        return false
    end
    if tes3.hasOwnershipAccess{ target = target} then
        logger:trace("Cannot purchase - Player has ownership access")
        return false
    end
    local owner = common.getOwner(target)
    if not owner then
        logger:trace("Cannot purchase - No owner")
        return false
    end
    if not owner.object:tradesItemType(target.object.objectType) then
        logger:trace("Cannot purchase - Owner does not trade this item type")
        return false
    end
    logger:trace("Can purchase %s", target.object.id)
    return true
end


---Purchase an item by activating it
---@param e activateEventData
event.register("activate", function(e)
    local target = e.target
    if not canPurchase(target) then
        logger:debug("Cannot purchase %s", target.object.id)
        return
    end
    local owner = common.getOwner(target)
    local price = tes3.calculatePrice{
        bartering = true,
        object = target.object,
        itemData = target.itemData,
        buying = true,
        merchant = owner
    }
    --player has enough gold
    if tes3.getPlayerGold() < price then
        tes3.messageBox(messages.NotEnoughGold())
        tes3.playSound{ reference = tes3.player, sound = "Menu Click" }
        return false
    end
    openPurchaseMenu(target, owner, price)
    return false
end, { priority = 100 })



---Show "Purchase" in tooltip if applicable
---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local target = e.reference
  if not canPurchase(target) then return end
    local owner = common.getOwner(target)
    local price = tes3.calculatePrice{
        bartering = true,
        object = e.reference.object,
        itemData = e.reference.itemData,
        buying = true,
        merchant = owner
    }

    local text = messages.TooltipMessage{
        price = price
    }
    local label = e.tooltip:createLabel{
        text = text,
        id = tes3ui.registerID("mer.accidentalTheftProtection.purchase"),
    }
    --player has enough gold
    if tes3.getPlayerGold() >= price then
        label.color = tes3ui.getPalette("active_color")
    else
        label.color = tes3ui.getPalette("disabled_color")
    end
end, { priority = -100 })

---Reset modded indicators when looking at a purchaseable item
event.register("simulate", function(e)
    if not common.config.mcm.enableDirectPurchase then return end
    local target = tes3.getPlayerTarget()
    if not target then return end
    if canPurchase(target) then
        logger:trace("Resetting modded indicators")
        common.resetModdedIndicators()
    end
end, { priority = -100})