local mod = "No Console"
local version = "1.0"

local function onInitialized()
    tes3.disableKey(tes3.scanCode["~"])
    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)