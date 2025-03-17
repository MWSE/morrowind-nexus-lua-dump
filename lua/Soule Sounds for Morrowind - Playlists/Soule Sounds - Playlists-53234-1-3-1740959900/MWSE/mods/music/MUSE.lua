local MUSE = {}

MUSE.systemVersion = 2.01
--Main variables

local musicPathRootCurrent = "data files/music/MS/"
local musicPathMain = "data files/music/MS/"
local musicPathDefault = "data files/music/"

local functions = require("music.functions")


local musicTypeCurrent = ""
local musicTypePrevious = ""

local musicPathCurrent = ""
local musicPathPrevious = ""

MUSE.musicPathQueued = ""
local musicTypeQueued = ""
local musicQueuedList = {region = true, cell = true, dungeon = false, tileset = false}

local musicPlaylist = {}

local trackNumber = 0
local trackNumberLast = 0

MUSE.musicFolderSetDone = false
---------------------------------
--Global info lists

MUSE.restart = false

MUSE.regionInfo =
{
    musicFolder = "",
    regionName = "",
    dungeonOv = "",
    combatOv = "",
    combatDisabled = false,
    airOv = "",
    depthsOv = "",
    tilesetDisabled = false,
    queued = false,
    queuedList = {region = true, cell = true, dungeon = false, tileset = false}
}
MUSE.regionCurrent = ""
MUSE.regionPrevious = ""

MUSE.dungeonOvCurrent = ""
MUSE.tilesetDisabledCurrent = false
MUSE.combatOvCurrent = ""
MUSE.airOvCurrent = ""
MUSE.depthsOvCurrent = ""

MUSE.combatDisable = false
MUSE.combatTresholdMod = 1

MUSE.combatMode = false
MUSE.depthsAirMode = false
MUSE.inAir = false

MUSE.specialmode = ""

MUSE.settingsConfig = mwse.loadConfig("MS_Config")
if (MUSE.settingsConfig == nil) then
    MUSE.settingsConfig =
    {
        combatMusic = "all",
        combatMusicTresholdMod = 1,
        regionQueue = true,
        debugMode = false,
    }
end


---------------------------------
--Debug


function MUSE.DebugLog(text)
    if(MUSE.settingsConfig.debugMode == true) then
        mwse.log("[MUSE] " .. text)
    end
end

function MUSE.DebugMessage(text)
    if(MUSE.settingsConfig.debugMode == true) then
        tes3.messageBox({message = "[MUSE] " .. text})
    end
end


---------------------------------
--Main functions


function MUSE.PlayMusicTrack(path)
    tes3.streamMusic
    {
        path = path,
        situation = tes3.musicSituation.uninterruptible
    }
end

function MUSE.RandomMusicTrack()
    if(musicPlaylist[1] == nil) then return end

    trackNumber = functions.randomizeNumber(#musicPlaylist, trackNumberLast)

    local root = "MS/"
    if(musicPathRootCurrent == musicPathDefault) then root = "" end

    MUSE.PlayMusicTrack(root .. musicPathCurrent .. musicPlaylist[trackNumber])

    trackNumberLast = trackNumber

    MUSE.DebugLog("Playing track: " .. musicPathCurrent .. musicPlaylist[trackNumber])
end

function MUSE.getMusicFiles()
    musicPlaylist = {}

    for file in lfs.dir(musicPathRootCurrent .. musicPathCurrent) do
        if string.endswith(file, ".mp3") then
            MUSE.DebugLog("Found music file: " .. musicPathRootCurrent .. musicPathCurrent .. file)
            table.insert(musicPlaylist, file)
        end
    end
end

function MUSE.CheckMusicDir(path) -- Do music files exist in the directory?
    local fSize = functions.checkFolder(musicPathRootCurrent .. path, ".mp3")
    MUSE.DebugLog("Check path: " .. musicPathRootCurrent .. path .. ": file count = " .. fSize)

    if(fSize == 0) then
        return false
    else
        return true
    end
end

function MUSE.SetMusicDir(path, musicType)
    musicPathCurrent = path .. "/"

	local hour = tes3.getGlobal("GameHour")
	
	if (hour >= 21 or hour <= 7) then -- night
		musicPathCurrent = musicPathCurrent .. "night/"
	end

    if(path == "Battle" or path == "Explore") then
        musicPathRootCurrent = musicPathDefault
    else
        musicPathRootCurrent = musicPathMain
    end
	

    ------------

    MUSE.DebugLog("Path change: --to-- " .. musicPathCurrent .. "   --from-- " .. musicPathPrevious)
    if(musicPathCurrent == musicPathPrevious) then
        return
    end

    if(MUSE.CheckMusicDir(path) == false) then return end

    ------------

    musicTypeCurrent = musicType
    musicTypePrevious = musicType
    MUSE.DebugLog("Set " .. musicTypeCurrent .. " music folder: " .. musicPathCurrent)

    musicPathPrevious = musicPathCurrent
    MUSE.getMusicFiles()
    MUSE.RandomMusicTrack()
end

function MUSE.QueueMusicDir(path, musicType)
    if(path == "Explore") then
        musicPathRootCurrent = musicPathDefault
    else
        musicPathRootCurrent = musicPathMain
    end

    if(MUSE.CheckMusicDir(path) == false) then return end

    if(musicTypeCurrent == "Region" or musicTypeCurrent == "cell") then
        if(musicType == "Region" or musicType == "cell") then

            MUSE.DebugLog("Queuing music dir: " .. path .. " type:" .. musicType)
            MUSE.musicFolderSetDone = true
            MUSE.musicPathQueued = path
            musicTypeQueued = musicType
            return
        end
    end

    MUSE.DebugLog("Queue attempted, but skipped: " .. path .. " type:" .. musicType)
    MUSE.SetMusicDir(path, musicType)
end

function MUSE.PlayQueuedTrack()
    if(MUSE.musicPathQueued == "" or MUSE.musicPathQueued == nil) then return false end
    MUSE.DebugLog("Playing queued dir: " .. MUSE.musicPathQueued .. " type:" .. musicTypeQueued)
    MUSE.SetMusicDir(MUSE.musicPathQueued, musicTypeQueued)

    MUSE.musicPathQueued = ""
    musicTypeQueued = ""
	return true
end

function MUSE.ClearQueue()
    MUSE.musicPathQueued = ""
    musicTypeQueued = ""
end


function MUSE.CheckifCombat()
    if(musicTypeCurrent == "Combat" and MUSE.combatMode == false) then
        return true
    end
    return false
end

---------------------------------
--Special modes (to implement)


--local hourNight = 21
--local hourDay = 7

--function MUSE.CheckHour()
--    local hour = tes3.getGlobal("GameHour")

--    if (hour >= hourNight or hour <= hourDay) then
--        if(MUSE.specialmode == "") then
--            MUSE.specialmode = "night"
--            MUSE.DebugLog("Night time")
--            MUSE.DebugMessage{message = "Night time."}
--        end
--    end

--    if (hour <= hourNight and hour >= hourDay) then
--        if(MUSE.specialmode ~= "") then
--            MUSE.specialmode = ""
--            MUSE.DebugLog("Day time")
--            MUSE.DebugMessage("Day time.")
--        end
--    end
--end


----------------------------------
--MCM


local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")

    local template = EasyMCM.createTemplate
    {
        name = "Morrowind Music System Extended 2 beta",
        headerImagePath = "textures/MUSE_header.dds"
    }

    local page = template:createPage()

    local category = page:createCategory("Settings")

    category:createSlider
    {
        label = "Combat enemy health treshold modifier (default = 1)",
        min = 0,
        max = 500,
        step = 1,
        jump = 10,
        description = "Min health requirement for enemies for combat music to start.",
        variable = EasyMCM.createTableVariable{
            id = "combatMusicTresholdMod",
            table = MUSE.settingsConfig
        },
        updateValueLabel = function(self)
            if self.elements.slider then
                local newValue = ( self.elements.slider.widget.current) / 100
                self.elements.label.text = string.format("Combat enemy health treshold modifier: %s", newValue )
            end
        end
    }

    category:createDropdown
    {
        label = "Combat music",
        description = "Will combat music play when in battle?",
        widthProportional = 0.1,
        options = {
            { label = "Enabled", value = "all" },
            { label = "Disabled", value = "none"}
        },
        variable = mwse.mcm.createTableVariable{
            id = "combatMusic",
            table = MUSE.settingsConfig
        }
    }

    category:createInfo
    {
        text = "Music control"
    }

    category:createOnOffButton
    ({
        label = "Region music queuing",
        description = "Regional music change will wait until current track is finished for smoother experience.",
        variable = EasyMCM.createTableVariable{
            id = "regionQueue",
            table = MUSE.settingsConfig
        }
    })

    category:createInfo
    {
        text = "Debug"
    }

    category:createOnOffButton
    ({
        label = "Debug mode",
        description = "Creates mod information in the log, use when troubleshooting.",
        variable = EasyMCM.createTableVariable{
            id = "debugMode",
            table = MUSE.settingsConfig
        }
    })

    template:saveOnClose("MS_Config", MUSE.settingsConfig)

    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)

return MUSE