--[[ Make cookfires and campfires with flint and tinder kit.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

    local configPath = "Morrowind_Crafting_3"
    local config = mwse.loadConfig(configPath)
    
    -- recipes for (creating items) per filters: item class, material
    local skillModule = require("OtherSkills.skillModule")
    local mc = require("Morrowind_Crafting_3.mc_common")
    
    local this = {}
    local skillID = "mc_Woodworking"
    local menu, eObjectRef, onPickUp, onCancel, onCreateCookFire, onCreateCampFire, fireType

-- Register IDs
local UID_classLabel = tes3ui.registerID("FirestartingMenu::menuLabel")
local UID_groupLabel = tes3ui.registerID("FirestartingMenu::menuLabel")

function this.init()
	this.id_menu = tes3ui.registerID("fireStarterMenu")
	this.id_PuBtn = tes3ui.registerID("fireStarterPU")
	this.id_cancel = tes3ui.registerID("fireStarter_cancel")
	this.id_cookFireButton = tes3ui.registerID("btnCookFire")
	this.id_campFireButton = tes3ui.registerID("btnCampFire")
end

-- Cancel button
function this.onCancel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function makeFire(fireObject)
    config = mwse.loadConfig(configPath)
    local fireActivator = fireObject.."_act"
    local skillValue = mc.fetchSkill(skillID)
    local pCell = tes3.getPlayerCell()
    if mc.countLogs() >= 4 then
        if mc.countKindling() >= 1 then
            if config.casualmode ~= true then
                if mc.skillCheck(skillID, 5) ~= true then
                    tes3.messageBox("Failed: Your kindling was used up in the attempt.")
                    tes3.playSound({ sound = "enchant fail", volume = 1.0, pitch = 0.0 })
                else
                    tes3.createReference({object = fireObject, 
                        position = eObjectRef.position, 
                        orientation = eObjectRef.orientation,
                        cell = pCell})
                    tes3.createReference({object = fireActivator, 
                        position = eObjectRef.position, 
                        orientation = eObjectRef.orientation,
                        cell = pCell})
                    mc.skillReward(skillID, skillValue, 5)
                    mc.removeLogs(4)
                end
                mc.removeKindling(1)
                mc.timePass(0.2)
			else
			    tes3.createReference({object = fireObject, 
					position = eObjectRef.position, 
                    orientation = eObjectRef.orientation,
                    cell = pCell})
                tes3.createReference({object = fireActivator, 
                    position = eObjectRef.position, 
                    orientation = eObjectRef.orientation,
                    cell = pCell})
                mc.removeLogs(4)
				mc.removeKindling(1)
                mc.timePass(0.2)
            end
            tes3.playSound({ sound = "Pack", volume = 1.0, pitch = 0.3 })
            this.onPickUp()
        else
            tes3.messageBox("You have wood, but no kindling material. Use straw, or some sort of fibrous material.")
        end
    else
        tes3.messageBox("You need at least 4 pieces of wood to make a viable fire.")
    end
end

function this.onCreateCookFire()
    makeFire("mc_logfire")
end

function this.onCreateCampFire()
    makeFire("mc_campfire")
end

function this.onPickUp() -- When called, pick up the tinder kit & place in player's inventory
	tes3.setEnabled({ reference = eObjectRef, enabled = false }) -- Should set current firekit to disabled
	tes3.addItem({ reference = tes3.player, item = "mc_firestarter", count = 1 }) -- Place one into player's inventory
    tes3ui.forcePlayerInventoryUpdate()
    tes3ui.leaveMenuMode()
	menu:destroy()
end

-- Create window and layout. Called by onCommand.
function this.createWindow()
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
    local label, button_block, menuBlock
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Flint and Tinder Kit"
	menu.width = 300
	menu.height = 200
	menu.minWidth = 200
	menu.minHeight = 150
	menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2
    
    menuBlock = menu:createBlock({ id = this.id_menu, fixedFrame = true })
    menuBlock.widthProportional = 1.0  -- width is 100% parent width
    menuBlock.flowDirection = "top_to_bottom"
    menuBlock.childAlignX = 0.5
    menuBlock.autoHeight = true

    local cookFireButton = menuBlock:createButton{ id = this.id_cookFireButton, text = "Create Cookfire"}
    local campFireButton = menuBlock:createButton{ id = this.id_campFireButton, text = "Create Campfire"}
    label = menuBlock:createLabel{text = ""}
    local pickUpButton = menuBlock:createButton{ id = this.id_PuBtn, text = "Pick Up Firekit"}
    label = menuBlock:createLabel{text = ""}
    local button_cancel = menuBlock:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
	
	-- Events
    button_cancel:register("mouseClick", this.onCancel)
    cookFireButton:register("mouseClick", this.onCreateCookFire)
    campFireButton:register("mouseClick", this.onCreateCampFire)
    pickUpButton:register("mouseClick", this.onPickUp)

	-- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
end


local function onActivate()
    this.createWindow()
end

UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("ScrappingMenu:ListBlockLabel")
event.register("initialized", this.init)

local function onEquip(e)
    if e.item.id == "mc_firestarter" then
        tes3.messageBox("To use the fire kit, place it where you wish to build the fire and activate it.")
    end
end

local function onActivate(e)
    if (e.activator == tes3.player) then
        if e.target.object.id == "mc_firestarter" then
            eObjectRef = e.target
            this.createWindow()
            return false
        end
    end
end
event.register("activate", onActivate)
event.register("equip", onEquip)