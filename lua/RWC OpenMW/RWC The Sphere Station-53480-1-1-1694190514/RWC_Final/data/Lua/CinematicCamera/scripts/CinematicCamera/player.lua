local storage = require('openmw.storage')
local A = require('openmw.types').Actor
local self = require('openmw.self')
local ui = require('openmw.ui')

require('scripts.CinematicCamera.settings')

local controlsSettings = storage.playerSection('SettingsCinematicCameraControls')

local MODES = {
    Off = 'off',
    Free = 'free',
    FirstPerson = 'firstPerson',
}

local modeHotkeys = {
    freeHotkey = MODES.Free,
    firstPersonHotkey = MODES.FirstPerson,
}

local modeModules = {
    [MODES.Off] = {
        on = function() end,
        update = function() end,
        off = function() end,
    },
    [MODES.Free] = require('scripts.CinematicCamera.free'),
    [MODES.FirstPerson] = require('scripts.CinematicCamera.firstPerson'),
}

local currentMode = MODES.Off

local function toggleMode(mode)
    local prevMode = currentMode
    modeModules[prevMode].off()
    if mode == currentMode then
        currentMode = MODES.Off
    else
        currentMode = mode
    end
    modeModules[currentMode].on()
end

return {
    engineHandlers = {
    
        onInputAction = function(id)
            if id >= 5 and id <= 8 then     -- action move W,A,S,D

                local helmet = A.equipment(self, A.EQUIPMENT_SLOT.Helmet)
                if helmet and helmet.recordId:find('space_ship') then 
                    
                    if currentMode ~= MODES.FirstPerson then toggleMode(MODES.FirstPerson) end
                else
                     
                    if currentMode == MODES.FirstPerson then toggleMode(MODES.FirstPerson) end
                end
                
            end
        end, 
       
        onFrame = function(dt)
            modeModules[currentMode].update(dt)
        end,
    }
}
