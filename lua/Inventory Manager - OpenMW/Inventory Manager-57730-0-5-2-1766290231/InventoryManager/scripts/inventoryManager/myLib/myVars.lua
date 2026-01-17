--- @type ui.Element[]
local myDelayedActions = {}
---@type {action: function, skip: number}[]
local doLater = {}
-- -@type ui.Element|{}
local mainWindow = {
        element = {}
}

---@type Vector2
local res
---@type number
local scale

local gv = {
        Year = nil,
        PCNAME = nil,
        pcname = nil,
        PCName = nil,
        PCClass = nil,
        PCRace = nil,
}

return {
        myDelayedActions = myDelayedActions,
        doLater = doLater,
        mainWindow = mainWindow,
        scale = scale,
        res = res,
        gv = gv,
}
