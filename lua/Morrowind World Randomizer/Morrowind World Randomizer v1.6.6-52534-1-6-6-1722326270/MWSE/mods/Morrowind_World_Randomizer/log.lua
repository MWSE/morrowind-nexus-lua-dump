local globalConfigName = "MWWRandomizer_Global"
local config = mwse.loadConfig(globalConfigName)
local logging
if config ~= nil then
    logging = config.logging
else
    logging = true
end
local label = "[Morrowind World Randomizer] "
if logging then
    return function(str, ...)
        if str then
            mwse.log(label.."["..tostring(os.time()).."] "..str, ...)
        end
    end
else
    return function() end
end