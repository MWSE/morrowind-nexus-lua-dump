---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").AnimationController.
-- Source: files/data/scripts/omw/mechanics/animationcontroller.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: local

---Animation controller interface
---local I = require('openmw.interfaces')
----- play spellcast animation
---I.AnimationController.playBlendedAnimation('spellcast', { startkey = 'self start', stopkey = 'self stop', priority = {
---I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
---end)
---I.AnimationController.addTextKeyHandler('', function(groupname, key)
---end)
---I.AnimationController.addPlayBlendedAnimationHandler(function (groupname, options)
---end)
---@class openmw.interfaces.AnimationController
---@field version number
local AnimationController = {}

---AnimationController Package
---@class openmw.interfaces.AnimationController.Package
local Package = {}

---Interface version
---@type number
AnimationController.version = nil

---Make this actor play an animation. Makes a call to openmw.animation.playBlended, after invoking handlers added through addPlayBlendedAnimationHandler
---@param groupname string The animation group to be played
---@param options table The table of play options that will be passed to openmw.animation.playBlended
function AnimationController.playBlendedAnimation(groupname, options) end

---Add a new playBlendedAnimation handler for this actor
---If `handler(groupname, options)` returns false, other handlers for
---the call will be skipped.
---@param handler fun(...): any The handler.
function AnimationController.addPlayBlendedAnimationHandler(handler) end

---Add a new animationEnded handler for this actor
---If `handler(groupname, info)` returns false, other handlers for
---the call will be skipped. info is a table that contains information related to
---the animation that ended and will contain the following fields:
---  * `time` - The absolute time in the animation when it was ended
---  * `completion` - The relative time (0-1) in the animation when it was ended
---  * `startKey` - The start key of the animation that ended
---  * `stopKey` - The stop key of the animation that ended
---@param handler fun(...): any The handler.
function AnimationController.addAnimationEndedHandler(handler) end

---Add a new text key handler for this actor
---While playing, some animations emit text key events. Register a handle to listen for all
---text key events associated with this actor's animations.
---If `handler(groupname, key)` returns false, other handlers for
---the call will be skipped.
---@param groupname string Name of the animation group to listen to keys for. If it is an empty string or nil, all keys will be received
---@param handler fun(...): any The handler.
function AnimationController.addTextKeyHandler(groupname, handler) end

return AnimationController
