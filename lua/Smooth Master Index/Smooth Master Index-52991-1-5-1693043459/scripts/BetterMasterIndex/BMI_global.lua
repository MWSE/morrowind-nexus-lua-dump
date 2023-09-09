local types = require("openmw.types")
local world = require("openmw.world")
local core = require("openmw.core")
local acti = require("openmw.interfaces").Activation
local util = require("openmw.util")
local I = require("openmw.interfaces")
local playerSneaking = false
if (core.API_REVISION < 44) then
    error("Better Master Index requires a newer version of OpenMW. Please update.")
end
local strongholdData = {}

local swappedPropylons = false
local triedOrbPlace = false

local function getPlayer()
    for i, ref in ipairs(world.activeActors) do
        if (ref.type == types.Player) then return ref end
    end
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        return rotate
    end
end
local lastChamber = nil
local TpToLevel = 2
local positions = {
    [1] = {
        x = 4097,
        y = 3898,
        z = 12758,
        rotation = 180,
        cell = "Hlormaren, Propylon Chamber",
        short = "hlor"
    },
    [2] = {
        x = 540,
        y = 630,
        z = -368,
        rotation = 270,
        cell = "Andasreth, Propylon Chamber",
        short = "andra"
    },
    [3] = {
        x = 540,
        y = 1024,
        z = -608,
        rotation = 270,
        cell = "Berandas, Propylon Chamber",
        short = "beran"
    },
    [4] = {
        x = 302,
        y = 504,
        z = -368,
        rotation = 270,
        cell = "Falasmaryon, Propylon Chamber",
        short = "falas"
    },
    [5] = {
        x = 410,
        y = 898,
        z = -496,
        rotation = 270,
        cell = "Falensarano, Propylon Chamber",
        short = "falen"
    },
    [6] = {
        x = 489,
        y = 766,
        z = -368,
        rotation = 270,
        cell = "Indoranyon, Propylon Chamber",
        short = "indo"
    },
    [7] = {
        x = 244,
        y = 888,
        z = -368,
        rotation = 270,
        cell = "Marandus, Propylon Chamber",
        short = "maran"
    },
    [8] = {
        x = 366,
        y = 628,
        z = -447,
        rotation = -90,
        cell = "Rotheran, Propylon Chamber",
        short = "roth"
    },
    [9] = {
        x = 408,
        y = 767,
        z = -484,
        rotation = 270,
        cell = "Telasero, Propylon Chamber",
        short = "telas"
    },
    [10] = {
        x = 290,
        y = 778,
        z = -496,
        rotation = -90,
        cell = "Valenvaryon, Propylon Chamber",
        short = "valen"
    }
}

local function playerHasItem(itemId)
    if (I.CCC_cont ~= nil) then return I.CCC_cont.itemCarriedByPlayer(itemId) end
    local inInv = types.Actor.inventory(getPlayer()):find(itemId)
    if (inInv) then return true end

    for index, value in ipairs(world.activeActors) do
        --Not sure who is the player's companion, but if anyone has it, it's probably one of the player's followers.
        local inCInv = types.Actor.inventory(value):find(itemId)
        if inCInv then return true end
    end
    return false
end
local function teleportPlayer(actor, cell, pos, rot)
    if actor.type == types.Player then
        
        for index, value in ipairs(world.activeActors) do
            
            value:sendEvent("teleportFollower",
            { destPos = pos, destCell = cell, destRot =rot })
        end
    end
    actor:teleport(cell,
        pos, {
            rotation = rot,
            onGround = true
        })
end
local function activateMan(object, actor)
    if (object.cell.name ~= "Caldera, Guild of Mages") then
        return
    end
    if (object.recordId == "t_com_crystalball_01" or object.recordId == "t_com_crystalballstand_01") then
        TpToLevel = 1
        local hasMasterIndex = playerHasItem("index_master")
        if (hasMasterIndex) then
            for index, fort in ipairs(positions) do
                if (fort.cell == lastChamber) then
                    actor:sendEvent("BMIPlaySound","Thunder2")
                    teleportPlayer(actor, fort.cell, util.vector3(fort.x, fort.y, fort.z),
                        createRotation(0, 0, math.rad(fort.rotation)))
                end
            end
            return false
        end
    end

    if (object.recordId == "folms mirel") then
        if (triedOrbPlace == false) then
            local obs = I.zhac_BMI_swap.placeOrb()
            for index, value in ipairs(obs) do
                acti.addHandlerForObject(value, activateMan)
            end
            triedOrbPlace = true
        end
        TpToLevel = 2
        local hasMasterIndex = playerHasItem("index_master")
        if (playerSneaking and hasMasterIndex) then
            for index, fort in ipairs(positions) do
                if (fort.cell == lastChamber) then
                    actor:sendEvent("BMIPlaySound","Thunder2")
                    teleportPlayer(actor, fort.cell, util.vector3(fort.x, fort.y, fort.z),
                        createRotation(0, 0, math.rad(fort.rotation)))
                end
            end
            return false
        end
    end
end

local calderaPos = {
    { x = 690, y = 555, z = 146, rotation = 90 },
    { x = 763, y = 702, z = 412, rotation = 90 }
}
local function activatePort(object, actor)
    for index, fort in ipairs(positions) do
        if (fort.cell == object.cell.name) then
            lastChamber = fort.cell
        end
        if (object.recordId == "active_port_" .. fort.short) then
            --  local newOb = removeScript(object)
            local hasIndex = playerHasItem("index_" .. fort.short)
            local hasMasterIndex = playerHasItem("index_master")

            if (playerSneaking and hasMasterIndex) then
                actor:sendEvent("BMIPlaySound","Thunder2")
                teleportPlayer(actor, "Caldera, Guild of Mages", util.vector3(calderaPos[TpToLevel].x,
                    calderaPos[TpToLevel].y,
                    calderaPos[TpToLevel].z), createRotation(0, 0, math.rad(calderaPos[TpToLevel].rotation)))
            elseif (hasIndex or hasMasterIndex) then
                actor:sendEvent("BMIPlaySound","Thunder2")
                teleportPlayer(actor, fort.cell, util.vector3(fort.x, fort.y, fort.z),
                    createRotation(0, 0, math.rad(fort.rotation)))
            else
                actor:sendEvent("BMIShowMessage",
                    "You do not have the Index for this Propylon.")
            end
              print(object.recordId)
            return false
        end
    end
    return false
end
local swapDone = false
local errorState = false
local function onSave()
    return
    { lastChamber = lastChamber, TpToLevel = TpToLevel, triedOrbPlace = triedOrbPlace, swapDone = swapDone, }
end

local function onPlayerAdded(player)
    if (errorState) then
        getPlayer():sendEvent("BMIShowMessage",
            "Propylons have their script active! You must check the ")
    end
    if (swapDone == false) then
        I.zhac_BMI_swap.swapBroken()

        swapDone = true
    end
end
local function onInit()
    for index, fort in ipairs(positions) do
        local cxell = world.getCellByName(fort.cell)
        for x, object in ipairs(cxell:getAll(types.Activator)) do
            for l, tfort in ipairs(positions) do
                if (object.recordId == "active_port_" .. tfort.short) then
                   
                    --  local newOb = removeScript(object)
                    acti.addHandlerForObject(object, activatePort)
                    --  print(object.recordId)
                end
            end
        end
    end
    local cmages = world.getCellByName("Caldera, Guild of Mages")
    for index, object in ipairs(cmages:getAll(types.NPC)) do
        if (object.recordId == "folms mirel") then
            acti.addHandlerForObject(object, activateMan)
        end
    end
    acti.addHandlerForType(types.Miscellaneous, activateMan)
    --  for index, object in ipairs(cmages:getAll(types.Miscellaneous)) do
    --    if (object.recordId == "t_com_crystalball_01" or object.recordId == "t_com_crystalballstand_01") then
    --
    --   end
    --end
    -- acti.addHandlerForType(types.Activator,activatePort)
end
local function onLoad(data)
    if (data) then
        lastChamber = data.lastChamber
        TpToLevel = data.TpToLevel
        triedOrbPlace = data.triedOrbPlace
        swapDone = data.swapDone
    end
    onInit()
end
local function BMI_TeleportToCell(data)
    --Simple function to teleport an object to any cell.

    if (data.cellname.name ~= nil) then
        data.cellname = data.cellname.name
    end
    data.item:teleport(data.cellname, data.position, data.rotation)
end
local function CCCSneakUpdate(val) playerSneaking = val; print(val);end
return {
    interfaceName = "zhac_BMI",
    interface = {
        version = 1,
        onInit = onInit,
        activatePort = activatePort
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onPlayerAdded = onPlayerAdded
    },
    eventHandlers = {
        BMISneakUpdate = CCCSneakUpdate,
        BMI_TeleportToCell = BMI_TeleportToCell
    }
}
