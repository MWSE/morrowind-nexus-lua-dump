-- compatibility/scriptedAnimations.lua
-- Soft compatibility for external scripted performances/poses that should take
-- precedence over Sit Down Please furniture control.

local module = {}

local EXTERNAL_SCRIPTED_ANIMATION_TOKENS = {
    "bellydance",
    "blowkiss",
    "bolute",
    "bodrum",
    "bcfiddle",
    "boocarina",
    "boflute",
    "keytar",
    "bagpipe",
    "dance",
    "potion",
    "drink",
    "eating",
    "bugmusk",
}

local ACTIVE_BLOCKING_ANIMATION_TOKENS = {
    "walk",
    "run",
    "swim",
    "jump",
    "weapon",
    "spell",
    "hit",
    "knock",
    "death",
}

local function activeGroupName(actor, animApi, group)
    if not (actor and animApi and animApi.getActiveGroup) then return "" end
    local ok, active = pcall(animApi.getActiveGroup, actor, group)
    return ok and active and string.lower(tostring(active)) or ""
end

local function activeGroupNames(actor, animApi)
    if not (actor and animApi and animApi.getActiveGroup and animApi.BONE_GROUP) then return nil end
    local groups = {
        animApi.BONE_GROUP.LowerBody,
        animApi.BONE_GROUP.Torso,
    }
    local names = {}
    for _, group in ipairs(groups) do
        local name = activeGroupName(actor, animApi, group)
        if name ~= "" then
            names[#names + 1] = name
        end
    end
    return names
end

local function tokenMatchReason(names, tokens, prefix)
    if not names then return nil end
    for _, name in ipairs(names) do
        for _, token in ipairs(tokens) do
            if name:find(token, 1, true) then
                return prefix .. name, name
            end
        end
    end
    return nil
end

function module.activeExternalAnimationReason(actor, animApi)
    return tokenMatchReason(
        activeGroupNames(actor, animApi),
        EXTERNAL_SCRIPTED_ANIMATION_TOKENS,
        "active_external_animation_"
    )
end

function module.activeBlockingAnimationReason(actor, animApi)
    local names = activeGroupNames(actor, animApi)
    local blockingReason, blockingName = tokenMatchReason(names, ACTIVE_BLOCKING_ANIMATION_TOKENS, "active_animation_")
    if blockingReason then return blockingReason, blockingName end

    return tokenMatchReason(names, EXTERNAL_SCRIPTED_ANIMATION_TOKENS, "active_external_animation_")
end

return module
