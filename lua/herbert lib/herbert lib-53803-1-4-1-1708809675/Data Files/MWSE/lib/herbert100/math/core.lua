return {
    -- =============================================================================
    -- CALCULUS
    -- =============================================================================
    --- approximate the integral of a smooth function
    ---@param f fun(x: number): number # smooth function
    ---@param a number # integral lower bound
    ---@param b number # integral upper bound
    ---@param n integer # number of subdivisions of (a,b) to perform
    ---@return number # the approximate integral
    integrate_approx = function(f, a, b, n)
        local w = (b - a) / n
        local sum = 0
        for k = 0, n do sum = sum + f(a + k * w) end
        return w * sum
    end,

    ---calculate the approximate derivative of a function
    ---@param f fun(x:number): number # function to differentiate
    ---@return fun(x: number): number # the derivative of f
    deriv_approx = function(f)
        return function(x)
            --[[ hey man, its close enough.
        the functions we're approximating are smooth anyway, so Taylor's theorem 
        kind of justifies this trick.
        ]]
            return (f(x + 0.000001) - f(x)) / 0.000001
        end
    end,

    -- =============================================================================
    -- LINEAR ALGEBRA
    -- =============================================================================

    --- solve a tridiagonal linear system
    ---@param u number[] upper diagonal
    ---@param d number[] diagonal
    ---@param l number[] lower diagional
    ---@param b number[] as in  Ax = b
    ---@return number[] x # solution to system
    solve_tridiagional_system = function(u,d,l,b)
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


}