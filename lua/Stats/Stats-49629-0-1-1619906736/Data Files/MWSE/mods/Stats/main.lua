-- Stats, v 0.1
-- by JaceyS
-- Requires a recent version of MWSE
-- Basic implementation of stat tracking in Morrowind. Adds a new menu button called "Stats", which opens a menu window.
-- 3 levels of tracking - global, character non-continous, character continuous.
-- Character continuous can be stored in player data.
-- Character non-continous needs to be stored in a json file, keyed to a specific character
-- (creation time, stored in player data to serve as unchanging reference, in case a another mod allows name changing)
-- Global can add up all non-continous characters in the json file to get totals.
-- TODO: better button image, more stats to track
-- Thanks to Danae and Danjb, whose mods "Morrowind Stats" and "Morrowind Acheivements" did this first.
-- Thanks to Hrnchamd for his UIInspector mod, which is invaluable when trying to figure out UI stuff.
-- Thanks to NullCascade, Merlord, Greatness7, Petethegoat, and anyone else who has worked on MWSE!
local defaultConfig ={
    characters = {}
}
local config = mwse.loadConfig("Stats", defaultConfig)
local menuIDs = {}
local statsTracked = {}
local characterID
local inGame = false


local function disp_time(time)
    if(time == nil) then
        return "no data"
    end
    local days = math.floor(time/86400)
    local hours = math.floor(math.fmod(time, 86400)/3600)
    local minutes = math.floor(math.fmod(time,3600)/60)
    local seconds = math.floor(math.fmod(time,60))
    return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end

local function getCharacterID()
    local playerData = tes3.player.data
    if (playerData.JaceyS == nil) then
        playerData.JaceyS = {}
    end
    if (playerData.JaceyS.Stats == nil) then
        playerData.JaceyS.Stats = {}
    end
    if (playerData.JaceyS.Stats.id == nil) then
        local id = tostring(os.time(os.date("!*t")))
        playerData.JaceyS.Stats.id = id
        config.characters[id] = {}
        mwse.saveConfig("Stats", config)
    end
    return tostring(playerData.JaceyS.Stats.id)
end

-- Stat Generating events
local function onEnterFrame(e)
    local playerData = tes3.player.data.JaceyS.Stats
    playerData.time = playerData.time + e.delta
    config.characters[characterID].time = config.characters[characterID].time + e.delta
    mwse.saveConfig("Stats", config)
end

--

local function onLoaded()
    inGame = true
    characterID = getCharacterID()
    event.register("enterFrame", onEnterFrame)
    local playerData = tes3.player.data.JaceyS.Stats
    if (playerData.time == nil) then
        playerData.time = 0
    end
    if (config.characters[characterID].time == nil) then
        config.characters[characterID].time = 0
        mwse.saveConfig("Stats", config)
    end
    if (config.characters[characterID].timesLoaded == nil) then
        config.characters[characterID].timesLoaded = 1
    else
        config.characters[characterID].timesLoaded = config.characters[characterID].timesLoaded + 1
    end
end
event.register("loaded", onLoaded)

local function onLoad()
    if (inGame == true) then
        event.unregister("enterFrame", onEnterFrame)
        inGame = false
    end
end
event.register("load", onLoad)

local function prepareSaveData()
    local playerData = tes3.player.data.JaceyS.Stats
    if (playerData == nil) then return "Error" end
    local output = ""
    for _, instructions in ipairs(statsTracked) do
        if (instructions.save == false) then goto continue end
        local append = ""
        if (instructions.process == "disp_time") then
            append = instructions.label .. disp_time(playerData[instructions.key]) .."\n"
        elseif (instructions.process == "date") then
            append = instructions.label .. os.date("%c", tonumber(characterID)) .. "\n"
        elseif (instructions.process == "print") then
            append = instructions.label .. playerData[instructions.key] .. "\n"
        end
        output = output .. append
        ::continue::
    end
    return output
end

local function prepareCharacterData()
    local characterData = config.characters[characterID]
    if (characterData == nil) then return "Error" end
    local output = ""
    for _, instructions in ipairs(statsTracked) do
        if (instructions.character == false) then goto continue end
        local append = ""
        if (instructions.process == "disp_time") then
            append = instructions.label .. disp_time(characterData[instructions.key]) .."\n"
        elseif (instructions.process == "date") then
            append = instructions.label .. os.date("%c", tonumber(characterID)) .. "\n"
        elseif (instructions.process == "print") then
            append = instructions.label .. characterData[instructions.key] .."\n"
        end
        output = output .. append
        ::continue::
    end
    return output
end

local function prepareGlobalData()
    local output = ""
    if (config.characters == {}) then return "Make a character to start tracking stats." end
    for _, instructions in ipairs(statsTracked) do
        if (instructions.global == false) then goto continue end
        local append = ""
        if (instructions.process == "disp_time") then
            local cumulative = 0
            for _, character in pairs(config.characters) do
                cumulative = cumulative + character[instructions.key]
            end
            append = instructions.label .. disp_time(cumulative) .."\n"
        elseif (instructions.process == "print") then
            local cumulative = 0
            if (instructions.key == nil) then
                for _, _ in pairs (config.characters) do
                    cumulative = cumulative + 1
                end
            else
                for _, character in pairs(config.characters) do
                    if (character[instructions.key] == nil) then goto continue end
                    cumulative = cumulative + character[instructions.key]
                end
            end
            append = instructions.label .. cumulative .."\n"
        end
        output = output .. append
        ::continue::
    end
    return output
end

local function onClickCloseButton()
    local statsMenu = tes3ui.findMenu(menuIDs.statsMenu)
    statsMenu:destroy()
    event.unregister("keyDown", onClickCloseButton, { filter = tes3.scanCode.escape })
    local menuOptions = tes3ui.findMenu(menuIDs.menuOptions)
    menuOptions.visible = true
end

local function onStatsMenuOpen()
    tes3.worldController.menuClickSound:play()
    local statsMenu = tes3ui.findMenu(menuIDs.statsMenu)
    if (statsMenu == nil) then
        statsMenu = tes3ui.createMenu({id = menuIDs.statsMenu, dragFrame = true})
        statsMenu.text = "Stats"
        statsMenu:register("unfocus", function(e)
			return false
		end)
        local menuOptions = tes3ui.findMenu(menuIDs.menuOptions)
        menuOptions.visible = false
        statsMenu.minWidth = 400
        statsMenu.minHeight = 200
        statsMenu.width = 600
        statsMenu.height = 600
        statsMenu.positionX = -300
        statsMenu.positionY = 300
        local statMenuButtonContainer = statsMenu:createBlock({id = menuIDs.statMenuButtonContainer})
        statMenuButtonContainer.flowDirection = "left_to_right"
        statMenuButtonContainer.autoWidth = true
        statMenuButtonContainer.autoHeight = true
        statMenuButtonContainer.minWidth = 600
        local thisSaveButton = statMenuButtonContainer:createButton({id = menuIDs.thisSaveButton, text = "This Save"})
        thisSaveButton.autoWidth = true
        local thisCharacterButton = statMenuButtonContainer:createButton({id = menuIDs.thisCharacterButton, text = "This Character"})
        thisCharacterButton.autoWidth = true
        local globalButton = statMenuButtonContainer:createButton({id = menuIDs.globalButton, text = "Global Stats"})
        globalButton.autoWidth = true
        statsMenu:createDivider()
        local header = statsMenu:createLabel()
        local scrollPane = statsMenu:createVerticalScrollPane({id = menuIDs.statsScrollPane})
        scrollPane.borderAllSides = 8
        scrollPane.borderBottom = 24
        scrollPane.widthProportional = 1.0
        scrollPane.heightProportional = 1.0
        scrollPane.autoHeight = true
        local paneContainer = scrollPane:findChild(menuIDs.pane)
        thisSaveButton:register("mouseClick", function()
            header.text = "This Save's Stats"
            paneContainer:destroyChildren()
            if(not inGame) then
                paneContainer:createLabel({text = "Please load a save to see per save stats."})
            else
                paneContainer:createLabel({text = prepareSaveData()})
            end
            statsMenu:updateLayout()
            scrollPane.widget:contentsChanged()
        end)
        thisCharacterButton:register("mouseClick", function()
            header.text = "This Character's Stats"
            paneContainer:destroyChildren()
            if(not inGame) then
                paneContainer:createLabel({text = "Please load a save to see that character's stats."})
            else
                paneContainer:createLabel({text = prepareCharacterData()})
            end
            statsMenu:updateLayout()
            scrollPane.widget:contentsChanged()
        end)
        local function onClickGlobalStats()
            header.text = "Global Stats"
            paneContainer:destroyChildren()
            paneContainer:createLabel({text = prepareGlobalData()})
            statsMenu:updateLayout()
            scrollPane.widget:contentsChanged()
        end
        globalButton:register("mouseClick", onClickGlobalStats)
        local exitButton = statsMenu:createButton({id = menuIDs.exitButton, text = "OK"})
        exitButton:register("mouseClick", onClickCloseButton)
        event.register("keyDown", onClickCloseButton, { filter = tes3.scanCode.escape })
        exitButton.absolutePosAlignX = 1.0
        exitButton.absolutePosAlignY = 1.0
        onClickGlobalStats()
        statsMenu:updateLayout()
    else
        statsMenu.visible = true
    end
end

local function onMenuOptionsActivated(e)
    if (not e.newlyCreated) then
		return
	end
    local menuOptions = tes3ui.findMenu(menuIDs.menuOptions)
    local nullMenu = menuOptions:findChild(menuIDs.nullMenu)
    local statsContainer = nullMenu:createImageButton({
        id = menuIDs.statsContainer,
        idleId = menuIDs.buttonidle,
        idle = "Textures/stats/buttonidle.dds",
        overId = menuIDs.buttonover,
        over = "Textures/stats/buttonover.dds",
        pressedId = menuIDs.buttonpressed,
        pressed = "Textures/stats/buttonpressed.dds"
    })
    nullMenu:reorderChildren(-4, -1, 1)
    statsContainer.consumeMouseEvents = true
    statsContainer:register("mouseClick", onStatsMenuOpen)
    menuOptions:updateLayout()
end
event.register("uiActivated", onMenuOptionsActivated, { filter = "MenuOptions" })


local function init()
    menuIDs.menuOptions = tes3ui.registerID("MenuOptions")
    menuIDs.nullMenu = -32588 -- forgive the magic number
    menuIDs.statsContainer = tes3ui.registerID("MenuOptions_Stats_container")
    menuIDs.buttonidle = tes3ui.registerID("MenuOptions_Statsidlebutton")
    menuIDs.buttonover = tes3ui.registerID("MenuOptions_Statsoverbutton")
    menuIDs.buttonpressed = tes3ui.registerID("MenuOptions_Statspressedbutton")
    menuIDs.helpMenu = tes3ui.registerID("HelpMenu")

    menuIDs.statsMenu = tes3ui.registerID("StatsMenu")
    menuIDs.statsMenuLabel = tes3ui.registerID("StatsMenuLabel")
    menuIDs.statsMenuButtonContainer = tes3ui.registerID("StatsMenuButtonContainer")
    menuIDs.thisSaveButton = tes3ui.registerID("MenuStats_ThisSaveButton")
    menuIDs.thisCharacterButton = tes3ui.registerID("MenuStats_ThisCharacterButton")
    menuIDs.globalButton = tes3ui.registerID("MenuStats_GloabalButton")
    menuIDs.exitButton = tes3ui.registerID("Menu_Stats_Exit Button")
    menuIDs.statsScrollPane = tes3ui.registerID("MenuStats_StatsScrollPane")
    menuIDs.pane = tes3ui.registerID("PartScrollPane_pane")

    statsTracked[1] = {
        label = "Time Played: ",
        key = "time",
        process = "disp_time",
        save = true,
        character = true,
        global = true
    }
    statsTracked[2] = {
        label = "Number of Characters: ",
        key = nil,
        process = "print",
        save = false,
        character = false,
        global = true
    }
    statsTracked[3] = {
        label = "Date Created: ",
        key = nil,
        process = "date",
        save = true,
        character = true,
        global = false
    }
    statsTracked[4] = {
        label = "Times Loaded from Save: ",
        key = "timesLoaded",
        process = "print",
        save = false,
        character = true,
        global = true
    }
end
event.register("initialized", init)
event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate("Stats")
    template:saveOnClose("Stats", config)
    --[[
    function disp_time(time)
        if(time == nil) then
            return "no data"
        end
        local days = math.floor(time/86400)
        local hours = math.floor(math.fmod(time, 86400)/3600)
        local minutes = math.floor(math.fmod(time,3600)/60)
        local seconds = math.floor(math.fmod(time,60))
        return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
    end
    

    local savePage = template:createSidebarPage({
        label = "This Save",
        description = "Stats for what has happened in the history of this save file."
    })
    --[[
    if (tes3.player) then
        local saveTimePlayed = tes3.player.data.JaceyS.Stats.time
    end
    local saveTimePlayedDisplay = savePage:createCategory({
        label = "Time Played: ",
        description = disp_time(saveTimePlayed)
    })
    
    local characterPage = template:createSidebarPage({
        label = "This Character",
        description = "Stats for what has happened to this character, over any number of branching timelines."
    })

    local globalPage = template:createSidebarPage({
        label = "Global Stats",
        description = "Stats across all tracked characters."
    })
    ]]
    mwse.mcm.register(template)
end)