local core = require("openmw.core")

if not core.magic then
    return {checkValues = function ()return true
        
    end}--no way to check in older versions
end
local effects = {
    ["SummonCreature04"] = { name = "Greater Mark", school = "mysticism" },
    ["SummonCreature05"] = { name = "Greater Recall", school = "mysticism" },

}
local function isEqual(table1, table2)
    for key, value in pairs(table2) do
        if table1[key] ~= value then
            return false
        end
    end
    return true
end
return {
    checkValues = function()
        local effect4 = core.magic.effects.records["SummonCreature04"]
        local effect5 = core.magic.effects.records["SummonCreature05"]
        if not isEqual(effect4, effects["SummonCreature04"]) then
            return false
        elseif not isEqual(effect5, effects["SummonCreature05"]) then
            return false
        end

        return true
    end
}
