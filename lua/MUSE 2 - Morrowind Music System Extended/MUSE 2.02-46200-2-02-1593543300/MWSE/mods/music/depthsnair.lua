local depthsNAirMod = {}

local MUSE = require("music.MUSE")
local functions = require("music.functions")

local airMinHeight = 5000
local underWaterMinDepth = -100

local groundZ = 0

local inAir = false
local underWater = false

local musicPathGeneral = "general/"

local musicTypeAir = "Air"
local musicTypeUnderwater = "Underwater"

local musicPathAir = "air/"
local musicPathUnderwater = "underwater/"


---------------------------------


local function GetGroundPosition()
    local player = tes3.getPlayerRef()

    if(player.mobile.isJumping == false) then
        groundZ = player.position.z
    end
end

local function CheckForAir()
    local player = tes3.getPlayerRef()
    local cell = tes3.getPlayerCell()

    if(cell.isInterior == true) then
        return
    end

    if(player.position.z > (groundZ + airMinHeight) and inAir == false) then
        inAir = true
        MUSE.DebugLog("Entering air, " .. player.mobile.position.z .. "/" .. (groundZ + airMinHeight))

        ---------------
        depthsNAirMod.StartMusic()
    end
    if(player.mobile.isJumping == false and inAir == true) then
        MUSE.restart = true
        MUSE.depthsAirMode = false
        MUSE.inAir = false
        MUSE.DebugLog("Leaving air")
        inAir = false
    end
end

local function CheckUnderWater()
    local player = tes3.getPlayerRef()
    local cell = tes3.getPlayerCell()
    local waterLevel = cell.waterLevel

    if(MUSE.combatMode == true) then return end

    if(cell.isInterior == true and cell.hasWater) then
        waterLevel = cell.waterLevel
    else
        waterLevel = 0
    end


    if(player.position.z < waterLevel + underWaterMinDepth and player.mobile.underwater == true and underWater == false) then
        underWater = true
        MUSE.DebugLog("Entering underwater")

        ---------------
        depthsNAirMod.StartMusic()
    end
    if(player.position.z > waterLevel and player.mobile.underwater == false and underWater == true) then
        MUSE.restart = true
        MUSE.depthsAirMode = false
        MUSE.DebugLog("Leaving underwater")
        underWater = false
    end
end


---------------------------------

function depthsNAirMod.StartMusic()
    if(inAir == true) then
        local path = ""
        path = musicPathGeneral .. musicPathAir
        if(MUSE.airOvCurrent ~= "") then
            path = musicPathGeneral .. MUSE.airOvCurrent .. "/"
            if(MUSE.CheckMusicDir(path) == false) then path = musicPathGeneral .. musicPathAir end
        end

        MUSE.SetMusicDir(path, musicTypeAir)
        if(MUSE.CheckMusicDir(path) == true) then
            MUSE.inAir = true
            MUSE.depthsAirMode = true
            MUSE.musicFolderSetDone = true
            return
        end
    end

    if(underWater == true) then
        local path = ""
        path = musicPathGeneral .. musicPathUnderwater
        if(MUSE.depthsOvCurrent ~= "") then
            path = musicPathGeneral .. MUSE.depthsOvCurrent .. "/"
            if(MUSE.CheckMusicDir(path) == false) then path = musicPathGeneral .. musicPathUnderwater end
        end

        MUSE.SetMusicDir(path, musicTypeUnderwater)
        if(MUSE.CheckMusicDir(path) == true) then
            MUSE.depthsAirMode = true
            MUSE.musicFolderSetDone = true
            return
        end
    end
end

function depthsNAirMod.Simulate()
    GetGroundPosition()
    CheckForAir()
    CheckUnderWater()
end

return depthsNAirMod