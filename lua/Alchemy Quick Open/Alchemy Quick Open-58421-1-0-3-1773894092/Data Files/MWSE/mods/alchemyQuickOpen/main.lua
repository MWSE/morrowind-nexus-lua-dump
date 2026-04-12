local log = mwse.Logger.new()
log.level = "INFO"
local config = require("alchemyQuickOpen.config")
local i18n = require("alchemyQuickOpen.i18n")

local GUI_ID = {}
local state = {
    registeredEvents = {},
}

local ignoreMenus = {}
function ignoreMenus:add(menu)
    self[tes3ui.registerID(menu)] = true
end

local function registerGUI()
    GUI_ID.MenuInventory = tes3ui.registerID("MenuInventory")

    ignoreMenus:add("MenuQuantity")
    ignoreMenus:add("MenuMapNoteEdit")
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
    -- Check that top menu isn't ignored
    local topMenu = tes3ui.getMenuOnTop()
    if ignoreMenus[topMenu.id] then
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

    tes3.messageBox{message = i18n("cannotOpen")}
end

local function registerKeybindEvent(tes3event)
    if state.registeredEvents[tes3event] then
        return
    end

    log:debug("register for event %s", tes3event)
    event.register(tes3event, onInput)
    state.registeredEvents[tes3event] = true
end

local function isValid(var)
    return var ~= false and var ~= nil
end

local function onMenuEnter(e)
    if not isInventoryAvailable() then
        return
    end

    if isValid(config.keybind.keyCode) then
        registerKeybindEvent(tes3.event.keyUp)
    end
    if isValid(config.keybind.mouseButton) then
        registerKeybindEvent(tes3.event.mouseButtonUp)
    end
    if isValid(config.keybind.mouseWheel) then
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
    event.register(tes3.event.modConfigEntryClosed, onModConfigEntryClosed, {filter = i18n("mcm.modName")})
    event.register(tes3.event.menuEnter, onMenuEnter)
    event.register(tes3.event.menuExit, onMenuExit)
    registerGUI()
end

event.register(tes3.event.initialized, onInitialized)
