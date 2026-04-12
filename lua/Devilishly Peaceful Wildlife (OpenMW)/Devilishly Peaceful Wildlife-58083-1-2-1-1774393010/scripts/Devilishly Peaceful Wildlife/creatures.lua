local self   = require("openmw.self")
local core   = require("openmw.core")
local types  = require("openmw.types")
local nearby = require("openmw.nearby")
local time   = require("openmw_aux.time")
local AI     = require("openmw.interfaces").AI
local anim   = require("openmw.animation")

local shared             = require("scripts.Devilishly Peaceful Wildlife.shared")
local FIGHT              = shared.FIGHT
local INSTANT_AGGRO      = shared.INSTANT_AGGRO
local GROUP_AGGRO        = shared.GROUP_AGGRO
local WARNING_CREATURES  = shared.WARNING_CREATURES
local DEFAULT_DISTANCES  = shared.DEFAULT_DISTANCES
local DISTANCE_OVERRIDES = shared.DISTANCE_OVERRIDES
local MARKSMAN_TYPES     = shared.MARKSMAN_TYPES
local EXTRA_CREATURES    = shared.EXTRA_CREATURES

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------

local CHECK_INTERVAL  = 2  -- keep as-is; early-outs do most of the work
local GROWL_COOLDOWN  = 1.25  -- seconds
local GROUP_RADIUS    = 5000

------------------------------------------------------------
-- STATE
------------------------------------------------------------

-- Cached per-actor locals to reduce table lookups
local _REC_ID, _BEHAVIOR, _INSTANT = nil, nil, false

local growlCounter     = 0
local growlThreshold   = math.random(1, 3)
local aiWasRemoved     = false
local savedPackage     = nil
local trackTimer       = nil
local lastGrowlTime    = 0
-- persistence for "once" behavior
local didSetCliffSpeed = false

------------------------------------------------------------
-- MATH
------------------------------------------------------------

local function angleDifference(a, b)
    local diff = b - a
    return math.atan2(math.sin(diff), math.cos(diff))
end

------------------------------------------------------------
-- STOP TRACKING
------------------------------------------------------------

local function stopTracking()
    if trackTimer then
        trackTimer()
        trackTimer = nil
    end
    self.controls.yawChange = 0
end

------------------------------------------------------------
-- START TRACKING (uses per-species warning window)
------------------------------------------------------------

local function startTracking(player, warnNear, warnFar)
    if trackTimer then return end
    -- reduce inner timer frequency from 0.01s → 0.03s (still smooth, fewer callbacks)
    trackTimer = time.runRepeatedly(function()
        if types.Actor.stats.dynamic.health(self).current <= 0
        or types.Actor.stats.ai.fight(self).base == 100 then
            stopTracking()
            return
        end
        local toPlayer = player.position - self.position
        local distance = toPlayer:length()
        if distance < warnFar and distance > warnNear then
            local targetYaw  = math.atan2(toPlayer.x, toPlayer.y)
            local currentYaw = self.rotation:getYaw()
            self.controls.yawChange = angleDifference(currentYaw, targetYaw) / 6
        else
            stopTracking()
        end
    end, 0.03 * time.second)
end

------------------------------------------------------------
-- INIT + "SET CLIFF SPEED ONCE"
------------------------------------------------------------

local function setCliffBaseSpeedOnce()
    -- Only for cliff racers; run once per actor instance
    if didSetCliffSpeed then return end
    if _REC_ID == "cliff racer" or _REC_ID == "cliff racer_diseased" then
        -- Set base "Speed" attribute to 300
        types.Actor.stats.attributes.speed(self).base = 300
        didSetCliffSpeed = true
    end
end

------------------------------------------------------------
-- GROUP AWARENESS (whitelisted + strict same-record)
------------------------------------------------------------

local function checkGroupAggro(player)
    -- If we're already hostile, skip.
    if types.Actor.stats.ai.fight(self).modified >= 100 then return end

    -- Only species explicitly whitelisted can propagate group aggro.
    if not GROUP_AGGRO[_REC_ID] then return end

    -- Skip group scan if player is far away from us. Packmates unlikely to matter.
    local pDist = (player.position - self.position):length()
    if pDist > GROUP_RADIUS + 1000 then return end


    for _, other in ipairs(nearby.actors) do
        if other ~= self
        and other.type == types.Creature
        -- STRICT: must be *exactly* the same record as us to propagate
        and other.recordId == _REC_ID
        and types.Actor.stats.dynamic.health(other).current > 0 then

            local dist = (other.position - self.position):length()
            if dist <= GROUP_RADIUS
            and types.Actor.stats.ai.fight(other).modified >= 90 then
                types.Actor.stats.ai.fight(self).base = 100
                AI.startPackage({ type = 'Combat', target = player })
                stopTracking()
                return
            end
        end
    end
end

local function goHostile(player)
    types.Actor.stats.ai.fight(self).base = 100
    AI.startPackage({ type = 'Combat', target = player })
    stopTracking()
end

------------------------------------------------------------
-- INIT
------------------------------------------------------------

local function onInit()
    if self.type ~= types.Creature then return end
    _REC_ID   = self.recordId
    _BEHAVIOR = WARNING_CREATURES[_REC_ID]
    _INSTANT  = INSTANT_AGGRO[_REC_ID] == true
    local newFight = FIGHT[_REC_ID]
    if newFight then
        types.Actor.stats.ai.fight(self).base = newFight
    end
    setCliffBaseSpeedOnce()
end

local function onSave()
    return { didSetCliffSpeed = didSetCliffSpeed }
end

local function onLoad(saved)
    if saved then
        didSetCliffSpeed = saved.didSetCliffSpeed or false
    end
    lastGrowlTime = 0
    onInit()
end

------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------

time.runRepeatedly(function()

    if types.Actor.stats.dynamic.health(self).current <= 0 then return end
    if self.type ~= types.Creature then return end

    local player = nearby.players[1]
    if not player then return end

    -- Per-species distances (with fallback to defaults)
    local distOverride = DISTANCE_OVERRIDES[_REC_ID]
    local warnNear   = distOverride and distOverride.warnNear or DEFAULT_DISTANCES.warnNear
    local warnFar    = distOverride and distOverride.warnFar  or DEFAULT_DISTANCES.warnFar
    local attackDist = distOverride and distOverride.attack   or DEFAULT_DISTANCES.attack
    local resetDist  = math.max(2000, warnFar + 500)

    -- Cheap far-distance early-out
    local distance = (player.position - self.position):length()
    if distance > resetDist then
        if growlCounter ~= 0 then
            growlCounter  = 0
            growlThreshold = math.random(1, 3)
        end
        return
    end

    -- GROUP CHECK (cheap guard inside)
    checkGroupAggro(player)

    -- SPECIAL: INSTANT AGGRO (no warning) FOR SLAUGHTERFISH/DREUGH
    if _INSTANT and distance < 2000 then
        goHostile(player)
        return
    end

    -- COMBAT STATE
    if types.Actor.stats.ai.fight(self).base == 100 then
        stopTracking()
        if aiWasRemoved then
            aiWasRemoved = false
            if savedPackage then
                AI.startPackage(savedPackage)
                savedPackage = nil
            end
        end
        return
    end

    -- MARKSMAN CHECK: attack if the player has marksman drawn within warn range
    if distance < warnFar and types.Actor.getStance(player) == 1 and (WARNING_CREATURES[_REC_ID] or EXTRA_CREATURES[_REC_ID]) then
        local eq = types.Actor.getEquipment(player)
        if eq then
            local item = eq[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            if item and item:isValid()
            and types.Weapon.objectIsInstance(item)
            and MARKSMAN_TYPES[types.Weapon.record(item).type] then
                goHostile(player)
                return
            end
        end
    end

    --------------------------------------------------------
    -- WARNING / STALKING *ONLY* FOR WARNING CREATURES
    --------------------------------------------------------
    if _BEHAVIOR then
        if distance < warnFar and distance > warnNear then

            if not aiWasRemoved then
                savedPackage = AI.getActivePackage()
                aiWasRemoved = true
                AI.removePackages("Wander")
            end

            startTracking(player, warnNear, warnFar)

            -- Gate anim/sound so we don't spam every tick
            if _BEHAVIOR.anim then
                anim.playBlended(self, _BEHAVIOR.anim, {
                    priority = anim.PRIORITY.Scripted
                })
            end

            local now = core.getRealTime and core.getRealTime() or 0
            if now == 0 or (now - lastGrowlTime) >= GROWL_COOLDOWN then
                local soundList = _BEHAVIOR.sounds
                if soundList and #soundList > 0 then
                    core.sound.playSound3d(soundList[math.random(#soundList)], self, {
                        timeOffset = 0.1,
                        volume     = 5,
                        loop       = false,
                        pitch      = 1.0,
                    })
                end
                lastGrowlTime = now
            end

            growlCounter = growlCounter + 1

        else
            stopTracking()
            if aiWasRemoved then
                aiWasRemoved = false
                if savedPackage then
                    AI.startPackage(savedPackage)
                    savedPackage = nil
                end
            end
        end

        -- ATTACK TRIGGER: ONLY for warning creatures
        if distance < attackDist or growlCounter > 1 + growlThreshold then
            goHostile(player)
        end
    end

    -- RESET if close-but-not-warning and we drifted away
    if distance > resetDist then
        growlCounter  = 0
        growlThreshold = math.random(1, 3)
    end

end, CHECK_INTERVAL * time.second)

------------------------------------------------------------
-- RETURN
------------------------------------------------------------

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
    },
}