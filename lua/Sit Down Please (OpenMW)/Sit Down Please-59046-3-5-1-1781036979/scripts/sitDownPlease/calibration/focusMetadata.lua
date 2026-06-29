-- calibration/focusMetadata.lua
---@omw-context none

local M = {}

local function cleanText(value)
    local text = tostring(value or "")
    if text == "" or text == "nil" then return "" end
    return text
end

local function roundNumber(value, digits)
    local number = tonumber(value)
    if not number then return "" end
    digits = tonumber(digits or 0) or 0
    local scale = 10 ^ digits
    local scaled = number * scale
    if scaled >= 0 then
        scaled = math.floor(scaled + 0.5)
    else
        scaled = math.ceil(scaled - 0.5)
    end
    number = scaled / scale
    if digits <= 0 then return tostring(number) end
    return string.format("%." .. tostring(digits) .. "f", number)
end

local function objectField(obj, field)
    if not obj then return nil end
    local ok, value = pcall(function() return obj[field] end)
    if ok then return value end
    return nil
end

local function candidateRecord(candidate)
    return cleanText(candidate and (candidate.recordId or objectField(candidate.object, "recordId")))
end

local function candidateRef(candidate)
    return cleanText(candidate and (candidate.refId or candidate.objectRefId or objectField(candidate.object, "id")))
end

local function candidateModel(candidate)
    return cleanText(candidate and candidate.model)
end

local function candidateName(candidate)
    return cleanText(candidate and candidate.name)
end

local function candidateKind(candidate)
    return cleanText(candidate and candidate.kind)
end

local function candidateScale(candidate)
    if not candidate then return nil end
    local scale = tonumber(candidate.scale)
    if scale then return scale end
    return tonumber(objectField(candidate.object, "scale"))
end

local function candidateContentFile(candidate)
    local value = cleanText(candidate and (candidate.contentFile or candidate.objectContentFile or objectField(candidate.object, "contentFile")))
    return value ~= "" and value or nil
end

function M.objectRefId(obj)
    return cleanText(objectField(obj, "id"))
end

function M.sanitizeCandidate(candidate)
    if not candidate then return nil end
    local recordId = candidateRecord(candidate)
    local refId = candidateRef(candidate)
    local model = candidateModel(candidate)
    local name = candidateName(candidate)
    local kind = candidateKind(candidate)
    local source = cleanText(candidate.source)
    if recordId == "" and refId == "" and model == "" and name == "" and kind == "" then return nil end
    return {
        recordId = recordId ~= "" and recordId or nil,
        refId = refId ~= "" and refId or nil,
        model = model ~= "" and model or nil,
        name = name ~= "" and name or nil,
        kind = kind ~= "" and kind or nil,
        source = source ~= "" and source or nil,
        contentFile = candidateContentFile(candidate),
        distance = tonumber(candidate.distance),
        score = tonumber(candidate.score),
        forwardDot = tonumber(candidate.forwardDot),
        scale = candidateScale(candidate),
        surfaceHit = candidate.surfaceHit == true,
    }
end

function M.sanitizeCandidates(candidates, limit)
    local out = {}
    limit = tonumber(limit or 8) or 8
    for _, candidate in ipairs(candidates or {}) do
        local sanitized = M.sanitizeCandidate(candidate)
        if sanitized then
            out[#out + 1] = sanitized
            if #out >= limit then break end
        end
    end
    return out
end

local function objectLabel(recordId, refId, fallback, includeRef)
    recordId = cleanText(recordId)
    refId = cleanText(refId)
    fallback = cleanText(fallback)
    local label = recordId ~= "" and recordId or (fallback ~= "" and fallback or "")
    if label == "" then label = refId end
    if includeRef ~= false and refId ~= "" and refId ~= label then
        label = label .. " [" .. refId .. "]"
    end
    return label
end

local function appendMetricParts(parts, candidate, options)
    options = options or {}
    local distance = roundNumber(candidate.distance, 0)
    if distance ~= "" then parts[#parts + 1] = "distance " .. distance .. " units" end
    if options.includeDot ~= false then
        local dot = roundNumber(candidate.forwardDot, 2)
        if dot ~= "" then parts[#parts + 1] = "dot=" .. dot end
    end
    if options.includeScore == true then
        local score = roundNumber(candidate.score, 0)
        if score ~= "" then parts[#parts + 1] = "score=" .. score end
    end
    if options.includeSource == true then
        local source = cleanText(candidate.source)
        if source ~= "" then parts[#parts + 1] = source end
    end
    if options.includeContentFile == true then
        local contentFile = cleanText(candidate.contentFile)
        if contentFile ~= "" then parts[#parts + 1] = contentFile end
    end
end

function M.formatCandidate(candidate, options)
    candidate = M.sanitizeCandidate(candidate)
    if not candidate then return "" end
    options = options or {}
    local parts = {}
    local kind = cleanText(candidate.kind)
    if kind ~= "" then parts[#parts + 1] = kind end
    local label = objectLabel(candidate.recordId, candidate.refId, candidate.name, options.includeRef)
    if label ~= "" then parts[#parts + 1] = label end
    if options.metrics ~= false then appendMetricParts(parts, candidate, options) end
    return table.concat(parts, " ")
end

function M.candidateSummary(candidates, limit, options)
    local lines = {}
    limit = tonumber(limit or 3) or 3
    for _, candidate in ipairs(candidates or {}) do
        local line = M.formatCandidate(candidate, options or { includeDot = false, includeScore = false, includeSource = false })
        if line ~= "" then
            lines[#lines + 1] = line
            if #lines >= limit then break end
        end
    end
    return table.concat(lines, "\n")
end

local function activeFocus(data)
    if not data then return nil end
    local recordId = cleanText(data.facingObjectId)
    local refId = cleanText(data.facingObjectRefId)
    if refId == "" then refId = M.objectRefId(data.facingObject) end
    local model = cleanText(data.facingObjectModel)
    local name = cleanText(data.facingObjectName)
    local kind = cleanText(data.facingKind)
    local source = cleanText(data.facingSurfaceSource)
    local contentFile = cleanText(data.facingObjectContentFile or objectField(data.facingObject, "contentFile"))
    if recordId == "" and refId == "" and model == "" and name == "" and kind == "" then return nil end
    return {
        recordId = recordId ~= "" and recordId or nil,
        refId = refId ~= "" and refId or nil,
        model = model ~= "" and model or nil,
        name = name ~= "" and name or nil,
        kind = kind ~= "" and kind or nil,
        source = source ~= "" and source or nil,
        contentFile = contentFile ~= "" and contentFile or nil,
        distance = tonumber(data.facingObjectDistance),
        forwardDot = tonumber(data.facingForwardDot),
        scale = tonumber(data.facingObjectScale) or tonumber(objectField(data.facingObject, "scale")),
        surfaceHit = data.facingSurfaceHit == true,
    }
end

local function ignoredFocus(data)
    if not data then return nil end
    local recordId = cleanText(data.ignoredFacingObjectId)
    local refId = cleanText(data.ignoredFacingObjectRefId)
    if refId == "" then refId = M.objectRefId(data.ignoredFacingObject) end
    local model = cleanText(data.ignoredFacingObjectModel)
    local name = cleanText(data.ignoredFacingObjectName)
    local kind = cleanText(data.ignoredFacingKind)
    local source = cleanText(data.tableClearanceFocusClearReason)
    local contentFile = cleanText(data.ignoredFacingObjectContentFile or objectField(data.ignoredFacingObject, "contentFile"))
    if recordId == "" and refId == "" and model == "" and name == "" and kind == "" then return nil end
    return {
        recordId = recordId ~= "" and recordId or nil,
        refId = refId ~= "" and refId or nil,
        model = model ~= "" and model or nil,
        name = name ~= "" and name or nil,
        kind = kind ~= "" and kind or nil,
        source = source ~= "" and source or nil,
        contentFile = contentFile ~= "" and contentFile or nil,
        distance = tonumber(data.ignoredFacingObjectDistance),
        forwardDot = tonumber(data.ignoredFacingFocusDot),
        scale = tonumber(data.ignoredFacingObjectScale) or tonumber(objectField(data.ignoredFacingObject, "scale")),
        surfaceHit = data.ignoredFacingSurfaceHit == true,
    }
end

local function facingMode(data)
    local reason = cleanText(data and data.facingReason):lower()
    if reason == "" then return nil, nil end
    if reason:find("bench_open_side", 1, true)
        or reason:find("single_seat_bench_object_", 1, true) then
        return "Outwards", ""
    end
    if reason:find("open_space", 1, true) then
        return "Open space", ""
    end
    return nil, nil
end

local function ignoredFocusLabel(focus)
    local kind = cleanText(focus and focus.kind):lower()
    if kind ~= "" then return "Rejected " .. kind .. " focus" end
    return "Rejected focus"
end

local function focusObjectLabel(focus)
    if not focus then return "" end
    return objectLabel(focus.recordId, focus.refId, focus.name, false)
end

local function focusDetailText(focus)
    if not focus then return "" end
    local lines = {}
    local kind = cleanText(focus.kind)
    local contentFile = cleanText(focus.contentFile)
    local model = cleanText(focus.model)
    local distance = roundNumber(focus.distance, 0)
    if kind ~= "" then lines[#lines + 1] = kind end
    if contentFile ~= "" then lines[#lines + 1] = contentFile end
    if model ~= "" then lines[#lines + 1] = model end
    if distance ~= "" then lines[#lines + 1] = "distance " .. distance .. " units" end
    return table.concat(lines, "\n")
end

local function sameFocusIdentity(candidate, focus)
    if not (candidate and focus) then return false end
    local candidateRefId = cleanText(candidate.refId or candidate.objectRefId)
    local focusRefId = cleanText(focus.refId)
    if candidateRefId ~= "" and focusRefId ~= "" then return candidateRefId == focusRefId end
    local candidateRecordId = cleanText(candidate.recordId)
    local focusRecordId = cleanText(focus.recordId)
    local candidateModel = cleanText(candidate.model)
    local focusModel = cleanText(focus.model)
    local candidateKindText = cleanText(candidate.kind)
    local focusKindText = cleanText(focus.kind)
    return candidateRecordId ~= "" and focusRecordId ~= ""
        and candidateRecordId == focusRecordId
        and (candidateModel == "" or focusModel == "" or candidateModel == focusModel)
        and (candidateKindText == "" or focusKindText == "" or candidateKindText == focusKindText)
end

local function focusAlternateCandidates(candidates, focus, ignored)
    local out = {}
    for _, candidate in ipairs(candidates or {}) do
        local sanitized = M.sanitizeCandidate(candidate)
        if sanitized
            and not sameFocusIdentity(sanitized, focus)
            and not sameFocusIdentity(sanitized, ignored) then
            out[#out + 1] = sanitized
        end
    end
    return out
end

function M.focusRows(data)
    if not data then return "", "", "", "" end
    local focus = activeFocus(data)
    local ignored = ignoredFocus(data)
    local modeLabel, modeDetail = facingMode(data)
    local label = ""
    local detail = ""
    local warnings = ""
    if focus then
        label = focusObjectLabel(focus)
        detail = focusDetailText(focus)
    elseif modeLabel then
        label = modeLabel
        detail = cleanText(modeDetail)
    elseif ignored then
        label = focusObjectLabel(ignored)
        detail = focusDetailText(ignored)
        warnings = ignoredFocusLabel(ignored)
    end

    local candidates = data.facingCandidates
    if (not candidates or #candidates == 0) and not modeLabel and data.ignoredFacingCandidates then
        candidates = data.ignoredFacingCandidates
    end
    local alternateCandidates = focusAlternateCandidates(candidates, focus, ignored)
    local summary = modeLabel and "" or M.candidateSummary(alternateCandidates, 2, { includeDot = false, includeScore = false, includeSource = false, includeRef = false })
    return label, detail, warnings, summary
end

function M.logSummary(data)
    if not data then return "", "", "" end
    local focus = activeFocus(data)
    local ignored = ignoredFocus(data)
    local modeLabel, modeDetail = facingMode(data)
    local label = ""
    local detail = ""
    if focus then
        label = M.formatCandidate(focus, { includeDot = true, includeScore = true, includeSource = true, includeContentFile = true })
        detail = focusDetailText(focus)
    elseif modeLabel then
        label = modeLabel
        detail = cleanText(modeDetail)
    elseif ignored then
        local formatted = M.formatCandidate(ignored, { includeDot = true, includeScore = true, includeSource = true, includeContentFile = true })
        label = formatted ~= "" and ("Rejected " .. formatted) or ignoredFocusLabel(ignored)
        detail = focusDetailText(ignored)
    end
    local candidates = data.facingCandidates
    if (not candidates or #candidates == 0) and data.ignoredFacingCandidates then
        candidates = data.ignoredFacingCandidates
    end
    local summary = M.candidateSummary(candidates, 3, { includeDot = true, includeScore = true, includeSource = true, includeContentFile = true })
    if summary == "" and ignored then
        summary = M.formatCandidate(ignored, { includeDot = true, includeScore = true, includeSource = true, includeContentFile = true })
    end
    return cleanText(label), cleanText(detail), cleanText(summary):gsub("\n", " | ")
end

return M
