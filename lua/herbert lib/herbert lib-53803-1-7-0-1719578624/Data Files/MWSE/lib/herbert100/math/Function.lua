
---@class herbert.Function : herbert.Class
---@field coeff number
---@field calculate fun(x): any
---@field private new fun(p: {coeff: number, calculate: fun(x): any}): herbert.Function
local Function = {}
Herbert_Class.new({name="Function",
    fields={
        {"coeff", default=1, eq=true},
        {"calculate", eq=true, 
            factory=function() return function() end end, 
            tostring=function(f) return debug.getinfo(f, "n").name or tostring(f) end
        }
    },
    ---@type herbert.Class.metatable<herbert.Function>
    obj_metatable={
        __add=function(f1, f2)
            if not Herbert_Class.is_instance_of(f1, Function) then
                local f2calc = f2.calculate
                return f2 .. {calculate=function (x) return f2calc(x) + f1 end}
            end

            local f1calc = f1.calculate
            if Herbert_Class.is_instance_of(f2, Function) then
                local f2calc = f2.calculate
                return f1 .. {calculate = function(x) return f1calc(x) + f2calc(x) end}
            else
                return f1 .. {calculate = function(x) return f1calc(x) + f2 end}
            end
        end,
        __sub=function(f1, f2)
            if not Herbert_Class.is_instance_of(f1, Function) then
                local f2calc = f2.calculate
                return f2 .. {calculate=function (x) return f1 - f2calc(x) end}
            end

            local f1calc = f1.calculate
            if Herbert_Class.is_instance_of(f2, Function) then
                local f2calc = f2.calculate
                return f1 .. {calculate = function(x) return f1calc(x) - f2calc(x) end}
            else
                return f1 .. {calculate = function(x) return f1calc(x) - f2 end}
            end
        end,
        __mul=function(f1, f2)
            if not Herbert_Class.is_instance_of(f1, Function) then
                local f2calc = f2.calculate
                return f2 .. {calculate=function (x) return f1 * f2calc(x) end}
            end

            local f1calc = f1.calculate
            if Herbert_Class.is_instance_of(f2, Function) then
                local f2calc = f2.calculate
                return f1 .. {calculate = function(x) return f1calc(x) * f2calc(x) end}
            else
                return f1 .. {calculate = function(x) return f1calc(x) * f2 end}
            end
        end,
        
    }
}, Function)