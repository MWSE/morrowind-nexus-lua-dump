local aux_util = require('openmw_aux.util')

local modLabel = ""

return function(...)
    local args = {...}
    local s = modLabel
    for _, var in pairs(args) do
        s = s..tostring(var).." "
    end
    print(s)
    for _, var in pairs(args) do
        if type(var) == "table" then
            print(aux_util.deepToString(var, 10))
        end
    end
end