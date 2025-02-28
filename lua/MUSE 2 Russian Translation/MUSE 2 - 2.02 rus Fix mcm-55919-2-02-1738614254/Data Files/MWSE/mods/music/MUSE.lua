local MUSE = {}

MUSE.systemVersion = 2.02
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
    MUSE.DebugLog("Check path: " .. musicPathRootCurrent .. path .. ", " .. fSize)

    if(fSize == 0) then
        return false
    else
        return true
    end
end

function MUSE.SetMusicDir(path, musicType)
    musicPathCurrent = path .. "/"

    if(path == "Battle" or path == "Explore") then
        musicPathRootCurrent = musicPathDefault
    else
        musicPathRootCurrent = musicPathMain
    end

    ------------

    MUSE.DebugLog("Path: " .. musicPathCurrent .. "/" .. musicPathPrevious)
    if(musicPathCurrent == musicPathPrevious) then
        return
    end

    if(MUSE.CheckMusicDir(path) == false) then return end

    ------------

    musicTypeCurrent = musicType
    musicTypePrevious = musicType
    MUSE.DebugLog("Set music" .. musicTypeCurrent .. " folder: " .. musicPathCurrent)

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

            MUSE.DebugLog("Queuing music dir: " .. path .. "/" .. musicType)
            MUSE.musicFolderSetDone = true
            MUSE.musicPathQueued = path
            musicTypeQueued = musicType
            return
        end
    end

    MUSE.DebugLog("Queue attempted, but skipped: " .. path .. "/" .. musicType)
    MUSE.SetMusicDir(path, musicType)
end

function MUSE.PlayQueuedTrack()
    if(MUSE.musicPathQueued == "" or MUSE.musicPathQueued == nil) then return end
    MUSE.DebugLog("Playing queued dir: " .. MUSE.musicPathQueued .. "/" .. musicTypeQueued)
    MUSE.SetMusicDir(MUSE.musicPathQueued, musicTypeQueued)

    MUSE.musicPathQueued = ""
    musicTypeQueued = ""
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


local hourNight = 21
local hourDay = 7

function MUSE.CheckHour()
    local hour = tes3.getGlobal("GameHour")

    if (hour >= hourNight or hour <= hourDay) then
        if(MUSE.specialmode == "") then
            MUSE.specialmode = "night"
            MUSE.DebugLog("Night time")
            MUSE.DebugMessage{message = "Night time."}
        end
    end

    if (hour <= hourNight and hour >= hourDay) then
        if(MUSE.specialmode ~= "") then
            MUSE.specialmode = ""
            MUSE.DebugLog("Day time")
            MUSE.DebugMessage("Day time.")
        end
    end
end


----------------------------------
--MCM
local modName = "MUSE - Расширенная музыкальная система"
local LINKS_LIST = {
	{
		text = "Страница мода на Nexusmods",
		url = "https://www.nexusmods.com/morrowind/mods/46200"
	},
}
local CREDITS_LIST = {
	{
		text = "Автор: Rytelier",
		url = "https://next.nexusmods.com/profile/Rytelier",
	},
}
local function addSideBar(component)
	component.sidebar:createCategory(modName.."\nВерсия: "..MUSE.systemVersion)
	component.sidebar:createInfo{ text = "Гибкая музыкальная система для Морровинда, позволяющая легко настраивать музыку для разных локаций и событий." }

	local linksCategory = component.sidebar:createCategory("Ссылки")
	for _, link in ipairs(LINKS_LIST) do
		linksCategory:createHyperLink{ text = link.text, url = link.url }
		end
	local creditsCategory = component.sidebar:createCategory("Авторы")
	for _, credit in ipairs(CREDITS_LIST) do
		creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
	end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = modName,
	headerImagePath = "textures/MUSE_header.dds" }
	template:saveOnClose("MS_Config", MUSE.settingsConfig)
	template:register()
		
	local page = template:createSideBarPage { name = "Настройки" }
	addSideBar(page)

    page:createSlider
    {
        label = "Модификатор порога здоровья врагов (по умолчанию = 1)",
        min = 0,
        max = 500,
        step = 1,
        jump = 10,
        description = "Модификатор порога здоровья врагов (по умолчанию = 1) Определяет минимальный уровень здоровья врагов, необходимый для начала проигрывания музыки.",
        variable = mwse.mcm.createTableVariable{
            id = "combatMusicTresholdMod",
            table = MUSE.settingsConfig
        },
        updateValueLabel = function(self)
            if self.elements.slider then
                local newValue = ( self.elements.slider.widget.current) / 100
                self.elements.label.text = string.format("Модификатор порога здоровья врагов: %s", newValue )
            end
        end
    }

    page:createDropdown
    {
        label = "Музыка боя",
        description = "Проигрывать музыку во время боя?",
        widthProportional = 0.1,
        options = {
            { label = "Включить", value = "all" },
            { label = "Отключить", value = "none"}
        },
        variable = mwse.mcm.createTableVariable{
            id = "combatMusic",
            table = MUSE.settingsConfig
        }
    }

    page:createInfo { text = "Управление музыкой" }

    page:createOnOffButton
    ({
        label = "Очередь воспроизведения региональной музыки",
        description = "Музыка следующего региона начнет играть лишь после окончания предыдущей музыки для более плавного перехода.",
        variable = mwse.mcm.createTableVariable{
            id = "regionQueue",
            table = MUSE.settingsConfig
        }
    })

    page:createInfo { text = "Отладка" }

    page:createOnOffButton
    ({
        label = "Режим отладки",
        description = "Записывает информацию о работе мода в журнал событий mwse.log. Использовать в случае возникновения ошибок.",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = MUSE.settingsConfig
        }
    })


	end
event.register("modConfigReady", registerMCM)

return MUSE