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
        if e.object.objectType == tes3.objectType.container then
            if e.tooltip then
                e.tooltip.flowDirection = "top_to_bottom"
                e.tooltip.autoHeight = true
            end
            if e.reference.data.alias then
                local aliasBlock = e.tooltip:createBlock()
                aliasBlock.autoHeight = true
                aliasBlock.autoWidth = true
                aliasBlock.paddingAllSides = 4
                label = aliasBlock:createLabel{text = e.reference.data.alias}
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
            if target and mc.playerAllowed(target) and (target.object.objectType == tes3.objectType.container) then
                this.createWindow(target)
			else
                tes3.messageBox("You cannot label this object.")
            end
        end
    end




    event.register("initialized", this.init)
    event.register("uiObjectTooltip", extraTooltip, {priority = -100})
    event.register("keyUp", makeLabel, {filter = tes3.scanCode.l})