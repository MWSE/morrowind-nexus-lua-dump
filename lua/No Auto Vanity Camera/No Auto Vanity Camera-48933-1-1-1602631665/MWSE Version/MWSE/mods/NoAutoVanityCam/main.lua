local mod = "No Auto Vanity Camera"
local version = "1.1"

local config = require("NoAutoVanityCam.config")

local function onInitialized()
    local timeout = tonumber(config.vanityTimeout)
    tes3.findGMST(tes3.gmst.fVanityDelay).value = timeout
    mwse.log("[%s %s] initialized.", mod, version)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\NoAutoVanityCam\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)