local common = require('ss20.common')
local config = common.config
local modName = config.modName
local journal_cs = config.journal_cs
local journal_main = config.journal_main
local function rotateAboutOrigin(ref, zRot)
    --Rotate around the 0,0,0 origin
    local m = tes3matrix33.new()
    m:fromEulerXYZ(0, 0, zRot)

    local t = ref.sceneNode.worldTransform
    ref.position = m * t.translation
    ref.orientation = m * t.rotation
end

local function placeItem(data, target)
    --Starting position around 0,0,0 for matrix rotation
    local placedRef = tes3.createReference{
        object = data.id,
        position = {
            data.position.x,
            data.position.y,
            data.position.z,
        },
        orientation = data.orientation,
        cell = target.cell
    }
    placedRef.scale = data.scale

    rotateAboutOrigin(placedRef, target.orientation.z)

    local m1 = tes3matrix33.new()
    m1:fromEulerXYZ(data.orientation)
    local m2 = placedRef.sceneNode.worldTransform
    placedRef.orientation = m1 * m2.rotation

    placedRef.position = {
        placedRef.position.x + target.position.x,
        placedRef.position.y + target.position.y,
        placedRef.position.z + target.position.z,
    }
    if placedRef.object.objectType == tes3.objectType.light then
        
        timer.delayOneFrame(function()
            common.log:debug("Turning lights on")
            common.onLight(placedRef)
        end)
    end
    common.log:debug("Placed %s", data.id)

end

local targetWall
local selectedRoom

local function onWallObjectInvalidated(e)
    if e.object == targetWall then
        targetWall = nil
    end
end
event.register("objectInvalidated", onWallObjectInvalidated)


local function purchaseRoom(room)
    local cost = common.getRoomCost(room)
    common.modSoulShards(-cost)
    local data = tes3.player.data[modName]
    data.roomsBuilt = data.roomsBuilt or 0
    data.roomsBuilt = data.roomsBuilt + 1
    common.log:debug("Purchased %s for %s shards", room.name, cost)
end

local function placeRoom()
    
    local journalIndex =  tes3.getJournalIndex{ id = journal_cs.id }
    if journalIndex < journal_cs.indexes.builtFirstRoom then
        tes3.updateJournal({
            id = journal_cs.id,
            index = journal_cs.indexes.builtFirstRoom
        })
    elseif journalIndex < journal_cs.indexes.builtSecondRoom then
        tes3.updateJournal({
            id = journal_cs.id,
            index = journal_cs.indexes.builtSecondRoom
        })
    end
    common.log:debug("Placing room")
    local roomObjectConfig = mwse.loadConfig("Shrine of Vernaccus Room Registration")
    local roomData = roomObjectConfig.rooms[selectedRoom.id]
    if not roomData then 
        error("Room data not found for %s", selectedRoom.id)
        return
    end
    for _, data in ipairs(roomData) do
        local obj = tes3.getObject(data.id)
        
        if obj and obj.objectType ~= tes3.objectType.light then
            placeItem(data, targetWall)
        end
    end

    --place lights last I guess
    for _, data in ipairs(roomData) do
        local obj = tes3.getObject(data.id)
        if obj and  obj.objectType == tes3.objectType.light then
            placeItem(data, targetWall)
        end
    end

    if targetWall.disable then
        event.trigger("SS20:DestroyWall", { wall = targetWall })
    else
        common.log:debug("%s does not have a disable function", targetWall.object.id)
    end
    common.log:debug("Finished placing room")
end


local isCasting

local function returnGuardian(golemRef)
    isCasting = false
    local originalLocation = tes3vector3.new(-450, 5132, 199)
    timer.start{
        duration = 2,
        callback = function() 
            if golemRef then
                -- tes3.playSound{
                --     reference = tes3.player,
                --     sound = 'mysticism cast'
                -- }
                
                tes3.positionCell{
                    reference = golemRef,
                    position = originalLocation,
                    cell = "Shrine of Vernaccus"
                }
                
                tes3.setAIWander{ 
                    reference = golemRef, 
                    range = 400, 
                    idles = {40, 30, 20, 0, 0, 0, 0, 0, 0},
                }
            end
        end
    }
  
end



local function guardianBuildRoom()
    local golem = tes3.getReference("ss20_dae_golem")
    if golem  then
        isCasting = true
        local distance = -200
        local pos = tes3vector3.new(
            targetWall.position.x + ( distance * math.cos(targetWall.orientation.z)),
            targetWall.position.y + ( distance * math.sin(targetWall.orientation.z)),
            targetWall.position.z
        )

        tes3.positionCell{
            reference = golem,
            position = pos,
            orientation = targetWall.orientation,
            cell = targetWall.cell
        }

        timer.start{
            duration = 1,
            callback = function()

                common.log:debug(tes3.cast{ 
                    reference = golem,
                    target = targetWall,
                    spell = 'flamebolt'
                })
                timer.start{
                    duration = 2,
                    callback = function()
                        tes3.playSound{
                            reference = tes3.player,
                            sound = "destruction hit"
                        }
                        local journalIndex =  tes3.getJournalIndex{ id = journal_cs.id }
                        if journalIndex < 15 then
                            placeRoom()
                            timer.start{
                                duration = 1,
                                callback = function()
                                    common.messageBox{
                                        message = "The wall dissolves as the golem draws from the Well of Fire to create a small room.",
                                        buttons = {
                                            {
                                                text = "Okay",
                                                callback = function()
                                                    common.log:debug("updating journal")
                                                    returnGuardian(golem)
                                                end
                                            }
                                        }
                                    }
                                end
                            }
                        else
                            placeRoom()
                            returnGuardian(golem)
                        end
                    end
                }
            end
        }
    end
end



local roomMenuIds = {
    menu = tes3ui.registerID("SS20_RoomBuildMenu"),
    roomName = tes3ui.registerID("SS20_RoomNameLabel"),
    roomDescription = tes3ui.registerID("SS20_roomDescriptionLabel"),
    buyButton = tes3ui.registerID("SS20_roomBuyButton"), 
    itemsList = tes3ui.registerID("ItemsList")
}

local function closeRoomMenu()
    local menu = tes3ui.findMenu(roomMenuIds.menu)
    if menu then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end



local function updateSelectedRoom(roomConfig)
    selectedRoom = roomConfig
    local menu = tes3ui.findMenu(roomMenuIds.menu)
    if not menu then return end
    common.log:debug("updating room to %s", roomConfig.name)
    local nameLabel = menu:findChild(roomMenuIds.roomName)
    nameLabel.text = roomConfig.name

    local descriptionLabel = menu:findChild(roomMenuIds.roomDescription)
    descriptionLabel.text = roomConfig.description
end

local function makeRoomSelectButton(room, parent)
    local name = room.name
    local cost = common.getRoomCost(room)

    local block = parent:createBlock()
    block.autoHeight = true
    block.widthProportional = 1.0
    block.flowDirection = "left_to_right"
    block.paddingLeft = 5
    block.paddingRight = 5
    local nameButton = block:createTextSelect()
    nameButton.text = name
    nameButton.widthProportional = 1.0

    local costButton = block:createLabel()
    costButton.text = string.format("%d Shards", cost)

    local souls = common.getSoulShards()
    nameButton:register("mouseClick", function()
        selectedRoom = room
        updateSelectedRoom(room)
    end)
    if souls < cost then
        nameButton.color = tes3ui.getPalette("disabled_color")
        nameButton.widget.idle = tes3ui.getPalette("disabled_color")
        costButton.color = tes3ui.getPalette("disabled_color")
    end
end

local function openBuildRoomMenu()
    if tes3ui.findMenu(roomMenuIds.menu) then return end
    -- create the base menu
    local menu = tes3ui.createMenu{id=roomMenuIds.menu, fixedFrame=true}
    menu.flowDirection = "top_to_bottom"
    menu.autoWidth = true
    menu.minWidth = 400
    menu.minHeight = 450

    local mainBlock = menu:createBlock{}
    mainBlock.flowDirection = "top_to_bottom"
    mainBlock.widthProportional = 1.0
    mainBlock.heightProportional = 1.0
    mainBlock.childAlignX = 0.5
    mainBlock.childAlignY = 0.5

    local headerLabel = mainBlock:createLabel()
    headerLabel.text = "Room Builder"
    headerLabel.color = tes3ui.getPalette("header_color")

    do
        local souls = common.getSoulShards()
        local menuDescriptionLabel = mainBlock:createLabel()
        menuDescriptionLabel.text = string.format("Soul Shards: %d", souls)
        menuDescriptionLabel:register("help", function()
            local tooltip = tes3ui.createTooltipMenu()
            tooltip:createLabel{ text = "Earn Soul Shards by killing enemies with the Bottle of Souls in your inventory."}
        end)
    end
    do
        local listBlock = mainBlock:createVerticalScrollPane{
            id = roomMenuIds.itemsList
        }
        listBlock.heightProportional = 1.3
        listBlock.widthProportional = 1.0
        listBlock.borderTop = 10
        --populate listBlock with rooms
        table.sort(config.rooms, function(a, b)
            return a.cost < b.cost
        end)
        for _, room in ipairs(config.rooms) do
            makeRoomSelectButton(room, listBlock, targetWall)
        end
    end

    --Show room description and cost
    do
        local descriptionBlock = mainBlock:createThinBorder()
        descriptionBlock.heightProportional = 0.7
        descriptionBlock.widthProportional = 1.0
        descriptionBlock.flowDirection = "top_to_bottom"
        descriptionBlock.paddingAllSides = 10

        local roomNameLabel = descriptionBlock:createLabel{ id = roomMenuIds.roomName }
        roomNameLabel.color = tes3ui.getPalette("header_color")
        roomNameLabel.text = ""

        local roomDescriptionLabel = descriptionBlock:createLabel{ id = roomMenuIds.roomDescription }
        roomDescriptionLabel.wrapText = true
    end
    -- create buttons container
    --menu:createDivider{}

    local buttonsBlock = menu:createBlock{}
    buttonsBlock.flowDirection = "left_to_right"
    buttonsBlock.widthProportional = 1.0
    buttonsBlock.autoHeight = true
    buttonsBlock.childAlignX = 0.5

    local buyButton = buttonsBlock:createButton{ id = roomMenuIds.buyButton, text = "Build"}
    buyButton:register("mouseClick", function()
        local cost = common.getRoomCost(selectedRoom)
        local souls = common.getSoulShards()
        if souls < cost then
            tes3.messageBox("You can not afford this room.")
            return
        end
        common.log:debug("clicked the buy button")
        menu:destroy()
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            purchaseRoom(selectedRoom)
            placeRoom()
        end)
        
    end)

    -- create a close button
    local closeButton = buttonsBlock:createButton{text="Close"}
    closeButton:register("mouseClick", function()
        closeRoomMenu()
    end)

    updateSelectedRoom(config.rooms[1])
    menu:updateLayout()
    tes3ui.enterMenuMode(roomMenuIds.menu)
end



local function onActivateCrumblingWall(e)
    
    common.log:debug(isCasting)
    local isWall = e.target.baseObject.id == 'ss20_in_daeBarrier01b'
        or e.target.baseObject.id == 'ss20_in_daeBarrier01a'

    if isWall and isCasting ~= true then
        
        local ss20_CS_index = tes3.getJournalIndex{ id = journal_cs.id }
        local ss20_main_index =  tes3.getJournalIndex{ id = journal_main.id }
        common.log:debug("hi: %s", ss20_CS_index)
        targetWall = e.target
        
        if ss20_CS_index < journal_cs.indexes.talkedToGolem then
            return
        elseif ss20_main_index >= 50 and ss20_main_index < 59 then
            return
        elseif ss20_CS_index < journal_cs.indexes.builtFirstRoom then
            selectedRoom = { id = 'ss20_firstroom'}
            guardianBuildRoom()
        elseif ss20_CS_index < journal_cs.indexes.bottlePickedUp then
            return
        else
            openBuildRoomMenu()
        end
    end
end
event.register("activate", onActivateCrumblingWall)
event.register("loaded", function() isCasting = false end)
