ZackBridge = require("SmoothMasterIndex.scripts.SmoothMasterIndex.zackbridge")
local BMI_swap = require("SmoothMasterIndex.bmi_swap").interface
local lastChamber = nil
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
    local player = tes3.player
    if player then
        local inventory = player.object.inventory
        for _, stack in pairs(inventory) do
            if stack.object.id == itemId then return true end
        end
        for index, actor in ipairs(tes3.mobilePlayer.friendlyActors) do
            local inventory = actor.inventory
            if not inventory then return false end
            for _, stack in pairs(inventory) do
                if stack.object.id == itemId then return true end
            end
        end
    end
    return false
end
local function activateMan(object, actor)
    if (tes3.player.cell.name ~= "Caldera, Guild of Mages") then return true end
    local playerSneaking = tes3.player.mobile.isSneaking
    if (object.baseObject.id:lower() == "t_com_crystalball_01" or
        object.baseObject.id:lower() == "t_com_crystalballstand_01") then
        if (tes3.player.data.SMI == nil) then tes3.player.data.SMI = {} end
        tes3.player.data.SMI.TpToLevel = 1
        local hasMasterIndex = playerHasItem("index_master")
        if (hasMasterIndex) then
            if (tes3.player.data.SMI and tes3.player.data.SMI.lastChamber) then
                lastChamber = tes3.player.data.SMI.lastChamber
            end
            for index, fort in ipairs(positions) do
                if (fort.cell == lastChamber) then

                    tes3.positionCell({
                        cell = fort.cell,
                        position = tes3vector3.new(fort.x, fort.y, fort.z),
                        orientation = tes3vector3.new(0, 0,
                                                      math.rad(fort.rotation))
                    })
                    tes3.playSound({sound = "Thunder2"})
                end
            end
            return false
        end
    end

    if (object.baseObject.id == "folms mirel") then
        local hasMasterIndex = playerHasItem("index_master")
        if (tes3.player.data.SMI == nil) then tes3.player.data.SMI = {} end
        tes3.player.data.SMI.TpToLevel = 2

        if (playerSneaking and hasMasterIndex) then
            if (tes3.player.data.triedOrbPlace == nil) then
                local obs = BMI_swap.placeOrb()

                tes3.player.data.triedOrbPlace = true
            end
            if (tes3.player.data.SMI and tes3.player.data.SMI.lastChamber) then
                lastChamber = tes3.player.data.SMI.lastChamber
            end
            for index, fort in ipairs(positions) do
                if (fort.cell == lastChamber) then

                    tes3.positionCell({
                        cell = fort.cell,
                        position = tes3vector3.new(fort.x, fort.y, fort.z),
                        orientation = tes3vector3.new(0, 0,
                                                      math.rad(fort.rotation))
                    })
                    tes3.playSound({sound = "Thunder2"})
                end
            end
            return false
        end

    end
end
local calderaPos = {
    {x = 690, y = 555, z = 146, rotation = 90},
    {x = 763, y = 702, z = 412, rotation = 90}
}
local function activateActivator(object, actor)
    for index, fort in ipairs(positions) do
        if (fort.cell == object.cell.name) then
            if (tes3.player.data.SMI == nil) then

                tes3.player.data.SMI = {}
            end
            tes3.player.data.SMI.lastChamber = fort.cell

        end
    end
    for index, fort in ipairs(positions) do

        if (object.id == "active_port_" .. fort.short) then
            local hasIndex = playerHasItem("index_" .. fort.short)
            local hasMasterIndex = playerHasItem("index_master")
            local playerSneaking = tes3.player.mobile.isSneaking
            if (hasMasterIndex and playerSneaking) then
                local level = 2
                if (tes3.player.data.SMI and tes3.player.data.SMI.TpToLevel) then
                    level = tes3.player.data.SMI.TpToLevel
                end
                tes3.positionCell({
                    cell = "Caldera, Guild of Mages",
                    position = tes3vector3.new(calderaPos[level].x,
                                               calderaPos[level].y,
                                               calderaPos[level].z),
                    orientation = tes3vector3.new(0, 0, math.rad(
                                                      calderaPos[level].rotation))
                })
                tes3.playSound({sound = "Thunder2"})
            elseif (hasMasterIndex or hasIndex) then
                tes3.positionCell({
                    cell = fort.cell,
                    position = tes3vector3.new(fort.x, fort.y, fort.z),
                    orientation = tes3vector3.new(0, 0, math.rad(fort.rotation))
                })
                tes3.playSound({sound = "Thunder2"})
            else
                tes3.messageBox("You do not have the Index for this Propylon.")

            end
            for index, fort in ipairs(positions) do
                if (fort.cell == actor.cell.name) then
                    if (tes3.player.data.SMI == nil) then

                        tes3.player.data.SMI = {}
                    end
                    if (fort.cell == "Indoranyon, Propylon Chamber" and
                        tes3.player.data.SMI.IndoryFixed == nil) then
                        BMI_swap.swapBroken(fort.cell)
                        --   print("Fixing Indory")
                        tes3.player.data.SMI.IndoryFixed = true
                    end
                    if (fort.cell == "Andasreth, Propylon Chamber" and
                        tes3.player.data.SMI.AndaFixed == nil) then
                        BMI_swap.swapBroken(fort.cell)
                        tes3.player.data.SMI.AndaFixed = true
                        --  print("Fixing ANda")
                    end

                end
            end
            return false
        end
    end
end
ZackBridge.AddObjectTypeActivationHandler("Activator", activateActivator)
ZackBridge.AddObjectTypeActivationHandler("Miscellaneous", activateMan)
ZackBridge.AddObjectTypeActivationHandler("NPC", activateMan)
local function onSave() return {lastChamber = lastChamber} end
local function onLoad(data) if (data) then lastChamber = data.lastChamber end end
