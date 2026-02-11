local input = require('openmw.input')
local storage = require('openmw.storage')
local Interface = require('scripts.Perfectionist.interface')
local Mechanics = require('scripts.Perfectionist.mechanics')

local optionsSection = storage.playerSection('Settings/Perfectionist/Options')

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

local function onRegisterData(data)
    if type(data) == "table" then
        Mechanics.registerData(data)
    end
end

-- =============================================================================
-- ENGINE HANDLERS
-- =============================================================================

local function onKeyPress(key)
    local configuredKey = optionsSection:get("Hotkey") or input.KEY.L
    if key.code == configuredKey then 
        Interface.toggleMenu()
    elseif key.code == input.KEY.Escape and Interface.isVisible() then 
        Interface.toggleMenu() 
    end
end

local function onInputAction(id)
    if Interface.isVisible() and (id == input.ACTION.Inventory or id == input.ACTION.Journal) then 
        Interface.toggleMenu() 
    end
end

local function onMouseWheel(vScroll, hScroll)
    if Interface.isVisible() then
        Interface.onMouseWheel(vScroll)
    end
end

local function onUpdate(dt)
    Mechanics.onUpdate(dt)
end

return { 
    engineHandlers = { 
        onKeyPress = onKeyPress, 
        onInputAction = onInputAction,
        onMouseWheel = onMouseWheel,
        onSave = Mechanics.onSave,
        onLoad = Mechanics.onLoad,
        onUpdate = onUpdate
    },
    eventHandlers = {
        Perfectionist_RegisterData = onRegisterData
    }
}