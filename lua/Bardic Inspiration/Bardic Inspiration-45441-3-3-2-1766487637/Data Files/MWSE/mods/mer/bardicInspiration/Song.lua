--[[
    An object representing a song that can be played on a lute.
    Includes functions for performing songs in a tavern or playing
    them to get a passive buff.
]]
local common = require("mer.bardicInspiration.common")
local animate = require("mer.bardicInspiration.controllers.animationController")
local tips = require("mer.bardicInspiration.controllers.tipsController")
local messages = require("mer.bardicInspiration.messages.messages")
local performances = require("mer.bardicInspiration.data.performances")
local journal = require("mer.bardicInspiration.controllers.journalController")


---@class BardicInspiration.Song.constructorParams
---@field name string
---@field path string
---@field difficulty string

---@class BardicInspiration.Song : BardicInspiration.Song.constructorParams
local Song = {
    buffId = "bardic_inspiration_self"
}

---@class BardicInspiration.Song.data
---@field name string
---@field path string
---@field difficulty string

--Constructor
---@param songData BardicInspiration.Song.data
---@return BardicInspiration.Song
function Song:new(songData)
    local song = table.copy(songData)
    assert(type(song.name) == "string")
    assert(type(song.path) == "string")
    assert(common.staticData.difficulties[song.difficulty])
    setmetatable(song, self)
    self.__index = self
    return song
end

local function blockEquip()
    return false
end

---@param e musicChangeTrackEventData | nil
local function endPerformance(e)
    e = e or {}

    if not common.data.songPlaying then return end
    if e.context == "mwscript" then
        common.log:info("MwScript streamMusic attemtped while performing. Blocking.")
        e.block = true
        return
    end

    common.log:debug("Ending performance")
    common.restoreMusic()
    --unregister our events
    event.unregister("equip", blockEquip)
    event.unregister("musicChangeTrack", endPerformance)
    timer.delayOneFrame(function()
        --Set status to played
        local currentPerformance = performances.getCurrent()
        if not currentPerformance then
            common.log:debug("Ended a performance when none was scheduled.")
            animate.stop()
        else
            common.log:debug("Ending performance, setting state to PLAYED")
            currentPerformance.state = performances.STATE.SKIP
            animate.stop()
            currentPerformance.state = performances.STATE.PLAYED
                    --Enable controls and congratulate player

            local tipsTotal = tips:getTotal()
            tips:stop()
            local message
            if tipsTotal > 0 then
                message = string.format(messages.donePerforming,
                    tipsTotal, currentPerformance.publicanName
                )
            else
                message = string.format(messages.donePerformingNoTips,
                    currentPerformance.publicanName
                )
            end
            tes3.messageBox{
                message = message,
                buttons = { "Okay" }
            }
            journal.completedGig(tipsTotal)
            common.data.songPlaying.timesPlayed = common.data.songPlaying.timesPlayed + 1
        end
        common.data.songPlaying = nil
    end)
end

--Perform at a tavern, earn gold
function Song:perform()
    animate.play()
    tips:start()
    common.data.currentSongDifficulty = self.difficulty

    for _, songData in ipairs(common.data.knownSongs) do
        if songData.name == self.name then
            common.data.songPlaying = songData
        end
    end
    --tes3.fadeOut{ duration = 5 }
    --Start playing music
    common.playMusic{ path = self.path }

    --Ends performance when the song ends (and another track is selected):

    event.register("musicChangeTrack", endPerformance, { priority = 1000 })
    event.register("BardicInspiration:EndPerformance", endPerformance)
    event.register("equip", blockEquip, { priority = 1000 } )
end

--Play while travelling, gives Inspiration buff
function Song:play()
    local endPlay
    local function checkCell(e)
        if e.cell.isInterior and not e.cell.behavesAsExterior then
            endPlay()
        end
    end
    endPlay = function(e)
        e = e or {}
        common.log:debug("Ending play music")
        if e.reference and e.reference ~= tes3.player then
            common.log:debug("%s is equipping, not the player", e.reference)
            return
        end
        if e.item and e.item.objectType ~= tes3.objectType.weapon then
            common.log:debug("%s is not a weapon", e.item.id)
            return
        end
        event.unregister("musicChangeTrack", endPlay, { priority = 1000 } )
        event.unregister("equip", endPlay )
        event.unregister("unequipped", endPlay )
        event.unregister("cellChanged", checkCell)
        event.unregister("weaponUnreadied", endPlay )
        common.data.travelPlay = nil
        common.log:debug("Stop music--")
        common.stopMusic()
        common.log:debug("Removing buff-------")
        tes3.removeSpell{ reference = tes3.player, spell = self.buffId }

    end
    common.log:debug("playing song at path %s", self.path)
    tes3.messageBox(messages.playingSong, self.name)
    common.playMusic{ path = self.path, crossfade = 0.2 }
    common.data.travelPlay = true
    tes3.addSpell{ reference = tes3.player, spell = self.buffId }
    -- for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
    --     mwscript.addSpell{ reference = actor, spell = self.buffId }
    -- end
    event.register("musicChangeTrack", endPlay, { priority = 1000 } )
    event.register("equip", endPlay, { priority = 1000 }  )
    event.register("unequipped", endPlay, { priority = 1000 }  )
    event.register("cellChanged", checkCell, { priority = 1000 } )
    event.register("weaponUnreadied", endPlay, { priority = 1000 }  )
end



local function clearOnLoad()
    event.unregister("equip", blockEquip)
    event.unregister("musicChangeTrack", endPerformance)

    --Clear on load

    if common.data.songPlaying then
        endPerformance()
    end
end
event.register("BardicInspiration:DataLoaded", clearOnLoad)

return Song