--global
local storedVars = {}
local function saveVariable(varName, var)
    storedVars[varName] = var
end
local function getVariable(varName, var)
    return storedVars[varName]
end

local function onSave()
    return storedVars
end
local function onLoad(data)
    if data then storedVars = data end
end

return {
    interfaceName = "ML_Core",
    interface = {
        getVariable = getVariable,
        saveVariable = saveVariable
    },
    engineHandlers = { onSave = onSave, onLoad = onLoad }
}
