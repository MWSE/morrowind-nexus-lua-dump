--
-- flux
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--


---@class FluxTween
---@field obj table
---@field rate number
---@field progress number
---@field _delay number
---@field _ease string
---@field vars table
---@field way number
---@field inited boolean?
---@field paused boolean?
---@field finished boolean?
---@field parent FluxGroup?
---@field _onstart function?
---@field _onupdate function?
---@field _oncomplete function?
---@field _onrewindcomplete function?
---@field _oncyclecomplete function?
---@field _dt number?
---@field g_tick table?
---@field _tick table?
local FluxTween = {}
FluxTween.__index = FluxTween

---@class FluxGroup
---@field _tick table?
---@field tweens FluxTween[]
local FluxGroup = {}
FluxGroup.__index = FluxGroup

---@class Flux
local flux = { _version = "0.1.5" }
flux.__index = flux

flux.tweens = {}

---@class FluxEasingFunctions
flux.easing = {
        ---@param p number
        ---@return number
        linear = function(p) return p end,

        ---@param p number
        ---@return number
        quadin = function(p) return p * p end,

        ---@param p number
        ---@return number
        quadout = function(p)
                p = 1 - p
                return 1 - (p * p)
        end,

        ---@param p number
        ---@return number
        quadinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (p * p)
                else
                        p = 2 - p
                        return 0.5 * (1 - (p * p)) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        cubicin = function(p) return p * p * p end,

        ---@param p number
        ---@return number
        cubicout = function(p)
                p = 1 - p
                return 1 - (p * p * p)
        end,

        ---@param p number
        ---@return number
        cubicinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (p * p * p)
                else
                        p = 2 - p
                        return 0.5 * (1 - (p * p * p)) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        quartin = function(p) return p * p * p * p end,

        ---@param p number
        ---@return number
        quartout = function(p)
                p = 1 - p
                return 1 - (p * p * p * p)
        end,

        ---@param p number
        ---@return number
        quartinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (p * p * p * p)
                else
                        p = 2 - p
                        return 0.5 * (1 - (p * p * p * p)) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        quintin = function(p) return p * p * p * p * p end,

        ---@param p number
        ---@return number
        quintout = function(p)
                p = 1 - p
                return 1 - (p * p * p * p * p)
        end,

        ---@param p number
        ---@return number
        quintinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (p * p * p * p * p)
                else
                        p = 2 - p
                        return 0.5 * (1 - (p * p * p * p * p)) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        expoin = function(p) return 2 ^ (10 * (p - 1)) end,

        ---@param p number
        ---@return number
        expoout = function(p)
                p = 1 - p
                return 1 - (2 ^ (10 * (p - 1)))
        end,

        ---@param p number
        ---@return number
        expoinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (2 ^ (10 * (p - 1)))
                else
                        p = 2 - p
                        return 0.5 * (1 - (2 ^ (10 * (p - 1)))) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        sinein = function(p) return -math.cos(p * (math.pi * 0.5)) + 1 end,

        ---@param p number
        ---@return number
        sineout = function(p)
                p = 1 - p
                return 1 - (-math.cos(p * (math.pi * 0.5)) + 1)
        end,

        ---@param p number
        ---@return number
        sineinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (-math.cos(p * (math.pi * 0.5)) + 1)
                else
                        p = 2 - p
                        return 0.5 * (1 - (-math.cos(p * (math.pi * 0.5)) + 1)) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        circin = function(p) return -(math.sqrt(1 - (p * p)) - 1) end,

        ---@param p number
        ---@return number
        circout = function(p)
                p = 1 - p
                return 1 - (-(math.sqrt(1 - (p * p)) - 1))
        end,

        ---@param p number
        ---@return number
        circinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (-(math.sqrt(1 - (p * p)) - 1))
                else
                        p = 2 - p
                        return 0.5 * (1 - (-(math.sqrt(1 - (p * p)) - 1))) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        backin = function(p) return p * p * (2.7 * p - 1.7) end,

        ---@param p number
        ---@return number
        backout = function(p)
                p = 1 - p
                return 1 - (p * p * (2.7 * p - 1.7))
        end,

        ---@param p number
        ---@return number
        backinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (p * p * (2.7 * p - 1.7))
                else
                        p = 2 - p
                        return 0.5 * (1 - (p * p * (2.7 * p - 1.7))) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        elasticin = function(p) return -(2 ^ (10 * (p - 1)) * math.sin((p - 1.075) * (math.pi * 2) / 0.3)) end,

        ---@param p number
        ---@return number
        elasticout = function(p)
                p = 1 - p
                return 1 - (-(2 ^ (10 * (p - 1)) * math.sin((p - 1.075) * (math.pi * 2) / 0.3)))
        end,

        ---@param p number
        ---@return number
        elasticinout = function(p)
                p = p * 2
                if p < 1 then
                        return 0.5 * (-(2 ^ (10 * (p - 1)) * math.sin((p - 1.075) * (math.pi * 2) / 0.3)))
                else
                        p = 2 - p
                        return 0.5 * (1 - (-(2 ^ (10 * (p - 1)) * math.sin((p - 1.075) * (math.pi * 2) / 0.3)))) + 0.5
                end
        end,

        ---@param p number
        ---@return number
        bouncein = function(p)
                local one_minus_p = 1 - p
                if one_minus_p < 1 / 2.75 then
                        return 1 - (7.5625 * one_minus_p * one_minus_p)
                elseif one_minus_p < 2 / 2.75 then
                        return 1 - (7.5625 * (one_minus_p - (1.5 / 2.75)) * (one_minus_p - (1.5 / 2.75)) + 0.75)
                elseif one_minus_p < 2.5 / 2.75 then
                        return 1 - (7.5625 * (one_minus_p - (2.25 / 2.75)) * (one_minus_p - (2.25 / 2.75)) + 0.9375)
                else
                        return 1 - (7.5625 * (one_minus_p - (2.625 / 2.75)) * (one_minus_p - (2.625 / 2.75)) + 0.984375)
                end
        end,

        ---@param p number
        ---@return number
        bounceout = function(p)
                p = 1 - p
                local result
                if p < 1 / 2.75 then
                        result = 7.5625 * p * p
                elseif p < 2 / 2.75 then
                        result = 7.5625 * (p - (1.5 / 2.75)) * (p - (1.5 / 2.75)) + 0.75
                elseif p < 2.5 / 2.75 then
                        result = 7.5625 * (p - (2.25 / 2.75)) * (p - (2.25 / 2.75)) + 0.9375
                else
                        result = 7.5625 * (p - (2.625 / 2.75)) * (p - (2.625 / 2.75)) + 0.984375
                end
                return 1 - result
        end,

        ---@param p number
        ---@return number
        bounceinout = function(p)
                p = p * 2
                if p < 1 then
                        local one_minus_p = 1 - p
                        local result
                        if one_minus_p < 1 / 2.75 then
                                result = 7.5625 * one_minus_p * one_minus_p
                        elseif one_minus_p < 2 / 2.75 then
                                result = 7.5625 * (one_minus_p - (1.5 / 2.75)) * (one_minus_p - (1.5 / 2.75)) + 0.75
                        elseif one_minus_p < 2.5 / 2.75 then
                                result = 7.5625 * (one_minus_p - (2.25 / 2.75)) * (one_minus_p - (2.25 / 2.75)) + 0.9375
                        else
                                result = 7.5625 * (one_minus_p - (2.625 / 2.75)) * (one_minus_p - (2.625 / 2.75)) +
                                    0.984375
                        end
                        return 0.5 * (1 - result)
                else
                        p = 2 - p
                        local result
                        if p < 1 / 2.75 then
                                result = 7.5625 * p * p
                        elseif p < 2 / 2.75 then
                                result = 7.5625 * (p - (1.5 / 2.75)) * (p - (1.5 / 2.75)) + 0.75
                        elseif p < 2.5 / 2.75 then
                                result = 7.5625 * (p - (2.25 / 2.75)) * (p - (2.25 / 2.75)) + 0.9375
                        else
                                result = 7.5625 * (p - (2.625 / 2.75)) * (p - (2.625 / 2.75)) + 0.984375
                        end
                        return 0.5 * (1 - result) + 0.5
                end
        end
}


---@type FluxEasingFunctions
flux.easeTable = {}
for key, _ in pairs(flux.easing) do
        flux.easeTable[key] = key
end


-- Helper functions
local function makefsetter(field)
        ---@param self FluxTween
        ---@param x function
        ---@return FluxTween
        return function(self, x)
                -- Simplified check: just verify it's callable by trying to call it
                if type(x) ~= "function" then
                        -- For non-function values, check if it's a table with __call metamethod
                        if type(x) ~= "table" or not getmetatable(x) or not getmetatable(x).__index then
                                error("expected function or callable", 2)
                        end
                end

                local old = self[field]
                self[field] = old and function(...)
                        old(...)
                        x(...)
                end or x
                return self
        end
end

local function makesetter(field, checkfn, errmsg)
        ---@param self FluxTween
        ---@param x any
        ---@return FluxTween
        return function(self, x)
                if checkfn and not checkfn(x) then
                        error(errmsg:gsub("%$x", tostring(x)), 2)
                end
                self[field] = x
                return self
        end
end

-- Tween method setters
FluxTween.ease = makesetter("_ease",
        function(x) return flux.easing[x] ~= nil end,
        "bad easing type '$x'")

FluxTween.delay = makesetter("_delay",
        function(x) return type(x) == "number" end,
        "bad delay time; expected number")

FluxTween.rewind = makesetter("_rewind",
        function(x) return type(x) == "number" or type(x) == "boolean" end,
        "bad rewind time; expected number or boolean")

FluxTween.cycle = makesetter("_cycle",
        function(x) return type(x) == "number" or type(x) == "boolean" end,
        "bad cycle value; expected number or boolean")

FluxTween.onstart = makefsetter("_onstart")
FluxTween.onupdate = makefsetter("_onupdate")
FluxTween.oncomplete = makefsetter("_oncomplete")
FluxTween.onrewindcomplete = makefsetter("_onrewindcomplete")
FluxTween.oncyclecomplete = makefsetter("_oncyclecomplete")

---@param tween_group FluxGroup?
---@param i number?
---@param deltatime number
---@param t FluxTween?
local function update_tween(tween_group, i, deltatime, t)
        t = t or tween_group[i]
        if not t or t.paused then
                return
        end
        t._dt = deltatime
        if t._delay > 0 then
                t._delay = t._delay - deltatime
                if t._delay <= 0 then
                        t._dt = -t._delay
                        t._delay = 0
                end
        end
        if t._delay > 0 then
                return
        end
        if t._dt <= 0 then
                return
        end
        if not t.inited then
                if tween_group then
                        flux.clear(tween_group, t.obj, t.vars)
                end
                t:init()
        end
        if t._onstart then
                t._onstart()
                t._onstart = nil
        end
        local remain = (1 - t.progress) / t.rate
        t.progress = t.progress + t.rate * t._dt
        local p = t.progress
        local x = p >= 1 and 1 or flux.easing[t._ease](p)
        for k, v in pairs(t.vars) do
                t.obj[k] = v.start + x * v.diff * t.way
        end
        if t._onupdate then t._onupdate(deltatime) end
        if p < 1 then
                return
        end
        t._dt = t._dt - remain
        if t._rewind and (t._rewind == true or t._rewind > 1) then
                t.progress = 0
                t._rewind = (t._rewind == true) or (t._rewind - 1)
                t.way = t.way * -1
                for k, v in pairs(t.vars) do
                        t.vars[k].start = t.obj[k]
                end
                if t._onrewindcomplete then t._onrewindcomplete() end
        elseif t._cycle and (t._cycle == true or t._cycle > 1) then
                t.progress = 0
                t._cycle = (t._cycle == true) or (t._cycle - 1)
                if t._oncyclecomplete then t._oncyclecomplete() end
        else
                if tween_group then
                        flux.remove(tween_group, i)
                end
                t.finished = true
                if t._oncomplete then t._oncomplete(t.obj) end
                if t.g_tick then t.g_tick.paused = false end
        end
end

---Create a new tween
---@param obj table
---@param time number
---@param vars table
---@return FluxTween
function FluxTween.new(obj, time, vars)
        local self = setmetatable({}, FluxTween)
        self.obj = obj
        self.rate = time > 0 and 1 / time or 0
        self.progress = time > 0 and 0 or 1
        self._delay = 0
        self._ease = "quadout"
        self.vars = {}
        self.way = 1
        for k, v in pairs(vars) do
                if type(v) ~= "number" then
                        error("bad value for key '" .. k .. "'; expected number")
                end
                self.vars[k] = v
        end
        return self
end

---Initialize tween values
function FluxTween:init()
        for k, v in pairs(self.vars) do
                local x = self.obj[k]
                if type(x) ~= "number" then
                        error("bad value on object key '" .. k .. "'; expected number")
                end
                self.vars[k] = { start = x, diff = v - x }
        end
        self.inited = true
end

---Update tween
---@param dt number
function FluxTween:update(dt)
        update_tween(nil, nil, dt, self)
end

---Chain another tween after this one
---@param ... any
---@return FluxTween
function FluxTween:after(...)
        local t
        if select("#", ...) == 2 then
                t = FluxTween.new(self.obj, ...)
        else
                t = FluxTween.new(...)
        end
        t.parent = self.parent
        self:oncomplete(function()
                flux.add(self.parent, t)
                update_tween(self.parent, #self.parent, self._dt or 0)
        end)
        return t
end

---Wait for delay
---@param t number
---@param f function?
---@return table
function FluxTween:wait(t, f)
        local tick = self.parent._tick
        assert(tick, "No tick set!", 2)
        local td = tick:delay(t, f)
        td.paused = true
        td._flux = self.parent
        self.g_tick = td
        return td
end

---Pause the tween
function FluxTween:pause()
        self.paused = true
end

---Resume the tween
function FluxTween:resume()
        self.paused = false
end

---Stop the tween
function FluxTween:stop()
        flux.remove(self.parent, self)
end

---Detach tween from group
---@return FluxTween
function FluxTween:detach()
        flux.remove(self.parent, self)
        return self
end

---Create a new tween group
---@return FluxGroup
function flux.group()
        return setmetatable({}, flux)
end

---Set tick library
---@param lib table
function flux:tick(lib)
        self._tick = lib
end

---Create a new tween in this group
---@param obj table
---@param time number
---@param vars table
---@return FluxTween
function flux:to(obj, time, vars)
        return flux.add(self, FluxTween.new(obj, time, vars))
end

---Alias for to
---@param ... any
function flux:__call(...)
        return self:to(...)
end

---Update all tweens in group
---@param deltatime number
function flux:update(deltatime)
        for i = #self, 1, -1 do
                update_tween(self, i, deltatime)
        end
end

---Clear tweens for object
---@param obj table
---@param vars table
function flux:clear(obj, vars)
        for t in pairs(self[obj] or {}) do
                if t.inited then
                        for k in pairs(vars) do t.vars[k] = nil end
                end
        end
end

---Add tween to group
---@param tween FluxTween
---@return FluxTween
function flux:add(tween)
        -- Add to object table, create table if it does not exist
        local obj = tween.obj
        self[obj] = self[obj] or {}
        self[obj][tween] = true

        if self._tick then
                tween._tick = self._tick
        end

        -- Add to array
        table.insert(self, tween)
        tween.parent = self
        return tween
end

---Remove tween from group
---@param x FluxTween|number
---@return FluxTween?
function flux:remove(x)
        if type(x) == "number" then
                -- Remove from object table, destroy table if it is empty
                local obj = self[x].obj
                self[obj][self[x]] = nil
                if not next(self[obj]) then self[obj] = nil end
                -- Remove from array
                self[x] = self[#self]
                return table.remove(self)
        end
        for i, v in ipairs(self) do
                if v == x then
                        return flux.remove(self, i)
                end
        end
end

-- Create bound instance for global use
local bound = {
        to = function(...) return flux.to(flux.tweens, ...) end,
        update = function(...) return flux.update(flux.tweens, ...) end,
        remove = function(...) return flux.remove(flux.tweens, ...) end,
        group = flux.group,
        easing = flux.easing,
        easeTable = flux.easeTable,
}
setmetatable(bound, flux)

return bound
