-- compatibility/animatedMorrowindSeeker.lua
---@omw-context local
-- Local NPC-side alignment responder for Animated Morrowind seated actors.

local compat = require('scripts/sitDownPlease/compatibility/animatedMorrowind')

local M = {}

local function settingsFrom(ctx)
    if ctx and type(ctx.settings) == "function" then return ctx.settings() end
    return ctx and ctx.settings or {}
end

local function actor(ctx)
    if ctx and type(ctx.actor) == "function" then return ctx.actor() end
    return ctx and ctx.actor or nil
end

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function sendResult(ctx, payload)
    payload = payload or {}
    local npc = actor(ctx)
    payload.npc = npc
    payload.recordId = npc and npc.recordId or nil
    local core = ctx and ctx.core or nil
    if not (core and core.sendGlobalEvent) then return false end
    local ok, err = pcall(function()
        core.sendGlobalEvent("SitDownPleaseAnimatedMorrowindAlignmentResult", payload)
    end)
    if not ok then debugLog(ctx, "animated morrowind compat result failed", tostring(err)) end
    return ok
end

function M.create(ctx)
    ctx = ctx or {}
    local state = {
        dialogueUntil = 0,
    }
    local controller = { state = state }

    function controller.sendResult(payload)
        return sendResult(ctx, payload)
    end

    function controller.onDialogueStarted(seconds)
        local core = ctx.core
        state.dialogueUntil = (core and core.getSimulationTime and core.getSimulationTime() or 0) + (tonumber(seconds) or 5)
    end

    function controller.onDialogueStopped()
        state.dialogueUntil = 0
    end

    function controller.onAssist(data)
        local requestId = data and data.requestId or nil
        local npc = actor(ctx)
        local actorReason = compat.knownSittingActorReason(npc)
        if not actorReason then
            sendResult(ctx, { requestId = requestId, skippedReason = "not_known_am_sitter" })
            return
        end
        if ctx.interactionActive and ctx.interactionActive() then
            sendResult(ctx, { requestId = requestId, skippedReason = "normal_sdp_interaction_active" })
            return
        end
        local now = ctx.core and ctx.core.getSimulationTime and ctx.core.getSimulationTime() or 0
        if now < (state.dialogueUntil or 0) then
            sendResult(ctx, { requestId = requestId, skippedReason = "dialogue_active" })
            return
        end
        local dangerReason = ctx.activeDangerReason and ctx.activeDangerReason() or nil
        if dangerReason then
            sendResult(ctx, { requestId = requestId, skippedReason = dangerReason })
            return
        end
        local packageBlocks, packageReason = false, nil
        if ctx.activePackageBlocksNewInteraction then
            packageBlocks, packageReason = ctx.activePackageBlocksNewInteraction("sitting", data)
        end
        if packageBlocks then
            sendResult(ctx, { requestId = requestId, skippedReason = packageReason })
            return
        end
        local animationBlocks, animationReason = false, nil
        if ctx.activeAnimationBlocksExternalCompat then
            animationBlocks, animationReason = ctx.activeAnimationBlocksExternalCompat()
        end
        if animationBlocks then
            sendResult(ctx, { requestId = requestId, skippedReason = animationReason })
            return
        end

        local obj = data and data.object or nil
        if not (obj and obj.position) then
            sendResult(ctx, { requestId = requestId, skippedReason = "missing_object" })
            return
        end

        local settings = settingsFrom(ctx)
        local profile = data.profile
        if not profile and ctx.profiles and ctx.profiles.getProfileForObject then
            profile = ctx.profiles.getProfileForObject(obj, "sitting", settings)
        end
        if not profile then
            sendResult(ctx, { requestId = requestId, objectId = data.objectId, skippedReason = "missing_profile" })
            return
        end

        local priorObject = ctx.currentObject and ctx.currentObject() or nil
        if ctx.setCurrentObject then ctx.setCurrentObject(obj) end
        local sitPosition, surfaceMode, surfaceSamples = ctx.sampleSittingSurface(obj, profile)
        if not sitPosition then
            if ctx.setCurrentObject then ctx.setCurrentObject(priorObject) end
            sendResult(ctx, {
                requestId = requestId,
                objectId = data.objectId,
                profileId = data.profileId or profile.profileId,
                skippedReason = "surface_" .. tostring(surfaceMode or "unavailable"),
            })
            return
        end

        local facingDirection = ctx.normalizeDirection3 and ctx.normalizeDirection3(data.preferredFacingDirection) or nil
        if not facingDirection and npc and npc.rotation then
            local yaw = npc.rotation:getYaw()
            facingDirection = ctx.util.vector3(math.sin(yaw), math.cos(yaw), 0)
        end
        facingDirection = facingDirection or ctx.util.vector3(0, 1, 0)

        local finalPos = ctx.finalPositionForProfile(sitPosition, facingDirection, profile, "standard", profile.animation)
        if ctx.setCurrentObject then ctx.setCurrentObject(priorObject) end
        if not finalPos then
            sendResult(ctx, { requestId = requestId, objectId = data.objectId, skippedReason = "missing_expected_position" })
            return
        end

        local sdpExpectedZ = finalPos.z
        local originalZ = npc and npc.position and npc.position.z or nil
        local expectedZ, expectedReason = compat.expectedExternalSeatedZ(npc, sitPosition.z, sdpExpectedZ, originalZ)
        if not expectedZ then
            sendResult(ctx, {
                requestId = requestId,
                objectId = data.objectId,
                profileId = data.profileId or profile.profileId,
                skippedReason = expectedReason or "unsupported_external_root_family",
            })
            return
        end
        local targetZ, reason, delta = compat.correctionTarget(originalZ, expectedZ, npc)
        local correctionNeeded = targetZ ~= nil

        debugLog(
            ctx,
            "animated morrowind compat evaluated",
            "actorReason", tostring(actorReason),
            "object", tostring(data.objectId),
            "profile", tostring(data.profileId or profile.profileId),
            "surface", tostring(surfaceMode),
            "samples", tostring(surfaceSamples),
            "originalZ", tostring(originalZ),
            "expectedZ", tostring(expectedZ),
            "expectedReason", tostring(expectedReason),
            "sdpExpectedZ", tostring(sdpExpectedZ),
            "delta", tostring(delta),
            "result", correctionNeeded and "correction_needed" or tostring(reason)
        )

        sendResult(ctx, {
            requestId = requestId,
            object = obj,
            objectId = data.objectId,
            profileId = data.profileId or profile.profileId,
            surfaceMode = surfaceMode,
            surfaceSamples = surfaceSamples,
            originalZ = originalZ,
            expectedZ = expectedZ,
            sdpExpectedZ = sdpExpectedZ,
            targetZ = targetZ,
            delta = delta,
            correctionNeeded = correctionNeeded,
            skippedReason = correctionNeeded and nil or reason,
        })
    end

    return controller
end

return M
