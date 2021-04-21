local mod = "Weather Chances Adjuster"
local version = "1.0.2"

local common = require("WeatherChances.common")

-- Runs on each journal update.
local function onJournal(e)

    -- Receiving these journal entries should change the weather chances in Red Mountain and Mournhold respectively.
    if ( e.topic.id == "C3_DestroyDagoth" and e.index == 20 )
    or ( e.topic.id == "TR_SothaSil" and e.index == 110 ) then
        common.changeWeatherChances()
    end
end

-- Runs each time the game is loaded.
local function onLoaded()
    common.changeWeatherChances()
end

local function onInitialized()
    event.register("loaded", onLoaded)
    event.register("journal", onJournal)
    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)

-- Registers the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\WeatherChances\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)