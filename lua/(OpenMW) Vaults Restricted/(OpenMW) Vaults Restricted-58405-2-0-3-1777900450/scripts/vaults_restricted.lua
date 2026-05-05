local self   = require('openmw.self')
local types  = require('openmw.types')
local AI     = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local util   = require('openmw.util')
local core   = require('openmw.core')
local time   = require('openmw_aux.time')
local async  = require('openmw.async')

local shared            = require('scripts.vaults_shared')
local WARNING_MESSAGES  = shared.WARNING_MESSAGES
local LOST_PLAYER_LINES = shared.LOST_PLAYER_LINES

local VEC_FORWARD  = util.vector3(0, 1, 0)
local HEAD_OFFSET  = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)
local COS_FOV      = math.cos(math.rad(100))
local LOST_PAUSE   = 1.0

local isIntruder       = false
local countdownActive  = false
local countdownCancel  = nil       -- handle to cancel the countdown timer
local countdownRemaining = nil     -- preserved between WARNING -> INVESTIGATING -> WARNING re-spots
local playerIsSneaking = false
local trackTimer       = nil
local wasInCombat      = false
local warningStartHP   = nil       -- guard HP when WARNING began, for instant-combat-on-attack
local hpCheckAcc       = 0         -- 0.1s accumulator for fast HP poll during WARNING
local lostPauseActive  = false     -- true while the post-search pause runs

local guardState       = "IDLE" -- IDLE, WARNING, INVESTIGATING, RETURNING
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

local function cancelCountdown()
    if countdownCancel then
        countdownCancel()
        countdownCancel = nil
    end
    countdownActive = false
end

local function getLostLine()
    return LOST_PLAYER_LINES[math.random(#LOST_PLAYER_LINES)]
end

-- Exit WARNING state cleanly
local function exitWarning()
    cancelCountdown()
    stopTracking()
    if not types.Actor.isDead(self) then
        self:enableAI(true)
        if self.type.getStance(self) ~= 0 then
            self.type.setStance(self, 0)
        end
    end
    warningStartHP = nil
    hpCheckAcc     = 0
    self.object:sendEvent("detd_SetIgnoreWeaponReaction", false)
end

local function startCombat(target)
    if not target or not target:isValid() then return end
    if not types.Actor.isDead(self) then
        self:enableAI(true)
    end
    AI.startPackage({ type = "Combat", target = target })
end

-- triggered locally when this guard's countdown expires OR when another guard in the same cell raises the alarm
local function attackPlayer(player, alreadyAlerted)
    if not alreadyAlerted then
        core.sendGlobalEvent('AddVaultBounty', { player = player, faction = data.vaultFaction })
        core.sendGlobalEvent('VaultsAlertAllGuards', {
            sourceGuard = self.object,
            cell        = self.cell.id,
            player      = player,
            faction     = data.vaultFaction,
        })
    end
    exitWarning()
    countdownRemaining = nil
    guardState  = "IDLE"
    wasInCombat = true
    startCombat(player)
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
    local result = nearby.castRay(self.position + HEAD_OFFSET, player.position + CHEST_OFFSET,
        { collisionType = 3, ignore = { self } })
    return not result.hit
end

local liveCountdown = nil

local function startCountdown(player)
    if countdownActive then return end
    countdownActive = true
    liveCountdown = countdownRemaining or data.countdown
    countdownRemaining = nil

    countdownCancel = time.runRepeatedly(function()
        if not countdownActive or guardState ~= "WARNING" then
            return false
        end
        if not canSeePlayer(player) then
            return false
        end

        if liveCountdown > 0 then
            local fmt = WARNING_MESSAGES[data.messageType] or WARNING_MESSAGES[0]
            player:sendEvent("GuardWarning", { message = string.format(fmt, math.ceil(liveCountdown)) })
            liveCountdown = liveCountdown - 1
        else
            attackPlayer(player, false)
            return false
        end
    end, 1 * time.second)
end

local function onUpdate(dt)
    if not data.modEnabled or not isIntruder or not self:isValid() or types.Actor.isDead(self) then return end
    if lostPauseActive then return end

    local player = nearby.players[1]
    if not player or self.cell ~= player.cell then return end

    if guardState == "WARNING" and warningStartHP then
        hpCheckAcc = hpCheckAcc + dt
        if hpCheckAcc >= 0.1 then
            hpCheckAcc = 0
            local currentHP = types.Actor.stats.dynamic.health(self).current
            if currentHP < warningStartHP then
                attackPlayer(player, false)
                return
            end
        end
    end

    local activePackage = AI.getActivePackage(self)
    local inCombat = activePackage and activePackage.type == "Combat"

    if inCombat then
        if trackTimer then stopTracking() end
        cancelCountdown()
        countdownRemaining = nil
        guardState = "IDLE"
        wasInCombat = true
        return
    end

    if wasInCombat then
        wasInCombat = false
        originalPos = nil
        lastPlayerPos = nil
    end

    local seesPlayer = canSeePlayer(player)

    if seesPlayer then
        lastPlayerPos = player.position

        if guardState == "IDLE" or guardState == "INVESTIGATING" or guardState == "RETURNING" then
            if guardState == "IDLE" then
                originalPos = self.position
                countdownRemaining = nil
            end
            AI.removePackages("Travel")

            guardState = "WARNING"

            self:enableAI(false)
            self.object:sendEvent("detd_SetIgnoreWeaponReaction", true)

            if self.type.getStance(self) ~= 1 then self.type.setStance(self, 1) end
            startTracking(player)

            warningStartHP = types.Actor.stats.dynamic.health(self).current
            hpCheckAcc     = 0

            startCountdown(player)
        end
    else
        if guardState == "WARNING" then
            -- sight lost
            if liveCountdown then
                countdownRemaining = liveCountdown
            end
            guardState = "INVESTIGATING"
            exitWarning()

            local bounds = types.Actor.getPathfindingAgentBounds(self)
            local dest = nearby.findNearestNavMeshPosition(lastPlayerPos, { agentBounds = bounds }) or lastPlayerPos
            AI.startPackage({ type = 'Travel', destPosition = dest, cancelOther = false })

        elseif guardState == "INVESTIGATING" then
            if not activePackage or activePackage.type ~= "Travel" then
                player:sendEvent("GuardWarning", { message = getLostLine() })
                guardState = "RETURNING"
                lostPauseActive = true
                async:newUnsavableSimulationTimer(LOST_PAUSE, function()
                    lostPauseActive = false
                    if not self:isValid() or types.Actor.isDead(self) then return end
                    if guardState ~= "RETURNING" then return end
                    if not originalPos then return end
                    local bounds = types.Actor.getPathfindingAgentBounds(self)
                    local dest = nearby.findNearestNavMeshPosition(originalPos, { agentBounds = bounds }) or originalPos
                    AI.startPackage({ type = 'Travel', destPosition = dest, cancelOther = false })
                end)
            end

        elseif guardState == "RETURNING" then
            if not activePackage or activePackage.type ~= "Travel" then
                guardState = "IDLE"
                originalPos = nil
                lastPlayerPos = nil
                -- guard fully gave up the chase: clear any preserved countdown
                countdownRemaining = nil
            end
        end
    end
end

local function onVaultStatus(newParams)
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
        if guardState == "WARNING" then
            exitWarning()
        else
            cancelCountdown()
            stopTracking()
        end
        -- player is no longer an intruder
        AI.removePackages("Combat")
        AI.removePackages("Travel")
        guardState         = "IDLE"
        wasInCombat        = false
        originalPos        = nil
        lastPlayerPos      = nil
        lostPauseActive    = false
        countdownRemaining = nil
    end
end

local function onPlayerSneakChanged(params)
    playerIsSneaking = params.sneaking
end

-- another guard in the same cell finished their countdown and is engaging
local function onVaultJoinCombat(params)
    if not data.modEnabled or not isIntruder then return end
    if not params or not params.player or not params.player:isValid() then return end
    if types.Actor.isDead(self) then return end

    local activePackage = AI.getActivePackage(self)
    if activePackage and activePackage.type == "Combat" then return end

    attackPlayer(params.player, true)
end

local function onInactive()
    cancelCountdown()
    stopTracking()
    if guardState == "WARNING" and not types.Actor.isDead(self) then
        self:enableAI(true)
        if self.type.getStance(self) ~= 0 then
            self.type.setStance(self, 0)
        end
    end
    wasInCombat        = false
    guardState         = "IDLE"
    warningStartHP     = nil
    hpCheckAcc         = 0
    originalPos        = nil
    lastPlayerPos      = nil
    lostPauseActive    = false
    countdownRemaining = nil
    core.sendGlobalEvent("VaultsRestricted_RequestRemoval", self.object)
end

return {
    eventHandlers = {
        VaultStatus        = onVaultStatus,
        PlayerSneakChanged = onPlayerSneakChanged,
        VaultJoinCombat    = onVaultJoinCombat,
    },
    engineHandlers = {
        onUpdate   = onUpdate,
        onInactive = onInactive,
    },
}