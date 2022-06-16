local modInfo = require("BarterGoldAdjuster.modInfo")
local config = require("BarterGoldAdjuster.config")
local common = require("BarterGoldAdjuster.common")
local mod = string.format("[%s %s]", modInfo.mod, modInfo.version)
local mult, floor, cap

local function processActor(actor)
    if not common.isMerchant(actor) then
        return
    end

    if config.blacklist[actor.id:lower()] then
        return
    end

    local newBarterGold = actor.barterGold * mult
    newBarterGold = math.clamp(newBarterGold, floor, cap)
    newBarterGold = math.floor(newBarterGold)
    actor.barterGold = newBarterGold
end

local function onInitialized()
    -- tonumber is needed because the MCM will annoyingly convert numbers to strings in the config file.
    -- Also sanity check, mult and floor should not be negative.
    mult = math.max(tonumber(config.mult), 0)
    floor = math.max(tonumber(config.floor), 0)
    floor = math.floor(floor)

    -- Negative value means no cap.
    cap = (tonumber(config.cap) >= 0 and tonumber(config.cap)) or math.huge
    cap = math.floor(cap)

    -- Floor shouldn't be greater than cap.
    floor = math.min(floor, cap)

    for actor in tes3.iterateObjects(tes3.objectType.npc) do
        processActor(actor)
    end

    for actor in tes3.iterateObjects(tes3.objectType.creature) do
        processActor(actor)
    end

    mwse.log("%s Initialized.", mod)
end

event.register(tes3.event.initialized, onInitialized)

local function onModConfigReady()
    dofile("BarterGoldAdjuster.mcm")
end

event.register(tes3.event.modConfigReady, onModConfigReady)