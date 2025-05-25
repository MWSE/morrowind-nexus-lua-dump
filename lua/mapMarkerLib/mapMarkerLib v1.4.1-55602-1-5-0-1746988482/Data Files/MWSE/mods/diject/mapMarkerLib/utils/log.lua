local modLabel = "[Marker Lib]"

local function logTable(table, prefix)
    for name, val in pairs(table) do
        if type(val) == "table" then
            logTable(val, "\t"..prefix..tostring(name).." ")
        else
            print(prefix..tostring(name).." "..tostring(val))
        end
    end
end

local this = {}

this.enabled = false

function this.log(...)
    if not this.enabled then return end
    local args = {...}
    local s = modLabel.."["..tostring(os.time()).."] "
    for _, var in pairs(args) do
        s = s..tostring(var).." "
    end
    print(s)
    for _, var in pairs(args) do
        if type(var) == "table" then
            logTable(var, "\t"..tostring(var).." ")
        end
    end
end

return this