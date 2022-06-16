

---comment
---@param e table|uiActivatedEventData
event.register("uiActivated", function(e)
    local ok = e.element:findChild("MenuLevelUp_Okbutton")
    local close = ok.parent:createButton{id = "MenuLevelUp_Closebutton", text = tes3.findGMST("sCancel").value}
    e.element:updateLayout()
    close:register("mouseClick", function()
        e.element:destroy()
        tes3ui.leaveMenuMode()
    end)
end, {filter = "MenuLevelUp"})

event.register("initialized", function()
    local rightClick = include("mer\\RightClickMenuExit\\init")
    if rightClick then
        rightClick.registerMenu{menuId = "MenuLevelUp", buttonId = "MenuLevelUp_Closebutton"}
    end
    print("[I'll Level Up Later, by Spammer] 1.0 Initialized!")
end, {priority = -1000})