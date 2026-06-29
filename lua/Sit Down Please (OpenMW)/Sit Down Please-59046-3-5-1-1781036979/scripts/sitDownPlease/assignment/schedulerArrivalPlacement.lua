-- assignment/schedulerArrivalPlacement.lua
---@omw-context none
-- Optional integration boundary for scheduler-arrived NPCs. The caller supplies
-- actors that another mod just enabled in the current cell; this module builds
-- SDP candidates once, chooses cell-wide slots, and hands off through the normal
-- SDP claim/local-placement path.

local M = {}

local function lower(value)
    if value == nil then return "" end
    return tostring(value):lower()
end

local function cellName(ctx, cell)
    if ctx and type(ctx.cellName) == "function" then return ctx.cellName(cell) end
    return cell and tostring(cell.name or cell.id or "") or ""
end

local function sameCell(ctx, actor, cell, expectedName)
    if not (actor and actor.cell and cell) then return false end
    if actor.cell ~= cell then return false end
    if expectedName and expectedName ~= "" and lower(cellName(ctx, cell)) ~= expectedName then return false end
    return true
end

local function actorId(actor)
    return actor and actor.id or nil
end

local function actorLabel(actor)
    return tostring(actor and (actor.recordId or actor.id) or "<actor>")
end

local function actorList(payload)
    local list = {}
    for _, actor in ipairs(payload and payload.actors or {}) do
        list[#list + 1] = actor
    end
    for _, item in ipairs(payload and payload.items or {}) do
        if item and item.actor then list[#list + 1] = item.actor end
    end
    return list
end

local function interactionOrder(ctx)
    local settings = ctx.settings or {}
    local profiles = ctx.profiles
    local hour = profiles.getGameHour()
    if settings.enableSleeping == true
        and profiles.isHourInWindow(hour, settings.sleepStartHour, settings.sleepEndHour) then
        return { "sleeping", "sitting" }
    end
    return { "sitting", "sleeping" }
end

local function enabled(ctx, interactionType)
    local settings = ctx.settings or {}
    if interactionType == "sleeping" then return settings.enableSleeping == true end
    if interactionType == "sitting" then return settings.enableSitting == true end
    return false
end

local function candidatePosition(candidate)
    return candidate and (candidate.position or (candidate.object and candidate.object.position)) or nil
end

local function candidateScore(ctx, npc, candidate, source)
    local profiles = ctx.profiles
    local key = tostring(source or "scheduler_arrival")
        .. "|actor=" .. tostring(actorId(npc) or npc and npc.recordId or "")
        .. "|object=" .. tostring(candidate and candidate.objectId or "")
        .. "|slot=" .. tostring(candidate and candidate.slotName or "")
    local randomScore = profiles.stableUnitInterval(key)
    local pos = candidatePosition(candidate)
    local distance = 0
    if npc and npc.position and pos then
        distance = (npc.position - pos):length()
    end
    -- Keep selection cell-wide, but use a tiny distance term to avoid absurd
    -- far-corner picks when several random scores are nearly tied.
    local distanceTerm = math.min(distance / 120000, 0.08)
    return randomScore + distanceTerm
end

local function candidateAvailable(ctx, npc, candidate)
    if not (candidate and candidate.object and candidate.slotKey) then return false end
    if ctx.isObjValid and not ctx.isObjValid(candidate.object) then return false end
    if ctx.slotOwnership and ctx.slotOwnership.claimedByOther then
        local claimed = ctx.slotOwnership.claimedByOther(candidate.slotKey, npc, ctx.occupiedSlots(), ctx.assignedActors())
        if claimed then return false end
    end
    return true
end

local function chooseCellWideCandidate(ctx, npc, candidates, source)
    local bestIndex = nil
    local bestScore = nil
    for i, candidate in ipairs(candidates or {}) do
        if candidateAvailable(ctx, npc, candidate) then
            local score = candidateScore(ctx, npc, candidate, source)
            if bestScore == nil or score < bestScore then
                bestScore = score
                bestIndex = i
            end
        end
    end
    if not bestIndex then return nil end
    local candidate = candidates[bestIndex]
    table.remove(candidates, bestIndex)
    return candidate
end

local function positionKey(pos)
    if not pos then return nil end
    local x = math.floor((tonumber(pos.x) or 0) / 48)
    local y = math.floor((tonumber(pos.y) or 0) / 48)
    local z = math.floor((tonumber(pos.z) or 0) / 48)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function addStandTarget(ctx, npc, targets, seen, candidate, source)
    local pos = candidate and (candidate.approachPos or candidate.position or (candidate.object and candidate.object.position)) or nil
    local key = positionKey(pos)
    if not key or seen[key] then return end
    seen[key] = true
    targets[#targets + 1] = {
        position = pos,
        objectId = candidate.objectId,
        slotName = candidate.slotName,
        interactionType = candidate.interactionType,
        score = candidateScore(ctx, npc, candidate, source),
    }
end

local function standTargets(ctx, npc, candidateLists, source)
    local targets = {}
    local seen = {}
    for _, interactionType in ipairs({ "sleeping", "sitting" }) do
        for _, candidate in ipairs(candidateLists[interactionType] or {}) do
            addStandTarget(ctx, npc, targets, seen, candidate, source)
        end
    end
    table.sort(targets, function(a, b) return (a.score or 0) < (b.score or 0) end)
    local limited = {}
    for i = 1, math.min(#targets, 4) do
        limited[#limited + 1] = {
            position = targets[i].position,
            objectId = targets[i].objectId,
            slotName = targets[i].slotName,
            interactionType = targets[i].interactionType,
        }
    end
    return limited
end

local function requestStandDispersal(ctx, npc, cell, candidateLists, source, reason)
    if type(ctx.requestStandDispersal) ~= "function" then return false end
    local targets = standTargets(ctx, npc, candidateLists or {}, source)
    if #targets <= 0 then return false end
    return ctx.requestStandDispersal(npc, cell, targets, source, reason) == true
end

local function sleepingTiming(ctx, npc, cell, source)
    if type(ctx.sleepEligibilityForNpc) ~= "function" then return true, nil, nil end
    return ctx.sleepEligibilityForNpc(npc, cell, {
        source = source,
        sleepInitialPlacementAllowed = true,
        initialPlacementAllowed = true,
        allowDueBedtimeInitialPlacement = true,
        schedulerArrivalPlacement = true,
    })
end

local function prepareCandidate(ctx, candidate, interactionType, timing)
    local prepared = ctx.profiles.shallowCopy(candidate)
    prepared.initialPlacement = true
    prepared.schedulerArrivalPlacement = true
    prepared.suppressInitialPlacementOverlay = true
    if interactionType == "sleeping" then
        prepared.sleepPhase = timing and timing.phase or nil
        prepared.actorBedtime = timing and timing.actorBedtime or nil
        prepared.actorWakeTime = timing and timing.actorWakeTime or nil
        prepared.sleepWakeBias = timing and timing.wakeBias or nil
        prepared.observedPlayerOverride = timing and timing.observedPlayerOverride or nil
    end
    return prepared
end

local function assignActor(ctx, npc, cell, candidateLists, order, source, stats)
    if not (npc and actorId(npc)) then stats.invalid = stats.invalid + 1; return false end
    if not sameCell(ctx, npc, cell, stats.expectedCellName) then stats.wrongCell = stats.wrongCell + 1; return false end
    if ctx.assignedActors()[actorId(npc)] then stats.alreadyAssigned = stats.alreadyAssigned + 1; return false end
    if ctx.isNpcObjectValidForAssignment and not ctx.isNpcObjectValidForAssignment(npc) then
        stats.ineligible = stats.ineligible + 1
        return false
    end

    local hadEligibleInteraction = false
    local hadIneligibleInteraction = false
    for _, interactionType in ipairs(order) do
        if enabled(ctx, interactionType) then
            local eligible, reason = ctx.isNpcEligibleForInteraction(npc, interactionType)
            local timing = nil
            if eligible and interactionType == "sleeping" then
                eligible, reason, timing = sleepingTiming(ctx, npc, cell, source)
            end
            if eligible then
                hadEligibleInteraction = true
                local candidates = candidateLists[interactionType]
                local attempts = 0
                while candidates and #candidates > 0 and attempts < 4 do
                    attempts = attempts + 1
                    local candidate = chooseCellWideCandidate(ctx, npc, candidates, source)
                    if not candidate then break end
                    local prepared = prepareCandidate(ctx, candidate, interactionType, timing)
                    local ok, sendReason = ctx.sendConsiderInteraction(npc, prepared)
                    if ok then
                        stats.assigned = stats.assigned + 1
                        if interactionType == "sleeping" then stats.sleeping = stats.sleeping + 1 end
                        if interactionType == "sitting" then stats.sitting = stats.sitting + 1 end
                        return true
                    end
                    stats.sendRejected = stats.sendRejected + 1
                    if ctx.debugLog then
                        ctx.debugLog(
                            "scheduler arrival candidate rejected",
                            actorLabel(npc),
                            "type", tostring(interactionType),
                            "object", tostring(candidate.objectId),
                            "slot", tostring(candidate.slotName),
                            "reason", tostring(sendReason)
                        )
                    end
                end
            else
                hadIneligibleInteraction = true
                if ctx.debugLog then
                    ctx.debugLog(
                        "scheduler arrival skip npc",
                        actorLabel(npc),
                        "type", tostring(interactionType),
                        "reason", tostring(reason)
                    )
                end
            end
        end
    end
    if requestStandDispersal(ctx, npc, cell, candidateLists, source, hadEligibleInteraction and "no_sit_sleep_candidate" or "sit_sleep_ineligible") then
        stats.dispersed = stats.dispersed + 1
        return true
    elseif hadEligibleInteraction then
        stats.noCandidate = stats.noCandidate + 1
    elseif hadIneligibleInteraction then
        stats.ineligible = stats.ineligible + 1
    end
    return false
end

function M.request(ctx, payload)
    local cell = ctx.currentCell and ctx.currentCell() or nil
    local actors = actorList(payload or {})
    local stats = {
        requested = #actors,
        considered = 0,
        assigned = 0,
        sleeping = 0,
        sitting = 0,
        dispersed = 0,
        alreadyAssigned = 0,
        invalid = 0,
        wrongCell = 0,
        ineligible = 0,
        noCandidate = 0,
        sendRejected = 0,
        expectedCellName = lower(payload and payload.cellName or ""),
    }

    if not cell then return stats end
    if stats.expectedCellName ~= "" and lower(cellName(ctx, cell)) ~= stats.expectedCellName then
        stats.wrongCell = stats.requested
        return stats
    end

    local order = interactionOrder(ctx)
    local candidateLists = {}
    for _, interactionType in ipairs(order) do
        if enabled(ctx, interactionType) then
            candidateLists[interactionType] = ctx.buildCandidateSlots(cell, interactionType)
        end
    end

    local maxActors = tonumber(payload and payload.maxActors or 24) or 24
    local source = tostring(payload and payload.source or "scheduler_arrival")
    for _, npc in ipairs(actors) do
        if stats.considered >= maxActors then break end
        stats.considered = stats.considered + 1
        assignActor(ctx, npc, cell, candidateLists, order, source, stats)
    end

    if ctx.infoLog then
        ctx.infoLog(
            "scheduler arrival placement",
            "source", source,
            "cell", cellName(ctx, cell),
            "requested", tostring(stats.requested),
            "considered", tostring(stats.considered),
            "assigned", tostring(stats.assigned),
            "sleeping", tostring(stats.sleeping),
            "sitting", tostring(stats.sitting),
            "dispersed", tostring(stats.dispersed),
            "noCandidate", tostring(stats.noCandidate),
            "ineligible", tostring(stats.ineligible)
        )
    end

    return stats
end

function M.targetsForActor(ctx, npc, cell, source)
    local candidateLists = {}
    for _, interactionType in ipairs({ "sleeping", "sitting" }) do
        if enabled(ctx, interactionType) then
            candidateLists[interactionType] = ctx.buildCandidateSlots(cell, interactionType)
        end
    end
    return standTargets(ctx, npc, candidateLists, tostring(source or "scheduler_arrival_fallback"))
end

return M
