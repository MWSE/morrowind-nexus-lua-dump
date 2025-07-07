

local Tweener = {
    easings = {},
    new = function(self)
        local inst = {
            animations = {}
        }

        setmetatable(inst, self)
        self.__index = self
        
        return inst
    end,
    add = function(self, duration, easingFunc, updateFunc)
        table.insert(self.animations, { duration = duration, easingFunc = easingFunc, updateFunc = updateFunc, elapsed = 0 })
        return self
    end,
    tick = function(self, dt)
        self.playing = true
        local anim = self.animations[1]
        if anim then
            anim.elapsed = anim.elapsed + dt
            local t = math.min(anim.elapsed / anim.duration, 1)
            anim.updateFunc(anim.easingFunc(t))
            if t >= 1 then
                table.remove(self.animations, 1)
            end
        end
        if #self.animations == 0 then 
            self.playing = false
        end
    end,
    finish = function(self)
        for _, anim in ipairs(self.animations) do
            anim.updateFunc(1)
        end
        self.animations = {}
        self.playing = false
    end
}

function Tweener.easings.linear(t)
    return t
end

function Tweener.easings.easeOutQuad(t)
    return t * (2 - t)
end

function Tweener.easings.easeInQuad(t)
    return t * t
end

function Tweener.easings.easeInOutQuad(t)
    return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end

function Tweener.easings.easeInCubic(t)
    return t * t * t
end

function Tweener.easings.easeOutCubic(t)
    return 1 - ((1 - t) ^ 3)
end

function Tweener.easings.easeInOutCubic(t)
    return t < 0.5 and 4 * t * t * t or 1 - ((-2 * t + 2) ^ 3) / 2
end

function Tweener.easings.easeInSine(t)
    return 1 - math.cos((t * math.pi) / 2)
end

function Tweener.easings.easeOutSine(t)
    return math.sin((t * math.pi) / 2)
end

function Tweener.easings.easeInOutSine(t)
    return -(math.cos(math.pi * t) - 1) / 2
end

local math_exp = math.exp
local math_cos = math.cos
local math_pi = math.pi

function Tweener.easings.springOutGeneric(x, lambda)
    -- Higher lambda = lower swing amplitude. 1 = 150% swing amplitude.
    -- w is the frequency of oscillation in the easing func, controls the amount of overswing
    local w = 1.5 * math_pi -- 4.71238
    return 1 - math_exp(-lambda * x) * math_cos(w * x)
end

function Tweener.easings.springOutWeak(x)
    return Tweener.easings.springOutGeneric(x, 4)
end

function Tweener.easings.springOutMed(x)
    return Tweener.easings.springOutGeneric(x, 3)
end

function Tweener.easings.springOutStrong(x)
    return Tweener.easings.springOutGeneric(x, 2)
end

function Tweener.easings.springOutTooMuch(x)
    return Tweener.easings.springOutGeneric(x, 1)
end

return Tweener
