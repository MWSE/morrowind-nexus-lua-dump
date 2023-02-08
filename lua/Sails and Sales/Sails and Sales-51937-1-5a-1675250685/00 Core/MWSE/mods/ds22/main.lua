local boats
local travelDestinations
local tradegoods = require("ds22\\tradegoods")
local prices = require("ds22\\prices")
local function initializedData()
    boats = {
        gondola01 = {
            bodyPart = "ds22_com_gondola_ship",
            activator = "ds22_act_gondola_01",
            misc = nil,
            animation = "ds22\\anim\\gondola.nif",
            container = "ds22_gondola_cargo",
            rotation = 0,
            cameraOffset = -500,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "Gondola",
            journalTopic = "ds22_get_gondola",
            journalIndex = 1,
            replaceStatic = nil,
            initpos = {33018, -87192, 25},
            initori = {0, 0, 0}
        },
        longboat01 = {
            bodyPart = "ds22_com_longboat_ship",
            activator = "ds22_act_longboat",
            misc = nil,
            animation = "ds22\\anim\\longboat.nif",
            container = "ds22_longboat_cargo",
            rotation = 0,
            cameraOffset = -1000,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "Longboat",
            journalTopic = "ds22_get_sailboat",
            journalIndex = 1,
            replaceStatic = nil,
            initpos = {-18456, -68954, 74},
            initori = {0, 0, 205}
        },
        midlongboat = {
            bodyPart = "ds22_com_mid_longboat_ship",
            activator = "ds22_act_mid_longboat",
            misc = nil,
            animation = "ds22\\anim\\longboat.nif",
            container = "ds22_midrow_cargo",
            rotation = 0,
            cameraOffset = -1000,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "Medium Longboat",
            journalTopic = "ds22_get_mid_longboat",
            journalIndex = 1,
            replaceStatic = nil,
            initpos = {141339, 33550, 50},
            initori = {0, 0, 205}
        },
        nordboat = {
            bodyPart = "ds22_com_nord_longboat_ship",
            activator = "ds22_act_nord_longboat",
            misc = nil,
            animation = "ds22\\anim\\longboat.nif",
            container = "ds22_rnordboatt_cargo",
            rotation = 0,
            cameraOffset = -1000,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "Nordic Longboat",
            journalTopic = "ds22_get_nord_longboat",
            journalIndex = 1,
            replaceStatic = nil,
            initpos = {-59382, 20383, 84},
            initori = {0, 0, 137}
        },
        sailboat = {
            bodyPart = "ds22_com_sailboat_ship",
            activator = "ds22_act_sailboat",
            misc = nil,
            animation = "ds22\\anim\\sailboat.nif",
            container = "ds22_sailboat_cargo",
            rotation = 0,
            cameraOffset = -800,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "Sailboat",
            journalTopic = "ds22_crew_vanj",
            journalIndex = 40,
            replaceStatic = nil,
            initpos = {64009, -71999, 18},
            initori = {0, 0, 308}
        },
        skiff = {
            bodyPart = "ds22_com_skiff_ship",
            activator = "ds22_act_skiff",
            misc = nil,
            animation = "ds22\\anim\\skiff.nif",
            container = "ds22_skiff_cargo",
            rotation = math.pi,
            cameraOffset = -600,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "Skiff",
            journalTopic = "ds22_crew_izza2",
            journalIndex = 60,
            replaceStatic = nil,
            initpos = {23856, -102158, 2},
            initori = {0, 0, 0}
        },
        rowboat_01 = {
            bodyPart = "ds22_rowboat_01",
            activator = "ds22_act_rowboat",
            misc = "ds22_Misc_rowboat_01",
            animation = "ds22\\anim\\rowboat.nif",
            container = "ds22_rowboat_cargo",
            rotation = math.pi,
            cameraOffset = -100,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = true,
        },
        rowboat_02 = {
            bodyPart = "ds22_rowboat_02",
            activator = "ds22_act_rowboat_02",
            misc = "ds22_Misc_rowboat_02",
            animation = "ds22\\anim\\rowboat.nif",
            container = "ds22_rowboat_02_cargo",
            rotation = 0,
            cameraOffset = -100,
            zOffset = 0,
            frontBackOffset = 0,
            isRowboat = true,
        },
        dunmer_ship = {
            bodyPart = "ds22_dunmer_ship",
            activator = "ds22_act_dunmer_ship",
            misc = nil,
            animation = "ds22\\anim\\large_ship.nif",
            container = "ds22_dunmer_ship_cargo",
            rotation = 0,
            cameraOffset = -2000,
            zOffset = 250,
            frontBackOffset = -200,
            isRowboat = false,
            remoteCabinDoor = "ds22_remote_cabin_door",
            remoteUpperDoor = "ds22_remote_upper_door",
            intCabinDoor = "ds22_in_de_cabindoor",
            intUpperDoor = "ds22_ex_de_ship_trapdoor",
            shipName = "Alessia's Revenge",
            journalTopic = "ds22_getaboat",
            journalIndex = 100,
            replaceStatic = nil,
            initpos = {62080, 187415, 0},
            initori = {0, 0, 285.5}
        },
        imp_galleon_01 = {
            bodyPart = "ds22_imp_galleon_01",
            activator = "ds22_act_imp_galleon_01",
            misc = nil,
            animation = "ds22\\anim\\large_ship.nif",
            container = "ds22_dunmer_ship_cargo",
            rotation = 0,
            cameraOffset = -2000,
            zOffset = 150,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "UnNamed"
        },
        imp_galleon_02 = {
            bodyPart = "ds22_imp_galleon_02",
            activator = "ds22_act_imp_galleon_02",
            misc = nil,
            animation = "ds22\\anim\\large_ship.nif",
            container = "ds22_dunmer_ship_cargo",
            rotation = 0,
            cameraOffset = -2000,
            zOffset = 150,
            frontBackOffset = 0,
            isRowboat = false,
            remoteCabinDoor = nil,
            remoteUpperDoor = nil,
            intCabinDoor = nil,
            intUpperDoor = nil,
            shipName = "UnNamed"
        }
    }
    travelDestinations = {
        {
            port = "Seyda Neen",
            pos = { -7266.458, -74517, 0 },
            ori = { 0, 0, 3.7}
        },
        {
            port = "Hla Oad",
            pos = { -50308.8671875, -39631.41796875, 0 },
            ori = { 0, 0, 0.98656493425369 }
        },
        {
            port = "Dagon Fel",
            pos = { 61729.125, 185162.09375, 0 },
            ori = { 0, 0, 2.935907125473 }
        },
        {
            port = "Tel Branora",
            pos = { 120438.9375, -101142.4453125, 0 },
            ori = { 0, 0, -2.2708549499512 }
        },
        {
            port = "Vos",
            pos = { 104616.0546875, 113361.0078125, 0 },
            ori = { 0, 0, -0.16966904699802 }
        },
        {
            port = "Wolverine Hall",
            pos = { 149884.828125, 26336.71484375, 0 },
            ori =  { 0, 0, -1.5835883617401 }
        },
        {
            port = "Vivec",
            pos = { 26764.383, -102501.008, 0 },
            ori = { 0, 0, 3.1125140190125 }
        },
        {
            port = "Khuul",
            pos = { -67463.8203125, 143053.625, 0 },
            ori = { 0, 0, 4.399975 }
        },
    }
end
event.register(tes3.event.initialized, initializedData)

local simulateEventRegistered
local function simulateCallback(e)
    if (tes3.player.position.z > -0.5 and tes3.player.data.ds22.goodPosition ~= nil) then
        tes3.positionCell({position = tes3.player.data.ds22.goodPosition})
    else
        tes3.player.data.ds22.goodPosition = tes3.player.position:copy()
    end
end

local function getCargoContainer(ident)
    local cell = tes3.getCell({id = "ToddTest"})
    local cargo
    for ref in cell:iterateReferences({tes3.objectType.container}) do
        if (ref.data.ds22 ~= nil) then
            if (ref.data.ds22.ident == ident) then
                cargo = ref
            end
        end
    end
    return cargo
end


local function displayableCargo(reference)
    local output = {}
    output.oar = 0
    output.crate = 0
    local items = reference.object.inventory.items
    for _, itemstack in pairs(items) do
        if itemstack.object.id == "ds22_oar_useable" then
            output.oar = itemstack.count
        end
        if string.find(itemstack.object.id, "ds22_crate_") then
            output.crate = output.crate + itemstack.count
        end
    end
end

local function displayCargoActivator(reference)
    --first, clear any outdated displays
    if reference.sceneNode.children ~= nil then
        for _, child in pairs(reference.sceneNode.children) do
            reference.sceneNode:detachChild(child)
        end
    end
    local cargoContainer = getCargoContainer(reference.data.ds22.cargoContainerIdent)
    local displayableCargo = displayableCargo(cargoContainer)
    if displayableCargo.oar >= 1 then
        local oar = tes3.loadMesh("x\\Ex_De_Oar.nif")
        local childOar = reference.sceneNode:attachChild(oar)
    end
    if displayableCargo.oar >= 2 then
        local oar = tes3.loadMesh("x\\Ex_De_Oar.nif")
        local childOar = reference.sceneNode:attachChild(oar)
    end
    local n = 1
    while n <= displayableCargo.crate do
        local crate = tes3.loadMesh("ds22\\crate_logo.nif")
        local childCrate = reference.sceneNode:attachChild(crate)
        n = n + 1
    end
end

local function endBoat(e)
    local ori = tes3.player.orientation:copy()
    ori.z = ori.z + tes3.player.data.ds22.currentBoat.rotation
    ori.angle = 0
    local activatorBoat = tes3.createReference({object = tes3.getObject(tes3.player.data.ds22.currentBoat.activator), position = tes3.player.position:copy(), orientation = ori})
    activatorBoat.position.z = 0
    local modifiedPosition = tes3.player.position:copy()
    modifiedPosition = tes3.player.position + (tes3.getPlayerEyeVector() * tes3.player.data.ds22.currentBoat.frontBackOffset)
    modifiedPosition.z = modifiedPosition.z + tes3.player.data.ds22.currentBoat.zOffset
    tes3.positionCell({position = modifiedPosition})
    tes3.loadAnimation({reference = tes3.mobilePlayer})
    --tes3.player.bodyPartManager:updateForReference(tes3.player)
    activatorBoat.data.ds22 = {}
    activatorBoat.data.ds22.cargoContainerIdent = tes3.player.data.ds22.currentCargoContainerIdent
    getCargoContainer(activatorBoat.data.ds22.cargoContainerIdent).data.ds22.cell = tes3.player.cell.id
    activatorBoat.data.ds22.boat = table.deepcopy(tes3.player.data.ds22.currentBoat)
    --[[if tes3.player.data.ds22.currentBoat.isRowboat == false then
        local cabinDoor = tes3.getReference(tes3.player.data.ds22.currentBoat.intCabinDoor)
        local upperDoor = tes3.getReference(tes3.player.data.ds22.currentBoat.intUpperDoor)
        tes3.setDestination({reference = cabinDoor, position = modifiedPosition, orientation = tes3.player.orientation:copy(), cell = tes3.player.cell})
        modifiedPosition = tes3.player.position + (tes3.getPlayerEyeVector() * (tes3.player.data.ds22.currentBoat.frontBackOffset * -1))
        modifiedPosition.z = modifiedPosition.z + tes3.player.data.ds22.currentBoat.zOffset + 50
        ori.z = ori.z + math.pi
        tes3.setDestination({reference = upperDoor, position = modifiedPosition, orientation = ori, cell = tes3.player.cell})
    end ]]--
    --displayCargoActivator(activatorBoat)
    tes3.player.data.ds22.currentCargoContainerIdent = nil
    tes3.player.data.ds22.boatMode = false
    tes3.player.data.ds22.currentBoat = nil
    tes3.player:updateEquipment()
    tes3.mobilePlayer.waterWalking = 0
    event.unregister(tes3.event.simulate, simulateCallback)
    event.unregister(tes3.event.keyDown, endBoat, {filter = tes3.scanCode.space})
    simulateEventRegistered = false
    --tes3.mobilePlayer.attackDisabled = false
    --tes3.mobilePlayer.jumpingDisabled = false
    if tes3.player.data.ds22.prevCamera ~= true then
        tes3.force1stPerson()
    end
    --tes3.mobilePlayer.viewSwitchDisabled = false
    tes3.worldController.flagTeleportingDisabled = tes3.player.data.ds22.prevTeleFlag
    tes3.worldController.flagLevitationDisabled = tes3.player.data.ds22.prevLeviFlag
    tes3.setPlayerControlState({enabled = true, attack = true, jumping = true, magic = true, vanity = true, viewSwitch = true})
    tes3.getInputBinding(tes3.keybind.sneak).code = tes3.player.data.ds22.sneakKey
    tes3.player.data.ds22.sneakKey = nil
    tes3.set3rdPersonCameraOffset({offset = tes3vector3.new(0, 0, 0)})
end

local function startBoat()
    tes3.loadAnimation({reference = tes3.mobilePlayer, file = tes3.player.data.ds22.currentBoat.animation})
    tes3.player.data.ds22.boatMode = true
    tes3.player.data.ds22.goodPosition = tes3.player.position:copy()
    tes3.player:updateEquipment()
    --tes3.player.bodyPartManager:setBodyPartForObject(tes3.player.object, tes3.activeBodyPart.tail, tes3.getObject("ds22_rowboat_01"), false)
    --tes3.player.bodyPartManager:updateForReference(tes3.player)
    tes3.mobilePlayer.waterWalking = 1
    event.register(tes3.event.simulate, simulateCallback)
    simulateEventRegistered = true
    event.register(tes3.event.keyDown, endBoat, {filter=tes3.scanCode.space})
    --tes3.mobilePlayer.attackDisabled = true
    --tes3.mobilePlayer.jumpingDisabled = true
    tes3.player.data.ds22.prevCamera = tes3.mobilePlayer.is3rdPerson
    tes3.force3rdPerson()
    --tes3.mobilePlayer.viewSwitchDisabled = true
    tes3.mobilePlayer.weaponReady = false
    tes3.worldController.flagTeleportingDisabled = true
    tes3.worldController.flagLevitationDisabled = true
    tes3.setPlayerControlState({enabled = true, attack = false, jumping = false, magic = false, vanity = true, viewSwitch = false})
    tes3.mobilePlayer.isSneaking = false
    if (tes3.getInputBinding(tes3.keybind.sneak).code) then tes3.player.data.ds22.sneakKey = tes3.getInputBinding(tes3.keybind.sneak).code end
    tes3.getInputBinding(tes3.keybind.sneak).code = nil
    timer.delayOneFrame(function()
        timer.delayOneFrame(function()
            tes3.set3rdPersonCameraOffset({offset = tes3vector3.new(0, tes3.player.data.ds22.currentBoat.cameraOffset, 0)})
        end)
    end)
end


local function onDropRowboatItem(e)
    if (string.find(e.reference.object.id, "ds22_Misc_rowboat")) then
        if (e.reference.cell.isInterior) then return end
        if (e.reference.position.z >0) then return end
        local droppedBoat
        for _, boat in pairs(boats) do
            if e.reference.object.id == boat.misc then
                droppedBoat = table.deepcopy(boat)
            end
        end
        local pos = e.reference.position:copy()
        local ori = e.reference.orientation:copy()
        e.reference:delete()
        local boat = tes3.createReference({object = tes3.getObject(droppedBoat.activator), position = pos, orientation = ori})
        boat.position.z = 0
        boat.data.ds22 = {}
        local cargoContainer = tes3.createReference({object = tes3.getObject(droppedBoat.container), position = tes3vector3:new(), cell = "ToddTest"})
        cargoContainer.data.ds22 = {}
        cargoContainer.data.ds22.ident = tostring(os.time()) .. tostring(math.random(1000))
        cargoContainer.data.ds22.cell = tes3.player.cell.id
        cargoContainer.data.ds22.name = "Rowboat"
        boat.data.ds22.cargoContainerIdent = cargoContainer.data.ds22.ident
        boat.data.ds22.boat = droppedBoat
    end
end
event.register(tes3.event.itemDropped, onDropRowboatItem)

local function onAltC(e)
    if e.isAltDown == false then return end
    tes3.addItem({reference = tes3.player, item = "ds22_Misc_rowboat_01", showMessage = true})
    tes3.addItem({reference = tes3.player, item = "ds22_oar_useable", count = 2})
end

-- event.register("keyDown", onAltC, {filter=tes3.scanCode.c})

local function onAltV(e)
    if e.isAltDown == false then return end
    tes3.addItem({reference = tes3.player, item = "ds22_Misc_rowboat_02", showMessage = true})
    tes3.addItem({reference = tes3.player, item = "ds22_oar_useable", count = 2})
end

-- event.register("keyDown", onAltV, {filter=tes3.scanCode.v})

local cachedBoat

local function cargoContainerClosed(e)
    displayCargoActivator(cachedBoat)
    cachedBoat = nil
    event.unregister(tes3.event.containerClosed, cargoContainerClosed)
end

local function shipActivate(c, e)
    if c.button == 2 then
        local door = tes3.getReference(e.target.data.ds22.boat.remoteCabinDoor)
        tes3.player:activate(door)
    elseif c.button == 1 then
        local door = tes3.getReference(e.target.data.ds22.boat.remoteUpperDoor)
        tes3.player:activate(door)
    else
        local ori = e.target.orientation
        local playerOri = tes3.player.orientation:copy()
        ori.z = ori.z + e.target.data.ds22.boat.rotation
        ori.angle = 0
        ori.x = playerOri.x
        ori.y = playerOri.y
        tes3.positionCell({position = e.target.position, orientation = ori})
        tes3.player.data.ds22.currentCargoContainerIdent = e.target.data.ds22.cargoContainerIdent
        tes3.player.data.ds22.currentBoat = table.deepcopy(e.target.data.ds22.boat)
        e.target:delete()
        tes3.player.data.ds22.prevTeleFlag = tes3.worldController.flagTeleportingDisabled
        tes3.player.data.ds22.prevLeviFlag = tes3.worldController.flagLevitationDisabled
        startBoat()
    end
end
local function fastTravel(c,e)
    if c.button == 0 then
        return
    end
    tes3.player.data.ds22.currentCargoContainerIdent = e.target.data.ds22.cargoContainerIdent
    tes3.player.data.ds22.currentBoat = table.deepcopy(e.target.data.ds22.boat)
    e.target:delete()
    tes3.player.data.ds22.prevTeleFlag = tes3.worldController.flagTeleportingDisabled
    tes3.player.data.ds22.prevLeviFlag = tes3.worldController.flagLevitationDisabled
    local travelDistance = math.sqrt((tes3.player.position:copy().x - travelDestinations[c.button].pos[1])^2 + (tes3.player.position:copy().y - travelDestinations[c.button].pos[2])^2 )
    local travelTime = travelDistance / tes3.findGMST(tes3.gmst.fTravelTimeMult).value
    tes3.advanceTime({hours = travelTime})
    tes3.positionCell({position = travelDestinations[c.button].pos, orientation = travelDestinations[c.button].ori})
    timer.delayOneFrame(function()
        startBoat()
        timer.delayOneFrame(function()
            timer.delayOneFrame(function()
                endBoat()
            end)
        end)
    end)
end

local function onActivateBoat(e)
    if e.target == nil then return end
    if (not string.find(e.target.object.id, "ds22_act_")) then return end
    if e.target.data.ds22.boat.isRowboat == false then
        if tes3.worldController.inputController:isShiftDown() then
            tes3.player:activate(getCargoContainer(e.target.data.ds22.cargoContainerIdent))
            return
        end
        if tes3.worldController.inputController:isControlDown() then
            local buttons = {"Cancel"}
            for i, data in pairs(travelDestinations) do
                buttons[i+1] = data.port
            end
            tes3.messageBox({message = "Fast Travel", buttons = buttons, callback = function(c) fastTravel(c, e) end })
            return
        end
        local cabinDoor = tes3.getReference(e.target.data.ds22.boat.intCabinDoor)
        local upperDoor = tes3.getReference(e.target.data.ds22.boat.intUpperDoor)
        if (upperDoor == nil and cabinDoor == nil) then
            local ori = e.target.orientation
            local playerOri = tes3.player.orientation:copy()
            ori.z = ori.z + e.target.data.ds22.boat.rotation
            ori.angle = 0
            ori.x = playerOri.x
            ori.y = playerOri.y
            tes3.positionCell({position = e.target.position, orientation = ori})
            tes3.player.data.ds22.currentCargoContainerIdent = e.target.data.ds22.cargoContainerIdent
            tes3.player.data.ds22.currentBoat = table.deepcopy(e.target.data.ds22.boat)
            e.target:delete()
            tes3.player.data.ds22.prevTeleFlag = tes3.worldController.flagTeleportingDisabled
            tes3.player.data.ds22.prevLeviFlag = tes3.worldController.flagLevitationDisabled
            startBoat()
        end
        local position = e.target.position:copy()
        local orientation = e.target.orientation:copy()
        position.z = position.z + e.target.data.ds22.boat.zOffset
        position.x = position.x + 100
        local modifiedOrientation = orientation:copy()
        modifiedOrientation.z = modifiedOrientation.z + math.pi
        local buttons = {}
        buttons[1] = "Pilot Ship"
        if upperDoor ~= nil then
            tes3.setDestination({reference = upperDoor, position = position, orientation = modifiedOrientation, cell = e.target.cell})
            buttons[2] = "Go Below Deck"
        end
        if cabinDoor ~= nil then
            tes3.setDestination({reference = cabinDoor, position = position, orientation = orientation, cell = e.target.cell})
            buttons[3] = "Enter Cabin"
        end
        tes3.messageBox({message = e.target.data.ds22.boat.shipName, buttons = buttons, callback = function(c) shipActivate(c, e) end})
        return
    end
    local cargoContainer = getCargoContainer(e.target.data.ds22.cargoContainerIdent)
    if cargoContainer == nil then tes3.messageBox("Error, try again.") return end
    if tes3.worldController.inputController:isControlDown() then
        for _, itemStack in pairs(cargoContainer.object.inventory.items) do
            tes3.transferItem({from = cargoContainer, to = tes3.player, item = itemStack.object, count = itemStack.count})
        end
        cargoContainer:delete()
        tes3.addItem({reference = tes3.player, item = e.target.data.ds22.boat.misc})
        e.target:delete()
        return
    elseif tes3.worldController.inputController:isShiftDown() then
        tes3.player:activate(cargoContainer)
        --cachedBoat = e.target
        --event.register(tes3.event.containerClosed, cargoContainerClosed)
        return
    else
        if ((tes3.getItemCount({reference = tes3.player, item = "ds22_oar_useable"}) + tes3.getItemCount({reference = cargoContainer, item = "ds22_oar_useable"}))< 2)
        then tes3.messageBox("You need two oars to row.") return end
        local ori = e.target.orientation
        local playerOri = tes3.player.orientation:copy()
        ori.z = ori.z + e.target.data.ds22.boat.rotation
        ori.angle = 0
        ori.x = playerOri.x
        ori.y = playerOri.y
        tes3.positionCell({position = e.target.position, orientation = ori})
        tes3.player.data.ds22.currentCargoContainerIdent = e.target.data.ds22.cargoContainerIdent
        tes3.player.data.ds22.currentBoat = table.deepcopy(e.target.data.ds22.boat)
        e.target:delete()
        tes3.player.data.ds22.prevTeleFlag = tes3.worldController.flagTeleportingDisabled
        tes3.player.data.ds22.prevLeviFlag = tes3.worldController.flagLevitationDisabled
        startBoat()
    end
end

event.register(tes3.event.activate, onActivateBoat)

local function onCargoHoldActivate(e)
    if e.target == nil then return end
    if (not string.find(e.target.object.id, "ds22_cargoAct")) then return end
    local boat = string.sub(e.target.object.id, 15, string.len(e.target.object.id))
    local container = tes3.getReference(boats[boat].container)
    tes3.player:activate(container)
end

event.register(tes3.event.activate, onCargoHoldActivate)
local function onAltB(e)
    if e.isAltDown == false then return end
    tes3.player.data.ds22.currentBoat = table.deepcopy(boats.dunmer_ship)
    local cargoContainer = tes3.createReference({object = tes3.getObject(tes3.player.data.ds22.currentBoat.container), position = tes3vector3:new(), cell = "ToddTest"})
    cargoContainer.data.ds22 = {}
    cargoContainer.data.ds22.ident = tostring(os.time()) .. tostring(math.random(1000))
    cargoContainer.data.ds22.cell = tes3.player.cell.id
    cargoContainer.data.ds22.name = tes3.player.data.ds22.currentBoat.shipName
    tes3.player.data.ds22.currentCargoContainerIdent = cargoContainer.data.ds22.ident
    startBoat()
end

--event.register("keyDown", onAltB, {filter=tes3.scanCode.b})

local function bodyPartAssignedCallback(e)
    if e.reference ~= tes3.player then return end
    if tes3.player.data.ds22 == nil then return end
    if tes3.player.data.ds22.boatMode == false then return end
    if e.index == tes3.activeBodyPart.tail then
        --local tail = e.bodyPart
        --tes3.messageBox(tail)
        e.bodyPart = tes3.getObject(tes3.player.data.ds22.currentBoat.bodyPart)
        --if tail then e.reference.sceneNode.children[1].children[2]:attachChild(tes3.loadMesh(tail.mesh)) end
    end
end
event.register(tes3.event.bodyPartAssigned, bodyPartAssignedCallback)

local function damageCallback(e)
    if tes3.player.data.ds22.boatMode == false then return end
    if e.mobile ~= tes3.mobilePlayer then return end
    e.block = true
end
--event.register(tes3.event.damage, damageCallback)

local function calcHitChanceCallback(e)
    if tes3.player.data.ds22.boatMode == false then return end
    if e.targetMobile ~= tes3.mobilePlayer then return end
    e.hitChance = 0
end
--event.register(tes3.event.calcHitChance, calcHitChanceCallback)

local function loadedCallback(e)
    if tes3.player.data.ds22 == nil then
        tes3.player.data.ds22 = {}
    end
    if (simulateEventRegistered == true) then
        event.unregister(tes3.event.simulate, simulateCallback)
        event.unregister(tes3.event.keyDown, endBoat, {filter = tes3.scanCode.space})
        simulateEventRegistered = false
    end
    if (tes3.player.data.ds22.sneakKey ~= nil) then
        tes3.getInputBinding(tes3.keybind.sneak).code = tes3.player.data.ds22.sneakKey
        tes3.player.data.ds22.sneakKey = nil
    end
    if tes3.player.data.ds22.boatMode == nil then
        tes3.player.data.ds22.boatMode = false
    end
    if tes3.player.data.ds22.boatMode == true then
        startBoat()
    end
end
event.register(tes3.event.loaded, loadedCallback)

local function onActivateOar(e)
    if e.target.object.id == "ds22_oar" then
        tes3.addItem({reference = tes3.player, item = "ds22_oar_useable"})
        e.target:delete()
        e.block = true
    end
end

event.register(tes3.event.activate, onActivateOar)

local function referenceSceneNodeCreatedCallback(e)
    if (e.reference.cell == nil) then return end
    if (e.reference.cell.isInterior ~= true) then return end
    if (e.reference.object.id == "ex_de_rowboat") then
        local ori = e.reference.orientation:copy()
        local pos = e.reference.position:copy()
        local scale = e.reference.scale
        tes3.createReference({object = tes3.getObject("ds22_Misc_rowboat_01"), position = pos, orientation = ori, cell = e.reference.cell, scale = scale})
        e.reference:delete()
    end
    if (e.reference.object.id == "ex_de_oar") then
        local ori = e.reference.orientation:copy()
        local pos = e.reference.position:copy()
        local scale = e.reference.scale
        tes3.createReference({object = tes3.getObject("ds22_oar"), position = pos, orientation = ori, cell = e.reference.cell, scale = scale})
        e.reference:delete()
    end
end
event.register(tes3.event.referenceSceneNodeCreated, referenceSceneNodeCreatedCallback)

local function placeBoat(e)
    local journalBoat = nil
--    tes3ui.log("Journal Entry")
    for _, boat in pairs(boats) do
       if e.topic.id == boat.journalTopic and e.index == boat.journalIndex then
--        tes3ui.log("Entry found")
        journalBoat = boat
       end
    end
    if journalBoat == nil then return end
    local pos
    local ori
    if journalBoat.replaceStatic ~= nil then
        local static = tes3.getReference(journalBoat.replaceStatic)
        pos = static.position
        ori = static.orientation
        static:delete()
    else
        pos = journalBoat.initpos
        ori = journalBoat.initori
    end
    local boat = tes3.createReference({object = journalBoat.activator, position = pos, orientation = ori})
    boat.data.ds22 = {}
    local cargoContainer = tes3.createReference({object = tes3.getObject(journalBoat.container), position = tes3vector3:new(), cell = "ToddTest"})
    cargoContainer.data.ds22 = {}
    cargoContainer.data.ds22.ident = tostring(os.time()) .. tostring(math.random(1000))
    cargoContainer.data.ds22.cell = tes3.player.cell.id
    cargoContainer.data.ds22.name = journalBoat.shipName
    boat.data.ds22.cargoContainerIdent = cargoContainer.data.ds22.ident
    boat.data.ds22.boat = journalBoat
end

event.register(tes3.event.journal, placeBoat)

local function markBlocker(e)
    if e.target ~= tes3.player then return end
    if (tes3.player.cell.id ~= "The Revenge, Cabin" and tes3.player.cell.id ~= "The Revenge, Cargo Hold" and tes3.player.cell.id ~="The Revenge, Upper Level") then return end
    if e.effectId ~= tes3.effect.mark then return end
    e.block = true
    tes3.removeEffects({reference = tes3.player, effect = tes3.effect.mark})
    tes3.messageBox("Placing a teleportation mark on a mobile ship would have wet consequences.")
end

event.register(tes3.event.spellTick, markBlocker)
--[[Trading]]--
local traders = {"arrille"}

local function isTrader(ref)
    local obj = ref.object
    local class = obj.class
    if ((class.id == "Trader Service") or (table.find(traders, ref.object.baseObject.id))) then
        return true
    else
        return false
    end
end

local guids = {
    MenuDialog = tes3ui.registerID("MenuDialog"),
    MenuDialog_disposition = tes3ui.registerID("MenuDialog_disposition"),
    MenuDialog_divider = tes3ui.registerID("MenuDialog_divider"),
    MenuDialog_TradeService = tes3ui.registerID("MenuDialog_service_TradeService"),
    TraderWindow = tes3ui.registerID("TraderWindow"),
    TraderWindow_TopLabel = tes3ui.registerID("TraderWindow_TopLabel"),
    TraderWindow_ScrollPane = tes3ui.registerID("TraderWindow_ScrollPane"),
    Pane = tes3ui.registerID("PartScrollPane_pane"),
    TraderWindow_BottomBlock = tes3ui.registerID("TraderWindow_BottomBlock"),
    TraderWindow_TransactionPrice = tes3ui.registerID("TraderWindow_TransactionPrice"),
    TraderWindow_BottomButtonContainer = tes3ui.registerID("TraderWindow_BottomButtonContainer"),
    TraderWindow_AcceptButton = tes3ui.registerID("TraderWindow_AcceptButton"),
    TraderWindow_CancelButton = tes3ui.registerID("TraderWindow_CancelButton"),
    PlayerTradeInventory = tes3ui.registerID("PlayerTradeInventory"),
    PlayerTradeInventory_TopBlock = tes3ui.registerID("PlayerTradeInventory_TopBlock"),
    PlayerTradeInventory_WeightBar = tes3ui.registerID("PlayerTradeInventory_WeightBar"),
    PlayerTradeInventory_BoatButton = tes3ui.registerID("PlayerTradeInventory_BoatButton"),
    PlayerTradeInventory_ScrollPane = tes3ui.registerID("PlayerTradeInventory_ScrollPane"),
    PlayerTradeInventory_BottomBlock = tes3ui.registerID("PlayerTradeInventory_BottomBlock"),
    PlayerTradeInventory_PlayerGold = tes3ui.registerID("PlayerTradeInventory_PlayerGold"),
    PlayerTradeInventory_BottomButtonContainer = tes3ui.registerID("PlayerTradeInventory_BottomButtonContainer"),
    PlayerTradeInventory_SellAll = tes3ui.registerID("PlayerTradeInventory_SellAll"),
    CrateBlock = tes3ui.registerID("CrateBlock"),
    CrateBlock_Upper = tes3ui.registerID("CrateBlock_Upper"),
    CrateBlock_Lower = tes3ui.registerID("CrateBlock_Lower"),
    CrateBlock_Label = tes3ui.registerID("CrateBlock_Label"),
    CrateBlock_Icon = tes3ui.registerID("CrateBlock_Label"),
    CrateBlock_Price = tes3ui.registerID("CrateBlock_Price"),
    CrateBlock_NoneButton = tes3ui.registerID("CrateBlock_NoneButton"),
    CrateBlock_Slider = tes3ui.registerID("CrateBlock_Slider"),
    CrateBlock_MaxButton = tes3ui.registerID ("CrateBlock_MaxButton")
}

local function getDialogMenu()
    return tes3ui.findMenu(guids.MenuDialog)
end

local function getMerchantObject()
    local menuDialog = getDialogMenu()
    if not menuDialog then return end

    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    if not merchant then return end

    return merchant.object
end

local function getDivider()
    local menu = tes3ui.findMenu(guids.MenuDialog)
    if not menu then return end
    local divider = menu:findChild(guids.MenuDialog_divider)
    return divider
end

local function getBoatsInMarket(package)
    local boatCells = {}
    local i = 1
    local boatStorage = tes3.getCell({id = "ToddTest"})
    for boat in boatStorage:iterateReferences({tes3.objectType.container}) do
        if boat.data.ds22 ~= nil then
            local cell = tes3.getCell({id = boat.data.ds22.cell})
            boatCells[i] = {}
            boatCells[i].boat = boat
            boatCells[i].cell = cell
            i = i + 1
        end
    end
    local marketX = package.exterior.gridX
    local marketY = package.exterior.gridY
--    tes3ui.log (marketX .. marketY)
    local boatsInMarket = {}
    local k = 1
    for _, boatCell in ipairs(boatCells) do
--        tes3ui.log (boatCell.cell.gridX .. boatCell.cell.gridY)
        if ( -- Checks to see if the any of the boats are within the exterior cell, or the surounding 24 cells on the grid
                (boatCell.cell.gridX <= marketX + 2 and boatCell.cell.gridX >= marketX -2)
                and (boatCell.cell.gridY <= marketY + 2 and boatCell.cell.gridY >= marketY -2)
            ) then
            boatsInMarket[k] = boatCell.boat
            k = k + 1
        end
    end
    return boatsInMarket
end
local function getMarket(merchant)
    local package = {}
    local cell = merchant.cell
    if cell.isInterior then
        local exitDoors = {}
        local i = 1
        local exterior = nil
        for door in cell:iterateReferences(tes3.objectType.door) do
            if door.destination ~= nil then
                if door.destination.cell.isInterior == false then
                    exterior = door.destination.cell
                    break
                end
                exitDoors[i] = door
                i = i +1
            end
        end
        local k = 1
        while ((exterior == nil) and (k <= 5)) do
            local exitDoorSnapshot = table.deepcopy(exitDoors)
            for _, door in ipairs(exitDoorSnapshot) do
                for secondaryDoor in door.destination.cell:iterateReferences(tes3.objectType.door) do
                    if secondaryDoor.destination ~= nil then
                        if secondaryDoor.destination.cell.isInterior == false then
                            exterior = secondaryDoor.destination.cell
                            break
                        end
                        exitDoors[i] = secondaryDoor
                        i = i + 1
                    end
                end
            end
            k = k + 1
        end
        package.exterior = exterior
    else
        package.exterior = cell
    end
    package.displayName = package.exterior.displayName
    package.region = package.exterior.region
    package.regionName = package.exterior.region.name
    if package.displayName == package.regionName then
        package.label = package.regionName
    else
        package.label = package.displayName .. ", " .. package.regionName
    end
    return package
end


local function populatePlayerTradeWindow(reference, merchant, pane)
    local khajiit = {"Khajiit", "T_Els_Cathay", "T_Els_Cathay-raht", "T_Els_Ohmes", "T_Els_Ohmes_raht", "T_Els_Suthay"}
    local tradesDrugs = false
    local tradesIllicit = false
    if (table.find(khajiit, merchant.object.race.id)) then
        tradesDrugs = true
    end
    if (merchant.object.faction) then
        if (merchant.object.faction.id == "Thieves Guild" or merchant.object.faction.id == "Camonna Tong") then
            tradesDrugs = true
            tradesIllicit = true
        end
    end
    for crate, data in pairs(tradegoods) do
        if (tes3.getItemCount({reference = reference, item = crate}) == 0) then goto continue end
        if (data.drugs and not (tradesDrugs or tradesIllicit)) then goto continue end
        if ((data.illicit and not data.drugs) and not tradesIllicit) then goto continue end
        local crateBlock = pane:createBlock({id = guids.CrateBlock})
        crateBlock.flowDirection = "top_to_bottom"
        crateBlock.autoWidth = true
        crateBlock.autoHeight = true
        local upper = crateBlock:createBlock({id = guids.CrateBlock_Upper})
        upper.flowDirection = "left_to_right"
        upper.autoWidth = true
        upper.autoHeight = true
        local label = upper:createLabel({id = guids.CrateBlock_Label, text = tes3.getObject(crate).name})
        local icon = upper:createImage({id = guids.CrateBlock_Icon, path = data.icon})
        local price = upper:createLabel({id = guids.CrateBlock_Price, text = "0 gold/crate"})
        local lower = crateBlock:createBlock({id = guids.CrateBlock_Lower})
        lower.flowDirection = "left_to_right"
        lower.autoWidth = true
        lower.autoHeight = true
        local noneButton = lower:createButton({id = guids.CrateBlock_NoneButton, text = "None"})
        local slider = lower:createSlider({id = guids.CrateBlock_Slider, current = 0, max = tes3.getItemCount({reference = reference, item = crate})})
        local maxButton = lower:createButton({id = guids.CrateBlock_MaxButton, text = "Max"})
        ::continue::
    end
end


local function populateTraderWindow (merchant, pane)
    local khajiit = {"Khajiit", "T_Els_Cathay", "T_Els_Cathay-raht", "T_Els_Ohmes", "T_Els_Ohmes_raht", "T_Els_Suthay"}
    local tradesDrugs = false
    local tradesIllicit = false
    if (table.find(khajiit, merchant.object.race.id)) then
        tradesDrugs = true
    end
    if(merchant.object.faction) then
        if (merchant.object.faction.id == "Thieves Guild" or merchant.object.faction.id == "Camonna Tong") then
            tradesDrugs = true
            tradesIllicit = true
        end
    end
    for crate, data in pairs(tradegoods) do
--        tes3ui.log(crate)
        if (data.drugs and not (tradesDrugs or tradesIllicit)) then goto continue end
        if ((data.illicit and not data.drugs) and not tradesIllicit) then goto continue end
        local crateBlock = pane:createBlock({id = guids.CrateBlock})
        crateBlock.flowDirection = "top_to_bottom"
        crateBlock.autoWidth = true
        crateBlock.autoHeight = true
        local upper = crateBlock:createBlock({id = guids.CrateBlock_Upper})
        upper.flowDirection = "left_to_right"
        upper.autoWidth = true
        upper.autoHeight = true
        local label = upper:createLabel({id = guids.CrateBlock_Label, text = tes3.getObject(crate).name})
--        tes3ui.log(data.icon)
        local icon = upper:createImage({id = guids.CrateBlock_Icon, path = data.icon})
        local mult = prices.getPriceMultiplierForItem(crate, getMarket(merchant).regionName)
--        tes3ui.log(mult)
        local price = upper:createLabel({id = guids.CrateBlock_Price, text = math.floor(data.basePrice * mult) .." gold/crate"})
        local lower = crateBlock:createBlock({id = guids.CrateBlock_Lower})
        lower.flowDirection = "left_to_right"
        lower.autoWidth = true
        lower.autoHeight = true
        local noneButton = lower:createButton({id = guids.CrateBlock_NoneButton, text = "None"})
        local slider = lower:createSlider({id = guids.CrateBlock_Slider, current = 0, max = 100})
        slider.width = 100
        local maxButton = lower:createButton({id = guids.CrateBlock_MaxButton, text = "Max"})
        ::continue::
    end
end
local function onTradeServiceClick()
    local menuDialog = getDialogMenu()
    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    local market = getMarket(merchant)
    local boatsInMarket = getBoatsInMarket(market)
    -- My code here
    local traderWindow = tes3ui.findMenu(guids.TraderWindow)
    if traderWindow == nil then
        traderWindow = tes3ui.createMenu({id = guids.TraderWindow, dragFrame = true})
        traderWindow.text = merchant.object.name
        menuDialog.visible = false
        traderWindow.minWidth = 400
        traderWindow.minHeight = 200
        traderWindow.width = 600
        traderWindow.height = 600
        traderWindow.positionX = 100
        traderWindow.positionY = 300
        local topLabel = traderWindow:createLabel({id = guids.TraderWindow_TopLabel, text = "Market: ".. market.label})
        topLabel.widthProportional = 1
        topLabel.autoHeight = true
        local scrollPane = traderWindow:createVerticalScrollPane({id = guids.TraderWindow_ScrollPane})
        scrollPane.borderAllSides = 8
        scrollPane.borderBottom = 24
        scrollPane.widthProportional = 1.0
        scrollPane.heightProportional = 1.0
        scrollPane.autoHeight = true
        local paneContainer = scrollPane:findChild(guids.Pane)
        populateTraderWindow(merchant, paneContainer)
        local bottomBlock = traderWindow:createBlock({id = guids.TraderWindow_BottomBlock})
        bottomBlock.flowDirection = "left_to_right"
        bottomBlock.widthProportional = 1
        bottomBlock.autoHeight = true
        local transactionPrice = bottomBlock:createLabel({id = guids.TraderWindow_TransactionPrice, text = "Transaction Total: 0"})
        transactionPrice.flowDirection = "left_to_right"
        transactionPrice.widthProportional = 1
        transactionPrice.autoHeight = true
        local bottomButtonContainer = bottomBlock:createBlock({id = guids.TraderWindow_BottomButtonContainer})
        bottomButtonContainer.flowDirection = "left_to_right"
        bottomButtonContainer.widthProportional = 1
        bottomButtonContainer.autoHeight = true
        bottomButtonContainer.childAlignX = 1
        bottomButtonContainer.childAlignY = 1
        local acceptButton = bottomButtonContainer:createButton({id = guids.TraderWindow_AcceptButton, text = "Accept"})
        local cancelButton = bottomButtonContainer:createButton({id = guids.TraderWindow_CancelButton, text = "Cancel"})
    end
    local playerTradeInventory = tes3ui.findMenu(guids.PlayerTradeInventory)
    local playerTradeInventorySelectedTab = tes3.player.object.name
    if playerTradeInventory == nil then
        playerTradeInventory = tes3ui.createMenu({id = guids.PlayerTradeInventory, dragFrame = true})
        playerTradeInventory.text = playerTradeInventorySelectedTab
        playerTradeInventory.minWidth = 400
        playerTradeInventory.minHeight = 200
        playerTradeInventory.width = 600
        playerTradeInventory.height = 600
        playerTradeInventory.positionX = -700
        playerTradeInventory.positionY = 300
        local topBlock = playerTradeInventory:createBlock({id = guids.PlayerTradeInventory_TopBlock})
        topBlock.widthProportional = 1
        topBlock.autoHeight = true
        local weightbar = topBlock:createFillBar({id = guids.PlayerTradeInventory_WeightBar, current = tes3.mobilePlayer.encumbrance.current, max = tes3.mobilePlayer.encumbrance.base})
        weightbar.widget.fillColor = tes3ui.getPalette(tes3.palette.magicColor)
        local playerButton = topBlock:createButton({id = guids.PlayerTradeInventory_BoatButton, text = tes3.player.object.name})
        for _, boat in ipairs(boatsInMarket) do
            topBlock:createButton({id = guids.PlayerTradeInventory_BoatButton, text = boat.data.ds22.name})
        end
        local scrollPane = playerTradeInventory:createVerticalScrollPane({id = guids.PlayerTradeInventory_ScrollPane})
        scrollPane.borderAllSides = 8
        scrollPane.borderBottom = 24
        scrollPane.widthProportional = 1.0
        scrollPane.heightProportional = 1.0
        scrollPane.autoHeight = true
        local paneContainer = scrollPane:findChild(guids.Pane)
        populatePlayerTradeWindow(tes3.player, merchant, paneContainer)
        local bottomBlock = playerTradeInventory:createBlock({id = guids.PlayerTradeInventory_BottomBlock})
        bottomBlock.flowDirection = "left_to_right"
        bottomBlock.widthProportional = 1
        bottomBlock.autoHeight = true
        local playerGold = bottomBlock:createLabel({id = guids.PlayerTradeInventory_PlayerGold, text = "Gold: " .. tes3.getPlayerGold()})
        playerGold.widthProportional = 1
        playerGold.autoHeight= true
        local bottomButtonContainer = bottomBlock:createBlock({id = guids.PlayerTradeInventory_BottomButtonContainer})
        bottomButtonContainer.widthProportional = 1
        bottomButtonContainer.autoHeight = true
        bottomButtonContainer.childAlignX = 1
        bottomButtonContainer.childAlignY = 1
        local sellAll = bottomButtonContainer:createButton({id = guids.PlayerTradeInventory_SellAll, text = "Sell All"})

    end
end

local function updateTradeServiceButton(e)
    timer.frame.delayOneFrame(function()
        local menuDialog = getDialogMenu()
        if not menuDialog then return end
        local tradeServiceButton = menuDialog:findChild(guids.MenuDialog_TradeService)
            tradeServiceButton.disabled = false
            tradeServiceButton.visible = true
            menuDialog:updateLayout()
    end)
end

local function createTradeButton(menuDialog)
    local parent = getDivider().parent
    local merchant = getMerchantObject()
    local button = parent:createTextSelect{
        id = guids.MenuDialog_TradeService,
        text = "Trade"
    }
    button.widthProportional = 1.0
    button:register("mouseClick", onTradeServiceClick)
    menuDialog:registerAfter("update", updateTradeServiceButton)
    parent:reorderChildren(getDivider(), button, 1)
    menuDialog:updateLayout()
end

local function onMenuDialogActivated()
    local menuDialog = getDialogMenu()
    -- Get the actor that we're talking with.
	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
    local ref = mobileActor.reference
    if isTrader(ref) then
        createTradeButton(menuDialog)
    end
end
--event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -99 } )