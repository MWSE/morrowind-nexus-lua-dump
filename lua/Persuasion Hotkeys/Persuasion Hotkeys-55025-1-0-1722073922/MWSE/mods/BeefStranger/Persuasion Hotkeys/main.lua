local cfg = require("BeefStranger.Persuasion Hotkeys.config")

local function openPersuasion()
    local dialogue = tes3ui.findMenu("MenuDialog")
    if dialogue then
        dialogue:findChild("MenuDialog_persuasion"):triggerEvent(tes3.uiEvent.mouseClick)
    else
        return
    end
end

--- @param name "Admire"|"Intimidate"|"Taunt"
local function pressButton(name)
    local persuasion = tes3ui.findMenu("MenuPersuasion")
    if persuasion then
        local serviceList = persuasion:findChild("MenuPersuasion_ServiceList")
        for _, element in pairs(serviceList.children) do
            if element.children[1].text == name then
                return element.children[1]:triggerEvent(tes3.uiEvent.mouseClick)
            end
        end
    else
        return
    end
end

---@param e keyDownEventData
local function keyDown(e)
    if e.keyCode == cfg.persuade.keyCode then
        openPersuasion()
    end
    if e.keyCode == cfg.admire.keyCode then
        pressButton("Admire")
    end
    if e.keyCode == cfg.intimidate.keyCode then
        pressButton("Intimidate")
    end
    if e.keyCode == cfg.taunt.keyCode then
        pressButton("Taunt")
    end
end
event.register("keyDown", keyDown)


event.register("initialized", function()
    print("[MWSE:Persuasion Hotkeys] initialized")
end)