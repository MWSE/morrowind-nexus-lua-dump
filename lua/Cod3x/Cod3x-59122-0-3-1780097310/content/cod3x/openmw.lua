---@meta

-- Convenience index for OpenMW LuaLS stubs. Runtime code should require modules directly.
---@class openmw
local openmw = {}
---@type openmw.ambient
openmw.ambient = require("openmw.ambient")
---@type openmw.animation
openmw.animation = require("openmw.animation")
---@type openmw.async
openmw.async = require("openmw.async")
---@type openmw.camera
openmw.camera = require("openmw.camera")
---@type openmw.content
openmw.content = require("openmw.content")
---@type openmw.core
openmw.core = require("openmw.core")
---@type openmw.debug
openmw.debug = require("openmw.debug")
---@type openmw.input
openmw.input = require("openmw.input")
---@type openmw.interfaces
openmw.interfaces = require("openmw.interfaces")
---@type openmw.markup
openmw.markup = require("openmw.markup")
---@type openmw.menu
openmw.menu = require("openmw.menu")
---@type openmw.nearby
openmw.nearby = require("openmw.nearby")
---@type openmw.postprocessing
openmw.postprocessing = require("openmw.postprocessing")
---@type openmw.SelfObject
openmw.self = require("openmw.self")
---@type openmw.storage
openmw.storage = require("openmw.storage")
---@type openmw.types
openmw.types = require("openmw.types")
---@type openmw.ui
openmw.ui = require("openmw.ui")
---@type openmw.util
openmw.util = require("openmw.util")
---@type openmw.vfs
openmw.vfs = require("openmw.vfs")
---@type openmw.world
openmw.world = require("openmw.world")
return openmw
