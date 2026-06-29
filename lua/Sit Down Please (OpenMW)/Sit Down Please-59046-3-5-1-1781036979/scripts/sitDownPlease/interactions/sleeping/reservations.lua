-- interactions/sleeping/reservations.lua
---@omw-context none
-- Runtime-only bed reservation ledger for preventing same-night pileups.

local M = {}

local DEFAULT_RESERVATION_SECONDS = 12 * 60
local DEFAULT_FAILED_SECONDS = 90

local function ownerLabel(reservation)
    return reservation and tostring(reservation.npcRecordId or reservation.npcId or "<none>") or "<none>"
end

function M.create(ctx)
    ctx = ctx or {}
    local reservations = {}
    local byNpc = {}
    local ttlDefault = tonumber(ctx.ttl) or DEFAULT_RESERVATION_SECONDS
    local failedTtl = tonumber(ctx.failedTtl) or DEFAULT_FAILED_SECONDS

    local controller = {}

    local function now()
        return ctx.now and ctx.now() or (ctx.realTimeNow and ctx.realTimeNow()) or 0
    end

    function controller.npcId(npc)
        return npc and tostring(npc.id or npc.recordId or "<npc>") or nil
    end

    function controller.ownerLabel(reservation)
        return ownerLabel(reservation)
    end

    function controller.releaseBySlot(slotKey, reason, expectedNpcId)
        if not slotKey then return end
        local reservation = reservations[slotKey]
        if not reservation then return end
        if expectedNpcId and reservation.npcId and reservation.npcId ~= expectedNpcId then return end
        reservations[slotKey] = nil
        if reservation.npcId and byNpc[reservation.npcId] == slotKey then byNpc[reservation.npcId] = nil end
        if ctx.sleepLightControl and ctx.sleepLightControl.clearPendingSleeper then
            ctx.sleepLightControl.clearPendingSleeper(
                reservation.npcId,
                reason or "reservation_released",
                tostring(reason or ""):find("reject", 1, true) ~= nil or tostring(reason or ""):find("failed", 1, true) ~= nil
            )
        end
        if ctx.debugLog then
            ctx.debugLog("sleep reservation released", ownerLabel(reservation), "slot", tostring(slotKey), "reason", tostring(reason or "released"))
        end
    end

    function controller.releaseForNpc(npcOrId, reason)
        local npcId = type(npcOrId) == "string" and npcOrId or controller.npcId(npcOrId)
        if not npcId then return end
        local slotKey = byNpc[npcId]
        if slotKey then controller.releaseBySlot(slotKey, reason, npcId) end
    end

    function controller.reserve(npc, candidate, reason, state, ttl)
        if not (npc and candidate and candidate.slotKey) then return nil end
        local npcId = controller.npcId(npc)
        if not npcId then return nil end

        local existingSlot = byNpc[npcId]
        local expiresIn = tonumber(ttl or ttlDefault) or ttlDefault
        if existingSlot and existingSlot == candidate.slotKey and reservations[existingSlot] then
            local reservation = reservations[existingSlot]
            reservation.npc = npc
            reservation.object = candidate.object or reservation.object
            reservation.objectId = candidate.objectId or reservation.objectId
            reservation.state = state or reservation.state or "assigned"
            reservation.reason = reason or reservation.reason or "normal_assignment"
            reservation.expiresAt = now() + expiresIn
            if ctx.settings and ctx.settings.debug and ctx.debugLog then
                ctx.debugLog(
                    "sleep reservation reused",
                    reservation.npcRecordId,
                    "slot", tostring(candidate.slotKey),
                    "object", tostring(candidate.objectId),
                    "state", tostring(reservation.state),
                    "reason", tostring(reservation.reason),
                    "seconds", tostring(expiresIn)
                )
            end
            return reservation
        end
        if existingSlot and existingSlot ~= candidate.slotKey then
            controller.releaseBySlot(existingSlot, "npc_reassigned_bed", npcId)
        end

        local reservation = {
            bedKey = candidate.slotKey,
            slotKey = candidate.slotKey,
            npc = npc,
            npcId = npcId,
            npcRecordId = npc.recordId or npc.id,
            cellName = ctx.cellName and ctx.cellName(npc.cell) or nil,
            objectId = candidate.objectId,
            object = candidate.object,
            state = state or "assigned",
            reason = reason or "normal_assignment",
            reservedAt = now(),
            expiresAt = now() + expiresIn,
            lastFailureReason = nil,
        }
        reservations[candidate.slotKey] = reservation
        byNpc[npcId] = candidate.slotKey
        if ctx.sleepLightControl and ctx.sleepLightControl.registerPendingSleeper then
            ctx.sleepLightControl.registerPendingSleeper(npc, {
                object = candidate.object,
                bed = candidate.object,
                bedId = candidate.objectId,
                position = candidate.object and candidate.object.position or npc.position,
                approachPosition = candidate.approachPos,
                originPosition = candidate.preInteractionPos,
                initialPlacement = candidate.initialPlacement == true,
                state = state or "assigned",
            })
        end
        if ctx.debugLog then
            ctx.debugLog(
                "sleep reservation created",
                reservation.npcRecordId,
                "slot", tostring(candidate.slotKey),
                "object", tostring(candidate.objectId),
                "state", tostring(reservation.state),
                "reason", tostring(reservation.reason),
                "seconds", tostring(expiresIn)
            )
        end
        return reservation
    end

    function controller.updateState(npcOrId, state, reason, ttl)
        local npcId = type(npcOrId) == "string" and npcOrId or controller.npcId(npcOrId)
        if not npcId then return nil end
        local slotKey = byNpc[npcId]
        local reservation = slotKey and reservations[slotKey] or nil
        if not reservation then return nil end
        reservation.state = state or reservation.state
        reservation.lastReason = reason or reservation.lastReason
        if ttl then reservation.expiresAt = now() + ttl end
        if ctx.debugLog then
            ctx.debugLog("sleep reservation state", ownerLabel(reservation), "slot", tostring(slotKey), "state", tostring(reservation.state), "reason", tostring(reason or reservation.lastReason or "update"))
        end
        return reservation
    end

    function controller.markFailed(npc, slotKey, reason)
        local npcId = controller.npcId(npc)
        local reservation = slotKey and reservations[slotKey] or (npcId and reservations[byNpc[npcId]] or nil)
        if not reservation then return end
        if npcId and reservation.npcId ~= npcId then return end
        reservation.state = "failed_cooldown"
        reservation.lastFailureReason = reason or "failed"
        reservation.expiresAt = now() + failedTtl
        if ctx.sleepLightControl and ctx.sleepLightControl.clearPendingSleeper then
            ctx.sleepLightControl.clearPendingSleeper(reservation.npcId, reason or "sleep_reservation_failed", true)
        end
        if ctx.debugLog then
            ctx.debugLog("sleep reservation failed cooldown", ownerLabel(reservation), "slot", tostring(reservation.slotKey), "reason", tostring(reason or "failed"), "seconds", tostring(failedTtl))
        end
    end

    function controller.forCandidate(candidate)
        if not (candidate and candidate.slotKey) then return nil end
        local reservation = reservations[candidate.slotKey]
        if not reservation then return nil end
        if reservation.expiresAt and now() > reservation.expiresAt then
            controller.releaseBySlot(candidate.slotKey, "expired")
            return nil
        end
        return reservation
    end

    function controller.reservedByOther(npc, candidate)
        local reservation = controller.forCandidate(candidate)
        if not reservation then return false, nil end
        local npcId = controller.npcId(npc)
        if npcId and reservation.npcId == npcId then return false, reservation end
        return true, reservation
    end

    function controller.prune(reason)
        local current = now()
        for slotKey, reservation in pairs(reservations) do
            local expired = reservation.expiresAt and current > reservation.expiresAt
            local invalidNpc = reservation.npc ~= nil and not (ctx.isObjValid and ctx.isObjValid(reservation.npc))
            local invalidObject = reservation.object ~= nil and not (ctx.isObjValid and ctx.isObjValid(reservation.object))
            if expired or invalidNpc or invalidObject then
                controller.releaseBySlot(slotKey, expired and "expired" or invalidNpc and "npc_invalid" or invalidObject and "bed_invalid" or reason)
            end
        end
    end

    function controller.existsForNpc(npc)
        local npcId = controller.npcId(npc)
        return npcId ~= nil and byNpc[npcId] ~= nil
    end

    function controller.reservedSlotForNpc(npc)
        local npcId = controller.npcId(npc)
        return npcId and byNpc[npcId] or nil
    end

    function controller.reset()
        reservations = {}
        byNpc = {}
    end

    return controller
end

return M
