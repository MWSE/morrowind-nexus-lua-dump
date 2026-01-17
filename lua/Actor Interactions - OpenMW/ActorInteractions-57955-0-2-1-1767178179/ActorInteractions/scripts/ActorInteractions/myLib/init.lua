local g = {}

---@class ScrollableItem
---@field name string
---@field icon? string
---@field magical? boolean
---@field count? number
---@field equipped? boolean
---@field object? GameObject
---@field spell? Spell|ActiveSpell
---@field effect? ActiveSpellEffect
---@field skill? string

g.util = require('scripts.ActorInteractions.myLib.myUtils')
g.soundFiles = require('scripts.ActorInteractions.myLib.myConstants').soundFiles
g.colors = require('scripts.ActorInteractions.myLib.myConstants').colors
g.textures = require('scripts.ActorInteractions.myLib.myConstants').textures
g.sizes = require('scripts.ActorInteractions.myLib.myConstants').sizes
g.tabName = require('scripts.ActorInteractions.myLib.myConstants').tabName
g.gui = require('scripts.ActorInteractions.myLib.myGUI')

g.templates = require('scripts.ActorInteractions.myLib.myTemplates')
g.myVars = require('scripts.ActorInteractions.myLib.myVars')
g.toolTip = require('scripts.ActorInteractions.myLib.toolTip')
g.controls = require('scripts.ActorInteractions.myLib.myControls')
g.layouts = require('scripts.ActorInteractions.myLib.myLayouts')

return g
