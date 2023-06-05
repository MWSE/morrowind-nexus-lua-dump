local log = require("leeches.log")
local utils = require("leeches.utils")
local pathing = require("leeches.quests.pathing")

local function startTrailingSequence()
    local ref = utils.getReference("leech_npc_mondrar")
    if ref == nil then
        log:error("Failed to get Mondrar reference")
        return
    end

    -- Don't do greetings while pathing.
    ref.mobile.hello = 0

    pathing.startPathing({
        reference = ref.id,
        onTick = "trailingMondrar",
        onFinish = "trailingMondrarFinished",
        destinations = {
            -- labor town open area
            { -17685.00, -11950.00, 170.00 },
            -- just before the bridge
            { -18639.00, -12952.00, 182.00 },
            -- just after the bridge
            { -19966.00, -12971.00, 182.00 },
            -- north from the bridge
            { -19840.00, -11679.00, 160.00 },
            -- toward the stairs to temple area
            { -20542.00, -10891.00, 236.00 },
            -- right before the stairs to temple area
            { -20800.00, -10763.00, 232.00 },
            -- partly up the stairs
            { -21023.00, -11218.00, 371.00 },
            -- after the stairs
            { -21457.00, -11005.00, 488.00 },
            -- before the stairs to manor area
            { -23423.00, -10579.00, 718.00 },
            -- right before the cell border
            { -24545.00, -10570.00, 960.00 },
            -- other side of the cell border
            { -24625.00, -10499.00, 960.00 },
            -- near the sewers entrance
            { -26404.00, -10547.00, 960.00 },
            -- entrance to sewers
            { -26552.01, -10574.20, 962.00 },
        },
    })
end

---@param e journalEventData
event.register("journal", function(e)
    if e.topic.id == "leech_mq_01" and e.index == 75 then
        startTrailingSequence()
    end
end)

local voiceLines = {
    { "vo\\d\\m\\srv_dm033.mp3", "I find you foul and disgusting. Leave now." },
    { "vo\\d\\m\\hlo_dm037.mp3", "Annoying outlanders." },
    { "vo\\d\\m\\hlo_dm001.mp3", "Go away." },
    { "vo\\d\\m\\hlo_dm033.mp3", "Leave me." },
    { "vo\\d\\m\\srv_dm030.mp3", "Leave me, before you feel my dagger in your flesh!" },
}

--- Play the next voice line if enough time has passed since the previous.
---
--- Returns false if there were no more voice lines remaining.
---
---@param ref tes3reference
---@param time number
---@return boolean
local function playNextVoiceLine(ref, time)
    local data = table.getset(ref.data, "trailingMondrar", {})

    -- Play a voice line if enough time has passed since the previous.
    if (data.voiceTiming or 0) < time then
        local index = data.voiceIndex or 1
        local voiceLine = voiceLines[index]
        if voiceLine == nil then
            return false
        end

        local path, text = unpack(voiceLine)
        tes3.say({ reference = ref, soundPath = path, subtitle = text })

        -- Set the next voice line.
        data.voiceIndex = index + 1

        -- Set the next voice time.
        data.voiceTiming = time + 5
    end

    return true
end

pathing.registerCallback("trailingMondrar", function(timer, reference)
    local mobile = assert(reference.mobile)

    -- Stop moving while player is too close.
    --
    if mobile.isPlayerDetected and mobile.playerDistance < 512 then
        -- Stop traveling.
        local packageId = tes3.getCurrentAIPackageId({ reference = reference })
        if packageId ~= tes3.aiPackage.wander then
            tes3.setAIWander({ reference = reference, idles = { 0, 0, 0, 0, 0, 0, 0, 0 } })
        end

        -- Are we too close?
        if mobile.playerDistance < 256 then
            mobile.forceSneak = false

            -- Face toward player.
            local angle = mobile:getViewToActor(tes3.mobilePlayer) ---@diagnostic disable-line
            reference.facing = reference.facing + math.rad(math.clamp(angle, -90, 90))

            -- Play a voice line.
            local success = playNextVoiceLine(reference, timer.timing)

            -- Out of voice lines? Start combat.
            -- TODO: Trigger appropriate journal.
            if success == false then
                mobile.forceSneak = false
                mobile:startCombat(tes3.mobilePlayer) ---@diagnostic disable-line
                timer:cancel()
            end
        end

        return false
    end

    -- Start sneaking toward the end.
    --
    if #timer.data.destinations < 5 then
        if mobile.isSneaking ~= true then
            mobile.forceSneak = true
            tes3.playAnimation({ reference = reference, group = tes3.animationGroup.idle3, loopCount = 0 })
        end
    end
end)

pathing.registerCallback("trailingMondrarFinished", function(timer, reference)
    tes3.positionCell({
        reference = reference,
        position = { -1575.00, 236.00, 5.00 },
        cell = "Balmora, Western Sewer Canal",
    })

    tes3.playSound({
        reference = tes3.player,
        sound = "Door Metal Open",
        volume = 0.6,
    })

    tes3.updateJournal({
        id = "leech_mq_01",
        index = 80,
        showMessage = true,
    })
end)
