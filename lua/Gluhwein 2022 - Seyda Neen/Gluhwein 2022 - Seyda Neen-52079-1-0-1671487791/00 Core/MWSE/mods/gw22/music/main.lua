-- file paths are relative to 'Data Files\\Music\\'

local SILENCE = "gw22\\special\\silence.mp3"
local SITUATION = tes3.musicSituation.explore

local TRACKS = {
    "gw22\\saturnalia-title.mp3",
    "gw22\\saturnalia-dream.mp3",
    "gw22\\saturnalia-explore2.mp3",
}

local battlePlayed
local GW_ID = "GW22_"
local BATTLE_TRACK = "gw22\\saturnalia-battle.mp3"


local function isSeydaNeenCell(cell)
    return (cell and cell.editorName or ""):startswith("Seyda Neen")
end

local function onCellChanged(e)
    local isSeydaNeen = isSeydaNeenCell(e.cell)
    local wasSeydaNeen = isSeydaNeenCell(e.previousCell)

    if isSeydaNeen and not wasSeydaNeen then
        tes3.streamMusic({path = table.choice(TRACKS), situation = SITUATION})
    elseif wasSeydaNeen and not isSeydaNeen then
        tes3.streamMusic({path = SILENCE})
    end
end
event.register("cellChanged", onCellChanged)

local function onMusicSelectTrack(e)
    if isSeydaNeenCell(tes3.player.cell) and e.situation == SITUATION then
        e.music = table.choice(TRACKS)
        e.situation = SITUATION
        return false
    end
end
event.register("musicSelectTrack", onMusicSelectTrack, { priority = 360 })

local function onMainMenu()
    tes3.streamMusic({path = "gw22\\saturnalia-title.mp3", situation = tes3.musicSituation.uninterruptible})
end
event.register (tes3.event.uiActivated, onMainMenu, { filter = "MenuOptions", doOnce = true, })

local function onCombatStart(e)
    if battlePlayed == true then return end

    local target = e.target.reference.id
    local actor = e.actor.reference.id
    if string.startswith(target, GW_ID)
    or string.startswith(actor, GW_ID) then
        tes3.streamMusic{path = BATTLE_TRACK, situation = tes3.musicSituation.battle}
        battlePlayed = true
    end
end

local function onCombatStopped()
    if tes3.player.mobile.inCombat then return end -- Because MW can be really dumb with that one
    local cell = tes3.getPlayerCell()
    local isSeydaNeen = isSeydaNeenCell(cell)
    if isSeydaNeen then
        tes3.streamMusic{path = table.choice(TRACKS), situation = SITUATION}
    else
        tes3.streamMusic({path = SILENCE})
    end
end

event.register(tes3.event.combatStart, onCombatStart)
event.register(tes3.event.combatStopped, onCombatStopped)

event.register("initialized", function()
    mwse.overrideScript("gw22_Music_s", function()
    end)
end)
