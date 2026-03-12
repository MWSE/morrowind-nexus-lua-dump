local log = mwse.Logger.new()
log.level = "INFO"
local config = require("alchemyQuickOpen.config")
local strings = require("alchemyQuickOpen.strings")

local GUI_ID = {}
local state = {
    registeredEvents = {},
}

local function registerGUI()
	GUI_ID.MenuInventory = tes3ui.registerID("MenuInventory")
	GUI_ID.MenuQuantity = tes3ui.registerID("MenuQuantity")
end

local function isInventoryAvailable()
    local menuInventory = tes3ui.findMenu(GUI_ID.MenuInventory)
    return menuInventory and menuInventory.visible
end

local function onInput(e)
    -- Check for match with keybind
    if not tes3.isKeyEqual({ expected = config.keybind, actual = e }) then
        return
    end
    -- Make sure we aren't holding something
    if tes3ui.getCursorTile() then
        return
    end
    -- Make sure MenuQuantity isn't at the top
    local topMenu = tes3ui.getMenuOnTop()
    if topMenu and topMenu.id == GUI_ID.MenuQuantity then
        return
    end
    -- Check that inventory is open
    if not isInventoryAvailable() then
        return
    end

    -- Check inventory for mortar and pestle
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.objectType == tes3.objectType.apparatus and
        stack.object.type == tes3.apparatusType.mortarAndPestle then
            tes3.playItemPickupSound{item = stack.object}
            tes3.showAlchemyMenu()
            e.claim = true
            return
        end
    end

    tes3.messageBox{message = strings.cannotOpen}
end

local function registerKeybindEvent(tes3event)
    if state.registeredEvents[tes3event] then
        return
    end

    log:debug("register for event %s", tes3event)
    event.register(tes3event, onInput)
    state.registeredEvents[tes3event] = true
end

local function onMenuEnter(e)
    if not isInventoryAvailable() then
        return
    end

    if config.keybind.keyCode ~= false then
        registerKeybindEvent(tes3.event.keyUp)
    end
    if config.keybind.mouseButton ~= false then
        registerKeybindEvent(tes3.event.mouseButtonUp)
    end
    if config.keybind.mouseWheel ~= false then
        registerKeybindEvent(tes3.event.mouseWheel)
    end
end

local function onMenuExit(e)
    for tes3event, _ in pairs(state.registeredEvents) do
        log:debug("unregister for event %s", tes3event)
        event.unregister(tes3event, onInput)
    end
    state.registeredEvents = {}
end

local function onModConfigEntryClosed()
    onMenuExit()
    if tes3.menuMode() then
        onMenuEnter()
    end
end

local function onInitialized(e)
    event.register(tes3.event.modConfigEntryClosed, onModConfigEntryClosed, {filter = strings.mcm.modName})
    event.register(tes3.event.menuEnter, onMenuEnter)
    event.register(tes3.event.menuExit, onMenuExit)
    registerGUI()
end

event.register(tes3.event.initialized, onInitialized)
