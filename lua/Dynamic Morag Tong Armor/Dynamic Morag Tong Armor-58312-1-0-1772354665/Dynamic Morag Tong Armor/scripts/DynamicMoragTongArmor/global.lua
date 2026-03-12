local world = require("openmw.world")
local types = require("openmw.types")

-- Mods to not give armor to
local modBlacklist = {}

-- NPCs to not give armor to
local actorBlacklist = {}

-- Factions that will be checked to apply the armor to
local supportedFactions = {
    ["morag tong"] = true,
}

-- Armor pieces IDs
local helmet = "morag_tong_helm"
local cuirass = "NX9_Tong_Cuirass"
local leftPauldron = "NX9_Tong_Pauldron_L"
local rightPauldron = "NX9_Tong_Pauldron_R"
local greaves = "NX9_Tong_Greaves"
local boots = "NX9_Tong_Boots"
local leftGauntlet = "NX9_Tong_Gauntlet_L"
local rightGauntlet = "NX9_Tong_Gauntlet_R"

-- Clothing pieces IDs
local robe = "common_robe_03_b"
local leftGlove = "common_glove_l_moragtong"
local rightGlove = "common_glove_r_moragtong"
local skirt = "Ros_mtar_skirt"

-- Pieces by slots
local helmetBySlot = {
    [types.Actor.EQUIPMENT_SLOT.Helmet] = helmet
}
local cuirassBySlot = {
    [types.Actor.EQUIPMENT_SLOT.Cuirass] = cuirass
}
local leftPauldronBySlot = {
    [types.Actor.EQUIPMENT_SLOT.LeftPauldron] = leftPauldron
}
local rightPauldronBySlot = {
    [types.Actor.EQUIPMENT_SLOT.RightPauldron] = rightPauldron
}
local greavesBySlot = {
    [types.Actor.EQUIPMENT_SLOT.Greaves] = greaves
}
local bootsBySlot = {
    [types.Actor.EQUIPMENT_SLOT.Boots] = boots
}
local leftGauntletBySlot = {
    [types.Actor.EQUIPMENT_SLOT.LeftGauntlet] = leftGauntlet
}
local rightGauntletBySlot = {
    [types.Actor.EQUIPMENT_SLOT.RightGauntlet] = rightGauntlet
}
local robeBySlot = {
    [types.Actor.EQUIPMENT_SLOT.Robe] = robe
}
local leftGloveBySlot = {
    [types.Actor.EQUIPMENT_SLOT.LeftGauntlet] = leftGlove
}
local rightGloveBySlot = {
    [types.Actor.EQUIPMENT_SLOT.RightGauntlet] = rightGlove
}
local skirtBySlot = {
    [types.Actor.EQUIPMENT_SLOT.Skirt] = skirt
}

-- Sets by ranks (each rank has a specific armor set)
local armorSetsByRank = {
    --  No gear at the lowest rank
    [2] = { cuirassBySlot, greavesBySlot, bootsBySlot },
    [3] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGloveBySlot, rightGloveBySlot },
    [4] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGauntletBySlot, rightGauntletBySlot },
    [5] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGauntletBySlot, rightGauntletBySlot, skirtBySlot},
    [6] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGauntletBySlot, rightGauntletBySlot, skirtBySlot, leftPauldronBySlot, rightPauldronBySlot },
    [7] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGauntletBySlot, rightGauntletBySlot, skirtBySlot, leftPauldronBySlot, rightPauldronBySlot, helmetBySlot },
    [8] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGauntletBySlot, rightGauntletBySlot, leftPauldronBySlot, rightPauldronBySlot, robeBySlot },
    [9] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGauntletBySlot, rightGauntletBySlot, leftPauldronBySlot, rightPauldronBySlot, robeBySlot },
    [10] = { cuirassBySlot, greavesBySlot, bootsBySlot, leftGauntletBySlot, rightGauntletBySlot, leftPauldronBySlot, rightPauldronBySlot, robeBySlot },
}

-- A list of NPCs that the script already did its magic for
local processedNPCs = {}

-- We'll store the current actor's equipment here
local currentEquipment

-- Remove the thing from its container and delete it
local function deleteObject(obj)
    obj.enabled = false
    obj:remove(1)
end

local function unequipItem(actor, slot)
    actor:sendEvent("dynamicMoragTongArmor_equipItem", { slot = slot, itemObject = nil })
end

-- Try to replace the armor piece in the chosen slot
local function replaceItem(actor, slot, itemId)
    local equippedItem = currentEquipment[slot]

    -- Simply remove the item from this slot
    if itemId == nil then
        unequipItem(actor, slot)
        return
    end

    -- Create the new item
    local newItem = world.createObject(itemId)

    -- Give this NPC the new item
    newItem:moveInto(actor.type.inventory(actor))
    actor:sendEvent("dynamicMoragTongArmor_equipItem", { slot = slot, itemObject = newItem })

    -- Get rid of the previosuly equipped item if there was one
    if equippedItem ~= nil then
        deleteObject(equippedItem)
    end
end

local function setItemsByRank(actor, faction)
    -- Get actor's faction rank
    local factionRank = actor.type.getFactionRank(actor, faction)

    if factionRank == nil then
        return
    end

    -- Make sure there are no other skirts/robes equipped, also make sure robes are not worn together with skirts
    replaceItem(actor, types.Actor.EQUIPMENT_SLOT.Skirt, nil)
    replaceItem(actor, types.Actor.EQUIPMENT_SLOT.Robe, nil)

    for _, armorPieceBySlot in pairs(armorSetsByRank[factionRank]) do
        local slot, itemId = next(armorPieceBySlot)
        
        if slot then
            replaceItem(actor, slot, itemId)
         end
    end
end

local function onActorActive(actor)
    -- Already processed
    if processedNPCs[actor.id] then
        return           
    end

    -- Don't dress an actor from a blacklisted mod
    if modBlacklist[actor.contentFile] then
        processedNPCs[actor.id] = true
        return
    end

    -- Don't dress a blacklisted actor
    if actorBlacklist[actor.recordId] then
        processedNPCs[actor.id] = true
        return
    end

    -- Don't dress an actor without a faction
    if actor.type.getFactions == nil then
        processedNPCs[actor.id] = true
        return
    end

    -- Don't dress an actor not in the supported faction
    local foundFactionMember = false
    local actorFaction

    for _, faction in pairs(actor.type.getFactions(actor)) do
        if supportedFactions[faction] and not foundFactionMember then
            foundFactionMember = true
            actorFaction = faction
            break
        end
    end

    if not foundFactionMember then
        processedNPCs[actor.id] = true
        return
    end

    -- We passed all the checks, so let's start with getting equipment of the actor
    currentEquipment = actor.type.equipment(actor)

    -- Replace equipment
    actor:sendEvent("dynamicMoragTongArmor_startEquipProcess")
    setItemsByRank(actor, actorFaction)
    
    -- Pretty much done!
    actor:sendEvent("dynamicMoragTongArmor_finishEquipProcess")
    processedNPCs[actor.id] = true
end

local function onLoad(data)
    processedNPCs = data.processedNPCs
end

local function onSave()
    return { processedNPCs = processedNPCs }
end

local function addModToBlacklist(pluginNames)
    for _, name in pairs(pluginNames) do
        modBlacklist[string.lower(name)] = true
    end
end

local function addActorToBlacklist(actorIds)
    for _, id in pairs(actorIds) do
        actorBlacklist[string.lower(id)] = true
    end
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onLoad = onLoad,
        onSave = onSave
    },
    interfaceName = "DynamicMoragTongArmor",
    interface = {
        AddActorToBlacklist = addActorToBlacklist,
        AddModToBlacklist = addModToBlacklist
    }
}
