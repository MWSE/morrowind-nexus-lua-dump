local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local originalPrint = print
_G.print = function(...)
    if ScheduleConfig.DEBUG_MODE then
        originalPrint(...)
    end
end

local core    = require('openmw.core')
local self    = require('openmw.self')
local types   = require('openmw.types')
local util    = require('openmw.util')
local async   = require('openmw.async')
local storage = require('openmw.storage')
local ai = require('openmw.interfaces').AI
local PropManager = require("scripts.ProceduralChatter.PropManager")
local SittingLogic = require("scripts.ProceduralChatter.SittingLogic")
local SleepLogic   = require("scripts.ProceduralChatter.SleepLogic")
local ActivityLibrary = require("scripts.ProceduralChatter.data.ActivityLibrary")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local NPCState = require("scripts.ProceduralChatter.NPCState")
local StateMachine = require("scripts.ProceduralChatter.StateMachine")
local Utils = require("scripts.ProceduralChatter.Utils")
local TargetedTravelUnstuck = require("scripts.ProceduralChatter.TargetedTravelUnstuck")

local function dbg(fmt, ...)
    if ScheduleConfig and ScheduleConfig.DEBUG_MODE then
        print("[ProceduralChatter] " .. string.format(fmt, ...))
    end
end

local travelUnstuck = TargetedTravelUnstuck.create({
    actor = self,
    ai = ai,
    debug = dbg,
})

--- Companions and live followers skip all procedural chatter behaviors.
local function isCompanionOrFollower(object)
    if Blacklist.isCompanion(object) then return true end
    if ai and ai.getActivePackage then
        local ok, pkg = pcall(ai.getActivePackage)
        if ok and pkg and (pkg.type == "Follow" or pkg.type == "Escort") then return true end
    end
    if ai and ai.getTargets then
        local okFollow, followTargets = pcall(ai.getTargets, "Follow")
        if okFollow and followTargets and #followTargets > 0 then return true end
        local okEscort, escortTargets = pcall(ai.getTargets, "Escort")
        if okEscort and escortTargets and #escortTargets > 0 then return true end
    end
    return false
end

local function normalizePosture(posture)
    if posture == "sitting" then return "sit" end
    if posture == "standing" then return "stand" end
    return posture or "both"
end

dbg("npc.lua LOADED")

-- Settings are now handled by player.lua and passed via event payload.

-- Native home: captured on the very first update frame, before any ProceduralChatter
-- script has issued a Travel/Wander/teleport for this NPC.  Used as the canonical
-- return destination after sleep or any script-driven displacement.
-- The global section is write-once (SleepManager writes on first cell entry) so
-- this local script reads the stored value when available, ensuring that a
-- displaced NPC always restores the correct pre-displacement origin.
local nativeHome          = nil   -- { position, rotation, wander }
local nativeHomeCaptured  = false
local _nativeHomeStore    = storage.globalSection('PC_NativeHomes')

local originalPosition = nil
local originalRotation = nil
local originalCellName = nil
local lookAtTarget = nil
local originalHello = nil

-- Pre-activity position: where the NPC was standing before an activity or
-- conversation walk moved them.  Activities return here when done.
-- Separate from originalPosition so the schedule system never needs to
-- touch originalPosition (which is the NPC's canonical cell position).
local preActivityPosition = nil
local preActivityRotation = nil

-- Set by PC_ClearForSchedule when the schedule system is about to disable
-- this NPC.  onInactive checks this flag and skips the teleport-back so
-- the schedule displacement isn't fought.
local scheduleControlled = false

-- === Smooth Departure (Phase A) ===
-- departureState: nil | "teardown" | "walking_to_door"
--   "teardown"        — waiting for sit/sleep/activity to finish, then will start Travel
--   "walking_to_door" — NPC is travelling to departureDoorPos
-- departureTimeout counts down; if it hits 0 the NPC fires PC_DepartureReachedDoor
-- anyway so the global always gets the signal.
local departureState   = nil
local departureDoorPos = nil
local departureTimeout = 0
local departureTravelRetries = 0
local DEPARTURE_DOOR_DIST = 80
local DEPARTURE_TRAVEL_RETRIES = 3

-- === Walk timeouts (stuck-detection) ===
-- If an NPC walks into a wall and makes no progress, these timeouts force
-- completion so the global schedule system doesn't hang forever.
local walkTimeout = 0
local arrivalTimeout = 0
local transitionTimeout = 0
local WALK_TIMEOUT = 30
local ARRIVAL_TIMEOUT = 45
local TRANSITION_TIMEOUT = 45
local currentWalkIsConversation = false

local arrivalWalkTarget   = nil
local ARRIVAL_DIST = 100

-- Schedule-owned Travel must not use TargetedTravelUnstuck: its nudge is a global
-- teleport toward facing direction and restartTravel() resets pathfinding every cycle.
local SCHEDULE_TRAVEL_LABELS = {
    arrival_walk = true,
    transition_walk = true,
    departure_door = true,
    departure_door_retry = true,
}

local function armTargetedTravel(target, label, stopDist)
    if SCHEDULE_TRAVEL_LABELS[label or ""] then return end
    if travelUnstuck and target then
        travelUnstuck.register(util.vector3(target.x, target.y, target.z), {
            label = label,
            stopDist = stopDist,
        })
    end
end

local function clearTargetedTravel()
    if travelUnstuck then travelUnstuck.clear() end
end
 
 -- === Smooth Transition (Cross-Exterior) ===
 -- transitionWalkTarget is set by PC_TransitionWalk; onUpdate fires PC_TransitionComplete
 -- when the NPC reaches the entrance of the next interior.
 local transitionWalkTarget = nil

-- NEW: Synchronization state for sitting/sleep teardown
local isWaitingForStandUp = false
local isWaitingForWakeUp  = false

local wasHostile = false
local hostilityClearTimer = 0
local HOSTILITY_CLEAR_DELAY = 10.0
local hostilityCheckTimer = 0
local HOSTILITY_CHECK_INTERVAL = 0.25
local returnTargetPos = nil
local returnTargetRot = nil
local savedWanderPackage = nil
local DEFAULT_FOREIGN_WANDER = {
    type = "Wander",
    distance = 512,
    duration = 0,
    idle = { min = 2, max = 6 },
    isRepeat = true
}

-- Activity State
local currentActivity = nil
local currentActivityOverrides = nil
local activityAnimStarted = false
local currentConversationGesture = nil
local activityCleanupTimer = 0
-- Sequence State (for multi-step activities like sweeping)
local activitySequence = nil
local sequenceStep = 0
local sequenceTimer = 0
local sequenceWandering = false
local currentSequenceAnim = nil
local _firstUpdateDone = false
local sm = nil
local isRuntimeHostileNow
local rejectConversationForHostility
-- (Reverted: isVanillaSitting / vanillaSitTimer)

local function getCurrentCellName()
    local cellName = ""
    pcall(function()
        cellName = self.cell and self.cell.name or ""
    end)
    return cellName
end

local function cellNamesMatch(a, b)
    if not a or not b or a == "" or b == "" then return false end
    return string.lower(a) == string.lower(b)
end

local function copyWanderPackage(pkg)
    if not pkg or pkg.type ~= "Wander" then return nil end
    local idle = nil
    if pkg.idle then
        idle = {
            min = pkg.idle.min,
            max = pkg.idle.max,
        }
    end
    return {
        type = "Wander",
        distance = pkg.distance,
        duration = pkg.duration,
        idle = idle,
        isRepeat = pkg.isRepeat ~= false,
    }
end

local function loadStoredNativeHome()
    local ok, stored = pcall(function()
        return _nativeHomeStore:get(tostring(self.id))
    end)
    if not ok or not stored then return nil end

    local pos = util.vector3(stored.x, stored.y, stored.z)
    local rot = util.transform.rotateZ(stored.yaw or 0)
    local wander = nil
    if stored.wander and stored.wander.type == "Wander" then
        wander = copyWanderPackage(stored.wander)
    end
    return {
        position = pos,
        rotation = rot,
        cellName = stored.cellName or "",
        wander = wander,
        raw = stored,
    }
end

--- Keep local originalPosition / nativeHome aligned with PC_NativeHomes (what Relocator uses).
local function syncCanonicalNativeHomeFromStore()
    local storedHome = loadStoredNativeHome()
    if not storedHome then return false end

    originalPosition = storedHome.position
    originalRotation = storedHome.rotation
    if storedHome.cellName and storedHome.cellName ~= "" then
        originalCellName = storedHome.cellName
    end

    if nativeHome then
        nativeHome.position = storedHome.position
        nativeHome.rotation = storedHome.rotation
        if storedHome.cellName ~= "" then
            nativeHome.cellName = storedHome.cellName
        end
        if storedHome.wander and not nativeHome.wander then
            nativeHome.wander = storedHome.wander
        end
        SleepLogic.setNativeHome(nativeHome)
    end
    return true
end

--- Resolve wander for the NPC's native cell (in-memory nativeHome, then persisted store).
local function resolveNativeWanderPackage()
    if nativeHome and nativeHome.wander then
        return nativeHome.wander
    end
    local storedHome = loadStoredNativeHome()
    if storedHome and storedHome.wander then
        if nativeHome then
            nativeHome.wander = storedHome.wander
            SleepLogic.setNativeHome(nativeHome)
        end
        return storedHome.wander
    end
    return nil
end

local function persistNativeWander(wander)
    if not wander or wander.type ~= "Wander" then return end
    local yaw = 0
    pcall(function()
        local fwd = self.rotation * util.vector3(0, 1, 0)
        yaw = math.atan2(fwd.x, fwd.y)
    end)
    core.sendGlobalEvent("PC_PersistNativeWander", {
        npc = self.object,
        npcId = self.id,
        position = self.position,
        yaw = yaw,
        cellName = getCurrentCellName(),
        wander = copyWanderPackage(wander),
    })
end

local function registerPreActivityPosition(opts)
    opts = opts or {}
    if preActivityPosition and not opts.forceRefresh then return end

    syncCanonicalNativeHomeFromStore()

    local fallbackPos = util.vector3(self.position.x, self.position.y, self.position.z)
    local fallbackRot = self.rotation
    local targetPos = fallbackPos
    local targetRot = fallbackRot

    -- Large-radius wanderers (native wander distance > 256) should return to where
    -- they were before the interruption, not snap back to nativeHome.position.
    -- Small-radius / static NPCs return to their exact native home spot.
    local isLargeWanderer = false
    local wanderPkg = resolveNativeWanderPackage()
    if wanderPkg and wanderPkg.distance then
        isLargeWanderer = wanderPkg.distance > 256
    end

    if not isLargeWanderer and not opts.useCurrentPosition then
        local canonPos = (nativeHome and nativeHome.position) or originalPosition
        local canonRot = (nativeHome and nativeHome.rotation) or originalRotation
        local canonCell = (nativeHome and nativeHome.cellName) or originalCellName
        if canonPos and cellNamesMatch(getCurrentCellName(), canonCell) then
            targetPos = canonPos
            targetRot = canonRot or fallbackRot
        end
    end

    preActivityPosition = targetPos
    preActivityRotation = targetRot
end

local function saveBehaviorForReturn(context, data)
    -- Never snapshot/overwrite wander while a schedule door walk owns Travel.
    if scheduleControlled
            or sm:is("arriving") or sm:is("departing") or sm:is("transitioning")
            or arrivalWalkTarget ~= nil or transitionWalkTarget ~= nil or departureDoorPos ~= nil then
        dbg("NPC %s %s: skipped (schedule relocation active)", self.recordId, tostring(context))
        return
    end
    local transitState = NPCState.get(self.object.id)
    if transitState == "traveling_home" or transitState == "traveling_to_destination" then
        dbg("NPC %s %s: skipped (schedule transit %s)", self.recordId, tostring(context), transitState)
        return
    end

    local isConversation = (data and data.reason == "conversation")
        or context == "PC_StartConversation"
    if isConversation then
        preActivityPosition = nil
        preActivityRotation = nil
    end

    syncCanonicalNativeHomeFromStore()
    local wanderPkg = resolveNativeWanderPackage()
    local isLargeWanderer = wanderPkg and wanderPkg.distance and wanderPkg.distance > 256

    local hadReturnAnchor = preActivityPosition ~= nil
    registerPreActivityPosition({
        forceRefresh = isConversation,
        -- Large wanderers: return to where they stood when the chat started.
        useCurrentPosition = isConversation and isLargeWanderer,
    })

    local active = ai.getActivePackage()
    if hadReturnAnchor and savedWanderPackage then
        dbg("NPC %s %s: keeping existing saved wander.", self.recordId, tostring(context))
    elseif active and active.type == "Wander" then
        savedWanderPackage = {
            type = "Wander",
            distance = active.distance,
            duration = active.duration,
            idle = active.idle,
            isRepeat = active.isRepeat
        }
        dbg("NPC %s %s captured Wander (Dist: %s)", self.recordId, tostring(context), tostring(active.distance))
    elseif not savedWanderPackage then
        savedWanderPackage = nil
        dbg("NPC %s %s: no active Wander, marked static (Type: %s)",
            self.recordId, tostring(context), active and active.type or "nil")
    else
        dbg("NPC %s %s: keeping existing saved wander.", self.recordId, tostring(context))
    end
end

local function makeDefaultForeignWander()
    return {
        type = "Wander",
        distance = DEFAULT_FOREIGN_WANDER.distance,
        duration = DEFAULT_FOREIGN_WANDER.duration,
        idle = {
            min = DEFAULT_FOREIGN_WANDER.idle.min,
            max = DEFAULT_FOREIGN_WANDER.idle.max
        },
        isRepeat = DEFAULT_FOREIGN_WANDER.isRepeat
    }
end

-- FORWARD DECLARATION or Helper Functions
local stopActivity -- Forward declare if needed, or just define fully here.
local startActivity

-- HELPER: Local Activity Manager
stopActivity = function(silent, forceClearAll)
    if not currentActivity and not forceClearAll then return end
    if currentActivity then
        dbg("Stopping Activity: %s", currentActivity)
        
        local act = ActivityLibrary[currentActivity]
        if act then
            -- 1. Stop Animation
            if act.anim or currentSequenceAnim then
                local anim = require('openmw.animation')
                -- Check if alive before cancelling
                if types.Actor.stats.dynamic.health(self).current > 0 then
                    pcall(function() anim.cancel(self, currentSequenceAnim or act.anim) end)
                end
            end
            
            -- 2. Cleanup (Remove) Props
            if act.props then
                for _, propId in ipairs(act.props) do
                    PropManager.cleanupProp(propId)
                end
            end
        end
    end
    
    if forceClearAll then
        local anim = require('openmw.animation')
        for _, act in pairs(ActivityLibrary) do
            if act.anim then
                if types.Actor.stats.dynamic.health(self).current > 0 then
                    pcall(function() anim.cancel(self, act.anim) end)
                end
            end
            if act.props then
                for _, propId in ipairs(act.props) do
                     PropManager.cleanupProp(propId)
                end
            end
        end
    end
    
    currentActivity = nil
    activityAnimStarted = false
    
    -- Reset Sequence State
    activitySequence = nil
    sequenceStep = 0
    sequenceTimer = 0
    sequenceWandering = false
    currentSequenceAnim = nil
    
    -- Report Finished to clear Busy state
    if not silent then
        core.sendGlobalEvent("PC_ActivityFinished", { npc = self })
    end
end

-- SEQUENCE EXECUTION LOGIC
local executeSequenceStep -- Forward declare
local playSequenceAnim

playSequenceAnim = function(animName, count)
    local act = ActivityLibrary[currentActivity]
    if not act then return end
    
    local anim = require('openmw.animation')
    local I = require('openmw.interfaces')

    local targetAnim = animName or act.anim
    if not targetAnim then
        dbg("WARN: No animation specified for sequence step.")
        return
    end

    currentSequenceAnim = targetAnim

    local mask = act.mask or 15
    local activePkg = ai.getActivePackage()
    local isWandering = (activePkg and activePkg.type == 'Wander')
    local isTraveling = (activePkg and activePkg.type == 'Travel')
    local isSitting = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
    
    if isSitting or isWandering or isTraveling then
        mask = 14
    end
    
    local config = { 
        blendMask = mask, 
        priority = act.priority or 13,
        loops = count,
        forceLoop = (count > 1)
    }
    
    local ok, err = pcall(function()
        I.AnimationController.playBlendedAnimation(targetAnim, config)
    end)
    if not ok then
        dbg("WARN: Failed to play sequence animation '%s': %s", targetAnim, tostring(err))
    else
        activityAnimStarted = true
    end
end

executeSequenceStep = function()
    if not activitySequence or sequenceStep > #activitySequence then
        -- Sequence complete
        dbg("Sequence complete. Stopping activity and returning.")
        stopActivity()
        
        -- Return to pre-activity position if stored
        if preActivityPosition then
            local isSitting = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
            if isSitting then
                dbg("Sequence complete while sitting; skipping return travel.")
                preActivityPosition = nil
                preActivityRotation = nil
            else
                ai.startPackage({
                    type = "Travel",
                    destPosition = preActivityPosition
                })
                armTargetedTravel(preActivityPosition, "activity_sequence_return", 50)
            end
        end
        return
    end

    local step = activitySequence[sequenceStep]
    dbg("Executing sequence step %d: type=%s", sequenceStep, step.type)

    if step.type == "anim" then
        playSequenceAnim(step.anim, step.count or 1)
        -- Animation completion is tracked in onUpdate, which will advance the step
    elseif step.type == "wander" then
        sequenceTimer = step.duration or 5
        sequenceWandering = true
        -- Start a short wander (just move around locally)
        ai.startPackage({
            type = "Wander",
            distance = 200,
            duration = step.duration
        })
    elseif step.type == "return" then
        -- Return to pre-activity position
        if preActivityPosition then
            local isSitting = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
            if isSitting then
                dbg("Return step while sitting; skipping travel to preserve seat.")
                preActivityPosition = nil
                preActivityRotation = nil
            else
                ai.startPackage({
                    type = "Travel",
                    destPosition = preActivityPosition
                })
                armTargetedTravel(preActivityPosition, "activity_step_return", 50)
            end
        end
        sequenceStep = sequenceStep + 1
        executeSequenceStep()
    end
end

startActivity = function(actId, overrides)
    local act = ActivityLibrary[actId]
    if not act then
        dbg("Error: Unknown Activity '%s'", tostring(actId))
        return false
    end
    
    -- Reject activities during active travel, sitting transitions, sleep transitions, or other busy states
    local currentLocalState = sm and sm:get() or "idle"
    local activePkg = ai.getActivePackage()
    local isTravelingPkg = (activePkg and activePkg.type == 'Travel')
    
    local isTravelState = currentLocalState == "walking" 
        or currentLocalState == "returning" 
        or currentLocalState == "departing" 
        or currentLocalState == "transitioning" 
        or currentLocalState == "arriving"
        or currentLocalState == "sleeping"
        or currentLocalState == "waking"
        or currentLocalState == "combat"
        or currentLocalState == "conversation"
        or isWaitingForStandUp
        or isWaitingForWakeUp

    local isSittingState = false
    if SittingLogic and SittingLogic.getState then
        local sState = SittingLogic.getState()
        isSittingState = sState == "walking_to_seat" or sState == "standing_up"
    end

    local isSleepingState = false
    if SleepLogic and SleepLogic.getState then
        local slState = SleepLogic.getState()
        isSleepingState = slState == "walking_to_bed" or slState == "laying_down" or slState == "waking_up"
    end

    if isTravelState or isTravelingPkg or isSittingState or isSleepingState then
        dbg("BLOCKED: NPC is currently traveling or busy (localState='%s', hasTravelPkg=%s, sittingState=%s, sleepingState=%s). Rejecting activity '%s'.",
            tostring(currentLocalState), tostring(isTravelingPkg), 
            tostring(SittingLogic and SittingLogic.getState and SittingLogic.getState() or "nil"), 
            tostring(SleepLogic and SleepLogic.getState and SleepLogic.getState() or "nil"), 
            actId)
        core.sendGlobalEvent("PC_ActivityFinished", { npc = self.object })
        return false
    end
    
    if currentActivity == actId then
        dbg("Activity already running.")
        return true
    end
    
    if currentActivity then stopActivity() end
    
    -- Posture Verification (Prevent Sit-Sweeping)
    local anim = require('openmw.animation')
    local reqPosture = normalizePosture(act.posture)
    if reqPosture == "stand" then
        local isSitting = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
        
        -- Fallback: Check Physical Animation State (Vanilla Sitters)
        if not isSitting then
             local ok1, result1 = pcall(function() return anim.isPlaying(self, "pcdbssit5") or anim.isPlaying(self, "dbssit5") or anim.isPlaying(self, "dbssit6") or anim.isPlaying(self, "sdpvasitting6") or anim.isPlaying(self, "sitidle1") end)
             if ok1 and result1 then isSitting = true end
             
             if not isSitting then
                 local ok2, result2 = pcall(function() return anim.isPlaying(self, "IdleSit") end)
                 if ok2 and result2 then isSitting = true end
             end
        end
        
        if isSitting then
            dbg("BLOCKED: Activity '%s' requires standing, but NPC is sitting.", actId)
            return false
        end
    end

    dbg("Starting Activity: %s", actId)
    currentActivity = actId
    activityAnimStarted = false -- Reset flag
    
    -- Report start to Global Manager
    core.sendGlobalEvent("PC_ActivityStarted", { npc = self, activityId = actId })
    
    -- Gesture-style activities that are compatible with wandering should not
    -- create a return anchor; they layer over the current AI package.
    local shouldCaptureReturn = (act.compatibleWithWandering ~= true) or (act.sequence ~= nil)
    if shouldCaptureReturn then
        registerPreActivityPosition()
        dbg("Stored pre-activity pos: %s", tostring(preActivityPosition))
    else
        dbg("Activity '%s' is wandering-compatible; skipping pre-activity anchor.", actId)
    end
    
    -- Check for sequence-based activity
    if act.sequence then
        dbg("Activity '%s' has a sequence with %d steps.", actId, #act.sequence)
        activitySequence = act.sequence
        sequenceStep = 1
        -- Equip props first, then start sequence
        if act.props and #act.props > 0 then
            currentActivityOverrides = overrides
            for _, propId in ipairs(act.props) do
                PropManager.equipProp(propId)
            end
            -- Sequence will start after prop equip confirmation
        else
            executeSequenceStep()
        end
        return true
    end
    
    -- Equip Props (non-sequence path)
    if act.props and #act.props > 0 then
        currentActivityOverrides = overrides
        for _, propId in ipairs(act.props) do
            PropManager.equipProp(propId)
        end
    else
        -- No props, play animation immediately
        dbg("Activity %s has no props. Playing '%s' immediately.", actId, act.anim)
        local anim = require('openmw.animation')
        local I = require('openmw.interfaces')
        
        local mask = act.mask or 14
        local activePkg = ai.getActivePackage()
        local isWandering = (activePkg and activePkg.type == 'Wander')
        local isTraveling = (activePkg and activePkg.type == 'Travel')
        local isSitting = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
        
        if isSitting or isWandering or isTraveling then
            mask = 14 -- Force Upper Body if Sitting, Wandering, or Traveling
        end
        
        -- Determine Loops
        local loopCount = 1
        if overrides and overrides.minLoops and overrides.maxLoops then
            loopCount = math.random(overrides.minLoops, overrides.maxLoops)
            dbg("Activity Loop Count: %d", loopCount)
        else
            loopCount = (act.loops ~= false) and 999 or 1 
        end
        
        local config = { 
             blendMask = mask, 
             priority = act.priority or 13,
             loops = loopCount,
             forceLoop = (loopCount > 1),
             blendDuration = act.blendTime -- Custom Lerp if supported
        }

        local ok, err = pcall(function()
             I.AnimationController.playBlendedAnimation(act.anim, config)
        end)
        if not ok then
             dbg("WARN: Failed to play activity animation (NPC Disabled?): %s", tostring(err))
             currentActivity = nil
             core.sendGlobalEvent("PC_ActivityFinished", { npc = self })
             return false
        end
        activityAnimStarted = true
    end
    return true
end


local isHolding = false
local holdPosition = nil

local function onSay(data)
    if data.file then
        core.sound.say(data.file, self, data.text)
    end
end

local function onStopVoice(_data)
    if currentConversationGesture then
        local anim = require('openmw.animation')
        pcall(function() anim.cancel(self, currentConversationGesture) end)
        currentConversationGesture = nil
    end
    if core.sound and core.sound.isSayActive and core.sound.stopSay then
        local ok, active = pcall(core.sound.isSayActive, self)
        if ok and active then
            pcall(core.sound.stopSay, self)
        end
    end
end

local function isPhysicallySitting()
    if SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting() then return true end
    if NPCState.isSitting(self.id) then return true end
    local sittingState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
    if sittingState == "seated" or sittingState == "walking_to_seat" then return true end

    local anim = require('openmw.animation')
    local ok, result = pcall(function()
        return anim.isPlaying(self, "sdpvasitting6")
            or anim.isPlaying(self, "pcdbssit5")
            or anim.isPlaying(self, "dbssit5")
            or anim.isPlaying(self, "dbssit6")
            or anim.isPlaying(self, "sitidle1")
            or anim.isPlaying(self, "IdleSit")
            or anim.isPlaying(self, "ChairSit01")
    end)
    return ok and result == true
end

local function isSleepTransitionActive()
    local sleepState = SleepLogic and SleepLogic.getState and SleepLogic.getState() or nil
    return sleepState == "walking_to_bed"
        or sleepState == "laying_down"
        or sleepState == "waking_up"
        or sleepState == "sleeping"
        or NPCState.isPendingSleep(self.id)
        or NPCState.isSleeping(self.id)
end

local function cancelConversationGesture()
    if not currentConversationGesture then return end
    local anim = require('openmw.animation')
    pcall(function() anim.cancel(self, currentConversationGesture) end)
    currentConversationGesture = nil
end

local function onPlayConversationAnimation(data)
    data = data or {}
    local animName = data.anim
    if type(animName) ~= "string" or animName == "" then return end

    local currentLocalState = sm and sm:get() or "idle"
    if currentLocalState == "sleeping"
            or currentLocalState == "waking"
            or currentLocalState == "combat"
            or currentLocalState == "departing"
            or currentLocalState == "transitioning"
            or currentLocalState == "arriving" then
        dbg("Skipping conversation gesture '%s' in state '%s'", animName, currentLocalState)
        return
    end

    local I = require('openmw.interfaces')
    if not (I and I.AnimationController and I.AnimationController.playBlendedAnimation) then
        dbg("Skipping conversation gesture '%s': AnimationController missing", animName)
        return
    end

    cancelConversationGesture()

    local activePkg = ai.getActivePackage()
    local isWandering = activePkg and activePkg.type == "Wander"
    local isTraveling = activePkg and activePkg.type == "Travel"
    local isSeated = isPhysicallySitting()

    local mask = data.mask or 14
    if isSeated or isWandering or isTraveling or isHolding or currentLocalState == "conversation" then
        mask = 14
    end

    local loops = data.loops or 1
    local config = {
        blendMask = mask,
        priority = data.priority or 13,
        loops = loops,
        forceLoop = data.forceLoop == true,
        blendDuration = data.blendDuration,
    }

    local ok, err = pcall(function()
        I.AnimationController.playBlendedAnimation(animName, config)
    end)
    if not ok then
        dbg("WARN: Failed to play conversation gesture '%s': %s", animName, tostring(err))
        return
    end

    currentConversationGesture = animName
end

local isWalkingToTarget = false
local currentWalkTarget = nil
local currentStopDist = 0
local pendingWalkAfterStand = nil
local isWaitingForConversationStandUp = false

local function suppressHello()
    if originalHello then return end  -- already suppressed
    local helloStat = types.Actor.stats.ai.hello(self)
    originalHello = helloStat.base
    helloStat.base = 0
end

local function restoreHello()
    if originalHello then
        local helloStat = types.Actor.stats.ai.hello(self)
        helloStat.base = originalHello
        originalHello = nil
    end
end

local function onWalkTo(data)
    -- data: { target = vector3, stopDistance = number }
    data = data or {}

    if Blacklist.isHostileByDefault(self.object) then
        dbg("NPC %s REJECT WalkTo (hostile by default)", self.recordId)
        return
    end

    if data.conversationWalk and (sm:is("hostile") or NPCState.isHostile(self.id) or isRuntimeHostileNow()) then
        dbg("NPC %s REJECT WalkTo (runtime hostile)", self.recordId)
        rejectConversationForHostility("hostile")
        return
    end

    if scheduleControlled or sm:is("departing") or sm:is("transitioning")
            or sm:is("arriving") or sm:is("returning") then
        dbg("NPC %s REJECT WalkTo (schedule relocation, state=%s)", self.recordId, sm:get())
        if data.conversationWalk then
            core.sendGlobalEvent("PC_ConversationWalkRejected", {
                npcId = self.object.id,
                reason = "schedule_relocation",
            })
        end
        return
    end
    if isSleepTransitionActive() then
        dbg("NPC %s REJECT WalkTo (sleep transition, sleepState=%s globalState=%s)",
            self.recordId,
            tostring(SleepLogic and SleepLogic.getState and SleepLogic.getState()),
            tostring(NPCState.get(self.id)))
        if data.conversationWalk then
            core.sendGlobalEvent("PC_ConversationWalkRejected", {
                npcId = self.object.id,
                reason = "sleep_transition",
            })
        end
        return
    end
    if NPCState.isInTransit(self.object.id) and not data.conversationWalk then
        dbg("NPC %s REJECT WalkTo (in transit, state=%s)", self.recordId, NPCState.get(self.object.id))
        return
    end
    if NPCState.isInTransit(self.object.id) and data.conversationWalk then
        dbg("NPC %s REJECT WalkTo (in transit, state=%s)", self.recordId, NPCState.get(self.object.id))
        core.sendGlobalEvent("PC_ConversationWalkRejected", {
            npcId = self.object.id,
            reason = "in_transit",
        })
        return
    end

    if not NPCState.canWalkTo(self.id) then
        dbg("NPC %s REJECT WalkTo (state=%s)", self.recordId, sm:get())
        if data.conversationWalk then
            core.sendGlobalEvent("PC_ConversationWalkRejected", {
                npcId = self.object.id,
                reason = "npc_state",
            })
        end
        return
    end

    dbg("NPC %s walking to target: %s (StopDist: %s)", self.recordId, tostring(data.target), tostring(data.stopDistance))
    
    -- Check local blacklist FIRST — if blacklisted, don't save any state.
    local walkBlacklisted
    if data.conversationWalk then
        walkBlacklisted = Blacklist.isConversationWalkBlacklisted(self.object)
    else
        walkBlacklisted = Blacklist.isSitBlacklisted(self.object)
    end
    if walkBlacklisted then
        dbg("NPC %s refuse PC_WalkTo: Blacklisted.", self.recordId)
        return 
    end

    if not preActivityPosition then
        saveBehaviorForReturn("PC_WalkTo")
        dbg("NPC %s saved pre-activity pos: %s", self.recordId, tostring(preActivityPosition))
    end
    suppressHello()

    local destVal = data.target
    if destVal.position then destVal = destVal.position end -- Extract vector if target is an object

    local sittingState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
    local isSeated = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
        or sittingState == "seated"
        or NPCState.isSitting(self.id)

    if isSeated then
        if data.forceStandForConversation and SittingLogic.requestStand then
            dbg("NPC %s standing up for walking conversation.", self.recordId)
            pendingWalkAfterStand = {
                target = util.vector3(destVal.x, destVal.y, destVal.z),
                stopDistance = data.stopDistance or 50
            }
            currentWalkIsConversation = data.conversationWalk == true
            isWaitingForConversationStandUp = true
            isWaitingForStandUp = true
            if SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting() then
                pcall(function() SittingLogic.requestStand("conversation") end)
            else
                core.sendGlobalEvent("PC_CancelSittingForNpc", { npc = self.object, reason = "conversation" })
            end
            transitionTo("walking", data)
            return
        end

        dbg("NPC %s is sitting. Skipping WalkTo...", self.recordId)
        -- We still send PC_Arrived to keep flow alive, assuming they are "Static".
        core.sendGlobalEvent("PC_Arrived", { npc = self, target = data.target })
        return
    end

    ai.startPackage({
        type = "Travel",
        destPosition = util.vector3(destVal.x, destVal.y, destVal.z),
    })
    isWalkingToTarget = true
    currentWalkTarget = destVal
    currentStopDist = data.stopDistance or 50
    walkTimeout = WALK_TIMEOUT
    currentWalkIsConversation = data.conversationWalk == true
    armTargetedTravel(currentWalkTarget, currentWalkIsConversation and "conversation_walk" or "walk_to", currentStopDist)
    transitionTo("walking", data)
end

local function restoreWanderForCurrentCell()
    local inNativeCell = false
    pcall(function()
        inNativeCell = nativeHome and nativeHome.cellName
            and self.cell and self.cell.name == nativeHome.cellName
    end)

    if inNativeCell then
        local pkg = resolveNativeWanderPackage() or savedWanderPackage
        if pkg then
            dbg("NPC %s in native cell; restoring native wander (instant).", self.recordId)
            ai.startPackage(pkg)
            savedWanderPackage = nil
        else
            dbg("NPC %s in native cell; no native wander, staying idle (instant).", self.recordId)
        end
    else
        dbg("NPC %s in foreign cell; starting default wander (instant).", self.recordId)
        ai.startPackage(makeDefaultForeignWander())
    end
end

local function clearConversationWalkState()
    cancelConversationGesture()
    lookAtTarget = nil
    isHolding = false
    holdPosition = nil
    isWalkingToTarget = false
    currentWalkTarget = nil
    walkTimeout = 0
    currentWalkIsConversation = false
    returnTargetPos = nil
    returnTargetRot = nil
    clearTargetedTravel()
end

local function finishInstantReturn(destPos, destRot)
    ai.removePackages("Travel")
    clearConversationWalkState()

    if destPos then
        local cellName = ""
        pcall(function() cellName = self.cell and self.cell.name or "" end)
        if cellName ~= "" then
            Utils.tryTeleport(self.object, cellName, destPos, { rotation = destRot or self.rotation })
        end
    end

    restoreWanderForCurrentCell()
    restoreHello()
    transitionTo("idle")
    core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "instant_return" })
end

--- End a conversation without a walk-back (seated or mid seat approach).
local function finishConversationInPlace(context)
    clearConversationWalkState()
    preActivityPosition = nil
    preActivityRotation = nil

    local sittingState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
    local preserveSitAi = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
        or sittingState == "walking_to_seat"
    if preserveSitAi then
        dbg("NPC %s in sit flow; skipping wander restore after conversation.", self.recordId)
    else
        restoreWanderForCurrentCell()
    end

    restoreHello()
    transitionTo("idle")
    if SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting() then
        core.sendGlobalEvent("PC_StateChanged", {
            npcId = self.id,
            state = "sitting",
            prevState = "conversation",
        })
    end
    core.sendGlobalEvent("PC_NpcStateReleased", {
        npc = self.object,
        context = context or "conversation_ended_in_place",
    })
end

local function onReturn(data)
    dbg("NPC %s returning to start checks...", self.recordId)
    data = data or {}
    cancelConversationGesture()

    if scheduleControlled or departureState or sm:is("departing") or sm:is("transitioning")
            or NPCState.get(self.object.id) == "departing"
            or NPCState.get(self.object.id) == "transitioning" then
        dbg("NPC %s ignoring PC_Return during schedule relocation", self.recordId)
        lookAtTarget = nil
        isHolding = false
        holdPosition = nil
        isWalkingToTarget = false
        currentWalkTarget = nil
        walkTimeout = 0
        currentWalkIsConversation = false
        clearTargetedTravel()
        preActivityPosition = nil
        preActivityRotation = nil
        return
    end

    local sittingState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
    if sittingState == "walking_to_seat" then
        dbg("NPC %s is walking_to_seat; ending conversation without return walk.", self.recordId)
        finishConversationInPlace("conversation_ended_walking_to_seat")
        return
    end

    if SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting() then
        dbg("NPC %s is sitting; ending conversation in place.", self.recordId)
        finishConversationInPlace("conversation_ended_while_seated")
        return
    end

    lookAtTarget = nil -- Stop looking when returning
    isHolding = false -- Stop leashing
    holdPosition = nil
    isWalkingToTarget = false
    currentWalkTarget = nil
    walkTimeout = 0
    currentWalkIsConversation = false
    clearTargetedTravel()

    -- If a schedule move is pending, skip the return-to-pre-activity walk.
    -- Schedule teleports send PC_Return as cleanup; it must not turn the
    -- schedule state back into a normal activity return.
    if NPCState.isScheduled(self.object.id) or NPCState.isInTransit(self.object.id) then
        dbg("NPC %s has pending schedule assignment; skipping return-to-pre-activity", self.recordId)
        preActivityPosition = nil
        preActivityRotation = nil
        if sm:is("conversation") then
            finishConversationInPlace("conversation_ended_schedule_pending")
        end
        return
    end

    if data.instant then
        if data.afterForcedSeatedConversation then
            local inNativeCell = false
            pcall(function()
                inNativeCell = nativeHome and nativeHome.cellName
                    and self.cell and self.cell.name == nativeHome.cellName
            end)

            if inNativeCell and nativeHome and nativeHome.position then
                dbg("NPC %s instant return to native position after seated conversation.", self.recordId)
                preActivityPosition = nil
                preActivityRotation = nil
                finishInstantReturn(nativeHome.position, nativeHome.rotation or self.rotation)
                return
            end

            dbg("NPC %s instant foreign-cell wander after seated conversation.", self.recordId)
            ai.removePackages("Travel")
            clearConversationWalkState()
            ai.startPackage(makeDefaultForeignWander())
            preActivityPosition = nil
            preActivityRotation = nil
            restoreHello()
            transitionTo("idle")
            core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "seated_conversation_wander" })
            return
        end

        if preActivityPosition then
            local pos = preActivityPosition
            local rot = preActivityRotation
            preActivityPosition = nil
            preActivityRotation = nil
            finishInstantReturn(pos, rot)
            return
        end

        dbg("NPC %s instant return with no destination; going idle.", self.recordId)
        clearConversationWalkState()
        restoreHello()
        transitionTo("idle")
        core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "instant_return_no_position" })
        return
    end

    if data.afterForcedSeatedConversation then
        local inNativeCell = false
        pcall(function()
            inNativeCell = nativeHome and nativeHome.cellName
                and self.cell and self.cell.name == nativeHome.cellName
        end)

        if inNativeCell and nativeHome and nativeHome.position then
            dbg("NPC %s returning to native position after seated conversation.", self.recordId)
            returnTargetPos = nativeHome.position
            returnTargetRot = nativeHome.rotation or self.rotation
            transitionTo("returning")
            ai.removePackages("Travel")
            ai.startPackage({
                type = "Travel",
                destPosition = returnTargetPos,
            })
            armTargetedTravel(returnTargetPos, "conversation_native_return", 50)
            suppressHello()
            preActivityPosition = nil
            preActivityRotation = nil
            return
        end

        dbg("NPC %s starting foreign-cell wander after seated conversation.", self.recordId)
        ai.removePackages("Travel")
        ai.startPackage(makeDefaultForeignWander())
        preActivityPosition = nil
        preActivityRotation = nil
        transitionTo("idle")
        core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "seated_conversation_wander" })
        return
    end

    if preActivityPosition then
        dbg("NPC %s returning to pre-activity pos: %s", self.recordId, tostring(preActivityPosition))

        -- Setup rotation restoration
        returnTargetPos = preActivityPosition
        returnTargetRot = preActivityRotation

        -- Enter returning before Travel so onUpdate won't treat this walk as external.
        transitionTo("returning")

        -- Remove "WalkTo" or "Hold" packages to prevent stack confusion
        ai.removePackages("Travel")

        ai.startPackage({
            type = "Travel",
            destPosition = preActivityPosition,
        })
        armTargetedTravel(returnTargetPos, "conversation_return", 50)
        suppressHello()
        preActivityPosition = nil
        preActivityRotation = nil
        return
    else
        dbg("NPC %s has no pre-activity position to return to!", self.recordId)
        local wasDeparting = sm:is("departing") or NPCState.get(self.object.id) == "departing"
        transitionTo("idle")
        if not wasDeparting then
            core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "return_no_position" })
        end
        return
    end
end

local function onStop(data)
    cancelConversationGesture()
    if NPCState.isInTransit(self.object.id) then
        dbg("NPC %s ignoring PC_Stop while schedule-controlled (state=%s)", self.recordId, NPCState.get(self.object.id))
        lookAtTarget = nil
        isHolding = false
        holdPosition = nil
        return
    end

    local sittingState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
    if (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
            or sittingState == "walking_to_seat" then
        dbg("NPC %s ignoring PC_Stop while seating/sitting", self.recordId)
        lookAtTarget = nil
        isHolding = false
        holdPosition = nil
        return
    end

    -- Remove the "WalkTo" package so they stop trying to reach the exact point
    ai.removePackages("Travel")
    isWalkingToTarget = false
    currentWalkTarget = nil
    walkTimeout = 0
    currentWalkIsConversation = false
    clearTargetedTravel()
    restoreHello()
    
    -- Enable Leashing
    isHolding = true
    holdPosition = self.position
    
    -- Initial Hold
    ai.startPackage({
        type = "Travel",
        destPosition = self.position
    })
end

local function onRestoreHello(data)
    restoreHello()
end

local function onFace(data)
    dbg("DEBUG: NPC %s Received PC_Face event", self.recordId)
    dbg("DEBUG: SittingLogic exists? %s | isSitting? %s", tostring(SittingLogic ~= nil), tostring(SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting()))
    -- data: { target = object }
    if sm:is("hostile") or NPCState.isHostile(self.id) or isRuntimeHostileNow() then
        dbg("NPC %s REJECT Face (runtime hostile)", self.recordId)
        self.controls.yawChange = 0
        lookAtTarget = nil
        rejectConversationForHostility("hostile")
        return
    end
    if not originalRotation then
        originalRotation = self.rotation
        dbg("NPC %s saved rotation for Face event.", self.recordId)
    end
    lookAtTarget = data.target
    
    -- Request Sitting Rotation (Separate Logic)
    if SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting() then
        dbg("DEBUG: NPC %s onFace (Sitting). Sending Rotation Request.", self.recordId)
        if data.target then
            core.sendGlobalEvent("PC_ConversationRotate", { 
                npc = self, 
                target = data.target, -- Pass object for Sitting check
                position = data.target.position 
            })
        end
        -- Disable local rotation
        self.controls.yawChange = 0
        return
    end
end

-- =============================================================================
-- Save-game migration map
-- =============================================================================
local STATE_MIGRATION = {
    conversing = "conversation",
    scheduleDeparting = "departing",
    scheduleTransitioning = "transitioning",
    scheduleArriving = "arriving",
}

-- =============================================================================
-- State Machine
-- =============================================================================

local function initializeStateMachine()
    sm = StateMachine.create({
        idle = {
            enter = function(prev, data) end,
            update = function(dt) end,
            exit = function(next) end,
        },
        walking = {
            enter = function(prev, data) end,
            update = function(dt)
                if isWalkingToTarget and currentWalkTarget then
                    walkTimeout = walkTimeout - dt
                    local dist = (self.position - currentWalkTarget):length()
                    local active = ai.getActivePackage()
                    
                    if dist < currentStopDist or (not active or active.type ~= "Travel") or walkTimeout <= 0 then
                        if walkTimeout <= 0 then
                            dbg("NPC %s walk TIMEOUT (Dist: %.2f).", self.recordId, dist)
                        else
                            dbg("NPC %s arrived (Dist: %.2f).", self.recordId, dist)
                        end
                        isWalkingToTarget = false
                        currentWalkTarget = nil
                        walkTimeout = 0
                        currentWalkIsConversation = false
                        clearTargetedTravel()
                        ai.removePackages("Travel")
                        
                        if nativeHome and nativeHome.wander then
                            ai.startPackage(nativeHome.wander)
                        end
                        restoreHello()
                        transitionTo("idle")
                        core.sendGlobalEvent("PC_Arrived", { actor = self })
                    end
                end
            end,
            exit = function(next) end,
        },
        departing = {
            enter = function(prev, data) end,
            update = function(dt)
                if departureState then
                    departureTimeout = departureTimeout - dt

                    if departureTimeout <= 0 then
                        local wasWalking = (departureState == "walking_to_door")
                        departureState   = nil
                        departureDoorPos = nil
                        departureTimeout = 0
                        departureTravelRetries = 0
                        if wasWalking then pcall(function() ai.removePackages("Travel") end) end
                        clearTargetedTravel()
                        restoreHello()
                        transitionTo("idle")
                        core.sendGlobalEvent("PC_DepartureReachedDoor", { npc = self })

                    elseif departureState == "teardown" then
                        local busy = false
                        if currentActivity then busy = true end
                        if not busy then
                            pcall(function()
                                if SittingLogic.isSitting and SittingLogic.isSitting() then busy = true end
                            end)
                        end
                        if not busy then
                            pcall(function()
                                if SleepLogic.isSleeping and SleepLogic.isSleeping() then busy = true end
                            end)
                        end
                        if not busy and (isWaitingForStandUp or isWaitingForWakeUp) then busy = true end

                        if not busy and departureDoorPos then
                            departureState = "walking_to_door"
                            departureTravelRetries = 0
                            suppressHello()
                            pcall(function() ai.removePackages("Travel") end)
                            pcall(function()
                                ai.startPackage({ type = "Travel", destPosition = departureDoorPos })
                            end)
                            armTargetedTravel(departureDoorPos, "departure_door", DEPARTURE_DOOR_DIST)
                        end

                    elseif departureState == "walking_to_door" and departureDoorPos then
                        local dist = 999999
                        pcall(function() dist = (self.position - departureDoorPos):length() end)
                        local active = nil
                        pcall(function() active = ai.getActivePackage() end)
                        local travelActive = active and active.type == "Travel"
                        if dist < DEPARTURE_DOOR_DIST then
                            departureState   = nil
                            departureDoorPos = nil
                            departureTimeout = 0
                            departureTravelRetries = 0
                            clearTargetedTravel()
                            restoreHello()
                            transitionTo("idle")
                            core.sendGlobalEvent("PC_DepartureReachedDoor", { npc = self })
                        elseif not travelActive and departureTravelRetries < DEPARTURE_TRAVEL_RETRIES then
                            departureTravelRetries = departureTravelRetries + 1
                            pcall(function()
                                ai.startPackage({ type = "Travel", destPosition = departureDoorPos })
                            end)
                            armTargetedTravel(departureDoorPos, "departure_door_retry", DEPARTURE_DOOR_DIST)
                        elseif not travelActive then
                            dbg("NPC %s departure Travel stopped near door (Dist: %.2f); completing handoff", self.recordId, dist)
                            departureState   = nil
                            departureDoorPos = nil
                            departureTimeout = 0
                            departureTravelRetries = 0
                            clearTargetedTravel()
                            restoreHello()
                            transitionTo("idle")
                            core.sendGlobalEvent("PC_DepartureReachedDoor", { npc = self })
                        end
                    end
                end
            end,
            exit = function(next) end,
        },
        transitioning = {
            enter = function(prev, data) end,
            update = function(dt)
                if transitionWalkTarget then
                    transitionTimeout = transitionTimeout - dt
                    local dist = 999999
                    pcall(function() dist = (self.position - transitionWalkTarget):length() end)
                    local active = nil
                    pcall(function() active = ai.getActivePackage() end)
                    if dist < 150 or transitionTimeout <= 0 then
                        if transitionTimeout <= 0 then
                            dbg("NPC %s transition TIMEOUT (Dist: %.2f).", self.recordId, dist)
                        end
                        transitionWalkTarget = nil
                        transitionTimeout = 0
                        clearTargetedTravel()
                        pcall(function() ai.removePackages("Travel") end)
                        restoreHello()
                        transitionTo("idle")
                        core.sendGlobalEvent("PC_TransitionComplete", { npc = self })
                    end
                end
            end,
            exit = function(next) end,
        },
        arriving = {
            enter = function(prev, data) end,
            update = function(dt)
                if arrivalWalkTarget then
                    arrivalTimeout = arrivalTimeout - dt
                    local dist = 999999
                    pcall(function() dist = (self.position - arrivalWalkTarget):length() end)

                    if dist < ARRIVAL_DIST then
                        arrivalWalkTarget = nil
                        arrivalTimeout = 0
                        clearTargetedTravel()
                        pcall(function() ai.removePackages("Travel") end)
                        restoreHello()
                        scheduleControlled = false
                        transitionTo("idle")
                        core.sendGlobalEvent("PC_ArrivalComplete", { npc = self })
                    elseif arrivalTimeout <= 0 then
                        dbg("NPC %s arrival TIMEOUT (dist=%.1f). Requesting teleport fallback.",
                            self.recordId, dist)
                        local failedTarget = arrivalWalkTarget
                        arrivalWalkTarget = nil
                        arrivalTimeout = 0
                        clearTargetedTravel()
                        pcall(function() ai.removePackages("Travel") end)
                        restoreHello()
                        scheduleControlled = false
                        transitionTo("idle")
                        core.sendGlobalEvent("PC_ArrivalFailed", { npc = self, targetPos = failedTarget })
                    end
                end
            end,
            exit = function(next) end,
        },
        activity = {
            enter = function(prev, data) end,
            update = function(dt)
                if currentActivity then
                    local act = ActivityLibrary[currentActivity]
                    local checkAnim = currentSequenceAnim or act.anim
                    local isSequence = activitySequence and sequenceStep > 0
                    if act and (act.loops == false or isSequence) and checkAnim then
                         local anim = require('openmw.animation')
                         if not anim.isPlaying(self, checkAnim) then
                             if activityAnimStarted then
                                  if activitySequence and sequenceStep <= #activitySequence then
                                      local step = activitySequence[sequenceStep]
                                      if step.type == "anim" then
                                          dbg("Sequence anim step %d complete.", sequenceStep)
                                          activityAnimStarted = false
                                          sequenceStep = sequenceStep + 1
                                          executeSequenceStep()
                                      end
                                  else
                                      dbg("Animation '%s' finished. Ending activity.", checkAnim)
                                      local nextAct = act.next
                                      stopActivity()
                                      
                                      if nextAct then
                                          dbg("Chaining to next activity: %s", nextAct)
                                          startActivity(nextAct)
                                      else
                                          transitionTo("idle")
                                      end
                                  end
                             end
                         end
                    end
                end
                
                if sequenceWandering and sequenceTimer > 0 then
                    sequenceTimer = sequenceTimer - dt
                    if sequenceTimer <= 0 then
                        dbg("Sequence wander step complete.")
                        sequenceWandering = false
                        ai.removePackages("Wander")
                        sequenceStep = sequenceStep + 1
                        executeSequenceStep()
                    end
                end
            end,
            exit = function(next) end,
        },
        returning = {
            enter = function(prev, data) end,
            update = function(dt)
                if returnTargetPos and returnTargetRot then
                    local dist = (self.position - returnTargetPos):length()
                    if dist < 50 then
                         local forward = returnTargetRot * util.vector3(0, 1, 0)
                         local targetYaw = math.atan2(forward.x, forward.y)
                         
                         local currentForward = self.rotation * util.vector3(0, 1, 0)
                         local currentYaw = math.atan2(currentForward.x, currentForward.y)
                         
                         local diff = targetYaw - currentYaw
                         while diff > math.pi do diff = diff - 2 * math.pi end
                         while diff < -math.pi do diff = diff + 2 * math.pi end
                         
                         if math.abs(diff) > 0.05 then
                             self.controls.yawChange = diff * 5.0 * dt
                         else
                             self.controls.yawChange = 0
                             returnTargetPos = nil
                             returnTargetRot = nil
                             clearTargetedTravel()
                             dbg("NPC %s arrived and rotated.", self.recordId)
                             
                             ai.removePackages("Travel")
                             
                             -- In native cell: always restore nativeHome.wander (or stay idle).
                             -- In non-native cell: always use default 512 wander.
                             local inNativeCell = false
                             pcall(function()
                                 inNativeCell = nativeHome and nativeHome.cellName
                                     and self.cell and self.cell.name == nativeHome.cellName
                             end)
                             
                             if inNativeCell then
                                 local pkg = resolveNativeWanderPackage() or savedWanderPackage
                                 if pkg then
                                     dbg("NPC %s in native cell; restoring native wander.", self.recordId)
                                     ai.startPackage(pkg)
                                     savedWanderPackage = nil
                                 else
                                     dbg("NPC %s in native cell; native wander is nil, staying idle.", self.recordId)
                                 end
                             else
                                 dbg("NPC %s in foreign cell; starting default wander.", self.recordId)
                                 ai.startPackage(makeDefaultForeignWander())
                              end
                              restoreHello()
                              transitionTo("idle")
                          end
                     end
                 end
            end,
            exit = function(next) end,
        },
        conversation = {
            enter = function(prev, data) end,
            update = function(dt) end,
            exit = function(next) end,
        },
        sleeping = {
            enter = function(prev, data) end,
            update = function(dt) end,
            exit = function(next) end,
        },
        waking = {
            enter = function(prev, data) end,
            update = function(dt) end,
            exit = function(next) end,
        },
        combat = {
            enter = function(prev, data) end,
            update = function(dt) end,
            exit = function(next) end,
        },
        hostile = {
            enter = function(prev, data) end,
            update = function(dt)
                if not wasHostile then
                    hostilityClearTimer = hostilityClearTimer + dt
                    if hostilityClearTimer >= HOSTILITY_CLEAR_DELAY then
                        hostilityClearTimer = 0
                        core.sendGlobalEvent("PC_HostilityCleared", { actor = self.object, npcId = self.id })
                        if sm:get() == "hostile" then
                            transitionTo("idle")
                        end
                    end
                else
                    hostilityClearTimer = 0
                end
            end,
            exit = function(next) end,
        },
    }, "idle", {
        onTransition = function(prev, new, data)
            core.sendGlobalEvent("PC_StateChanged", {
                npcId = self.id,
                state = new,
                prevState = prev,
            })
        end
    })
end

initializeStateMachine()

function transitionTo(newState, data)
    sm:transition(newState, data)
end

isRuntimeHostileNow = function()
    local activePkg = nil
    pcall(function() activePkg = ai.getActivePackage() end)
    if activePkg and (activePkg.type == "Combat" or activePkg.type == "Pursue") then
        return true
    end

    if ai and ai.getTargets then
        local ok, targets = pcall(ai.getTargets, "Combat")
        if ok and targets and #targets > 0 then
            return true
        end
    end

    return false
end

rejectConversationForHostility = function(reason)
    core.sendGlobalEvent("PC_ConversationWalkRejected", {
        npcId = self.id,
        reason = reason or "hostile",
    })
end

local function onUpdate(dt)
    -- ============================================
    -- UNIVERSAL BLOCK (always runs)
    -- ============================================

    -- 1. Native home capture (first frame)
    if not nativeHomeCaptured then
        if Blacklist.isHostileByDefault(self.object) then
            nativeHomeCaptured = true
            return
        end
        if not SleepLogic.isSleeping() and not SittingLogic.isSitting() then
            local pkg = ai.getActivePackage()
            local activeWander = copyWanderPackage(pkg)
            local pos, rot, wander
            local storedHome = loadStoredNativeHome()
            -- Do not persist wander while still on a schedule door→home walk; position
            -- would be the door and could poison PC_NativeHomes for new saves.
            -- Persist native wander whenever we see an active Wander package.
            -- If a stored home already exists we can safely update just the wander
            -- data even while in transit; for brand-new NPCs we only capture when
            -- not on a schedule walk so the door position doesn't poison the store.
            local onScheduleArrivalWalk = sm:is("arriving") or sm:is("departing")
                or sm:is("transitioning") or NPCState.isInTransit(self.object.id)
            if activeWander and (storedHome or not onScheduleArrivalWalk) then
                persistNativeWander(activeWander)
            end

            if storedHome then
                pos = storedHome.position
                rot = storedHome.rotation
                wander = storedHome.wander or activeWander
                originalCellName = storedHome.cellName or ""
            else
                pos = self.position
                rot = self.rotation
                wander = activeWander
                originalCellName = getCurrentCellName()
            end

            local homeCellName = originalCellName
            if homeCellName == "" then
                homeCellName = getCurrentCellName()
            end
            nativeHome = { position = pos, rotation = rot, wander = wander, cellName = homeCellName }
            nativeHomeCaptured = true
            SleepLogic.setNativeHome(nativeHome)

            if storedHome then
                originalPosition = storedHome.position
                originalRotation = storedHome.rotation
                if storedHome.cellName and storedHome.cellName ~= "" then
                    originalCellName = storedHome.cellName
                end
            elseif not originalPosition then
                originalPosition = pos
                originalRotation = rot
                if originalCellName == "" then
                    originalCellName = homeCellName
                end
            end
        end
    end

    -- 2. Substate gatekeepers
    SittingLogic.update(dt)
    SleepLogic.update(dt)
    if travelUnstuck then travelUnstuck.update(dt) end

    -- 2b. Auto-capture behavior if an external system (SittingGlobal, SleepManager)
    -- started a Travel package without going through PC_WalkTo.
    -- Skip schedule relocation walks (door depart/arrive) so conversation return
    -- does not send the NPC back to a transient door position.
    local globalNpcState = NPCState.get(self.object.id)
    local scheduleStationary = globalNpcState == "at_destination" or globalNpcState == "at_home"

    if not preActivityPosition and not scheduleControlled and not scheduleStationary
            and not sm:is("departing") and not sm:is("transitioning")
            and not sm:is("arriving") and not sm:is("returning")
            and not arrivalWalkTarget
            and not NPCState.isInTransit(self.object.id)
            and globalNpcState ~= "traveling_home"
            and globalNpcState ~= "traveling_to_destination"
            and globalNpcState ~= "departing"
            and globalNpcState ~= "transitioning"
            and globalNpcState ~= "arriving"
            and globalNpcState ~= "returning" then
        local pkg = ai.getActivePackage()
        if pkg and pkg.type == "Travel" then
            registerPreActivityPosition()
            dbg("NPC %s auto-captured pre-activity position for external Travel", self.recordId)
        end
    end

    -- Hostility state reconciliation: if global bus still shows "hostile" but
    -- local script has restarted (e.g., after cell change) and NPC is not
    -- currently in combat, sync global back to idle so behaviors can resume.
    if NPCState.get(self.id) == "hostile" and sm:get() ~= "hostile" then
        local currentlyHostile = isRuntimeHostileNow()
        if not currentlyHostile then
            dbg("NPC %s reconciling stale global hostile state → idle", self.recordId)
            core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "idle", prevState = "hostile" })
        end
    end
    
    -- 3. Leashing (holding substate) — disabled during schedule door walks
    if isHolding and holdPosition and not sm:is("departing") and not sm:is("transitioning") then
        local distToHold = (self.position - holdPosition):length()
        if distToHold > 50 then 
            ai.startPackage({
                type = "Travel",
                destPosition = holdPosition
            })
        end
    end
    
    -- 4. Facing Logic (facing substate)
    if lookAtTarget then
        if not lookAtTarget:isValid() then
            lookAtTarget = nil
            return
        end

        if sm:is("sleeping") or sm:is("waking")
                or (SleepLogic and SleepLogic.getState and SleepLogic.getState() ~= "idle") then
            lookAtTarget = nil
            self.controls.yawChange = 0
            return
        end
        
        if SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting() then
            self.controls.yawChange = 0
            return
        end
        
        local delta = lookAtTarget.position - self.position
        local targetYaw = math.atan2(delta.x, delta.y)
        
        local forward = self.rotation * util.vector3(0, 1, 0)
        local currentYaw = math.atan2(forward.x, forward.y)
        
        local diff = targetYaw - currentYaw
        while diff > math.pi do diff = diff - 2 * math.pi end
        while diff < -math.pi do diff = diff + 2 * math.pi end
        
        if math.abs(diff) > 0.05 then
            self.controls.yawChange = diff * 5.0 * dt
        else
            self.controls.yawChange = 0
        end
    end

    -- 5. Hostility Monitor (runtime combat propagation)
    hostilityCheckTimer = hostilityCheckTimer + dt
    local isHostileNow = false
    local didHostilityCheck = false
    if hostilityCheckTimer >= HOSTILITY_CHECK_INTERVAL then
        hostilityCheckTimer = 0
        didHostilityCheck = true
        isHostileNow = isRuntimeHostileNow()
    end

    if didHostilityCheck then
        if isHostileNow and not wasHostile then
            dbg("NPC %s entered hostility!", self.recordId)
            wasHostile = true
            hostilityClearTimer = 0

            -- New comprehensive hostility event. PC_CombatStarted remains a
            -- compatibility ingress for older callers, routed globally.
            core.sendGlobalEvent("PC_HostilityStarted", { actor = self.object, npcId = self.id })

            -- Clear all movement flags (same as PC_CombatStarted handler)
            isWalkingToTarget = false
            currentWalkTarget = nil
            walkTimeout = 0
            departureState   = nil
            departureDoorPos = nil
            departureTimeout = 0
            arrivalWalkTarget = nil
            arrivalTimeout = 0
            transitionWalkTarget = nil
            transitionTimeout = 0
            returnTargetPos = nil
            returnTargetRot = nil
            preActivityPosition = nil
            preActivityRotation = nil
            clearTargetedTravel()
            pcall(function() ai.removePackages("Travel") end)
            restoreHello()

            -- Stop local activity
            stopActivity()

            -- Stand up if seated
            local sittingState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
            local isSeated = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
                or sittingState == "seated"
                or NPCState.isSitting(self.id)
            if isSeated then
                if SittingLogic and SittingLogic.requestStand then
                    pcall(function() SittingLogic.requestStand("hostility") end)
                else
                    core.sendGlobalEvent("PC_CancelSittingForNpc", { npc = self.object, reason = "hostility" })
                end
            end

            -- Wake if sleeping
            if sm:is("sleeping") or sm:is("waking") or NPCState.isSleeping(self.id) then
                if SleepLogic and SleepLogic.requestWake then
                    pcall(function() SleepLogic.requestWake() end)
                end
                core.sendGlobalEvent("PC_WakeMeUp", { npc = self.object })
            end

            transitionTo("hostile")
        elseif not isHostileNow and wasHostile then
            wasHostile = false
        end
    end

    -- 6. Activity Cleanup Monitor (universal failsafe)
    activityCleanupTimer = activityCleanupTimer + dt
    if activityCleanupTimer > 30.0 then
        activityCleanupTimer = 0
        if not currentActivity then
             local inv = types.Actor.inventory(self)
             for _, act in pairs(ActivityLibrary) do
                  if act.props then
                      for _, pid in ipairs(act.props) do
                           if inv:find(pid) then
                               dbg("Failsafe: Removing stuck prop %s", pid)
                               PropManager.cleanupProp(pid)
                           end
                      end
                  end
             end
        end
    end

    -- ============================================
    -- PRIMARY STATE UPDATE
    -- ============================================
    -- Save-game migration: remap old local state names on first update
    if not _firstUpdateDone then
        _firstUpdateDone = true
        local migrated = STATE_MIGRATION[sm:get()]
        if migrated then
            dbg("MIGRATING state %s -> %s", sm:get(), migrated)
            transitionTo(migrated)
        end
    end

    if sm:get() then
        sm:update(dt)
    end
end

-- Cell Exit Handler: Return NPC to pre-activity position when player leaves.
-- If the schedule system flagged this NPC (scheduleControlled), skip the
-- teleport-back so we don't fight the schedule displacement.
local function onInactive()
    if scheduleControlled then
        -- Schedule system is moving this NPC — don't fight it.
        scheduleControlled = false
        stopActivity()
        preActivityPosition = nil
        preActivityRotation = nil
        return
    end
    if preActivityPosition then
        -- Don't teleport the NPC if they are actively walking/traveling.
        -- onInactive can fire when an NPC simply walks across a cell boundary
        -- or when the engine does a quick script restart; teleporting them back
        -- to their pre-activity position looks like an awkward snap.
        local active = ai.getActivePackage()
        if active and (active.type == "Travel" or active.type == "Wander") then
            preActivityPosition = nil
            preActivityRotation = nil
            stopActivity()
            return
        end
        dbg("NPC %s becoming inactive. Returning to pre-activity pos.", self.recordId)
        local cellName = ""
        pcall(function() cellName = self.cell and self.cell.name or "" end)
        if cellName ~= "" then
             core.sendGlobalEvent("PC_Teleport", {
                 npc = self,
                 cell = cellName,
                 position = preActivityPosition,
                 rotation = preActivityRotation
             })
        end
        preActivityPosition = nil
        preActivityRotation = nil
        stopActivity()
    end
end

-- HELPER: Local Activity Manager
-- Moved to top

local function onStartWander(data)
    dbg("Received PC_StartWander event for %s", self.recordId)
    scheduleControlled = false
    if sm:is("hostile") then
        dbg("NPC %s is hostile; ignoring wander start", self.recordId)
        return
    end
    local sleepState = SleepLogic and SleepLogic.getState and SleepLogic.getState() or nil
    if sm:is("sleeping") or sm:is("waking") or sleepState ~= "idle" then
        dbg("NPC %s is sleeping/waking; ignoring wander start", self.recordId)
        return
    end

    -- Clear any stale departure/arrival state (NPC may have just been re-enabled).
    departureState   = nil
    departureDoorPos = nil
    departureTimeout = 0
    arrivalWalkTarget = nil
    arrivalTimeout = 0
    transitionWalkTarget = nil
    transitionTimeout = 0
    isWalkingToTarget = false
    currentWalkTarget = nil
    walkTimeout = 0

    -- Defense: do NOT start a wander package if the NPC is sitting or walking
    -- to a seat. Schedule arrival wander can race with SittingGlobal's offer.
    local sittingState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
    if (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
            or sittingState == "walking_to_seat" then
        dbg("NPC %s is seating/sitting; deferring wander start", self.recordId)
        return
    end

    local pkg = nil
    local hasExplicitParams = data and (data.distance ~= nil or data.duration ~= nil or data.idle ~= nil)

    syncCanonicalNativeHomeFromStore()
    
    -- Determine which cell we're in relative to native home.
    -- If nativeHome hasn't been captured yet (script restart), load from store.
    local inNativeCell = false
    pcall(function()
        local home = nativeHome or loadStoredNativeHome()
        inNativeCell = home and home.cellName
            and self.cell and self.cell.name == home.cellName
    end)
    
    if hasExplicitParams then
        -- Caller provided explicit wander params — use them directly.
        pkg = {
            type = 'Wander',
            distance = data.distance,
            duration = data.duration or 0,
            idle = data.idle or { min = 2, max = 5 }
        }
    elseif inNativeCell then
        -- In native cell: always use persisted/native wander (or stay idle).
        pkg = resolveNativeWanderPackage()
    else
        -- In foreign cell: use what the NPC was doing before we touched them.
        pkg = makeDefaultForeignWander()
    end
    
    if not pkg then
        dbg("NPC %s has no wander source for this cell; staying idle.", self.recordId)
        transitionTo("idle", data)
        return
    end
    clearTargetedTravel()
    ai.startPackage(pkg)
    dbg("Starting Wander package for %s", self.recordId)
    local active = ai.getActivePackage()
    if active then
        dbg("Active Package: Type=%s, Dist=%s", active.type, tostring(active.distance))
    else
        dbg("Active Package: None (Failed to start?)")
    end
    transitionTo("idle", data)
end

local function onReturnHome(data)
    if not preActivityPosition then return end
    dbg("Returning Home for %s", self.recordId)

    ai.removePackages('Wander')

    -- Use Travel package to return to pre-activity position
    ai.startPackage({
        type = 'Travel',
        destPosition = preActivityPosition,
        cancelIfStuck = true
    })
    armTargetedTravel(preActivityPosition, "activity_return_home", 50)
end

local function onStopWander(data)
    -- Remove ALL packages of type Wander? Or just the one we added?
    -- ai.removePackages('Wander') removes all wander packages.
    -- This might be intrusive if they had a default wander package.
    -- But for now, we assume we want to clear the deck for the activity.
    ai.removePackages('Wander')
    
    -- If stop is called, usually it's for an activity. 
    -- If we want them to return home AFTER wandering but NOT for an activity...
    -- The user asked "upon ending wander they return".
    -- "Ending wander" implies either timeout or manual stop.
    -- ActivityManager sends StopWander when assigning activity.
    -- If assigning activity, we want them to do the activity (maybe at current spot?).
    -- If they wander then stop, maybe they should go home?
    -- Let's make "Return Home" an explicit command from ActivityManager if deemed necessary.
    -- Or trigger it here if no activity is starting?
    -- For now, I'll just add the handler and update ActivityManager to call it when stopping wander?
    -- Wait, if they stop wandering to do an activity, they should stay there or go home?
    -- User said: "upon ending wander they return to their original location"
    -- If they stop to Sweep, they sweep at current location (usually).
    -- If they stop to Return Home, they walk back.
    -- I will allow ActivityManager to call PC_ReturnHome.
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = onInactive,
        onActivated = function(activator)
            if SleepLogic.isSleeping() then
                -- NPC is asleep — wake them first, then open dialogue once standing.
                core.sendGlobalEvent("PC_WakeForDialogue", { npc = self.object, activator = activator })
                return
            end
        end,
    },
    eventHandlers = {
        -- PC_SaveBehavior: external systems (SittingGlobal, SleepManager, etc.)
        -- MUST call this BEFORE sending StartAIPackage or otherwise touching
        -- this NPC's AI.  Captures pre-intervention position and wander package
        -- so restoration later uses the correct baseline.
        PC_SaveBehavior = function(data)
            saveBehaviorForReturn("PC_SaveBehavior", data)
        end,

        StartAIPackage = function(data)
            if not data or not data.type then return end

            local pkg = { type = data.type }
            if data.destPosition then pkg.destPosition = data.destPosition end
            if data.distance ~= nil then pkg.distance = data.distance end
            if data.duration ~= nil then pkg.duration = data.duration end
            if data.idle ~= nil then pkg.idle = data.idle end
            if data.isRepeat ~= nil then pkg.isRepeat = data.isRepeat end
            if data.cancelIfStuck ~= nil then pkg.cancelIfStuck = data.cancelIfStuck end

            if pkg.type == "Travel" then
                pcall(function() ai.removePackages("Travel") end)
            end

            local ok, err = pcall(function()
                ai.startPackage(pkg)
            end)
            if not ok then
                dbg("StartAIPackage failed for %s type=%s err=%s", self.recordId, tostring(pkg.type), tostring(err))
                return
            end

            local active = nil
            pcall(function() active = ai.getActivePackage() end)
            dbg("StartAIPackage applied for %s type=%s active=%s",
                self.recordId, tostring(pkg.type), tostring(active and active.type or "nil"))
            if pkg.type == "Travel" and pkg.destPosition then
                local sState = SittingLogic and SittingLogic.getState and SittingLogic.getState() or nil
                local slState = SleepLogic and SleepLogic.getState and SleepLogic.getState() or nil
                local label = data.travelLabel or "external_travel"
                if sState == "walking_to_seat" then
                    label = "walking_to_seat"
                elseif slState == "walking_to_bed" then
                    label = "walking_to_bed"
                end
                armTargetedTravel(pkg.destPosition, label, data.stopDistance or 50)
            elseif pkg.type ~= "Travel" then
                clearTargetedTravel()
            end
        end,
        
        PC_WalkTo = onWalkTo,
        PC_Return = onReturn,
        PC_Stop = onStop,
        PC_Face = onFace,
        PC_TargetedTravelNudgeResult = function(data)
            if travelUnstuck then travelUnstuck.onNudgeResult(data or {}) end
        end,
        PC_StartConversation = function(data)
            if sm:is("hostile") or NPCState.isHostile(self.id) or isRuntimeHostileNow() then
                dbg("NPC %s REJECT conversation (runtime hostile)", self.recordId)
                rejectConversationForHostility("hostile")
                return
            end
            if isCompanionOrFollower(self.object) then
                dbg("NPC %s REJECT conversation (companion/follower)", self.recordId)
                return
            end
            if Blacklist.isHostileByDefault(self.object) then
                dbg("NPC %s REJECT conversation (hostile by default)", self.recordId)
                return
            end
            if SittingLogic and SittingLogic.getState and SittingLogic.getState() == "walking_to_seat" then
                dbg("NPC %s REJECT conversation (walking_to_seat)", self.recordId)
                return
            end
            if isSleepTransitionActive() then
                dbg("NPC %s REJECT conversation (sleep transition, sleepState=%s globalState=%s)",
                    self.recordId,
                    tostring(SleepLogic and SleepLogic.getState and SleepLogic.getState()),
                    tostring(NPCState.get(self.id)))
                return
            end
            if scheduleControlled or sm:is("departing") or sm:is("transitioning")
                    or sm:is("arriving") or sm:is("returning") then
                dbg("NPC %s REJECT conversation (schedule relocation, state=%s)", self.recordId, sm:get())
                return
            end
            if NPCState.isInTransit(self.object.id) then
                dbg("NPC %s REJECT conversation (in transit, state=%s)", self.recordId, NPCState.get(self.object.id))
                return
            end
            -- A moving conversation may start while this actor is still inside
            -- the PC_WalkTo travel state; allow that specific local transition.
            local localState = sm:get()
            local canConverseLocally = localState == "idle"
                or localState == "sitting"
                or localState == "conversation"
                or localState == "activity"
            if not canConverseLocally and not sm:is("walking") then
                dbg("NPC %s REJECT conversation (state=%s)", self.recordId, localState)
                return
            end
            if sm:is("walking") and not currentWalkIsConversation then
                dbg("NPC %s REJECT conversation (non-conversation walk)", self.recordId)
                return
            end
            saveBehaviorForReturn("PC_StartConversation", { reason = "conversation" })
            transitionTo("conversation", data)
        end,
        PC_RestoreHello = onRestoreHello,
        PC_ActivateBy = function(data)
            if data.activator then
                local ok, err = pcall(function() self:activateBy(data.activator) end)
                if not ok then
                    print(string.format("[npc.lua] activateBy failed: %s", tostring(err)))
                end
            end
        end,
        PC_Say = onSay,
        PC_StopVoice = onStopVoice,
        PC_PlayConversationAnimation = onPlayConversationAnimation,
        
        PC_TestUnequip = function(data)
            dbg("'O' Pressed: Stopping Activity")
            stopActivity()
        end,

        PropManager_EquipConfirm = function(data)
            if PropManager and PropManager.onEquipConfirm then
                PropManager.onEquipConfirm(data)
                
                -- Dynamic Animation Trigger
                if currentActivity then
                    local act = ActivityLibrary[currentActivity]
                    if act and act.props then
                        -- Check if this prop is part of the activity
                        local isRelevant = false
                        for _, p in ipairs(act.props) do
                             if p == data.propId then isRelevant = true break end
                        end
                        
                        if isRelevant then
                             -- Check if this is a sequence-based activity
                             if activitySequence and sequenceStep > 0 then
                                 dbg("Prop %s equipped for sequence activity %s. Starting sequence.", data.propId, currentActivity)
                                 executeSequenceStep()
                             else
                                 -- Non-sequence path: play animation directly
                                 local anim = require('openmw.animation')
                                 local I = require('openmw.interfaces')
                                 
                                 dbg("Prop %s confirmed for Activity %s. Playing '%s'.", data.propId, currentActivity, act.anim)
                                 
                                 local mask = act.mask or 14
                                 -- Check if sitting (Procedural OR check animation)
                                 local proceduralSit = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
                                 
                                 -- Vanilla check for mask enforcement (One-off check)
                                 local checkVanilla = false
                                 if not proceduralSit then
                                     local anim = require('openmw.animation')
                                     local ok, res = pcall(function()
                                         return anim.isPlaying(self, "sdpvasitting6")
                                             or anim.isPlaying(self, "pcdbssit5")
                                             or anim.isPlaying(self, "dbssit5")
                                             or anim.isPlaying(self, "dbssit6")
                                             or anim.isPlaying(self, "sitidle1")
                                             or anim.isPlaying(self, "IdleSit")
                                             or anim.isPlaying(self, "ChairSit01")
                                     end)
                                     if ok and res then checkVanilla = true end
                                 end
                                 
                                 if proceduralSit or checkVanilla then
                                     mask = 14 -- Force Upper Body if Sitting
                                     dbg("NPC is sitting (Force Upper Body Mask 14).")
                                 end
                                 
                                 local config = { 
                                     blendMask = mask, 
                                     priority = act.priority or 13, -- anim.PRIORITY.Scripted
                                     loops = (act.loops ~= false) and 999 or 1, 
                                     forceLoop = (act.loops ~= false)
                                 }
                                 
                                 -- Protect against "disabled object" errors if NPC state changes rapidly
                                 local ok, err = pcall(function()
                                    I.AnimationController.playBlendedAnimation(act.anim, config)
                                 end)
                                 if not ok then
                                    dbg("Warning: Failed to play animation (Actor might be disabled): %s", tostring(err))
                                 else
                                    activityAnimStarted = true -- Mark as running so updater can watch for end
                                 end
                             end
                        end
                    end
                end
            end
        end,
        
        -- Sitting Logic Handlers
        PC_ConsiderStools     = function(data)
            if sm:is("hostile") then
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object, usable = false, reason = "hostile",
                })
                return
            end
            if isCompanionOrFollower(self.object) then
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object, usable = false, reason = "companion_or_follower",
                })
                return
            end
            if Blacklist.isHostileByDefault(self.object) then
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object, usable = false, reason = "hostile_by_default",
                })
                return
            end
            if SleepLogic and SleepLogic.getState and SleepLogic.getState() ~= "idle" then
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object, usable = false, reason = "sleep_state_not_idle",
                })
                return
            end
            if not NPCState.canSit(self.id) then
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object, usable = false, reason = "npc_state_cannot_sit",
                })
                return
            end
            preActivityPosition = nil
            preActivityRotation = nil
            suppressHello()
            SittingLogic.onConsiderStools(data)
            if SittingLogic.getState and SittingLogic.getState() ~= "walking_to_seat" then
                restoreHello()
            end
        end,
        PC_ConsiderStool      = function(data)
            print(string.format("[npc.lua] PC_ConsiderStool for %s state=%s", self.recordId, sm:get()))
            if isCompanionOrFollower(self.object) then
                print(string.format("[npc.lua] REJECT stool for %s (companion/follower)", self.recordId))
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object,
                    stool = data and data.stool or nil,
                    usable = false,
                })
                return
            end
            if Blacklist.isHostileByDefault(self.object) then
                print(string.format("[npc.lua] REJECT stool for %s (hostile by default)", self.recordId))
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object,
                    stool = data and data.stool or nil,
                    usable = false,
                })
                return
            end
            -- Defense: reject stool offers while SleepLogic is already processing
            -- a bed (walking_to_bed, laying_down, sleeping, waking_up) so the
            -- global SittingGlobal race-condition can't drag a sleeper out of bed.
            if SleepLogic and SleepLogic.getState and SleepLogic.getState() ~= "idle" then
                print(string.format("[npc.lua] REJECT stool for %s (sleepLogic state=%s)",
                    self.recordId, tostring(SleepLogic.getState())))
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object,
                    stool = data and data.stool or nil,
                    usable = false,
                })
                return
            end
            -- Defense: reject stool offers while walking or in schedule transit.
            -- A stool offered mid-arrival will conflict with PC_StartWander sent on arrival.
            if not NPCState.canSit(self.id) then
                print(string.format("[npc.lua] REJECT stool for %s (state=%s)", self.recordId, sm:get()))
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object,
                    stool = data and data.stool or nil,
                    usable = false,
                })
                return
            end
            preActivityPosition = nil
            preActivityRotation = nil
            suppressHello()
            SittingLogic.onConsiderTheStool(data)
            if SittingLogic.getState and SittingLogic.getState() ~= "walking_to_seat" then
                restoreHello()
            end
        end,
        PC_SitDownPlease      = function(data)
            SittingLogic.onSitDownPlease(data)
            restoreHello()
        end,
        PC_StandUpPlease      = function(data)
            SittingLogic.onStandUpPlease(data)
            -- Don't restore hello if a walk is queued after stand-up (conversation)
            -- or if we're in the middle of a scheduled departure teardown.
            if pendingWalkAfterStand or isWaitingForStandUp or sm:is("departing") then
                return
            end
            restoreHello()
        end,
        PC_VerifySitState     = SittingLogic.onVerifySitState,
        PC_RecheckStoolFacing = SittingLogic.onRecheckStoolFacing,
        PC_CancelTravelToSeat = function(data)
            clearTargetedTravel()
            SittingLogic.onCancelTravelToSeat(data)
            if SittingLogic.getState and SittingLogic.getState() ~= "walking_to_seat"
                    and not (SittingLogic.isSitting and SittingLogic.isSitting()) then
                transitionTo("idle")
            end
            if not (data and data.keepHelloSuppressed) then
                restoreHello()
            end
        end,
        Died                  = SittingLogic.onDied,

        -- Sleep Logic Handlers
        PC_ConsiderBeds        = function(data)
            if sm:is("hostile") then
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object, bed = nil, usable = false,
                })
                return
            end
            if isCompanionOrFollower(self.object) then
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object, bed = nil, usable = false,
                })
                return
            end
            if Blacklist.isHostileByDefault(self.object) then
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object, bed = nil, usable = false,
                })
                return
            end
            if not NPCState.canSleep(self.id) then
                print(string.format("[npc.lua] REJECT beds for %s (state=%s)", self.recordId, NPCState.get(self.id)))
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object, bed = nil, usable = false,
                })
                return
            end
            stopActivity()
            suppressHello()
            SleepLogic.onConsiderBeds(data)
            if SleepLogic.getState and SleepLogic.getState() ~= "walking_to_bed" then
                restoreHello()
            end
        end,
        PC_ConsiderBed         = function(data)
            if sm:is("hostile") then
                print(string.format("[npc.lua] REJECT bed for %s (hostile)", self.recordId))
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object,
                    bed = data and data.bed or nil,
                    usable = false,
                })
                return
            end
            if isCompanionOrFollower(self.object) then
                print(string.format("[npc.lua] REJECT bed for %s (companion/follower)", self.recordId))
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object,
                    bed = data and data.bed or nil,
                    usable = false,
                })
                return
            end
            if Blacklist.isHostileByDefault(self.object) then
                print(string.format("[npc.lua] REJECT bed for %s (hostile by default)", self.recordId))
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object,
                    bed = data and data.bed or nil,
                    usable = false,
                })
                return
            end
            if not NPCState.canSleep(self.id) then
                print(string.format("[npc.lua] REJECT bed for %s (state=%s)", self.recordId, sm:get()))
                core.sendGlobalEvent("PC_BedCheckResult", {
                    npc = self.object,
                    bed = data and data.bed or nil,
                    usable = false,
                })
                return
            end
            stopActivity()  -- unequip any held props before committing to sleep
            suppressHello() -- npc.lua owns hello suppression (merged from SleepLogic)
            SleepLogic.onConsiderBed(data)
            if SleepLogic.getState and SleepLogic.getState() ~= "walking_to_bed" then
                restoreHello()
            end
        end,
        PC_SleepPlease = function(data)
            lookAtTarget = nil
            self.controls.yawChange = 0
            pcall(function() ai.removePackages("Travel") end)
            SleepLogic.onSleepPlease(data)
            transitionTo("sleeping")
        end,
        PC_TeleportSleepPlease = function(data)
            lookAtTarget = nil
            self.controls.yawChange = 0
            pcall(function() ai.removePackages("Travel") end)
            suppressHello() -- npc.lua owns hello suppression (merged from SleepLogic)
            SleepLogic.onTeleportSleepPlease(data)
            transitionTo("sleeping")
        end,
        PC_WakeUpPlease = function(data)
            SleepLogic.onWakeUpPlease(data)
            restoreHello()  -- npc.lua owns hello restoration (merged from SleepLogic)
            if data and data.skipLerp then
                transitionTo("idle")
            else
                transitionTo("waking")
            end
        end,
        PC_CancelTravelToBed   = function(data)
            clearTargetedTravel()
            SleepLogic.onCancelTravelToBed(data)
            restoreHello()
        end,
        
        -- Activity Manager Handlers
        PC_StartActivity = function(data)
            if sm:is("hostile") then
                dbg("NPC %s REJECT activity (hostile)", self.recordId)
                return
            end
            if isCompanionOrFollower(self.object) then
                dbg("NPC %s REJECT activity (companion/follower)", self.recordId)
                return
            end
            if Blacklist.isHostileByDefault(self.object) then
                dbg("NPC %s REJECT activity (hostile by default)", self.recordId)
                return
            end
            -- Local guard: SittingLogic transitions to walking_to_seat synchronously,
            -- but PC_StateChanged to global is async (one frame delay). This guard
            -- catches the window where global NPCState still shows 'idle'.
            if SittingLogic and SittingLogic.getState and SittingLogic.getState() == "walking_to_seat" then
                dbg("NPC %s REJECT activity (SittingLogic walking_to_seat)", self.recordId)
                return
            end
            local act = data and data.activityId and ActivityLibrary[data.activityId] or nil
            local reqPosture = act and normalizePosture(act.posture) or "both"
            if reqPosture == "stand" and SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting() then
                dbg("NPC %s REJECT stand-only activity while sitting", self.recordId)
                return
            end
            local globalState = NPCState.get(self.id)
            if not (NPCState.canActivity(self.id) or globalState == "pending_activity" or globalState == "activity") then
                dbg("NPC %s REJECT activity (localState=%s globalState=%s)", self.recordId, sm:get(), tostring(globalState))
                return
            end
            if startActivity(data.activityId, { minLoops = data.minLoops, maxLoops = data.maxLoops }) then
                transitionTo("activity", data)
            end
        end,
        PC_StopActivity = function(data)
            local silent = false
            local forceClearAll = false
            local instant = false
            if type(data) == "table" then
                silent = data.silent
                forceClearAll = data.forceClearAll
                instant = data.instant
            end
            stopActivity(silent, forceClearAll)

            if instant and preActivityPosition then
                local pos = preActivityPosition
                local rot = preActivityRotation
                preActivityPosition = nil
                preActivityRotation = nil
                ai.removePackages("Travel")
                local cellName = ""
                pcall(function() cellName = self.cell and self.cell.name or "" end)
                if cellName ~= "" then
                    Utils.tryTeleport(self.object, cellName, pos, { rotation = rot or self.rotation })
                end
                restoreWanderForCurrentCell()
            end

            -- Only transition to idle and notify global if this is a genuine activity stop.
            -- silent=true means the caller (e.g. ConversationManager) is managing state itself.
            if not silent then
                transitionTo("idle")
                core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "activity_ended" })
            end
        end,
        
        -- ASYNC CHECK HANDLER
        PC_QueryPosture = function(data)
            -- Check if sitting
             local proceduralSit = (SittingLogic and SittingLogic.isSitting and SittingLogic.isSitting())
             local vanillaSit = false
             
             if not proceduralSit then
                 local anim = require('openmw.animation')
                 local ok, res = pcall(function() 
                     return anim.isPlaying(self, "sdpvasitting6")
                         or anim.isPlaying(self, "pcdbssit5")
                         or anim.isPlaying(self, "dbssit5")
                         or anim.isPlaying(self, "dbssit6")
                         or anim.isPlaying(self, "sitidle1")
                         or anim.isPlaying(self, "IdleSit")
                         or anim.isPlaying(self, "ChairSit01")
                 end)
                 if ok and res then vanillaSit = true end
             end
             
             core.sendGlobalEvent("PC_ReturnPosture", { 
                 npc = self, 
                 isSitting = (proceduralSit or vanillaSit)
             })
        end,
        
        -- Wandering Handlers
        PC_StartWander = onStartWander,
        PC_StopWander = onStopWander,
        PC_ReturnHome = onReturnHome,

        -- PC_ClearForSchedule: the schedule system is about to disable/teleport
        -- this NPC.  Sets scheduleControlled so onInactive won't fight the
        -- displacement.  Clears activity state but preserves originalPosition.
        PC_ClearForSchedule = function(_data)
            scheduleControlled = true
            -- Clear smooth-transition state so it doesn't restart after re-enable.
            departureState   = nil
            departureDoorPos = nil
            departureTimeout = 0
            arrivalWalkTarget = nil
            arrivalTimeout = 0
            local active = ai.getActivePackage()
            if active and active.type == "Wander" then
                savedWanderPackage = copyWanderPackage(active)
                local inNativeCell = false
                pcall(function()
                    inNativeCell = nativeHome and nativeHome.cellName
                        and self.cell and self.cell.name == nativeHome.cellName
                end)
                if inNativeCell then
                    nativeHome.wander = savedWanderPackage
                    persistNativeWander(savedWanderPackage)
                    SleepLogic.setNativeHome(nativeHome)
                end
            end

            -- Behavior Restoration: restore native wander if no activity is starting
            if not currentActivity and nativeHome and nativeHome.wander then
                ai.startPackage(nativeHome.wander)
            end

            if currentActivity or preActivityPosition then
                dbg("%s: schedule takeover, clearing activity state", self.recordId)
                stopActivity()
                preActivityPosition = nil
                preActivityRotation = nil
            end
            transitionTo("idle")
        end,

        -- === Smooth Departure (Phase A) ===

        -- PC_PrepareForDeparture: sent by Relocator.dispatchSmooth / queueReturnSmooth
        -- when the player is watching. Sets up the teardown -> walk-to-door sequence.
        PC_PrepareForDeparture = function(data)
            if sm:is("departing") or sm:is("transitioning") then
                dbg("NPC %s REJECT departure (already in transit, state=%s)", self.recordId, sm:get())
                return
            end
            if sm:is("arriving") or sm:is("returning") then
                dbg("NPC %s interrupting %s for new schedule departure", self.recordId, sm:get())
                arrivalWalkTarget = nil
                arrivalTimeout = 0
                returnTargetPos = nil
                returnTargetRot = nil
                isWalkingToTarget = false
                currentWalkTarget = nil
                walkTimeout = 0
                pcall(function() ai.removePackages("Travel") end)
                restoreHello()
            end
            -- scheduleControlled prevents onInactive from fighting the relocation.
            scheduleControlled = true
            suppressHello()
            currentWalkIsConversation = false
            pendingWalkAfterStand = nil
            isWaitingForConversationStandUp = false
            isHolding = false
            holdPosition = nil
            lookAtTarget = nil
            returnTargetPos = nil
            returnTargetRot = nil

            departureState   = "teardown"
            departureDoorPos = data and data.doorPos or nil
            departureTimeout = data and data.timeout or 15
            departureTravelRetries = 0

            -- Kick off teardown immediately so the idle-check in onUpdate can
            -- start the door-walk as soon as the NPC is truly free.
            if SittingLogic and SittingLogic.onStandUpPlease and SittingLogic.isSitting() then
                isWaitingForStandUp = true
                core.sendGlobalEvent("PC_ForceStandForDeparture", { npc = self.object })
                -- Use the proper hook for a smooth teardown that notifies the global script
                pcall(function() SittingLogic.requestStand('relocation') end)
            end
            if SleepLogic and SleepLogic.onWakeUpPlease and SleepLogic.isSleeping() then
                isWaitingForWakeUp = true
                pcall(SleepLogic.onWakeUpPlease, {})
            end
            stopActivity(true, false)  -- silent, not force-clear-all
            core.sendGlobalEvent("PC_ActivityFinished", { npc = self.object })
            preActivityPosition = nil
            preActivityRotation = nil
            transitionTo("departing", data)
        end,

        -- PC_DepartureAbort: sent by the global timeout path just before the NPC
        -- is disabled, so the local state machine doesn't restart on re-enable.
        PC_DepartureAbort = function(_data)
            departureState   = nil
            departureDoorPos = nil
            departureTimeout = 0
            departureTravelRetries = 0
            arrivalWalkTarget = nil
            arrivalTimeout = 0
            transitionWalkTarget = nil
            transitionTimeout = 0
            isWalkingToTarget = false
            currentWalkTarget = nil
            walkTimeout = 0
            currentWalkIsConversation = false
            clearTargetedTravel()
            restoreHello()
            transitionTo("idle")
        end,

        -- === Smooth Arrival (Phase B) ===

        -- PC_ArrivalWalk: sent by Relocator.materialiseNpc when the NPC has been
        -- teleported to the door entrance inside the destination cell. The NPC walks
        -- to slotPos; onUpdate fires PC_ArrivalComplete when they arrive.
        PC_ArrivalWalk = function(data)
            local targetPos = data and (data.slotPos or data.arriveTarget)
            if not targetPos then return end
            scheduleControlled = true
            preActivityPosition = nil
            preActivityRotation = nil
            syncCanonicalNativeHomeFromStore()
            departureState   = nil
            departureDoorPos = nil
            departureTimeout = 0
            arrivalWalkTarget = targetPos
            arrivalTimeout = ARRIVAL_TIMEOUT
            suppressHello()
            clearTargetedTravel()
            pcall(function() ai.removePackages("Wander") end)
            pcall(function() ai.removePackages("Travel") end)
            pcall(function()
                ai.startPackage({ type = "Travel", destPosition = targetPos })
            end)
            transitionTo("arriving", { slotPos = targetPos })
            core.sendGlobalEvent("PC_StateChanged", {
                npcId = self.id,
                state = "arriving",
                prevState = NPCState.get(self.id),
            })
        end,

        -- PC_TransitionWalk: sent by Relocator.onDepartureReachedDoor during cross-exterior
        -- transitions. The NPC walks from source exterior door to destination exterior door.
        PC_TransitionWalk = function(data)
            local targetPos = data and data.doorPos
            if not targetPos then return end
            scheduleControlled = true
            -- Clear any stale departure/arrival state.
            departureState   = nil
            departureDoorPos = nil
            departureTimeout = 0
            arrivalWalkTarget = nil
            transitionWalkTarget = targetPos
            transitionTimeout = TRANSITION_TIMEOUT
            suppressHello()
            clearTargetedTravel()
            pcall(function() ai.removePackages("Travel") end)
            pcall(function()
                ai.startPackage({ type = "Travel", destPosition = targetPos })
            end)
            transitionTo("transitioning", { target = targetPos })
        end,

        -- PC_ScheduleWalkTo: legacy handler, kept for schedule_npc.lua walk mode.
        -- Also sets scheduleControlled to prevent onInactive interference.
        PC_ScheduleWalkTo = function(_data)
            scheduleControlled = true
            if currentActivity or preActivityPosition then
                stopActivity()
                preActivityPosition = nil
                preActivityRotation = nil
            end
        end,

        -- Schedule arrival handlers
        -- PC_ScheduleTryFindSeat: sent by TavernEvening.onArrived when an NPC
        -- arrives at a tavern.  Tries to assign a seat via SittingLogic.
        PC_ScheduleTryFindSeat = function(data)
            dbg("%s: PC_ScheduleTryFindSeat received", self.recordId)
            if SittingLogic and SittingLogic.onConsiderTheStool then
                suppressHello()
                pcall(SittingLogic.onConsiderTheStool, data or {})
                if SittingLogic.getState and SittingLogic.getState() ~= "walking_to_seat" then
                    restoreHello()
                end
            end
        end,

        PC_StandUpFinished = function(_data)
            dbg("%s: PC_StandUpFinished received", self.recordId)
            if pendingWalkAfterStand then
                local walk = pendingWalkAfterStand
                pendingWalkAfterStand = nil
                isWaitingForConversationStandUp = false
                isWaitingForStandUp = false

                ai.startPackage({
                    type = "Travel",
                    destPosition = walk.target,
                })
                isWalkingToTarget = true
                currentWalkTarget = walk.target
                currentStopDist = walk.stopDistance or 50
                walkTimeout = WALK_TIMEOUT
                currentWalkIsConversation = true
                armTargetedTravel(currentWalkTarget, "conversation_walk_after_stand", currentStopDist)
                transitionTo("walking", { target = walk.target, stopDistance = currentStopDist })
                return
            end

            local wasWaitingForDeparture = isWaitingForStandUp or sm:is("departing") or NPCState.get(self.id) == "departing"
            isWaitingForStandUp = false
            isWaitingForConversationStandUp = false
            if not wasWaitingForDeparture then
                core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "stood_up" })
            end
        end,

        PC_WakeUpFinished = function(_data)
            dbg("%s: PC_WakeUpFinished received", self.recordId)
            isWaitingForWakeUp = false
            if SleepLogic and SleepLogic.onWakeUpFinished then
                pcall(SleepLogic.onWakeUpFinished)
            end
            if wasHostile or isRuntimeHostileNow() or NPCState.isHostile(self.id) then
                transitionTo("hostile")
            else
                transitionTo("idle")
                core.sendGlobalEvent("PC_NpcStateReleased", { npc = self.object, context = "woken" })
            end
        end,

        -- PC_CombatStarted: actual combat only. Wakes sleepers via SleepManager.
        PC_CombatStarted = function(_data)
            dbg("%s: PC_CombatStarted received — clearing movement state", self.recordId)
            -- Cancel all movement flags
            isWalkingToTarget = false
            currentWalkTarget = nil
            walkTimeout = 0
            departureState   = nil
            departureDoorPos = nil
            departureTimeout = 0
            arrivalWalkTarget = nil
            arrivalTimeout = 0
            transitionWalkTarget = nil
            transitionTimeout = 0
            returnTargetPos = nil
            returnTargetRot = nil
            preActivityPosition = nil
            preActivityRotation = nil
            clearTargetedTravel()
            -- Remove travel packages
            pcall(function() ai.removePackages("Travel") end)
            restoreHello()
            if wasHostile or isRuntimeHostileNow() or NPCState.isHostile(self.id) then
                transitionTo("hostile")
            else
                transitionTo("idle")
            end
        end,

        -- PC_ClearMovementState: non-combat state clear (teleports, schedule preemption).
        -- Does the same local cleanup as PC_CombatStarted but does NOT wake sleepers.
        PC_ClearMovementState = function(data)
            if data and data.actor then
                local ok, actorId = pcall(function() return data.actor.id end)
                if ok and actorId and actorId ~= self.object.id then return end
            end
            local preserveSchedule = data and data.preserveSchedule
            dbg("%s: PC_ClearMovementState received — clearing movement state", self.recordId)
            isWalkingToTarget = false
            currentWalkTarget = nil
            walkTimeout = 0
            isHolding = false
            holdPosition = nil
            lookAtTarget = nil
            returnTargetPos = nil
            returnTargetRot = nil
            preActivityPosition = nil
            preActivityRotation = nil
            if not preserveSchedule then
                departureState   = nil
                departureDoorPos = nil
                departureTimeout = 0
                departureTravelRetries = 0
                arrivalWalkTarget = nil
                arrivalTimeout = 0
                transitionWalkTarget = nil
                transitionTimeout = 0
                clearTargetedTravel()
                pcall(function() ai.removePackages("Travel") end)
                restoreHello()
                transitionTo("idle")
            end
        end,
    }
}
