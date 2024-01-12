local worldLoaded, world = pcall(require, "openmw.world")

local mwse = true
local engineHandlers = {}
local function onInit()

end
local activateFunctions = {}
local updateFunctions = {}
local function onUpdate(dt)
    if (mwse) then
        for index, func in ipairs(updateFunctions) do
            func(dt.delta)
        end
    else
        for index, func in ipairs(updateFunctions) do
            func(dt)
        end
    end
end
 function engineHandlers.addFunction(name, func)
    if (name == "onUpdate") then
        table.insert(updateFunctions, func)
    end
end

function engineHandlers.RegisterActivateByType(func, type)
    table.insert(activateFunctions, { func = func, type = type })
    return nil
end
local function onActivateMWSE(e)
    local result = true
    for index, funcData in ipairs(activateFunctions) do
        if (funcData.type == e.target.object.objectType) then
            
            local res =  funcData.func(e.target, e.activator)
            if(res == false) then
                result = false
            end
        end
    end
    if(result == false) then
        return false
    end
end
if (mwse == false) then
    print("Not MWSE")
    return {
        interfaceName  = "ZackBridgeEngineHandlers",
        interface      = {
            version = 1,
            addFunction = engineHandlers.addFunction,
        },
        eventHandlers  = {
        },
        engineHandlers = { onInit = onInit, onLoad = onInit, onUpdate = onUpdate }
    }
else
    event.register(tes3.event.activate, onActivateMWSE)
    event.register(tes3.event.simulate, onUpdate)
end

return engineHandlers