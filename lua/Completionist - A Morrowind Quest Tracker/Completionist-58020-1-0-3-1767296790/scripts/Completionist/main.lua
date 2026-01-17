local input = require('openmw.input')
local storage = require('openmw.storage')
local Interface = require('scripts.Completionist.interface')

require('scripts.Completionist.load_quests') 

local optionsSection = storage.playerSection('Settings/Completionist/Options')

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
        onMouseWheel = onMouseWheel --
    } 
}