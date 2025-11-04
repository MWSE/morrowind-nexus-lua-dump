local g = {}


g.util = require('scripts.inventoryManager.myLib.myUtils')
g.colors = require('scripts.inventoryManager.myLib.myConstants').colors
g.textures = require('scripts.inventoryManager.myLib.myConstants').textures
g.sizes = require('scripts.inventoryManager.myLib.myConstants').sizes
g.lists = require('scripts.inventoryManager.myLib.myConstants').lists
g.gui = require('scripts.inventoryManager.myLib.myGUI')


g.templates = require('scripts.inventoryManager.myLib.myTemplates')
g.window = require('scripts.inventoryManager.myLib.window')
g.scrollableList = require('scripts.inventoryManager.myLib.scrollableList')
g.myDelayedActions = require(
'scripts.inventoryManager.myLib.DELAYED_ACTION_IS_NOT_ALLOWED_TO_START_ANOTHER_DELAYED_ACTION')



return g
