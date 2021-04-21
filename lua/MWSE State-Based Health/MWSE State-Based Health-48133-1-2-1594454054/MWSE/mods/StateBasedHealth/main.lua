local mod = "State-Based Health"
local version = "1.2"

-- Include our config file.
local config = require("StateBasedHealth.config")

local currentEndurance, currentStrength, currentLevel, enterFrameActive

-- Runs when the game is first loaded, and when player's strength, endurance and/or level have changed.
local function setHealth()

    -- Set to the new values for later checks in onEnterFrame.
    currentEndurance = tes3.mobilePlayer.endurance.current
    currentStrength = tes3.mobilePlayer.strength.current
    currentLevel = tes3.player.object.level

    -- Basically vanilla health formula, but retroactive and based on current stats.
    local newMaxHealth = ( ( currentEndurance + currentStrength ) / 2 ) + ( ( currentLevel - 1) * tes3.findGMST(tes3.gmst.fLevelUpHealthEndMult).value * currentEndurance )

    -- Determine magnitude of Fortify Health currently affecting player.
    local fortifyHealthMagnitude = tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = tes3.effect.fortifyHealth,
    }

    -- Without this MCP feature, Fortify Health affects only current health not max health, so no need to take it into account for max health.
    if tes3.hasCodePatchFeature(44) then
        newMaxHealth = newMaxHealth + fortifyHealthMagnitude
    end

    -- math.max returns the highest of the listed values. Implements a minimum of 1 depending on player config choices.
    if config.maxHealthSafety then
        newMaxHealth = math.max(newMaxHealth, 1)
    end

    local newCurrentHealth

    if config.maintainDifference then

        -- Subtract difference between max and current health to maintain difference.
        newCurrentHealth = newMaxHealth - ( tes3.mobilePlayer.health.base - tes3.mobilePlayer.health.current )
    else

        -- Multiply by current health ratio to maintain ratio.
        newCurrentHealth = newMaxHealth * tes3.mobilePlayer.health.normalized
    end

    if config.maxHealthSafety and config.currentHealthSafety and config.maintainDifference then
        newCurrentHealth = math.max(newCurrentHealth, 1)
    end

    -- If we're maintaining ratio, then we need to take into account Fortify Health when determining current health.
    -- Otherwise, after the Fortify Health effect wears off, the ratio would be different than it would be if there had been no Fortify Health.
    if fortifyHealthMagnitude > 0 and not config.maintainDifference then

        -- Determine what the player's present and new health would be without the Fortify Health effect.
        local maxHealthWouldBe = tes3.mobilePlayer.health.base
        local currentHealthWouldBe = tes3.mobilePlayer.health.current - fortifyHealthMagnitude
        local maxHealthWillBe = newMaxHealth

        -- Max health would also be different if the player has this MCP feature.
        if tes3.hasCodePatchFeature(44) then
            maxHealthWouldBe = maxHealthWouldBe - fortifyHealthMagnitude
            maxHealthWillBe = maxHealthWillBe - fortifyHealthMagnitude
        end

        -- What the health ratio would be without the Fortify Health effect. This is the ratio we'll be maintaining.
        local ratioWouldBe = currentHealthWouldBe / maxHealthWouldBe

        -- What the player's current health needs to be after Fortify Health wears off in order to maintain the above ratio.
        local currentHealthWillBe = maxHealthWillBe * ratioWouldBe

        -- Add back Fortify Health magnitude, to ensure ratio is correct when it wears off.
        newCurrentHealth = currentHealthWillBe + fortifyHealthMagnitude
    end

    -- Actually change max and current health.
    tes3.setStatistic{
        reference = tes3.player,
        name = "health",
        base = newMaxHealth,
    }

    tes3.setStatistic{
        reference = tes3.player,
        name = "health",
        current = newCurrentHealth,
    }
end

-- Runs every frame to check if the relevant stats have changed.
local function onEnterFrame()

    -- If stats haven't changed, or player is dead, no need to do anything, so return.
    if ( tes3.mobilePlayer.endurance.current == currentEndurance
    and tes3.mobilePlayer.strength.current == currentStrength
    and tes3.player.object.level == currentLevel )
    or tes3.mobilePlayer.health.current <= 0 then
        return
    end

    setHealth()
end

-- Runs when the game is loaded.
local function onLoaded()
    setHealth()

    -- This event occurs every frame, including when the menu is open.
    if not enterFrameActive then
        enterFrameActive = true
        event.register("enterFrame", onEnterFrame)
    end
end

local function onInitialized()
    enterFrameActive = false
    event.register("loaded", onLoaded)
    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)

-- Register the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\StateBasedHealth\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)