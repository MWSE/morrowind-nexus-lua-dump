local storage = require('openmw.storage')
local async = require('openmw.async')

local localConfigLib = require("scripts.fancy_door_randomizer.config")
local storageName = localConfigLib.storageName

return {
    eventHandlers = {
        fdrbd_updateSettings = async:callback(function(data)
            local configData = data.configData
            if not configData then return end
            localConfigLib.data = configData
            local function filStorage(storageSection)
                for name, val in pairs(storageSection:asTable()) do
                    local confVal = localConfigLib.getValueByString(name)
                    if confVal ~= nil and confVal ~= val then
                        storageSection:set(name, confVal)
                    end
                end
            end
            filStorage(storage.playerSection(storageName))
            filStorage(storage.playerSection(storageName.."_inToEx"))
            filStorage(storage.playerSection(storageName.."_inToIn"))
            filStorage(storage.playerSection(storageName.."_exToEx"))
            filStorage(storage.playerSection(storageName.."_exToIn"))
            require("scripts.fancy_door_randomizer.settings")
        end),
    },
}