local nearby = require('openmw.nearby')
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local types = require('openmw.types')

local function ShowMessage(mess)
ui.showMessage(mess)

end

local ambient = require('openmw.ambient')
local function playSoundEvent(soundId)
    ambient.playSound(soundId)
end

local function OpenEnchantMenu(obj)
    I.UI.setMode("Enchanting",{target =obj})
end

local function OpenHarvestingContainer(Actor)
I.UI.addMode('Container', {target = Actor})
end


return {
    eventHandlers = { ShowMessage = ShowMessage, playSoundEvent = playSoundEvent, OpenEnchantMenu = OpenEnchantMenu, OpenHarvestingContainer = OpenHarvestingContainer },
}