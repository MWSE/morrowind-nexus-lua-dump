local types = require("openmw.types")
local core = require("openmw.core")
local world = require("openmw.world")
local util = require("openmw.util")
local l10n = core.l10n("AnimatedPickup")


local M = {}

local player
local merchants = {}
local purchase = {}

local ui = {
    message = function(text) player:sendEvent("anpUiMessage", {show=text})		end,
    sound = function(sound) player:sendEvent("anpUiSound", { id=sound })		end,
    menu = function(arg) player:sendEvent("anpUiMessage", arg)				end
}

local function voices(data)
    core.sendGlobalEvent("dynVoiceEvent", {event="voice", data=data})
end

local function getOwner(reference)
    local id = reference.owner.recordId
    local owner = merchants[id]
    if owner then
        local o = owner.object
        if o and o:isValid() and o.count ~= 0 then
            if o.cell ~= reference.cell then o = nil end
            return o
        end
    end
    if owner and owner.scanned == reference.cell then return end
    print("SCAN for merchant "..id)
    local actor
    for _, v in ipairs(world.activeActors) do
        if v.recordId == id then actor = v end
    end
    merchants[id] = {scanned=reference.cell}
    if actor then merchants[id].object = actor end
    return actor
end

local typeToService = {
	[types.Apparatus] = "Apparatus",
	[types.Armor] = "Armor",
--	[types.Book] = "Books",
	[types.Clothing] = "Clothing",
	[types.Ingredient] = "Ingredients",
	[types.Light] = "Lights",
	[types.Lockpick] = "Picks",
	[types.Miscellaneous] = "Misc",
	[types.Potion] = "Potions",
	[types.Probe] = "Probes",
	[types.Repair] = "RepairItems",
	[types.Weapon] = "Weapon"
	}

local function tradesItemType(id, item)
    local services = types.NPC.record(id).servicesOffered
    if not services.Barter then return false end
    if types.Item.itemData(item).enchantmentCharge then
        if services.MagicItems then return true end
        return false
    end
--    if services.MagicItems and types.Ingredient.objectIsInstance(item) then return true end
    local serviceType = typeToService[item.type]
    return services[serviceType]
end

local condition = { wpnArm = { [types.Weapon] = true, [types.Armor] = true },
    others = { [types.Lockpick] = true, [types.Probe] = true, [types.Repair] = true } }

--- Barter math courtesy of ZackUtils by ZackHasACat
local function getBarterOffer(npc, item, buying)
    -- Calculate base price
    local rec = item.type.record(item)
    local data = types.Item.itemData(item)
    local basePrice = 1
    if data.condition then
        if condition.wpnArm[item.type] then basePrice = (data.condition / rec.health) end
        if condition.others[item.type] then basePrice = (data.condition / rec.maxCondition) end
    end
    if data.soul then basePrice = types.Creature.record(data.soul).soulValue end
    basePrice = basePrice * rec.value
    
    local self = player
    local playerMerc = types.NPC.stats.skills.mercantile(self).modified

    local playerLuck = types.Actor.stats.attributes.luck(self).modified
    local playerPers = types.Actor.stats.attributes.personality(self).modified

    local playerFatigueTerm = 1.25
    local npcFatigueTerm = 1.25

    -- Calculate the remaining parts of the function using the provided variables/methods
    local clampedDisposition = util.clamp(types.NPC.getDisposition(npc, self), 0, 100)
    local a = math.min(playerMerc, 100)
    local b = math.min(0.1 * playerLuck, 10)
    local c = math.min(0.2 * playerPers, 10)
    local d = math.min(types.NPC.stats.skills.mercantile(npc).modified, 100)
    local e =
        math.min(0.1 * types.Actor.stats.attributes.luck(npc).modified, 10)
    local f = math.min(0.2 *
        types.Actor.stats.attributes.personality(npc)
        .modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * playerFatigueTerm
    local npcTerm = (d + e + f) * npcFatigueTerm
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.floor(basePrice * item.count * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end

function M.uiMessageMenu(e)
    if e ~= 1 then
        ui.sound("Menu Click")
        -- Dynamic Voices interop
        voices{event="direct", action="close", actor=purchase.npc, player=player}
        return
    end

    ui.sound("Item Gold Up")
    player:sendEvent("anpResetTooltip")
    local item, npc = purchase.item, purchase.npc
    item.owner.recordId = nil
    local gold = types.Actor.inventory(player):find("gold_001")
    local pay = gold:split(purchase.price)
    pay:moveInto(npc)
    if item.parentContainer or world.isWorldPaused() then
        item:moveInto(player)
    else
--        print(item, item.parentContainer)
        item:activateBy(player)
    end
                    --Add <barter success> disposition to NPC
    types.NPC.modifyBaseDisposition(npc, player, core.getGMST("iBarterSuccessDisposition"))

    -- Dynamic Voices interop
    voices{event="direct", action="buy", actor=purchase.npc, player=player}

end

---Open the dialog to purchase an item
---@param itemRef tes3reference
---@param owner tes3mobileNPC
---@param price number
local function openPurchaseMenu(itemRef, owner, price)
    print("Opening purchase menu for", itemRef.recordId)
    local itemName = itemRef.type.record(itemRef).name
    if itemRef.count > 1 then itemName = itemName .. " (" .. itemRef.count .. ")" end
    local ownerName = types.NPC.record(owner).name
    purchase.npc, purchase.item, purchase.price = owner, itemRef, price
    ui.menu({ message = string.format(l10n("PurchaseMessage"), itemName, price, ownerName),
        buttons = { core.getGMST("sYes"), core.getGMST("sNo") }
    })
    ui.sound("Menu Click")

    --- Dynamic Voices interop
    voices{event="direct", action="open", actor=owner, player=player}

end

---Check if the player is looking at an item and is in a state where they can purchase it
---@param target tes3reference
---@return boolean
local function canPurchase(target)
    local id = target.recordId
    if id:find("^gold_") then
--        print("Cannot purchase", id, "- Target is gold")
        return false
    end
    local ownerId = target.owner.recordId
    if not ownerId or not types.NPC.record(ownerId) then
--        print("Cannot purchase", id, "- No NPC owner")
        return false
    end
    if not tradesItemType(ownerId, target) then
--        print("Cannot purchase", id, "- Owner does not trade this item type")
        return false
    end
    print("Can purchase", id)
    return true
end

local function getPlayerGold()
	local gold = types.Actor.inventory(player):find("gold_001")
	if not gold then return 0 end
	return gold.count
end

---Purchase an item by activating it
---@param e activateEventData
function M.onActivate(target, actor)
    player = actor
    if not canPurchase(target) then
--        print("Cannot purchase", target.recordId)
        return true
    end
    local owner = getOwner(target)
    if not owner then
        ui.message(string.format(l10n("msg_sellermissing"), types.NPC.record(target.owner.recordId).name))
        ui.sound("Menu Click")
        return false
    end
    if owner and types.Actor.isDead(owner) then
        ui.message(string.format(l10n("msg_sellerdead"), types.NPC.record(owner).name))
        ui.sound("Menu Click")
        return false
    end
    local price = getBarterOffer(owner, target, true)
    --player has enough gold
    if getPlayerGold() < price then
        ui.message("NotEnoughGold")
        ui.sound("Menu Click")
        return false
    end
    openPurchaseMenu(target, owner, price)
    return false
end

return M
