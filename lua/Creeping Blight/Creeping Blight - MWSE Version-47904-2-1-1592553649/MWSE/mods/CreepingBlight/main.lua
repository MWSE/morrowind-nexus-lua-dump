local mod = "Creeping Blight"
local version = "2.1"

local config = require("CreepingBlight.config")
local common = require("CreepingBlight.common")

local cellChangedActive, currentDay

-- Runs on each journal update.
local function onJournal(e)

    -- All of these journal entries should trigger a change in the weather or a new questStage.
    if ( e.topic.id == "C3_DestroyDagoth" and e.index == 20 )
    or ( e.topic.id == "TR_SothaSil" and e.index == 110 )
    or ( e.topic.id == "A1_2_AntabolisInformant" and e.index == 10 )
    or ( e.topic.id == "A1_11_ZainsubaniInformant" and e.index == 50 )
    or ( e.topic.id == "A2_2_6thHouse" and e.index == 50 )
    or ( e.topic.id == "A2_3_CorprusCure" and e.index == 50 )
    or ( e.topic.id == "A2_6_Incarnate" and e.index == 50 )
    or ( e.topic.id == "B8_MeetVivec" and e.index == 50 )
    or ( e.topic.id == "CX_BackPath" and e.index == 50 ) then
        common.changeWeatherChances()
    end
end

-- Runs each time the player changes cells.
local function onCellChanged()
    local endGameIndex = tes3.getJournalIndex{ id = "C3_DestroyDagoth" }

    -- Main Quest is now complete, so there's no need to check for days passed anymore.
    if endGameIndex >= 20 then
        cellChangedActive = false
        event.unregister("cellChanged", onCellChanged)
        return
    end

    local newDay = tes3.findGlobal("DaysPassed").value

    -- Another day has passed, so change weather chances, but only if days passed increases blight chance.
    if newDay ~= currentDay and config.maxTimeFactor > 0 then
        currentDay = newDay
        common.changeWeatherChances()
    end
end

-- Runs each time the game is loaded.
local function onLoaded()
    currentDay = tes3.findGlobal("DaysPassed").value
    local endGameIndex = tes3.getJournalIndex{ id = "C3_DestroyDagoth" }

    -- Only register this event once, and only if the Main Quest hasn't been completed yet.
    if endGameIndex < 20 and not cellChangedActive then
        cellChangedActive = true
        event.register("cellChanged", onCellChanged)
    end

    common.changeWeatherChances()
end

local function onInitialized()
    cellChangedActive = false

    event.register("loaded", onLoaded)
    event.register("journal", onJournal)
    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)

-- Registers the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\CreepingBlight\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)