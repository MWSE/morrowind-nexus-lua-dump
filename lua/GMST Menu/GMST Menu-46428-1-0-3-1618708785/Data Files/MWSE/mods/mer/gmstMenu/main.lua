 
local function registerModConfig()
    --get easyMCM
    local easyMCM = require("easyMCM.modConfig")
    --get your MCM data file (put it somewhere in your own mod folder)
    local mcmData = require ("mer.gmstMenu.mcmData")
    --Create your MCM
    local mcm = easyMCM.registerModData( mcmData ) 
    --And register the config
    mwse.registerModConfig(mcmData.name, mcm)
end
event.register("modConfigReady", registerModConfig)


local function initialize()
    local config = mwse.loadConfig("custom_gmsts")
    if config then
        for gmst, value in pairs(config) do
            if string.find(gmst, "^i") then
                tes3.findGMST(gmst).value = math.round(tonumber(value), 0)
            elseif string.find(gmst, "^f") then
                tes3.findGMST(gmst).value = tonumber(value)
            else -- string
                tes3.findGMST(gmst).value = value
            end
        end
    end
end

 event.register("initialized", initialize)