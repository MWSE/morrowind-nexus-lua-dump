require("scripts.abandoned-flat-containers.checks")
local ambient = require("openmw.ambient")
local async = require("openmw.async")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local vfs = require("openmw.vfs")

-- Easter egg stuff
local quest = types.Player.quests(self)["momw_afc_taking_liberties"]
local BATTLE_OVER_DELAY = 5
local BOSS_DISABLE_DELAY = 2
local SONG_DISTANCE = 2040
local STOP_MUSIC_DELAY = 3
local flea = "momw_afc_flea"
local ozzie = "momw_afc_ozzie"
local slash = "momw_afc_slash"
local bossTrack = "17 - Boss Battle 2.flac"
local hasBossSong = vfs.fileExists(bossTrack)
local bossSongPlaying = false
local bossesAreDead = false
local songTriggers  = {
    [flea] = true,
    [ozzie] = true,
    [slash] = true
}
local bossStatus  = {}


local warned = false
local function playBossMusic(stop)
    if not hasBossSong then
        if not warned then
            print("WARNING: Track for easter egg boss music not found!")
            print("WARNING: Missing the file: '17 - Boss Battle 2.flac'")
            warned = true
        end
        return
    end
    if stop then
        ambient.stopMusic()
        bossSongPlaying = false
        return
    end
    ambient.stopMusic()
    ambient.streamMusic(bossTrack)
    bossSongPlaying = true
end

local function onLoad(data)
    if not data then return end
    bossSongPlaying = data.bossSongPlaying
    bossStatus = data.bossStatus
	bossesAreDead = data.bossesAreDead
end

local function onSave()
	return {
        bossSongPlaying = bossSongPlaying,
        bossStatus = bossStatus,
        bossesAreDead = bossesAreDead
    }
end

local function onUpdate()
    -- Try to bail
    if bossesAreDead then return end
    if self.cell.name ~= "Enchanting Storage" then return end

    -- If all three bosses are dead then register them as such, stop the music, and bail.
    if bossStatus[flea] and bossStatus[ozzie] and bossStatus[slash] then
        bossesAreDead = true
        if bossSongPlaying then
            -- Stop the music after a short delay
            async:newSimulationTimer(
                STOP_MUSIC_DELAY,
                async:registerTimerCallback(
                    "momw_afc_stop_music",
                    function() playBossMusic(true) end
                )
            )

            -- Update the journal
            quest:addJournalEntry(30)

            async:newSimulationTimer(
                BATTLE_OVER_DELAY,
                async:registerTimerCallback(
                    "momw_afc_boss_battle_over",
                    function()
                        -- The battle is over and the player didn't get killed. Great Job!
                        core.sendGlobalEvent("momw_afc_bossBattleOver", self)
                    end
                )
            )
        end
        return
    end

    -- Scan for our bosses
    for _, actor in pairs(nearby.actors) do
        local recordId = actor.recordId
        if songTriggers[recordId] then
            -- Has this one been killed?
            if not bossStatus[recordId] and types.NPC.isDead(actor) then
                bossStatus[recordId] = true
                async:newSimulationTimer(
                    BOSS_DISABLE_DELAY,
                    async:registerTimerCallback(
                        string.format("momw_afc_disable_%s", recordId),
                        function()
                            core.sendGlobalEvent("momw_afc_disableActor", actor)
                        end
                    )
                )
            end

            -- Play the boss music as needed
            if not bossSongPlaying and (self.position - actor.position):length() <= SONG_DISTANCE then
                playBossMusic()
            end
        end
    end
end

local function UiModeChanged(data)
    if data.oldMode == "Dialogue" and data.newMode == nil then
        if quest and quest.stage == 20 then
            -- Wait until the dialogue box closes before zapping the player off to battle
            ambient.playSound("conjuration hit")
            core.sendGlobalEvent("momw_afc_bossBattleBegin", self)
        end
    end
end

local function inform(data)
    ui.showMessage(string.format("Your %s been deposited", data.str))
    ambient.playSound(data.sound)
end


return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        momw_af_containers_inform = inform
    }
}
