--- @type ui.Element[]
local myDelayedActions = {}

---@type Vector2
local res
---@type number
local scale

---@type Window
local mainWindow = {
        element = {},
        title = ''
}


---@type SimpleList
local currentList

return {
        myDelayedActions = myDelayedActions,
        res = res,
        scale = scale,
        mainWindow = mainWindow,
        currentList = currentList
}
