-- BarterMod_Persuasion.lua
-- Offer to Barter through Persuasion menu, with disposition & Mercantile influence

local ClassDemand = require("bartermod.BarterMod_ClassDemand")
local AskLogic = require("bartermod.BarterMod_AskRules")
local ID_MenuPersuasion, ID_ServiceList, ID_BarterButton

-- TUNING CONSTANTS
local MIN_ASK_VALUE        = 100    -- lowest value NPC will demand
local MAX_OFFER_VALUE      = 2500   -- highest value NPC will offer
local BASE_VALUE_TOL       = 4.0    -- base offer/ask ratio tolerance
local DISP_INFLUENCE       = 0.005  -- how much each disp point tightens tolerance
local MERC_TOLERANCE_BOOST = 0.25   -- up to 25% wider tolerance at Merc 100
local MERC_DIVISOR         = 20     -- +1 disp bonus per this many Merc levels


local fallbackIDs = { "gold_001", "probe_journeyman_01" }

local allItems = {}
local npcDeals = {}

-- Fisher–Yates shuffle for rotating categories
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

-- Build the global item pool once per load
local function buildItemPool()
    local scanTypes = {
        tes3.objectType.alchemy, tes3.objectType.ammo,
        tes3.objectType.apparatus, tes3.objectType.armor,
        tes3.objectType.book, tes3.objectType.clothing,
        tes3.objectType.ingredient, tes3.objectType.lockpick,
        tes3.objectType.light, tes3.objectType.miscItem,
        tes3.objectType.probe, tes3.objectType.repairItem,
        tes3.objectType.scroll, tes3.objectType.spell,
        tes3.objectType.tool, tes3.objectType.weapon,
    }

    allItems = {}
    for _, oType in ipairs(scanTypes) do
        for obj in tes3.iterateObjects(oType) do
            if obj.value > 0 and not obj.isKey and not obj.isSoulGem then
                table.insert(allItems, obj)
            end
        end
    end

    if #allItems == 0 then
        for _, id in ipairs(fallbackIDs) do
            local obj = tes3.getObject(id)
            if obj then table.insert(allItems, obj) end
        end
    end

    mwse.log("[BarterMod] pooled %d items", #allItems)
end

-- Helper: does player have at least 1 of itemID?
local function hasMatchingItem(itemID)
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.id == itemID and stack.count > 0 then
            return true
        end
    end
    return false
end

-- Clear cached deals for this NPC so next time is fresh
local function clearDeals(ref)
    local key = ("%s_%d"):format(ref.baseObject.id, ref.uniqueIndex or 0)
    npcDeals[key] = nil
end
-- ### GET DEALS #### 
-- Generate up to 3 deals, applying disp & Mercantile to fairness tolerance
local function getDeals(ref)
    local key = ("%s_%d"):format(ref.baseObject.id, ref.uniqueIndex or 0)
    if npcDeals[key] then
        return npcDeals[key]
    end
    local classID = ref.object.class.id or "default"
    mwse.log("[BarterMod] generating new deals for %s (class %s)", ref.object.name, classID)

    -- 1) Build class-tuned pools
    local demandTypes = ClassDemand.getDemandTypes(classID)
    local offerPool   = {}
    local askPools    = AskLogic.buildAskPools(classID)

    -- Add fallback demand types for tight classes
    if #demandTypes < 2 then
        table.insert(demandTypes, tes3.objectType.miscItem)
        table.insert(demandTypes, tes3.objectType.book)
    end

    for _, oType in ipairs(demandTypes) do
        for obj in tes3.iterateObjects(oType) do
            if obj.value > 0
               and obj.value <= MAX_OFFER_VALUE
               and not obj.isKey
               and not obj.isSoulGem
            then
                table.insert(offerPool, obj)
            end
        end
    end
    if #offerPool == 0 then offerPool = allItems end

    -- 2) Compute base ratio bounds
    local dispLevel  = ref.object.disposition or 0
    local mercLevel  = tes3.mobilePlayer.mercantile.current or 0

    local dispFactor = 1 + (dispLevel * DISP_INFLUENCE)
    local baseTol    = BASE_VALUE_TOL / dispFactor
    local skillFactor = 1 + (mercLevel / 100) * MERC_TOLERANCE_BOOST

    local tolHigh = baseTol * skillFactor
    local tolLow  = 1 / tolHigh

    -- 3) Build a rotating list of category keys
    local validCategories = {}
    for oType, pool in pairs(askPools) do
        if #pool > 0 then table.insert(validCategories, oType) end
    end
    shuffle(validCategories)

    -- 4) Main deal generation loop with per-category rotation
    local list = {}
    for _, oType in ipairs(validCategories) do
        if #list >= 3 then break end
        local pool = askPools[oType]
        local ask  = pool[math.random(#pool)]
        local offer = offerPool[math.random(#offerPool)]

        if ask.id ~= offer.id then
            local ratio = offer.value / ask.value
            if ratio > tolLow and ratio < tolHigh then
                table.insert(list, { ask = ask, offer = offer })
            end
        end
    end

    -- 5) Post-pass pruning: limit alchemy to one slot
    local pruned = {}
    local seenAlch = false
    for _, deal in ipairs(list) do
        if deal.ask.objectType == tes3.objectType.alchemy then
            if not seenAlch then
                table.insert(pruned, deal)
                seenAlch = true
            end
        else
            table.insert(pruned, deal)
        end
        if #pruned == 3 then break end
    end
    list = pruned

    -- 6) If still no deals, fallback retry with expanded tolerance and default ask pool
    if #list == 0 then
        mwse.log("[BarterMod] too few fair deals; retrying with relaxed rules")

        tolHigh = tolHigh * 2
        tolLow  = 1 / tolHigh

        askPools = AskLogic.buildAskPools("default")
        validCategories = {}
        for oType, pool in pairs(askPools) do
            if #pool > 0 then table.insert(validCategories, oType) end
        end
        shuffle(validCategories)

        for _, oType in ipairs(validCategories) do
            if #list >= 3 then break end
            local pool = askPools[oType]
            local ask  = pool[math.random(#pool)]
            local offer = offerPool[math.random(#offerPool)]

            if ask.id ~= offer.id then
                local ratio = offer.value / ask.value
                if ratio > tolLow and ratio < tolHigh then
                    table.insert(list, { ask = ask, offer = offer })
                end
            end
        end
    end
-- 7) Optional fourth slot: potion priority
local alchPool = {}
for obj in tes3.iterateObjects(tes3.objectType.alchemy) do
    if obj.value >= MIN_ASK_VALUE and obj.value <= 1000
       and not obj.isKey and not obj.isSoulGem then
        table.insert(alchPool, obj)
    end
end

local alchAsk = alchPool[math.random(#alchPool)]
for attempt = 1, 10 do
    local offer = offerPool[math.random(#offerPool)]
    local ratio = offer.value / alchAsk.value
    if offer.id ~= alchAsk.id and ratio > tolLow and ratio < tolHigh then
        table.insert(list, {
            ask   = alchAsk,
            offer = offer,
            isPotion = true  -- tag for UI coloring
        })
        break
    end
end

    -- 7) Cache and return
    npcDeals[key] = list
    return list
end


-- Execute trade, compute dynamic disposition bonus
local function performTrade(ref, deal)
    tes3.removeItem{ reference = tes3.player, item = deal.ask.id,   count = 1 }
    tes3.addItem   { reference = tes3.player, item = deal.offer.id, count = 1 }
    tes3.addItem   { reference = ref,           item = deal.ask.id,   count = 1 }

    local mercLevel = tes3.mobilePlayer.mercantile.current or 0
    local askVal    = deal.ask.value
    local offerVal  = deal.offer.value
    local ratio     = offerVal / askVal

    local skillBonus = math.floor(mercLevel / MERC_DIVISOR)
    local fairBonus  = math.clamp(
        math.floor(10 - math.abs(ratio - 1) * 10) + skillBonus,
        2, 12
    )

    tes3.modDisposition{ reference = ref, value = fairBonus }

    local sentiment
    if math.abs(ratio - 1) < 0.1 then
        sentiment = "An equitable trade. Respect grows."
    elseif ratio >= 1.2 then
        sentiment = "Your generosity impresses them."
    elseif ratio <= 0.8 then
        sentiment = "They seem to feel slightly shortchanged."
    else
        sentiment = "Trade accepted. Business as usual."
    end

    tes3.messageBox("%s completes the trade. %s Disposition +%d.",
        ref.object.name, sentiment, fairBonus
    )
    mwse.log("[BarterMod] traded with %s; disp +%d (ratio %.2f, Merc bonus %d)",
        ref.object.name, fairBonus, ratio, skillBonus
    )
end

-- Show the barter menu under Persuasion
local function showBarterMenu(ref)
    if #allItems == 0 then
        tes3.messageBox("BarterMod: no items available.")
        return
    end

    local deals = getDeals(ref)
    if #deals == 0 then
        tes3.messageBox("No fair trades available right now.")
        return
    end

    local buttons = {}
    for i, deal in ipairs(deals) do
    local label = ("Offer: %s\nAsk:   %s")
                    :format(deal.offer.name, deal.ask.name)

    buttons[i] = {
       text     = ("%s"):format(label),
--        tooltip  = label,
        callback = function()
            if not hasMatchingItem(deal.ask.id) then
                tes3.messageBox("You need %s to trade.", deal.ask.name)
                return
            end
            performTrade(ref, deal)
            clearDeals(ref)
        end,
 --      textColor = deal.isPotion and { 0.5, 0.9, 0.6 } or nil

    }
end


    table.insert(buttons, {
        text     = "Cancel",
        isCancel = true,
        callback = function()
            tes3.messageBox("Barter canceled.")
        end
    })

    tes3ui.showMessageMenu{
        message = "Select a barter deal:",
        buttons = buttons
    }
end

-- Hook into Persuasion UI
local function onBarterClick()
    local menu     = tes3ui.findMenu(ID_MenuPersuasion)
    local actorObj = menu and menu:getPropertyObject("MenuPersuasion_Actor")
    if not (actorObj and actorObj.reference) then return end
local disp = actorObj.reference.object.disposition or 0
if disp < 40 then
    local blockedMessages = {
        "They eye you with suspicion.",
        "Trade? With you? Not likely.",
        "They don't seem willing to barter.",
        "You're not trusted enough for trade.",
    }
    tes3.messageBox("%s %s", actorObj.reference.object.name, blockedMessages[math.random(#blockedMessages)])
    return
end

    menu:destroy()
    showBarterMenu(actorObj.reference)
end

local function onPersuasionActivated(e)
    if not e.newlyCreated then return end
    local pane = e.element:findChild(ID_ServiceList)
    if not pane then return end

    local btn = pane:createTextSelect{
        id   = ID_BarterButton,
        text = "Offer to Barter"
    }
    btn:register("mouseClick", onBarterClick)

    e.element.visible = false
    e.element.visible = true
    e.element:updateLayout()
end

-- INITIALIZATION
event.register("initialized", function()
    math.randomseed(os.time())
    ID_MenuPersuasion = tes3ui.registerID("MenuPersuasion")
    ID_ServiceList    = tes3ui.registerID("MenuPersuasion_ServiceList")
    ID_BarterButton   = tes3ui.registerID("MenuPersuasion_ServiceList_OfferToBarter")

    event.register("loaded", function()
        buildItemPool()
        event.register("uiActivated", onPersuasionActivated, { filter = "MenuPersuasion" })
        mwse.log("[BarterMod] initialized and hooked Persuasion menu")
    end)
end)
