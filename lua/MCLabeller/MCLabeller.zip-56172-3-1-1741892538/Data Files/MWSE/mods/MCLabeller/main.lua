--[[ Script for showing special tooltips outside of other tools
	part of Morrowind Crafting 3
	Toccatta and Drac  c/r 2019 ]]--

    local this = {}
    local mc = require("Morrowind_Crafting_3.mc_common")
    --local recipes = require("Morrowind_Crafting_3.Mining.recipes")
    local configPath = "Morrowind_Crafting_3"
    local config = mwse.loadConfig(configPath)
    local menu, inputLabel
    local textFilter = ""

    function this.init()
        this.id_menu = tes3ui.registerID("UID_LabelMenu")
        UID_filterText = tes3ui.registerID("UID_LabelText::Input")
        mwse.log("Container Labels initialized")
    end

    -- Cancel button
    local function onCancel(e)
	    local menu = tes3ui.findMenu(this.id_menu)
	    if (menu) then
		    tes3ui.leaveMenuMode()
            menu:destroy()
            return false
	    end
    end

    function playerAllowed(containerRef)
        --[[
        local owner = tes3.getOwner(containerRef)
        if (owner) then
            if (owner.playerJoined) then
                if (containerRef.attachments["variables"].requirement <= owner.playerRank) then
                    return true
                end
            end
            return false
        end
        ]]  -- uncomment this block if you want labelling owned objects to be disallowed
        return true
    end

    function getAlt()
        local inputController = tes3.worldController.inputController
        return (
            inputController:isKeyDown(tes3.scanCode.leftAlt)
            or inputController:isKeyDown(tes3.scanCode.rightAlt)
        )
    end

    local function forceInstance(reference)
        local object = reference.object
        if (object.isInstance == false) then
            --tes3.messageBox("Cloning object!!!")
            object:clone(reference)
            reference.modified = true
        end
        return reference --.object
    end

    local function extraTooltip(e)
        local label
        if (e.object.objectType == tes3.objectType.container) or (e.object.objectType == tes3.objectType.door) then
            if e.tooltip then
                e.tooltip.flowDirection = "top_to_bottom"
                e.tooltip.autoHeight = true
            end
            if e.reference.data.alias then
                local element = e.tooltip:findChild("HelpMenu_name")
                if (element ~= nil) then element.visible = false end
                element = e.tooltip:findChild("UIEXP_Tooltip_ExtraDivider")
                if (element ~= nil) then element.visible = false end
                element = e.tooltip:findChild("HelpMenu_locked")
                if (element ~= nil) then element.visible = false end
                local aliasBlock = e.tooltip:createBlock()
                aliasBlock.autoHeight = true
                aliasBlock.autoWidth = true
                aliasBlock.paddingAllSides = 0
                label = aliasBlock:createLabel{text = e.reference.data.alias}
                label.color = tes3ui.getPalette("header_color")

                if (e.object.objectType == tes3.objectType.door) then
                    element = e.tooltip:findChild("HelpMenu_destinationTo")
                    if (element ~= nil) then element.visible = false end
                    element = e.tooltip:findChild("HelpMenu_destinationCell")
                    if (element ~= nil) then element.visible = false end
                    if (e.reference.destination.cell ~= nil) then
                        local toBlock = e.tooltip:createBlock()
                        toBlock.autoHeight = true
                        toBlock.autoWidth = true
                        toBlock.paddingAllSides = 0
                        label = toBlock:createLabel{text = tes3.findGMST("sTo").value}
                    
                        local destBlock = e.tooltip:createBlock()
                        destBlock.autoHeight = true
                        destBlock.autoWidth = true
                        destBlock.paddingAllSides = 0
                        label = destBlock:createLabel{text = e.reference.destination.cell.displayName}
                    end
                end
                
                if (tes3.getLockLevel(e) ~= nil) then
                    local lockBlock = e.tooltip:createBlock()
                    lockBlock.autoHeight = true
                    lockBlock.autoWidth = true
                    lockBlock.paddingAllSides = 0
                    local lLvl = tes3.findGMST("sLockLevel").value
                    local lVal = tes3.getLockLevel(e)
                    if (tes3.getLocked(e) == false) then lVal = tes3.getGMST("sUnlocked").value end
                    label = lockBlock:createLabel{text = lLvl..": "..lVal}
                end
            end
        end
    end

    function this.createWindow(reference)
        if (tes3ui.findMenu(this.id_menu) ~= nil) then
            return
        end
        tes3ui.enterMenuMode()
        menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
        menu.width = 620
        menu.autoHeight = true
        menu.minWidth = 620
        --menu.minHeight = 60
        menu.positionX = menu.width / -2
        menu.positionY = menu.height / 2
        menu.flowDirection = "top_to_bottom"
        menu.childAlignX = 0.5
        local filterLabel = menu:createLabel({ text = "Label As:"})
        local menuBlock = menu:createBlock{}
        menuBlock.flowDirection = "left_to_right"
        menuBlock.widthProportional = 1.0
        menuBlock.autoHeight = true
        menuBlock.childAlignX = -1.0
		filterLabel.borderRight = 2
		local filterInputBorder = menuBlock:createThinBorder{}
		filterInputBorder.widthProportional = 0.3
        filterInputBorder.height = 24
		filterInputBorder.childAlignX = 0.5
		filterInputBorder.childAlignY = 0.5
		filterInputBorder.absolutePosAlignY = 0.5

		local filterTextInput = filterInputBorder:createTextInput({ id = UID_filterText })
		filterTextInput.borderLeft = 5
		filterTextInput.borderRight = 5
		filterTextInput.widget.lengthLimit = 60
		filterTextInput.widget.eraseOnFirstKey = true

        if reference.data.alias then
            textFilter = reference.data.alias
        else
            textFilter = ""
        end

		filterTextInput.text = textFilter

        filterTextInput.widthProportional = 0.3

        local safeRef = tes3.makeSafeObjectHandle(reference)

		filterTextInput:register("keyEnter",
			function()
			local text = filterTextInput.text
			if (text == "") then
				textFilter = ""
			else
                if safeRef:valid() then
                    textFilter = text
                    forceInstance(safeRef:getObject())
                    if textFilter == " " then textFilter = nil end
                    reference.data.alias = textFilter
                    if textFilter ~= nil then tes3.messageBox("Labeled as ("..textFilter..")") end
                    textFilter = ""
                end
			end
            menu:destroy()
            tes3ui.leaveMenuMode()
			end )
        local buttonCancel = menuBlock:createButton{id = "UID_labelerButton", text = tes3.findGMST("sCancel").value}
        menu:updateLayout()
        buttonCancel:register("mouseClick", onCancel)
        tes3ui.acquireTextInput(filterTextInput)

    end

    local function makeLabel()
        local temp
        if mc.getAlt() == true then --Verify is container & unowned
            local target = tes3.getPlayerTarget()
            if target and mc.playerAllowed(target) and ((target.object.objectType == tes3.objectType.container) or (target.object.objectType == tes3.objectType.door)) then
                this.createWindow(target)
			else
                tes3.messageBox("You cannot label this object.")
            end
        end
    end

    event.register("initialized", this.init)
    event.register("uiObjectTooltip", extraTooltip, {priority = 101})
    event.register("keyUp", makeLabel, {filter = tes3.scanCode.l})