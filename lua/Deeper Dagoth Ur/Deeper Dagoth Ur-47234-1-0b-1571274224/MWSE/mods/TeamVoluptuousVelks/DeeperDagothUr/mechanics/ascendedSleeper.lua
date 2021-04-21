local common = require("TeamVoluptuousVelks.DeeperDagothUr.common")

-- Ascended Sleeper Mechanics --
local ascendedSleeperId = "ascended_sleeper"

local function isAscendedSleeper(id)
    return id == ascendedSleeperId
end

local function onDeathOfAscendedSleeper(e)
    local referenceId = e.mobile.object.baseObject.id
    if (isAscendedSleeper(referenceId) == false) then
        return
    end

    common.debug("Ascended Sleeper is dying.")

    -- 10% chance of this occuring on death.
    if (common.shouldPerformRandomEvent(10)) then
        local result = math.random(1, 3)

        if (result == 1) then
            common.debug("Ascended Sleeper Death: Result 1.")
            tes3.messageBox(common.data.dialogue.ascendedSleeper[1])
        elseif (result == 2) then
            common.debug("Ascended Sleeper Death: Result 2.")
            tes3.messageBox(common.data.dialogue.ascendedSleeper[2])
        else 
            common.debug("Ascended Sleeper Death: Result 3.")
            tes3.messageBox(common.data.dialogue.ascendedSleeper[3])
        end

        return
    end

    common.debug("Ascended Sleeper Death: Check failed.")
end

local onCombatStartedWithAscendedSleeperInitialized = {}
local function onCombatStartedWithAscendedSleeper(e)
    local targetId = e.target.object.baseObject.id
    local targetReferenceId = e.target.object.id

    if (isAscendedSleeper(targetId) == false) then
        return
    end

    if (e.actor ~= tes3.mobilePlayer) then
        return
    end

    if (onCombatStartedWithAscendedSleeperInitialized[targetReferenceId] == true) then  
        return
    end

    common.debug("Starting Combat with Ascended Sleeper.")

    -- Mark the reference as processed.
    onCombatStartedWithAscendedSleeperInitialized[targetReferenceId] = true

    local ascendedSleeper = e.target
    local player = e.actor

    local hasCastHealSpell = false
    local castsSummonAshSlaves = 0

    local combatTimer
    combatTimer = timer.start({
        duration = 5,
        callback = function ()
            if (ascendedSleeper.health.current < 1) then                
                common.debug("Ascended Sleeper Combat: Ascended sleeper has died. Timer Cancelled.")
                combatTimer:cancel()
                return
            end

            if (hasCastHealSpell and castsSummonAshSlaves >= 5) then             
                common.debug("Ascended Sleeper Combat: Ascended sleeper has used all new mechanics. Timer Cancelled.")
                combatTimer:cancel()
                return
            end

            if (common.shouldPerformRandomEvent(60) == false) then
                common.debug("Ascended Sleeper Combat: Random Check failed. Continuing on next iteration.")
                return
            end

            common.debug("Ascended Sleeper Combat: Current health at " .. ascendedSleeper.health.current)

            if (hasCastHealSpell == false and ascendedSleeper.health.current <= 100) then
                common.debug("Ascended Sleeper Combat: Casting Self Heal.")

                -- Explodes spell, healing self and giving blight to nearby actors.
                common.forceCast({
                    reference = ascendedSleeper,
                    target = ascendedSleeper,
                    spell = common.data.spellIds.ascendedSleeperHeal
                })            

                local distainceLimit = 450
                if (player.position:distance(ascendedSleeper.position) <= distainceLimit) then
                    local rand = math.random(0, 4)
                    local spellObject = {}
                    if (rand == 1) then
                        spellObject = common.data.diseaseIds.blackHeartBlight
                    elseif (rand == 2) then
                        spellObject = common.data.diseaseIds.ashWoeBlight
                    elseif (rand == 3) then
                        spellObject = common.data.diseaseIds.ashChancreBlight
                    else
                        spellObject = common.data.diseaseIds.chanthraxBlight
                    end

                    mwscript.addSpell({
                        reference = player,
                        spell = spellObject.id
                    })

                    tes3.messageBox("As the Ascended Sleeper heals, you are contaminated due to your close proximity. You have contracted %s.", spellObject.name)
                end

                hasCastHealSpell = true
            end

            if (castsSummonAshSlaves < 5) then
                common.debug("Ascended Sleeper Combat: Summoning Ash Slaves.")

                -- Explodes spell, for visual effect.
                common.forceCast({
                    reference = ascendedSleeper,
                    target = ascendedSleeper,
                    spell = common.data.spellIds.ascendedSleeperSummonAshSlaves
                })

                castsSummonAshSlaves = castsSummonAshSlaves + 1
            end
        end,
        iterations = 24
    })
end

event.register("death", onDeathOfAscendedSleeper)
event.register("combatStarted", onCombatStartedWithAscendedSleeper)
------------------------------------------