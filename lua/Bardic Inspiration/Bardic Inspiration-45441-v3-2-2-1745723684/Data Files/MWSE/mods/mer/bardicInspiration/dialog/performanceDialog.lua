local common = require("mer.bardicInspiration.common")
local reward = require("mer.bardicInspiration.controllers.rewardController")
local performances = require("mer.bardicInspiration.data.performances")
local messages = require("mer.bardicInspiration.messages.messages")
local Publican = require("mer.bardicInspiration.data.publican")
local journal = require("mer.bardicInspiration.controllers.journalController")
--Configs--------------------------------------------------------
local STATE = performances.STATE
local infos = common.staticData.dialogueEntries
--Dialog event handlers-----------------------------------

--INFOS---------------------

-- local function infoGetReward(e)
--     common.log:trace("---infoGetReward - reward and reset")
--     local thisPerformance = performances.getCurrent()
--     local amount = thisPerformance.reward
--     reward.give(amount)
--     reward.raiseDisposition{ actorId = thisPerformance.publicanId, rewardAmount = amount }
--     performances.clearCurrent()
-- end
-- event.register("infoGetText", infoGetReward, {filter = tes3.getDialogueInfo(infos.hasPlayed) })





---@param e infoGetTextEventData
local function infoGetReward(e)
    common.log:trace("---infoGetReward - reward and reset")
    local thisPerformance = performances.getCurrent()
    if not thisPerformance then return end
    local amount = thisPerformance.reward
    reward.give(amount)
    reward.raiseDisposition{ actorId = thisPerformance.publicanId, rewardAmount = amount }
    journal.gotPaid(amount)
    performances.clearCurrent()
end
event.register("infoGetText", infoGetReward, {filter = tes3.getDialogueInfo(infos.hasPlayed) })


---@param e infoGetTextEventData
local function showDoAccept(e)--Schedule a performance
    local currentPublican = Publican.get()
    if not currentPublican then
        common.log:warn("No current publican, blocking")
        return
    end

    common.log:trace("passes, setting performance data")
    performances.add{
        day = tes3.worldController.daysPassed.value,
        state = STATE.SCHEDULED,
        reward = reward.get(),
        publicanId = currentPublican.object.id,
        publicanName = currentPublican.object.name,
    }
    journal.scheduleGig()
end
event.register("infoGetText", showDoAccept, { filter = tes3.getDialogueInfo(infos.doAccept) } )

local function showNoSongs(e)
    common.log:debug("---showNoSongs")
    -- If there is a bard in the cell, the publican will point them out to you.
    for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
        common.log:debug("ref: %s", ref.id)
        common.log:debug("ref class: %s", ref.object.class)
        if common.isBard(ref) and not ref.disabled then
            common.log:debug("found bard")
            local message = ref.object.female
                and messages.dialog_NoSongsBardFemale
                or messages.dialog_NoSongsBardMale
            e.text = string.format(message, ref.object.name)
        end
    end
end
event.register("infoGetText", showNoSongs, { filter = tes3.getDialogueInfo(infos.noSongs) } )

---FILTERS-----------------

local function filterHasPlayed(e)--"Thanks for playing! Here's your payment"
    common.log:trace("---filterHasPlayed")

    if not common.isInnkeeper(e.reference) then
        e.passes = false
    end

    local thisPerformance = performances.getCurrent()
    if not thisPerformance then
        common.log:trace("No performance here, blocking")
        e.passes = false
        return
    end
    local hasPlayedAlready = thisPerformance.state == STATE.PLAYED
    if not hasPlayedAlready then
        common.log:trace("Hasn't played yet, blocking")
        e.passes = false
    end
end
event.register("infoFilter", filterHasPlayed, { filter = tes3.getDialogueInfo(infos.hasPlayed) })

local function filterHasAccepted(e)
    common.log:trace("---filterHasAccepted")

    if not common.isInnkeeper(e.reference) then
        e.passes = false
    end

    local thisPerformance = performances.getCurrent()

    local isScheduled = thisPerformance and thisPerformance.state == STATE.SCHEDULED
    if not isScheduled then
        common.log:trace("State is not scheduled, blocking event")
        e.passes = false
        return
    end

    local isToday = thisPerformance and thisPerformance.day == tes3.worldController.daysPassed.value
    if not isToday then
        common.log:trace("Performance is not today, blocking event")
        e.passes = false
        return
    end
end
event.register("infoFilter", filterHasAccepted, { filter = tes3.getDialogueInfo(infos.hasAccepted) })


local function filterDescribeGig(e)
    common.log:trace("---filterDescribeGig")

    if not common.isInnkeeper(e.reference) then
        e.passes = false
    end

    reward.calculate(e.reference.object)
    Publican.set(e.reference)
end
event.register("infoFilter", filterDescribeGig, { filter = tes3.getDialogueInfo(infos.describeGig)})


local function filterAskToPerform(e)
    common.log:trace("---filterAskToPerform")

    if not common.isInnkeeper(e.reference) then
        e.passes = false
    end

    if #common.data.knownSongs == 0 or not common.hasLute() then
        common.log:trace("No lute, blocking")
        e.passes = false
    end
end
event.register("infoFilter", filterAskToPerform, { filter = tes3.getDialogueInfo(infos.askToPerform)})

local function filterTooLate(e)
    common.log:trace("---filterTooLate")

    if not common.isInnkeeper(e.reference) then
        e.passes = false
    end

    if #common.data.knownSongs == 0 or not common.hasLute() then
        common.log:trace("No lute or songs, blocking")
        e.passes = false
    end
end
event.register("infoFilter", filterTooLate, { filter = tes3.getDialogueInfo(infos.tooLate)})



local function filterNoLute(e)
    common.log:trace("---filterNoLute")

    if not common.isInnkeeper(e.reference) then
        common.log:trace("Not an innkeeper, blocking")
        e.passes = false
    end

    if common.hasLute() then
        common.log:trace("No lute, blocking")
        e.passes = false
    end
end
event.register("infoFilter", filterNoLute, { filter = tes3.getDialogueInfo(infos.noLute)})

local function filterGiveLute(e)
    common.log:trace("---filterGiveLute")

    if common.hasGivenLute() then
        common.log:trace("Already given lute, blocking")
        e.passes = false
    end

    if not common.isInnkeeper(e.reference) then
        common.log:trace("Not an innkeeper, blocking")
        e.passes = false
    end

    if not common.getOwnedLuteInCell(e.reference) then
        common.log:trace("Publican doesn't have owned lute, blocking")
        e.passes = false
    end

    if common.hasLute() then
        common.log:trace("Player already has lute, blocking")
        e.passes = false
    end
end
event.register("infoFilter", filterGiveLute, { filter = tes3.getDialogueInfo(infos.innkeeperGivesLute)})

local function filterNoSongs(e)
    common.log:trace("---filterNoSongs")

    if not common.isInnkeeper(e.reference) then
        e.passes = false
    end
end
event.register("infoFilter", filterNoSongs, { filter = tes3.getDialogueInfo(infos.noSongs)})


