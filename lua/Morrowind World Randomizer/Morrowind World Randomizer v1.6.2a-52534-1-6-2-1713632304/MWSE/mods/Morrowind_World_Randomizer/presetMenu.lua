local config = include("Morrowind_World_Randomizer.config")

local this = {}

-- Some code taken from EasyMCM https://github.com/jhaakma/EasyMCM

this.menuId = tes3ui.registerID("profileMenu:menuId")
this.i18n = nil

function this.createMenu(okFunction, cancelFunction)
    if (tes3ui.findMenu(this.menuId) ~= nil) then
        return
    end

    local menu = tes3ui.createMenu{ id = this.menuId, fixedFrame = true }

    menu.alpha = 1.0
    menu.minWidth = 400
    menu.minHeight = 300
    menu.width = 400
    menu.height = 300
    menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2

    menu:register("unfocus", function(e)
        return false
    end)

    local textLabel = menu:createLabel{ text = this.i18n("modConfig.label.selectRandProfile") }
    textLabel.borderBottom = 5

    local scrollPane = menu:createVerticalScrollPane()
    scrollPane.widthProportional = 1.0
    scrollPane.heightProportional = 1.0
    scrollPane.autoHeight = true
    scrollPane:setPropertyBool("PartScrollPane_hide_if_unneeded", true)

    local dropdown = scrollPane:createThinBorder()
    dropdown.flowDirection = "top_to_bottom"
    dropdown.autoHeight = true
    dropdown.widthProportional = 1.0
    dropdown.paddingAllSides = 6
    dropdown.borderTop = 0

    local profileList = {}

    for label, val in pairs(config.profiles) do
        table.insert(profileList, label)
    end

    local createDropdownItem = function(label)
        local item = dropdown:createTextSelect{ text = label }
        item.widthProportional = 1.0
        item.autoHeight = true
        item.borderBottom = 3
        item.widget.idle = tes3ui.getPalette("normal_color")
        item.widget.over = tes3ui.getPalette("normal_over_color")
        item.widget.pressed = tes3ui.getPalette("normal_pressed_color")
        return item
    end

    local selectedProfile = "default"
    local item = createDropdownItem(selectedProfile)

    local dropdownActive = true
    local dropdownClick
    for _, label in ipairs(profileList) do

        local listItem = createDropdownItem(label)
        listItem:register("mouseClick", function ()
            dropdown:destroyChildren()
            item = createDropdownItem(label)
            item:register("mouseClick", dropdownClick)
            selectedProfile = label
            dropdownActive = false
            menu:updateLayout()
        end)
    end
    dropdownClick = function()
        if not dropdownActive then
            dropdownActive = true
            for _, label in ipairs(profileList) do

                local listItem = createDropdownItem(label)
                listItem:register("mouseClick", function ()
                    dropdown:destroyChildren()
                    item = createDropdownItem(label)
                    item:register("mouseClick", dropdownClick)
                    selectedProfile = label
                    dropdownActive = false
                    menu:updateLayout()
                end)
            end
        else
            dropdownActive = false
            dropdown:destroyChildren()
            item = createDropdownItem(selectedProfile)
            item:register("mouseClick", dropdownClick)
        end
        menu:updateLayout()
    end

    item:register("mouseClick", dropdownClick)

    local button_block = menu:createBlock()
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 1.0

    local button_ok = button_block:createButton{ text = tes3.findGMST("sOK").value }
    local button_cancel = button_block:createButton{ text = tes3.findGMST("sCancel").value }

    button_cancel:register(tes3.uiEvent.mouseClick, function()
        tes3ui.leaveMenuMode()
        menu:destroy()
        if cancelFunction then cancelFunction() end
    end)
    button_ok:register(tes3.uiEvent.mouseClick, function()
        local profile = "default"
        if selectedProfile and selectedProfile ~= "" then
            profile = selectedProfile
        end
        config.loadProfile(profile)
        tes3ui.leaveMenuMode()
        menu:destroy()
        if okFunction then okFunction(profile) end
    end)

    menu:updateLayout()
    tes3ui.enterMenuMode(this.menuId)
end

return function(i18n)
    this.i18n = i18n
    return this
end