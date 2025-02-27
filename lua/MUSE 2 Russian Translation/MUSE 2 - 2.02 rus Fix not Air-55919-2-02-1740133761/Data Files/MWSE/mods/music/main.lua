local MUSE = require("music.MUSE")
local regionMod = require("music.region")
local interiorMod = require("music.interior")
local depthsNAirMod = require("music.depthsnair")
local cellMod = require("music.cell")
local combatMod = require("music.combat")

---------------------------------

local function OnInitialize()
    regionMod.OnInitalize()
    interiorMod.OnInitalize()
    cellMod.OnInitalize()
    combatMod.OnInitalize()
end
event.register("initialized", OnInitialize)

---------------------------------


local function FindHostileActors()
    local cell = tes3.getPlayerCell()

    for enemy in cell:iterateReferences(tes3.objectType.creature) do
        if(enemy.mobile ~= nil) then
            for actor in tes3.iterate(enemy.mobile.hostileActors) do
                if actor.reference == tes3.player then
                    MUSE.DebugLog("Combat: hostile actor found: " .. actor.object.name)
                    return true
                end
            end
        end
    end
    for enemy in cell:iterateReferences(tes3.objectType.npc) do
        if(enemy.mobile ~= nil) then
            for actor in tes3.iterate(enemy.mobile.hostileActors) do
                if actor.reference == tes3.player then
                    MUSE.DebugLog("Combat: hostile actor found: " .. actor.object.name)
                    return true
                end
            end
        end
    end
    MUSE.DebugLog("Combat: no hostiles.")
    return false
end

local leavingCombat = false

local function OnCellEnter()
    local player = tes3.player.mobile

    if(player.inCombat == false and FindHostileActors() == false) then
        leavingCombat = true
    end
    if(MUSE.combatMode == true) then
        return
    end
    if(MUSE.depthsAirMode == true) then
        return
    end

    MUSE.musicFolderSetDone = false

    cellMod.OnCellEnter()
    interiorMod.OnCellEnter()
    regionMod.OnCellEnter()
end
event.register("cellChanged", OnCellEnter)
event.register("loaded", OnCellEnter)

---------------------------------


local combatEndTimer

local function Load()
    combatMod.ClearEnemyList()
end
event.register("loaded", Load)

local function CombatEnd()
    if(FindHostileActors() == true) then return end

    if(MUSE.depthsAirMode == false) then
        OnCellEnter()
    end
    --depthsNAirMod.StartMusic()

    combatMod.ClearEnemyList()
end

local function OnCombatStop(e)
    combatMod.OnCombatLeave()
    if(MUSE.combatMode == false) then
        combatEndTimer = timer.start({ duration = 1, callback = CombatEnd })
    end
end
event.register("combatStop", OnCombatStop)

local function OnCombatStart(e)
    combatMod.OnCombatEnter(e)
end
event.register("combatStart", OnCombatStart)

local function OnCombatStarted(e)
    combatMod.CombatStarted(e)
    if(combatEndTimer ~= nil) then combatEndTimer:cancel() end
end
event.register("combatStarted", OnCombatStarted)

---------------------------------

local function OnUpdate()
    --depthsNAirMod.Simulate()
    --MUSE.CheckHour()

    if(MUSE.restart == true) then
        OnCellEnter()
        MUSE.restart = false
    end

    if(MUSE.CheckifCombat == true) then
        leavingCombat = true
    end

    if(leavingCombat == true and MUSE.combatMode == true) then
        combatMod.OnCombatLeave()
        if(MUSE.combatMode == false) then
            combatEndTimer = timer.start({ duration = 3, callback = CombatEnd })
        end
        leavingCombat = false
    end
end
event.register("simulate", OnUpdate)

---------------------------------

local function OnSelectTrack()
    MUSE.PlayQueuedTrack()

    timer.frame.delayOneFrame(MUSE.RandomMusicTrack)
end
event.register("musicSelectTrack", OnSelectTrack)