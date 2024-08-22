local daedraMarkerId = "zhac_hestatur_daedramarker"
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")

local config = require("scripts.Hestatur.config")
local daedraMarkers = {}
local daedraRevision = 1
local daedraList = {
    "winged twilight",
    "scamp",
    "hunger",
    "golden saint",
    "dremora",
   -- "ab_dae_darkseducer",
    "daedroth"
}
local daedraId
local barrierBroken = false
local gateOpened = false
local function getGuardId()
    local randomIndex = math.random(#daedraList) -- Generate random index
    return daedraList[randomIndex]               -- Return the element at the random index
end
local function setGuardId(id)
    daedraId = id
    daedraRevision = daedraRevision + 1
end --golden saint_summon
local function getGuardItems()
    local items = {
        "torch_infinite_time",
        "imperial cuirass_armor",
        "imperial_greaves",
        "imperial boots",
        "imperial left gauntlet",
        "imperial right gauntlet",
        "imperial left pauldron",
        "imperial right pauldron",
        "imperial belt",
        "imperial shield",
        "imperial skirt_clothing",
        "imperial broadsword"
    }
    return items
end
local function addGuardItems(daedra)

end
local function getActorInCell(cell, id)
    for index, value in ipairs(cell:getAll()) do
        if value.id == id then
            return value
        end
    end
end
local function onObjectActive(obj)
    if obj.recordId == "zhac_marker_delete" then
        obj:remove()
        core.sendGlobalEvent("runCleanUp")
        types.Player.quests(world.players[1]).zhac_hestatur_conquer:addJournalEntry(60)
    end
    if I.cleanup.isCastleFree() then
        return
    end
    if obj.recordId == daedraMarkerId and not daedraMarkers[obj.id] then
        obj.enabled = false
        local newGuard = world.createObject(getGuardId())
        newGuard:teleport(obj.cell, obj.position, obj.rotation)
        daedraMarkers[obj.id] = {}
        daedraMarkers[obj.id].id = newGuard.id
        daedraMarkers[obj.id].revision = daedraRevision
    elseif obj.recordId == daedraMarkerId and daedraMarkers[obj.id] ~= nil and daedraMarkers[obj.id].revision ~= daedraRevision then
        --print(daedraMarkers[obj.id].revision)
        local obj = getActorInCell(obj.cell, daedraMarkers[obj.id].id)
        if obj then
            obj:remove()
        end
        local newGuard = world.createObject(getGuardId())
        addGuardItems(newGuard)
        newGuard:teleport(obj.cell, obj.position, obj.rotation)
        daedraMarkers[obj.id] = {}
        daedraMarkers[obj.id].id = newGuard.id
        daedraMarkers[obj.id].revision = daedraRevision
    elseif obj.recordId == daedraMarkerId and daedraMarkers[obj.id] ~= nil and daedraMarkers[obj.id].revision == daedraRevision then
    elseif obj.recordId == daedraMarkerId then
    end
end
local function onActorActive(actor)
    for index, obj in ipairs(actor.cell:getAll(types.Activator)) do
        if daedraMarkers[obj.id] and  obj.recordId == daedraMarkerId and daedraMarkers[obj.id].id == actor.id then
            onObjectActive(obj)
        end
    end
end

local function onSave()
    return { daedraMarkers = daedraMarkers, daedraRevision = daedraRevision, gateOpened = gateOpened, barrierBroken =
    barrierBroken, }
end
local function onLoad(data)
    if data then
        daedraMarkers = data.daedraMarkers
        gateOpened = data.gateOpened
        daedraRevision = data.daedraRevision
        barrierBroken = data.barrierBroken
    end
end
local function getOutsideDaedra()
    local cell1 = world.getCellById("Esm3ExteriorCell:6:25")
    local cell2 = world.getCellById("Esm3ExteriorCell:5:25")
    local count = 0
    local ls = {}
    for index, value in ipairs(cell1:getAll(types.Creature)) do
        if value.position.z > 0 and not types.Actor.isDead(value) then
            count = count + 1
            table.insert(ls, value)
        end
    end
    for index, value in ipairs(cell2:getAll(types.Creature)) do
        if value.position.z > 0 and not types.Actor.isDead(value) then
            count = count + 1
            table.insert(ls, value)
        end
    end
    return count, ls
end
local function getInsideDaedra()
    local cell1 = world.getCellById("Esm3ExteriorCell:6:26")
    local count = 0
    local ls = {}
    for index, value in ipairs(cell1:getAll(types.Creature)) do
        if value.position.z > 0 and not types.Actor.isDead(value) and value.position.z < 1460 then
            count = count + 1
            table.insert(ls, value)
        end
    end
    return count, ls
end
local function openCastleGate()
    local player = world.players[1]
    types.Player.quests(world.players[1]).zhac_hestatur_discover:addJournalEntry(30)
    world.mwscript.getGlobalVariables(world.players[1]).spok_ht_portpos = 11
    local count, daedra = getInsideDaedra()
    for index, actor in ipairs(daedra) do
        actor:sendEvent('StartAIPackage', { type = 'Combat', target = player })
    end
    gateOpened = true
end
local function daedraDied()
    if gateOpened then
        return
    end
    local count, ls = getOutsideDaedra()
    if count == 0 then
        openCastleGate()
    else
        --print(count)
    end
end
local function playerHasSoul(soulId)
    local player = world.players[1]
    for index, value in ipairs(types.Actor.inventory(player):getAll(types.Miscellaneous)) do
        local objSoul = types.Miscellaneous.getSoul(value)
        if objSoul and objSoul == soulId then
            return true
        end
    end
    return false
end
local function breakBarrier()
    local cell = world.getCellById("hestatur, great hall")
    for index, value in ipairs(cell:getAll(types.Activator)) do
        if value.recordId:find("zhac_forcefield") then
            value:remove()
        end
        if value.recordId:find("zhac_hestatur_redwall") then
            value:remove()
        end
    end
    barrierBroken = true
end
local function generalDeath()
    local soulCount = 0
        for i = 1, 7, 1 do
            if playerHasSoul("zhac_hestatur_dremgen_" .. tostring(i)) then
                soulCount = soulCount + 1
            end
        end
        if soulCount > 6 then
            types.Player.quests(world.players[1]).zhac_hestatur_conquer:addJournalEntry(30)
        end
end
local function onCellChange_Hest(newId)
    if not barrierBroken and newId == "hestatur, great hall" then
        local soulCount = 0
        for i = 1, 7, 1 do
            if playerHasSoul("zhac_hestatur_dremgen_" .. tostring(i)) then
                soulCount = soulCount + 1
            end
        end
        if soulCount > 6 then
            breakBarrier()
        end
    end
end
local function resurrectDaedra(obj)
    local newDaedra = world.createObject(obj.recordId)
    newDaedra:teleport(obj.cell, obj.position)
    obj:remove()
end
I.Activation.addHandlerForType(types.Miscellaneous, function (obj, actor)
if obj.recordId == "ab_misc_daesigilstone_01" and obj.contentFile and obj.cell.id == "hestatur, great hall" then
    local canFree = true
    local cell = world.getCellById("hestatur, great hall")
    for index, value in ipairs(cell:getAll(types.Creature)) do
        if not types.Actor.isDead(value) and value.recordId ~= "zhac_hest_guide" then
            canFree = false
        end
    end
    if canFree then
      --  obj:remove()
       -- core.sendGlobalEvent("runCleanUp")
       return true
    else
        
    end
return false
end
    
end)

return {
    interfaceName = "daedra",
    interface = {
        getOutsideDaedra = getOutsideDaedra,
    },
    eventHandlers = {
        resurrectDaedra = resurrectDaedra,
        onCellChange_Hest = onCellChange_Hest,
        breakBarrier = breakBarrier,
        daedraDied = daedraDied,
        openCastleGate = openCastleGate,
        generalDeath = generalDeath,
    },
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave = onSave,
        onLoad = onLoad,
        onActorActive = onActorActive,
    }
}
