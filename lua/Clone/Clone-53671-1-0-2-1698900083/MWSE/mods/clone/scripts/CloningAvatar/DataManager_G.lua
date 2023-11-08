local data = {}
local world = require("openmw.world")
local function onSave()
    return { data = data }
end
local function onLoad(tdata)
    if not tdata then return end
    data = tdata.data
end
local function setValue(varName, var)
    data[varName] = var
end
local function getValue(varName)
    return data[varName]
end
return {
    interfaceName = "CA_DataManager",
    interface = {
        getValue = getValue,
        setValue = setValue
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = {
    }
}
