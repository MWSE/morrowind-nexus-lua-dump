--[[
    SmoothTalker Interop Module
    Public API for integration with other mods
--]]

local patience = require("SmoothTalker.patience")
local unlocks = require("SmoothTalker.unlocks")
local persuasion = require("SmoothTalker.persuasion")
local ui = require("SmoothTalker.ui")

local interop = {}

-- Module version for compatibility checking
-- Version history:
-- 1.0 - 1
-- 1.1 - 2
-- 1.2 - 3
-- 1.3 - 4
-- 1.4 - 5
-- 1.5 - 6
interop.VERSION = 5

-- Export unlock feature constants for external use
interop.FEATURE = unlocks.FEATURE


--- Modify an NPC's patience by the specified amount (clamped to 0-100)
--- Starts the regeneration timer on first modification if not already running
--- @param npcRef tes3reference The NPC reference
--- @param amount number Amount to modify patience by
interop.modPatience = patience.modPatience

--- Check if an NPC's patience is depleted
--- @param npcRef tes3reference The NPC reference
--- @return boolean depleted True if patience is depleted, false otherwise
interop.isPatienceDepleted = patience.isDepleted


-- Export unlock functions

--- Check if a feature is unlocked for a given speechcraft level
--- @param feature string|nil The feature to check (use unlocks.FEATURE constants), nil means always unlocked
--- @return boolean unlocked True if the feature is unlocked at this speechcraft level, false otherwise
interop.isUnlocked = unlocks.isUnlocked


--- Perform persuasion action and handle the outcomes
--- @param actionType string|nil The action to perform: "admire"|"taunt"|"intimidate"|"placate"|"bond"|"bribe"
--- @param npcRef tes3reference The NPC reference
--- @param bribeAmount number|nil Gold value of the bribe. Not used if actionType other than bribe
--- @param keepGold boolean|nil If set to true, gold won't be transferred on success - use if you handle gold transfer on your side
--- @return boolean success Whether the action succeeded
interop.persuade = ui.handleAction

--- Get the success chance for a persuasion action
--- @param action string The action type "admire"|"taunt"|"intimidate"|"placate"|"bond"|"bribe"
--- @param npcRef tes3reference The NPC reference
--- @param bribeAmount number|nil The bribe amount (if applicable)
--- @return number The success chance (0-100, clamped to min/max)
interop.getSuccessChance = persuasion.getSuccessChance

--- Get the mod version
--- @return integer version The build number, see top of the file for version mapping
function interop.getVersion()
    return interop.VERSION
end


return interop
