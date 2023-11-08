-- Declarations --
local self = require('openmw.self')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')

-- Event Handlers --
local function sortingComplete()
    ambient.playSound("Item Bodypart Down")
    ui.showMessage("Sorting complete!")
end

local function sendPickupSound()
    ambient.playSound("Item Bodypart Up")
end

-- Return --
return {
    eventHandlers = {
        sortingComplete = sortingComplete,
        sendPickupSound = sendPickupSound
    }
}