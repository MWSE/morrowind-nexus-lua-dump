---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").AI.
-- Source: files/data/scripts/omw/ai.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: local

---Basic AI interface
---@class openmw.interfaces.AI
---@field version number
local AI = {}

---AI Package
---@class openmw.interfaces.AI.Package
---@field type string Type of the AI package.
---@field target openmw.LObject|nil Target (usually an actor) of the AI package (can be nil).
---@field sideWithTarget boolean Whether to help the target in combat (true or false).
---@field destPosition openmw.util.Vector3 Destination point of the AI package.
---@field distance number|nil Distance value (can be nil).
---@field duration number|nil Duration value (can be nil).
---@field idle table|nil Idle value (can be nil).
---@field isRepeat boolean Should this package be repeated (true or false).
local Package = {}

---Interface version
---@type number
AI.version = nil

---Return the currently active AI package (or `nil` if there are no AI packages).
---@return openmw.interfaces.AI.Package|nil
function AI.getActivePackage() end

---Return whether the actor is fleeing.
---@return boolean
function AI.isFleeing() end

---Start a new AI package.
---@param options table See the "AI packages" page.
function AI.startPackage(options) end

---Iterate over all packages starting from the active one and remove those where `filterCallback` returns false.
---@param filterCallback fun(...): any
function AI.filterPackages(filterCallback) end

---Iterate over all packages and run `callback` for each starting from the active one.
---The same as `filterPackage`, but without removal.
---@param callback fun(...): any
function AI.forEachPackage(callback) end

---Remove packages of given type (remove all packages if the type is not specified).
---@param packageType? string (optional) The type of packages to remove.
function AI.removePackages(packageType) end

---Return the target of the active package if the package has given type
---@param packageType string The expected type of the active package
---@return openmw.LObject|nil The target (can be nil if the package has no target or has another type)
function AI.getActiveTarget(packageType) end

---Get a list of targets from all packages of the given type.
---@param packageType string
---@return openmw.LObject[]
function AI.getTargets(packageType) end

return AI
