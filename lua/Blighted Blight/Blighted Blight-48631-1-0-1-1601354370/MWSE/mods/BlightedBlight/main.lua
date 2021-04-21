local mod = "Blighted Blight"
local version = "1.0.1"

local config = require("BlightedBlight.config")

local blightSpells = {}

-- Runs when Morrowind first starts.
-- Iterates through all the spells in the game's data and adds all the blight diseases to the blightSpells table.
-- Corprus is technically a blight spell, so it has to be specifically excluded.
local function getBlightSpells()
    for spell in tes3.iterateObjects(tes3.objectType.spell) do
        if spell.castType == tes3.spellType.blight and spell.id ~= "corprus" then
            table.insert(blightSpells, spell)
        end
    end
end

-- Checks to see if the player is affected by any of the blight diseases in the blightSpells table.
local function checkBlight()
    for _, blight in ipairs(blightSpells) do
        if tes3.mobilePlayer:isAffectedByObject(blight) then
            return true
        end
    end

    return false
end

-- Checks to see if the player is in an interior cell (and not one that behaves as an exterior, like the Mournhold "exteriors").
local function checkInterior()
    local cell = tes3.player.cell
    return cell.isInterior and not cell.behavesAsExterior
end

-- Runs each time the player changes cells.
local function onCellChanged()

    -- If the player has set blight chance to 0, or is in an interior, or already has a blight disease, then do nothing.
    if config.blightChance <= 0
    or checkInterior()
    or checkBlight() then
        return
    end

    local currentRegion = tes3.player.cell.region

    -- The player has entered a "wilderness" cell, or some other exterior cell that somehow has no region, so bail.
    if not currentRegion then
        return
    end

    local weatherId = currentRegion.weather.index

    -- The weather in the new cell is not blight, so do nothing.
    if weatherId ~= tes3.weather.blight then
        return
    end

    -- This takes into account not only any Resist Blight Disease magnitude on the player, but also any Weakness to Blight Disease magnitude.
    local blightResMag = tes3.mobilePlayer.resistBlightDisease

    -- Player is immune to blight disease, so do nothing.
    if blightResMag >= 100 then
        return
    end

    local baseChance = config.blightChance * 0.01

    -- This multiplier is normally 1 when Resist Blight Disease magnitude is 0.
    -- Resist Blight Disease will make it less than 1.
    -- Weakness to Blight Disease will make it greater than 1 (blightResMag can be negative).
    local blightMagMult = 0.01 * ( 100 - blightResMag )

    local blightChance = baseChance * blightMagMult

    -- A random float value between 0 and 1.
    local blightRand = math.random()

    -- The roll went the player's way, so do nothing.
    if blightRand > blightChance then
        return
    end

    -- A random integer between 1 and the number of blight diseases in the blightSpells table.
    local blightNum = math.random(#blightSpells)

    -- Pick a random blight spell.
    local blightToAdd = blightSpells[blightNum]
    local blightName = blightToAdd.name

    mwscript.addSpell{
        reference = tes3.player,
        spell = blightToAdd,
    }

    tes3.messageBox("You have contracted %s", blightName)
end

local function onInitialized()
    getBlightSpells()

    event.register("cellChanged", onCellChanged)
    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)

-- Register the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\BlightedBlight\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)