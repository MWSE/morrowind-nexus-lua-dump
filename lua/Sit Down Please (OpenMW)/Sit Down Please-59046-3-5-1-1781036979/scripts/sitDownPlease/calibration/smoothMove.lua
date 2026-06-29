-- calibration/smoothMove.lua
---@omw-context none
-- Runtime owner for short scripted actor smoothing.

local M = {}

local DEFAULT_DURATION = 0.20
local DEFAULT_STEP_SECONDS = 0.016
local DEFAULT_BUSY_RETRY_SECONDS = 0.015

local function smoothReason(reason)
    local text = tostring(reason or "")
        return text == "developer_menu"
        or text == "menu_nudge"
        or text == "station_presenter_entry"
        or text == "station_dialogue_facing_restore"
        or text == "animated_morrowind_alignment_assist"
        or text:find("nudge", 1, true) ~= nil
end

local function yawDeltaShortest(fromYaw, toYaw)
    fromYaw = tonumber(fromYaw) or 0
    toYaw = tonumber(toYaw) or fromYaw
    local delta = (toYaw - fromYaw) % (math.pi * 2)
    if delta > math.pi then delta = delta - (math.pi * 2) end
    return delta
end

function M.create(ctx)
    ctx = ctx or {}
    local moves = {}
    local durationDefault = tonumber(ctx.duration) or DEFAULT_DURATION
    local stepSeconds = tonumber(ctx.stepSeconds) or DEFAULT_STEP_SECONDS
    local busyRetrySeconds = tonumber(ctx.busyRetrySeconds) or DEFAULT_BUSY_RETRY_SECONDS

    local controller = {}

    function controller.reason(reason)
        return smoothReason(reason)
    end

    function controller.yawDelta(fromYaw, toYaw)
        return yawDeltaShortest(fromYaw, toYaw)
    end

    function controller.queue(npc, data, finalPosition, finalRotation, label, reason, options)
        options = options or {}
        if not smoothReason(reason) then return false end
        if not (npc and npc.id and data and finalPosition) then return false end
        if options.skipStateCheck ~= true and ctx.isInteractionState and not ctx.isInteractionState(data) then return false end

        local startPosition = npc.position
        local startYaw = npc.rotation and npc.rotation.getYaw and npc.rotation:getYaw() or finalRotation or 0
        local finalYaw = tonumber(finalRotation) or startYaw
        local distance = startPosition and (startPosition - finalPosition):length() or 0
        local yawDistance = math.abs(yawDeltaShortest(startYaw, finalYaw))
        if distance < 0.25 and yawDistance < math.rad(0.25) then return false end

        local now = ctx.now and ctx.now() or 0
        local duration = tonumber(options.duration) or durationDefault
        moves[npc.id] = {
            npc = npc,
            data = data,
            startPosition = startPosition,
            finalPosition = finalPosition,
            startYaw = startYaw,
            finalYaw = finalYaw,
            yawDelta = yawDeltaShortest(startYaw, finalYaw),
            startedAt = now - (duration * 0.10),
            lastStepAt = 0,
            nextStepAt = now,
            duration = duration,
            label = label or "calibration",
            reason = reason or "calibration",
            skipStateCheck = options.skipStateCheck == true,
            isActive = options.isActive,
        }
        return true
    end

    function controller.active(npcId)
        return npcId ~= nil and moves[npcId] ~= nil
    end

    function controller.process()
        if next(moves) == nil then return end
        local now = ctx.now and ctx.now() or 0
        for npcId, move in pairs(moves) do
            local npc = move.npc
            local data = move.data
            local active = false
            if move.isActive then
                local okActive, activeValue = pcall(move.isActive, npc, data, npcId)
                active = okActive and activeValue == true
            elseif ctx.assignedActorFor then
                active = ctx.assignedActorFor(npcId) == data
            end
            if not (ctx.isObjValid and ctx.isObjValid(npc) and data and active and move.startPosition and move.finalPosition) then
                moves[npcId] = nil
            elseif move.skipStateCheck ~= true and ctx.isInteractionState and not ctx.isInteractionState(data) then
                moves[npcId] = nil
            elseif move.nextStepAt and now < move.nextStepAt then
                -- wait for OpenMW's previous accepted teleport to settle
            elseif move.lastStepAt ~= 0 and now - move.lastStepAt < stepSeconds then
                -- wait for the next small step
            else
                local duration = tonumber(move.duration) or durationDefault
                if duration <= 0 then duration = durationDefault end
                local t = math.min(1, math.max(0, (now - (move.startedAt or now)) / duration))
                local eased = t * t * (3 - (2 * t))
                local pos = move.startPosition + ((move.finalPosition - move.startPosition) * eased)
                local yaw = (tonumber(move.startYaw) or 0) + ((tonumber(move.yawDelta) or 0) * eased)
                local ok, err = ctx.tryTeleport(npc, npc.cell, pos, { rotation = ctx.rotationFromYaw(yaw, npc.rotation) })
                move.lastStepAt = now
                if not ok then
                    if not (ctx.deferTeleportFailure and ctx.deferTeleportFailure(data, err, tostring(move.label or "calibration_smooth"))) then
                        if ctx.debugLog then ctx.debugLog(tostring(move.label or "calibration") .. " smooth teleport failed", npc.recordId or npc.id, tostring(err)) end
                        moves[npcId] = nil
                    else
                        move.nextStepAt = now + busyRetrySeconds
                        move.startPosition = npc.position or move.startPosition
                        move.startYaw = npc.rotation and npc.rotation.getYaw and npc.rotation:getYaw() or move.startYaw
                        move.yawDelta = yawDeltaShortest(move.startYaw, move.finalYaw)
                        move.startedAt = now - (duration * 0.18)
                    end
                else
                    data.teleportBusySkips = nil
                    data.teleportBusyFirstAt = nil
                    move.nextStepAt = now + stepSeconds
                    if t >= 1 then moves[npcId] = nil end
                end
            end
        end
    end

    function controller.reset()
        moves = {}
    end

    return controller
end

M.reason = smoothReason
M.yawDelta = yawDeltaShortest

return M
