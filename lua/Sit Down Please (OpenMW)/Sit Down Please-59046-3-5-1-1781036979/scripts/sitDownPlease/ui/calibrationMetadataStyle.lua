---@omw-context none

local M = {}

local DETAIL_LINE_HEIGHT = 14
local DEFAULT_ROW_HEIGHT = DETAIL_LINE_HEIGHT
local DEFAULT_MAX_LINES = 6
local COMPACT_MAX_LINES = 4

function M.rowHeight(value, row)
    local text = tostring(value or "")
    if text == "" then return 0 end
    local lines = 0
    local estimatedCharsPerLine = 38
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line == "" then
            lines = lines + 1
        elseif row and row.manualLines == true then
            lines = lines + 1
        else
            lines = lines + math.max(1, math.ceil(#line / estimatedCharsPerLine))
        end
    end
    lines = math.max(1, lines)
    local lineHeight = tonumber(row and row.lineHeight) or DETAIL_LINE_HEIGHT
    if row and row.compactDetail == true then
        local maxLines = tonumber(row.maxLines) or COMPACT_MAX_LINES
        return math.max(lineHeight, math.min(maxLines * lineHeight, lines * lineHeight))
    end
    if row and row.compactSub == true then
        return lineHeight
    end
    if row and (row.wrap == true or row.manualLines == true) then
        local maxLines = tonumber(row.maxLines) or DEFAULT_MAX_LINES
        return math.max(lineHeight, math.min(maxLines * lineHeight, lines * lineHeight))
    end
    return tonumber(row and row.defaultHeight) or DEFAULT_ROW_HEIGHT
end

local function warningSeverity(value)
    local text = tostring(value or ""):lower()
    if text == "" then return "none" end
    if text:find("critical", 1, true)
        or text:find("lua error", 1, true)
        or text:find("hard invalid", 1, true)
        or text:find("missing animation", 1, true)
        or text:find("invalid target transform", 1, true)
        or text:find("invalid transform", 1, true)
        or text:find("no valid slot", 1, true)
        or text:find("sleep transform is missing", 1, true)
        or text:find("below floor", 1, true)
        or text:find("below bed object", 1, true)
        or text:find("below sleep surface", 1, true)
        or text:find("below safe approach", 1, true) then
        return "critical"
    end
    if text:find("failed", 1, true)
        or text:find("validation", 1, true)
        or text:find("collision", 1, true)
        or text:find("raycast", 1, true)
        or text:find("issue", 1, true)
        or text:find("weak", 1, true)
        or text:find("untrusted", 1, true)
        or text:find("unsafe", 1, true)
        or text:find("blocked", 1, true)
        or text:find("blocker", 1, true)
        or text:find("clearance", 1, true)
        or text:find("table/counter", 1, true)
        or text:find("unverified", 1, true)
        or text:find("item on", 1, true)
        or text:find("route", 1, true)
        or text:find("wrong floor", 1, true)
        or text:find("below sampled surface", 1, true)
        or text:find("above sampled surface", 1, true) then
        return "issue"
    end
    return "awareness"
end

function M.rowTextColor(util, key, value)
    if key == "actorDetail" or key == "furnitureDetail"
        or key == "actorPose"
        or key == "focusDetail" or key == "focusCandidates"
        or key == "furnitureSource" or key == "furnitureModel" then
        return util.color.rgb(0.64, 0.61, 0.53)
    end
    if key == "actorStatus" then
        return util.color.rgb(1.0, 0.72, 0.24)
    end
    if key == "actorWarnings" or key == "furnitureWarnings" or key == "focusWarnings" or key == "profileWarnings" or key == "genericWarnings" then
        local text = tostring(value or ""):lower()
        if text:find("external animation", 1, true) then
            return util.color.rgb(1.0, 0.72, 0.24)
        end
        if text:find("override", 1, true)
            or text:find("manual", 1, true)
            or text:find("debug", 1, true)
            or text:find("weak", 1, true)
            or text:find("untrusted", 1, true) then
            return util.color.rgb(1.0, 0.58, 0.18)
        end
        return util.color.rgb(1.0, 0.78, 0.28)
    end
    if key == "actorBlockers" or key == "furnitureBlockers" or key == "profileBlockers" or key == "genericBlockers" then
        return util.color.rgb(1.0, 0.28, 0.22)
    end
    if key == "rejections" then
        return util.color.rgb(1.0, 0.28, 0.22)
    end
    if key == "blockers" then
        local text = tostring(value or ""):lower()
        if text:find("item on", 1, true)
            or text:find("paper/book", 1, true)
            or text:find("hard blocker", 1, true)
            or text:find("clutter", 1, true)
            or text:find("external animation", 1, true) then
            return util.color.rgb(1.0, 0.28, 0.22)
        end
        return util.color.rgb(1.0, 0.58, 0.18)
    end
    if key == "normalPlay" then
        local text = tostring(value or ""):lower()
        if text:find("blocked", 1, true) then return util.color.rgb(1.0, 0.28, 0.22) end
        if text:find("allowed", 1, true) then return util.color.rgb(0.45, 0.85, 0.45) end
        return util.color.rgb(1.0, 0.58, 0.18)
    end
    if key == "safetyGate" then
        local text = tostring(value or ""):lower()
        if text:find("normal play blocked", 1, true) then return util.color.rgb(1.0, 0.28, 0.22) end
        if text:find("unverified", 1, true) then return util.color.rgb(1.0, 0.28, 0.22) end
        if text:find("normal play allowed", 1, true)
            or text:find("cell verified", 1, true)
            or text:find("cell prefix verified", 1, true)
            or text:find("place verified", 1, true)
            or text:find("region verified", 1, true)
            or text:find("furniture verified", 1, true)
            or text:find("furniture allowed", 1, true)
            or text:find("furniture type allowed", 1, true) then
            return util.color.rgb(0.45, 0.85, 0.45)
        end
        return util.color.rgb(1.0, 0.58, 0.18)
    end
    if key == "warnings" then
        local severity = warningSeverity(value)
        if severity == "critical" then return util.color.rgb(1.0, 0.28, 0.22) end
        if severity == "issue" then return util.color.rgb(1.0, 0.58, 0.18) end
        if severity == "awareness" then return util.color.rgb(0.78, 0.74, 0.64) end
    end
    return util.color.rgb(0.94, 0.92, 0.84)
end

function M.rowLabelColor(util, key, value)
    if key == "actorWarnings" or key == "actorBlockers"
        or key == "furnitureWarnings" or key == "furnitureBlockers"
        or key == "profileWarnings" or key == "profileBlockers"
        or key == "genericWarnings" or key == "genericBlockers"
        or key == "rejections"
        or key == "blockers"
        or key == "warnings" then
        return M.rowTextColor(util, key, value)
    end
    return util.color.rgb(0.82, 0.78, 0.66)
end

return M
