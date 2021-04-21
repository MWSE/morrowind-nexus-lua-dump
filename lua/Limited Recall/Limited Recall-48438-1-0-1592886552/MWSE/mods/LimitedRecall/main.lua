local mod = "Limited Recall"
local version = "1.0"

local config = require("LimitedRecall.config")

local savedData, magicFailMessage, recallsLeftToday, recallsLeftLifetime, currentInGameDay, currentRealDay, outOfRecallsMessage

-- Updates the persistent data storing how many Recalls have been cast.
local function incrementRecallCount()

    -- Recall has already been cast this in-game day, so just increment the count.
    if currentInGameDay == savedData.lastRecallInGameDay then
        savedData.recallsTodayInGame = savedData.recallsTodayInGame + 1

    -- This is the first casting this in-game day, so update the last day value and set the count to 1.
    else
        savedData.lastRecallInGameDay = currentInGameDay
        savedData.recallsTodayInGame = 1
    end

    -- Same as above, but for real-life days. We keep track of both, even though the player is only using one limit at a time.
    if currentRealDay == savedData.lastRecallRealDay then
        savedData.recallsTodayReal = savedData.recallsTodayReal + 1
    else
        savedData.lastRecallRealDay = currentRealDay
        savedData.recallsTodayReal = 1
    end

    -- Increment the lifetime count. We keep track of this even if the lifetime limit is not being enforced.
    savedData.recallsLifetime = savedData.recallsLifetime + 1

    recallsLeftToday = recallsLeftToday - 1
    recallsLeftLifetime = recallsLeftLifetime - 1

    if config.displayMessages then

        -- Separate lines in the message for Recalls left today and total Recalls left.
        local todayMessage, lifetimeMessage

        if recallsLeftToday == 1 then
            todayMessage = "You have 1 Recall remaining today."
        else
            todayMessage = string.format("You have %d Recalls remaining today.", recallsLeftToday)
        end

        if recallsLeftLifetime == 1 then
            lifetimeMessage = "You have 1 Recall remaining in total."
        else
            lifetimeMessage = string.format("You have %d Recalls remaining in total.", recallsLeftLifetime)
        end

        if config.enableLifetimeLimit then

            -- Player is out of lifetime Recalls, so just tell them that (how many are left for the day doesn't matter).
            if recallsLeftLifetime <= 0 then
                tes3.messageBox(lifetimeMessage)

            -- Show both messages.
            else
                tes3.messageBox(todayMessage .. "\n" .. lifetimeMessage)
            end

        -- Not using the lifetime limit, so just show how many are left for the day.
        else
            tes3.messageBox(todayMessage)
        end
    end
end

-- The failure message is slightly different depending on whether the player is out of lifetime Recalls.
local function adjustOutOfRecallsMessage()
    if config.enableLifetimeLimit and recallsLeftLifetime <= 0 then
        outOfRecallsMessage = outOfRecallsMessage .. "."
    else
        outOfRecallsMessage = outOfRecallsMessage .. " today."
    end
end

-- Updates how many Recalls are left to the player.
local function checkRecallsLeft()
    recallsLeftToday = config.recallLimit
    recallsLeftLifetime = config.recallLifetimeLimit - savedData.recallsLifetime

    currentInGameDay = tes3.findGlobal("DaysPassed").value

    -- os.time() is the number of seconds since midnight, January 1, 1970.
    -- Divide by the number of seconds in a day to get the number of days since that time.
    -- This actually won't be exactly right, due to leap seconds, but close enough.
    -- The actual number doesn't matter, only that it will remain the same for the whole real-life day.
    currentRealDay = math.ceil(os.time() / 86400)

    -- If the player has cast Recall already today, subtract the saved number of times Recall has been used
    -- Which values are used depends on whether the player is using a real-life or in-game day limit.
    if config.realLifeDayLimit then
        if currentRealDay == savedData.lastRecallRealDay then
            recallsLeftToday = recallsLeftToday - savedData.recallsTodayReal
        end
    else
        if currentInGameDay == savedData.lastRecallInGameDay then
            recallsLeftToday = recallsLeftToday - savedData.recallsTodayInGame
        end
    end
end

-- Runs each time any source of magic effects (spells, enchanted items, scrolls, potions, ingredients) is used.
local function onMagicCasted(e)

    -- Mod is configured to only limit spells, so we don't care about these other sources.
    if not config.limitAllSources then
        return
    end

    -- It's not the player using the magic source, so we don't care.
    if e.caster ~= tes3.player then
        return
    end

    -- This is a spell, so we don't care (spells are handled in onSpellCast).
    if e.sourceInstance.sourceType == 1 then
        return
    end

    local isRecall = false
    local effectNum

    -- Check each effect to see if it includes a Recall effect (and remember which effect is Recall).
    for i = 1, #e.source.effects do
        if e.source.effects[i].id == tes3.effect.recall then
            isRecall = true
            effectNum = i
            break
        end
    end

    -- Not Recall, so we don't care.
    if not isRecall then
        return
    end

    -- Determine how many Recalls are left to the player, today and in total.
    checkRecallsLeft()

    -- Player is out of Recalls.
    if recallsLeftToday <= 0 or ( config.enableLifetimeLimit and recallsLeftLifetime <= 0 ) then

        -- Change the Recall effect to Reflect (it will only be 1 point for 1 second) to prevent the player from Recalling.
        e.sourceInstance.source.effects[effectNum].id = tes3.effect.reflect

        -- Determine the message to display on failure, depending on whether the player is out of lifetime or just daily Recalls.
        outOfRecallsMessage = "You cannot use any more Recall effects"
        adjustOutOfRecallsMessage()

        tes3.messageBox(outOfRecallsMessage)

        -- Play the spell failure sound.
        tes3.playSound{
            sound = "Spell Failure Mysticism",
            reference = tes3.player,
        }

        -- Wait for the effect to be applied.
        timer.start{
            duration = 0.1,
            callback = function()

                -- Cancel the hit sound for the Reflect effect.
                tes3.removeSound{
                    sound = "mysticism hit",
                    reference = tes3.player,
                }

                -- Change the effect for this item back to Recall (otherwise a Recall amulet would be converted to a Reflect amulet for example).
                e.sourceInstance.source.effects[effectNum].id = tes3.effect.recall
            end,
        }

        return
    end

    -- Player is not out of Recalls, so allow the effect to take place as normal.
    -- Increment the persistent Recall counts in the player's savegame, and possibly display a message.
    incrementRecallCount()
end

-- Runs each time a regular spell is cast, before success or failure is determined.
local function onSpellCast(e)

    -- If it's not the player casting the spell, we don't care.
    if e.caster ~= tes3.player then
        return
    end

    local isRecall = false

    -- Check each of the spell's effects to see if it includes the Recall effect.
    for i = 1, #e.source.effects do
        if e.source.effects[i].id == tes3.effect.recall then
            isRecall = true
            break
        end
    end

    -- This is not a Recall spell, so we don't care.
    if not isRecall then
        return
    end

    -- Determine how many Recalls are left to the player, today and in total.
    checkRecallsLeft()

    -- Player is out of Recalls.
    if recallsLeftToday <= 0 or ( config.enableLifetimeLimit and recallsLeftLifetime <= 0 ) then

        -- Force the spell to fail.
        e.castChance = 0

        -- Restore the magicka the player expended to cast the spell.
        tes3.modStatistic{
            reference = tes3.player,
            name = "magicka",
            current = e.source.magickaCost,
        }

        -- Determine the message to display on failure, depending on whether the player is out of lifetime or just daily Recalls.
        outOfRecallsMessage = "You cannot cast Recall any more"
        adjustOutOfRecallsMessage()

        -- Change this GMST so our custom failure message will be displayed.
        tes3.findGMST("sMagicSkillFail").value = outOfRecallsMessage

        -- Wait for the failure message to be displayed then change the GMST back.
        timer.start{
            duration = 0.1,
            callback = function()
                tes3.findGMST("sMagicSkillFail").value = magicFailMessage
            end,
        }

        return
    end

    -- Player is not out of Recalls, so determine whether or not the spell succeeds.
    -- We have to determine success or failure ourselves because otherwise a failed casting would count toward the limit.
    if e.castChance < math.random(0, 100) then

        -- We've determined the spell fails, so make the spell actually fail.
        e.castChance = 0
        return
    end

    -- We've determined the spell succeeds, so make the spell actually succeed.
    e.castChance = 100

    -- Increment the persistent Recall counts in the player's savegame, and possibly display a message.
    incrementRecallCount()
end

-- Runs each time the game is loaded.
local function onLoaded()

    -- Get our persistent data stored in the savegame, creating it if needed.
    tes3.player.data.limitedRecall = tes3.player.data.limitedRecall or {}
    savedData = tes3.player.data.limitedRecall

    savedData.recallsTodayInGame = savedData.recallsTodayInGame or 0
    savedData.recallsTodayReal = savedData.recallsTodayReal or 0
    savedData.recallsLifetime = savedData.recallsLifetime or 0

    savedData.lastRecallInGameDay = savedData.lastRecallInGameDay or 1
    savedData.lastRecallRealDay = savedData.lastRecallRealDay or 1
end

local function onInitialized()
    event.register("loaded", onLoaded)
    event.register("spellCast", onSpellCast)
    event.register("magicCasted", onMagicCasted)

    -- Get this here so we can set it back to this text later.
    magicFailMessage = tes3.findGMST("sMagicSkillFail").value

    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)

-- Register the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\LimitedRecall\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)