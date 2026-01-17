local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')

local MODNAME = "Pilferer"
local nextUpdate = 0
local UPDATE_INTERVAL = 0.1  -- faster updates for accurate tracking

local wasSaying = false
local saveData = {}

-- Greeting detection state
local speechStartTime = nil
local greetingCheckPending = false
local initialPosition = nil
local positionTrackStart = nil
local rotationTrackStart = nil  -- when to start monitoring rotation direction
local overshootWindowStart = nil  -- grace window when NPC switches rotation direction
local wasRotatingCorrectly = nil  -- track if NPC was rotating toward player last frame
local lastYaw = nil
local greetingFailed = false
local wrongWayAccum = 0  -- cumulative rotation away from player
local playerWasInRange = false

-- Constants from GMSTs
local iGreetDistanceMultiplier = core.getGMST("iGreetDistanceMultiplier")  -- default 6
local BOOSTED_HELLO = 150
local GREETING_DISTANCE = BOOSTED_HELLO * iGreetDistanceMultiplier  -- 1200 by default

local GREETING_CHECK_DURATION = 2.0
local FACING_CONE_DEG = 60
local POSITION_TOLERANCE = 30
local POSITION_TRACK_DELAY = 0.3  -- wait before tracking position
local ROTATION_GRACE_PERIOD = 0.3  -- wait before tracking rotation direction
local OVERSHOOT_WINDOW = 0.25  -- grace time when NPC switches from rotating toward to away (player might have moved)
local MIN_ROTATION_DEG = 0.2  -- minimum rotation to detect direction
local WRONG_WAY_THRESHOLD_DEG = 15  -- cumulative wrong-way rotation to fail

local DEG_TO_RAD = math.pi / 180
local FACING_CONE = FACING_CONE_DEG * DEG_TO_RAD
local MIN_ROTATION = MIN_ROTATION_DEG * DEG_TO_RAD
local WRONG_WAY_THRESHOLD = WRONG_WAY_THRESHOLD_DEG * DEG_TO_RAD

local function angleDiff(a, b)
    local diff = a - b
    while diff > math.pi do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    return diff
end

local function resetGreetingState()
    speechStartTime = nil
    greetingCheckPending = false
    initialPosition = nil
    positionTrackStart = nil
    rotationTrackStart = nil
    overshootWindowStart = nil
    wasRotatingCorrectly = nil
    lastYaw = nil
    greetingFailed = false
    wrongWayAccum = 0
    playerWasInRange = false
end

local function checkGreetingBehavior(now)
    local player = nearby.players[1]
    if not player then return false, "no player" end
    
    local toPlayer = player.position - self.position
    local distance = toPlayer:length()
    local inRange = distance <= GREETING_DISTANCE
    
    -- Track if player was ever in range
    if inRange then
        playerWasInRange = true
    end
    
    -- If player left greeting distance
    if not inRange then
        if playerWasInRange and not greetingFailed then
            return true, "player left greeting distance"
        else
            return false, "too far"
        end
    end
    
    -- Check NPC hasn't moved (after delay to let them finish their step)
    if not positionTrackStart then
        positionTrackStart = now
    elseif now - positionTrackStart > POSITION_TRACK_DELAY then
        if not initialPosition then
            initialPosition = self.position  -- record position after delay
        else
            local moved = (self.position - initialPosition):length()
            if moved > POSITION_TOLERANCE then
                greetingFailed = true
                return false, "NPC moved"
            end
        end
    end
    
    local currentYaw = self.rotation:getYaw()
    local angleToPlayer = math.atan2(toPlayer.x, toPlayer.y)
    local currentAngleDiff = angleDiff(currentYaw, angleToPlayer)
    local absAngleDiff = math.abs(currentAngleDiff)
    local isInCone = absAngleDiff < FACING_CONE
    
    -- Check if we're in overshoot window (started when NPC switched from rotating toward to away)
    local inOvershootWindow = overshootWindowStart and (now - overshootWindowStart < OVERSHOOT_WINDOW)
    
    -- Track rotation direction when outside cone (with grace period)
    if not isInCone then
        -- Start grace period when first going outside cone
        if not rotationTrackStart then
            rotationTrackStart = now
        end
        local trackingRotation = now - rotationTrackStart > ROTATION_GRACE_PERIOD
        
        if trackingRotation and lastYaw then
            local yawDelta = angleDiff(currentYaw, lastYaw)
            
            if math.abs(yawDelta) > MIN_ROTATION then
                -- Determine if this rotation moved toward or away from player
                -- currentAngleDiff > 0 means NPC should rotate negative (decrease yaw)
                -- currentAngleDiff < 0 means NPC should rotate positive (increase yaw)
                -- So "correct" rotation has opposite sign to currentAngleDiff
                local rotatingCorrectWay = (yawDelta > 0 and currentAngleDiff < 0) or 
                                            (yawDelta < 0 and currentAngleDiff > 0)
                
                if not rotatingCorrectWay then
                    -- Check if we just switched from correct to incorrect rotation
                    if wasRotatingCorrectly then
                        overshootWindowStart = now
                        inOvershootWindow = true
                    end
                    
                    -- Only penalize if not in overshoot window
                    if not inOvershootWindow then
                        wrongWayAccum = wrongWayAccum + math.abs(yawDelta)
                        if wrongWayAccum > WRONG_WAY_THRESHOLD then
                            greetingFailed = true
                            return false, "rotated away from player"
                        end
                    end
                end
                
                wasRotatingCorrectly = rotatingCorrectWay
            end
        end
    else
        -- Inside cone - reset grace period for next time
        rotationTrackStart = nil
        overshootWindowStart = nil
        wasRotatingCorrectly = nil
    end
    
    lastYaw = currentYaw
    
    if greetingFailed then
        return false, "previously failed"
    end
    
    -- Keep observing while player is in range
    return nil, "still checking"
end

local function onLoad(data)
    saveData = data or {}
    saveData.helloBoosted = saveData.helloBoosted or false
    saveData.originalHelloBase = saveData.originalHelloBase  -- can be nil
    
    -- Reapply modifier if we were boosted when saved
    if saveData.helloBoosted and saveData.originalHelloBase then
        local hello = types.Actor.stats.ai.hello(self)
        hello.modifier = BOOSTED_HELLO - saveData.originalHelloBase
        print(string.format("[%s] Restored hello boost on load (base %d)", MODNAME, saveData.originalHelloBase))
    end
end

local function onSave()
    return saveData
end

local function getName()
    return types.NPC.record(self).name or self.recordId
end

local function boostHello()
    if saveData.helloBoosted then return end
    
    -- Don't boost in exteriors or quasi-exteriors
    local cell = self.cell
    if cell and (cell.isExterior or cell:hasTag("QuasiExterior")) then
        return
    end
    
    local hello = types.Actor.stats.ai.hello(self)
    saveData.originalHelloBase = hello.base
    local modifier = BOOSTED_HELLO - hello.base
    hello.modifier = modifier
    saveData.helloBoosted = true
    print(string.format("[%s] %s: ready to greet (base %d + modifier %d = effective %d)", MODNAME, getName(), saveData.originalHelloBase, modifier, BOOSTED_HELLO))
end

local function resetHello()
    if not saveData.helloBoosted then return end
    
    local hello = types.Actor.stats.ai.hello(self)
    hello.modifier = 0
    saveData.helloBoosted = false
    print(string.format("[%s] %s: hello reset to base %d", MODNAME, getName(), saveData.originalHelloBase or hello.base))
end

local function onUpdate()
    local now = core.getSimulationTime()
	if not saveData.helloBoosted then return end
    --if now < nextUpdate then return end
    --nextUpdate = now + UPDATE_INTERVAL

    local isSaying = core.sound.isSayActive(self)
    
    -- When speech starts while boosted, start tracking
    if isSaying and not wasSaying then
        local name = getName()
        print(string.format("[%s] %s: started speaking (boosted=%s)", MODNAME, name, tostring(saveData.helloBoosted)))
        
        if saveData.helloBoosted then
            -- Only mute if far away
            local player = nearby.players[1]
            if player then
                local distance = (player.position - self.position):length()
                if distance > 400 then
                    core.sound.stopSay(self)
                end
            end
            resetGreetingState()
            speechStartTime = now
            greetingCheckPending = true
            lastYaw = self.rotation:getYaw()
        end
    end
    
    -- Check for greeting behavior over 2 seconds
    if greetingCheckPending then
        local elapsed = now - speechStartTime
        if elapsed <= GREETING_CHECK_DURATION then
            local result, reason = checkGreetingBehavior(now)
            if result == true then
                local name = getName()
                print(string.format("[%s] %s: greeting detected (%s)", MODNAME, name, reason))
                core.sendGlobalEvent("Pilferer_greetingDetected", {name = name})
                resetGreetingState()
                resetHello()
            elseif result == false then
                print(string.format("[%s] %s: not a greeting (%s)", MODNAME, getName(), reason))
                resetGreetingState()
                resetHello()
            end
            -- result == nil means keep checking
        else
            -- Timeout - succeed if player was in range and nothing failed
            if playerWasInRange and not greetingFailed then
                local name = getName()
                print(string.format("[%s] %s: greeting detected (observation complete)", MODNAME, name))
                core.sendGlobalEvent("Pilferer_greetingDetected", {name = name})
            else
                print(string.format("[%s] %s: greeting check timed out", MODNAME, getName()))
            end
            resetGreetingState()
            resetHello()
        end
    end
    
    wasSaying = isSaying
end

local function onInactive()
    if saveData.helloBoosted then
        local hello = types.Actor.stats.ai.hello(self)
        hello.modifier = 0
        saveData.helloBoosted = false
        saveData.originalHelloBase = nil
    end
    resetGreetingState()
    core.sendGlobalEvent("Pilferer_unhookActor", self)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = onInactive,
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        Pilferer_boostHello = boostHello,
        Pilferer_resetHello = resetHello,
    },
}