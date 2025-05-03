---Class BardicInspiration.SongController
local SongController = {}
local Song = require("mer.bardicInspiration.Song")
local common = require("mer.bardicInspiration.common")
local messages = require("mer.bardicInspiration.messages.messages")

function SongController.showMenu()
    --delay a frame so it triggers outside menuMode
    timer.delayOneFrame(function()
        local buttons = {}
        --add songs
        for _, song in ipairs(SongController.getKnownSongs({ sort = true, reverse = true})) do
            table.insert(buttons, {
                text = song.name,
                callback = function()
                    common.log:debug("Performing: %s", song.name)
                    song:perform()
                end,
                tooltip = {
                    header = song.name,
                    text = string.format(messages.songTooltip,
                        messages["difficulty_" .. song.difficulty],
                        song.timesPlayed,
                        song.taughtBy or ""
                    )
                }
            })
        end

        tes3ui.showMessageMenu{
            message = messages.whatToPlay,
            buttons = buttons,
            cancels = true,
            pageSize = 10
        }
    end)
end

function SongController.getKnownSongs(e)
    e = e or { sort = false, reverse = false}
    if not tes3.player then return end
    common.log:debug("getKnownSongs()")
    local songs = {}
    for _, songData in ipairs(common.data.knownSongs) do
        common.log:trace("getting song %s", songData.name)
        if lfs.attributes("Data Files/Music/" .. songData.path) then
            table.insert(songs, Song:new(songData))
        else
            common.log:debug("Cannot find 'Music/%s'", songData.path)
        end
    end
    if e.sort then
        SongController.sortSongListByDifficulty({ list = songs, reverse = e.reverse })
    end
    return songs
end



function SongController.sortSongListByDifficulty(e)
    local function difficultySort(songA, songB)
        local sorter = {
            beginner = 1,
            intermediate = 2,
            advanced = 3
        }
        if sorter[songA.difficulty] == sorter[songB.difficulty] then
            return common.songSorter(songA, songB)
        end

        if e.reverse then
            return sorter[songA.difficulty]>sorter[songB.difficulty]
        else
            return sorter[songA.difficulty]<sorter[songB.difficulty]
        end
    end
    table.sort(e.list, difficultySort)
end

function SongController.learnSong(songData)
    assert(type(songData.name) == "string")
    assert(type(songData.path) == "string")
    assert(common.staticData.difficulties[songData.difficulty])
    songData.timesPlayed = 0
    --common.data.knownSongs[songData.name] = songData
    table.insert(common.data.knownSongs, songData)
end

function SongController.getPlayerSong(songName)
    for _, songData in ipairs(common.data.knownSongs) do
        if songData.name == songName then
            return songData
        end
    end
end

function SongController.playRandom()
    common.log:debug("playRandom()")
    local knownSongs = SongController.getKnownSongs()
    if #knownSongs == 0 then
        tes3.messageBox(messages.noSongsKnown)
    else
        ---@type BardicInspiration.Song
        local song = table.choice(knownSongs)
        if song then
            common.log:debug("Playing random song %s", song.name)
            song:play()
        end
    end
end

return SongController