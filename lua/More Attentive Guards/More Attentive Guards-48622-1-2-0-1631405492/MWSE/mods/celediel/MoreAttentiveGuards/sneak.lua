local common = require("celediel.MoreAttentiveGuards.common")
local config = require("celediel.MoreAttentiveGuards.config").getConfig()
local interop = require("celediel.MoreAttentiveGuards.interop")
local this = {}

-- {{{ variables and such
-- only one guard following at a time makes sense
-- other guards are like "oh they've got this, I don't need to help"
local follower
local followTimer
local dialogueTimer
local isFollowing = false
local ogPosition
-- }}}

-- {{{ helper functions

local function log(...) if config.debug then common.log(...) end end

local function calculateFollowTime()
    -- Modified formula from RubberMan's "Inquisitive Guards"
    -- https://www.nexusmods.com/morrowind/mods/46538
    local sneak = tes3.mobilePlayer.sneak.value and tes3.mobilePlayer.sneak.value or tes3.mobilePlayer.sneak.base
    -- if player sneak is 100 or greater, guards won't follow at all
    local max = tes3.hasCodePatchFeature(110) and (sneak <= 100 and 101 or 0) or 101
    local value = (max - sneak) / 3
    -- clamp to positive
    return math.clamp(value, 0, math.huge)
end

local function doChecks(e)
    if not config.sneakEnable then return false end
    if not e.target.isSneaking then return false end
    if not e.detector.object.isGuard then return false end
    if e.target ~= tes3.mobilePlayer then return false end

    -- don't bother following in outside wilderness cells
    if not tes3.player.cell.restingIsIllegal then return false end

    if e.detector.inCombat then
        log("Busy with combat, not following...")
        return false
    end

    -- all good
    return true
end

-- }}}

-- {{{ timer functions

local function startDialogue(chance)
    if not follower then return end

    local roll = type(chance) == "number" and chance or math.random(0, 100)

    log("Dialogue roll = %s > %s == %s", config.sneakDialogueChance, roll, config.sneakDialogueChance > roll)
    if config.sneakDialogueChance > roll then
        if config.sneakDialogue == common.dialogueMode.text then
            local response = common.playGuardText(follower.object.name, table.choice(common.dialogues.text[config.language].sneaking),
                                                  tes3.mobilePlayer)
            log(response)
        elseif config.sneakDialogue == common.dialogueMode.voice then
            local response = common.playGuardVoice(follower, "sneaking")
            log("Playing sound file %s because sneaking", response)
        end
    end
end

-- * NPC travels back to where they were before following player, then wanders
-- * tries to guess how long it'll take NPC to get back to their original position
local function stopFollowing(onTimer)
    if not follower or not isFollowing then return end
    isFollowing = false

    local function startWander()
        local wanderRange = common.generateWanderRange(tes3.getPlayerCell())
        local idles = common.generateIdles()

        log("%s has probably reached their original destination, resuming %s range wander...", follower.object.name, wanderRange)
        tes3.setAIWander({ reference = follower, range = wanderRange, reset = true, idles = idles })

        follower = nil
        interop.setGuardFollower(follower)
    end

    local function startTravel()
        -- I couldn't think of a better way to "know" when they've reach their destination
        -- so I set a timer based on the distance from the original position. It's okay-ish.
        local distance = ogPosition:distance(follower.position)
        local duration = math.ceil(distance / 95)

        -- duration of 0 is bad for timers, so
        duration = duration > 0 and duration or 1

        log("%s has decided that %s isn't doing anything suspicious, heading back to %s... " ..
                "(which is %s distance units away... it'll probably take %s seconds to get there)", follower.object.name,
            tes3.player.object.name, ogPosition, distance, duration)

        -- send a dialogue to let player know guard doesn't care any more
        if onTimer then
            if config.sneakDialogue == common.dialogueMode.text then
                local response = common.playGuardText(follower.object.name, table.choice(common.dialogues[config.language].stop_following),
                                                      tes3.mobilePlayer)
                log(response)
            elseif config.sneakDialogue == common.dialogueMode.voice then
                local response = common.playGuardVoice(follower, "stop_following")
                log("Playing sound file %s because stop_following", response)
            end
        end

        if dialogueTimer and dialogueTimer.state == timer.active then dialogueTimer:cancel() end

        tes3.setAITravel({ reference = follower, destination = ogPosition })
        ogPosition = nil

        timer.start({ duration = duration, iterations = 1, callback = startWander })
    end

    timer.delayOneFrame(startTravel)
end

local function startFollowing()
    if not follower or isFollowing then return end

    local function startFollow()
        local followTime = calculateFollowTime()
        if followTime <= 0 then return end
        log("%s starting to follow %s for %s time units", follower.object.name, tes3.player.object.name, followTime)

        tes3.setAIFollow({ reference = follower, target = tes3.mobilePlayer })

        followTimer = timer.start({ duration = followTime, callback = stopFollowing })

        if config.sneakDialogue ~= common.dialogueMode.none then
            startDialogue(0) -- always say something the first time
            dialogueTimer = timer.start({ duration = config.sneakDialogueTimer, iterations = -1, callback = startDialogue })
        end

        isFollowing = true
    end

    ogPosition = follower.position:copy()

    timer.delayOneFrame(startFollow)
end

local function abortFollow()
    -- send a dialogue to let player know guard doesn't care any more
    if config.sneakDialogue == common.dialogueMode.text then
        local response = common.playGuardText(follower.object.name, table.choice(common.dialogues.text[config.language].stop_sneaking),
                                              tes3.mobilePlayer)
        log(response)
    elseif config.sneakDialogue == common.dialogueMode.voice then
        local response = common.playGuardVoice(follower, "stop_sneaking")
        log("Playing sound file %s because stop_sneaking", response)
    end
    stopFollowing(false)
end

-- }}}

-- {{{ returned event functions

this.onDetectSneak = function(e)
    if not doChecks(e) then return end

    if not isFollowing then
        log("%s is checking for %s %ssuccessfully", e.detector.object and e.detector.object.name or "no one",
            e.target.object and e.target.object.name or "no one", e.isDetected and "" or "un")
    end

    if e.isDetected and not follower and not isFollowing then
        follower = e.detector
        interop.setGuardFollower(follower)
        -- follow for a time
        startFollowing()
        -- else -- uncomment this for extreme debug messages
        --     log("Not following because detection = %s or follower = %s or isFollowing = %s", e.isDetected, follower,
        --         isFollowing)
    end
end

this.onCalcMoveSpeed = function(e)
    if e.mobile ~= tes3.mobilePlayer or tes3.mobilePlayer.isSneaking then return end

    if follower and followTimer and followTimer.state == timer.active then
        log("Player not sneaking, aborting follow")

        followTimer:cancel()
        abortFollow()
    end
end

this.onLoaded = function(e)
    -- some clean-up
    follower = nil
    followTimer = nil
    dialogueTimer = nil
    ogPosition = nil
    isFollowing = false
    interop.setGuardFollower(follower)
end

-- }}}

return this

-- vim: fdm=marker
