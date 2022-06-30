-- Vapourmist by tewlwolow
-- Automatic mist/fog/vapour based on time, location, and weather

-->>>---------------------------------------------------------------------------------------------<<<--

local version = require("tew\\Vapourmist\\version")
local VERSION = version.version
local data = require("tew\\Vapourmist\\data")

local function loadData()
    local player = tes3.player
    if player then
        player.data.vapourmist = {}
        player.data.vapourmist.cells = {}

        for _, fogType in pairs(data.fogTypes) do
            player.data.vapourmist.cells[fogType.name] = {}
        end

        player.data.vapourmist.cells[data.interiorFog.name] = {}
    end
end

local function init()
    mwse.log("[Vapourmist] Version "..VERSION.." initialised.") 
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\conditionController.lua")
    event.register("loaded", loadData)
end

-- Registers MCM menu --
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\mcm.lua")
end)


event.register("initialized", init)