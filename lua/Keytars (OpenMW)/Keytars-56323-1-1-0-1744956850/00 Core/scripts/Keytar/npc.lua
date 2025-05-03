local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")

local configGlobal = require('scripts.Keytar.config.global')
local K = require("scripts.Keytar.keytarist")

local inspirationTimer = 0
local inspirationInterval = 1 -- seconds
local inspirationDistance = 2000

local graceTimer = 0
local gracePeriod = 0.15 -- seconds

local lastRealTime = core.getRealTime()

local danceTimer = 0
local danceMaxTimer = 0.5
local lastDanceEventTime = core.getRealTime()

local ignoreSendTimer = 0
local ignoreSendInterval = 2

local validKeytarist = false
local validKeytaristCheckTimer = 0

local danceOffset = math.random(0, 15) / 16

local function getDanceOffset()
    if configGlobal.options.danceTimingVariation then
        return danceOffset
    else
        return 0
    end
end

local function receiveTime(data)
    K.musicTime = data.time + (core.getRealTime() - data.realTime)
end

local function isFollower()
    local targets = I.AI.getTargets('Follow')
    for _, target in ipairs(targets) do
        if target and target.type == types.Player then
            return true
        end
    end
    return false
end

local function canDance()
    return configGlobal.options.nearbyNpcsDance and not K.isPlaying() and not types.Actor.isDead(self) and next(I.AI.getTargets('Combat')) == nil
end

local function tryDance(time)
    if canDance() then
        danceTimer = danceMaxTimer
        local lastTime = K.musicTime
        K.musicTime = time

        lastDanceEventTime = lastDanceEventTime or core.getRealTime()
        local realTime = core.getRealTime()
        if not anim.isPlaying(self, 'keytardance') or (time - lastTime) - (realTime - lastDanceEventTime) > 0.05 then
            -- prevent jittering when multiple keytarists are sending dance events
            anim.cancel(self, 'keytardance')
            K.startAnim('keytardance', getDanceOffset())
        end
    end
    lastDanceEventTime = realTime
end

local function turnTowardPlayer(minDiff, rate)
    local player = nearby.players[1]
    if player then
        local vectorToPlayer = (player.position - self.position):normalize()
        local targetYaw = math.atan2(vectorToPlayer.x, vectorToPlayer.y)
        local currentYaw = self.object.rotation:getYaw()
        local changeAmt = targetYaw - currentYaw
        changeAmt = (changeAmt + math.pi) % (2 * math.pi) - math.pi -- Normalize to [-pi, pi]
        if math.abs(changeAmt) > minDiff then
            self.controls.yawChange = changeAmt * rate
        end
    end
end

local function update(dt)
    if danceTimer > 0 then
        danceTimer = danceTimer - dt
        K.handleMovement(dt, 'idle')
    else
        if anim.isPlaying(self, 'keytardance') then
            anim.cancel(self, 'keytardance')
        end
    end

    if validKeytaristCheckTimer < configGlobal.technical.validKeytaristRecheckInterval then
        validKeytaristCheckTimer = validKeytaristCheckTimer + dt
    else
        validKeytaristCheckTimer = 0
        validKeytarist = K.isValidKeytarist(self)
    end

    if validKeytarist then
        if configGlobal.options.enableFollowerAI then
            inspirationTimer = inspirationTimer + dt
            if K.isPlaying() then
                K.startAnim('keytar')
                K.musicTime = (K.musicTime + (core.getRealTime() - lastRealTime)) % configGlobal.customMusic.customMusicLength
            else
                anim.cancel(self, 'keytar')
                K.musicTime = -1
            end

            if configGlobal.options.teleportingKeytarists and K.distTo(nearby.players[1]) > configGlobal.technical.teleportingKeytaristsDistance then
                core.sendGlobalEvent('TeleportToPlayer', self)
            end
            
            if types.Actor.isDead(self) then
                K.stopPlaying()
                return
            end

            I.AI.filterPackages(function(package)
                return not (package.type == 'Combat' and package.target and package.target.type == types.Player)
            end)

            local target = I.AI.getActiveTarget('Combat')
            if target then
                if types.Actor.isDead(target) then
                    target = nil
                else
                    types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                end
            end

            if configGlobal.options.untargetableKeytarists then
                if ignoreSendTimer < ignoreSendInterval then
                    ignoreSendTimer = ignoreSendTimer + dt
                else
                    ignoreSendTimer = 0
                    for _, actor in ipairs(I.AI.getTargets('Combat')) do
                        actor:sendEvent('IgnoreKeytarists')
                    end
                end
            end

            local health = types.Actor.stats.dynamic.health(self)
            if configGlobal.options.immortalKeytarists and isFollower() then
                health.modifier = 100000
                health.current = health.current + 100 
            else
                health.modifier = 0
            end
            health.current = math.min(health.current, health.base + health.modifier)

            if target and isFollower() then
                if configGlobal.options.pacifistKeytarists then
                    local distToTarget = K.distTo(target)
                    local distToPlayer = K.distTo(nearby.players[1])
                    local freeze = distToTarget < configGlobal.technical.targetFreezeDistance or distToPlayer < configGlobal.technical.playerFreezeDistance
                    self.enableAI(self, not freeze) -- Freeze if close to combat target

                    if distToPlayer < configGlobal.technical.playerMoveDistance then
                        -- Get out of the player's way
                        turnTowardPlayer(0, 0.1)
                        self.controls.movement = -1
                    elseif freeze then
                        turnTowardPlayer(math.pi / 3, 0.05)
                    end
                else
                    self.enableAI(self, true)
                end

                if configGlobal.options.inspiringKeytarists and inspirationTimer >= inspirationInterval then
                    inspirationTimer = 0
                    if K.distTo(nearby.players[1]) < inspirationDistance then
                        nearby.players[1]:sendEvent('ReceiveInspiration', self)
                    end
                end

                graceTimer = 0
            else
                self.enableAI(self, true)
            end
            
            if target and not K.isPlaying() then
                K.startPlaying(configGlobal.technical.npcKeytarVolume)
            elseif K.isPlaying() and not target then
                graceTimer = graceTimer + dt
                if graceTimer >= gracePeriod then
                    K.stopPlaying()
                end
            end

            if K.isPlaying() then
                K.handleMovement(dt)
            end

            K.tickDanceSend(dt)
        else
            self.enableAI(self, true)
            if K.isPlaying() then
                K.stopPlaying()
            end
        end
    elseif K.isPlaying() then
        K.stopPlaying()
    end

    if core.getRealTime() - lastRealTime > 0.25 then
        K.resyncAnim('keytar')
    end
    
    lastRealTime = core.getRealTime()
end

return {
    engineHandlers = {
        onUpdate = update,
        onInactive = function()
            if validKeytarist and isFollower() and configGlobal.options.teleportingKeytarists then
                core.sendGlobalEvent('TeleportToPlayer', self)
            end
        end
    },
    eventHandlers = {
        SendKeytarTime = receiveTime,
        TimeToDance = tryDance,
    }
}