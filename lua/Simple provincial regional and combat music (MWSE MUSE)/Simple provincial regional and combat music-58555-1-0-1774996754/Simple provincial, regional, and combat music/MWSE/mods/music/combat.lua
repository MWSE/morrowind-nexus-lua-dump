local combatMod = {}

local MUSE = require("music.MUSE")
local functions = require("music.functions")

local playerLevelTiers = {10, 30}
local enemyHealthAdditions = {9, 5}

local combatTresholdInitial = 50
local combatTresholdCurrent = 0

local currentEnemies = {}
local currentEnemiesHealth = 0

local musicTypeCombat = "Combat"
local musicPathCombat = "combat/"

local combatEnemyOverride = ""

---------------------------------

local enemyInfo = {
    folder = "",
    priority = 0,
    instant = false,
    boss = false,
    tresholdMod = 1,

    enemyNames = {} -- wird jetzt für ID-Teile genutzt
}

local enemyCustomMap = {}

local function BuildEnemyTable()
    for file in lfs.dir("data files/MWSE/config/MS/") do
	
        if file:find("MS_e_", 1, true) and file:find("%.json$") then
            MUSE.DebugLog("Found config (combat): " .. file)

            local fileName = string.gsub(file, ".json", "")
            local MSconfig = mwse.loadConfig("MS/" .. fileName)

            if MSconfig and MSconfig.folder then
                local fullPath = "Data Files/Music/MS/combat/" .. MSconfig.folder
                local assignFolderSize = functions.checkFolder(fullPath, ".mp3")

                if(assignFolderSize >= 1) then

                    table.insert(enemyInfo, {})
                    local info = enemyInfo[#enemyInfo]

                    info.folder = MSconfig.folder
                    info.priority = MSconfig.priority
                    info.instant = MSconfig.instant or false
                    info.boss = MSconfig.boss or false
                    info.tresholdMod = MSconfig.tresholdMod or 1
                    info.enemyNames = MSconfig.enemyNames or {}

                    MUSE.DebugLog(
                        "(folder)" .. info.folder .. "/" ..
                        "(priority)" .. info.priority .. "/" ..
                        "(enemyEntries)" .. #info.enemyNames
                    )
                else
                    MUSE.DebugLog("Custom folder " .. fullPath .. " is empty or missing.")
                end
            else
                mwse.log("[MUSE] Invalid config: " .. fileName)
            end
        end
    end

    table.sort(enemyInfo, function(a, b) return a.priority > b.priority end)

    -- jetzt KEINE Map mehr → wir iterieren später direkt über enemyInfo
end

---------------------------------

-- 🔥 NEU: Partial ID Matching
local function CheckEnemyFromIdPartial(enemyId)
    local id = enemyId:lower()

    for _, info in ipairs(enemyInfo) do
        for _, key in ipairs(info.enemyNames) do
            local search = key:lower()

            if string.find(id, search, 1, true) then
                MUSE.DebugLog("Matched ID part: \"" .. search .. "\" in \"" .. id .. "\"")
                return info.folder
            end
        end
    end

    MUSE.DebugLog("No ID match for \"" .. id .. "\"")
    return nil
end

---------------------------------

local function CalculateTreshold(modifier)
    local playerLevel = tes3.player.object.level

    if(playerLevel < playerLevelTiers[1]) then
        combatTresholdCurrent =
        (combatTresholdInitial + (playerLevel * enemyHealthAdditions[1] - enemyHealthAdditions[1]))
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier
    end

    if(playerLevel >= playerLevelTiers[1] and playerLevel < playerLevelTiers[2]) then
        combatTresholdCurrent =
        (combatTresholdInitial
        + ((playerLevelTiers[1] * enemyHealthAdditions[1]) - enemyHealthAdditions[1])
        + (((playerLevel - playerLevelTiers[1]) * enemyHealthAdditions[2]) - enemyHealthAdditions[2]))
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier
    end

    if(playerLevel >= playerLevelTiers[2]) then
        combatTresholdCurrent =
        (combatTresholdInitial
        + ((playerLevelTiers[1] * enemyHealthAdditions[1]) - enemyHealthAdditions[1])
        + ((((playerLevelTiers[2] - playerLevelTiers[1]) - playerLevelTiers[1]) * enemyHealthAdditions[2]) - enemyHealthAdditions[2]))
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier
    end
end

local function CalculateEnemiesHealth()
    currentEnemiesHealth = 0
    for _, v in pairs(currentEnemies) do
        currentEnemiesHealth = currentEnemiesHealth + v.health.current
    end
end

local function AddEnemyToList(mobile)
    local ref = mobile.reference
    if ref and currentEnemies[ref] == nil then
        currentEnemies[ref] = mobile
        MUSE.DebugLog("Enemy added: " .. ref.id)
    end
end

local function RemoveEnemyFromList(e)
    currentEnemies[e.object] = nil
end
event.register("objectInvalidated", RemoveEnemyFromList)

function combatMod.ClearEnemyList()
    currentEnemies = {}
    currentEnemiesHealth = 0
end

function StartMusic()
    if(MUSE.settingsConfig.combatMusic ~= "all") then return end
    
    if(combatTresholdCurrent > currentEnemiesHealth) then
        return
    end

    MUSE.DebugLog("Entering combat.")
    MUSE.combatMode = true

    if(combatEnemyOverride ~= "") then
        local pathCombatOv = musicPathCombat .. combatEnemyOverride .. "/"
        MUSE.SetMusicDir(pathCombatOv, musicTypeCombat)
        if(MUSE.CheckMusicDir(pathCombatOv)) then
            MUSE.musicFolderSetDone = true
            return
        end
    end

    if(MUSE.combatOvCurrent ~= "") then
        local pathCombatOv = musicPathCombat .. MUSE.combatOvCurrent .. "/"
        MUSE.SetMusicDir(pathCombatOv, musicTypeCombat)
        if(MUSE.CheckMusicDir(pathCombatOv)) then
            MUSE.musicFolderSetDone = true
            return
        end
    end

    MUSE.SetMusicDir("Battle", musicTypeCombat)
    if(MUSE.CheckMusicDir("Battle")) then
        MUSE.musicFolderSetDone = true
        return
    end
end

---------------------------------

function combatMod.OnInitalize()
    BuildEnemyTable()
end

function combatMod.OnCombatEnter(e)
    if(MUSE.combatDisable) then return end
    if(MUSE.settingsConfig.combatMusic ~= "all") then return end
    if(MUSE.inAir) then return end

    local player = tes3.player.mobile

    if(e.actor == player) then return end

    if(e.target == player) then

        AddEnemyToList(e.actor)
        CalculateEnemiesHealth()
        CalculateTreshold(1)

        MUSE.DebugLog("Enemies' health/threshold: " .. currentEnemiesHealth .. " / " .. combatTresholdCurrent)

        -- 🔥 ID statt Name
        local enemyId = e.actor.reference.object.id

        local resultDir = CheckEnemyFromIdPartial(enemyId)

        if resultDir then
            combatEnemyOverride = resultDir
            StartMusic()
        else
            combatEnemyOverride = ""
        end
    end
end

function combatMod.CombatStarted(e)
    if(MUSE.settingsConfig.combatMusic ~= "all") then return end
    if(MUSE.combatMode) then return end

    local player = tes3.player.mobile

    if(e.actor == player) then return end

    if(e.target == player) then
        StartMusic()
    end
end

function combatMod.OnCombatLeave()
    local player = tes3.player.mobile
    if(player.inCombat == false and MUSE.combatMode == true) then
        MUSE.DebugLog("Leaving combat.")
        currentEnemiesHealth = 0
        MUSE.combatMode = false
    end
end

return combatMod