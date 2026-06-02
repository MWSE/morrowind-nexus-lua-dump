-- kegstand_g.lua
local world     = require("openmw.world")
local core      = require("openmw.core")
local types     = require("openmw.types")
local interface = require("openmw.interfaces")
local async     = require("openmw.async")

local Crimes = interface.Crimes

local activeMods = {
    base          = true,
    devilishNeeds = types.Activator.record("detd_Furn_Com_Kegstand") ~= nil,
    kegDrip       = types.Activator.record("furn_com_kegstand_dr")   ~= nil,
}

local kegModRules = {
    base = {
        kegIds = {
            ["furn_com_kegstand"] = true,
            ["furn_de_kegstand"]  = true,
        },
    },
    kegDrip = {
        kegIds = {
            ["furn_com_kegstand_dr"] = true,
            ["furn_de_kegstand_dr"]  = true,
        },
    },
    devilishNeeds = {
        kegIds = {
            ["detd_furn_com_kegstand"] = true,
        },
    },
}

local kegDrinkById   = {}
local kegModelById   = {}
local overlaySpawned = {}  -- original obj.id -> true, prevents double-spawn on cell reload
local kegIconPath  = "icons/usable-kegstands/kegstand.tga"

local bottleWhitelist = {
    ["misc_com_bottle_01"]          = true,
    ["misc_com_bottle_02"]          = true,
    ["misc_com_bottle_03"]          = true,
    ["misc_com_bottle_04"]          = true,
    ["misc_com_bottle_05"]          = true,
    ["misc_com_bottle_06"]          = true,
    ["misc_com_bottle_07"]          = true,
    ["misc_com_bottle_07_float"]    = true,
    ["misc_com_bottle_08"]          = true,
    ["misc_com_bottle_09"]          = true,
    ["misc_com_bottle_10"]          = true,
    ["misc_com_bottle_11"]          = true,
    ["misc_com_bottle_12"]          = true,
    ["misc_com_bottle_13"]          = true,
    ["misc_com_bottle_14"]          = true,
    ["misc_com_bottle_14_float"]    = true,
    ["misc_com_bottle_15"]          = true,
    ["misc_com_metal_goblet_01"]    = true,
    ["misc_com_metal_goblet_02"]    = true,
    ["misc_de_goblet_01"]           = true,
    ["misc_de_goblet_02"]           = true,
    ["misc_de_goblet_03"]           = true,
    ["misc_de_goblet_04"]           = true,
    ["misc_de_goblet_05"]           = true,
    ["misc_de_goblet_06"]           = true,
    ["misc_de_goblet_07"]           = true,
    ["misc_de_goblet_08"]           = true,
    ["misc_de_goblet_09"]           = true,
    ["misc_de_glass_green_01"]      = true,
    ["misc_com_pitcher_metal_01"]   = true,
    ["misc_com_redware_pitcher"]    = true,
    ["misc_de_pitcher_01"]          = true,
    ["misc_imp_silverware_cup"]     = true,
    ["misc_imp_silverware_cup_01"]  = true,
    ["misc_imp_silverware_pitcher"] = true,
    ["misc_com_tankard_01"]         = true,
    ["misc_de_tankard_01"]          = true,
    ["misc_de_glass_yellow_01"]     = true,
    ["misc_com_redware_flask"]      = true,
    ["misc_flask_01"]               = true,
    ["misc_flask_02"]               = true,
    ["misc_flask_03"]               = true,
    ["misc_flask_04"]               = true,
    ["misc_com_bucket_01"]          = true,
    ["misc_com_bucket_01_float"]    = true,
    ["misc_com_bucket_metal"]       = true,
    ["misc_beaker_01"]              = true,
}

local kegDrinkVariants = {
    { id = "potion_empty_placeholder",  name = "Empty",             rarity = "empty"     },
    { id = "potion_comberry_wine_01",   name = "Shein",             rarity = "common"    },
    { id = "Potion_Local_Brew_01",      name = "Mazte",             rarity = "common"    },
    { id = "potion_comberry_brandy_01", name = "Greef",             rarity = "common"    },
    { id = "Potion_Cyro_Whiskey_01",    name = "Flin",              rarity = "very_rare" },
    { id = "potion_cyro_brandy_01",     name = "Cyrodiilic Brandy", rarity = "very_rare" },
    { id = "potion_local_liquor_01",    name = "Sujamma",           rarity = "rare"      },
}

if activeMods.devilishNeeds then
    table.insert(kegDrinkVariants, {
        id = "detd_goodpotwater", name = "Water", rarity = "common"
    })
end

local function shouldReplace(obj)
    local id = obj.recordId:lower()
    for mod, rule in pairs(kegModRules) do
        if activeMods[mod] and rule.kegIds[id] then return true end
    end
    return false
end

local function pickRandomDrink()
    local roll   = math.random()
    local rarity
    if     roll <= 0.10 then rarity = "empty"
    elseif roll <= 0.15 then rarity = "rare"
    elseif roll <= 0.99 then rarity = "common"
    else                     rarity = "very_rare"
    end
    local pool = {}
    for _, d in ipairs(kegDrinkVariants) do
        if d.rarity == rarity then table.insert(pool, d) end
    end
    return pool[math.random(#pool)]
end

local function makeKegName(drinkName, uses)
    if uses <= 0 then return "Empty Kegstand" end
    return string.format("%s Kegstand (%d)", drinkName, uses)
end

local function usesFromKegName(recName)
    local n = recName:match("%((%d+)%)$")
    return n and tonumber(n) or 0
end

local function getRemainingUses(obj)
    local rec = types.Miscellaneous.record(obj.recordId)
    if not rec then return 0 end
    return usesFromKegName(rec.name)
end

local function drinkFromKegName(recName)
    if recName == "Empty Kegstand" then
        return { id = "potion_empty_placeholder", name = "Empty", rarity = "empty" }
    end
    local drinkName = recName:gsub("%s*%(%d+%)$", ""):match("^(.+) Kegstand$")
    if not drinkName then return nil end
    for _, d in ipairs(kegDrinkVariants) do
        if d.name == drinkName then return d end
    end
    return nil
end

local function makeDrinkHandler(drink)
    return function(object, actor)
        if actor.type ~= types.Player then return true end
        actor:sendEvent("KegstandMod_checkTheft_eqnx", {
            keg   = object,
            drink = drink,
            actor = actor,
        })
        return false
    end
end

local function giveKegActivationInterface(data)
    kegDrinkById[data.object.id] = data.drink
    interface.Activation.addHandlerForObject(data.object, makeDrinkHandler(data.drink))
end

local function setRemainingUses(obj, uses, label, drink)
    local model      = kegModelById[obj.id] or "meshes/f/furn_com_kegstand.nif"
    local potRec     = drink and types.Potion.record(drink.id)
    local drinkPrice = potRec and potRec.value or 0

    local draft = types.Miscellaneous.createRecordDraft({
        name   = makeKegName(label, uses),
        weight = 0,
        icon   = kegIconPath,
        model  = model,
        value  = drinkPrice,
    })

    local newObj = world.createObject(world.createRecord(draft).id, 1)
    newObj:setScale(obj.scale)
    newObj:teleport(obj.cell, obj.position, obj.rotation)

    core.sendGlobalEvent("GiveKegActivationInterface", {
        object = newObj,
        drink  = kegDrinkById[obj.id],
    })

    obj:remove()
end

local function handleKegDrink(actor, keg, drink, stolen)
    local inv = types.Actor.inventory(actor)
    local emptyBottle
    for _, item in ipairs(inv:getAll()) do
        if bottleWhitelist[item.recordId:lower()] then emptyBottle = item; break end
    end

    if not emptyBottle then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", { msg = "You need an empty bottle.", fail = true })
        return
    end

    local usesLeft = getRemainingUses(keg)
    if usesLeft <= 0 then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", { msg = "The keg is empty.", fail = true })
        return
    end

    local bottleName = types.Miscellaneous.record(emptyBottle.recordId).name
    emptyBottle:remove(1)
    world.createObject(drink.id, 1):moveInto(inv)
    setRemainingUses(keg, usesLeft - 1, drink.name, drink)

    if stolen then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = string.format("Glug glug... You fill the %s with %s.", bottleName, drink.name)
        })
    end
end

local function onObjectActive(obj)
    -- CASE 1: our Misc overlay loading from a save — re-register handler
    if obj.type == types.Miscellaneous then
        local rec = types.Miscellaneous.record(obj.recordId)
        if rec and rec.icon == kegIconPath then
            local drink = drinkFromKegName(rec.name)
            if drink then
                kegModelById[obj.id] = rec.model or "meshes/f/furn_com_kegstand.nif"
                core.sendGlobalEvent("GiveKegActivationInterface", { object = obj, drink = drink })
            end
        end
        return
    end

    -- CASE 2: original keg — spawn Misc overlay on top, leave original untouched
    if not shouldReplace(obj) then return end

    async:newUnsavableSimulationTimer(0.1, function()
        if not obj:isValid() then return end

        -- Guard: don't spawn a second overlay on cell reload within the same session.
        if overlaySpawned[obj.id] then return end
        overlaySpawned[obj.id] = true

        local record =
            (obj.type == types.Static    and types.Static.record(obj.recordId))   or
            (obj.type == types.Activator and types.Activator.record(obj.recordId)) or
            nil
        local model = record and record.model or "meshes/f/furn_com_kegstand.nif"

        local selectedDrink = pickRandomDrink()
        local useCount      = selectedDrink.rarity == "empty" and 0 or math.random(3, 9)
        local potRec        = types.Potion.record(selectedDrink.id)
        local drinkPrice    = potRec and potRec.value or 0

        local draft = types.Miscellaneous.createRecordDraft({
            name   = makeKegName(selectedDrink.name, useCount),
            weight = 0,
            icon   = kegIconPath,
            model  = model,
            value  = drinkPrice,
        })

        local newObj = world.createObject(world.createRecord(draft).id, 1)
        -- Scale up 1% so this Misc's bounding box wraps the underlying Static
        -- and consistently wins the raycast from any angle.
        newObj:setScale(obj.scale * 1.01)
        newObj:teleport(obj.cell, obj.position, obj.rotation)

        kegModelById[newObj.id] = model
        core.sendGlobalEvent("GiveKegActivationInterface", {
            object = newObj,
            drink  = selectedDrink,
        })

        -- Original Static/Activator is intentionally left in place.
        -- Static: provides collision. Activator: harmless duplicate.
        -- The Misc on top handles all interaction.
    end)
end

local function handleBuyDrink(data)
    local actor, keg, drink = data.actor, data.keg, data.drink
    local inv = types.Actor.inventory(actor)

    local emptyBottle
    for _, item in ipairs(inv:getAll()) do
        if bottleWhitelist[item.recordId:lower()] then emptyBottle = item; break end
    end
    if not emptyBottle then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", { msg = "You need an empty bottle.", fail = true })
        return
    end

    local usesLeft = getRemainingUses(keg)
    if usesLeft <= 0 then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", { msg = "The keg is empty.", fail = true })
        return
    end

    local rec  = types.Potion.record(drink.id)
    local cost = rec and rec.value or 10

    local goldItem
    for _, item in ipairs(inv:getAll()) do
        if item.recordId == "gold_001" then goldItem = item; break end
    end
    if not goldItem or goldItem.count < cost then
        actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
            msg = string.format("You don't have enough gold. (Cost: %d gold)", cost), fail = true
        })
        return
    end

    goldItem:remove(cost)

    if data.seller and types.NPC.inventory(data.seller) then
        world.createObject("gold_001", cost):moveInto(types.NPC.inventory(data.seller))
    end

    local sellerName = data.seller and types.NPC.record(data.seller).name
    actor:sendEvent("KegstandMod_UIShowMessage_eqnx", {
        msg = sellerName
            and string.format("You buy a pint of %s from %s for %d gold.", drink.name, sellerName, cost)
            or  string.format("You buy a pint of %s for %d gold.", drink.name, cost)
    })

    core.sendGlobalEvent("KegstandMod_resumeDrink_eqnx", {
        actor = actor, keg = keg, drink = drink, stolen = false,
    })
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive,
    },
    eventHandlers = {
        GiveKegActivationInterface   = giveKegActivationInterface,
        KegstandMod_buyDrink_eqnx    = handleBuyDrink,
        KegstandMod_commitTheft_eqnx = function(data)
            Crimes.commitCrime(data.player, {
                arg = data.value or 0, victim = data.victim, type = 5,
            })
        end,
        KegstandMod_resumeDrink_eqnx = function(data)
            handleKegDrink(data.actor, data.keg, data.drink, data.stolen)
        end,
    },
}
