
local core = require("openmw.core")


local gmstChecker = {}
local values = {
    ["sEffectSummonCreature04"] = "Greater Mark",
    ["sEffectSummonCreature05"] = "Greater Recall",
    ["sMagicCreature04ID"] = "Teleport_summonMark",
    ["sMagicCreature05ID"] = "Teleport_summonRecall",
}
function gmstChecker.checkValues()
    for key, value in pairs(values) do
        if  core.getGMST(key) ~= value then
            print("INCORRECT:" .. key,core.getGMST(key),value)
            return false
        end
    end
    return true
end

return gmstChecker