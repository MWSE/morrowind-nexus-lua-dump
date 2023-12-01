local settings = require("scripts.comprehensive_rebalance.lib.settings")

local core = require('openmw.core')
local time = require("openmw_aux.time")
local stopFn = nil

local function pluginCheck(player)
    if not core.contentFiles.has(settings.MOD_NAME_ADDON) then
        stopFn = time.runRepeatedly(
            function ()
                player:sendEvent("showMessage", "PLUGIN NOT INSTALLED!\n\nPlease enable ".. settings.MOD_NAME_ADDON .." in the launcher!")
                print("comprehensive_rebalance.owmaddon is not installed!")
            end,
        time.second * 1
        )
    end
end

return {
    engineHandlers = {
        onPlayerAdded = pluginCheck
    }
}
