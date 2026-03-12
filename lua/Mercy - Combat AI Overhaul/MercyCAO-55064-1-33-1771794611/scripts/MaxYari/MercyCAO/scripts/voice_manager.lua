-- All available vanilla dialog voice record types:
-- Alarm
-- Attack
-- Flee
-- Hello
-- Hit
-- Idle
-- Intruder
-- Thief

local gutils = require(mp .. "scripts/gutils")
local customVoiceRecords = require(mp .. "scripts/custom_voice_records")

local types = require("openmw.types")
local core = require("openmw.core")
local omwself = require("openmw.self")
local storage = require("openmw.storage")

local soundSettings = storage.globalSection('MercyCAOAudioSettings')
local useAIVoicelines = soundSettings:get("AIVoicelines")
local showSubtitles = soundSettings:get("ShowSubtitles")

local module = {}

local addVoiceRecords = function(records)
    for combatState, recs in pairs(records) do
        for _, record in ipairs(recs) do
            table.insert(customVoiceRecords[combatState], record)
        end
    end
end

module.addVoiceRecords = addVoiceRecords

local function noSpecificFilters(info)
    -- I probably can check the disposition as well for the "filterActorDisposition"
    local specificFilters = { "filterActorClass", "filterActorFaction", "filterPlayerCell", "filterPlayerFaction",
        "isQuestFinished", "isQuestName", "isQuestRestart", "questStage" }
    local noFilters = true
    for _, filter in ipairs(specificFilters) do
        if info[filter] then
            noFilters = false
            break
        end
    end
    return noFilters
end

local function beastCheck(info, isBeast)
    -- Author: Mostly ChatGPT 2024
    local fileName = info.sound:match("[^/]+$")
    return isBeast or not fileName:match("^b")
end

local function vampireCheck(info, isVampire)
    return isVampire or not string.find(info.sound,"/vo/v/")
end

local function findRelevantInfos(recordType, race, gender, isBeast, isVampire)
    local fittingInfos = {}
    local records = core.dialogue.voice.records[recordType]
    if not records then return fittingInfos end

    --print("Looking for ", recordType, " voice record type")

    for _, voiceInfo in pairs(records.infos) do
        -- Need to also filter by enemy race and also accept those that are nil?
        -- TO DO: Probably should not check for omwself here in the future. This function kind of suppose to work on any actor, not only on self. For now it works only on self anyway though.
        if voiceInfo.sound and voiceInfo.filterActorRace == race and voiceInfo.filterActorGender == gender and (not voiceInfo.filterActorId or voiceInfo.filterActorId == omwself.recordId) and noSpecificFilters(voiceInfo) and beastCheck(voiceInfo, isBeast) and vampireCheck(voiceInfo, isVampire) then
            --print(gutils.dialogRecordInfoToString(voiceInfo))
            table.insert(fittingInfos, voiceInfo)
        end
    end

    return fittingInfos
end

local lastPickedIndices = {}


local function say(actor, targetActor, recordType, force)
    if not actor then
        error("Say was called without an actor")
    end

    local wActor = gutils.Actor:new(actor)

    local race = nil
    local gender = nil
    local isBeast = false
    local isVampire = false
    local targetGender = nil

    if types.NPC.objectIsInstance(actor) then
        local npc = types.NPC.record(actor)
        if npc.isMale then
            gender = "male"
        else
            gender = "female"
        end
        race = npc.race
        isBeast = types.NPC.isWerewolf(actor)
        isVampire = wActor:isVampire()
    end

    if targetActor and types.NPC.objectIsInstance(targetActor) then
        if not types.NPC.record(targetActor).isMale then
            targetGender = "female"
        else
            targetGender = "male"
        end
    end

    if not types.NPC.objectIsInstance(actor) or types.Actor.isDead(actor) then return false end
    if not force and core.sound.isSayActive(actor) then return false end


    local fittingInfos = {}
    if useAIVoicelines then
        fittingInfos = customVoiceRecords.findRelevantInfos(recordType, race, gender, isBeast, isVampire)
    end
    if #fittingInfos == 0 then fittingInfos = findRelevantInfos(recordType, race, gender, isBeast, isVampire) end

    -- Pick random voice file ensuring that same line doesnt repeat twice
    -- print("Fitting amount of voicelines: ", #fittingInfos)
    local lastPickedIndex = lastPickedIndices[recordType]
    local availableIndices = {}
    for i, info in ipairs(fittingInfos) do
        if info.targetGender and info.targetGender ~= targetGender then goto continue end
        if i == lastPickedIndex and #fittingInfos > 1 then goto continue end

        table.insert(availableIndices, i)
        ::continue::
    end

    if #availableIndices == 0 then
        gutils.print(
            "WARNING: No voice records of type " ..
            recordType ..
            " were found to fit " .. tostring(race) .. " " .. tostring(gender) .. " character.", 1)
        -- Not saying is not that bad, just ignore it
        return false
    end

    -- Do something if available
    local pickedIndex = availableIndices[math.random(1, #availableIndices)]
    lastPickedIndices[recordType] = pickedIndex

    local voiceInfo = fittingInfos[pickedIndex]


    -- Finally say it!
    --print("Voiceline to use: ", voiceInfo.sound, voiceInfo.text, tostring(voiceInfo.filterActorId),voiceInfo.id)
    -- core.sound.say(voiceInfo.sound, actor, voiceInfo.text)
    -- say doesnt respect the subtitle setting for some reason, so rather force no subtitles here, since most of the voice lines have none anyway.
    if showSubtitles and voiceInfo.text and voiceInfo.text ~= "" then
        core.sound.say(voiceInfo.sound, actor, voiceInfo.text)
    else
        core.sound.say(voiceInfo.sound, actor)
    end
    return true
end

module.say = say

return module
