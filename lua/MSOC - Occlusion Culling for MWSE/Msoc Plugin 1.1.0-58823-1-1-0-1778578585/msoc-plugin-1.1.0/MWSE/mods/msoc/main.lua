-- msoc: native plugin loader + MCM bootstrap.
--
-- Loads the C++ plugin, pushes the values from msoc.json into the
-- native statics via plugin.configure(table), then registers the MCM
-- page once MWSE's mcm module is ready.

local msoc = include("msoc")

if not msoc then
    mwse.log("[msoc] msoc.dll not loaded. If you're using a mod manager, "
        .. "check that .dll files weren't filtered out of the install.")
    return
end

mwse.log("[msoc] plugin loaded, version=%s, mocLink=%s",
    tostring(msoc.version), tostring(msoc.mocLink))

local cfg = require("msoc.config")
cfg.syncToNative(msoc)

mwse.log("[msoc] config synced from msoc.json: EnableMSOC=%s, ExteriorCull=%s",
    tostring(cfg.config.EnableMSOC),
    tostring(cfg.config.OcclusionEnableExterior))

-- mcm.lua registers its own modConfigReady handler; require at top
-- level so that handler is installed before the event fires.
require("msoc.mcm")
