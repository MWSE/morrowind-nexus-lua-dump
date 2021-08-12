
local this = {}

this.staticData = require("mer.bardicInspiration.data.staticData")
this.modName = this.staticData.modName
this.skills = require("mer.bardicInspiration.controllers.skillController").skills
this.messageBox = require("mer.bardicInspiration.messageBox")

do --mcm config
    local inMemConfig
    this.defaultConfig = require("mer.bardicInspiration.data.defaultConfig")
    this.config = setmetatable({
        save = function(newConfig)
            inMemConfig = newConfig
            mwse.saveConfig(this.staticData.configPath, inMemConfig)
        end
    }, {
        __index = function(_, key)
                inMemConfig = inMemConfig or mwse.loadConfig(this.staticData.configPath, this.defaultConfig)
            return inMemConfig[key]
        end,
        __newindex = function(_, key, value)
            inMemConfig = inMemConfig or mwse.loadConfig(this.staticData.configPath, this.defaultConfig)
            inMemConfig[key] = value
            mwse.saveConfig(this.staticData.configPath, inMemConfig)
        end
    })
end

--initialise player data
local function initPlayerData()
    tes3.player.data.mer_bardicInspiration = tes3.player.data.mer_bardicInspiration or {}
    for k, v in pairs(this.staticData.initPlayerData) do
        tes3.player.data.mer_bardicInspiration[k] = tes3.player.data.mer_bardicInspiration[k] or v
    end
end
do
    this.data = setmetatable({}, {
        __index = function(_, key)
            if tes3.player then
                initPlayerData()
                return tes3.player.data.mer_bardicInspiration[key]
            end
        end,
        __newindex = function(_, key, value)
            if tes3.player then
                initPlayerData()
                tes3.player.data.mer_bardicInspiration[key] = value
            end
        end
    })
end

local function onLoad()
    initPlayerData()
    --add topics
    mwscript.addTopic{ topic = "give a performance"}
    mwscript.addTopic{ topic = "teach me a song"}
    event.trigger("BardicInspiration:DataLoaded")
end
event.register("loaded", onLoad)

local logLevel = this.config.logLevel
this.log = require("mer.bardicInspiration.logger").new{
    name = "Bardic Inspiration",
    --outputFile = "Ashfall.log",
    logLevel = logLevel
}

function this.isLute(item)
    return item and this.staticData.lutes[item.id] == true
end

function this.isInnkeeper(ref)
    local id = ref.baseObject.id:lower()
    if ref.object.class.id == "Publican" or this.config.innkeepers[id] then
        return true
    end
end


function this.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end



local function setControlsDisabled(state)
    tes3.mobilePlayer.controlsDisabled = state
    tes3.mobilePlayer.jumpingDisabled = state
    tes3.mobilePlayer.attackDisabled = state
    tes3.mobilePlayer.magicDisabled = state
    tes3.mobilePlayer.mouseLookDisabled = state
end
function this.disableControls()
    setControlsDisabled(true)
end
function this.enableControls()
    setControlsDisabled(false)
    tes3.runLegacyScript{command = "EnableInventoryMenu"}
end

function this.hasLute()
    for id in pairs(this.staticData.lutes) do
        if tes3.player.object.inventory:contains(id) then
            return true
        end
    end
    return false
end

function this.playMusic(e)
    e = e or {}
    this.log:debug("tes3.worldController.audioController.volumeMusic: %s", tes3.worldController.audioController.volumeMusic)
    tes3.streamMusic{ path = e.path, crossfade = e.crossfade or 0.1 }
    if tes3.worldController.audioController.volumeMusic <= 0 then
        this.log:debug("media is <= 0, setting volume to effects volume")
        this.data.previousMusicVolume = tes3.worldController.audioController.volumeMusic
        tes3.worldController.audioController.volumeMusic = 0.8
        this.log:debug("new tes3.worldController.audioController.volumeMusic: %s", tes3.worldController.audioController.volumeMusic)
    end
    
end

function this.restoreMusic()
    if this.data.previousMusicVolume then
        this.log:debug("restoring previous volume")
        tes3.worldController.audioController.volumeMusic = this.data.previousMusicVolume
        this.data.previousMusicVolume = nil
    end
end

function this.stopMusic(e)
    this.log:debug("Stopping music")
    e = e or {}
    local crossfade = e.crossfade or 0.5
    tes3.streamMusic{ path = "mer_bard/silence.mp3", crossfade = crossfade }
    timer.start{
        type = timer.real,
        duration = crossfade,
        iterations = 1,
        callback = this.restoreMusic
    }
end

local fadingOut
--Fades out, passes time then runs callback when finished
function this.fadeTimeOut(e)
    local function fadeTimeIn()
        fadingOut = nil
        tes3.runLegacyScript({command = 'EnablePlayerControls'})
        e.callback()
    end

    tes3.fadeOut({duration = 0.5})
    tes3.runLegacyScript({command = 'DisablePlayerControls'})
    --Halfway through, advance gamehour
    local iterations = 10
    timer.start(
        {
            type = timer.real,
            iterations = iterations,
            duration = (e.secondsTaken / iterations),
            callback = (function()
                local gameHour = tes3.findGlobal('gameHour')
                gameHour.value = gameHour.value + (e.hoursPassed / iterations)
            end)
        }
    )
    fadingOut = true
    --All the way through, fade back in
    timer.start(
        {
            type = timer.real,
            iterations = 1,
            duration = e.secondsTaken,
            callback = (function()
                local fadeBackTime = 1
                tes3.fadeIn({duration = fadeBackTime})
                timer.start(
                    {
                        type = timer.real,
                        iterations = 1,
                        duration = fadeBackTime,
                        callback = fadeTimeIn
                    }
                )
            end)
        }
    )
end

--sorters
this.songSorter = function(songA, songB)
    local nameA = songA.name:lower()
    local nameB = songB.name:lower()
    if string.startswith(nameA, "the") then
        nameA = string.sub(nameA, 5)
    end
    if string.startswith(nameB, "the") then
        nameB = string.sub(nameB, 5)
    end
    return nameA < nameB
end


event.register("BardicInspiration:DataLoaded", function()
    this.log:debug("loaded")
    if fadingOut then
        this.log:debug("fading back in")
        tes3.runLegacyScript({command = 'EnablePlayerControls'})
        tes3.fadeIn({duration = 0.1})
        fadingOut = nil
    end
end)

return this