local self   = require('openmw.self')
local types  = require('openmw.types')
local AI     = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local util   = require('openmw.util')
local core   = require('openmw.core')
local time   = require('openmw_aux.time')
local async = require('openmw.async')

local shared           = require('scripts.vaults_shared')
local WARNING_MESSAGES = shared.WARNING_MESSAGES

local VEC_FORWARD  = util.vector3(0, 1, 0)
local HEAD_OFFSET  = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)
local COS_FOV      = math.cos(math.rad(100))

local isIntruder       = false
local countdownActive  = false
local aiWasRemoved     = false
local playerIsSneaking = false
local trackTimer       = nil
local isStanceLocked = false

local guardState       = "IDLE" -- possible states are IDLE, WARNING, INVESTIGATING, RETURNING
local originalPos      = nil
local lastPlayerPos    = nil

local data = {
    messageType        = 0,
    vaultFaction       = nil,
    countdown          = 5,
    witnessRadius      = 600,
    modEnabled         = true,
    chameleonThreshold = 85,
    sneakThreshold     = 75,
    signCompat         = false,
}

local function angleDifference(a, b)
    local diff = b - a
    return math.atan2(math.sin(diff), math.cos(diff))
end

local function stopTracking()
    if trackTimer then trackTimer() trackTimer = nil end
    self.controls.yawChange = 0
end

local function startTracking(player)
    if trackTimer then return end
    trackTimer = time.runRepeatedly(function()
        if not self:isValid() or types.Actor.isDead(self) or not player or not player:isValid() then
            stopTracking()
            return
        end
        local toPlayer = player.position - self.position
        local targetYaw = math.atan2(toPlayer.x, toPlayer.y)
        local currentYaw = self.rotation:getYaw()
        self.controls.yawChange = angleDifference(currentYaw, targetYaw) / 6
    end, 0.03 * time.second)
end

local function restoreAI()
    stopTracking()
    aiWasRemoved = false

    local activePackage = AI.getActivePackage(self)
        if activePackage and activePackage.type == "Combat" then 
            return
    end

    if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
end

local function isPlayerHidden(player)
    local eff   = types.Actor.activeEffects(player)
    local invis = eff and eff:getEffect("invisibility")
    local cham  = eff and eff:getEffect("chameleon")

    if (invis and invis.magnitude and invis.magnitude > 0) or
       (cham  and cham.magnitude  and cham.magnitude  >= data.chameleonThreshold) then
        return true
    end

    if playerIsSneaking then
        if data.signCompat then
            return true
        end
        local sneak = types.NPC.stats.skills.sneak(player).modified
        if sneak >= data.sneakThreshold then return true end
    end

    return false
end

local function canSeePlayer(player)
    if not player or types.Actor.isDead(player) or isPlayerHidden(player) then return false end
    local toPlayer = player.position - self.position
    if toPlayer:length() > data.witnessRadius then return false end
    local npcForward = self.rotation:apply(VEC_FORWARD)
    if npcForward:dot(toPlayer:normalize()) < COS_FOV then return false end
    local result = nearby.castRay(self.position + HEAD_OFFSET, player.position + CHEST_OFFSET, {collisionType = 3, ignore = {self}})
    return not result.hit
end

local function updateLogic(dt)
    if not data.modEnabled or not isIntruder or not self:isValid() or types.Actor.isDead(self) then return end

    local player = nearby.players[1]
    if not player or self.cell ~= player.cell then return end

    local activePackage = AI.getActivePackage(self)
    
    if activePackage and activePackage.type == "Combat" then 
        if trackTimer then stopTracking() end
        guardState = "IDLE"
        countdownActive = false
        return 
    end

    local seesPlayer = canSeePlayer(player)

    if seesPlayer then
        lastPlayerPos = player.position

        if guardState == "IDLE" or guardState == "INVESTIGATING" or guardState == "RETURNING" then
            if guardState == "IDLE" then
                originalPos = self.position
            end
            
            guardState = "WARNING"
            
            if not aiWasRemoved then
                AI.removePackages("Wander")
                aiWasRemoved = true
            end
            
            AI.removePackages("Travel")
            
            if self.type.getStance(self) ~= 1 then self.type.setStance(self, 1) end
            startTracking(player)

            if not countdownActive then
                countdownActive = true
                local timerValue = data.countdown
                
                time.runRepeatedly(function()
                    if not countdownActive or not canSeePlayer(player) then return false end
                    
                    if timerValue > 0 then
                        local fmt = WARNING_MESSAGES[data.messageType] or WARNING_MESSAGES[0]
                        player:sendEvent("GuardWarning", { message = string.format(fmt, math.ceil(timerValue)) })
                        timerValue = timerValue - 1
                    else
                        stopTracking()
                        countdownActive = false
                        core.sendGlobalEvent('AddVaultBounty', { player = player, faction = data.vaultFaction })
                        AI.startPackage({ type = "Combat", target = player })
                        return false
                    end
                end, 1 * time.second)
            end
        end
    else
        if guardState == "WARNING" then
            guardState = "INVESTIGATING"
            countdownActive = false
            restoreAI()
            
            local bounds = types.Actor.getPathfindingAgentBounds(self)
            local dest = nearby.findNearestNavMeshPosition(lastPlayerPos, { agentBounds = bounds }) or lastPlayerPos
            AI.startPackage({ type = 'Travel', destPosition = dest, cancelOther = false })

        elseif guardState == "INVESTIGATING" then
            if not activePackage or activePackage.type ~= "Travel" then
                guardState = "RETURNING"
                local bounds = types.Actor.getPathfindingAgentBounds(self)
                local dest = nearby.findNearestNavMeshPosition(originalPos, { agentBounds = bounds }) or originalPos
                AI.startPackage({ type = 'Travel', destPosition = dest, cancelOther = false })
            end

        elseif guardState == "RETURNING" then
            if not activePackage or activePackage.type ~= "Travel" then
                guardState = "IDLE"
                originalPos = nil
                lastPlayerPos = nil
                restoreAI()
            end
        end
    end
end

local function forceWritStance()
    if not self:isValid() or types.Actor.isDead(self) then return end
    
    if guardState == "WARNING" then
        if self.type.getStance(self) ~= 1 then
            self.type.setStance(self, 1)
        end
        async:newUnsavableSimulationTimer(0.02, async:callback(forceWritStance))
    else
        isStanceLocked = false
    end
end

return {
    eventHandlers = {
        VaultStatus = function(newParams)
            isIntruder         = newParams.intruder
            data.messageType   = newParams.messageType or 0
            data.vaultFaction  = newParams.faction
            data.countdown     = newParams.countdown or 5
            data.witnessRadius = newParams.witnessRadius or 600
            data.modEnabled    = newParams.modEnabled ~= false
            data.chameleonThreshold = newParams.chameleonThreshold or 85
            data.sneakThreshold     = newParams.sneakThreshold or 75
            data.signCompat    = newParams.signCompat == true
            
            if not isIntruder then 
                restoreAI()
                local activePackage = AI.getActivePackage(self)
                if not (activePackage and activePackage.type == "Combat") then
                    AI.removePackages("Travel")
                end
                AI.removePackages("Travel")
                guardState = "IDLE" 
                countdownActive = false
            end
        end,
        PlayerSneakChanged = function(params)
            playerIsSneaking = params.sneaking
        end,
        detd_pcWeaponState = function(value)
            if value == 0 and guardState == "WARNING" then
                if not isStanceLocked then
                    isStanceLocked = true
                    forceWritStance()
                end
            end
        end,
    },
    engineHandlers = { 
        onUpdate = updateLogic,
        onInactive = function() 
            stopTracking()
            countdownActive = false
            aiWasRemoved = false
            guardState = "IDLE"
        end 
    }
}