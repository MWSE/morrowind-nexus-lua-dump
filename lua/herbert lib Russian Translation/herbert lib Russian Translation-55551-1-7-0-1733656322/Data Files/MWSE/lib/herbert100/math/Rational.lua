local Class = require("herbert100.Class") -- change this please

---@alias herbert.Rational.num_or_denom
---|herbert.Class
---|number
---|function

---@class herbert.Rational : herbert.Class
---@field num herbert.Rational.num_or_denom # numerator
---@field denom herbert.Rational.num_or_denom # denom
---@field new fun(num: herbert.Rational.num_or_denom, denom:herbert.Rational.num_or_denom?): herbert.Rational
local Rational = {denom = 1}

local function should_call(val)
    local vt = type(val)
    return vt == "function" or vt == "table" and getmetatable(val).__call ~= nil

end
Class.new({name = "Rational",
    new_obj_func = "no_obj_data_table",
    obj_metatable = {
        __tostring = function(self)
            if type(self.num) == "number" then
                if type(self.denom) == "number" then
                    if self.denom == 1 then 
                        return tostring(self.num) 
                    else
                        return string.format("%s/%s", self.num, self.denom)
                    end
                else
                    return string.format("%s/(%s)", self.num, self.denom)
                end
                
            else -- numerator is not a number
                if type(self.denom) == "number" then
                    if self.denom == 1 then 
                        return tostring(self.num)
                    else
                        return string.format("(%s)/%s", self.num, self.denom)
                    end
                else
                    return string.format("(%s) / (%s)", self.num, self.denom)
                end
                
                
            end

        end,
        __mul = function(r1, r2)
            if not Class.is_instance_of(r1, Rational) then
                r1, r2 = r2, r1
            end
            if Class.is_instance_of(r2, Rational) then
                return Rational.new(r1.num * r2.num, r2.denom * r2.denom)
            else
                return Rational.new(r1.num * r2, r1.denom)
            end
        end,
        __add = function(r1,r2)
            if not Class.is_instance_of(r1, Rational) then
                r1, r2 = r2, r1
            end
            if Class.is_instance_of(r2, Rational) then
                return Rational(
                    r1.num*r2.denom + r2.num*r1.denom,
                    r1.denom*r2.denom
                )
            else
                return Rational(r1.num + r2*r1.denom, r1.denom)
            end
            
        end,

        __eq = function (r1, r2)
            if not Class.is_instance_of(r1, Rational) then
                r1, r2 = r2, r1
            end
            if Class.is_instance_of(r2, Rational) then
                return r1.num * r2.denom == r2.num * r1.denom
            else
                return r1.num == r2 * r1.denom
            end
        end,
        __lt = function (r1, r2)
            if not Class.is_instance_of(r1, Rational) then return not (r1 >= r2) end

            if Class.is_instance_of(r2, Rational) then
                return r1.num * r2.denom < r2.num * r1.denom
            else
                return r1.num < r2 * r1.denom
            end
        end,

        __le = function (r1, r2)
            if not Class.is_instance_of(r1, Rational) then return not (r1 > r2) end

            if Class.is_instance_of(r2, Rational) then
                return r1.num * r2.denom <= r2.num * r1.denom
            else
                return r1.num <= r2 * r1.denom
            end
        end,

        __unm = function(self) return Rational(-self.num, self.denom) end,

        __sub = function(p1, p2) return (-p2) + p1  end,

        __pow = function(self, exp)
            if exp >= 0 then 
                return Rational(self.num^exp, self.denom^exp)
            else
                return Rational(self.denom^(-exp), self.num^(-exp))
            end
        end,

        __div = function(num, denom) return Rational(num, denom) end,

        __call = function(self, x)
            return
                (should_call(self.num) and self.num(x) or self.num)
                    /
                (should_call(self.denom) and self.denom(x) or self.denom)
        end,
    },
    init = function(self, num, denom)
        self.num = num
        self.denom = denom
    end,
}, Rational)

--- convert a `Rational` object back into a number. NOTE: This will only work if the numerator and denominator are both `number`s.
---@param self herbert.Rational
---@return number|herbert.Rational
function Rational:tonumber()
    return self.num / self.denom
end

--- simplifies this expression inplace
function Rational:simplify(numbers_too)
    local num, denom = self.num, self.denom
    while true do
        if Class.is_instance_of(num, Rational) then ---@cast num herbert.Rational
            denom = denom * num.denom
            num = num.num
        elseif Class.is_instance_of(denom, Rational) then ---@cast denom herbert.Rational
            num = num * denom.denom
            denom = denom.num
        elseif numbers_too and type(denom) == "number" and denom ~= 1 then
            num = num * ( 1 / denom)
            denom = 1
        else
            break
        end
    end
    self.num = num
    self.denom = denom
end

return Rational