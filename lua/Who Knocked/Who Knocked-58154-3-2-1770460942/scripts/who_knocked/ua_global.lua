-- Universal Activator - Global Script
-- Handles door activation registration and event sending
-- Follows the proven click_activator pattern

local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local core = require("openmw.core")
local time = require("openmw_aux.time")

local MOD_ID = "UniversalActivator"

-- Helper functions
local function msg(message)
    print("[" .. MOD_ID .. "] " .. message)
end

-- Response scheduling
local scheduledResponses = {}

local function scheduleResponse(data)
    -- Store the scheduled response
    scheduledResponses[data.door.recordId] = {
        message = data.message,
        door = data.door,
        doorType = data.doorType,
        unlockChance = data.unlockChance,
        executeTime = core.getGameTime() + data.delay
    }
    msg("Scheduled response for " .. data.door.recordId .. " in " .. data.delay .. " seconds")
end

local function processScheduledResponses()
    local currentTime = core.getGameTime()
    local player = world.players[1]
    
    for recordId, response in pairs(scheduledResponses) do
        if currentTime >= response.executeTime then
            -- Check if player is still near the door
            if player and (player.position - response.door.position):length() <= 200 then
                -- Send response to player script
                player:sendEvent("UA_DoorResponse", {
                    message = response.message,
                    door = response.door,
                    doorType = response.doorType,
                    unlockChance = response.unlockChance
                })
            end
            -- Remove processed response
            scheduledResponses[recordId] = nil
        end
    end
end

-- Universal Door Activation Handler
I.Activation.addHandlerForType(types.Door, function(door, actor)
    -- Safety check: ensure door is valid
    if not door then
        msg("Invalid door object, allowing default behavior")
        return true
    end
    
    msg("Door clicked: " .. tostring(door.recordId))
    
    -- Only handle player activations
    local player = world.player or world.players[1]
    if not player or actor ~= player then
        msg("Not player activation, allowing default behavior")
        return true
    end
    
    -- Check if main WhoKnocked system is enabled
    -- Query the settings global script for current setting
    local whoGlobal = require("openmw.interfaces").WhoKnockedGlobal
    if whoGlobal and whoGlobal.interface then
        local settings = whoGlobal.interface.getSettings()
        if not settings.enableWhoKnocked then
            msg("WhoKnocked system is disabled, allowing default behavior")
            return true  -- Allow default Morrowind door behavior
        end
    end
    
    -- Check if door is locked
    if not types.Door.isLocked(door) then
        msg("Door is not locked, allowing default behavior")
        return true
    end
    
    msg("Locked door clicked, sending knock-knock event to player")
    
    -- Send knock-knock event to player script (UI available there)
    actor:sendEvent("UA_ShowKnockKnock", {
        door = door,
        recordId = door.recordId,
        cellName = door.cell.name
    })
    
    -- Return false to prevent default behavior when door is locked
    return false
end)

-- Event handlers
local function UA_ScheduleResponse(data)
    scheduleResponse(data)
end

local function UA_UnlockDoor(data)
    -- Handle unlock requests from player script
    if data.door and data.door.type and data.door.type.unlock then
        data.door.type.unlock(data.door)
        msg("Door unlocked via " .. data.method .. ": " .. data.door.recordId)
        
        -- Notify player script of success
        local player = world.players[1]
        if player then
            player:sendEvent("UA_DoorUnlocked", {
                door = data.door,
                method = data.method,
                message = data.message
            })
        end
    else
        msg("Failed to unlock door: invalid door object")
    end
end

-- Bounty application handler (applies bounty in global context) v2.1
local function onApplyBounty(data)
    if not data or not data.bounty or data.bounty <= 0 then return end
    
    msg("[Global] Applying bounty: " .. data.bounty .. " gold for " .. (data.method or "unknown"))
    
    local player = world.players[1]
    if not player then
        msg("[Global] ERROR: No player found for bounty application")
        return
    end
    
    -- Apply bounty using SHOP mod's proven API pattern
    local currentBounty = 0
    if types.Player.getBounty then
        currentBounty = types.Player.getBounty(player) or 0
    elseif types.Player.getCrimeLevel then
        currentBounty = types.Player.getCrimeLevel(player) or 0
    end
    
    local newBounty = currentBounty + data.bounty
    
    -- Apply bounty with robust API fallbacks
    local apiUsed = "unknown"
    if types.Player.setBounty then
        types.Player.setBounty(player, newBounty)
        apiUsed = "setBounty"
    elseif types.Player.setCrimeLevel then
        types.Player.setCrimeLevel(player, newBounty)
        apiUsed = "setCrimeLevel"
    else
        -- Fallback via mwscript
        world.mwscript.run(player, 'SetPCCrimeLevel ' .. newBounty)
        apiUsed = "mwscript"
    end
    
    msg("[Global] Applied bounty using API: " .. apiUsed .. " (old: " .. currentBounty .. ", new: " .. newBounty .. ")")
    
    -- Send event for reputation system ONLY if bounty was actually applied
    if data.bounty > 0 then
        core.sendGlobalEvent("UA_BountyApplied", {
            method = data.method,
            bounty = data.bounty,
            originalBounty = data.originalBounty,
            multiplier = data.multiplier,
            apiUsed = apiUsed,
            door = data.door,
            location = data.location
        })
    end
end

-- Start response processing timer
time.runRepeatedly(processScheduledResponses, 1, {type = time.SimulationTime})

msg("Universal Activator loaded")

return {
    eventHandlers = {
        UA_ScheduleResponse = UA_ScheduleResponse,
        UA_UnlockDoor = UA_UnlockDoor,
        UA_ApplyBounty = onApplyBounty
    }
}
