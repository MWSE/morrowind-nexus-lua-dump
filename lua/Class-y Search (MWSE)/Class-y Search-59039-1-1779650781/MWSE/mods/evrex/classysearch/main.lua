-- Class-y Search
-- Author: everything_rex
-- Adds a real-time search bar to the premade class selection menu

local function onMenuChooseClass(e)
	if not e.newlyCreated then
        return
    end
    local menu = e.element
    local classScroll = menu:findChild("MenuChooseClass_ClassScroll")
    if not classScroll then
        mwse.log("[ClassySearch] classScroll NOT found")
        return
    end
    local pane = menu:findChild("PartScrollPane_pane")
    if not pane then
        mwse.log("[ClassySearch] pane NOT found")
        return
    end
    local grandParent = classScroll.parent.parent

    -- Create search border
    local border = grandParent:createThinBorder()
    border.autoWidth = true
    border.autoHeight = true
    border.widthProportional = 1.0
    border.borderTop = 1
    border.borderBottom = 6
    border.borderLeft = 4
    border.borderRight = 4
	border.paddingAllSides = 1

    -- Create search input
    local searchInput = border:createTextInput({
        id = "ClassySearch_input",
        placeholderText = "Search by name...",
        autoFocus = true,
    })
    searchInput.borderLeft = 5
    searchInput.borderRight = 15
    searchInput.borderTop = 0
    searchInput.borderBottom = 4
	searchInput.widget.lengthLimit = 33

    -- Clear label anchored to the right
    local clearLabel = border:createLabel({ id = "ClassySearch_clear", text = "X" })
    clearLabel.absolutePosAlignX = 1.0
    clearLabel.absolutePosAlignY = 0.5
    clearLabel.borderRight = 4

    -- Re-acquire focus on click
    border:registerAfter(tes3.uiEvent.mouseClick, function()
        tes3ui.acquireTextInput(searchInput)
    end)

    -- Filter class list on every key press
    local function filterClasses()
        local query = searchInput.text:lower()
        local searching = not searchInput.widget:getIsPlaceholding() and query:len() > 0
        for _, child in ipairs(pane.children) do
            if child.text then
                if searching then
                    child.visible = child.text:lower():find(query, 1, true) ~= nil
                else
                    child.visible = true
                end
            end
        end
        menu:updateLayout()
    end

    -- Clear on click
    clearLabel:register(tes3.uiEvent.mouseClick, function()
        searchInput.widget:clear()
        filterClasses()
        tes3ui.acquireTextInput(searchInput)
    end)

    searchInput:registerAfter("keyPress", filterClasses)

    -- Move search border to the top
    grandParent:reorderChildren(0, -1, 1)

    menu:updateLayout()
    mwse.log("[ClassySearch] search bar created")
end
event.register("uiActivated", onMenuChooseClass, { filter = "MenuChooseClass" })