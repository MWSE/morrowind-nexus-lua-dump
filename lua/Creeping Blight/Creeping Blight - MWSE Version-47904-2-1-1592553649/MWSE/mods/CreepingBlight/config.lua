local data = require("CreepingBlight.data")
local defaults = data.defaults

return mwse.loadConfig("CreepingBlight", {
    maxQuestFactor = 90,
    maxTimeFactor = 75,
    daysToMax = 365,
    weatherChances = defaults,
})