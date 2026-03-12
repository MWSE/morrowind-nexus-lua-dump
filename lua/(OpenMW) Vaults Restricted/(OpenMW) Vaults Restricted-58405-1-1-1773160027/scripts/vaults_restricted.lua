local self   = require('openmw.self')
local types  = require('openmw.types')
local AI     = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local util   = require('openmw.util')
local core   = require('openmw.core')
local time   = require('openmw_aux.time')

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

local data = {
    messageType = 0,
    vaultFaction = nil,
    countdown = 5,
    witnessRadius = 600,
    modEnabled = true
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
    if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
end

local function isPlayerHidden(player)
    local eff = types.Actor.activeEffects(player)
    local invis = eff and eff:getEffect("invisibility")
    local cham  = eff and eff:getEffect("chameleon")
    local sneak = types.NPC.stats.skills.sneak(player).modified
    
    if (invis and invis.magnitude and invis.magnitude > 0) or
       (cham  and cham.magnitude  and cham.magnitude  >= 85) or
       (playerIsSneaking and sneak >= 75) then
        return true
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
        return 
    end

    if canSeePlayer(player) then
        if not aiWasRemoved then
            AI.removePackages("Wander")
            aiWasRemoved = true
        end
        
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
    else
        if countdownActive or aiWasRemoved or self.type.getStance(self) ~= 0 then
            countdownActive = false
            restoreAI()
        end
    end
end

return {
    eventHandlers = {
        VaultStatus = function(newParams)
            isIntruder = newParams.intruder
            data.messageType = newParams.messageType or 0
            data.vaultFaction = newParams.faction
            data.countdown = newParams.countdown or 5
            data.witnessRadius = newParams.witnessRadius or 600
            data.modEnabled = newParams.modEnabled ~= false
            if not isIntruder then restoreAI() end
        end,
        PlayerSneakChanged = function(data)
            playerIsSneaking = data.sneaking
        end
    },
engineHandlers = { 
        onUpdate = updateLogic,
        onInactive = function() 
            stopTracking()
            countdownActive = false
            aiWasRemoved = false
        end 
    }
}