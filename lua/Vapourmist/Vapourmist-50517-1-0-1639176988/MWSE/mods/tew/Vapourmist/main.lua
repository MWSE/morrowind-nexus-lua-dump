-- Vapourmist by tewlwolow
-- Automatic mist/fog/vapour based on time, location, and weather

--[[ TODO:
* diff between spawning hours - movement
]]

-->>>---------------------------------------------------------------------------------------------<<<--

local version = require("tew\\Vapourmist\\version")
local VERSION = version.version

local config = require("tew\\Vapourmist\\config")

local function init()

    mwse.log("[Vapourmist] Version "..VERSION.." initialised.")
    local mistOn = config.mistOn
    local cloudsOn = config.cloudsOn

    if mistOn then
        mwse.log("[Vapourmist "..VERSION.."] Loading file: mist.lua.")
        dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\mist.lua")
    end

    if cloudsOn then
        mwse.log("[Vapourmist "..VERSION.."] Loading file: clouds.lua.")
        dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\cloud.lua")
    end

end

-- Registers MCM menu --
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\mcm.lua")
end)


event.register("initialized", init)