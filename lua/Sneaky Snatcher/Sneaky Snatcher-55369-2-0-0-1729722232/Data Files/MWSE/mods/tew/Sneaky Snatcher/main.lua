local config = require("tew.Sneaky Snatcher.config")

-- Flag to control whether player has been detected by NPCs
---@type boolean
local playerDetected

-- Timestamp for last detection attempt
---@type number
local lastChecked = 0

-- A table to track references (yes, again and again)
---@type tes3reference[]
local refs = {}

--- A table to hold our skill increase values for activate targets
local activateTypes = {
    [tes3.objectType.container] = config.sneakSkillIncreaseContainer,
    [tes3.objectType.door] = config.sneakSkillIncreaseDoor,
}

--- Determine if we have a valid target for our action
--- @param target tes3reference
local function isValidTarget(target)
    return (
        (
            config.useOwnership and tes3.hasOwnershipAccess { target = target } or not config.useOwnership
        ) and
        (
            (target.object.objectType == tes3.objectType.container and not target.lockNode) or
            (not target.context)
        )
    )
end

-- Do our thing in the activate event
--- @param e activateEventData
local function activateCallback(e)
    local actTarget = e.target
    if (e.activator == tes3.player) and
        (tes3.mobilePlayer.isSneaking and not playerDetected) and
        (tes3.getSimulationTimestamp(false) - (lastChecked) < 2) and
        (isValidTarget(actTarget)) and
        (
            (not actTarget.tempData.sneakySnatcher) or
            (actTarget.tempData.sneakySnatcher and not actTarget.tempData.sneakySnatcher.accessed)
        ) then
        actTarget.tempData.sneakySnatcher = {}
        actTarget.tempData.sneakySnatcher.accessed = true
        table.insert(refs, actTarget)
        tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak,
            activateTypes[actTarget.object.objectType] or config.sneakSkillIncreaseObject)
    end
end
event.register(tes3.event.activate, activateCallback)

-- Track detection attempts
--- @param e detectSneakEventData
local function detectSneakCallback(e)
    if (e.target == tes3.mobilePlayer) and (e.detector.object.objectType == tes3.objectType.npc) then
        playerDetected = e.detector.isPlayerDetected and not e.detector.isPlayerHidden
        lastChecked = tes3.getSimulationTimestamp(false)
    end
end
event.register(tes3.event.detectSneak, detectSneakCallback)

-- Clear flags and tracker on cell change
--- @param e cellChangedEventData
local function cellChangedCallback(e)
    for _, ref in ipairs(refs) do
        ref.tempData.sneakySnatcher = {}
    end
    refs = {}
end
event.register(tes3.event.cellChanged, cellChangedCallback)

-- Reset timestamp on game loaded
--- @param e loadedEventData
local function loadedCallback(e)
    lastChecked = 0
end
event.register(tes3.event.loaded, loadedCallback)

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
    dofile("Data Files\\MWSE\\mods\\tew\\Sneaky Snatcher\\mcm.lua")
end)
