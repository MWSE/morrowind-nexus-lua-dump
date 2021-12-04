local this = {
    config = {},
    currentlyExposed = {},
    currentlyBleeding = {},
    currentArmorCache = {},
    multistrikeCounters = {},
    currentlyRushed = {},
    bonusMultiplierFromAttackEvent = {},
    currentlyHamstrung = {},
    fadeTimer = nil,
    enemyHealthBar = nil,
    weaponSkills = {
        [0] = true, -- block
        [4] = true, -- blunt
        [5] = true, -- long blade
        [6] = true, -- axe
        [7] = true, -- spear
        [22] = true, -- short blade
        [26] = true, -- hand to hand
    },
    armorSkills = {
        [2] = true, -- medium armor
        [3] = true, -- heavy armor
        [17] = true, -- unarmored
        [21] = true, -- light armor
    }
}
local defaultConfig = {
    showMessages = true,
    showActiveBlockMessages = true,
    showDamageNumbers = false,
    showDebugMessages = false,
    showSkillGainDebugMessages = false,
    toggleAlwaysHit = true,
    toggleWeaponPerks = true,
    toggleActiveBlocking = true,
    toggleHandToHandPerks = true,
    toggleSkillGain = true,
    toggleBalanceGMSTs = true,
    creatureBonusModifier = 0.3,
    weaponSkillModifier = 0.2,
    attackBonusModifier = 0.5,
    fatigueReductionModifier = 0.2,
    sanctuaryModifier = 0.35,
    multistrikeStrikesNeeded = 3,
    multistrikeBonuseDamageMultiplier = 1,
    criticalStrikeMultiplier = 1,
    bleedMultiplier = 1.5,
    handToHandBaseDamageMin = 2,
    handToHandBaseDamageMax = 3,
    agilityKnockdownChanceMinMod = 0.25,
    activeBlockingFatigueMin = 0.25,
    activeBlockingFatiguePercentBase = 0.25,
    weaponSkillGainBaseModifier = 0.6,
    armorSkillGainBaseModifier = 0.8,
    toggleActiveBlockingMouse2 = false,
    executeThreshold = 0.25,
    bowZoomLevel = 2,
    hamstringModifier = 0.5,
    fullDrawFatigueDrainPercent = 0.05,
    fullDrawFatigueMin = 0.20,
    fullDrawBackSpeedModifier = 0.3,
    crossbowCriticalRange = 800,
    thrownAgilityModifier = 0.5,
    riposteDamageMultiplier = 0.5,
    riposteDuration = 2,
    activeBlockKey = {
        keyCode = 44,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    nonStandardAttackKey = {
        keyCode = nil,
    },
    gmst = {
        knockdownMult = 0.8,
        knockdownOddsMult = 70,
        fatigueAttackMult = 0.2,
        fatigueAttackBase = 3,
        weaponFatigueMult = 0.5,
        projectileMaxSpeed = 4000,
        projectileMinSpeed = 560,
        thrownWeaponMaxSpeed = 1200,
        thrownWeaponMinSpeed = 360,
    },
    weaponTier1 = {
        weaponSkillMin = 25,
        criticalStrikeChance = 10,
        multistrikeDamageMultiplier = 0.1,
        bleedChance = 15,
        stunChance = 5,
        bonusDamageForFatigueMultiplier = 0.15,
        handToHandBaseDamageMin = 3,
        handToHandBaseDamageMax = 4,
        handToHandKnockdownChance = 5,
        handToHandKnockdownDamageMultiplier = 0.1,
        activeBlockingFatiguePercent = 0.2,
        weaponSkillGainModifier = 0.65,
        bowFullDrawMultiplier = 0.25,
        bowNPCDrawMultiplier = 0.1,
        crossbowCriticalDamageMultiplier = 0.1,
        thrownCriticalStrikeChance = 10,
    },
    weaponTier2 = {
        weaponSkillMin = 50,
        criticalStrikeChance = 20,
        multistrikeBonusChance = 5,
        multistrikeDamageMultiplier = 0.2,
        bleedChance = 20,
        maxBleedStack = 1,
        stunChance = 10,
        bonusArmorDamageMultiplier = 0.2,
        bonusDamageForFatigueMultiplier = 0.3,
        adrenalineRushChance = 10,
        handToHandBaseDamageMin = 5,
        handToHandBaseDamageMax = 7,
        handToHandKnockdownChance = 10,
        handToHandKnockdownDamageMultiplier = 0.1,
        activeBlockingFatiguePercent = 0.15,
        weaponSkillGainModifier = 0.7,
        executeDamageMultiplier = 0.5,
        bowFullDrawMultiplier = 0.50,
        bowNPCDrawMultiplier = 0.17,
        hamstringChance = 10,
        repeaterChance = 20,
        crossbowCriticalDamageMultiplier = 0.15,
        thrownCriticalStrikeChance = 20,
        thrownChanceToRecover = 50,
        riposteChance = 10,
    },
    weaponTier3 = {
        weaponSkillMin = 75,
        criticalStrikeChance = 35,
        multistrikeBonusChance = 10,
        multistrikeDamageMultiplier = 0.35,
        bleedChance = 25,
        maxBleedStack = 2,
        stunChance = 15,
        bonusArmorDamageMultiplier = 0.25,
        bonusDamageForFatigueMultiplier = 0.45,
        adrenalineRushChance = 20,
        handToHandBaseDamageMin = 8,
        handToHandBaseDamageMax = 11,
        handToHandKnockdownChance = 15,
        handToHandKnockdownDamageMultiplier = 0.2,
        activeBlockingFatiguePercent = 0.1,
        weaponSkillGainModifier = 0.8,
        executeDamageMultiplier = 1,
        bowFullDrawMultiplier = 0.75,
        bowNPCDrawMultiplier = 0.25,
        hamstringChance = 15,
        repeaterChance = 35,
        crossbowCriticalDamageMultiplier = 0.20,
        thrownCriticalStrikeChance = 35,
        thrownChanceToRecover = 75,
        riposteChance = 15,
    },
    weaponTier4 = {
        weaponSkillMin = 100,
        criticalStrikeChance = 50,
        multistrikeBonusChance = 20,
        multistrikeDamageMultiplier = 0.5,
        bleedChance = 30,
        maxBleedStack = 3,
        stunChance = 20,
        bonusArmorDamageMultiplier = 0.33,
        bonusDamageForFatigueMultiplier = 0.6,
        adrenalineRushChance = 30,
        handToHandBaseDamageMin = 11,
        handToHandBaseDamageMax = 14,
        handToHandKnockdownChance = 20,
        handToHandKnockdownDamageMultiplier = 0.35,
        activeBlockingFatiguePercent = 0.05,
        weaponSkillGainModifier = 1,
        executeDamageMultiplier = 1.5,
        bowFullDrawMultiplier = 1,
        bowNPCDrawMultiplier = 0.33,
        hamstringChance = 20,
        repeaterChance = 50,
        crossbowCriticalDamageMultiplier = 0.25,
        thrownCriticalStrikeChance = 50,
        thrownChanceToRecover = 100,
        riposteChance = 20,
    },
}

-- Loads the configuration file for use.
function this.loadConfig()
	this.config = defaultConfig

    local configJson = mwse.loadConfig("ngc")
	if (configJson ~= nil) then
		this.config = configJson
    else
        mwse.saveConfig("ngc", this.config)
    end

	mwse.log("[Next Generation Combat] Loaded configuration:")
	mwse.log(json.encode(this.config, { indent = true }))
end

-- common util functions
function this.getARforTarget(target)
    local totalAR = 0
    for id, slot in pairs(tes3.armorSlot) do
        local equippedSlot = tes3.getEquippedItem({ actor = target, objectType = tes3.objectType.armor, slot = slot })
        if equippedSlot then
            totalAR = totalAR + equippedSlot.object.armorRating
        end
    end

    return totalAR
end

function this.keybindTest(b, e)
    return (b.keyCode == e.keyCode) and
    (b.isShiftDown == e.isShiftDown) and
    (b.isAltDown == e.isAltDown) and
    (b.isControlDown == e.isControlDown)
end

function this.updateEnemyHealthBar(targetActor)
    -- show enemy health bar
    this.enemyHealthBar.visible = true
    this.enemyHealthBar:setPropertyFloat("PartFillbar_current", targetActor.health.current)
    this.enemyHealthBar:setPropertyFloat("PartFillbar_max", targetActor.health.base)

    if this.fadeTimer == nil or this.fadeTimer.state == timer.expired  then
        this.fadeTimer = timer.start({
            duration = 3,
            callback = function ()
                this.enemyHealthBar.visible = false
            end,
            iterations = 1
        })
    elseif this.fadeTimer.state == timer.active then
        this.fadeTimer:reset()
    end
end

return this