--[[
    Handles events and player input for command menu
]]
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("CommandMenuController")
local commandMenu = require("mer.theGuarWhisperer.CommandMenu.CommandMenu")

--check if activate key is down
local function didPressActivate()
    local inputController = tes3.worldController.inputController
    return inputController:keybindTest(tes3.keybind.activate)
end

--Check if toggle key is down
local function didPressToggleKey(e)
    local toggleKey = common.config.mcm.commandToggleKey
    return toggleKey
        and e.keyCode == toggleKey.keyCode
        and not not e.isShiftDown == not not toggleKey.isShiftDown
        and not not e.isControlDown == not not toggleKey.isControlDown
        and not not e.isAltDown == not not toggleKey.isAltDown
end

--Check if modifier is pressed
local function hasModifierPressed()
    local inputController = tes3.worldController.inputController
    local pressedModifier = inputController:isKeyDown(tes3.scanCode.lShift)
    logger:debug("Pressed modifier? %s", pressedModifier)
    return pressedModifier
end


---@param e keyDownEventData
event.register("keyDown", function(e)
    if tes3.menuMode() then
        return
    end
    --Pressed Activate
    if didPressActivate() then

        if commandMenu.activeCompanion then
            --can activate as long as we aren't looking at another reference
            local target = tes3.getPlayerTarget()
            if target == nil or target == commandMenu.activeCompanion.reference then
                commandMenu:performAction()
            end
        end
    else
        --Check if Command button was pressed
       if didPressToggleKey(e) then
            return commandMenu:toggleCommandMenu()
        end
    end
end)

---Scroll through command options
---@param e mouseWheelEventData
event.register("mouseWheel", function(e)
    if not common.data then return end
    if tes3ui.menuMode() then return end
    if commandMenu.activeCompanion then
        if e.delta < 0 then
            commandMenu:scrollUp()
        else
            commandMenu:scrollDown()
        end
    end
end)

---Open the command menu
---@param e { guar: GuarWhisperer.GuarCompanion}
event.register("TheGuarWhisperer:showCommandMenu", function(e)
    logger:debug("activating menu")
    if hasModifierPressed() and e.guar.pack:hasPack() then
        e.guar.pack:takeItemLookingAt()
    else
        commandMenu:showCommandMenu(e.guar)
    end
end)

--Allow exiting of command menu
event.register("mouseButtonDown", function(e)
    if e.button == tes3.worldController.inputController.inputMaps[19].code then
        commandMenu:destroy()
    end
end)