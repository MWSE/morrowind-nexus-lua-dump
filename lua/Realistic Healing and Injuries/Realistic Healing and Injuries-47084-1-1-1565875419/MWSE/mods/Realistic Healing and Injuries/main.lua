local config = mwse.loadConfig("Realistic Healing and Injuries")
if (config == nil) then
	config = {
        combatDuration = 15,
        healthPercentPerTick = 0.1,
        minFatigueMod = 0.50,
        minHealthMod = 0.50,
        allowAlways = false,
        enableInjuries = true,
        restingHoursRequired = 8,
        durationHealthTick = 3,
        baseInjuryChance = 5,
        weakenedInjuryChanceBonus = 5,
        showInjuryMessages = true,
        debug = false,
	}
    mwse.saveConfig("Realistic Healing and Injuries", config)
end
local mcm = require("Realistic Healing and Injuries.mcm")
mcm.config = config
event.register("modConfigReady", mcm.registerModConfig)

local nextTimestamp
local timestampOffset = config.durationHealthTick / 100
local injuries = {
    [1] = "rhai_head_injury",
    [2] = "rhai_body_injury",
    [3] = "rhai_arm_injury",
    [4] = "rhai_leg_injury",
}
local playerRecentlyInCombat = false
local playerCombatTimer

local function healthTick(e)
    if nextTimestamp == nil then
        nextTimestamp = e.timestamp + timestampOffset
        return
    end

    if e.timestamp > nextTimestamp then
        if not config.allowAlways and playerRecentlyInCombat then
            nextTimestamp = e.timestamp + timestampOffset
            return
        end
        local maxHealth = tes3.mobilePlayer.health.base
        local currentHealth = tes3.mobilePlayer.health.current

        -- reduce healing by up to 50% further if low fatigue
        local maxFatigue = tes3.mobilePlayer.fatigue.base
        local currentFatigue = tes3.mobilePlayer.fatigue.current
        local fatigueMod
        if currentFatigue < maxFatigue then
            fatigueMod = currentFatigue / maxFatigue
            if fatigueMod < config.minFatigueMod then
                fatigueMod = config.minFatigueMod
            end
        end

        if currentHealth < maxHealth then
            local healthMod = currentHealth / maxHealth
            if healthMod < config.minHealthMod then
                healthMod = config.minHealthMod
            end

            local perTickMod = config.healthPercentPerTick
            -- reduce healing by half if running or swimming
            if tes3.mobilePlayer.isRunning or tes3.mobilePlayer.isSwimming then
                perTickMod = perTickMod / 2
            end

            -- adjust per tick by low health and low fatigue
            perTickMod = perTickMod * healthMod
            if fatigueMod then
                perTickMod = perTickMod * fatigueMod
            end

            local perTick = maxHealth * perTickMod
            if (perTick + currentHealth) > maxHealth then
                if config.debug then
                    tes3.messageBox({ message = "Healing by: " .. perTick })
                end
                tes3.setStatistic({ reference = tes3.player, name = "health", current = maxHealth })
            else
                if config.debug then
                    tes3.messageBox({ message = "Healing by: " .. perTick })
                end
                tes3.setStatistic({ reference = tes3.player, name = "health", current = (currentHealth + perTick)})
            end
        end
        nextTimestamp = e.timestamp + timestampOffset
    end
end

local function calcRestInterrupt(e)
    tes3.setStatistic({ reference = tes3.player, name = "health", current = tes3.mobilePlayer.health.base })

    if e.resting and tes3.mobilePlayer.restHoursRemaining > (config.restingHoursRequired - 1) then
        -- we have started to rest for at least 8 hours
        for _, spell in ipairs(injuries) do
            if mwscript.getSpellEffects({reference = tes3.player, spell = spell}) then
                mwscript.removeSpell({reference = tes3.player, spell = spell})
            end
        end
    end
end

local function calcInjury(e)
    local defender = e.mobile
    local defenderRef = e.reference

    if not config.allowAlways then
        -- we've been hit, so player is in combat
        playerRecentlyInCombat = true
        if playerCombatTimer then
            playerCombatTimer:cancel()
            playerCombatTimer = nil
        end
        playerCombatTimer = timer.start({
            duration = config.combatDuration,
            callback = function()
                playerCombatTimer = nil
                playerRecentlyInCombat = false
            end,
        })
    end

    -- only ignore magic
    if e.source ~= "magic" then
        local maxHealth = defender.health.base
        local currentHealth = defender.health.current
        local healthDiff = currentHealth /  maxHealth
        local maxFatigue = defender.fatigue.base
        local currentFatigue = defender.fatigue.current
        local fatigueDiff = currentFatigue / maxFatigue
        local injuryChance = config.baseInjuryChance

        if (healthDiff + fatigueDiff) > 0 then
            injuryChance = injuryChance + (config.weakenedInjuryChanceBonus * (1 - ((healthDiff + fatigueDiff) / 2)))
            if config.debug then
                tes3.messageBox({ message = "Injury chance: " .. injuryChance })
            end
        end

        local injuryRoll = math.random(100)
        if injuryChance >= injuryRoll then
            -- we have an injury, roll for injury type
            local injuryTypeRoll = math.random(4)
            local injurySpell = injuries[injuryTypeRoll]
            if injurySpell then
                if not mwscript.getSpellEffects({reference = defenderRef, spell = injurySpell}) then
                    mwscript.addSpell({reference = defenderRef, spell = injurySpell})

                    if tes3.player == defenderRef and config.showInjuryMessages then
                        tes3.messageBox({ message = "Injured!" })
                    end
                end
            end
        end
    end
end

local function initialized(e)
    if tes3.isModActive("Realistic Healing And Injuries.esp") then
        mwse.log("[Realistic Healing and Injuries] Initialized")
        event.register("simulate", healthTick)
        event.register("calcRestInterrupt", calcRestInterrupt)
        if config.enableInjuries then
            event.register("damage", calcInjury)
            mwse.log("[Realistic Healing and Injuries] Injuries enabled")
        end
    end
end
event.register("initialized", initialized)