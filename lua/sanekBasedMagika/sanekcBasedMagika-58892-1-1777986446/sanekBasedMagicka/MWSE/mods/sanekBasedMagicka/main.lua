local modInfo = require("sanekBasedMagicka.modInfo")
local config = require("sanekBasedMagicka.config")
local interop = require("sanekBasedMagicka.interop")

local currentWillpower, currentIntelligence, currentLevel, magickaMultiplier
local statMenuId = tes3ui.registerID("MenuStat")
local hudMenuId = tes3ui.registerID("MenuMulti")
local magickaBarId = tes3ui.registerID("MenuStat_magicka_fillbar")
local modVersion = string.format("[%s %s]", modInfo.mod, modInfo.version)

local function logMsg(message)
    if config.logging then
        mwse.log("%s %s", modVersion, message)
    end
end

local function updateMenu(menu)
    if menu then
        local maxMagicka = tes3.mobilePlayer.magicka.base
        local currentMagicka = tes3.mobilePlayer.magicka.current

        local bar = menu:findChild(magickaBarId)

        if bar then
            bar.widget.current = currentMagicka
            bar.widget.max = maxMagicka

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

local function setMagicka()
    local oldMaxMagicka = tes3.mobilePlayer.magicka.base
    local oldCurrentMagicka = tes3.mobilePlayer.magicka.current
    logMsg(string.format("Old max magicka: %f", oldMaxMagicka))
    logMsg(string.format("Old current magicka: %f", oldCurrentMagicka))

    currentWillpower = tes3.mobilePlayer.willpower.current
    currentIntelligence = tes3.mobilePlayer.intelligence.current
    currentLevel = tes3.player.object.level
    logMsg(string.format("Willpower: %f", currentWillpower))
    logMsg(string.format("Intelligence: %f", currentIntelligence))
    logMsg(string.format("Level: %d", currentLevel))

	magickaMultiplier = tes3.mobilePlayer.magickaMultiplier.current
	logMsg(string.format("Magicka Multiplier: %f", magickaMultiplier))
	local newMaxMagicka
	
	if config.softScale then
		newMaxMagicka = (currentIntelligence + config.willpowerMod * currentWillpower) * (1 + config.multMod * (math.max(magickaMultiplier - 1,  0) ^ config.PowExp)) * (1 + config.levelMod * currentLevel)

        logMsg(string.format("New max magicka (Soft Scale): %f", newMaxMagicka))
	else
		newMaxMagicka = (currentIntelligence + config.willpowerMod * currentWillpower) * (1 + config.multMod * (math.max(magickaMultiplier - 1,  0))) * (1 + config.levelMod * currentLevel)
		
		logMsg(string.format("New max magicka (Linear Scale): %f", newMaxMagicka))
	end
	

    local fortifyMagickaMagnitude = tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = tes3.effect.fortifyMagicka,
    }

    local fortifyMagickaAffectingMax = 0

    logMsg(string.format("Fortify Magicka magnitude: %f", fortifyMagickaMagnitude))
    logMsg(string.format("Fortify Magicka magnitude affecting max magicka: %f", fortifyMagickaAffectingMax))

    newMaxMagicka = newMaxMagicka + fortifyMagickaAffectingMax
    logMsg(string.format("New max magicka (taking into account Fortify Magicka): %f", newMaxMagicka))

    -- Other mods can tell this mod to apply magicka modifiers.
    for descriptor, amount in pairs(interop.extraMagicka) do
        local num = tonumber(amount)

        if num then
            newMaxMagicka = newMaxMagicka + num
            logMsg(string.format("Applying magicka modifier from \"%s\": %f", descriptor, num))
        else
            logMsg(string.format("Magicka modifier from \"%s\" is not a valid number, skipping.", descriptor))
        end
    end

    logMsg(string.format("New max magicka (after all modifiers from other mods): %f", newMaxMagicka))

    newMaxMagicka = math.min(math.max(newMaxMagicka, config.minMaxMagicka),config.maxMaxMagicka)
    logMsg(string.format("Minimum max magicka setting: %f", config.minMaxMagicka))
    logMsg(string.format("Maximum max magicka setting: %f", config.maxMaxMagicka))
    logMsg(string.format("New max magicka (taking into account minimum and maximum max magicka setting): %f", newMaxMagicka))

    local newCurrentMagicka

    if config.maintainDifference then
        local difference = oldMaxMagicka - oldCurrentMagicka
        newCurrentMagicka = newMaxMagicka - difference
        logMsg(string.format("Maintaining difference. Difference: %f", difference))
        logMsg(string.format("New current magicka: %f", newCurrentMagicka))
    else
        local ratio = tes3.mobilePlayer.magicka.normalized
        newCurrentMagicka = newMaxMagicka * ratio
        logMsg(string.format("Maintaining ratio. Ratio: %f", ratio))
        logMsg(string.format("New current magicka: %f", newCurrentMagicka))
    end

    -- If we're maintaining ratio, then we need to take into account Fortify Magicka when determining current magicka.
    -- Otherwise, after the Fortify Magicka effect wears off, the ratio would be different than it would be if there had
    -- been no Fortify Magicka.
    if fortifyMagickaMagnitude > 0 and not config.maintainDifference then
        logMsg("There is a Fortify Magicka magnitude, and we are maintaining ratio. Adjusting new current magicka to compensate.")

        -- Determine what the player's present and new magicka would be without the Fortify Magicka effect.
        local maxMagickaWouldBe = oldMaxMagicka - fortifyMagickaAffectingMax
        local currentMagickaWouldBe = oldCurrentMagicka - fortifyMagickaMagnitude
        local maxMagickaWillBe = newMaxMagicka - fortifyMagickaAffectingMax

        -- What the magicka ratio would be without the Fortify Magicka effect. This is the ratio we'll be maintaining.
        local ratioWouldBe

        if maxMagickaWouldBe == 0 then
            ratioWouldBe = 0
        else
            ratioWouldBe = currentMagickaWouldBe / maxMagickaWouldBe
        end

        -- What the player's current magicka needs to be after Fortify Magicka wears off in order to maintain the above
        -- ratio.
        local currentMagickaWillBe = maxMagickaWillBe * ratioWouldBe

        --[[ Add back Fortify Magicka magnitude, to ensure the ratio is correct after it wears off. If any of these
        values are negative (or 0 in the case of max magicka), the results are really weird and very incorrect. (This can
        happen, for example, if the player takes damage such that their current magicka is less than their Fortify Magicka
        magnitude.) In this case, nevermind, just maintain the existing ratio. ]]--
        if maxMagickaWouldBe > 0
        and currentMagickaWouldBe >= 0
        and maxMagickaWillBe > 0 then
            newCurrentMagicka = currentMagickaWillBe + fortifyMagickaMagnitude
        end

        logMsg(string.format("Old max magicka would be without Fortify Magicka: %f", maxMagickaWouldBe))
        logMsg(string.format("Old current magicka would be without Fortify Magicka: %f", currentMagickaWouldBe))
        logMsg(string.format("New max magicka will be when Fortify Magicka expires: %f", maxMagickaWillBe))
        logMsg(string.format("Magicka ratio would be without Fortify Magicka: %f", ratioWouldBe))
        logMsg(string.format("Current magicka needs to be when Fortify Magicka expires: %f", currentMagickaWillBe))
        logMsg(string.format("New current magicka, taking into account Fortify Magicka: %f", newCurrentMagicka))
    end

    tes3.setStatistic{
        reference = tes3.player,
        name = "magicka",
        base = newMaxMagicka,
    }

    expectedMaxMagicka = newMaxMagicka
	
    tes3.setStatistic{
        reference = tes3.player,
        name = "magicka",
        current = newCurrentMagicka,
    }

    updateDisplay()
    interop.recalcMagicka = false
end

local function almostEqual(a, b, epsilon)
    epsilon = epsilon or 0.01
	return math.abs(a - b) <= epsilon
end	

local function onEnterFrame()
    if not tes3.player then
        return
    end

    local willChanged = tes3.mobilePlayer.willpower.current ~= currentWillpower
    local intChanged = tes3.mobilePlayer.intelligence.current ~= currentIntelligence
    local levelChanged = tes3.player.object.level ~= currentLevel
    local multChanged = tes3.mobilePlayer.magickaMultiplier.current ~= magickaMultiplier

    local baseDrifted = false
    if expectedMaxMagicka then
        baseDrifted = not almostEqual(tes3.mobilePlayer.magicka.base, expectedMaxMagicka, 0.5)
    end

    if not willChanged
    and not intChanged
    and not levelChanged
    and not multChanged
    and not baseDrifted
    and not interop.recalcMagicka then
        return
    end

    if baseDrifted then
        logMsg(string.format(
            "Magicka base drift detected. Current base: %f | Expected base: %f",
            tes3.mobilePlayer.magicka.base,
            expectedMaxMagicka
        ))
    else
        logMsg("Willpower, intelligence, fortify maximum magicka magnitude, level, or magicka base has changed. Calculating magicka.")
    end

    setMagicka()
end

local function onLoaded()
    logMsg("Game loaded. Calculating magicka.")
    setMagicka()
end

local function onInitialized()
    event.register("loaded", onLoaded)
    event.register("enterFrame", onEnterFrame)
    mwse.log("%s Initialized.", modVersion)
end

event.register("initialized", onInitialized)


local function onModConfigReady()
    dofile("sanekBasedMagicka.mcm")
end

event.register("modConfigReady", onModConfigReady)