local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local interfaces = require('openmw.interfaces')

local function onLoad()
    types.Player.sendMenuEvent(self.object, 'requireCurrentSaveDir')
end

local function clearStorage()

    local macData = interfaces.storageUtils.getStorage("achievements")
    local macDataTable = interfaces.storageUtils.getStorage("achievements"):asTable()

    for k, v in pairs(macDataTable) do
        if v == true then
            macData:set(k, false)
        end
    end

end

return {
    engineHandlers = {
        onLoad = onLoad
    },
    eventHandlers = {
        clearStorage = clearStorage
    }
}