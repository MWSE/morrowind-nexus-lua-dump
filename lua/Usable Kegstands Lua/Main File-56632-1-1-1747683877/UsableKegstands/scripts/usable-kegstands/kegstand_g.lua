-- kegstand_g.lua
-- Core logic for replacing static keg models with usable ones,
-- assigning randomized drinks, managing refill uses,
-- and handling activation for stealing or purchasing drinks.

-- OpenMW modules
local world     = require("openmw.world")
local core      = require("openmw.core")
local types     = require("openmw.types")
local interface = require("openmw.interfaces")
local async = require("openmw.async")

local Crimes    = interface.Crimes

local activeMods = {
    base = true,
    devilishNeeds = types.Activator.record("detd_Furn_Com_Kegstand") ~= nil,
    kegDrip = types.Activator.record("furn_com_kegstand_dr") ~= nil,
}

-- Rules for keg-handling per mod: defines whether to remove the mod's keg if found
local kegModRules = {
    base = {
        kegIds = {
            ["furn_com_kegstand"] = true,
            ["furn_de_kegstand"] = true,
        },
    },
    kegDrip = {
        kegIds = {
            ["furn_com_kegstand_dr"] = true,
            ["furn_de_kegstand_dr"] = true,
        },
    },
    devilishNeeds = {
        kegIds = {
            ["detd_furn_com_kegstand"] = true,
        },
    },
}

-- Runtime storage for dynamic mappings
local kegDrinkById  = {}  -- object.id -> drink table
local kegModelById  = {}  -- object.id -> original model

-- Asset paths
local kegIconPath = "icons/usable-kegstands/kegstand.tga"

-- Acceptable bottle-like containers the player can fill
local bottleWhitelist = {
    ["misc_com_bottle_01"] = true,
    ["misc_com_bottle_02"] = true,
    ["misc_com_bottle_03"] = true,
    ["misc_com_bottle_04"] = true,
    ["misc_com_bottle_05"] = true,
    ["misc_com_bottle_06"] = true,
    ["misc_com_bottle_07"] = true,
    ["misc_com_bottle_07_float"] = true,
    ["misc_com_bottle_08"] = true,
    ["misc_com_bottle_09"] = true,
    ["misc_com_bottle_10"] = true,
    ["misc_com_bottle_11"] = true,
    ["misc_com_bottle_12"] = true,
    ["misc_com_bottle_13"] = true,
    ["misc_com_bottle_14"] = true,
    ["misc_com_bottle_14_float"] = true,
    ["misc_com_bottle_15"] = true,
    ["misc_com_metal_goblet_01"] = true,
    ["misc_com_metal_goblet_02"] = true,
    ["misc_de_goblet_01"] = true,
    ["misc_de_goblet_02"] = true,
    ["misc_de_goblet_03"] = true,
    ["misc_de_goblet_04"] = true,
    ["misc_de_goblet_05"] = true,
    ["misc_de_goblet_06"] = true,
    ["misc_de_goblet_07"] = true,
    ["misc_de_goblet_08"] = true,
    ["misc_de_goblet_09"] = true,
    ["misc_de_glass_green_01"] = true,
    ["misc_com_pitcher_metal_01"] = true,
    ["misc_com_redware_pitcher"] = true,
    ["misc_de_pitcher_01"] = true,
    ["misc_imp_silverware_cup"] = true,
    ["misc_imp_silverware_cup_01"] = true,
    ["misc_imp_silverware_pitcher"] = true,
    ["misc_com_tankard_01"] = true,
    ["misc_de_tankard_01"] = true,
    ["misc_de_glass_yellow_01"] = true,
    ["misc_com_redware_flask"] = true,
    ["misc_flask_01"] = true,
    ["misc_flask_02"] = true,
    ["misc_flask_03"] = true,
    ["misc_flask_04"] = true,
    ["misc_com_bucket_01"] = true,
    ["misc_com_bucket_01_float"] = true,
    ["misc_com_bucket_metal"] = true,
    ["misc_beaker_01"] = true,
}

-- List of possible drinks, assigned randomly on replacement
local kegDrinkVariants = {
    { id = "potion_empty_placeholder", name = "Empty", rarity = "empty" },  -- special zero-use keg
    { id = "potion_comberry_wine_01",     name = "Shein",             rarity = "common"    },
    { id = "Potion_Local_Brew_01",        name = "Mazte",             rarity = "common"    },
    { id = "potion_comberry_brandy_01",   name = "Greef",             rarity = "common"    },
    { id = "Potion_Cyro_Whiskey_01",      name = "Flin",              rarity = "very_rare" },
    { id = "potion_cyro_brandy_01",       name = "Cyrodiilic Brandy", rarity = "very_rare" },
    { id = "potion_local_liquor_01",      name = "Sujamma",           rarity = "rare"      },
}

if activeMods.devilishNeeds then
    table.insert(kegDrinkVariants, {
        id = "detd_goodpotwater",
        name = "Water",
        rarity = "common"
    })
end

-- Determine if object should be replaced with a usable keg
local function shouldReplace(obj)
    local id = obj.recordId:lower()
    for mod, rule in pairs(kegModRules) do
        if activeMods[mod] and rule.kegIds[id] then
            return true
        end
    end
    return false
end

-- Randomly select a drink from the weighted rarity pool
local function pickRandomDrink()
    local roll = math.random()
    local pool = {}

    if roll <= 0.10 then
        for _, d in ipairs(kegDrinkVariants) do
            if d.rarity == "empty" then table.insert(pool, d) end
        end
    elseif roll <= 0.15 then
        for _, d in ipairs(kegDrinkVariants) do
            if d.rarity == "rare" then table.insert(pool, d) end
        end
    elseif roll <= 0.99 then
        for _, d in ipairs(kegDrinkVariants) do
            if d.rarity == "common" then table.insert(pool, d) end
        end
    else
        for _, d in ipairs(kegDrinkVariants) do
            if d.rarity == "very_rare" then table.insert(pool, d) end
        end
    end

    return pool[math.random(#pool)]
end

-- Determine remaining uses based on item value vs drink base price
local function getRemainingUses(obj, baseValue)
    local rec = types.Miscellaneous.record(obj.recordId)
    if not rec then return 0 end
    return math.floor(rec.value / baseValue)
end

-- Replace keg object with updated copy reflecting reduced uses
local function setRemainingUses(obj, baseValue, uses, label)
    local model = kegModelById[obj.id] or "meshes/f/furn_com_kegstand.nif"
    local displayName = (uses <= 0) and "Empty Kegstand" or (label .. " Kegstand")

    local draft = types.Miscellaneous.createRecordDraft({
        name = displayName,
        weight = 0,
        icon = kegIconPath,
        model = model,
        value = baseValue * uses
    })

    local newRecordId = world.createRecord(draft).id
    local replacement = world.createObject(newRecordId, 1)

    replacement:setScale(obj.scale)
    replacement:teleport(obj.cell, obj.position, obj.rotation)

    core.sendGlobalEvent("GiveKegActivationInterface", {
        object = replacement,
        drink = kegDrinkById[obj.id]
    })

    obj:remove()
end

-- Generates an interaction handler for a specific drink keg
local function makeDrinkHandler(drink)
    return function(object, actor)
        if actor.type ~= types.Player then return true end
        actor:sendEvent("KegstandMod_checkTheft_eqnx", {
            keg = object,
            drink = drink,
            actor = actor,
        })
        return false
    end
end

-- Core logic: attempt to fill a bottle with a drink (via steal or buy)
local function handleKegDrink(actor, keg, drink, stolen)
    local inv = types.Actor.inventory(actor)
    local emptyBottle
    for _, item in ipairs(inv:getAll()) do
        if bottleWhitelist[item.recordId:lower()] then
            emptyBottle = item
            break
        end
    end

    if not emptyBottle then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = "You need an empty bottle.",
            fail = true
        })
        return
    end

    local rec = types.Potion.record(drink.id)
    local baseValue = rec and rec.value or 10
    local usesLeft = getRemainingUses(keg, baseValue)

    if usesLeft <= 0 then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = "The keg is empty.",
            fail = true
        })
        return
    end

    emptyBottle:remove(1)
    world.createObject(drink.id, 1):moveInto(inv)
    setRemainingUses(keg, baseValue, usesLeft - 1, drink.name)

    if stolen then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = string.format("Glug glug... You fill the %s with %s.",
                types.Miscellaneous.record(emptyBottle).name,
                drink.name
            )
        })
    end
end

-- Called when keg object is added to world; replaces it with usable keg
local function onObjectActive(obj)
    local id = obj.recordId:lower()

    -- Check if keg should be replaced
    if shouldReplace(obj) then
        -- Delay to allow other mods (e.g., Devilish Needs) to override first
        async:newUnsavableSimulationTimer(0.1, function()
            -- Ensure the object still exists
            if not obj:isValid() or obj.enabled == false then return end

            local selectedDrink = pickRandomDrink()
            local drinkRec = types.Potion.record(selectedDrink.id)
            local baseValue = drinkRec and drinkRec.value or 10

            local record = obj.type == types.Static and types.Static.record(obj.recordId)
                        or obj.type == types.Activator and types.Activator.record(obj.recordId)
            local model = record and record.model or "meshes/f/furn_com_kegstand.nif"

            local useCount = selectedDrink.rarity == "empty" and 0 or math.random(4, 24)
            local draft = types.Miscellaneous.createRecordDraft({
                name = selectedDrink.name .. " Kegstand",
                weight = 0,
                icon = kegIconPath,
                model = model,
                value = baseValue * useCount
            })

            local newRecId = world.createRecord(draft).id
            local newObj = world.createObject(newRecId, 1)

            newObj.enabled = obj.enabled
            newObj:setScale(obj.scale)
            newObj:teleport(obj.cell, obj.position, obj.rotation)

            kegModelById[newObj.id] = model
            core.sendGlobalEvent("GiveKegActivationInterface", {
                object = newObj,
                drink = selectedDrink
            })

            obj:remove()
        end)
    end
end


-- Assigns the activation handler for a newly created drink keg
local function giveKegActivationInterface(data)
    kegDrinkById[data.object.id] = data.drink
    interface.Activation.addHandlerForObject(data.object, makeDrinkHandler(data.drink))
end

-- Handles buying a drink legally (used if player is not sneaking or detected)
local function handleBuyDrink(data)
    local actor, keg, drink = data.actor, data.keg, data.drink
    local inv = types.Actor.inventory(actor)

    local emptyBottle
    for _, item in ipairs(inv:getAll()) do
        if bottleWhitelist[item.recordId:lower()] then
            emptyBottle = item
            break
        end
    end

    if not emptyBottle then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = "You need an empty bottle.",
            fail = true
        })
        return
    end

    local rec = types.Potion.record(drink.id)
    local baseValue = rec and rec.value or 10
    local usesLeft = getRemainingUses(keg, baseValue)

    if usesLeft <= 0 then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = "The keg is empty.",
            fail = true
        })
        return
    end

    local cost = baseValue
    local goldItem
    for _, item in ipairs(inv:getAll()) do
        if item.recordId == "gold_001" then
            goldItem = item
            break
        end
    end

    if not goldItem or goldItem.count < cost then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = "You don't have enough gold.",
            fail = true
        })
        return
    end

    if data.seller and types.NPC.inventory(data.seller) then
        -- Transfer gold to the seller NPC
        local goldStack = world.createObject("gold_001", cost)
        goldStack:moveInto(types.NPC.inventory(data.seller))
    else
        -- No seller (fallback): remove gold silently
        goldItem:remove(cost)
    end

    actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
        msg = data.seller
            and string.format("You buy a pint of %s from %s for %d gold.",
                    drink.name,
                    types.NPC.record(data.seller).name,
                    cost)
            or string.format("You buy a pint of %s for %d gold.", drink.name, cost)
    })

    core.sendGlobalEvent("KegstandMod_resumeDrink_eqnx", {
        actor = actor,
        keg = keg,
        drink = drink,
        stolen = false,
    })
end

-- Main API export
return {
    engineHandlers = {
        onObjectActive = onObjectActive
    },
    eventHandlers = {
        GiveKegActivationInterface = giveKegActivationInterface,
        KegstandMod_buyDrink_eqnx = handleBuyDrink,
        KegstandMod_commitTheft_eqnx = function(data)
            Crimes.commitCrime(data.player, {
                arg = data.value or 0,
                victim = data.victim,
                type = 5
            })
        end,
        KegstandMod_resumeDrink_eqnx = function(data)
            handleKegDrink(data.actor, data.keg, data.drink, data.stolen)
        end
    }
}

