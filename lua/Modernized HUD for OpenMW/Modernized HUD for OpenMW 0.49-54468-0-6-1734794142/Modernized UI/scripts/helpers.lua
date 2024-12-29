local ui = require("openmw.ui")
local time = require('openmw_aux.time')
local util = require('openmw.util')
local v2 = util.vector2

local barWidth = 12
local gap = 3

local oscillation = 0

-- Templates
spacer = { type = ui.TYPE.Widget, props = { size = v2(0, gap) } }

-- Helper functions
function smoothstep(a, b, t)
    local ft = t * t * (3 - 2 * t)
    return a + ft * (b - a)
end

-- Function that checks if value is in range and returns bool
function isInRange(value, min, max)
    return value >= min and value <= max
end

-- Make a function that oscillates between black and white based on time
function oscillateBackground(deltaTime)
    oscillation = oscillation + deltaTime
    local f = 0.2 + math.sin(oscillation) / 4
    return util.color.rgb(f * (1), f * (0.2), f * (0.2))
end

function l(length)
	return v2(length, barWidth)
end

function abbreviateNumber(number)
    local suffixes = {"", "K", "M", "B", "T"}  -- Add more suffixes as needed
    
    local index = 1
    while number >= 1000 and index < #suffixes do
        number = number / 1000
        index = index + 1
    end
    
    -- Check if the decimal part is zero, if so, remove it
    local formattedNumber = string.format("%.1f", number)
    if formattedNumber:sub(-2) == ".0" then
        formattedNumber = formattedNumber:sub(1, -3)
    end
    
    return formattedNumber .. suffixes[index]
end