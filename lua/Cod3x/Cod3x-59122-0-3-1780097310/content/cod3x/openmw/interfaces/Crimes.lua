---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").Crimes.
-- Source: files/data/scripts/omw/crimes.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: global

---Allows to utilize built-in crime mechanics.
---@class openmw.interfaces.Crimes
---@field version number
local Crimes = {}

---Table with information needed to commit crimes.
---@class openmw.interfaces.Crimes.CommitCrimeInputs
---@field victim openmw.GObject|nil The victim of the crime (optional)
---@field type openmw.types.OFFENSE_TYPE_IDS The type of the crime to commit. See openmw.types.OFFENSE_TYPE_IDS (required)
---@field faction string|nil ID of the faction the crime is committed against (optional)
---@field arg number|nil The amount to increase the player bounty by if the crime type is theft. Ignored otherwise (optional, defaults to 0)
---@field victimAware boolean|nil Whether the victim is aware of the crime (optional, defaults to false)
local CommitCrimeInputs = {}

---Table containing information returned by the engine after committing a crime
---@class openmw.interfaces.Crimes.CommitCrimeOutputs
---@field wasCrimeSeen boolean Whether the crime was seen
local CommitCrimeOutputs = {}

---Interface version
---@type number
Crimes.version = nil

---Commits a crime as if done through an in-game action. Can only be used in global context.
---@param player openmw.GObject The player committing the crime
---@param options openmw.interfaces.Crimes.CommitCrimeInputs A table of parameters describing the committed crime
---@return openmw.interfaces.Crimes.CommitCrimeOutputs A table containing information about the committed crime
function Crimes.commitCrime(player, options) end

return Crimes
