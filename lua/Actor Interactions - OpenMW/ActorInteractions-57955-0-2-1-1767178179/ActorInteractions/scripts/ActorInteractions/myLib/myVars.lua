--- @type ui.Element[]
local myDelayedActions = {}
---@type {action: function, skip: number}[]
local doLater          = {}
---@type myWindow
local mainWindow       = {
        element = {}
}

---@type myWindow
local dressUpWindow    = {
        element = {}
}

---@type Actor
local currentActor
---@type Vector2
local res
---@type number
local scale
---@type ScrollableList|ScrollableGrid
local currentScrollable

return {
        myDelayedActions = myDelayedActions,
        doLater = doLater,
        mainWindow = mainWindow,
        scale = scale,
        res = res,
        currentScrollable = currentScrollable,
        currentActor = currentActor,
        dressUpWindow = dressUpWindow
}
