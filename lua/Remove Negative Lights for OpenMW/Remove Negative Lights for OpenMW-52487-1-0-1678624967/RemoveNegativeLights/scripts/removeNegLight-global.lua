local types = require('openmw.types')

local Light = types.Light

local darkname = 'dark_'

local function onObjectActive(object)
    if (not object.enabled) then return end
    
    if (not Light.objectIsInstance(object)) then return end

    local record = Light.record(object)

    if (record.model == 'meshes\\') and (string.match(record.id,darkname)) then
        object.enabled = false
    end
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive
    }
}