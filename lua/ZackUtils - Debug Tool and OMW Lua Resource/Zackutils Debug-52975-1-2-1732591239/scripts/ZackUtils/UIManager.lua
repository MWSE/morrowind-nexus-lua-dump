
local storedUIs = {}

local function storeUI(name,UI)
storedUIs[name] = UI
print("Storing UI")
print(UI == nil)
end
local function destroyNamedUI(name)
if storedUIs[name] then
    storedUIs[name]:destroy()
else
    error("No stored UI named " .. name)
end

end
return{
    interfaceName = "ZU_UIManager",
    interface = {storeUI = storeUI,destroyNamedUI = destroyNamedUI},
    eventHandlers = {destroyNamedUI = destroyNamedUI}
}