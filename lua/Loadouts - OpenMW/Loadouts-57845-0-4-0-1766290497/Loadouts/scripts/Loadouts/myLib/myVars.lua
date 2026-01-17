--- @type ui.Element[]
local myDelayedActions = {}
---@type {action: function, skip: number}[]
local doLater          = {}
---@type Weapon
local secondWeapon     = nil
---@type string
local instrument       = nil
local performerInfo    = nil
---@type myWindow
local mainWindow       = {
        element = {}
}
---@type OneSavedLoadOut[]
local savedLoadouts    = {}
local keepPrev         = {}


---@type Vector2
local res
---@type number
local scale


return {
        myDelayedActions = myDelayedActions,
        doLater = doLater,
        secondWeapon = secondWeapon,
        instrument = instrument,
        mainWindow = mainWindow,
        savedLoadouts = savedLoadouts,
        performerInfo = performerInfo,
        keepPrev = keepPrev,
        scale = scale,
        res = res
}
