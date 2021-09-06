local mod = "Rational Names BTBGI Addendum"
local version = "1.1"
local modVersion = string.format("[%s %s]", mod, version)

local data = require("RationalNames.BTBGIAddendum.data")

local function onInitialized()
    if (not tes3.isModActive("BTB's Game Improvements (Necro Edit).esp"))
    and (not tes3.isModActive("BTB's Game Improvements (Necro Edit - No RAB).esp")) then
        mwse.log("%s BTBGI not detected.", modVersion)
        return
    end

    local rationalNames = include("RationalNames.interop")

    if not rationalNames then
        mwse.log("%s Rational Names not detected.", modVersion)
        return
    end

    for _, objectType in ipairs(data.components) do
        for id, btbgiName in pairs(data.baseNames[objectType]) do
            rationalNames.data.baseNames[objectType][id] = btbgiName
        end
    end

    -- So the "alternate spoiled potion names" feature of Rational Names won't override BTBGI's spoiled potion names.
    for id, spoiledPotionName in pairs(data.spoiledPotionsAltNames) do
        rationalNames.data.spoiledPotionsAltNames[id] = spoiledPotionName
    end

    mwse.log("%s Rational Names base names updated for BTBGI.", modVersion)
end

event.register("initialized", onInitialized)