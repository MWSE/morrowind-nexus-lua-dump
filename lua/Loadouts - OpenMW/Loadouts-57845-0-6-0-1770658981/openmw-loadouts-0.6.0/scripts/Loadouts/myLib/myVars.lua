---@type ui.Element[]
local myDelayedActions = {}
---@type {action: function, skip: number}[]
local doLater          = {}
---@type Weapon
local secondWeapon     = nil


---@class CustomSlot
---@field recordId string|nil
---@field keepPrev boolean

---@type CustomSlot|{}
local instrument = {}

---@type CustomSlot|{}
local backPack = {}


local performerInfo = nil
---@type myWindow
local mainWindow    = {
        element = {}
}
---@type OneSavedLoadOut[]
local savedLoadouts = {}
local keepPrev      = {}


---@type Vector2
local res

return {
        myDelayedActions = myDelayedActions,
        doLater = doLater,
        secondWeapon = secondWeapon,
        instrument = instrument,
        mainWindow = mainWindow,
        savedLoadouts = savedLoadouts,
        performerInfo = performerInfo,
        keepPrev = keepPrev,
        res = res,
        backPack = backPack,
}
