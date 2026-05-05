local core    = require('openmw.core')
local self    = require('openmw.self')
local types   = require('openmw.types')
local nearby  = require('openmw.nearby')
local util    = require('openmw.util')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local ui      = require('openmw.ui')
local I       = require('openmw.interfaces')
local time    = require('openmw_aux.time')

local shared            = require('scripts.nightpatrol_shared')
local GUARD_PATTERNS         = shared.GUARD_PATTERNS
local GUARD_TR_PATTERNS      = shared.GUARD_TR_PATTERNS
local GUARD_EXCLUDE_PATTERNS = shared.GUARD_EXCLUDE_PATTERNS
local EXEMPT_IDS        = shared.EXEMPT_IDS
local DEFAULTS          = shared.DEFAULTS
local MESSAGES          = shared.MESSAGES

local NPC   = types.NPC
local Actor = types.Actor

local section = storage.playerSection('SettingsNightPatrol')

local VEC_FORWARD  = util.vector3(0, 1, 0)
local HEAD_OFFSET  = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)
local COS_FOV      = math.cos(math.rad(80))

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    MOD_ENABLED         = get('MOD_ENABLED'),
    DETECTION_RANGE     = get('DETECTION_RANGE'),
    DOOR_SCAN_RANGE     = get('DOOR_SCAN_RANGE'),
    NIGHT_START         = get('NIGHT_START'),
    NIGHT_END           = get('NIGHT_END'),
    STRAY_DISTANCE      = get('STRAY_DISTANCE'),
    DOOR_ARRIVAL_DIST   = get('DOOR_ARRIVAL_DIST'),
    DOOR_STRAY_DIST     = get('DOOR_STRAY_DIST'),
    CHAMELEON_THRESHOLD = get('CHAMELEON_THRESHOLD'),
    SNEAK_THRESHOLD     = get('SNEAK_THRESHOLD'),
    SIGN_COMPAT         = get('SIGN_COMPAT'),
    DISPOSITION_THRESHOLD = get('DISPOSITION_THRESHOLD'),
}

section:subscribe(async:callback(function(_, key)
    if key then
        cachedSettings[key] = get(key)
    else
        for k in pairs(cachedSettings) do
            cachedSettings[k] = get(k)
        end
    end
end))


local escortGuard       = nil
local escortIsOrdinator = false
local guardBusy         = false
local cooldown          = 0
local triedGuards       = {}

-- phases: nil (no escort / wait phase), 'travel', 'waiting'
local escortPhase       = nil
local doorPos           = nil
local destCellName      = nil
local guardOriginPos    = nil
local guardOriginCell   = nil
local guardOriginId     = nil
local waitTimer         = nil

local CHECK_INTERVAL = 1.0 * time.second
local timer = 0
local COOLDOWN_SECONDS = 8 * time.second

-- stray suppression: during active bounty + grace period after arrest closes
local lastBounty    = 0
local strayGrace    = 0
local STRAY_GRACE_SECONDS = 8 * time.second

local trespassPending = 0
local TRESPASS_PENDING_SECONDS = 3 * time.second


local function pickMessage(event)
    local pool = MESSAGES[event]
    if not pool then return nil end
    local list = escortIsOrdinator and pool.ordinator or pool.guard
    if not list or #list == 0 then return nil end
    return list[math.random(#list)]
end

local function showMessage(event)
    local msg = pickMessage(event)
    if msg then ui.showMessage(msg) end
end


local function resolveIsSneaking()
    if cachedSettings.SIGN_COMPAT then
        local signIface = I.SneakIsGoodNow
        if signIface and signIface.playerState then
            return signIface.playerState.isSneaking == true
        end
        return false
    end
    return self.controls.sneak
end

local function isPlayerHidden()
    local player = self.object
    local eff    = Actor.activeEffects(player)
    local invis = eff and eff:getEffect('invisibility')
    if invis and invis.magnitude and invis.magnitude > 0 then return true end
    local cham = eff and eff:getEffect('chameleon')
    if cham and cham.magnitude and cham.magnitude >= cachedSettings.CHAMELEON_THRESHOLD then return true end
   if resolveIsSneaking() then
        if cachedSettings.SIGN_COMPAT then return true end
        local sneak = NPC.stats.skills.sneak(player).modified
        if sneak >= cachedSettings.SNEAK_THRESHOLD then return true end
    end
    return false
end


local function canSeePlayer(npc, radius)
    local toPlayer = self.position - npc.position
    local len = toPlayer:length()
    if len == 0 then return true end
    if len > radius then return false end
    local npcForward = npc.rotation:apply(VEC_FORWARD)
    if npcForward:dot(toPlayer / len) < COS_FOV then return false end
    local result = nearby.castRay(
        npc.position + HEAD_OFFSET,
        self.position + CHEST_OFFSET,
        { collisionType = 3, ignore = { npc } }
    )
    return not result.hit
end


local function getGameHour()
    return (core.getGameTime() % time.day) / time.hour
end

local function isNightHour(hour)
    local s = cachedSettings.NIGHT_START
    local e = cachedSettings.NIGHT_END
    if s > e then return hour >= s or hour < e
    else return hour >= s and hour < e end
end


local function isGuard(npc)
    local id = npc.recordId
    for _, pattern in ipairs(GUARD_PATTERNS) do
        if id:find(pattern) then return true end
    end
    for _, pattern in ipairs(GUARD_TR_PATTERNS) do
        if id:find(pattern) then
            for _, exclude in ipairs(GUARD_EXCLUDE_PATTERNS) do
                if id:find(exclude) then return false end
            end
            return true
        end
    end
    return false
end

local function isOrdinator(npc)
    return npc.recordId:find("ordinator") ~= nil
end

local function isExempt(npc)
    return EXEMPT_IDS[npc.recordId] == true
end


local function commitTrespass()
    core.sendGlobalEvent('NightPatrol_Trespass', {
        player = self.object,
        guard  = escortGuard,
    })
end


local function returnGuardHome()
    if escortGuard and escortGuard:isValid() and guardOriginPos then
        core.sendGlobalEvent('NightPatrol_ReturnGuard', {
            guard    = escortGuard,
            cellName = guardOriginCell or '',
            position = guardOriginPos,
        })
    end
end

local function resetState()
    escortGuard = nil
    escortIsOrdinator = false
    escortPhase = nil
    doorPos = nil
    destCellName = nil
    guardOriginPos = nil
    guardOriginCell = nil
    guardOriginId = nil
    guardBusy = false
    waitTimer = nil
end

local function endEscaped()
    showMessage('escort_escaped')
    if escortGuard and escortGuard:isValid() then
        escortGuard:sendEvent('NightPatrol_StopAndReturn', {})
    end
    -- if same guard re-detects player, we need the real patrol point
    escortGuard = nil
    escortIsOrdinator = false
    escortPhase = nil
    doorPos = nil
    destCellName = nil
    guardBusy = false
    waitTimer = nil
    -- guardOriginPos/Cell intentionally preserved
end

local function endArrived()
    showMessage('escort_arrived')
    returnGuardHome()
    if escortGuard and escortGuard:isValid() then
        escortGuard:sendEvent('NightPatrol_FullStop', {})
    end
    resetState()
end

-- guard fought player (Combat), escort is over
local function endCombat()
    local gid = escortGuard and escortGuard.id
    resetState()
    cooldown = COOLDOWN_SECONDS
    if gid then triedGuards[gid] = COOLDOWN_SECONDS end
end

-- player strayed
local function onPlayerStrayed()
    commitTrespass()
    trespassPending = TRESPASS_PENDING_SECONDS
end


local function findNearestGuard()
    if isPlayerHidden() then return nil end
    local range = cachedSettings.DETECTION_RANGE
    local bestDist = range + 1
    local bestGuard = nil
    local playerPos = self.position
    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object
           and actor.type == NPC
        then
            local dist = (actor.position - playerPos):length()
            if dist < bestDist
               and not Actor.isDead(actor)
               and isGuard(actor)
               and not isExempt(actor)
               and not triedGuards[actor.id]
               and canSeePlayer(actor, range)
            then
                local disp = NPC.getDisposition(actor, self.object) or 0
                if disp < cachedSettings.DISPOSITION_THRESHOLD then
                    bestDist = dist
                    bestGuard = actor
                end
            end
        end
    end
    return bestGuard
end


local function onUpdate(dt)

    if not cachedSettings.MOD_ENABLED then
        if escortGuard then
            if escortGuard:isValid() then
                escortGuard:sendEvent('NightPatrol_StopEscort', {})
            end
            resetState()
        end
        return
    end

    timer = timer + dt
    if timer < CHECK_INTERVAL then return end
    timer = 0

    local cell = self.cell
    if not cell then return end

    -- player entered interior while escort active
    if not cell.isExterior then
        if escortGuard then
            if destCellName and cell.name == destCellName then
                -- entered the intended shelter door
                endArrived()
            else
                -- ended up somewhere else
                returnGuardHome()
                if escortGuard and escortGuard:isValid() then
                    escortGuard:sendEvent('NightPatrol_FullStop', {})
                end
                resetState()
            end
        end
        return
    end

    local hour = getGameHour()

    if escortGuard then
        if not escortGuard:isValid() or Actor.isDead(escortGuard) then
            resetState()
            return
        end

        -- guard and player no longer in same cell, exteriors are fine
        local guardCell = escortGuard.cell
        if guardCell ~= cell then
            local bothExterior = cell.isExterior and guardCell and guardCell.isExterior
            if not bothExterior
               -- likely intervention or recall
               or (escortGuard.position - self.position):length() > cachedSettings.STRAY_DISTANCE * 5
            then
                returnGuardHome()
                if escortGuard:isValid() then
                    escortGuard:sendEvent('NightPatrol_FullStop', {})
                end
                resetState()
                return
            end
        end

        local bounty = types.Player.getCrimeLevel(self)
        if lastBounty == 0 and bounty > 0 then
            strayGrace = 0
        elseif lastBounty > 0 and bounty == 0 then
            strayGrace = STRAY_GRACE_SECONDS
            showMessage('escort_resume')
        end
        lastBounty = bounty

        -- commitCrime confirmed by engine: clear pending flag
        if bounty > 0 and trespassPending > 0 then
            trespassPending = 0
        elseif trespassPending > 0 then
            trespassPending = trespassPending - CHECK_INTERVAL
        end

        -- guard is busy, skip checks
        if guardBusy then
            return
        end

        -- wait phase
        if waitTimer then
            waitTimer = waitTimer - CHECK_INTERVAL
            if waitTimer <= 0 then
                waitTimer = nil
                escortPhase = 'travel'
            end
            return
        end


        -- stealth escape
        if isPlayerHidden() then
            endEscaped()
            return
        end

        -- morning, so guard releases player, walks home
        if not isNightHour(hour) then
            showMessage('escort_morning')
            if escortGuard:isValid() then
                escortGuard:sendEvent('NightPatrol_StopAndReturn', {})
            end
            resetState()
            return
        end

        if strayGrace > 0 then
            strayGrace = strayGrace - CHECK_INTERVAL
            return
        end

        if bounty > 0 then
            return
        end

        if trespassPending > 0 then
            return
        end

        -- travel phase, player must stay near guard
        if escortPhase == 'travel' then
            local distToGuard = (escortGuard.position - self.position):length()
            if distToGuard > cachedSettings.STRAY_DISTANCE then
                onPlayerStrayed()
                return
            end
        end

        -- waiting phase, player must stay near door
        if escortPhase == 'waiting' and doorPos then
            local distToDoor = (self.position - doorPos):length()
            if distToDoor > cachedSettings.DOOR_STRAY_DIST then
                onPlayerStrayed()
                return
            end
        end

        return
    end


    for gid, remaining in pairs(triedGuards) do
        remaining = remaining - CHECK_INTERVAL
        if remaining <= 0 then
            triedGuards[gid] = nil
        else
            triedGuards[gid] = remaining
        end
    end

    if cooldown > 0 then
        cooldown = cooldown - CHECK_INTERVAL
        return
    end

    if not isNightHour(hour) then return end

    local guard = findNearestGuard()
    if guard then
        escortGuard = guard
        escortIsOrdinator = isOrdinator(guard)
        escortPhase = nil

        -- preserve original patrol point only if re-escorting the same guard
        if not guardOriginPos or guardOriginId ~= guard.id then
            guardOriginPos = guard.position
            local guardCell = guard.cell
            guardOriginCell = guardCell and (guardCell.name or '') or ''
            guardOriginId = guard.id
        end

        guard:sendEvent('NightPatrol_StartEscort', {
            target = self.object,
            doorScanRange   = cachedSettings.DOOR_SCAN_RANGE,
            doorArrivalDist = cachedSettings.DOOR_ARRIVAL_DIST,
        })
    end
end


-- event handlers

local function onGuardBusy(data)
    if escortGuard and data.guard == escortGuard then
        local wasBusy = guardBusy
        guardBusy = data.busy == true
        -- arrest resolved (fine paid): guard script restarts Escort
        if wasBusy and not guardBusy then
            escortPhase = 'travel'
        end
    end
end

local function onEscortConfirmed(data)
    if escortGuard and data.guard == escortGuard then
        destCellName = data.destCellName
        waitTimer = 5 * time.second
        showMessage('escort_start')
    end
end

local function onNoShelter(data)
    if escortGuard and data.guard == escortGuard then
        local gid = escortGuard.id
        resetState()
        if gid then triedGuards[gid] = COOLDOWN_SECONDS end
    end
end

local function onGuardAtDoor(data)
    if escortGuard and data.guard == escortGuard then
        escortPhase = 'waiting'
        doorPos = data.doorPos
        showMessage('escort_at_door')
    end
end

-- guard fought player, escort over
local function onEscortEnded(data)
    if escortGuard and data.guard == escortGuard then
        endCombat()
    end
end

-- engine reports back whether the trespass was actually witnessed
local function onTrespassResult(data)
    if data and data.seen then
        showMessage('escort_fled')
    else
        trespassPending = 2 * time.second
    end
end


return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        NightPatrol_GuardBusy        = onGuardBusy,
        NightPatrol_EscortConfirmed  = onEscortConfirmed,
        NightPatrol_NoShelter        = onNoShelter,
        NightPatrol_GuardAtDoor      = onGuardAtDoor,
        NightPatrol_EscortEnded      = onEscortEnded,
        NightPatrol_TrespassResult   = onTrespassResult,
    },
}