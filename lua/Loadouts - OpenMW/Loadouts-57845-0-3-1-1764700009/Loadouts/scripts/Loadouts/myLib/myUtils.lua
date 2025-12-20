local core = require('openmw.core')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local ui = require('openmw.ui')



local mouse = {
        x = 0,
        y = 0,
}

mouse.setX = function(value)
        mouse.x = value
end
mouse.setY = function(value)
        mouse.y = value
end



local function throt(o, delay, action)
        if not o.set then
                o.till = core.getRealTime() + delay
                o.set = true
        end

        if core.getRealTime() > o.till then
                action()
                o.set = false
        end
end


---@type table<string, [number, function]>
local currentDebounces = {}

local function debounce(actionName, delay, action)
        if not currentDebounces[actionName] then
                currentDebounces[actionName] = { core.getRealTime() + delay, action }
        else
                currentDebounces[actionName][1] = core.getRealTime() + delay
                currentDebounces[actionName][2] = action
        end
end


local function snapFloor(value, to)
        return math.floor(value / to) * to
end


local function lerp(a, b, r)
        return a + (b - a) * (1 - r ^ (core.getRealFrameDuration() * core.getSimulationTimeScale()))
end

-- t: current time
-- b: beginning value
-- c: total change in value
-- d: duration
local function easeInExpo(t, b, c, d)
        if t == 0 then
                return b
        end
        t = t / d
        return c * math.pow(2, 10 * (t - 1)) + b
end


local debugTextEl

local function setDebugText(text)
        if not debugTextEl then
                debugTextEl = ui.create({
                        layer = 'Notification',
                        -- layer = 'Windows',
                        template = I.MWUI.templates.textNormal,
                        props = {
                                text = 'testing testing',
                                textSize = 14,
                                multiline = true,
                                position = util.vector2(10, 10),
                        }
                })
        end

        debugTextEl.layout.props.text = tostring(text)
        debugTextEl:update()
        -- ui.updateAll()
end

return {
        throt = throt,
        lerp = lerp,
        easeInExpo = easeInExpo,
        setDebugText = setDebugText,
        snapFloor = snapFloor,
        mouse = mouse,
        currentDebounces = currentDebounces,
        debounce = debounce,
}
