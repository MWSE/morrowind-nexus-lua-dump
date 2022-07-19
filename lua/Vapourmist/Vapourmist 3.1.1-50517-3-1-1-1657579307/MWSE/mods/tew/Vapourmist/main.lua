-- Vapourmist by tewlwolow
-- Automatic mist/fog/vapour based on time, location, and weather

-->>>---------------------------------------------------------------------------------------------<<<--

local version = require("tew\\Vapourmist\\version")
local VERSION = version.version

local function init()
    mwse.log("[Vapourmist] Version "..VERSION.." initialised.") 
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\conditionController.lua")
end

-- Registers MCM menu --
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\mcm.lua")
end)


event.register("initialized", init)