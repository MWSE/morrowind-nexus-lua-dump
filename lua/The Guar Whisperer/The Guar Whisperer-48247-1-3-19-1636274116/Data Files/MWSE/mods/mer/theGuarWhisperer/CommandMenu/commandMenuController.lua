--[[
    Handles events and player input for command menu
]]

local common = require("mer.theGuarWhisperer.common")
local commandMenu = require("mer.theGuarWhisperer.CommandMenu.CommandMenuModel")


--check if activate key is down
local function didPressActivate()
    local inputController = tes3.worldController.inputController
    return inputController:keybindTest(tes3.keybind.activate)
end

--Check if toggle key is down
local function didPressToggleKey(e)
    local config = common.getConfig()
    return (
        config.commandToggleKey and
        e.keyCode == config.commandToggleKey.keyCode and
        not not e.isShiftDown == not not config.commandToggleKey.isShiftDown and
        not not e.isControlDown == not not config.commandToggleKey.isControlDown and
        not not e.isAltDown == not not config.commandToggleKey.isAltDown
    )
end

local function hasModifierPressed()
    local inputController = tes3.worldController.inputController
    local pressedModifier = inputController:isKeyDown(tes3.scanCode.lShift)
    common.log:debug("Pressed modifier? %s", pressedModifier)
    return pressedModifier
end


--Check if looking at a part of the backpack and grab it straight from there
local function grabFromPack(animal)
    common.log:debug("Calling ray test")
    local eyePos =  tes3.getPlayerEyePosition()
    local results = tes3.rayTest{
        position = eyePos,
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player },
        findAll = true
    }
   
    if results then
        for _, result in ipairs(results) do
            if result and result.object then
                common.log:debug("Ray hit %s", result.object.name)
                for _, data in pairs(common.packItems) do
                    if data.grabNode then

                        local hitNode
                        local node = result.object
                        while node.parent do
                            if node.name == data.grabNode then
                                hitNode = true
                                break
                            end
                            node = node.parent
                        end
                        if hitNode then
                            local distanceToIntersection = result.intersection:distance(eyePos)
                            local distanceToGuar = animal.reference.position:distance(eyePos)
                            if distanceToIntersection > distanceToGuar then
                                --too far away
                                hitNode = false
                            end
                        end

                        if hitNode then

                            if data.grabNode == "LANTERN" then
                                if animal.refData.lanternOn then
                                    animal:turnLanternOff{ playSound = true }
                                else
                                    animal:turnLanternOn{ playSound = true }
                                end
                                return true
                            end

                            common.log:debug("Grabbing %s from pack", data.grabNode)
                            for _, itemId in ipairs(data.items) do
                                local inventory = animal.reference.object.inventory
                                if inventory:contains(itemId) then
                                    common.log:debug("Found %s in inventory", itemId)
                                    for stack in tes3.iterate(inventory.iterator) do
                                        if stack.object.id:lower() == itemId:lower() then
                                            local count = stack.count
                                            local itemData
                                            if stack.variables and #stack.variables > 0 then
                                                count = 1
                                                itemData = stack.variables[1]
                                            end
                                            common.log:debug("Item transferred successfully")
                                            tes3.messageBox("Retrieved %s from pack.", stack.object.name)
                                            tes3.transferItem{
                                                from = animal.reference,
                                                to = tes3.player,
                                                item = stack.object.id,
                                                itemData = itemData,
                                                count = count
                                            }
                                            event.trigger("Ashfall:triggerPackUpdate")
                                            return true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                animal:setSwitch()
            end
        end
    end

    common.log:debug("Entering pack")
    animal.refData.triggerDialog = true
    tes3.player:activate(animal.reference)
    return true


    -- common.log:debug("nothing grabbed from pack")
    -- return false
end


local function onKeyPress(e)
    if tes3.menuMode() then 
        return 
    end
    --Pressed Activate
    if didPressActivate() then
        
        if commandMenu.activeCompanion then
            --can activate as long as we aren't looking at another reference
            local target = tes3.getPlayerTarget()
            if target == nil or target == commandMenu.activeCompanion.reference then
                commandMenu:performAction()
            end
        end
    else
        --Check if Command button was pressed
       if didPressToggleKey(e) then 
            return commandMenu:toggleCommandMenu() 
        end
    end
end
event.register("keyDown", onKeyPress) 



local function onMouseWheelChanged(e)
    if not common.data then return end
    if tes3ui.menuMode() then return end
    if commandMenu.activeCompanion then
        if e.delta < 0 then
            commandMenu:scrollUp()
        else
            commandMenu:scrollDown()
        end
    end
end
event.register("mouseWheel", onMouseWheelChanged)


local function activateMenu(e)
    common.log:debug("activating menu")
    local didGrabFromPack
    if hasModifierPressed() then
        didGrabFromPack = grabFromPack(e.animal)
    end
    if not didGrabFromPack then
        commandMenu:showCommandMenu(e.animal)
    end
end
event.register("TheGuarWhisperer:showCommandMenu", activateMenu)

--Allow exiting of command menu
local function onMouseButtonDown(e)
    if e.button == tes3.worldController.inputController.inputMaps[19].code then
        commandMenu:destroy()
    end
end
event.register("mouseButtonDown", onMouseButtonDown)