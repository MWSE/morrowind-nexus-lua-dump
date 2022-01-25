local common = require('ss20.common')
local mainTeleporterName = "Well of Fire"
local shrinePlatformId = 'ss20_dae_platteleportshrine'
local platformId = 'ss20_dae_platteleport'
local steppedOnPad

local function isTeleporter(ref)
    return ref and (ref.object.id:lower() == platformId or ref.object.id:lower() == shrinePlatformId)
end

local function isWithinReach(ref)
    return ref.position:distance(tes3.player.position) < 50
end


local teleportNameId = tes3ui.registerID("TeleportPadName")
local teleportMenuId = tes3ui.registerID("TeleportMenu")

local function closeTeleportMenu()
    local menu = tes3ui.findMenu(teleportMenuId)
    if menu then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

local function nameChosen(thisTeleporter)
    closeTeleportMenu()
    tes3ui.leaveMenuMode(teleportNameId)
    tes3ui.findMenu(teleportNameId):destroy()
    tes3.messageBox("Teleporter renamed to %s", thisTeleporter.data.ss20TeleporterName)
    
end

local function nameTeleporter(thisTeleporter)
    local menu = tes3ui.createMenu{ id = teleportNameId, fixedFrame = true }
    menu.minWidth = 400
    menu.alignX = 0.5
    menu.alignY = 0
    menu.autoHeight = true
   -- menu.widthProportional = 1
    --menu.heightProportional = 1
    local textField = mwse.mcm.createTextField(
        menu,
        {
            label = "Enter the name of this Teleporter:",
            variable = mwse.mcm.createTableVariable{
                id = 'ss20TeleporterName', 
                table = thisTeleporter.data
            },
            callback = function() 
                thisTeleporter.modified = true
                nameChosen(thisTeleporter) 
            end
        }
    )
    tes3ui.acquireTextInput(textField.elements.inputField)
    tes3ui.enterMenuMode(teleportNameId)

end


local function teleportTo(teleporter)
    closeTeleportMenu()
    timer.delayOneFrame(function()

        tes3.playSound{ reference = tes3.player, sound = "mysticism cast"}
        tes3.positionCell{
            reference = tes3.player,
            position = teleporter.position:copy(),
            orientation = teleporter.orientation:copy() + tes3vector3.new(0, 0, math.rad(180)),
            cell = teleporter.cell
        }
        tes3.createReference{
            object = 'AB_Fx_MagicMystCast',
            position = tes3.player.position:copy(),
            cell = tes3.player.cell
        }
    end)
end

local function teleportMenu(active, teleporters)
    local menu = tes3ui.createMenu{ id = teleportMenuId, fixedFrame = true }
    menu.minWidth = 250
    menu.autoHeight = true
    menu.alignX = 0.5
    menu.alignY = 0

    local menuLabel = menu:createLabel()
    menuLabel.text = string.format("Teleporter: %s", active.data.ss20TeleporterName or "")
    menuLabel.color = tes3ui.getPalette("header_color")
    menuLabel.borderBottom = 5

    local directionsMenu = menu:createLabel()
    directionsMenu.borderBottom = 5
    common.log:debug(#teleporters)
    if #teleporters == 0 then
        directionsMenu.text = "You have not registered any new teleporters."
    else
        directionsMenu.text = "Select your destination:"
        local list = menu:createVerticalScrollPane()
        list.minHeight = 200
        for _, teleporter in ipairs(teleporters) do
        
            local button = list:createTextSelect()
            button.text = teleporter.data.ss20TeleporterName
            button:register("mouseClick", function() 
                teleportTo(teleporter) 
            end)
        end
    end

    local buttonBlock = menu:createBlock()
    buttonBlock.widthProportional = 1
    buttonBlock.autoHeight = true
    buttonBlock.flowDirection = "left_to_right"

    local renameButton = buttonBlock:createButton{ text = "Rename"}
    renameButton:register("mouseClick", function()
        nameTeleporter(active)
    end)

    local closeButton = buttonBlock:createButton{text="Close"}
    closeButton:register("mouseClick", function()
        closeTeleportMenu()
    end)

    menu:updateLayout()
    tes3ui.enterMenuMode(teleportMenuId)
end




local function checkTeleportPadDistance(e)
    if not common.isAllowedToManipulate() then
        return 
    end

    local teleporters = {}
    local thisTeleporter

    for ref in tes3.player.cell:iterateReferences(tes3.objectType.activator) do
        --Name the shrine teleporter immediately
        if ref.object.id:lower() == shrinePlatformId  and not ref.data.ss20TeleporterName then
            ref.data.ss20TeleporterName = mainTeleporterName
        end

        if isTeleporter(ref) then
            --This is the one we're standing on
            if isWithinReach(ref) then
                thisTeleporter = ref

            --For all the others, if they have names then add them to the teleport list
            elseif ref.data.ss20TeleporterName then
                table.insert(teleporters, ref)
            end
        end
    end
    if thisTeleporter then
        
        if not steppedOnPad then
            steppedOnPad = true
            --If it hasn't been named yet, enter the name menu
            if not thisTeleporter.data.ss20TeleporterName then
                thisTeleporter.data.ss20TeleporterName = string.format("Teleporter #%d", #teleporters + 1)
                nameTeleporter(thisTeleporter)
            else
                --Otherwise, enter the teleport menu
                teleportMenu(thisTeleporter, teleporters)
            end
        end
    else
        steppedOnPad = false
    end

end

event.register("simulate", checkTeleportPadDistance)

event.register("loaded", function() steppedOnPad = false end)




local function teleporterTooltip(e)
    if isTeleporter(e.reference) then
        local name = e.reference.data.ss20TeleporterName
        if name then
            local label = e.tooltip:findChild(tes3ui.registerID('HelpMenu_name'))
            if label then
                label.text = string.format("%s: %s", label.text, name)
            end
        end
    end
end

event.register("uiObjectTooltip", teleporterTooltip)