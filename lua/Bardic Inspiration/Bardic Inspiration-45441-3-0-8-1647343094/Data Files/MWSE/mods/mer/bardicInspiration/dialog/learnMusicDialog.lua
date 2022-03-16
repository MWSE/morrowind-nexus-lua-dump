local common = require("mer.bardicInspiration.common")
local songList = require("mer.bardicInspiration.data.songList")
local infos = common.staticData.dialogueEntries
local messages = require("mer.bardicInspiration.messages.messages")
local songController = require("mer.bardicInspiration.controllers.songController")
local currentBard

--Helpers

local function getHoursPassed()
    return ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value
end

local function knowsSong(song)
    for _, knownSong in ipairs(common.data.knownSongs) do
        if song.name == knownSong.name then
            return true
        end
    end
    return false
end

local function getPlayerDifficultyLevel()
    local difficultyOrder = { "intermediate", "advanced"}
    local playerSkill = common.skills.performance.value
    local playerDifficultyLevel = "beginner"
    for _, diffId in ipairs(difficultyOrder) do
        local difficulty = common.staticData.difficulties[diffId]
        local minSkill = difficulty.minSkill
        if playerSkill >= minSkill then
            playerDifficultyLevel = diffId
        end
    end
    return playerDifficultyLevel
end

local function hasSkillsToLearn(song)
    local minSkill = common.staticData.difficulties[song.difficulty].minSkill
    local playerSkill = common.skills.performance.value
    local isSkilledEnough = playerSkill >= minSkill
    return isSkilledEnough
end

local function canLearnSong(song)
    return song
        and hasSkillsToLearn(song)
        and not knowsSong(song)
end



--[[
    Add a random set of songs from each difficulty to a bard's repertiore
]]
local function addSongsToBard(bard)
    common.log:debug("Adding songs to %s", bard.object.name)
    local data = bard.data.mer_bardicInspiration
    for difficulty, diffConf in pairs(common.staticData.difficulties) do
        local shuffledSongs = common.shuffle(table.copy(songList[difficulty]))
        for _ = 1, diffConf.songsPerBard do
            if #shuffledSongs > 0 then
                local song = table.remove(shuffledSongs)
                table.insert(data.songs, song)
                common.log:debug("Added %s song: %s", difficulty, song.name)
            end
        end
    end
end


--[[
    Initialise the data on a bard reference
]]
local function initBardData(bard)
    bard.data.mer_bardicInspiration = bard.data.mer_bardicInspiration or {
        songs = {},
    }
    if #bard.data.mer_bardicInspiration.songs == 0 then
        addSongsToBard(bard)
    end
end

--[[
    metafunctions for accessing data on bard reference
]]
local function getBardData(bard)
    if not common.isBard(bard) then return end
    local data = setmetatable({}, {
        __index = function(_, key)
            if bard then
                initBardData(bard)
                return bard.data.mer_bardicInspiration[key]
            end
        end,
        __newindex = function(_, key, value)
            if bard then
                initBardData(bard)
                bard.data.mer_bardicInspiration[key] = value
            end
        end
    })
    return data
end

local function bardReadyToTeach(bard)
    -- local now = getHoursPassed()
    -- local data = getBardData(bard)
    -- if data then
    --     local timeLastTaughtHour = data.timeLastTaughtHour or -1000
    --     local interval = common.staticData.bardTeachIntervalHours

    --     return timeLastTaughtHour + interval < now
    -- end
    -- return false

    local data = getBardData(bard)
    if data then
        local playerSong = songController.getPlayerSong(data.lastTaughtSongName)
        if playerSong then
            common.log:debug(playerSong)
            if playerSong.timesPlayed >= common.staticData.bardTeachSongPlayedMin then
                return true
            end
            return false
        end
        return true
    end
    return true
end


local function getSongFromBard(bard)
    if not bard then return end
    local bardData = getBardData(bard)

    if canLearnSong(bardData.currentSong) then
        return bardData.currentSong
    else
        --sort from most to least difficult
        songController.sortSongListByDifficulty{list = bardData.songs, reverse = true}
        local currentSong
        for _, song in ipairs(bardData.songs) do
            if canLearnSong(song) then
                common.log:debug("Bard will now teach %s", song.name)
                song.taughtBy = bard.object.name
                currentSong = song
                break
            end
        end
        return currentSong
    end
end

--Infos
local function infoTeachConfirm(e)
    if e.passes ~= false then
        timer.delayOneFrame(function()
            local song = getSongFromBard(currentBard)
            if song then
                common.playMusic{ path = song.path}
                common.fadeTimeOut{
                    hoursPassed = 0.25,
                    secondsTaken = 10,
                    callback = function()
                        common.stopMusic{ crossfade = 3.0 }
                        timer.start{
                            duration = 1,
                            type = timer.real,
                            iterations = 1,
                            callback = function()
                                local msg = string.format(messages.learnedSong, song.name)
                                tes3.messageBox{
                                    message = msg,
                                    buttons = { tes3.findGMST(tes3.gmst.sOK).value }
                                }
                                getBardData(currentBard).timeLastTaughtHour = getHoursPassed()
                                getBardData(currentBard).lastTaughtSongName = song.name
                                songController.learnSong(song)
                            end
                        }

                    end
                }
            end
        end)
    end
end
event.register("infoGetText", infoTeachConfirm, {filter = tes3.getDialogueInfo(infos.teachConfirm) })

local function infoTeachChoice(e)
    if e.passes ~= false then
        local playerDifficultyLevel = getPlayerDifficultyLevel()


        local songToLearn = getSongFromBard(currentBard)
        if songToLearn then
            getBardData(currentBard).currentSong = songToLearn
            local message
            local difficultyMsg = messages['difficulty_' .. songToLearn.difficulty]:lower()
            local playerDifficultyMsg = messages["difficulty_" .. playerDifficultyLevel]:lower()
            if songToLearn.difficulty ~= playerDifficultyLevel then
                --Bard has a song to teach but it is beneath the player's level
                message = messages.dialog_teachChoice_lesser
                e.text = string.format(message, playerDifficultyMsg, difficultyMsg, songToLearn.name)
            elseif playerDifficultyLevel == "advanced" then
                --Bard has an advanced song to teach
                message = messages.dialog_teachChoice_advanced
                e.text = string.format(message, tes3.player.object.name, songToLearn.name)
            else
                --Bard has a song matching the player's level, not advanced
                message = messages.dialog_teachChoice
                e.text = string.format(message, difficultyMsg, songToLearn.name)
            end

        else
            common.log:debug("infoTeachChoice(): No song to learn")
        end
    end
end
event.register("infoGetText", infoTeachChoice, {filter = tes3.getDialogueInfo(infos.teachChoice) })



--Filters
local function filterNoTeachMustWait(e)
    if not common.isBard(e.reference) then return end
    common.log:debug("---filterNoTeachMustWait")
    currentBard = e.reference
    if bardReadyToTeach(currentBard) then
        e.passes = false
    end
end
event.register("infoFilter", filterNoTeachMustWait, { filter = tes3.getDialogueInfo(infos.noTeachMustWait)})


local function filterTeachChoice(e)
    if not common.isBard(e.reference) then return end
    common.log:debug("---filterTeachChoice")
    currentBard = e.reference
    local songToLearn = getSongFromBard(currentBard)
    if songToLearn and hasSkillsToLearn(songToLearn) and not knowsSong(songToLearn) then
        --passes based on vanilla filters
    else --
        e.passes = false
    end
end
event.register("infoFilter", filterTeachChoice, { filter = tes3.getDialogueInfo(infos.teachChoice)})


local function filterNoTeachLowSkill(e)
    if not common.isBard(e.reference) then return end
    common.log:debug("---filterNoTeachLowSkill")
    currentBard = e.reference
    local songToLearn = getSongFromBard(currentBard)
    if songToLearn then
        --passes based on vanilla filters
    else --
        e.passes = false
    end
end
event.register("infoFilter", filterNoTeachLowSkill, { filter = tes3.getDialogueInfo(infos.noTeachLowSkill)})

local function filterNoTeachNoSongs(e)
    if not common.isBard(e.reference) then return end
    common.log:debug("---filterNoTeachNoSongs")
    currentBard = e.reference
    local songToLearn = getSongFromBard(currentBard)
    if songToLearn and not knowsSong(songToLearn) then
        e.passes = false
    end
end
event.register("infoFilter", filterNoTeachNoSongs, { filter = tes3.getDialogueInfo(infos.noTeachNoSongs)})

--Adds class filters to all dialogs
for _, infoData in pairs(infos) do
    if infoData.classFilter then
        event.register("infoFilter", function(e)
            local passes = false
            if infoData.classFilter == "bard" and common.isBard(e.reference) then
                common.log:debug("Is a bard!")
                passes = true
            elseif infoData.classFilter == "publican" and common.isInnkeeper(e.reference) then
                common.log:debug("Is an innkeeper!")
                passes = true
            end
            if not passes then
                e.passes = false
            end
        end, { filter = tes3.getDialogueInfo(infoData)})
    end
end

