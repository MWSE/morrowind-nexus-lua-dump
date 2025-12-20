--- @type ui.Element[]
local myDelayedActions = {}

---@type {action: function, skip: number}[]
local doLater = {}


---@type Weapon
local secondWeapon = nil

---@type string
local instrument = nil

local performerInfo = nil

---@type ui.Element|{}
local selectEqWindow = {}


---@type myWindow
local mainWindow = {
        element = {}
}


---@type OneSavedLoadOut[]
local savedLoadouts = {}



return {
        myDelayedActions = myDelayedActions,
        doLater = doLater,
        secondWeapon = secondWeapon,
        instrument = instrument,
        selectEqWindow = selectEqWindow,
        mainWindow = mainWindow,
        savedLoadouts = savedLoadouts,

        performerInfo = performerInfo,
}
