local Class = require("herbert100.Class")

---@class Rational
---@field num number|function|Polynomial # numerator
---@field denom number|function|Polynomial # denom
---@field new fun(num: number|Polynomial, denom:number|Polynomial?): Rational
local Rational = {denom = 1}


Rational = Class({name = "Rational", new_obj_func = "no_obj_data_table",
    obj_metatable = {
        __tostring = function(self)
            if type(self.num) ~= "number" then
                if type(self.denom) ~= "number" then
                    return string.format("(%s) / (%s)", tostring(self.num), tostring(self.denom))
                else
                    return string.format("(%s)/%s", tostring(self.num), self.denom)
                end
                
            else -- numerator is a number

                if type(self.denom) ~= "number" then
                    return string.format("%s/(%s)", self.num, self.denom)
                else
                    return string.format("%s/%s", self.num, self.denom)
                end
                
            end
        end,
        __mul = function(r1,r2)
            -- if the second term isn't a `Rational`, but the first term is
            if type(r2) == "number" or not r2:is_instance_of(Rational) then 
                return Rational(r1.num*r2, r1.denom)

            -- if the first term isn't a `Rational`, but the second term is
            elseif type(r1) == "number" or not r1:is_instance_of(Rational) then 
                return Rational(r2.num*r1, r2.denom)

            -- if both terms are `Rational`
            else
                return Rational(
                    r1.num*r2.num,
                    r1.denom * r2.denom
                )
            end
        end,
        __add = function(r1,r2)
            if type(r2) == "number" or not r2:is_instance_of(Rational) then 
                return Rational(
                    r1.num + r2*r1.denom,
                    r1.denom
                )
            elseif type(r1) == "number" or not r1:is_instance_of(Rational) then 
                return Rational(
                    r2.num + r1*r2.denom,
                    r2.denom
                )
            else
                return Rational(
                    r1.num*r2.denom + r2.num*r1.denom,
                    r1.denom*r2.denom
                )
            end
            
        end,
        __unm = function(self)
            return Rational(-self.num, self.denom)
        end,
        __sub = function(p1, p2) return (-p2) + p1  end,
        __pow = function(self, exp)
            if exp >= 0 then 
                return Rational(self.num^exp, self.denom^exp)
            else
                return Rational(self.denom^(-exp), self.num^(-exp))
            end
        end,
        __div = function(num, denom)
            return Rational(num,denom)
        end,
        __call = function(self, x)
            local res
            if type(self.num) == "number" then 
                res = self.num
            else
                res = self.num(x)
            end

            if type(self.denom) == "number" then 
                return res / self.denom
            else
                return res / self.denom(x)
            end
        end,
    },
    init = function(self, num, denom)
        denom = denom or 1
        -- the actual numberator and denominator that well use
        local _num, _denom = 1,1
        
        -- we need to perform some somplifications so that we dont get stupidly large towers of rational expressions.

        -- if the numerator is a rational expression
        if type(num) ~= "number" and num:is_instance_of(Rational) then
            _num = num.num 
            _denom = num.denom
        else -- the numberator is not a rational expression
            _num = num
        end
        -- if the denominator is a rational expression
        if type(denom) ~= "number" and denom:is_instance_of(Rational) then
            _num = _num * denom.denom
            _denom = _denom * denom.num
        else
            _denom = denom
        end
        
        self.num = _num 
        self.denom = _denom
    end,
}, Rational)

--- convert a `Rational` object back into a number. NOTE: This will only work if the numerator and denominator are both `number`s.
---@param self Rational
---@return number|Rational
function Rational:tonumber()
    return self.num / self.denom
end



return Rational