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

local function BuildEnemyTable()
    for file in lfs.dir("data files/MWSE/config/MS/") do
        if file:find("MS_e_", 1, true) and file:find("%.json$") then
            local fileName = string.gsub(file, ".json", "")

            local MSconfig = mwse.loadConfig("MS/" .. fileName)

            local assignFolderSize = functions.checkFolder("data files/music/" .. "MS" .. "/" .. "combat" .. "/" .. MSconfig.folder, ".mp3")
            if(assignFolderSize >= 1) then --assign combat data only if folder has music

                table.insert(enemyInfo, {})

                enemyInfo[#enemyInfo].folder = MSconfig.folder
                enemyInfo[#enemyInfo].priority = MSconfig.priority
                if(MSconfig.instant ~= nil) then enemyInfo[#enemyInfo].instant = MSconfig.instant else enemyInfo[#enemyInfo].instant = false end
                if(MSconfig.boss ~= nil) then enemyInfo[#enemyInfo].boss = MSconfig.boss else enemyInfo[#enemyInfo].boss = false end
                enemyInfo[#enemyInfo].tresholdMod = MSconfig.tresholdMod
                enemyInfo[#enemyInfo].enemyNames = MSconfig.enemyNames

                MUSE.DebugLog
                (
                    #MUSE.regionInfo
                    .. "(folder)" .. enemyInfo[#enemyInfo].folder .. "/"
                    .. "(priority)" .. enemyInfo[#enemyInfo].priority .. "/"
                    .. "(instant)" .. tostring(enemyInfo[#enemyInfo].instant ) .. "/"
                    .. "(boss)" .. tostring(enemyInfo[#enemyInfo].boss ) .. "/"
                    .. "(tresholdMod)" .. enemyInfo[#enemyInfo].tresholdMod .. "/"
                    .. "(enemyNames)" .. #enemyInfo[#enemyInfo].enemyNames .. "/"
                )

            end
        end
    end
    table.sort(enemyInfo, function( a, b ) return a.priority > b.priority end)
end


---------------------------------


local function CheckEnemyFromList(enemyName)
    MUSE.DebugLog("Checking enemy, " .. enemyName:lower())
    for i = 1, #enemyInfo do
        for j = 1, #enemyInfo[i].enemyNames do
            MUSE.DebugLog( enemyInfo[i].enemyNames[j]:lower() .. " " .. enemyName:lower())
            if(enemyName:lower() == enemyInfo[i].enemyNames[j]:lower()) then
                MUSE.DebugLog("Checking enemy success, " .. enemyName:lower())
                return enemyInfo[i].folder
            end
        end
    end
    return ""
end

local function CalculateTreshold(modifier)
    local player = tes3.getPlayerRef().object

    if(player.level < playerLevelTiers[1]) then --levels 0 - 10
        combatTresholdCurrent = (combatTresholdInitial + (player.level * enemyHealthAdditions[1] - enemyHealthAdditions[1])) --add tier 1
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier --mods
    end
    if(player.level >= playerLevelTiers[1] and player.level < playerLevelTiers[2]) then --levels 10 - 30
        combatTresholdCurrent = (combatTresholdInitial + ((playerLevelTiers[1] * enemyHealthAdditions[1]) - enemyHealthAdditions[1]) --add tier 1
        + (((player.level - playerLevelTiers[1]) * enemyHealthAdditions[2]) - enemyHealthAdditions[2])) --add tier 2
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier --mods
    end
    if(player.level >= playerLevelTiers[2]) then --levels 30+, health treshold locked
        combatTresholdCurrent = (combatTresholdInitial + ((playerLevelTiers[1] * enemyHealthAdditions[1]) - enemyHealthAdditions[1]) --add tier 1
        + (((playerLevelTiers[2] - playerLevelTiers[1]) * enemyHealthAdditions[2]) - enemyHealthAdditions[2])) --add tier 2
        * (MUSE.settingsConfig.combatMusicTresholdMod/100) * modifier --mods
    end
end

local function CalculateEnemiesHealth()
    currentEnemiesHealth = 0
    for r, _ in pairs(currentEnemies) do
        currentEnemiesHealth = currentEnemiesHealth + r.mobile.health.current
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
    -- NC: Also remove any references to an invalidated mobile.
    local ref = table.find(currentEnemies, e.object)
    if (ref) then
        currentEnemies[ref] = nil
    end
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

        CalculateTreshold(1)

        if (CheckEnemyFromList(e.actor.reference.object.name) ~= "") then
            MUSE.DebugLog("Custom enemy music, " .. e.actor.reference.object.name)
            combatEnemyOverride = CheckEnemyFromList(e.actor.reference.object.name)
            StartMusic()
        else
            combatEnemyOverride = ""
        end

        AddEnemyToList(e.actor)
        CalculateEnemiesHealth()

        MUSE.DebugLog("Enemies' health: " .. currentEnemiesHealth .. "/" .. combatTresholdCurrent)
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