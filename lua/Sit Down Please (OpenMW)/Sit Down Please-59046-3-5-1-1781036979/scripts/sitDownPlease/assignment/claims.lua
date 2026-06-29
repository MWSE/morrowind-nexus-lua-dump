-- assignment/claims.lua
---@omw-context none
-- Runtime-only claim registries for SDP-owned targets.

local M = {}

local function stringify(value)
    return value ~= nil and tostring(value) or nil
end

function M.actorId(actor)
    if type(actor) == "string" then return actor end
    if actor and actor.id then return tostring(actor.id) end
    if actor and actor.recordId then return tostring(actor.recordId) end
    return nil
end

function M.actorLabel(actor)
    if type(actor) == "string" then return actor end
    return tostring(actor and (actor.recordId or actor.id) or "<actor>")
end

function M.targetKey(ctx, obj, slotName, claimType)
    local slot = tostring(slotName or claimType or "default")
    if ctx and ctx.objectSlotKey then
        return ctx.objectSlotKey(obj, slot)
    end
    return tostring(obj and (obj.id or obj.recordId) or "<target>") .. "::" .. slot
end

function M.createRegistry(defaults)
    defaults = defaults or {}
    local byTarget = {}
    local byActor = {}
    local R = {
        byTarget = byTarget,
        byActor = byActor,
    }

    function R:get(targetKey)
        return targetKey and byTarget[targetKey] or nil
    end

    function R:isClaimed(targetKey)
        return targetKey ~= nil and byTarget[targetKey] ~= nil
    end

    function R:actorTarget(actorOrId)
        local actorKey = M.actorId(actorOrId)
        return actorKey and byActor[actorKey] or nil
    end

    function R:actorClaim(actorOrId)
        local targetKey = self:actorTarget(actorOrId)
        return targetKey and byTarget[targetKey] or nil
    end

    function R:claim(targetKey, actor, data, options)
        options = options or {}
        if not targetKey then return false, "missing_claim_key" end
        local actorKey = M.actorId(actor) or stringify(options.actorId)
        local existing = byTarget[targetKey]
        if existing and options.replaceExisting ~= true then
            return false, "target_already_claimed", existing
        end
        if actorKey and byActor[actorKey] and byActor[actorKey] ~= targetKey and options.replaceExisting ~= true then
            return false, "actor_already_claims_target", byActor[actorKey]
        end
        if existing then self:release(targetKey, nil, "claim_replaced") end

        data = data or {}
        data.claim = {
            targetKey = targetKey,
            actorId = actorKey,
            actorRecordId = actor and actor.recordId or nil,
            claimType = options.claimType or defaults.claimType or "target",
            source = options.source or defaults.source or "runtime",
            reason = options.reason or defaults.reason or "claimed",
            claimedAt = options.claimedAt or options.now,
        }
        byTarget[targetKey] = data
        if actorKey then byActor[actorKey] = targetKey end
        return true, data
    end

    function R:release(targetKey, actorOrId, reason)
        if not targetKey then return false end
        local data = byTarget[targetKey]
        if not data then return false end
        local expectedActor = M.actorId(actorOrId)
        local claimActor = data.claim and data.claim.actorId or M.actorId(data.npc)
        if expectedActor and claimActor and expectedActor ~= claimActor then
            return false, "claim_actor_mismatch", data
        end
        byTarget[targetKey] = nil
        if claimActor and byActor[claimActor] == targetKey then byActor[claimActor] = nil end
        if data.claim then data.claim.releaseReason = reason or "released" end
        return true, data
    end

    function R:releaseForActor(actorOrId, reason)
        local targetKey = self:actorTarget(actorOrId)
        if not targetKey then return false end
        return self:release(targetKey, actorOrId, reason)
    end

    function R:clear()
        for key in pairs(byTarget) do byTarget[key] = nil end
        for key in pairs(byActor) do byActor[key] = nil end
    end

    return R
end

return M
