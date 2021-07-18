local modInfo = require("StateBasedHealth.modInfo")
local config = require("StateBasedHealth.config")
local interop = require("StateBasedHealth.interop")

local currentEndurance, currentStrength, currentLevel
local statMenuId = tes3ui.registerID("MenuStat")
local hudMenuId = tes3ui.registerID("MenuMulti")
local healthBarId = tes3ui.registerID("MenuStat_health_fillbar")
local modVersion = string.format("[%s %s]", modInfo.mod, modInfo.version)

local function logMsg(message)
    if config.logging then
        mwse.log("%s %s", modVersion, message)
    end
end

local function updateMenu(menu)
    if menu then
        local maxHealth = tes3.mobilePlayer.health.base
        local currentHealth = tes3.mobilePlayer.health.current

        local bar = menu:findChild(healthBarId)

        if bar then
            bar.widget.current = currentHealth
            bar.widget.max = maxHealth

            bar:updateLayout()
            menu:updateLayout()
        end
    end
end

local function updateDisplay()
    local statMenu = tes3ui.findMenu(statMenuId)
    local hudMenu = tes3ui.findMenu(hudMenuId)

    updateMenu(statMenu)
    updateMenu(hudMenu)
end

local function getAbilityMag(effect)
    local mag = 0
    local activeEffect = tes3.mobilePlayer.activeMagicEffects

    for _ = 1, tes3.mobilePlayer.activeMagicEffectCount do
        activeEffect = activeEffect.next

        if activeEffect.effectId == effect then
            local instance = activeEffect.instance

            if instance.sourceType == tes3.magicSourceType.spell
            and instance.source.castType == tes3.spellType.ability then
                mag = mag + activeEffect.magnitude
            end
        end
    end

    return mag
end

local function setHealth()
    local oldMaxHealth = tes3.mobilePlayer.health.base
    local oldCurrentHealth = tes3.mobilePlayer.health.current
    logMsg(string.format("Old max health: %f", oldMaxHealth))
    logMsg(string.format("Old current health: %f", oldCurrentHealth))

    currentEndurance = tes3.mobilePlayer.endurance.current
    currentStrength = tes3.mobilePlayer.strength.current
    currentLevel = tes3.player.object.level
    logMsg(string.format("Endurance: %f", currentEndurance))
    logMsg(string.format("Strength: %f", currentStrength))
    logMsg(string.format("Level: %d", currentLevel))

    -- Basically vanilla health formula, but based on current stats.
    local fLevelUpHealthEndMult = tes3.findGMST(tes3.gmst.fLevelUpHealthEndMult).value
    local newMaxHealth = ( ( currentEndurance + currentStrength ) / 2 ) + ( ( currentLevel - 1) * fLevelUpHealthEndMult * currentEndurance )
    logMsg(string.format("fLevelUpHealthEndMult GMST: %f", fLevelUpHealthEndMult))
    logMsg(string.format("New max health (per formula): %f", newMaxHealth))

    local fortifyHealthMagnitude = tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = tes3.effect.fortifyHealth,
    }

    local fortifyHealthAffectingMax = 0

    -- With this MCP feature, all Fortify Health effects affect max health. Without it, only Fortify Health abilities
    -- affect max health.
    if tes3.hasCodePatchFeature(tes3.codePatchFeature.fortifyMaximumHealth) then
        fortifyHealthAffectingMax = fortifyHealthMagnitude
    elseif fortifyHealthMagnitude > 0 then
        fortifyHealthAffectingMax = getAbilityMag(tes3.effect.fortifyHealth)
    end

    logMsg(string.format("Fortify Health magnitude: %f", fortifyHealthMagnitude))
    logMsg(string.format("Fortify Health magnitude affecting max health: %f", fortifyHealthAffectingMax))

    newMaxHealth = newMaxHealth + fortifyHealthAffectingMax
    logMsg(string.format("New max health (taking into account Fortify Health): %f", newMaxHealth))

    -- Other mods can tell this mod to apply health modifiers.
    for descriptor, amount in pairs(interop.extraHealth) do
        local num = tonumber(amount)

        if num then
            newMaxHealth = newMaxHealth + num
            logMsg(string.format("Applying health modifier from \"%s\": %f", descriptor, num))
        else
            logMsg(string.format("Health modifier from \"%s\" is not a valid number, skipping.", descriptor))
        end
    end

    logMsg(string.format("New max health (after all modifiers from other mods): %f", newMaxHealth))

    newMaxHealth = math.max(newMaxHealth, config.minMaxHealth)
    logMsg(string.format("Minimum max health setting: %f", config.minMaxHealth))
    logMsg(string.format("New max health (taking into account minimum max health setting): %f", newMaxHealth))

    local newCurrentHealth

    if config.maintainDifference then
        local difference = oldMaxHealth - oldCurrentHealth
        newCurrentHealth = newMaxHealth - difference
        logMsg(string.format("Maintaining difference. Difference: %f", difference))
        logMsg(string.format("New current health: %f", newCurrentHealth))
    else
        local ratio = tes3.mobilePlayer.health.normalized
        newCurrentHealth = newMaxHealth * ratio
        logMsg(string.format("Maintaining ratio. Ratio: %f", ratio))
        logMsg(string.format("New current health: %f", newCurrentHealth))
    end

    -- If we're maintaining ratio, then we need to take into account Fortify Health when determining current health.
    -- Otherwise, after the Fortify Health effect wears off, the ratio would be different than it would be if there had
    -- been no Fortify Health.
    if fortifyHealthMagnitude > 0 and not config.maintainDifference then
        logMsg("There is a Fortify Health magnitude, and we are maintaining ratio. Adjusting new current health to compensate.")

        -- Determine what the player's present and new health would be without the Fortify Health effect.
        local maxHealthWouldBe = oldMaxHealth - fortifyHealthAffectingMax
        local currentHealthWouldBe = oldCurrentHealth - fortifyHealthMagnitude
        local maxHealthWillBe = newMaxHealth - fortifyHealthAffectingMax

        -- What the health ratio would be without the Fortify Health effect. This is the ratio we'll be maintaining.
        local ratioWouldBe

        if maxHealthWouldBe == 0 then
            ratioWouldBe = 0
        else
            ratioWouldBe = currentHealthWouldBe / maxHealthWouldBe
        end

        -- What the player's current health needs to be after Fortify Health wears off in order to maintain the above
        -- ratio.
        local currentHealthWillBe = maxHealthWillBe * ratioWouldBe

        --[[ Add back Fortify Health magnitude, to ensure the ratio is correct after it wears off. If any of these
        values are negative (or 0 in the case of max health), the results are really weird and very incorrect. (This can
        happen, for example, if the player takes damage such that their current health is less than their Fortify Health
        magnitude.) In this case, nevermind, just maintain the existing ratio. ]]--
        if maxHealthWouldBe > 0
        and currentHealthWouldBe >= 0
        and maxHealthWillBe > 0 then
            newCurrentHealth = currentHealthWillBe + fortifyHealthMagnitude
        end

        logMsg(string.format("Old max health would be without Fortify Health: %f", maxHealthWouldBe))
        logMsg(string.format("Old current health would be without Fortify Health: %f", currentHealthWouldBe))
        logMsg(string.format("New max health will be when Fortify Health expires: %f", maxHealthWillBe))
        logMsg(string.format("Health ratio would be without Fortify Health: %f", ratioWouldBe))
        logMsg(string.format("Current health needs to be when Fortify Health expires: %f", currentHealthWillBe))
        logMsg(string.format("New current health, taking into account Fortify Health: %f", newCurrentHealth))
    end

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

    updateDisplay()
    interop.recalcHealth = false
end

local function onEnterFrame()
    if not tes3.player then
        return
    end

    if tes3.mobilePlayer.health.current <= 0 then
        return
    end

    if tes3.mobilePlayer.endurance.current == currentEndurance
    and tes3.mobilePlayer.strength.current == currentStrength
    and tes3.player.object.level == currentLevel
    and not interop.recalcHealth then
        return
    end

    logMsg("Endurance, strength or level has changed, or another mod has triggered a health recalculation. Calculating health.")
    setHealth()
end

local function onLoaded()
    logMsg("Game loaded. Calculating health.")
    setHealth()
end

local function onInitialized()
    event.register("loaded", onLoaded)
    event.register("enterFrame", onEnterFrame)
    mwse.log("%s Initialized.", modVersion)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("StateBasedHealth.mcm")
end

event.register("modConfigReady", onModConfigReady)