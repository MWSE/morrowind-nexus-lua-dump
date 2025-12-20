local ui = require('openmw.ui')
local util = require('openmw.util')

local stringLib = require("scripts.quest_guider_lite.utils.string")

local config = require("scripts.quest_guider_lite.config")

local this = {}

this.whiteTexture = ui.texture{ path = "white" }


function this.getTextHeight(text, fontSize, width, mul, extraRowCount, removeColors)
    if removeColors then
        text = this.removeColorMarkers(text)
    end
    if not mul then mul = 0.7 end
    if #text == 0 then return 0 end
    local words = {}
    local charWidth = fontSize * mul
    local rowMaxSize = math.floor(width / charWidth)
    local rowCount = extraRowCount or 0
    for line in text:gmatch("([^\n]*)\n?") do
        local currentRowSize = 0
        for word in line:gmatch("%S+") do
            local wordSize = utf8.len(word) or string.len(word)
            if currentRowSize + wordSize <= rowMaxSize then
                currentRowSize = currentRowSize + wordSize + 1
            else
                rowCount = rowCount + 1
                currentRowSize = wordSize
            end
            table.insert(words, word)
        end
        rowCount = rowCount + 1
    end
    rowCount = rowCount - 1
    return rowCount * fontSize, rowCount
end


---@return number
function this.getContentHeight(content, isHorisontal)
    local res = 0

    local function add(val)
        if isHorisontal then
            res = math.max(res, val)
        else
            res = res + val
        end
    end

    for _, elem in pairs(content) do
        if elem.props and elem.props.size then
            add(elem.props.size.y)
        elseif elem.props and elem.props.textSize then
            add(elem.props.textSize)
        elseif elem.userData and elem.userData.height then
            add(elem.userData.height)
        elseif elem.content then
            add(this.getContentHeight(elem.content, elem.props and elem.props.horisontal or false))
        end
    end

    return res
end


function this.getUIScale()
	local width = ui.layers[ui.layers.indexOf("HUD")].size.x
	local screenSize = ui.screenSize()
	return screenSize.x / width
end


function this.getScaledScreenSize()
    return ui.layers[ui.layers.indexOf("HUD")].size
end


local specialCharacters = {
    ["("] = "(",
    [")"] = ")",
    ["."] = ".",
    ["%"] = "%",
    ["+"] = "+",
    ["-"] = "-",
    ["*"] = "*",
    ["?"] = "?",
    ["["] = "[",
    ["]"] = "]",
    ["^"] = "^",
    ["$"] = "$"
}

function this.colorize(text, search, color, defaultColor)
    if not search or #search == 0 then return text end

    color = color or "#000000"
    defaultColor = defaultColor or ("#"..config.data.ui.defaultColor:asHex())

    local lowerText = stringLib.utf8_lower(text)
    local lowerSearch = stringLib.utf8_lower(search)

    local result = ""
    local i = 1
    local textLen = stringLib.length(text)
    local searchLen = stringLib.length(search)

    while i <= textLen do
        local subText = stringLib.utf8_sub(lowerText, i, searchLen)
        if subText == lowerSearch then
            result = result .. color .. stringLib.utf8_sub(text, i, searchLen) .. defaultColor
            i = i + searchLen
        else
            result = result .. stringLib.utf8_sub(text, i, 1)
            i = i + 1
        end
    end

    return result
end


function this.colorizeNested(text, search, color, defaultColor)
    if not search then return text end
    local searchLen = #search
    if searchLen == 0 then return text end

    color = color or "#000000"
    defaultColor = defaultColor or ("#"..config.data.ui.defaultColor:asHex())

    local lowerText = stringLib.utf8_lower(text)
    local lowerSearch = stringLib.utf8_lower(search)

    local result = ""
    local lastIndex = 1
    local currentColor = defaultColor

    local function nextColorMarker(s, start)
        return s:find("#%x%x%x%x%x%x", start)
    end

    local textLen = #text
    local i = 1
    while i <= textLen do
        local colorStart, colorEnd = nextColorMarker(text, i)
        local segmentEnd = colorStart and colorStart - 1 or textLen
        local segment = text:sub(i, segmentEnd)
        local lowerSegment = lowerText:sub(i, segmentEnd)

        local segResult = ""
        local segIdx = 1
        while segIdx <= #segment do
            local found = false
            if lowerSegment:sub(segIdx, segIdx + #lowerSearch - 1) == lowerSearch then
                segResult = segResult .. color .. segment:sub(segIdx, segIdx + searchLen - 1) .. currentColor
                segIdx = segIdx + searchLen
                found = true
            end
            if not found then
                segResult = segResult .. segment:sub(segIdx, segIdx)
                segIdx = segIdx + 1
            end
        end

        result = result .. segResult

        if colorStart then
            local marker = text:sub(colorStart, colorEnd)
            result = result .. marker
            currentColor = marker
            i = colorEnd + 1
        else
            break
        end
    end

    return result
end


---@param patterns {pattern : string, color : string}[]
function this.colorizeNestedMulti(text, patterns, defaultColor)
    if not patterns or #patterns == 0 then return text end

    defaultColor = defaultColor or ("#" .. config.data.ui.defaultColor:asHex())
    local lowerText = stringLib.utf8_lower(text)
    local matches = {}

    for idx, pat in ipairs(patterns) do
        local search = pat.pattern
        local color = pat.color or "#000000"
        if search and #search > 0 then
            local lowerSearch = stringLib.utf8_lower(search)
            local start = 1
            while true do
                local found = lowerText:find(lowerSearch, start, true)
                if not found then break end
                table.insert(matches, {start = found, finish = found + #search - 1, color = color, patIdx = idx, len = #search})
                start = found + 1
            end
        end
    end

    table.sort(matches, function(a, b)
        if a.start == b.start then
            return a.patIdx < b.patIdx
        end
        return a.start < b.start
    end)

    local filtered = {}
    local lastEnd = 0
    for _, m in ipairs(matches) do
        if m.start > lastEnd then
            table.insert(filtered, m)
            lastEnd = m.finish
        end
    end

    local result = ""
    local idx = 1
    local colorStack = {defaultColor}
    local matchIdx = 1
    local textLen = #text

    while idx <= textLen do
        local m = filtered[matchIdx]
        if m and idx == m.start then
            result = result .. m.color .. text:sub(m.start, m.finish) .. colorStack[#colorStack]
            idx = m.finish + 1
            matchIdx = matchIdx + 1
        else
            result = result .. text:sub(idx, idx)
            idx = idx + 1
        end
    end

    return result
end


function this.removeColorMarkers(text)
    return text:gsub("#%x%x%x%x%x%x", "")
end


return this