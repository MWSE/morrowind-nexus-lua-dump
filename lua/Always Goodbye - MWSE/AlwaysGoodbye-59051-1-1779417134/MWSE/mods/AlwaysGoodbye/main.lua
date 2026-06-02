local modName = "Always Goodbye"

local configModule = require("AlwaysGoodbye.config")
local config = configModule.current

require("AlwaysGoodbye.mcm")

local ID_GoodbyeButton = tes3ui.registerID("MenuDialog_button_bye")
local ID_HookedGoodbye = tes3ui.registerID("AlwaysGoodbye:HookedGoodbye")

local function hookGoodbye()
    if not config.enabled then
        return
    end

    local menu = tes3ui.findMenu("MenuDialog")

    if not menu then
        return
    end

    local goodbye = menu:findChild(ID_GoodbyeButton)

    if not goodbye then
        return
    end

    -- Prevent attaching this handler more than once to the same Goodbye button.
    if goodbye:findChild(ID_HookedGoodbye) then
        return
    end

    local marker = goodbye:createBlock({
        id = ID_HookedGoodbye,
    })
    marker.visible = false

    -- The vanilla button can look clickable but refuse to close dialogue
    -- during red-text decision prompts. This forces it to close the dialogue menu.
    goodbye.disabled = false
    goodbye.visible = true

    goodbye:register(tes3.uiEvent.mouseClick, function()
        local currentMenu = tes3ui.findMenu("MenuDialog")

        if currentMenu then
            currentMenu:destroy()
        end
    end)

    menu:updateLayout()
end

local function delayedDialogueCheck()
    timer.delayOneFrame(hookGoodbye)
end

event.register(tes3.event.uiActivated, function(e)
    local name = e.element and e.element.name

    if name ~= "MenuDialog" then
        return
    end

    delayedDialogueCheck()
end)

mwse.log("[%s] Initialized.", modName)