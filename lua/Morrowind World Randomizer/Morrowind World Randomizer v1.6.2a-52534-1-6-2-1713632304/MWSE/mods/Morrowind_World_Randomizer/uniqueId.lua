local globalConfig = include("Morrowind_World_Randomizer.config").global

local this = {}

function this.getUniqueId()
    if not globalConfig.uniqueId then globalConfig.uniqueId = -1 end
    globalConfig.uniqueId = globalConfig.uniqueId + 1
    return globalConfig.uniqueId
end

return this