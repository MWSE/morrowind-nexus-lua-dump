-- animation/playback.lua
-- Shared local-script animation selection helpers for Sit Down Please.
-- Kept separate from interactionSeeker.lua to avoid the Lua 200-local limit and
-- make missing-animation behavior easier to audit.
local self = require('openmw.self')
local anim = require('openmw.animation')

local module = {}
local SLEEP_GROUPS = {
    "sdpvasitting8",
    "sdpvasitting9",
    "vasitting8",
    "vaSitting8",
    "vasitting9",
    "vaSitting9",
    "knockout",
    "knockdown",
}

function module.available(animationName)
    if not animationName then return false end
    if not anim or not anim.hasGroup then return false end
    local ok, hasGroup = pcall(anim.hasGroup, self, animationName)
    return ok and hasGroup == true
end

function module.nameAliases(animationName)
    local list = {}
    local seen = {}
    local function add(name)
        if name and not seen[name] then
            seen[name] = true
            list[#list + 1] = name
        end
    end
    add(animationName)
    local lower = string.lower(tostring(animationName or ""))
    if lower == "sitidle1" then
        add("sitidle1")
        add("SitIdle1")
        add("sdpvasitting6")
        add("sdpvasitting2")
        add("sdpvasitting3")
        add("sdpvasitting4")
        add("vasitting6")
        add("vaSitting6")
        add("vasitting2")
        add("vasitting3")
        add("vasitting4")
        add("vaSitting2")
        add("vaSitting3")
        add("vaSitting4")
    elseif lower == "sdpvasitting6" or lower == "vasitting6" then
        add("sdpvasitting6")
        add("vasitting6")
        add("vaSitting6")
        add("sitidle1")
        add("SitIdle1")
        add("sdpvasitting2")
        add("sdpvasitting3")
        add("sdpvasitting4")
        add("vasitting2")
        add("vasitting3")
        add("vasitting4")
    elseif lower == "sdpvasitting8" or lower == "vasitting8" then
        add("sdpvasitting8")
        add("sdpvasitting9")
        add("vasitting8")
        add("vaSitting8")
        add("vasitting9")
        add("vaSitting9")
        add("knockout")
        add("knockdown")
    elseif lower == "sdpvasitting9" or lower == "vasitting9" then
        add("sdpvasitting9")
        add("sdpvasitting8")
        add("vasitting9")
        add("vaSitting9")
        add("vasitting8")
        add("vaSitting8")
        add("knockout")
        add("knockdown")
    end
    return list
end

function module.deterministicHash(value)
    value = tostring(value or "")
    local hash = 0
    for i = 1, #value do
        hash = (hash * 33 + string.byte(value, i)) % 2147483647
    end
    return hash
end

function module.variantAnimationName(variant)
    if type(variant) == "table" then return variant.animation or variant.name or variant.id end
    return variant
end

local function firstAvailableAlias(animationName)
    for _, alias in ipairs(module.nameAliases(animationName)) do
        if module.available(alias) then return alias end
    end
    return nil
end

local function firstCaseAlias(animationName)
    animationName = tostring(animationName or "")
    if animationName == "" then return nil end
    for _, alias in ipairs(module.nameAliases(animationName)) do
        if module.available(alias) then return alias end
    end
    return nil
end

local function firstStrictAvailable(names)
    for _, name in ipairs(names or {}) do
        if module.available(name) then return name end
    end
    return nil
end

local function flatDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function textLooksLikeCounterOrBar(text)
    text = string.lower(tostring(text or ""))
    return text:find("counter", 1, true) ~= nil
        or text:find("_bar_", 1, true) ~= nil
        or text:find("/bar_", 1, true) ~= nil
        or text:match("^bar[_%-%s]") ~= nil
        or text:match("[_%-%s]bar[_%-%s]") ~= nil
end

local function candidatePosition(candidate)
    return candidate and (candidate.position or candidate.object and candidate.object.position) or nil
end

local function candidateText(candidate)
    return tostring(candidate and candidate.recordId or "")
        .. " " .. tostring(candidate and candidate.model or "")
        .. " " .. tostring(candidate and candidate.name or "")
        .. " " .. tostring(candidate and candidate.kind or "")
end

local function candidateLooksLikeTable(candidate)
    local text = string.lower(candidateText(candidate))
    if textLooksLikeCounterOrBar(text) then return false end
    return text:find("table", 1, true) ~= nil or text:find("desk", 1, true) ~= nil or tostring(candidate and candidate.kind or "") == "table"
end

local function frontDot(seatPos, candidatePos, facingDirection)
    if not (seatPos and candidatePos and facingDirection) then return nil end
    local dx = (candidatePos.x or 0) - (seatPos.x or 0)
    local dy = (candidatePos.y or 0) - (seatPos.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return nil end
    return (dx / len) * (facingDirection.x or 0) + (dy / len) * (facingDirection.y or 0)
end

local function sittingSeatPosition(data)
    return data and (data.sittingSeatPosition or (data.object and data.object.position)) or nil
end

local function frontCounterOrBarBeatsTable(data)
    local seatPos = sittingSeatPosition(data)
    local facingDirection = data and data.preferredFacingDirection
    if not (seatPos and facingDirection) then return false end
    local nearestBar = nil
    local nearestTable = nil
    for _, candidate in ipairs(data.facingCandidates or {}) do
        local pos = candidatePosition(candidate)
        local dot = frontDot(seatPos, pos, facingDirection)
        if dot and dot > 0.45 then
            local dist = flatDistance(seatPos, pos)
            if dist then
                if textLooksLikeCounterOrBar(candidateText(candidate)) then
                    nearestBar = nearestBar and math.min(nearestBar, dist) or dist
                elseif candidateLooksLikeTable(candidate) then
                    nearestTable = nearestTable and math.min(nearestTable, dist) or dist
                end
            end
        end
    end
    return nearestBar ~= nil and (nearestTable == nil or nearestBar <= nearestTable + 28)
end

local function profileLooksLikeStool(profile)
    local text = string.lower(table.concat({
        tostring(profile and profile.profileId or ""),
        tostring(profile and profile.type or ""),
        tostring(profile and profile.seatType or ""),
        tostring(profile and profile.category or ""),
    }, " "))
    return text:find("stool", 1, true) ~= nil
end

local function profileLooksLikeBench(profile)
    local text = string.lower(table.concat({
        tostring(profile and profile.profileId or ""),
        tostring(profile and profile.type or ""),
        tostring(profile and profile.seatType or ""),
        tostring(profile and profile.category or ""),
        tostring(profile and profile.seatCategory or ""),
    }, " "))
    return text:find("bench", 1, true) ~= nil
end

local function profileLooksLikeBackedChair(profile)
    local text = string.lower(table.concat({
        tostring(profile and profile.profileId or ""),
        tostring(profile and profile.type or ""),
        tostring(profile and profile.seatType or ""),
        tostring(profile and profile.category or ""),
        tostring(profile and profile.seatCategory or ""),
        tostring(profile and profile.rotationMode or ""),
    }, " "))
    return text:find("backed_chair", 1, true) ~= nil
        or text:find("backed chair", 1, true) ~= nil
        or text:find("respectfurnitureforward", 1, true) ~= nil
end

local function closeTableContext(data, profile)
    if not (data and data.interactionType == "sitting" and data.facingKind == "table") then return false end
    if profileLooksLikeStool(profile) then return false end
    if profileLooksLikeBench(profile) then return false end
    if profileLooksLikeBackedChair(profile) then return false end
    local focusText = tostring(data.facingObjectId or "") .. " " .. tostring(data.facingObjectModel or "") .. " " .. tostring(data.facingObjectName or "")
    if textLooksLikeCounterOrBar(focusText) then return false end
    if frontCounterOrBarBeatsTable(data) then return false end
    local seatPos = sittingSeatPosition(data)
    local focusDot = frontDot(seatPos, data.facingObjectPosition, data.preferredFacingDirection)
    if focusDot and focusDot < 0.55 then return false end
    local distance = flatDistance(seatPos, data.facingObjectPosition)
    local maxDistance = profileLooksLikeStool(profile) and 115 or 170
    return distance ~= nil and distance <= maxDistance
end

local function objectUnavailableError(err)
    local text = string.lower(tostring(err or ""))
    return text:find("disabled object", 1, true) ~= nil
        or text:find("removed", 1, true) ~= nil
end

function module.debugCandidates(profile, data)
    local out = {}
    local seen = {}
    local function add(name)
        name = tostring(name or "")
        if name ~= "" and not seen[name] then
            seen[name] = true
            out[#out + 1] = name
        end
    end

    if data and data.interactionType == "sleeping" and type(profile.sleepAnimationVariants) == "table" then
        for _, variant in ipairs(profile.sleepAnimationVariants) do
            for _, alias in ipairs(module.nameAliases(module.variantAnimationName(variant))) do add(alias) end
        end
    end
    if type(profile.animations) == "table" then
        for _, animationName in ipairs(profile.animations) do
            for _, alias in ipairs(module.nameAliases(animationName)) do add(alias) end
        end
    end
    if profile.animation then
        for _, alias in ipairs(module.nameAliases(profile.animation)) do add(alias) end
    end
    return table.concat(out, ",")
end

function module.chooseAvailable(profile, data)
    if not profile then return nil end

    if data and data.interactionType == "sitting" then
        if closeTableContext(data, profile) then
            local tablePose = firstStrictAvailable({ "sdpvasitting6", "vasitting6", "vaSitting6" })
            if tablePose then return tablePose, nil end
        end
        local legacy = firstStrictAvailable({ "sitidle1", "SitIdle1" })
        if legacy then return legacy, nil end
    end

    if data and data.interactionType == "sleeping" and type(profile.sleepAnimationVariants) == "table" then
        local available = {}
        for _, variant in ipairs(profile.sleepAnimationVariants) do
            local animationName = module.variantAnimationName(variant)
            local resolvedName = firstCaseAlias(animationName)
            if resolvedName then
                table.insert(available, { variant = variant, animation = resolvedName })
            end
        end

        if #available > 0 then
            local key = table.concat({
                tostring(self.object.recordId or self.object.id or "npc"),
                tostring(data.object and (data.object.recordId or data.object.id) or "object"),
                tostring(data.slotName or data.slotKey or "slot"),
            }, "|")
            local index = (module.deterministicHash(key) % #available) + 1
            local chosen = available[index]
            return chosen.animation, chosen.variant
        end
    end

    local candidates = {}
    if type(profile.animations) == "table" then
        for _, animationName in ipairs(profile.animations) do
            table.insert(candidates, animationName)
        end
    end
    if profile.animation then
        table.insert(candidates, profile.animation)
    end

    local available = {}
    local seenAvailable = {}
    local seen = {}
    for _, animationName in ipairs(candidates) do
        for _, alias in ipairs(module.nameAliases(animationName)) do
            if alias and not seen[alias] then
                seen[alias] = true
                if module.available(alias) then
                    local canonical = string.lower(tostring(alias))
                    if not seenAvailable[canonical] then
                        seenAvailable[canonical] = true
                        available[#available + 1] = alias
                    end
                end
            end
        end
    end

    if #available > 0 then
        local key = table.concat({
            tostring(self.object.recordId or self.object.id or "npc"),
            tostring(data and data.object and (data.object.recordId or data.object.id) or "object"),
            tostring(data and (data.slotName or data.slotKey) or "slot"),
            tostring(data and data.interactionType or "interaction"),
        }, "|")
        local index = (module.deterministicHash(key) % #available) + 1
        return available[index], nil
    end

    return nil, nil
end


function module.forceClearQueue(debugLog, reason, clearScripted, selfRef)
    if not (anim and anim.clearAnimationQueue) then return false end
    local actorSelf = selfRef or self
    local ok, err = pcall(function()
        anim.clearAnimationQueue(actorSelf, clearScripted ~= false)
    end)
    if type(debugLog) == "function" then
        if ok then
            debugLog("sleep animation queue force-cleared", "reason", tostring(reason or "wake_cleanup"))
        elseif not objectUnavailableError(err) then
            debugLog("sleep animation queue force-clear failed", "reason", tostring(reason or "wake_cleanup"), tostring(err))
        end
    end
    return ok == true
end

function module.forceCancelSleepGroups(debugLog, reason, selfRef)
    if not (anim and anim.cancel) then return false end
    local actorSelf = selfRef or self
    local attempted = 0
    local failed = 0
    for _, groupName in ipairs(SLEEP_GROUPS) do
        attempted = attempted + 1
        local ok = pcall(anim.cancel, actorSelf, groupName)
        if not ok then failed = failed + 1 end
    end
    if failed == attempted then
        return false
    end
    if type(debugLog) == "function" then
        debugLog(
            "sleep animation groups force-cancelled",
            "reason", tostring(reason or "wake_cleanup"),
            "groups", tostring(attempted),
            "failed", tostring(failed)
        )
    end
    return failed < attempted
end

return module
