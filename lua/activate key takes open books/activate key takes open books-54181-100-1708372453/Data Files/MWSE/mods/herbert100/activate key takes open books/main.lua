local activate = tes3.keybind.activate
local book_menu_id
local scroll_menu_id
local book_take_btn_id
local scroll_take_btn_id

event.register("keyDown", function(e)
    if e.keyCode ~= tes3.getInputBinding(activate).code 
    or tes3.getInputBinding(activate).device ~= 0 -- 0 is keyboard
    or not tes3.menuMode()
    then return end
    
    local menu = tes3ui.findMenu(book_menu_id)
    if menu then
        local btn = menu:findChild(book_take_btn_id)
        if btn then btn:triggerEvent("mouseClick") end
        return
    end
    menu = tes3ui.findMenu(scroll_menu_id)
    if menu then
        local btn = menu:findChild(scroll_take_btn_id)
        if btn then btn:triggerEvent("mouseClick") end
    end
end)
-- do the same thing, but for the special case when the activate button is bound to a mouse button
---@param e mouseButtonDownEventData
event.register("mouseButtonDown", function(e)
    if e.button ~= tes3.getInputBinding(activate).code 
    or tes3.getInputBinding(activate).device ~= 1 -- 1 is mouse
    or not tes3.menuMode()
    then return end
    
    local menu = tes3ui.findMenu("MenuBook")
    if menu then
        local btn = menu:findChild(book_take_btn_id)
        if btn then btn:triggerEvent("mouseClick") end
        return
    end
    menu = tes3ui.findMenu("MenuScroll")
    if menu then
        local btn = menu:findChild(scroll_take_btn_id)
        if btn then btn:triggerEvent("mouseClick") end
    end
end)

event.register("initialized",function(e)
    mwse.log("[activate key takes open books] mod initialized")
    book_menu_id = tes3ui.registerID("MenuBook")
    scroll_menu_id = tes3ui.registerID("MenuScroll")
    book_take_btn_id = tes3ui.registerID("MenuBook_button_take")
    scroll_take_btn_id = tes3ui.registerID("MenuBook_PickupButton")
end)