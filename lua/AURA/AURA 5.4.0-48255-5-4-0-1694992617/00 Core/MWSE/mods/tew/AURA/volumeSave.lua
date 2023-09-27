local cellData = require("tew.AURA.cellData")
local common = require("tew.AURA.common")
local config = require("tew.AURA.config")
local defaults = require("tew.AURA.defaults")
local messages = require(config.language).messages
local moduleData = require("tew.AURA.moduleData")
local soundData = require("tew.AURA.soundData")
local fader = require("tew.AURA.fader")
local volumeController = require("tew.AURA.volumeController")
local adjustVolume = volumeController.adjustVolume
local getVolume = volumeController.getVolume
local setVolume = volumeController.setVolume
local debugLog = common.debugLog

local this = {}

function this.init()
    this.entries = 0
    this.adjustedModules = {}
    this.id_menu = tes3ui.registerID("AURA:MenuAdjustVolume")
    this.id_header = tes3ui.registerID("AURA:MenuAdjustVolume_header")
    this.id_headerLabel = tes3ui.registerID("AURA:MenuAdjustVolume_headerLabel")
    this.id_scrollPane = tes3ui.registerID("AURA:MenuAdjustVolume_scrollPane")
    this.id_trackList = tes3ui.registerID("AURA:MenuAdjustVolume_trackList")
    this.id_trackBlock = tes3ui.registerID("AURA:MenuAdjustVolume_trackBlock")
    this.id_trackInfo = tes3ui.registerID("AURA:MenuAdjustVolume_trackInfo")
    this.id_sliderLabel = tes3ui.registerID("AURA:MenuAdjustVolume_sliderLabel")
    this.id_buttonBlock = tes3ui.registerID("AURA:MenuAdjustVolume_buttonBlock")
    this.id_buttonUndo = tes3ui.registerID("AURA:MenuAdjustVolume_buttonUndo")
    this.id_buttonRestoreDefaults = tes3ui.registerID("AURA:MenuAdjustVolume_buttonRestoreDefaults")
    this.printConfigVolumes()
    this.setConfigVolumes()
end

local function textInputIsActive()
    local menuController = tes3.worldController.menuController
    local inputFocus = menuController.inputController.textInputFocus
    if (not inputFocus or not inputFocus.visible) then
        return false
    end
    return true
end

local sliderPercent = {
    labelFmt = "%d%%  (%s = %d%%)",
    sliderMult = 1,
    sliderMin = 0,
    sliderMax = 100,
    sliderStep = 1,
    sliderJump = 5,
}
local sliderCoefficient = {
    labelFmt = "[%.2f x " .. messages.exteriorVolume .. "]  (%s = %.2fx)",
    sliderMult = 100,
    sliderMin = 0,
    sliderMax = 60,
    sliderStep = 1,
    sliderJump = 5,
}

local function createSlider(parent, sc)
    local current = sc.volumeTableCurrent[sc.key] * sc.sliderType.sliderMult
    local default = sc.volumeTableDefault[sc.key] * sc.sliderType.sliderMult
    local slider = parent:createSlider{
        current = current,
        min = sc.sliderType.sliderMin,
        max = sc.sliderType.sliderMax,
        step = sc.sliderType.sliderStep,
        jump = sc.sliderType.sliderJump,
    }
    slider.widthProportional = 0.99
    slider.borderTop = 5
    slider.borderBottom = 5
    local sliderLabel = parent:createLabel{ id = this.id_sliderLabel, text = "" }
    sliderLabel.text = string.format(sc.sliderType.labelFmt, current / sc.sliderType.sliderMult, messages.default, default / sc.sliderType.sliderMult)
    slider:register("PartScrollBar_changed", function(e)
        local sliderValue = slider:getPropertyInt("PartScrollBar_current")
        local newValue = sliderValue / sc.sliderType.sliderMult
        sliderLabel.text = string.format(sc.sliderType.labelFmt, newValue, messages.default, default / sc.sliderType.sliderMult)
        sc.volumeTableCurrent[sc.key] = newValue
        if sc.moduleName then
            adjustVolume{module = sc.moduleName, config = this.config}
            common.setInsert(this.adjustedModules, sc.moduleName)
        else
            setVolume(sc.track, newValue / 100)
        end
    end)
end

local function createEntry(id)
    local menu = tes3ui.findMenu(this.id_menu)
    local trackList = menu:findChild(this.id_trackList)
    local trackBlock = trackList:createBlock{ id = id or this.id_trackBlock }
    trackBlock.widthProportional = 1
    trackBlock.autoHeight = true
    trackBlock.flowDirection = tes3.flowDirection.topToBottom
    trackBlock.borderTop = 5
    trackBlock.borderBottom = 20
    local trackInfo = trackBlock:createLabel{ id = this.id_trackInfo, text = ""}
    trackInfo.wrapText = true
    this.entries = this.entries + 1
    return trackBlock
end

local function doExtremes()
    local cw = tes3.worldController.weatherController.currentWeather
    if (not this.cell.isInterior) and (cw) and (cw.index == 6 or cw.index == 7 or cw.index == 9) then
        local menu = tes3ui.findMenu(this.id_menu)
        local sc = {}
        local track
        if cw.name == "Ashstorm" then
            track = tes3.getSound("Ashstorm")
        elseif cw.name == "Blight" then
            track = tes3.getSound("Blight")
        elseif cw.name == "Blizzard" then
            track = tes3.getSound("BM Blizzard")
        end
        sc.key = cw.name
        sc.track = track
        sc.sliderType = sliderPercent
        sc.volumeTableDefault = defaults.volumes.extremeWeather
        sc.volumeTableCurrent = this.config.volumes.extremeWeather
        local entry = createEntry()
        local trackInfo = entry:findChild(this.id_trackInfo)
        trackInfo.text = string.format("%s: %s", cw.name, track.id)
        createSlider(entry, sc)
        menu:updateLayout()
    end
end

local function doRain()
    local track, rainType
    local cw = tes3.worldController.weatherController.currentWeather
    if (not this.cell.isInterior) and cw and cw.rainLoopSound and cw.rainLoopSound:isPlaying() then
        track = cw.rainLoopSound
        rainType = cellData.rainType[cw.index]
        if not rainType then return end -- Needs variable rain sounds. TODO: maybe add tooltip
    else
        return
    end

    local menu = tes3ui.findMenu(this.id_menu)
    local sc = {}
    sc.key = rainType
    sc.track = track
    sc.sliderType = sliderPercent
    sc.volumeTableDefault = defaults.volumes.rain[cw.name]
    sc.volumeTableCurrent = this.config.volumes.rain[cw.name]

    local entry = createEntry()
    local trackInfo = entry:findChild(this.id_trackInfo)
    trackInfo.text = string.format("%s (%s): %s", cw.name, rainType, track.id)
    createSlider(entry, sc)
    menu:updateLayout()
end

local function doModules()
    local menu = tes3ui.findMenu(this.id_menu)
    for moduleName, data in pairs(moduleData) do
        if data.new and data.newRef and tes3.getSoundPlaying{sound = data.new, reference = data.newRef} then
            local ref = data.newRef
            local track = data.new
            local configKey = common.getInteriorType(this.cell):gsub("ten", "sma")
            local sc = {}
            local entry = createEntry()
            local trackInfo = entry:findChild(this.id_trackInfo)
            if fader.isRunning(moduleName) then
                trackInfo.text = string.format("%s: %s", moduleName, messages.fadeInProgress)
                goto nextModule
            end

            sc.volumeTableDefault = defaults.volumes.modules[moduleName]
            sc.volumeTableCurrent = this.config.volumes.modules[moduleName]

            if this.cell.isInterior
            and (moduleName ~= "interiorWeather")
            and (moduleName ~= "interior") then
                sc.sliderType = sliderCoefficient
            else
                if (ref ~= tes3.mobilePlayer.reference) and (moduleName == "rainOnStatics") then
                    trackInfo.text = string.format("%s: %s", moduleName, messages.findOutdoorShelter)
                    trackInfo:register(tes3.uiEvent.help, function(e)
                        local tooltip = tes3ui.createTooltipMenu()
                        local tip = messages.findOutdoorShelterTooltip
                        tooltip:createLabel{ text = tip }
                    end)
                    goto nextModule
                end
                if cellData.playerUnderwater then
                    configKey = "und"
                    sc.sliderType = sliderCoefficient
                else
                    configKey = "volume"
                    sc.sliderType = sliderPercent
                end
            end

            sc.key = configKey
            sc.moduleName = moduleName

            trackInfo.text = string.format("%s: %s", moduleName, track.id)
            createSlider(entry, sc)
        end
        :: nextModule ::
    end
    menu:updateLayout()
end

local function updateHeader()
    local menu = tes3ui.findMenu(this.id_menu)
    local trackList = menu:findChild(this.id_trackList)
    local hLabel = menu:findChild(this.id_headerLabel)
    local cellType
    if (trackList) and (this.entries > 0) and this.cell.isInterior then
        cellType = common.getInteriorType(this.cell):gsub("^sma$", messages.small):gsub("^ten$", messages.small):gsub("^big$", messages.big)
        hLabel.text = string.format("%s (%s)", messages.adjustForInterior, cellType)
    elseif (trackList) and (this.entries > 0) and not this.cell.isInterior then
        hLabel.text = messages.adjustForExterior
        if cellData.playerUnderwater then
            hLabel.text = string.format("%s\n(%s)", hLabel.text, messages.underwater)
        end
    else
        hLabel.text = messages.noTracksPlaying
    end
end

local function createHeader()
    local menu = tes3ui.findMenu(this.id_menu)
    local headerBlock = menu:createBlock{ id = this.id_header }
    headerBlock.widthProportional = 1
    headerBlock.autoHeight = true
    headerBlock.flowDirection = tes3.flowDirection.topToBottom
    headerBlock.borderTop = 20
    headerBlock.borderBottom = 25
    local hLabel = headerBlock:createLabel{ id = this.id_headerLabel, text = "" }
    hLabel.widthProportional = 1
    hLabel.wrapText = true
    hLabel.justifyText = "center"
end

local function createFooter()
    local menu = tes3ui.findMenu(this.id_menu)
    local buttonBlock = menu:createBlock{ id = this.id_buttonBlock }
    buttonBlock.absolutePosAlignX = 0.99
    buttonBlock.absolutePosAlignY = 0.99
    buttonBlock.autoWidth = true
    buttonBlock.autoHeight = true

    local buttonRestoreDefaults = buttonBlock:createButton{ id = this.id_buttonRestoreDefaults, text = messages.restoreDefaults }
    local buttonUndo = buttonBlock:createButton{ id = this.id_buttonUndo, text = messages.undo }

    buttonRestoreDefaults:register(tes3.uiEvent.mouseClick, this.onRestoreDefaults)
    buttonUndo:register(tes3.uiEvent.mouseClick, this.onUndo)
end

local function createBody()
    if not this.cell then return end
    local menu = tes3ui.findMenu(this.id_menu)
    local trackList = menu:findChild(this.id_trackList)
    if not trackList then
        this.entries = 0
        trackList = menu:createVerticalScrollPane{ id = this.id_trackList }
        trackList.widthProportional = 0.99
        trackList.heightProportional = 0.9
    end
    doExtremes()
    doRain()
    doModules()
    updateHeader()
end

local function createWindow()

    local menu = tes3ui.createMenu{ id = this.id_menu, dragFrame = true }
    tes3ui.enterMenuMode(this.id_menu)

    menu.text = "AURA"
    menu.width = 430
    menu.height = 600
    if this.positionX and this.positionY then
        menu.positionX = this.positionX
        menu.positionY = this.positionY
    else
        menu.positionX = menu.maxWidth / 2 - menu.width
        menu.positionY = menu.maxHeight / 2
        menu:loadMenuPosition()
    end

    createHeader()
    createBody()

    if this.entries > 0 then createFooter() end

    updateHeader()

    menu.width = 430
    menu.height = 600
    menu:updateLayout()
    menu.visible = true
end

local function redraw()
    local menu = tes3ui.findMenu(this.id_menu)
    local trackList = menu:findChild(this.id_trackList)
    trackList:destroy()
    mwse.saveConfig("AURA", this.config)
    this.config = mwse.loadConfig("AURA", defaults)
    this.configPrevious = table.deepcopy(this.config)
    createBody()
    for _, moduleName in ipairs(this.adjustedModules) do
        adjustVolume{module = moduleName, config = this.config}
    end
    table.clear(this.adjustedModules)
    this.setConfigVolumes(this.config)
    menu:updateLayout()
end

function this.toggle(e)

    if textInputIsActive() then return end

    if e.isShiftDown then

        local menu = tes3ui.findMenu(this.id_menu)

        if (not menu) then
            this.cell = cellData.cell
            this.config = mwse.loadConfig("AURA", defaults)
            this.configPrevious = table.deepcopy(this.config)
            createWindow()
            if (not tes3ui.menuMode()) then
                tes3ui.enterMenuMode(this.id_menu)
                debugLog("Toggle on.")
            end
        else
            this.positionX = menu.positionX
            this.positionY = menu.positionY
            menu:destroy()
            if (tes3ui.menuMode()) then
                tes3ui.leaveMenuMode()
                debugLog("Toggle off.")
            end
            if this.config then mwse.saveConfig("AURA", this.config) end
            this.configPrevious = nil
            this.entries = 0
            table.clear(this.adjustedModules)
        end

    end
end

function this.onUndo(e)
    debugLog("Reverting changes.")
    this.config.volumes.modules = this.configPrevious.volumes.modules
    this.config.volumes.rain = this.configPrevious.volumes.rain
    this.config.volumes.extremeWeather = this.configPrevious.volumes.extremeWeather
    redraw()
end

function this.onRestoreDefaults(e)
    debugLog("Restoring defaults.")
    this.config.volumes.modules = defaults.volumes.modules
    this.config.volumes.rain = defaults.volumes.rain
    this.config.volumes.extremeWeather = defaults.volumes.extremeWeather
    redraw()
    tes3.messageBox{ message = messages.defaultsRestored }
end

function this.setConfigVolumes(c)
    local config = c or mwse.loadConfig("AURA", defaults)
    local vanillaRain = tes3.getSound("Rain")
    local vanillaStorm = tes3.getSound("rain heavy")
    local ashstorm = tes3.getSound("ashstorm")
    local blight = tes3.getSound("Blight")
    local blizzard = tes3.getSound("BM Blizzard")
    if config.rainSounds then
        if vanillaRain then vanillaRain.volume = 0 end
        if vanillaStorm then vanillaStorm.volume = 0 end
    end
    for weatherName, data in pairs(soundData.rainLoops) do
        for rainType, track in pairs(data) do
            if track then
                setVolume(track, config.volumes.rain[weatherName][rainType] / 100)
            end
        end
    end
    if ashstorm then setVolume(ashstorm, config.volumes.extremeWeather["Ashstorm"] / 100) end
    if blight then setVolume(blight, config.volumes.extremeWeather["Blight"] / 100) end
    if blizzard then setVolume(blizzard, config.volumes.extremeWeather["Blizzard"] / 100) end
end

function this.printConfigVolumes()
    local config = mwse.loadConfig("AURA", defaults)
    for configKey, volumeTable in pairs(config.volumes) do
        if configKey == "modules" then
            for moduleName, moduleVol in pairs(volumeTable) do
                debugLog(string.format("[%s] vol: %s, big: %s, sma: %s, und: %s", moduleName, moduleVol.volume, moduleVol.big, moduleVol.sma, moduleVol.und))
            end
        elseif configKey == "rain" then
            for weatherName, weatherData in pairs(volumeTable) do
                debugLog(string.format("[%s] light: %s, medium: %s, heavy: %s", weatherName, weatherData.light, weatherData.medium, weatherData.heavy))
            end
        else
            for volumeTableKey, volumeTableValue in pairs(volumeTable) do
                debugLog(string.format("[%s] %s: %s", configKey, volumeTableKey, volumeTableValue))
            end
        end
    end
end

this.init()
event.register(tes3.event.keyDown, this.toggle, { filter = config.volumeSave.keyCode })