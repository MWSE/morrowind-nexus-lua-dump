local modInfo = require("FortifyMAX.modInfo")
local config = require("FortifyMAX.config")
local magicka = require("FortifyMAX.magicka")
local fatigue = require("FortifyMAX.fatigue")
local spellTick = require("FortifyMAX.spellTick")
local common = require("FortifyMAX.common")
local interop = require("FortifyMAX.interop")

local simulateActive

local function modCurrentAttribute(attribute, amount)
    common.logMsg("Main", string.format("Modding current %s by %d.", tes3.attributeName[attribute], amount))

    tes3.modStatistic{
        reference = tes3.player,
        attribute = attribute,
        current = amount,
    }
end

--[[ This is needed solely in case the player is using a mod that adds a Fortify Magicka/Fatigue ability to a race or
birthsign. Such abilities are normally useless, but this mod causes them to work basically as expected. However, they
don't work until a savegame is loaded or a relevant attribute is changed, so we change an attribute after chargen just
to trigger the ability. ]]--
local function tweakAttribute(effect, attribute)
    if common.getEffectMag(effect) <= 0 then
        return
    end

    local amount = -1

    -- Attributes on the mobile are off by one compared to MWSE.
    if tes3.mobilePlayer.attributes[attribute + 1].current < 1 then
        amount = -amount
    end

    -- We have to wait a frame in the first place because otherwise it doesn't work. Then wait another frame to change
    -- it back.
    timer.frame.delayOneFrame(function()
        modCurrentAttribute(attribute, amount)

        timer.frame.delayOneFrame(function()
            modCurrentAttribute(attribute, -amount)
        end)
    end)
end

-- We need to check later to see if abilities are granted by the player's race or birthsign, so grab the spells lists
-- here.
local function getRaceBirthsign()
    common.playerRace = tes3.player.object.race
    common.playerBirthsign = tes3.mobilePlayer.birthsign
    common.raceSpells = common.playerRace.abilities
    common.birthsignSpells = common.playerBirthsign.spells

    common.logMsg("Main", string.format("Player race: %s. Player birthsign: %s", common.playerRace.id, common.playerBirthsign.id))
end

local function onSimulate()
    if tes3.findGlobal("CharGenState").value ~= -1 then
        return
    end

    simulateActive = false
    event.unregister("simulate", onSimulate)
    getRaceBirthsign()
    tweakAttribute(tes3.effect.fortifyMagicka, tes3.attribute.intelligence)
    tweakAttribute(tes3.effect.fortifyFatigue, tes3.attribute.agility)
end

local function onLoaded(e)
    if e.newGame then
        simulateActive = true
        event.register("simulate", onSimulate)
    else
        getRaceBirthsign()
    end
end

local function onLoad()
    if simulateActive then
        simulateActive = false
        event.unregister("simulate", onSimulate)
    end

    common.playerRace = nil
    common.playerBirthsign = nil
    common.raceSpells = {}
    common.birthsignSpells = {}
end

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

    simulateActive = false

    event.register("load", onLoad)
    event.register("loaded", onLoaded)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("FortifyMAX.mcm")
end

event.register("modConfigReady", onModConfigReady)