---@diagnostic disable: return-type-mismatch
local Class = require("herbert100.Class")

local Rational = require("herbert100.math.Rational")

---@class herbert.Polynomial : herbert.Class
---@field indeterminant string the variable of this polynomial. defaults to 't'
---@field new fun(coeffs: number[]|number|string, ...: number): herbert.Polynomial create a new polynomial with these coefficients
local Polynomial = {indeterminant = 't'}
Class.new({name = "Polynomial",
    
    new_obj_func=function (arg1, ...)
        local self
        local at = type(arg1)
        if at == "table" then
            self = arg1
            if not self.indeterminant then
                if type(self[1]) == "string" then
                    self.indeterminant = table.remove(self, 1)
                end
            end

            -- shift values down if `[0]` wasnt specified
            if not self[0] then
                for i=0, #self do
                    self[i] = self[i+1]
                end
            end
        else
            if at == "string" then
                self = {indeterminant=arg1, [0]=..., select(2, ...)}
            else
                self = {[0]=arg1, ...}
            end

        end
        -- make sure leading term is not 0
        for i=#self, 1, -1 do
            if self[i] == 0 then 
                self[i] = nil
            else
                break
            end
        end
        self.n = #self 


        return self
    end,
    
    obj_metatable = {
        __tostring = function(self)
            local strings

            -- build the string in reverse order
            for exp=#self, 0,-1 do
                local coeff = self[exp]
                if type(coeff) ~= "number" then
                    if strings ~= nil then
                        strings[#strings+1]=  " + "
                    else
                        strings = {}
                    end
                    strings[#strings+1] = string.format("(%s)", coeff)
                    -- coefficient has been added, so now lets add the exponent string.
                    goto add_exp
                elseif coeff == 0 -- skip this term if the coefficient is 0
                    then goto continue
                end



                -- we are now sure `coeff` is a number and `coeff ~= 0`.

                -- if this isn't the first term (eg there are terms to the left), add a plus or minus sign
                if strings ~= nil then
                    if coeff > 0 then 
                        strings[#strings+1]=  " + " 
                    else
                        strings[#strings+1]= " - " 
                        coeff = -1 * coeff -- we dont want to print 2 negative signs
                    end
                else
                    strings = {}
                end

                -- only add the coefficient if the exponent is 0 or the coefficient is ~= 1.
                if exp == 0 or coeff ~= 1 then
                    -- if `coeff` has lots of decimal places and its not the constant term, add a "*" sign after the coefficient
                    if exp ~= 0 and coeff * 1000 % 1 ~= 0 then 
                        strings[#strings+1] = string.format("%s*", coeff)
                    else
                        strings[#strings+1] = coeff
                    end
                end

                ::add_exp::
                if exp == 1 then 
                    strings[#strings+1] = self.indeterminant
                elseif exp > 1 then
                    strings[#strings+1] = string.format("%s^%i", self.indeterminant, exp)
                end

                ::continue::
            end
            -- if we couldnt find any nonzero coefficients, return "0"
            return (strings ~= nil and table.concat(strings)) or "0"
        end,
        __mul = function(p1,p2)
            if not Class.is_instance_of(p1, Polynomial) then
                p1, p2 = p2, p1
            end

            local coeffs = {}
            if type(p2) == 'number' then
                for exp=0,#p1 do 
                    coeffs[exp] = p1[exp] * p2
                end
                return Polynomial.new(coeffs)

            elseif Class.is_instance_of(p2, Rational) then
                return Rational.__secrets.obj_metatable.__mul(p2, p1)

            else
                local min, max = p1, p2 -- assuming #self <= #other
                if #p1 >= #p2 then
                    min, max = p2, p1
                end
                local min_deg = #min
                local max_deg = #max
                local total_deg = #p1 + #p2
                for exp=0,total_deg do
                    -- calculate coefficient for degree i term
                    coeffs[exp] = 0
                    --[[add terms min[i] *max[exp-i]
                        NEED:
                            1) i <= min_deg 
                            2) exp-i <= max_deg ~> i - exp >= -max_deg
                                                ~> i >= exp - max_deg
                    ]]
                    for i=math.max(0,exp-max_deg), math.min(min_deg,exp) do
                        coeffs[exp] = coeffs[exp] + min[i] * max[exp-i]
                    end
                end
                return Polynomial.new(coeffs)
        
            end
        end,
        __div = function(p1, p2) return Rational.new(p1,p2) end,
        __add = function(p1,p2)
            -- make sure `p1` is a `Polynomial`
            if not Class.is_instance_of(p1, Polynomial) then
                p1, p2 = p2, p1
            end

            -- if it's a number, just add it to the constant term and move on
            if type(p2) == 'number' then
                return p1 .. {[0]=p1[0] + p2}

            -- if it's a rational, use it's add function
            elseif p2:is_instance_of(Rational) then
                return Rational.__secrets.obj_metatable.__add(p2, p1)
            else
                local coeffs = {}
                -- need to add each term
                local min, max = p1, p2 -- assuming #self <= #other
                if #p1 >= #p2 then
                    min, max = p2, p1
                end
                for exp=0,#min do
                    coeffs[exp] = min[exp] + max[exp]
                end
                for exp = #min+1, #max do 
                    coeffs[exp] = max[exp]
                end
                return Polynomial.new(coeffs)
            end
        end,
        __unm = function(self) 
            local coeffs = {}
            for exp=0,#self do
                coeffs[exp] = - self[exp]
            end
            return Polynomial.new(coeffs)
        end,
        __sub = function(p1, p2) return p1 + (-p2) end,

        __pow = function(self, exp)
            -- if it's a number, just add it to the constant term
            if exp == 0 then return self.new({[0]=1})
            elseif exp == 1 then return self
            elseif exp > 1 then return self * self^(exp-1)
            elseif exp < 0 then return 1 / self^(-exp)
            end
        end,
        __call = function(self, x)
            local b = self[self.n]
            for i=self.n-1, 0, -1 do 
                -- loop backwards, starting at n-1, ending at 0
                b = self[i]  + b * x
            end
            return b
        end,

        __lt = function(p1,p2)
            if Class.is_instance_of(p1, Polynomial) then
                if type(p2) == "number" then
                    return #p1 == 0 and p1[0] < p2
                elseif Class.is_instance_of(p2, Polynomial) then
                    if #p1 ~= #p2 then return false end
                    for i=0, #p1 do 
                        if p1[i] >= p2[i] then return false end
                    end
                    return true
                end
            elseif type(p1) == "number" then
                return #p2 == 0 and p1 < p2[0]
            end
            return false
        end,
        __le = function(p1,p2)
            if Class.is_instance_of(p1, Polynomial) then
                if type(p2) == "number" then
                    return #p1 == 0 and p1[0] <= p2
                elseif Class.is_instance_of(p2, Polynomial) then
                    if #p1 ~= #p2 then return false end
                    for i=0, #p1 do 
                        if p1[i] > p2[i] then return false end
                    end
                    return true
                end
            elseif type(p1) == "number" then
                return #p2 == 0 and p1 <= p2[0]
            end
            return false
            
        end,
        __eq = function(p1, p2)

            if not Class.is_instance_of(p1, Polynomial) then
                p1,p2 = p2,p1
            end
            if type(p2) == "number" then
                return #p1 == 0 and p1[0] == p2
            elseif Class.is_instance_of(p2, Polynomial) then
                if #p1 ~= #p2 then return false end
                for i=0, #p1 do
                    if p1[i] ~= p2[i] then return false end
                end
                return true
            end
            return false
            
        end,
    },
}, Polynomial)

--- differentiate this `Polynomial`
---@param self herbert.Polynomial
---@return herbert.Polynomial derivative
function Polynomial:differentiate()
    local coeffs = {}
    for exp = 1, #self do 
        coeffs[exp-1] = self[exp] * exp
    end
    return Polynomial.new(coeffs)
end

--- integrate this `Polynomial`
---@param self herbert.Polynomial
---@param C number constant of integration, 0 by default
---@return herbert.Polynomial anti_derivative
function Polynomial:integrate(C)
    local coeffs = {[0] = C or 0}
    for exp = 0, #self do
        coeffs[exp+1] = self[exp] / (exp+1)
    end
    return Polynomial.new(coeffs)
end

--- `t` is the generator of the `R`-algebra `R[t]`, 
--- where `R` is the ring of floating point numbers :)
---@type herbert.Polynomial
Polynomial.t = Polynomial.new(0,1)

return Polynomial