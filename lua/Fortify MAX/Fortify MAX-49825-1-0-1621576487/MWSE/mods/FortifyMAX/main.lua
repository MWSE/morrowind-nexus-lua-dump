local modInfo = require("FortifyMAX.modInfo")
local config = require("FortifyMAX.config")
local magicka = require("FortifyMAX.magicka")
local fatigue = require("FortifyMAX.fatigue")
local spellTick = require("FortifyMAX.spellTick")
local common = require("FortifyMAX.common")
local interop = require("FortifyMAX.interop")

local function onInitialized()
    local buildDate = mwse.buildDate
    local mod = string.format("[%s %s]", modInfo.mod, modInfo.version)
    local tooOld = string.format("%s MWSE is too out of date. Update MWSE to use this mod.", mod)

    -- This mod uses a couple recently-added MWSE features (.currentRaw and .baseRaw for attributes, and attribute param
    -- for tes3.getEffectMagnitude), so require up to date MWSE with these features.
    if not buildDate
    or buildDate < 20210518 then
        tes3.messageBox(tooOld)
        mwse.log(tooOld)
        return
    end

    mwse.log("%s initialized.", mod)

    -- We want to require a restart to enable/disable the mod's components (for simplicity), so don't even register the
    -- events if the component isn't enabled.
    if config.magicka then

        -- These events have a low priority to ensure that other mods that adjust magicka on these events can go first.
        event.register("loaded", magicka.onLoaded, { priority = -10 })
        event.register("enterFrame", magicka.onEnterFrame, { priority = -10 })

        mwse.log("%s Magicka component enabled.", mod)
    end

    if config.fatigue then
        event.register("loaded", fatigue.onLoaded, { priority = -10 })
        event.register("enterFrame", fatigue.onEnterFrame, { priority = -10 })

        mwse.log("%s Fatigue component enabled.", mod)
    end

    if config.spellTick then
        event.register("spellTick", spellTick.onSpellTick)

        mwse.log("%s spellTick component enabled.", mod)
    end

    -- These are set here on initialized to ensure they won't change later until after a restart (since the components
    -- themselves won't be enabled/disabled until after a restart).
    interop.magicka = config.magicka
    interop.fatigue = config.fatigue
    interop.spellTick = config.spellTick

    common.logMsg("Main", string.format("interop.magicka = %s. interop.fatigue = %s. interop.spellTick = %s", interop.magicka, interop.fatigue, interop.spellTick))
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\FortifyMAX\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)