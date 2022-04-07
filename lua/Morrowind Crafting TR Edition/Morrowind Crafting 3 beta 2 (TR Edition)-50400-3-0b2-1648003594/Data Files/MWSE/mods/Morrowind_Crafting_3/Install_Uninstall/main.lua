--[[ Install/Uninstall controls
Part of Morrowind Crafting 3   c/r 2019, Drac and Toccatta ]]

local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}
local thing, locked, nameVar, thingName, status, menuWindow, permID, permThing, hasPerm
local menu, id_menu, id_lockButton, id_installButton, id_pickUpButton, id_menuBlock, menuBlock, id_cancelButton
local id_btn1, id_btn2, id_btn3
local lockButton, installButton, pickUpButton, label, mc_uninstall, btn1, btn2, btn3, tempMenu
local hasToolKit = false
local noLock = { "mc_carpentry_kit",
                "mc_fletching_kit",
                "mc_sewing_kit",
            }

local function init()
    id_menu = tes3ui.registerID("Lock_Install_Menu")
    id_lockButton = tes3ui.registerID("Lock_Lock_Button")
    id_installButton = tes3ui.registerID("Lock_Install_Button")
    id_pickUpButton = tes3ui.registerID("Lock_PickUp_Button")
    id_menuBlock = tes3ui.registerID("Lock_menuBlock")
    id_cancelButton = tes3ui.registerID("Lock_cancelButton")
    id_btn1 = tes3ui.registerID("Lock_btn1")
    id_btn2 = tes3ui.registerID("Lock_btn2")
    id_btn3 = tes3ui.registerID("Lock_btn3")
end

function this.onPickUp() -- When called, pick up the cutting board & place in player's inventory
	--local objectRef = tes3.getPlayerTarget()
	tes3.setEnabled({ reference = thing, enabled = false }) -- Should set current cutting board to disabled
	timer.delayOneFrame(function()
        mwscript.setDelete({ reference = thing, delete = true })
    end)
	tes3.addItem({ reference = tes3.player, item = thing.object.id, count = 1 }) -- Place one into player's inventory
    tes3ui.forcePlayerInventoryUpdate()
    tes3ui.leaveMenuMode()
    menu:destroy()
end

function this.onLockButton()
    if status == "Locked" then
        thing.data.mclockstatus = nil
    else
        thing.data.mclockstatus = 1
    end
	menu:destroy()
    this.menuWindow()
end

function this.onInstall()
    -- permID = new item ID
    local scaleSet = tes3.setGlobal("mc_scaler", thing.scale)

    if tes3.player.cell.isInterior == true then
        permThing = tes3.createReference{ object = permID,
                position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
                orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
                cell = tes3.player.cell,
                scale = thing.scale
                }
    else
        permThing = tes3.createReference{ object = permID,
                position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
                orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
                scale = thing.scale
                }
    end
    --local scaleSet = tes3.setGlobal("mc_scaler", 1)
    --permThing.sceneNode.parent:update();permThing.sceneNode.parent:updateNodeEffects()
    tes3.setEnabled({ reference = thing, enabled = false }) -- Disable old reference
    timer.delayOneFrame(function()
        mwscript.setDelete({ reference = thing, delete = true })
    end) -- "setdelete 1"
    mc.timePass(0.2)
    tes3ui.leaveMenuMode()
    menu:destroy()
    tes3.messageBox("Item was installed.")
    return false
end

-- Cancel button
function this.onCancel(e)
    local menu = tes3ui.findMenu(id_menu)
    permID = nil; permThing = nil
	if (menu) then
		tes3ui.leaveMenuMode()
        menu:destroy()
	end
end

function this.doUnInstall()
    local strLength = string.len(thingName)
    local newThing = string.sub(thingName, 1, (strLength - 2))
    if tes3.player.cell.isInterior == true then
        permThing = tes3.createReference{ object = newThing,
                position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
                orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
                cell = tes3.player.cell,
                scale = thing.scale}
    else
        permThing = tes3.createReference{ object = newThing,
                position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
                orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
                scale = thing.scale}
    end
    permThing.sceneNode.parent:update()
    permThing.sceneNode.parent:updateNodeEffects()
    thing:disable()
    timer.delayOneFrame(function()
            if (thing) then
                thing.deleted = true
                thing = nil
            end
        end)
    mc.timePass(0.2)
    tes3ui.leaveMenuMode()
    mc_uninstall.value = 0
    thing = nil
    permThing = nil
    menu = nil
    tes3.messageBox("Item was uninstalled.")
    --return false
end

function this.safeUnInstall()
    tes3.messageBox("Moving items from container to player...")
    for idx, x in pairs(thing.object.inventory) do
        tes3.transferItem{ from = thing, to = tes3.player, item = x.object.id, 
            itemData = x.itemData, count = x.count}
    end
    mc.timePass(0.2)
    tes3ui.forcePlayerInventoryUpdate()
    this.doUnInstall()
end

function this.containerMenu()
    -- Return if window is already open
    if (tes3ui.findMenu(id_menu) ~= nil) then
        return
    end
    menu = tes3ui.createMenu{ id = id_menu, fixedFrame = true }
    menu.width = 300
    menu.height = 150
    menu.minWidth = 300
    menu.minHeight = 150
    menu.alpha = 0.75
    menu.text = "Container Uninstalling"
    menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2
    menu.flowDirection = "top_to_bottom"
    menuBlock = menu:createBlock({ id = id_menuBlock, fixedFrame = true })
    menuBlock.autoHeight = true
    menuBlock.widthProportional = 1.0
    menuBlock.childAlignX = 0.5
    menuBlock.flowDirection = "top_to_bottom"
    label = menuBlock:createLabel{text = "This container has items in it."}
    label.alignX = 0.5
    label = menuBlock:createLabel{text = "Do you wish to:"}
    label.alignX = 0.5
    menuBlock = menu:createBlock{ id = id_menuBlock, fixedFrame = true }
    menuBlock.flowDirection = "top_to_bottom"
    menuBlock.widthProportional = 1.0
    menuBlock.heightProportional = 1.0
    btn1 = menuBlock:createButton{id = id_btn1, text = "Uninstall (loses contents)"}
    btn1.widthProportional = 1.0
    btn2 = menuBlock:createButton{id = id_btn2, text = "Take items, then uninstall"}
    btn2.widthProportional = 1.0
    btn3 = menuBlock:createButton{id = id_btn3, text = "Cancel uninstall"}
    btn3.widthProportional = 1.0

    btn1:register("mouseClick", this.doUnInstall)
    btn2:register("mouseClick", this.safeUnInstall)
    btn3:register("mouseClick", this.onCancel)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(id_menu)
end

function this.onUnInstall() -- mc_uninstall was set; is this an uninstallable thing?
    if string.endswith(thingName, "_p") then -- Yep, it's supposed to be uninstallable
        if (thing.baseObject.objectType == tes3.objectType.container) 
            and #thing.object.inventory ~= 0 then -- Has things in it!
            -- short menu - uninstall, move items to player & uninstall, or cancelButton
            this.containerMenu()
        else -- Just do it (not a container)
            this.doUnInstall()
        end
    end
end

function this.menuWindow()
    local textItem
    -- Return if window is already open
    if (tes3ui.findMenu(id_menu) ~= nil) then
        return
    end
    menu = tes3ui.createMenu{ id = id_menu, fixedFrame = true }
    menu.width = 200
    menu.height = 200
    menu.minWidth = 200
    menu.minHeight = 200
    menu.alpha = 0.75
    menu.text = "Item Lock / Unlock"
    menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2
	menu.flowDirection = "top_to_bottom"
    menuBlock = menu:createBlock({ id = id_menuBlock, fixedFrame = true })
    menuBlock.heightProportional = 1.0
    menuBlock.widthProportional = 1.0
    menuBlock.childAlignX = 0.5
    menuBlock.childAlignY = 0.5
    menuBlock.flowDirection = "top_to_bottom"
    status = "Not Locked"; if thing.data.mclockstatus then status = "Locked" end
    if status == "Locked" then textItem = "Unlock Item" else textItem = "Lock Item in Place" end
    label = menuBlock:createLabel({ text = thing.object.name })
    label.color = tes3ui.getPalette("header_color")
    label = menuBlock:createLabel({ text = "" })
    lockButton = menuBlock:createButton({ id = id_lockButton, text = textItem })
    lockButton.widthProportional = 1.0
    if permThing then
        installButton = menuBlock:createButton({ id = id_installButton, text = "Install Item for Use"})
        installButton.widthProportional = 1.0
    end
    label = menuBlock:createLabel({ text = "" })
    pickUpButton = menuBlock:createButton({ id = id_pickUpButton, text = "Pick Up" })
    pickUpButton.widthProportional = 1.0
    label = menuBlock:createLabel({ text = "" })
    cancelButton = menuBlock:createButton({ id = id_cancelButton, text = "Cancel"})
    cancelButton.widthProportional = 1.0

    cancelButton:register("mouseClick", this.onCancel)
    pickUpButton:register("mouseClick", this.onPickUp)
    lockButton:register("mouseClick", this.onLockButton)
    if permThing then
        installButton:register("mouseClick", this.onInstall)
    end

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(id_menu)
end

function this.handleMisc()
    this.menuWindow()
end

local function doActivate(e)
    local thingType, thingBlock, thingCarry
    locked = false
	if (e.activator == tes3.player) then
        thing = e.target
        thingName = thing.baseObject.id
        thingBlock = string.find(string.upper(thingName), "FIRE",1,true)
		thingCarry = thing.baseObject.canCarry
        if thing.stackSize == 1 then
            thingType = thing.baseObject.objectType
            --if string.startswith(thingName, "mc_") then
                if not string.endswith(thingName, "_p") then
				    if mwscript.getItemCount({ reference = tes3.player, item = "mc_carpentry_kit" }) > 0 then
					    hasToolKit = true
				    else
					    hasToolKit = false
                    end
                    if ((thingType == tes3.objectType.miscItem) or ((thingType == tes3.objectType.light) and (thingBlock == nil) and (thingCarry == true))) then
                        permID = thing.object.id.."_p"
                        permThing = tes3.getObject(permID)
                        if (hasToolKit == true) and (permThing or (thingType == tes3.objectType.light)) then
                            this.handleMisc()
                            return false
                        else
                            if thing.data then
                                if thing.data.mclockstatus then
                                    return false
                                else
                                    -- ignore this script and do nothing special
                                    return
                                end
                            end
                        end
                    end
                else
                    mc_uninstall = tes3.findGlobal("mc_uninstall")
                    if mc_uninstall.value == 1 then
                        this.onUnInstall()
                        return false
                    end
                end
            --end
        end
   end
end

UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("MasonryMenu:ListBlockLabel")
event.register("initialized", init)
event.register("activate", doActivate)