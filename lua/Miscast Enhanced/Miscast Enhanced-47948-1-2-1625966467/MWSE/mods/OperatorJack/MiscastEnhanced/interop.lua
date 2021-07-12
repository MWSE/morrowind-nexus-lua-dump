local functions = require("OperatorJack.MiscastEnhanced.functions")

local interop = {}

interop.setEffectHandler = function(effectId, handler)
    return functions.setEffectHandler(effectId, handler)
end

return interop