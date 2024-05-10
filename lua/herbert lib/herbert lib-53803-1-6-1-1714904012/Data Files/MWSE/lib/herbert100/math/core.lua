---@class herbert.math.core
local math_core = {}

-- =============================================================================
-- CALCULUS
-- =============================================================================
--- approximate the integral of a smooth function
---@param f fun(x: number): number # smooth function
---@param a number # integral lower bound
---@param b number # integral upper bound
---@param n integer # number of subdivisions of (a,b) to perform
---@return number # the approximate integral
function math_core.integrate_approx(f, a, b, n)
    local w = (b - a) / n
    local sum = 0
    for k = 0, n do sum = sum + f(a + k * w) end
    return w * sum
end

---calculate the approximate derivative of a function
---@param f fun(x:number): number # function to differentiate
---@return fun(x: number): number # the derivative of f
function math_core.deriv_approx(f)
    return function(x)
        --[[ hey man, its close enough.
    the functions we're approximating are smooth anyway, so Taylor's theorem 
    kind of justifies this trick.
    ]]
        return (f(x + 0.000001) - f(x)) / 0.000001
    end
end

-- =============================================================================
-- LINEAR ALGEBRA
-- =============================================================================

--- solve a tridiagonal linear system
---@param u number[] upper diagonal
---@param d number[] diagonal
---@param l number[] lower diagional
---@param b number[] as in  Ax = b
---@return number[] x # solution to system
function math_core.solve_tridiagional_system(u,d,l,b)
    local n = #d
    -- LU factorization
    local L, U, c  = {}, {d[1]}, {b[1]}
    for i=2,n do
        -- LU factorization
        L[i-1] = l[i-1]/U[i-1]
        U[i] = d[i] - L[i-1]*u[i-1]
        -- forwards substitution
        c[i] = b[i] - L[i-1]*c[i-1]
    end
    -- backwards substitution time
    local x = {[n]=c[n]/U[n]}
    for k=1,n-1 do --for i=n-1 -> 1
        local i=n-k
        x[i] = (c[i]-u[i]*x[i+1])/U[i]
    end
    return x
end

do -- normal distribution
    local phi_denom =  math.sqrt(2 * math.pi)

    local function phi(x)
        return math.exp(- 0.5 * x^2) / phi_denom
    end

    --Zelen and Severo approximation for cumulative density function of the standard normal distribution
    local function Phi(x)
        if x < 0 then return 1 - Phi(-x) end
        if x == 0 then return 0.5 end

        local t = 1 / (1 + 0.2316419 * x)

        return 1 - phi(x) * (
            0.319381530 * t
            + -0.356563782 * t^2
            +  1.781477937 * t^3
            + -1.821255978 * t^4
            +  1.330274429 * t^5
        )
    end

    math.standard_normal_cdf = Phi

    function math_core.normal_cdf(x, avg, var)
        return var > 0 and Phi((x - avg) / math.sqrt(var)) 
            or 0.5
    end

end

math_core.norms = {}


return math_core