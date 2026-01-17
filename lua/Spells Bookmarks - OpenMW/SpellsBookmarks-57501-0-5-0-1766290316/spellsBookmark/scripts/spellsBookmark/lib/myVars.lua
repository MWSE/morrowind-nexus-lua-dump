local myDelayedActions = {}

---@type myWindow
local mainWindow = {
        element = {}
}

---@type Vector2
local res
---@type number
local scale

return {
        myDelayedActions = myDelayedActions,
        mainWindow = mainWindow,
        res = res,
        scale = scale,
}
