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


local enemyInfo =
{
    folder = "",
    priority = 0,
    instant = false,
    boss = false,
    tresholdMod = 1,

    enemyNames = {}
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
                if(assignFolderSize >= 1) then --assign combat data only if folder has music

                    table.insert(enemyInfo, {})

                    local info = enemyInfo[#enemyInfo]
                    info.folder = MSconfig.folder
                    info.priority = MSconfig.priority
                    if(MSconfig.instant ~= nil) then info.instant = MSconfig.instant else info.instant = false end
                    if(MSconfig.boss ~= nil) then info.boss = MSconfig.boss else info.boss = false end
                    info.tresholdMod = MSconfig.tresholdMod
                    info.enemyNames = MSconfig.enemyNames

                    MUSE.DebugLog
                    (
                        #MUSE.regionInfo
                        .. "(folder)" .. info.folder .. "/"
                        .. "(priority)" .. info.priority .. "/"
                        .. "(instant)" .. tostring(info.instant ) .. "/"
                        .. "(boss)" .. tostring(info.boss ) .. "/"
                        .. "(tresholdMod)" .. info.tresholdMod .. "/"
                        .. "(enemyNames)" .. #info.enemyNames .. "/"
                    )
                else
					MUSE.DebugLog("Custom folder " .. fullPath .. " is empty or does not exist. Cannot use override.")
                end
            else
                mwse.log("[MUSE] Config file " .. fileName .. " is not valid json. It has been skipped.")
            end
        end
    end
    table.sort(enemyInfo, function( a, b ) return a.priority > b.priority end)
    
    -- Convert to lookup table, respecting priority
    for _, info in ipairs(enemyInfo) do
        for _, name in ipairs(info.enemyNames) do
            local name_casefold = name:lower()
            if enemyCustomMap[name_casefold] == nil then
                enemyCustomMap[name_casefold] = info
            end
        end
    end
end


---------------------------------


local function CheckEnemyFromList(enemyName)
    local key = enemyName:lower()
    local info = enemyCustomMap[key]

    if info then
        MUSE.DebugLog("Found customized enemy \"" .. key .. "\"")
        return info.folder
    else
        MUSE.DebugLog("No custom music for \"" .. key .. "\"")
    end

    return nil
end

local function CalculateTreshold(modifier)
    local playerLevel = tes3.player.object.level

    if(playerLevel < playerLevelTiers[1]) then --levels 0 - 10
        combatTresholdCurrent = (combatTresholdInitial + (playerLevel * enemyHealthAdditions[1] - enemyHealthAdditions[1])) --add tier 1
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier --mods
    end
    if(playerLevel >= playerLevelTiers[1] and playerLevel < playerLevelTiers[2]) then --levels 10 - 30
        combatTresholdCurrent = (combatTresholdInitial + ((playerLevelTiers[1] * enemyHealthAdditions[1]) - enemyHealthAdditions[1]) --add tier 1
        + (((playerLevel - playerLevelTiers[1]) * enemyHealthAdditions[2]) - enemyHealthAdditions[2])) --add tier 2
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier --mods
    end
    if(playerLevel >= playerLevelTiers[2]) then --levels 30+, health treshold locked
        combatTresholdCurrent = (combatTresholdInitial + ((playerLevelTiers[1] * enemyHealthAdditions[1]) - enemyHealthAdditions[1]) --add tier 1
        + ((((playerLevelTiers[2] - playerLevelTiers[1]) - playerLevelTiers[1]) * enemyHealthAdditions[2]) - enemyHealthAdditions[2])) --add tier 2
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier --mods
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

    ------------

    MUSE.DebugLog("Entering combat.")
    MUSE.combatMode = true

    --Assing enemy override
    if(combatEnemyOverride ~= "") then
        local pathCombatOv = musicPathCombat .. combatEnemyOverride .. "/"
        MUSE.SetMusicDir(pathCombatOv, musicTypeCombat)
        if(MUSE.CheckMusicDir(pathCombatOv) == true) then
            MUSE.musicFolderSetDone = true
            return
        end
    end

    --Assign combat override
    if(MUSE.combatOvCurrent ~= "") then
        local pathCombatOv = musicPathCombat .. MUSE.combatOvCurrent .. "/"
        MUSE.SetMusicDir(pathCombatOv, musicTypeCombat)
        if(MUSE.CheckMusicDir(pathCombatOv) == true) then
            MUSE.musicFolderSetDone = true
            return
        end
    end

    --Assign default combat music
    MUSE.SetMusicDir("Battle", musicTypeCombat)
    if(MUSE.CheckMusicDir("Battle") == true) then

        MUSE.musicFolderSetDone = true
        return
    end
end


---------------------------------


function combatMod.OnInitalize()
    BuildEnemyTable()
end

function combatMod.OnCombatEnter(e)
    if(MUSE.combatDisable == true) then return end

    if(MUSE.settingsConfig.combatMusic ~= "all") then return end

    local player = tes3.player.mobile

    if(MUSE.inAir == true) then return end

    if(e.actor == player) then return end

    if(e.target == player) then

        AddEnemyToList(e.actor)
        CalculateEnemiesHealth()

        CalculateTreshold(1)
        MUSE.DebugLog("Enemies' health/threshold: " .. currentEnemiesHealth .. " / " .. combatTresholdCurrent)

        local enemyName = e.actor.reference.object.name
        local resultDir = CheckEnemyFromList(enemyName)
        if resultDir then
            MUSE.DebugLog("Custom enemy music, " .. resultDir)
            combatEnemyOverride = resultDir
            StartMusic()
        else
            combatEnemyOverride = ""
        end
    end
end

function combatMod.CombatStarted(e)
    if(MUSE.settingsConfig.combatMusic ~= "all") then return end
    if(MUSE.combatMode == true) then return end
    ------------
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