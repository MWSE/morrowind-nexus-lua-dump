
local function arcsinh(x) 
    return math.log(x+ math.sqrt(x^2+1))
end

local function f(x) 
    return (math.atan(x - math.pi/2) + math.atan(math.pi/2))/(math.pi/2 + math.atan(math.pi/2))
end


return  {
    gradual_growth = function(x)
        local O_L = 0
        local O_A = 3.55
        local O_T = 2.3

        local M=0.637
        
        local C_A = 0.35
        local C_L = 0.47

        local E = 3.95
        
        return M * ( arcsinh(C_A*(math.log(1+C_L*(x+1),10)^E - O_L) - O_A) + O_T )
    end,

    quick_growth_1 = function(x) 
        local O_L = 0.1
        local O_A = 3.55
        local O_T = 1.76

        local M=0.67
        
        local C_A = 0.385
        local C_L = 0.45
        
        local E = 4.22

        return M * ( arcsinh(C_A*(math.log(1+C_L*(x+1),10)^E - O_L) - O_A) + O_T )
    end,

    --- this version is only used to generate the splines
    --- the spline will default to using this function if we pass an out of range point, which shouldn't happen very often.
    ---@param willpower integer
    quick_growth_2 = function(willpower)
        local M, C, O = 2.4, 0.02734, 40
        return M * f(C * (willpower - O))
    end,
}