---@class MyEq
local MyEqClass = {
        ---@type string
        recordId = nil,
        ---@type string
        icon = nil,
        ---@type  boolean
        keepPrev = false,
}


---@class OneSavedLoadOut
local OneSavedLoadOut = {
        name = '',
        ---@type table<number, MyEq>
        myEq = {},
        ---@type  Weapon
        secondWeapon = nil,
        ---@type CustomSlot
        instrument = nil,
        ---@type CustomSlot
        backPack = nil
}

---@class I
---@field SunsDusk SunsDuskInterface

---@class SunsDuskInterface
---@field getSaveData fun(): {backpackId: string}


local g = {}

g.util = require('scripts.Loadouts.myLib.myUtils')
g.colors = require('scripts.Loadouts.myLib.myConstants').colors
g.textures = require('scripts.Loadouts.myLib.myConstants').textures
g.sizes = require('scripts.Loadouts.myLib.myConstants').sizes
g.gui = require('scripts.Loadouts.myLib.myGUI')
g.controls = require('scripts.Loadouts.myLib.myControls')

g.templates = require('scripts.Loadouts.myLib.myTemplates')
g.myVars = require('scripts.Loadouts.myLib.myVars')
g.toolTip = require('scripts.Loadouts.myLib.toolTip')



return g
