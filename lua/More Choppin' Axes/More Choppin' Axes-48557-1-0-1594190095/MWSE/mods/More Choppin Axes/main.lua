local common = require("More Choppin Axes.common")
local config = require("More Choppin Axes.config").getConfig()

local function onInitialized()
    if not config.enabled then return end

    if config.logLevel >= common.logLevels.small then
        common.log("Start choppin' with fix type " .. common.fixes[config.fixType])
    end

    common.applyFixes(config.fixType, config.logLevel)

    if config.logLevel >= common.logLevels.small then
        common.log("That's it for choppin'")
    end
end

event.register("initialized", onInitialized)

event.register("modConfigReady", function()
    mwse.mcm.register(require("More Choppin Axes.mcm"))
end)
