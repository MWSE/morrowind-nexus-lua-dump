local ui = require('openmw.ui')
local util = require('openmw.util')

local this = {}


function this.convertAlign(str, default)
    return ui.ALIGNMENT[str] or (default or ui.ALIGNMENT.End)
end


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
        if type(v.name) == 'string' then
            content.__nameIndex[v.name] = i
        end
    end
    rawset(content, #content, nil)

    return true
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


function this.getTextHeight(text, fontSize, width, mul)
    if not mul then mul = 0.7 end
    if #text == 0 then return 0 end
    local words = {}
    local charWidth = fontSize * mul
    local rowMaxSize = math.floor(width / charWidth)
    local rowCount = 1
    for line in text:gmatch("[^\n]+") do
        local currentRowSize = 0
        for word in line:gmatch("%S+") do
            local wordSize = utf8.len(word) or string.len(word)
            if currentRowSize + wordSize <= rowMaxSize then
                currentRowSize = currentRowSize + wordSize + 1
            else
                rowCount = rowCount + 1
                currentRowSize = wordSize ---@diagnostic disable-line: cast-local-type
            end
            table.insert(words, word)
        end
        rowCount = rowCount + 1
    end
    rowCount = rowCount - 1
    return rowCount * fontSize, rowCount
end


function this.getUIScale()
	local width = ui.layers[ui.layers.indexOf("HUD")].size.x
	local screenSize = ui.screenSize()
	return screenSize.x / width
end


function this.getScaledScreenSize()
    return ui.layers[ui.layers.indexOf("HUD")].size
end


return this