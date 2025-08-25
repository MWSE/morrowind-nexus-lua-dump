local config = require("StormAtronach.SO.config")
local interop = require("StormAtronach.SO.interop")

local log = mwse.Logger.new({
	name = "Stealth Overhaul",
	level = mwse.logLevel.debug,
})

local investigation = {}

-- The following is a refactoring of Celediel's More Attentive Guards sneak module
-- All credit for the original work goes to Celediel. Thanks! :)

-- Variables
-- I think the only one follower at a time approach from Celediel makes sense, so let's keep it

-- From Celediel 
local function generateIdles()
    local idles = {}
    -- idles[1] = 0 -- ? idle 1 is not used?
    for i = 1, 4 do idles[i] = math.random(0, 60) end
    idles[5] = 0 -- ? Idle6: Rubbing hands together and showing wares
    for i = 6, 8 do idles[i] = math.random(0, 60) end
    return idles
end


---@param npcRef tes3reference
local function doChecks(npcRef)
    -- Let's check if the npcRef has a mobile
    local mob = npcRef.mobile
    if not mob then log:debug("NPC %s does not have a mobile", npcRef.id or "none")return true end
    -- Let's check if it can do stuff
    if mob.isKnockedDown or mob.isHitStunned or
    mob.isParalyzed or mob.isDead or mob.inCombat
    then log:debug("NPC can't continue") return true end

    -- Ok, if all good:
    return false
end


---@param npcRef tes3reference
investigation.startWander = function(npcRef)
        -- Set the wander range
        if not (npcRef and npcRef.mobile) then log:debug("No ref or mobile in StartWander") return end

        local wanderRange = config.wanderRangeInterior or 500
        if npcRef.mobile.cell.isOrBehavesAsExterior then
            wanderRange = config.wanderRangeExterior or 2000
        end
        -- Regenerates the idles
        local idles = generateIdles()

        
        tes3.setAIWander({ reference = npcRef, range = wanderRange, reset = true, idles = idles })
end

---@param e mwseTimerCallbackData
local function returnToOriginalPosition(e)
    local data = e.timer.data
    if not data then log:debug("Payload for returnToOriginalPosition is missing") return end
    local npcRef = tes3.getReference(data.npcRef) or nil
    if not npcRef then log:debug("Reference does not exist in Return To Original Position") return end
    tes3.setAITravel({reference = npcRef, destination = data.originalPosition, reset = true})
end

-- Checks if we reach the destination
---@param e mwseTimerCallbackData
local function checkDestination(e)
    local data = e.timer.data
    if not data then log:debug("Timer data payload not present") e.timer:cancel() return end
    ---@type tes3reference
    local npcRef = tes3.getReference(data.npcRef)
    -- Check if this still exists
    if not (npcRef and npcRef.mobile) then
        log:debug("Reference no longer valid or mobile does not exist anymore")
        e.timer:cancel() return
    end
    -- Check if the mobile is in the same cell as the player. if not, reset the position
    if npcRef.mobile.cell ~= tes3.mobilePlayer.cell then
        log:debug("NPC not in the same cell. Returning to original position")
        -- The below concept is cursed. Let's just cancel the travel and let them wander around in the new position
        -- We select the original position 
        --local rePosition = data.originalPosition or npcRef.mobile.position
        --npcRef.mobile.position = rePosition
        investigation.startWander(npcRef)
    end
    -- Check if the AI package is still travel or if we have arrived and it is wander
    local npcAIPackage = npcRef.mobile.aiPlanner.currentPackageIndex
    local AITravel = npcAIPackage == tes3.aiPackage.travel
    local AIWander = npcAIPackage == tes3.aiPackage.wander
    if not (AITravel or AIWander) then
        log:debug("For some reason, NPC is not travelling or wandering anymore")
        e.timer:cancel() return
    end

    -- Check if the NPC can still travel:
    local cantContinue = doChecks(npcRef)
    if cantContinue then
        log:debug("For some reason, NPC can't continue travel")
        e.timer:cancel()
        investigation.startWander(npcRef)
        return
    end

    -- Ok, for the actual check
    -- Last minute nil-checking
    if not (npcRef and npcRef.mobile and npcRef.mobile.position) then log:debug("Nil checking failed before restarting the wander") return end
    local destination = data.destination or npcRef.mobile.position:copy()
    local remainingDistance =  npcRef.mobile.position:distance(destination)

    -- Are we there yet?
    if remainingDistance <= 5 or AIWander then
        -- If we arrived, cancel the timer
        e.timer:cancel()
        -- Start wandering around
        investigation.startWander(npcRef)
        -- Let's not spend the whole day here:
        local investigationTime = math.random(3,8)

        log:debug("Attempting to go back. NPC %s,",npcRef.id)
    
        -- Timer logic to start return to original position
        timer.register("SA_SO_startTripBack", returnToOriginalPosition)
        timer.start({
            type = timer.simulate,
            duration = investigationTime,
            callback = "SA_SO_startTripBack",
            iterations = 1,
            persist = true,
            data = {npcRef = npcRef.id, originalPosition = data.originalPosition},
            })
        
    end
end


-- NPC gets suspicious and starts travelling to the position
---@param npcRef tes3reference
---@param destination tes3vector3
investigation.startTravel = function(npcRef, destination)
    -- Check that the inputs are there and not nil
    if (not npcRef) or (not destination) then log:debug("Investigation start: Missing npcRef %s, missing destination %s", (not npcRef), (not destination)) return end
    local cantContinue = doChecks(npcRef)
    if cantContinue then log:debug("NPC is doing other stuff") return end

    local aux = {}
    aux.originalPosition = npcRef.position:copy()

    aux.distance    = npcRef.position:distance(destination)
    aux.duration    = math.round(math.clamp(aux.distance/50,config.minTravelTime or 1, config.maxTravelTime or 15),0)
    -- If for some reason the duration is less than one, let's set it as 1
    if aux.duration < 1 then aux.duration = 1 end
    -- yallah! let's go, my dear npc:
    local npcRefSafe = tes3.makeSafeObjectHandle(npcRef)
    timer.delayOneFrame(function() 
        if not npcRefSafe:valid() then log:debug("NPC ref handle got invalidated") return end
        local npcRefSafeRetrieved = npcRefSafe:getObject()
        tes3.setAITravel({ reference = npcRefSafeRetrieved, destination = destination }) end)
log:debug("Attempting to start travel. NPC %s, duration %s",npcRef.id,aux.duration)
local message = string.format("Attempting to start travel. NPC %s, duration %s",npcRef.id,aux.duration)
-- tes3.messageBox(message) -- Debugging stuff
    timer.register("SA_SO_checkIfNPCArrived", checkDestination)
    timer.start({
        type        = timer.simulate,
        duration    = 1,
        callback    = "SA_SO_checkIfNPCArrived",
        iterations  = aux.duration,
        persist     = true,
        data        = {npcRef = npcRef.id, destination = destination, originalPosition = aux.originalPosition}
    })
    return aux
end


return investigation

