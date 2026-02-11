local input = require('openmw.input')
local storage = require('openmw.storage')
local self = require('openmw.self') 
local Interface = require('scripts.Completionist.interface')
local Mechanics = require('scripts.Completionist.mechanics')

local optionsSection = storage.playerSection('Settings/Completionist/Options')

-- =============================================================================
-- EVENT HANDLER
-- =============================================================================
local function onRegisterPack(data)
    if type(data) == "table" then
        Mechanics.registerQuests(data)
        print("[Completionist] Pack de quests registrado via Evento.")
    end
end

-- =============================================================================
-- ENGINE HANDLERS
-- =============================================================================
local function onKeyPress(key)
    local configuredKey = optionsSection:get("Hotkey") or input.KEY.K
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

return { 
    engineHandlers = { 
        onKeyPress = onKeyPress, 
        onInputAction = onInputAction,
        onMouseWheel = onMouseWheel,
        onSave = Mechanics.onSave,
        onLoad = Mechanics.onLoad
    },
    eventHandlers = {
        Completionist_RegisterPack = onRegisterPack
    }
}