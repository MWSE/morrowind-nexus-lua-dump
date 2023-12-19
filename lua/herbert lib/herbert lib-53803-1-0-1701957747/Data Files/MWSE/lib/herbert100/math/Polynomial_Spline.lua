local Class = require("herbert100.Class")
local herbertmath = require("herbert100.math.core")

local deriv_approx = herbertmath.deriv_approx
local solve_tridiagional_system = herbertmath.solve_tridiagional_system



---@class spline_params
---@field f fun(x: number): number the function to interpolate
---@field points number[] points to interpolate at
---@field boundary_conditions "trivial"|"deriv"|nil which boundary conditions to use
---@field f_vals number[]? value of `f` at each point

--[[## Polynomial Splines
these are used for spline interpolation, ie giving nice approximations of single-variable functions.
you can make a new one by specifying the function to interpolate, and then a list of points to interpolate the function at.
it's recommended that you use the `Evenly_Spaced_Spline` instead, though, since that one is quite a bit faster (but perhaps more limited idk).
]]
---@class Polynomial_Spline : Class
---@field f fun(number): number  # the function being interpolated, this will be used if an out of range point is passed during evaluation
---@field f_vals number[]  # values of f at each point. will be generated on object creation.
---@field points number[] # a list of EVENLY SPACED points, STARTING AT INDEX 0 (the first point)
---@field coeffs number[][] # coefficients of polynomials, generated on object creation. don't worry about this.
---@field n integer # the number of points. don't worry about this either.
---@field lower_bound number
---@field upper_bound number
---@field boundary_conditions "trivial"|"deriv"|nil how to compute boundary conditions.
---@field new fun(params: spline_params): Polynomial_Spline
local Polynomial_Spline = Class{name = "Polynomial Spline",
    post_init = function(self)
        if not self.f_vals then
            self.f_vals = {}
            for i,p in pairs(self.points) do
                self.f_vals[i] = self.f(p)
            end
        end
        self:_generate_spline()
    end,
    obj_metatable = {
        __tostring = function(self) 
            local table_copy = require("herbert100").table_copy
            local Polynomial = require("herbert100").math.Polynomial
            local strings = {string.format("%s with piecewise components:", self.__secrets.name)}
            for i=1, self.n do
                local coeffs = self.coeffs[i]
                local coeffs_copy = table_copy(coeffs)
                local lp, up = self.points[i-1], self.points[i]
                strings[#strings+1] = string.format("%6s ≤ t ≤ %-6s: %s",
                    -- tostring(math.floor(lp*100)/100),  tostring(math.floor(up*100)/100),
                    math.round(lp,2), math.round(up,2),
                    tostring(Polynomial.new(coeffs_copy))
                )
            end
            return table.concat(strings, "\n")
        end,
        __eq = function(self, other)
            if not other.coeffs or not other.n or self.n ~= other.n then return false end 

            for i=0, self.n do 
                if self.points[i] ~= other.points[i] then return false end

            end
            for i=1, self.n do 
                for k=0,3 do 
                    if self.coeffs[i][k] ~= other.coeffs[i][k] then return false end
                end
            end

            return true
        end,
        __mul = function(self, num)
            if type(self) == "number" then return num * self end
            local p = {coeffs = {}, points = self.points, n = self.n, dist = self.dist}
            if self.f then 
                p.f = function(x) return num*self.f(x) end 
            end

            for i, coeffs in pairs(self.coeffs) do 
                p.coeffs[i] = {}
                p.coeffs[i][0] = num * coeffs[0]
                p.coeffs[i][1] = num * coeffs[1]
                p.coeffs[i][2] = num * coeffs[2]
                p.coeffs[i][3] = num * coeffs[3]
            end
            p.lower_bound = self.lower_bound
            p.upper_bound = self.upper_bound
            p.index_by_points = self.index_by_points
            p.__HCI = true

            setmetatable(p, getmetatable(self))

            return p
        end,
        __add = function(self, num)
            if type(self) == "number" then return num + self end
            local p = {coeffs = {}, points = self.points, n = self.n, dist = self.dist}
            if self.f then
                p.f = function(x) return self.f(x) + num end 
            end

            for i, coeffs in pairs(self.coeffs) do 
                p.coeffs[i] = {}
                p.coeffs[i][0] = coeffs[0] + num
                p.coeffs[i][1] = coeffs[1]
                p.coeffs[i][2] = coeffs[2]
                p.coeffs[i][3] = coeffs[3]
            end
            p.lower_bound = self.lower_bound
            p.upper_bound = self.upper_bound
            p.index_by_points = self.index_by_points
            p.__HCI = true
            setmetatable(p, getmetatable(self))

            return p
        end,
        __call = function(self, x)
            if x >= self.points[self.n] then 
                return x == self.points[self.n] and self.f_vals[self.n] or self.f(x)
            elseif x < self.points[0] then
                return self.f(x)
            end
            local coeffs, pt 
            -- now find the closest point 
            -- print("in uneven_call: x = " .. x)
            for i=1, self.n do 
                -- print("\ti = " .. i .. ", \t pts[i] = " .. self.points[i])
                if x <= self.points[i] then 
                    -- print("found match!")
                    coeffs = self.coeffs[i]
                    pt = self.points[i-1]
                    break
                end
            end
            x = x - pt
            -- evaluate using Horner's method to cut down on the number of multiplications we do
            return coeffs[0] + x * (coeffs[1] + x * (coeffs[2] + x * coeffs[3]))
        end,
    }
}

--- make a new spline from pairs of points.
---@param xy_pairs number[][]
---@return Polynomial_Spline
function Polynomial_Spline.new_from_xy_pairs(xy_pairs)
    local points, f_vals = {}, {}
    if xy_pairs[0] then 
        for i, xy_pair in pairs(xy_pairs) do
            points[i], f_vals[i] = table.unpack(xy_pair)
        end
    else
        for i, xy_pair in ipairs(xy_pairs) do
            points[i-1], f_vals[i-1] = table.unpack(xy_pair)
        end 
    end
    local f = function(x)
        if x >= points[#points] then return f_vals[#points]
        elseif x <= points[0]   then return f_vals[0]
        else
            for i,p in ipairs(points) do
                if x <= p then return f_vals[i] end
            end
        end
    end
    return Polynomial_Spline.new({points = points, f = f, f_vals = f_vals})     
end

function Polynomial_Spline:_generate_spline()
   -- compute function at those points
    -- local f_vals, fpp_vals = {}, {}
 
    self.coeffs = {}
    self.n = #self.points

    -- local fp_vals = {}
    local a_0,a_1,a_2,a_3 = {},{},{}, {}
    -- gonna take the form dt^3 + ct^2 + bt + a

    for i=0, self.n do
        a_0[i] = self.f_vals[i]
    end
    -- setup h (difference between values of f)
    -- setup d (diagonal of the matrix)
    local h, d = {}, {}
    for i=0, self.n-1 do
        h[i] = self.points[i+1]-self.points[i]
    end
    for i=1,self.n-1 do 
        d[i] = 2 *(h[i-1] + h[i])
    end

    local deriv = deriv_approx(self.f)


    local b = {}
    for i=1, self.n-1 do
        -- print(h[i])
        b[i] = 3/h[i] * (a_0[i+1]-a_0[i]) - 3/h[i-1] * (a_0[i]-a_0[i-1])
        -- print(b[i])
    end


    -- solve the system
    a_2 = solve_tridiagional_system(h,d,h,b)

    if not self.f or self.boundary_conditions == "trivial" then
    -- a_2 is c in the paper
    -- basic condition
        a_2[0],a_2[self.n] = 0,0
    else
        -- clamped condition: 
        -- 2*h[0]*a_2[0] +  h[0] * a_2[1]  = 3 * (a_0[1] - a_0[0])/h[0] - 3 * deriv(points[0]) 
        a_2[0]  = (3 * (a_0[1] - a_0[0])/h[0] - 3 * deriv(self.points[0]) - h[0] * a_2[1])/ (2 * h[0])
        -- h[n-1]*c[n-1] + 2h[n-1]*c[n] = -3/h[n-1] * (a[n] - a[n-1]) + 3 * deriv(self.points[n])
        a_2[self.n] = (-3/h[self.n-1] * (a_0[self.n] - a_0[self.n-1]) + 3 * deriv(self.points[self.n]) - h[self.n-1] * a_2[self.n-1])/ (2 * h[self.n-1])
    end

    for i=0, self.n-1 do
        a_1[i] = (a_0[i+1]-a_0[i])/h[i] - (2*a_2[i]+a_2[i+1])*h[i]/3
        a_3[i] = (a_2[i+1]-a_2[i])/(3 * h[i])

        local a_0p, a_1p, a_2p, a_3p= a_0[i], a_1[i], a_2[i], a_3[i]
        self.coeffs[i+1] = {[0]=a_0p, a_1p, a_2p, a_3p,}
        -- obj.polynomials[i+1] = a_0p + a_1p * (t - x) + a_2p *  (t - x)^2 + a_3p * (t-x)^3
        -- obj.polynomials[i+1] = a_0p + a_1p * (t - x) + a_2p *  (t - x)^2 + a_3p * (t-x)^3
        -- print("f(" .. x .. ") = " .. f_vals[i])
        -- print("p_i(" .. x .. ") = " .. obj.polynomials[i+1](x))
        
    end
    -- make the polynomial

    -- obj.coeffs[#obj.coeffs+1] = obj.coeffs[#obj.coeffs]


end



---@class evenly_spaced_spline_params
---@field dist number? distance between points
---@field lower_bound number? lowest point to interpolate
---@field upper_bound number? highest point to interpolate
---@field f fun(x:number): number the function to interpolate
---@field points number[]? the points to interpolate. MUST BE EVENLY SPACED. can be passed instead of `lower_bound`, `upper_bound`, and `dist`.

--[[## Evenly_Spaced_Spline
this lets you create a polynomial spline by passing in four things:
- `f`: the function to interpolate
- `lower_bound`: the lowest value to interpolate
- `upper_bound`: the highest to interpolate
- `dist` the distance between the points used to approximate the function.
    - having this be a lower number will increase the accuracy of the interpolation, but will use more memory.

after it is created, you can call the `Spline` just like a normal function: eg by typing `spline(x)`.
]]
---@class Evenly_Spaced_Spline : Polynomial_Spline
---@field dist number the distance between points.
---@field index_by_points table<number, integer> returns the index of a given point.
---@field new fun(params:evenly_spaced_spline_params): Evenly_Spaced_Spline
local Evenly_Spaced_Spline = Class{name = "Evenly Spaced Polynomial Spline", parents={Polynomial_Spline},
    post_init = function(self)
        -- make new points if none were given.
        if not self.points then 
            self.points = {}
            self.points[0] = self.lower_bound
            repeat
                self.points[#self.points+1] = self.points[#self.points] + self.dist
            until self.points[#self.points] >= self.upper_bound
        else
            self.lower_bound = self.points[0]
            self.upper_bound = self.points[#self.points]
            self.dist = self.points[1] - self.points[0]
        end
    
        Polynomial_Spline.__secrets.post_init(self)
        self.dist = self.points[1] - self.points[0]
        self.index_by_points = {}
        for i,pt in pairs(self.points) do
            self.index_by_points[pt] = i
        end
    end,
    obj_metatable = {__call = function(self, x)
        
        if x < self.lower_bound or self.upper_bound <= x then
            --[[
                we're treating the special case `x == self.points[self.n]` separately because the algorithm below has trouble with it. 

                more specifically, the code below would set `pt = self.points[self.n]`, and then look for `self.coeffs[self.n+1]`, which doesn't exist.
                
                it would do this because every other polynomial is defined on the interval `[pt, next_pt]`, whereas in this special case, there is no `next_pt`.

                there are a few different was to solve this problem, but i chose this one for performance reasons.

                this case happens so rarely that it's better to make the most common scenario, `lower_bound <= x < upperbound`, as efficient as possible
            ]]
            if x == self.upper_bound then 
                local coeffs = self.coeffs[self.n]
                x = x - self.points[self.n-1]
                return coeffs[0] + x * (coeffs[1] + x * (coeffs[2] + x * coeffs[3]))
            else
                return self.f(x)
            end
         end
        

        --[[get the largest point in `self.points` that's smaller than x.
            the formula should really be 
                `pt` = `x - math.abs( x - self.points[0]) % self.dist`,
            but we're now working under the assumption that x >= self.points[0], so we don't need to take absolute values
        ]]
        local pt = x  - (x -self.lower_bound) % self.dist 


        -- print("in even_call: x = " .. x .. " \tpt = " .. pt )
        -- print("\tx - x % dist = " .. (x - x % self.dist))
        -- print("\tx - | x - pts[0] | % dist = " .. (x - math.abs(-self.points[0] + x )% self.dist))
        
        --[[ the polynomial we're interested in is defined on the interval [ `pt`, `next_pt` ].
            this means that if `pt` has index `i` and `next_pt` has index `i+1`, then we want the polynomial `p[i+1]`, since `p[i+1]` is the 
            polynomial for the interval `[ pts[i], pts[i+1] ]`
        ]]
        local coeffs = self.coeffs[self.index_by_points[pt]+1] -- relevant polynomial is the next one
       
        -- print(string.format("\t\tcoeffs = %3.4ft^3 + %3.4ft^2 + %3.4ft + %3.4f", coeffs[3], coeffs[2], coeffs[1], coeffs[0]))
        

        -- the coeffiences are really the coefficients of the polynomial a_0 + a_1(x-pt) + a_2(x-pt)^2 + a_3(x-pt)^3
        x = x - pt

        -- evaluate using Horner's method to cut down on the number of multiplications performed
        return coeffs[0] + x * (coeffs[1] + x * (coeffs[2] + x * coeffs[3]))
    end,}

}

return {Polynomial_Spline = Polynomial_Spline, Evenly_Spaced_Spline = Evenly_Spaced_Spline}