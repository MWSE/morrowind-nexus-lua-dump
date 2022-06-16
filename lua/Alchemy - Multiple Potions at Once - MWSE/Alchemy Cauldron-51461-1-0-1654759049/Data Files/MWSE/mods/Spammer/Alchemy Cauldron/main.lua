local mod = {
    name = "Alchemy Cauldron",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }

local ingredients = {
    "MenuAlchemy_ingredient_one",
    "MenuAlchemy_ingredient_two",
    "MenuAlchemy_ingredient_three",
    "MenuAlchemy_ingredient_four"
}
---comment
---@param e table|uiActivatedEventData
event.register("uiActivated", function(e)
    local create = e.element:findChild("MenuAlchemy_create_button")
    local name = e.element:findChild("MenuAlchemy_potion_name")
    name.parent:register("mouseClick", function() tes3ui.acquireTextInput(name) end)
    local block = create.parent:createBlock()
    block.height = 30
    block.autoWidth = true
    local minus = block:createButton{text = "-"}
    local text = block:createThinBorder():createTextInput{placeholderText = "1", numeric = true, autoFocus = false}
    text.parent.width = 90
    text.parent.height = 30
    text.width = 88
    text.height = 28
    text.wrapText = true
    text.justifyText = "center"
    text.parent:register("mouseClick", function() text:triggerEvent("mouseClick") end)
    text.borderLeft = 5
    text.borderRight = 5
    text.widget.lengthLimit = 3
    local plus = block:createButton{text = "+"}
    block.parent:reorderChildren(0, -1, 1)
    minus:register("mouseClick", function()
        if tonumber(text.text) > 1 then
            text.text = text.text-1
            text:triggerEvent("textUpdated")
        else
            text.text = "1"
            text:triggerEvent("textUpdated")
        end
    end)
    plus:register("mouseClick", function()
        text.text = text.text+1
        text:triggerEvent("textUpdated")
    end)
    text:registerAfter("textUpdated", function(t)
        create:register("mouseClick", function(f)
            local count = 1000
            local empty = 0
            for _,v in ipairs(ingredients) do
                local slot = e.element:findChild(v)
                local ing = slot:findChild("MenuAlchemy_count") and slot:findChild("MenuAlchemy_count").text
                if ing and count >= tonumber(ing) then
                    count = tonumber(ing)
                elseif (not ing) and slot.children[1] then
                    count = 1
                elseif (not ing) then
                    empty = empty+1
                end
            end
            --debug.log(empty)
            if empty >= 3 then
                tes3.messageBox("%s", tes3.findGMST("sNotifyMessage6a").value)
                return
            end
            local number = tonumber(t.source.text)
            --debug.log(number)
            --debug.log(tonumber(t.source.text))
            if (number > 0) and (number <= count) then
                for _ = 1, number do
                    f.source:forwardEvent(f)
                end
            elseif (number > 0) then
                for _ = 1, count do
                    f.source:forwardEvent(f)
                end
            else
                tes3.messageBox("Invalid number of potions provided! Will only craft one!")
                f.source:forwardEvent(f)
            end
        end)
    end)
    e.element:registerAfter("update", function() text:triggerEvent("textUpdated") end)
    e.element:updateLayout()
end, {filter = "MenuAlchemy"})

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})