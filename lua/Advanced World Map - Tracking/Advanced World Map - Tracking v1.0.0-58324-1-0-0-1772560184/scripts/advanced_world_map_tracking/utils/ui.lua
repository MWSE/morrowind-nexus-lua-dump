local ui = require("openmw.ui")

local this = {}

this.whiteTexture = ui.texture{ path = "white" }


function this.removeFromContent(content, index)
    if type(index) == "string" then
        index = content.__nameIndex[index]
    end

    if not index then return end

    local val = rawget(content, index)
    if not val then return end

    local oldName = val and val.name
    if oldName then
        content.__nameIndex[oldName] = nil
    end

    for i = index, #content - 1 do
        local v = rawget(content, i + 1)
        rawset(content, i, v)
        if type(v.name) == "string" then
            content.__nameIndex[v.name] = i
        end
    end
    rawset(content, #content, nil)

    return index
end


function this.clearContent(content)
    for i = #content, 1, -1 do
        this.removeFromContent(content, i)
    end
end


function this.isExistsInContent(content, index)
    if type(index) == "string" then
        return rawget(content.__nameIndex, index) ~= nil
    else
        return rawget(content, index) ~= nil
    end
end


---@return boolean success
function this.safeAddToContent(content, elem)
    local success = pcall(function()
        content:add(elem)
    end)
    return success
end


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
            if elem.props.textShadow then
                add(1)
            end
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
	local width = ui.layers[1].size.x
	local screenSize = ui.screenSize()
	return screenSize.x / width
end


function this.getScaledScreenSize()
    return ui.layers[1].size
end


function this.getTooltipWidth()
    local scaledScreenSize = ui.layers[1].size
    local width = scaledScreenSize.x
	local screenSize = ui.screenSize()
    local scale = screenSize.x / width
    return math.min(scaledScreenSize.x * 0.4, width / 5 * scale)
end


return this