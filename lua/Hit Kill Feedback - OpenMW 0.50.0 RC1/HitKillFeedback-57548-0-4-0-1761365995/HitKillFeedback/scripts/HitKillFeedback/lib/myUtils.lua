local core = require('openmw.core')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local ui = require('openmw.ui')

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



local function lerp(a, b, r)
        return a + (b - a) * (1 - r ^ (core.getRealFrameDuration() * core.getSimulationTimeScale()))
end

local function bounce_easing(over, t)
        return over * t * (t - 1)
end

---@param t number current time
---@param b number beginning value
---@param c number total change in value
---@param d number duration
---@return any
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
                        layer = 'HUD',
                        template = I.MWUI.templates.textNormal,
                        props = {
                                text = 'debug text',
                                textSize = 16,
                                multiline = true,
                                relativePosition = util.vector2(0, 0),
                        }
                })
        end

        debugTextEl.layout.props.text = tostring(text)
        debugTextEl:update()
end

return {
        throt = throt,
        lerp = lerp,
        bounce_easing = bounce_easing,
        easeInExpo = easeInExpo,
        setDebugText = setDebugText,
}



