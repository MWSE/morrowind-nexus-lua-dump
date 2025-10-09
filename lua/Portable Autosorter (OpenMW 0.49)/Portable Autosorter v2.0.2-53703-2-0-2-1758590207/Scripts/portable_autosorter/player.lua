-- Declarations --
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')

-- Event Handlers --
local function sortingComplete()
    ambient.playSound("spellmake success")
    ui.showMessage("Sorting complete!")
end

-- Return --
return {
    eventHandlers = {
        sortingComplete = sortingComplete
    }
}