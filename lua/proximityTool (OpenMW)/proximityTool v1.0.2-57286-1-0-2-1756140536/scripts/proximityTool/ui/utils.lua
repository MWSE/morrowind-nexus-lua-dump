local ui = require('openmw.ui')
local util = require('openmw.util')

local this = {}


function this.convertAlign(str, default)
    return ui.ALIGNMENT[str] or (default or ui.ALIGNMENT.End)
end


function this.removeFromContent(content, index)
    local removedEl = table.remove(content, index)
    if not removedEl then return end

    if removedEl.name then
        content.__nameIndex[removedEl.name] = nil
    end

    for i = index, #content do
        local elem = content[i]

        if elem.name then
            content.__nameIndex[elem.name] = i
        end
    end

    return removedEl
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