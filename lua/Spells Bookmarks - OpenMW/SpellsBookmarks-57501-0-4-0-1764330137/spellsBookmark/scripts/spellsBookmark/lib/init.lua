local g = {}


g.util = require('scripts.spellsBookmark.lib.myUtils')
g.colors = require('scripts.spellsBookmark.lib.myConstants').colors
g.textures = require('scripts.spellsBookmark.lib.myConstants').textures
g.sizes = require('scripts.spellsBookmark.lib.myConstants').sizes
g.lists = require('scripts.spellsBookmark.lib.myConstants').lists
g.gui = require('scripts.spellsBookmark.lib.myGUI')


g.templates = require('scripts.spellsBookmark.lib.myTemplates')
g.window = require('scripts.spellsBookmark.lib.window')
g.scrollableList = require('scripts.spellsBookmark.lib.scrollableList')
g.myDelayedActions = require(
'scripts.spellsBookmark.lib.delayedActions')



return g
