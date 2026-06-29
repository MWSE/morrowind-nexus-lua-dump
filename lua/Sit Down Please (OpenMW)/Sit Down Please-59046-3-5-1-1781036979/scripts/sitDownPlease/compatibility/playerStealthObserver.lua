-- compatibility/playerStealthObserver.lua
---@omw-context none

local M = {}

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function actorIsValid(actor)
    if not actor then return false end
    local ok, valid = pcall(function() return actor:isValid() end)
    return ok and valid == true
end

local function readPlayerStealthState(ctx)
    local player = ctx and ctx.player or nil
    local core = ctx and ctx.core or nil
    local types = ctx and ctx.types or nil
    local isSneaking = false
    local known = false
    local isMoving = false
    local isInvisible = false
    local chameleon = 0

    local okControls, controlsData = pcall(function()
        local controls = player and player.controls or nil
        if not controls then return nil end
        local sneak = nil
        if controls.sneak ~= nil then sneak = controls.sneak end
        if sneak == nil and controls.isSneaking ~= nil then sneak = controls.isSneaking end
        if sneak == nil and controls.sneaking ~= nil then sneak = controls.sneaking end

        local movement = tonumber(controls.movement or 0) or 0
        local sideMovement = tonumber(controls.sideMovement or 0) or 0
        return {
            sneak = sneak,
            moving = math.abs(movement) > 0.01 or math.abs(sideMovement) > 0.01,
        }
    end)

    if okControls and controlsData then
        local value = controlsData.sneak
        if value ~= nil then
            known = true
            if type(value) == "number" then
                isSneaking = value ~= 0
            else
                isSneaking = value == true
            end
        end
        isMoving = controlsData.moving == true
    end

    local okEffects = pcall(function()
        if not (types and types.Actor and types.Actor.activeEffects) then return end
        local activeEffects = types.Actor.activeEffects(player and player.object or nil)
        if not activeEffects then return end
        local magic = core and core.magic and core.magic.EFFECT_TYPE
        if not magic then return end
        local invisibility = activeEffects:getEffect(magic.Invisibility)
        isInvisible = invisibility ~= nil and tonumber(invisibility.magnitude or 0) > 0
        local cham = activeEffects:getEffect(magic.Chameleon)
        chameleon = cham and tonumber(cham.magnitude or 0) or 0
    end)
    if not okEffects then
        isInvisible = false
        chameleon = 0
    end

    return {
        isSneaking = isSneaking,
        known = known,
        isMoving = isMoving,
        isInvisible = isInvisible,
        chameleon = chameleon,
    }
end

function M.create(ctx)
    local state = {
        stealthPollTimer = 0,
        lastSneakState = nil,
        lastSneakKnown = nil,
        lastMoveState = nil,
        lastInvisibleState = nil,
        lastChameleonState = nil,
        sleepingActors = {},
    }

    local function publishStealthState(force)
        local stealth = readPlayerStealthState(ctx)
        if not force
            and stealth.isSneaking == state.lastSneakState
            and stealth.known == state.lastSneakKnown
            and stealth.isMoving == state.lastMoveState
            and stealth.isInvisible == state.lastInvisibleState
            and stealth.chameleon == state.lastChameleonState then
            return false
        end

        state.lastSneakState = stealth.isSneaking
        state.lastSneakKnown = stealth.known
        state.lastMoveState = stealth.isMoving
        state.lastInvisibleState = stealth.isInvisible
        state.lastChameleonState = stealth.chameleon

        if ctx and ctx.core and ctx.core.sendGlobalEvent then
            ctx.core.sendGlobalEvent('SitDownPleasePlayerStealthState', {
                player = ctx.player and ctx.player.object or nil,
                isSneaking = stealth.isSneaking,
                known = stealth.known,
                isMoving = stealth.isMoving,
                isInvisible = stealth.isInvisible,
                chameleon = stealth.chameleon,
            })
        end
        return true
    end

    local function clearSneakIsGoodNowStatus(actorId, reason)
        local interfaces = ctx and ctx.interfaces or nil
        local sig = interfaces and interfaces.SneakIsGoodNow
        local statuses = sig and sig.observerActorStatuses
        if not statuses then return false end

        local ast = statuses[actorId]
        if not ast then return false end

        ast.noticing = false
        ast.progress = 0.0
        ast.successRolls = 3
        ast.sneakChance = 100
        ast.isKnockedOut = true
        ast.inLOS = false

        if ast.marker then
            local ok = pcall(function()
                if ast.marker.destroy then
                    ast.marker:destroy()
                elseif ast.marker.disappear then
                    ast.marker:disappear(false, true)
                end
            end)
            if not ok then
                debugLog(ctx, "sneak compatibility marker cleanup failed", tostring(actorId), tostring(reason))
            end
            ast.marker = nil
        end

        statuses[actorId] = nil
        return true
    end

    local function suppressSleepingActors()
        for actorId, info in pairs(state.sleepingActors) do
            local actor = info and info.actor
            if not actorIsValid(actor) then
                state.sleepingActors[actorId] = nil
                clearSneakIsGoodNowStatus(actorId, "invalid_sleeping_actor")
            else
                clearSneakIsGoodNowStatus(actorId, info.reason or "sleeping")
            end
        end
    end

    return {
        sleepingActors = state.sleepingActors,
        publishStealthState = publishStealthState,
        clearSneakIsGoodNowStatus = clearSneakIsGoodNowStatus,
        suppressSleepingActors = suppressSleepingActors,
        update = function(dt)
            suppressSleepingActors()
            state.stealthPollTimer = state.stealthPollTimer + (tonumber(dt) or 0)
            if state.stealthPollTimer < 0.5 then return false end
            state.stealthPollTimer = 0
            return publishStealthState(false)
        end,
        setSleepingActor = function(data)
            if not data then return nil end
            local actor = data.actor
            local actorId = data.actorId or (actor and actor.id)
            if not actorId then return nil end

            if data.sleeping == true then
                state.sleepingActors[actorId] = { actor = actor, recordId = data.recordId, reason = data.reason }
                suppressSleepingActors()
                return actorId, true
            end

            state.sleepingActors[actorId] = nil
            clearSneakIsGoodNowStatus(actorId, data.reason or "sleeping_actor_cleared")
            return actorId, false
        end,
        isActorSleeping = function(actor)
            return actor and actor.id and state.sleepingActors[actor.id] ~= nil or false
        end,
    }
end

return M
