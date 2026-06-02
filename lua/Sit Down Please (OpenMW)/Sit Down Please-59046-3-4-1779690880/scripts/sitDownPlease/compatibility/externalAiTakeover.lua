-- compatibility/externalAiTakeover.lua
-- Small helpers for distinguishing Sit Down Please-owned AI movement from
-- external AI movement.

local module = {}

local EXTERNAL_INCAPACITATION_SPELLS = {
    detd_sleep_spell = "external_incapacitation_spell",
    detd_sleepspellenchat = "external_incapacitation_spell",
    detd_sleep_spell3 = "external_incapacitation_spell",
}

local EXTERNAL_CONTROL_SCRIPTS = {
    ["scripts/gnddys_local.lua"] = "external_control_script",
    ["scripts/bh_npc.lua"] = "external_control_script",
    ["scripts/bh_npc_reward.lua"] = "external_control_script",
    ["scripts/pause-control/actor.lua"] = "external_control_script",
}

function module.packageDestination(pkg)
    if not pkg then return nil end
    return pkg.destPosition or pkg.destination
end

local function actorHasScript(actor, scriptPath)
    if not (actor and actor.hasScript and scriptPath) then return false end
    local ok, has = pcall(function() return actor:hasScript(scriptPath) end)
    return ok and has == true
end

local function near(a, b, radius)
    if not (a and b) then return false end
    local ok, dist = pcall(function() return (a - b):length() end)
    return ok and dist <= radius
end

function module.newTracker()
    local tracker = {}

    function tracker:reset()
    end

    function tracker:travelDecision(params)
        params = params or {}
        local pkg = params.pkg
        if not (pkg and pkg.type == "Travel") then
            self:reset()
            return false, nil, { action = "not_travel" }
        end

        local pkgDest = module.packageDestination(pkg)
        local targetPos = params.targetPos
        local actorPosition = params.actorPosition
        local currentInteractionTravelDest = params.currentInteractionTravelDest
        local ownsFreshSleepTravel = params.ownTravelGrace == true and params.interactionType == "sleeping"

        if currentInteractionTravelDest
            and near(currentInteractionTravelDest, pkgDest, tonumber(params.ownTravelRadius or 180) or 180) then
            self:reset()
            return false, nil, { action = "own_recorded_sleep_travel", dest = pkgDest }
        end

        if near(targetPos, pkgDest, tonumber(params.targetRadius or 120) or 120) then
            if params.interactionType ~= "sleeping"
                or ownsFreshSleepTravel
                or (params.initialPlacement == true and (tonumber(params.interactionElapsed or 0) or 0) <= (tonumber(params.initialPlacementGrace or 8) or 8)) then
                self:reset()
                return false, nil, { action = "own_target_travel", dest = pkgDest }
            end
        end

        if params.interactionType == "sleeping"
            and actorPosition
            and near(actorPosition, pkgDest, tonumber(params.noopTravelRadius or 90) or 90) then
            self:reset()
            return false, nil, { action = "external_noop_travel", dest = pkgDest }
        end

        if ownsFreshSleepTravel and not pkgDest then
            self:reset()
            return false, nil, { action = "own_recent_sleep_travel_no_dest" }
        end

        -- Initial-placement sleep deliberately ignores destinationless Travel
        -- noise because it is not a meaningful movement takeover. Travel with a
        -- real destination that was not started by Sit Down Please is external
        -- schedule/quest/mod control and should release the sleeper.
        if params.interactionType == "sleeping"
            and params.initialPlacement == true
            and not pkgDest then
            self:reset()
            return false, nil, { action = "initial_sleep_travel_no_dest" }
        end

        self:reset()
        return true, "external_travel_takeover", {
            action = "external_travel_takeover",
            dest = pkgDest,
            interactionElapsed = tonumber(params.interactionElapsed or 0) or 0,
        }
    end

    return tracker
end

function module.stopReasonPreservesExternalTravel(reason)
    local text = tostring(reason or "")
    return text == "other_travel"
        or text == "external_travel_takeover"
        or text == "other_ai_package"
        or text == "follow_or_escort"
        or text == "follow"
        or text == "escort"
        or text == "combat"
        or text:find("^external_", 1) ~= nil
end

function module.sleepReleaseShouldUseBedsideExit(reason)
    local text = tostring(reason or "")
    return text == "external_travel_takeover"
        or text == "other_travel"
        or text == "other_ai_package"
        or text == "follow_or_escort"
        or text == "follow"
        or text == "escort"
        or text == "combat"
        or text == "active_non_idle_stance"
end

function module.externalControlScriptReason(actor)
    for scriptPath, reason in pairs(EXTERNAL_CONTROL_SCRIPTS) do
        if actorHasScript(actor, scriptPath) then
            return reason, scriptPath
        end
    end
    return nil
end

function module.activeNonIdleStanceReason(actor, typesApi)
    if not (actor and typesApi and typesApi.Actor and typesApi.Actor.getStance) then return nil end
    local ok, stance = pcall(typesApi.Actor.getStance, actor)
    if not ok then return nil end

    local stanceConst = typesApi.Actor.STANCE or {}
    local weapon = stanceConst.Weapon or 1
    local spell = stanceConst.Spell or 2
    if stance == weapon or stance == spell or stance == 1 or stance == 2 then
        return "active_non_idle_stance", stance
    end
    return nil
end

function module.activeControlInputReason(actor, controls)
    if not controls then return nil end

    local movement = tonumber(controls.movement or 0) or 0
    if math.abs(movement) > 0.05 then return "external_control_movement", movement end

    local sideMovement = tonumber(controls.sideMovement or 0) or 0
    if math.abs(sideMovement) > 0.05 then return "external_control_side_movement", sideMovement end

    if controls.jump == true then return "external_control_jump", true end

    local noAttack = actor and actor.ATTACK_TYPE and actor.ATTACK_TYPE.NoAttack or 0
    local use = tonumber(controls.use)
    if use and use ~= noAttack and use ~= 0 then
        return "external_control_use", use
    end

    return nil
end

function module.externalIncapacitationReason(actor, typesApi)
    if not (actor and typesApi and typesApi.Actor and typesApi.Actor.activeSpells) then return nil end
    local okSpells, spells = pcall(typesApi.Actor.activeSpells, actor)
    if not (okSpells and spells and spells.isSpellActive) then return nil end

    for spellId, reason in pairs(EXTERNAL_INCAPACITATION_SPELLS) do
        local okActive, active = pcall(function()
            return spells:isSpellActive(spellId)
        end)
        if okActive and active == true then
            return reason, spellId
        end
    end

    return nil
end

return module
