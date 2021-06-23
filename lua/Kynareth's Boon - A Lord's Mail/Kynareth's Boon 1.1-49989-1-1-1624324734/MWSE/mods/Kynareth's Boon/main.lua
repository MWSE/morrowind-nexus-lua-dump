-- The maximum proportion of an actor's maximum health that will be affected each second.
local maxProportion = 0.01

-- The maximum range at which the effect is effective.
local range = 500

local function getEffectiveMagnitude(mobile, stat, magnitude)
    -- Effect damages the actor.
    if magnitude < 0 then
        -- Actor's Resist Magicka magnitude minus actor's Weakness to Magicka magnitude. Can be negative.
        local resistMagicka = mobile.resistMagicka

        if resistMagicka ~= 0 then
            -- Resist Magicka magnitudes above 100 would result in negative damage, i.e. healing. Weakness to Magicka
            -- magnitude is not capped, so magnitudes above 100 (i.e. resistMagicka is < -100) can continue to make
            -- things worse.
            resistMagicka = math.min(resistMagicka, 100)

            -- The result is a number between 0.0, for magnitude 100 Resist Magicka, and 2.0, for magnitude 100 Weakness
            -- to Magicka. (It can actually be above 2.0 with very high Weakness to Magicka magnitudes.)
            local multiplier = -resistMagicka
            multiplier = multiplier * 0.01
            multiplier = multiplier + 1

            magnitude = magnitude * multiplier
        end
    end

    -- Effect heals the actor.
    if magnitude > 0 then
        local currentStat = mobile[stat].current
        local maxStat = mobile[stat].base
        local difference = maxStat - currentStat

        if difference <= 0 then
            -- The actor's current stat is at or above the max, so do nothing.
            magnitude = 0
        else
            -- Make sure we're not healing the actor above the max.
            magnitude = math.min(magnitude, difference)
        end
    end

    return magnitude
end

local function modCurrentStat(mobile, stat, amount)
    if amount == 0 then
        return
    end

    tes3.modStatistic{
        reference = mobile,
        name = stat,
        current = amount,
    }
end

-- Has a percent chance of returning true equal to num.
local function checkRandom(num)
    -- Num is the Spell Absorption or Reflect magnitude. No point in a magnitude above 100.
    num = math.min(num, 100)
    local proportionalNum = num * 0.01

    -- Random float between 0 and 1.
    local random = math.random()

    if random < proportionalNum then
        return true
    else
        return false
    end
end

local function getEffectMag(mobile, effect)
    return tes3.getEffectMagnitude{
        reference = mobile,
        effect = effect,
    }
end

-- Runs once per second.
local function lordsMailEffect()
    local playerCuirass = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.armor,
        slot = tes3.armorSlot.cuirass,
    }

    -- Player doesn't have a cuirass equipped.
    if not playerCuirass then
        return
    end

    -- Player is equipping the wrong cuirass.
    if playerCuirass.object.id ~= "lords_cuirass_unique" then
        return
    end

    -- Returns a table of all mobile actors within the defined distance from the player.
    local mobileList = tes3.findActorsInProximity{
        reference = tes3.player,
        range = range,
    }

    -- Iterate through each of these actors one at a time.
    for _, mobile in ipairs(mobileList) do
        -- The player is always within range of the player.
        if mobile == tes3.mobilePlayer then
            goto continue
        end

        local hostileToPlayer = false

        -- Go through a list of all actors the present actor is actively hostile toward and see if any of them is the
        -- player. Doing it this way instead of just checking .fight to ensure the player can't just sneak up on an
        -- enemy and stand there until the enemy is dead.
        for _, hostileActor in ipairs(mobile.hostileActors) do
            if hostileActor == tes3.mobilePlayer then
                hostileToPlayer = true
                break
            end
        end

        -- Only affect actors who are actively trying to kill the player.
        if not hostileToPlayer then
            goto continue
        end

        -- How far away the present actor is from the player. There's mobile.playerDistance, but it's less accurate.
        local distance = mwscript.getDistance{
            reference = mobile,
            target = tes3.mobilePlayer,
        }

        -- 0.0 means the actor is right on top of the player, 1.0 means the actor is at the far end of the range.
        local proportionalDistance = distance / range

        -- Reverse the above, 0.0 is at the far end of the range, 1.0 is right on top of the player.
        proportionalDistance = math.max(1 - proportionalDistance, 0)

        -- The proportion of the actor's max health that will be affected, ranging from 0 to maxProportion.
        local proportion = maxProportion * proportionalDistance

        local actorMaxHealth = mobile.health.base
        local magnitude = actorMaxHealth * proportion

        --[[ The total Spell Absorption magnitude on the actor. Note that this works a bit differently than in vanilla.
        In vanilla Spell Absorption is not additive, but each effect results in a separate chance to absorb. For this
        mod, multiple effects are additive, because that's a whole lot easier than rolling a chance for each effect
        separately. ]]--
        local spellAbsorption = getEffectMag(mobile, tes3.effect.spellAbsorption)

        if spellAbsorption > 0 then
            -- Has a percent chance of returning true equal to the actor's Spell Absorption magnitude.
            if checkRandom(spellAbsorption) then
                -- Increase the actor's magicka, but make sure we don't boost it above the max.
                local effectiveMagnitude = getEffectiveMagnitude(mobile, "magicka", magnitude)
                modCurrentStat(mobile, "magicka", effectiveMagnitude)

                -- And we're done with this actor.
                goto continue
            end
        end

        local reflect = getEffectMag(mobile, tes3.effect.reflect)

        if reflect > 0 then
            if checkRandom(reflect) then
                -- If the reflect check succeeds, the effect is reversed (i.e. heal the actor, hurt the player).
                magnitude = -magnitude
            end
        end

        -- For negative magnitudes, take Resist Magicka (and Weakness to Magicka) into account. For positive magnitudes,
        -- make sure we don't increase health above the max.
        local magnitudePlayer = getEffectiveMagnitude(tes3.mobilePlayer, "health", magnitude)
        local magnitudeActor = getEffectiveMagnitude(mobile, "health", -magnitude)

        modCurrentStat(tes3.mobilePlayer, "health", magnitudePlayer)
        modCurrentStat(mobile, "health", magnitudeActor)

        ::continue::
    end
end

-- Runs every time the game is loaded.
local function onLoaded()
    -- Runs our main function every second. -1 iterations means repeat indefinitely.
    timer.start{
        duration = 1,
        iterations = -1,
        callback = lordsMailEffect,
    }
end

event.register("loaded", onLoaded)