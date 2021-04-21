--[[
    Timely Escape
    v1.1.3
    by JaceyS
]]--

--[[
    Logic Flow.
    (Configurable steps are marked with an asterisk)
    1. function onDamage() detects if incoming damage is enough to kill the player. Blocks the damage, and if an escape
        is not already underway, starts one by calling ->
    2. function prepareEscape(), which checks to see if teleportation is blocked, and if the player is killed by due to
        low stats*. Plays the death animation*, fades out, and proceeds after a delaty to ->
    3. function escape() confirms escape*, and then teleports the player to Shrine of Azura*, or generates a potion
        with an intervention effect* to feed to the player. Quashes spell sound*. Flags teleporting to true so that->
    4. function onCellChange() can detect when the player has teleported. Proceeds to ->
    5. function timeSkip(), which passes game time* before proceeding to ->
    6. function finalizeEscape(), which applies stat penalties*, plays messages*, clears harmful spell effects, and
        heals* the player before closing the escape and fading back in.
]]
local config = require("TimelyEscape.config")
local escaping
local perspective
local quashSpellSound
local teleporting
local timeScale

-- prevent other mods that run on equip or equipped from triggering when my potion is equipped.
local function potionEquipOverride(e)
    if (e.item.id == "TE_Teleport_Potion") then
		e.claim = true
	end
end
-- used to quash the potion drinking sound.
local function potionDrinkSoundQuasher()
    tes3.removeSound({sound = tes3.getSound("Drink"), reference = tes3.player})
end
-- used to quash the spell sound if the natural mode is enabled. Doesn't seem to work.
local function spellSoundQuasher()
    tes3.removeSound({sound = tes3.getSound("mysticism hit"), reference = tes3.player})
end
-- prevent the player from saving during the escape, which would break everything if they then reloaded the save.
local function blockSave()
    if (escaping == true) then
        tes3.messageBox "You can't save right now -- you are dying!"
        return false
    end
end
-- Prevent the player from loading during while the temporary event-registered functions are spun up, so that they don't stay on if they load a new game.
local function loadBlocker()
    return false
end

local function finalizeEscape()
    -- apply any stat penalties. First put the non-changing elements in a table.
    local statPenalty = {limit = true, reference = tes3.mobilePlayer, value = -1 * config.statPenalty}
    local stat
    local stats
    local statName
    -- determine if we are working with stats or attributes
    if (config.penaltyOptions == "skills") then
        stat = "skill"
        stats = table.size(tes3.skill) -1
        statName = tes3.skillName
    else
        stat = "attribute"
        stats = table.size(tes3.attribute) -1
        statName = tes3.attributeName
    end
    local pickedStats = {}
    local reportOut = ""
    if (config.randomPick == true and config.penaltyOptions == "skills" or config.penaltyOptions == "attributes") then
        local numbertoPick = tonumber(config.numberToPick)
        if (numbertoPick >= stats + 1) then
            numbertoPick = stats + 1
        end
        local n = 1
        while (n <= numbertoPick) do -- randomly pick a number of skills to decrease, add them to a table
            local pick = math.random(0, stats) -- unlike Lua tables, the attributes and skills start with 0.
            if(config.preventDoublePick == true) then     -- if preventDoublePick is true,
                if (table.find(pickedStats,pick) == nil) then   -- then search through the table for the value
                    pickedStats[n] = pick                 -- before adding it.
                    reportOut = reportOut.."Your ".. statName[pick].." "..stat.." has been reduced."
                    n = n + 1
                    if(n <= numbertoPick) then
                        reportOut = reportOut .. "\n"
                    end
                end
            else
                pickedStats[n] = pick
                reportOut = reportOut.."Your ".. statName[pick].." "..stat.." has been reduced."
                n = n + 1
                if(n <= numbertoPick) then
                    reportOut = reportOut .. "\n"
                end
            end
        end
        for i = 1, table.size(pickedStats) do -- iterate through the table of picked skills
            local iterateStatPenalty = statPenalty
            iterateStatPenalty[stat] = pickedStats[i]
            tes3.modStatistic(iterateStatPenalty) -- and decrease them
        end
    elseif (stat == "attribute" and (config.penaltyOptions == "luck" or config.penaltyOptions == "endurance")) then
        local singleStatPenalty = statPenalty
        if(config.penaltyOptions == "luck") then
            singleStatPenalty[stat] = tes3.attribute.luck
        else
            singleStatPenalty[stat] = tes3.attribute.endurance
        end
        tes3.modStatistic(singleStatPenalty)
    else
        for i = 0, stats do --if randomPick is not enabled, then decrease all the skills.
            local iterateStatPenalty = statPenalty
            iterateStatPenalty[stat] = i
            tes3.modStatistic(iterateStatPenalty)
        end
    end
    -- if the messageBox config option is true, display a message
    if (config.messageBox == true) then
        if (config.statPenalty > 0)then
            reportOut = "This has been a harrowing experience. You feel weaker in body, mind, and spirit.\n" .. reportOut
        end
        if (config.natural == true) then
            if(config.recoveryTime > 1) then
                reportOut = "You have been unconcious for "..config.recoveryTime.. " days.\n" .. reportOut
            end
            reportOut = "You awaken with a pounding headache. The local priests inform you that a friendly traveler found you left for dead, and returned you here to recover. The traveler did not wait for you to wake up, and did not tell the priests their identity, so you may never know your savior.\n" .. reportOut
        else
            reportOut = "Some great power has saved you from a certain death.\n" .. reportOut
        end
        if(reportOut ~= "") then
            tes3.messageBox({message = reportOut, buttons = {"Continue"}})
        end
    end
    -- if the voice config option is true, play the voice clip.
    if (config.voice == true) then
        tes3.say({
            soundPath = "Vo\\Misc\\fearnot.mp3",
            reference = tes3.player,
            subtitle = "Fear not, for I am watchful. You have been chosen."
        })
    end
    -- if we played the death animation, we need to undo the effects of it.
    if(config.deathAnimation == true) then
        if (perspective == false)then tes3.force1stPerson() end
        tes3.mobilePlayer.controlsDisabled = false
        tes3.playAnimation({
            reference = tes3.mobilePlayer,
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 1
        })
    end
    -- if restore health is true, then set the player's current health to base.
    if(config.restoreHealth == true) then
        tes3.setStatistic({name = "health", reference = tes3.mobilePlayer, current = tes3.mobilePlayer.health.base})
    end
    -- remove damaging spell effects so that it does not immediately kill the player again
    for i=1, table.size(config.damagingEffectIDs) do
		tes3.removeEffects({effect = config.damagingEffectIDs[i], reference = tes3.player})
    end
    if(config.natural == true) then
        event.unregister("simulate", spellSoundQuasher)
    end
    event.unregister("simulate", potionDrinkSoundQuasher)
    event.unregister("load", loadBlocker)
    tes3.fadeIn({duration = 1})
    escaping = false
end

-- Put timescale back to normal, and proceed
local function endTimeSkip()
    tes3.findGlobal("TimeScale").value = timeScale
    finalizeEscape()
end

-- if natural is enabled, then speed up time until that has been elapsed. Otherwise, proceed.
local function timeSkip()
    if (config.natural == true) then
        timeScale = tes3.findGlobal("TimeScale").value
        tes3.findGlobal("TimeScale").value = 172800 -- pass 1 day every .5 second.
        timer.start({type = timer.game, duration = config.recoveryTime * 24, callback = endTimeSkip})
    else
        finalizeEscape()
    end
end

-- fallback for the edgecase in which the player is already in the cell the intervention would have taken them.
local function hasCellChanged()
    if (teleporting == true) then
        teleporting = false
        timer.delayOneFrame(timeSkip)
    end
end

-- wait until the player has been teleported to the new cell to proceed
local function onCellChanged()
    if (teleporting == true) then
        teleporting = false
        timer.delayOneFrame(timeSkip)
    end
end

--Teleport to Azura, or generate and equip a teleport potion.
local function escape()
    if(config.teleportOption == "azura") then
        tes3.playSound({sound = "mysticism hit", volume = 1, reference = tes3.player})
        tes3.positionCell({
            cell = "Shrine of Azura",
            position = {409.38, 5115.61, 2.00},
            orientation = {math.rad(0), math.rad(-35), math.rad(270)}
        })
        -- flag for the onCellChange function
        teleporting = true
        return
    end
    -- set the escapeEffectID value to the corresponding number based on the almsivi config option
    local escapeEffectID
    if(config.teleportOption == "almsivi") then
        escapeEffectID = tes3.effect.almsiviIntervention
    else
        escapeEffectID = tes3.effect.divineIntervention
    end
    -- if the natural option is enabled, block the spell sound.
    if(config.natural == true) then
        event.register("simulate", spellSoundQuasher)
    end
    -- create a potion with the selected type of intervention effect
    local teleportPotion = tes3alchemy.create({
        id = "TE_Teleport_Potion",
        effects = {{
            id = escapeEffectID
        }}
    })
    --[[ give the potion to the player, and equip it.
    Using using the addItem function separately, because the addItem boolean built into the equip method wasn't working.
    Using the mwscript addItem function, because the tes3 one was playing a pickup sound.
    Using the mwscript equip function,
    because for some reason the equip method on the tes3mobilePlayer wasn't allowing me to intercept the potion sound.
    ]]--
    event.register("load", loadBlocker)
    event.register("simulate", potionDrinkSoundQuasher)
    mwscript.addItem({reference = tes3.mobilePlayer, item = teleportPotion})
    mwscript.equip({reference = tes3.mobilePlayer, item = teleportPotion})
    -- clean up the created potion object, so that the ID can be used again.
    tes3.deleteObject(teleportPotion)
    -- flag for the onCellChange function
    teleporting = true
    -- fallback for the edgecase where the player is already in the cell where the intervention would have taken them.
    timer.start({duration = 3, callback = hasCellChanged})
end

-- if enabled, get confirmation before proceeding
local function confirm()
    if (config.confirmation == true) then
        tes3.messageBox({
            message = "Do you want to accept intervention?",
            buttons = { tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value },
            callback = function(e)
                if (e.button == 1) then
                    tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
                    return
                else
                    timer.delayOneFrame(escape)
                end
            end
        })
    else
        timer.delayOneFrame(escape)
    end
end

--After the delay for the animation, proceed as normal.
local function endAnimate()
    tes3.fadeOut({duration = 0.5})
    timer.start({duration = 0.5, callback = confirm})
end

-- prepare for the escape, by checking for confounding factors, fading the screen, and playing animations, if enabled.
local function prepareEscape()
    -- A series of checks to kill the player if something is to prevent the teleportation.
    -- kill player if teleporting is disabled (such as in the Heart chamber)
    if (tes3.worldController.flagTeleportingDisabled == true) then
        escaping = false
        tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
        return
    end
    --[[If Luck - Binary is enabled, then check to see if the player has zero or less luck,
        and block the intervention. ]]--
    if (config.attributeDependentSurival == "luckBinary") then
        if (tes3.mobilePlayer.luck.current <= 0) then
            escaping = false
            tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
            return
        end
    end
    --[[ If Luck - Percentage is enabled, generate a random number between 1 and 100,
        and check it against the player's luck. ]]--
    if (config.attributeDependentSurival == "luckPercentage") then
        if (math.random(100) > tes3.mobilePlayer.luck.current) then
            escaping = false
            tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
            return
        end
    end
    --[[If Endurance - Binary is enabled, then check to see if the player has zero or less endurance,
        and block the intervention. ]]--
    if (config.attributeDependentSurival == "enduranceBinary") then
        if (tes3.mobilePlayer.endurance.current <= 0) then
            escaping = false
            tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
            return
        end
    end
    --[[ If Endurance - Percentage is enabled, generate a random number between 1 and 100,
        and check it against the player's endurance. ]]--
    if (config.attributeDependentSurival == "endurancePercentage") then
        if (math.random(100) > tes3.mobilePlayer.endurance.current) then
            escaping = false
            tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
            return
        end
    end
    -- if the option is enabled, simulate the vanilla death routine.
    if(config.deathAnimation == true) then
        perspective = tes3.is3rdPerson()
        tes3.mobilePlayer.controlsDisabled = true
        tes3.force3rdPerson()
        tes3.streamMusic({path = "Special\\MW_Death.mp3", crossfade = 0.2})
        tes3.playAnimation({
            reference = tes3.mobilePlayer,
            group = config.deathAnimations[math.random(5)],
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 1
        })
        timer.start({duration = 3, callback = endAnimate})
    else
        tes3.fadeOut({duration = 0.5})
        timer.start({duration = 0.5, callback = confirm})
    end
end

-- detect a killing blow on the player, and negate it. If not already escaping, start the escape process.
local function onDamage(e)
    if(e.mobile == tes3.mobilePlayer and config.enable) then
        local difficulty = tes3.getWorldController().difficulty
        local difficultyMult = tes3.findGMST(tes3.gmst.fDifficultyMult).value
        local difficultyFactor
        if(difficulty > 0) then
            difficultyFactor = 1 + difficultyMult * difficulty
        else
            difficultyFactor = 1 + difficulty / difficultyMult
        end -- If damage is from an attack, apply the difficulty modifier before checking to see if it would kill the player.
        if(e.source == "attack" and (tes3.mobilePlayer.health.current - math.abs(e.damage) * difficultyFactor) <= 1.1) then
            tes3.mobilePlayer.health.current = 1.1 + math.abs(e.damage) * difficultyFactor
            if (escaping ~= true) then
                escaping = true
                prepareEscape()
            end
        elseif (tes3.mobilePlayer.health.current - math.abs(e.damage) <= 1.1) then
            tes3.setStatistic({reference = tes3.mobilePlayer, name = "health", current = tes3.mobilePlayer.health.current + math.abs(e.damage)})
            if (escaping ~= true) then
                escaping = true
                prepareEscape()
            end
        end
    end
end

--[[Reset the variables upon loading, to prevent undesired behavior if the player
starts a new game or loads a game during the escape process.]]--
local function resetVariables()
    escaping = false
    perspective = nil
    quashSpellSound = false
    teleporting = false
    timeScale = nil
    tes3.fadeIn({duration = 0.01})
end

-- Register the events to be used in baseline behavior
local function initialized()
	event.register("equip", potionEquipOverride, {priority = 1e+06})
	event.register("equipped", potionEquipOverride, {priority = 1e+06})
    event.register("damage", onDamage, {priority = -100})
    event.register("save", blockSave)
    event.register("cellChanged", onCellChanged)
    event.register("onMagicCasted", spellSoundQuasher)
    event.register("loaded", resetVariables)
	print("[Timely Escape: INFO] Timely Escape Initialized")
end

-- register the initialized event
event.register("initialized", initialized)


--register our mod when mcm is ready for it
event.register("modConfigReady", function()
	require("TimelyEscape.mcm")
end)