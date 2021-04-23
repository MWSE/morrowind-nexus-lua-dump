local WtC
local plazaWeathers = {0,1,2,4,5}
local config = require("tew\\Glass Domes\\config")
local tewLib = require("tew\\tewLib\\tewLib")
local isOpenPlaza=tewLib.isOpenPlaza
local greenTint = config.greenTint
local debugLogOn = config.debugLogOn
local fauxWeathers = require("tew\\Glass Domes\\fauxWeathers")
local lastCell
local lastDomeWeather = ""
local version="1.2.8"

local ashValues = fauxWeathers.ashValues
local blightValues = fauxWeathers.blightValues
local foggyValues = fauxWeathers.foggyValues
local overcastValues = fauxWeathers.overcastValues

local function getWeatherData(var)
    return {var.r, var.g, var.b}
end

local function debugLog(string)
    if debugLogOn then
       mwse.log("[Glass Domes "..version.."]: "..string)
    end
end

local nightTint = {0.029529996216297,0.11865200102329,0.090317867696285}

local tintStrengths={
    ["Weak"] = {0.53574013710022,0.82729339599609,0.72401332855225},
    ["Moderate"] = {0.37413274645805,0.85105844736099,0.70162286758423},
    ["Strong"] = {0.21105913817883,0.86475539207458,0.68743902444839},
}

local function getTintStrength()
    for name, value in pairs(tintStrengths) do
        if name == config.tintStrength then
            return value
        end
    end
end

local weatherTintsOld={
[0]={},
[1]={},
[2]={},
[3]={},
[4]={},
[5]={},
[6]={},
[7]={},
[8]={},
[9]={},
}

local function setTint(colour, tint)
    colour.r = tint[1]
    colour.g = tint[2]
    colour.b = tint[3]
end

local function removeGreenTint()
    debugLog("Reverting green tint.")
    if weatherTintsOld[0][1] ~= nil then
        for _, w in pairs(WtC.weathers) do
            for wIndex, _ in pairs(weatherTintsOld) do
                if w.index == wIndex then
                    setTint(w.sunDayColor, weatherTintsOld[w.index][1])
                    setTint(w.sunNightColor, weatherTintsOld[w.index][2])
                    setTint(w.sunSunriseColor, weatherTintsOld[w.index][3])
                    setTint(w.sunSunsetColor, weatherTintsOld[w.index][4])
                end
            end
        end
    end
end

local function applyGreenTint()
    local tintGlass=getTintStrength()
    for _, w in pairs(WtC.weathers) do
        table.insert(weatherTintsOld[w.index], getWeatherData(w.sunDayColor))
        table.insert(weatherTintsOld[w.index], getWeatherData(w.sunNightColor))
        table.insert(weatherTintsOld[w.index], getWeatherData(w.sunSunriseColor))
        table.insert(weatherTintsOld[w.index], getWeatherData(w.sunSunsetColor))
        setTint(w.sunDayColor, tintGlass)
        setTint(w.sunNightColor, nightTint)
        setTint(w.sunSunriseColor, tintGlass)
        setTint(w.sunSunsetColor, tintGlass)
        debugLog("Setting green tints for weather: ["..w.index.."]")
    end
end

local function prepareFauxAsh()
    local wO =  WtC.weathers[4]
    debugLog("Applying faux ashstorm weather.")
    setTint(wO.sunDayColor, ashValues["sunDayColor"])
    setTint(wO.fogSunsetColor, ashValues["fogSunsetColor"])
    setTint(wO.fogDayColor, ashValues["fogDayColor"])
    setTint(wO.skyNightColor, ashValues["skyNightColor"])
    setTint(wO.fogSunriseColor, ashValues["fogSunriseColor"])
    setTint(wO.ambientSunsetColor, ashValues["ambientSunsetColor"])
    setTint(wO.ambientSunriseColor, ashValues["ambientSunriseColor"])
    setTint(wO.ambientDayColor, ashValues["ambientDayColor"])
    setTint(wO.sunNightColor, ashValues["sunNightColor"])
    setTint(wO.sunSunriseColor, ashValues["sunSunriseColor"])
    setTint(wO.sunSunsetColor, ashValues["sunSunsetColor"])
    setTint(wO.sundiscSunsetColor, ashValues["sundiscSunsetColor"])
    setTint(wO.skyDayColor, ashValues["skyDayColor"])
    setTint(wO.ambientNightColor, ashValues["ambientNightColor"])
    setTint(wO.fogNightColor, ashValues["fogNightColor"])
    setTint(wO.skySunriseColor, ashValues["skySunriseColor"])
    wO.cloudTexture=ashValues["cloudTexture"]
end

local function prepareFauxBlight()
    local wO =  WtC.weathers[4]
    debugLog("Applying faux blight weather.")
    setTint(wO.sunDayColor, blightValues["sunDayColor"])
    setTint(wO.fogSunsetColor, blightValues["fogSunsetColor"])
    setTint(wO.fogDayColor, blightValues["fogDayColor"])
    setTint(wO.skyNightColor, blightValues["skyNightColor"])
    setTint(wO.fogSunriseColor, blightValues["fogSunriseColor"])
    setTint(wO.ambientSunsetColor, blightValues["ambientSunsetColor"])
    setTint(wO.ambientSunriseColor, blightValues["ambientSunriseColor"])
    setTint(wO.ambientDayColor, blightValues["ambientDayColor"])
    setTint(wO.sunNightColor, blightValues["sunNightColor"])
    setTint(wO.sunSunriseColor, blightValues["sunSunriseColor"])
    setTint(wO.sunSunsetColor, blightValues["sunSunsetColor"])
    setTint(wO.sundiscSunsetColor, blightValues["sundiscSunsetColor"])
    setTint(wO.skyDayColor, blightValues["skyDayColor"])
    setTint(wO.ambientNightColor, blightValues["ambientNightColor"])
    setTint(wO.fogNightColor, blightValues["fogNightColor"])
    setTint(wO.skySunriseColor, blightValues["skySunriseColor"])
    wO.cloudTexture=blightValues["cloudTexture"]
end

local function prepareFauxFoggy()
    local wO =  WtC.weathers[4]
    debugLog("Applying faux foggy weather.")
    setTint(wO.sunDayColor, foggyValues["sunDayColor"])
    setTint(wO.fogSunsetColor, foggyValues["fogSunsetColor"])
    setTint(wO.fogDayColor, foggyValues["fogDayColor"])
    setTint(wO.skyNightColor, foggyValues["skyNightColor"])
    setTint(wO.fogSunriseColor, foggyValues["fogSunriseColor"])
    setTint(wO.ambientSunsetColor, foggyValues["ambientSunsetColor"])
    setTint(wO.ambientSunriseColor, foggyValues["ambientSunriseColor"])
    setTint(wO.ambientDayColor, foggyValues["ambientDayColor"])
    setTint(wO.sunNightColor, foggyValues["sunNightColor"])
    setTint(wO.sunSunriseColor, foggyValues["sunSunriseColor"])
    setTint(wO.sunSunsetColor, foggyValues["sunSunsetColor"])
    setTint(wO.sundiscSunsetColor, foggyValues["sundiscSunsetColor"])
    setTint(wO.skyDayColor, foggyValues["skyDayColor"])
    setTint(wO.ambientNightColor, foggyValues["ambientNightColor"])
    setTint(wO.fogNightColor, foggyValues["fogNightColor"])
    setTint(wO.skySunriseColor, foggyValues["skySunriseColor"])
    wO.cloudTexture=foggyValues["cloudTexture"]
end

local function onCellChanged()
    local cell = tes3.getPlayerCell()
    local currentWeather = WtC.currentWeather
    local nextWeather = WtC.nextWeather
    local wO =  WtC.weathers[4]

    if not cell then return end

    if isOpenPlaza(cell)==false and lastCell and isOpenPlaza(lastCell)==true then
        debugLog("Transitioning from plaza cell.")

        if greenTint == true then
            removeGreenTint()
        end

        tes3.getSound("Rain").volume = 0.8
        tes3.getSound("rain heavy").volume = 1
        tes3.getSound("Rain").volume = 0.8
        tes3.getSound("rain heavy").volume = 1

        tes3.removeSound{sound="ashstorm", reference=tes3.mobilePlayer}
        tes3.removeSound{sound="Blight", reference=tes3.mobilePlayer}

        if not cell.isInterior then
            if lastDomeWeather == "ashstorm" then
                WtC:switchImmediate(6)
                WtC:updateVisuals()
                WtC:switchImmediate(6)
                WtC:updateVisuals()
            elseif lastDomeWeather == "Blight" then
                WtC:switchImmediate(7)
                WtC:updateVisuals()
                WtC:switchImmediate(7)
                WtC:updateVisuals()
            elseif lastDomeWeather == "Foggy" then
                WtC:switchImmediate(2)
                WtC:updateVisuals()
                WtC:switchImmediate(2)
                WtC:updateVisuals()
            end
        else
            if lastDomeWeather == "ashstorm" then
                WtC:switchImmediate(6)
            elseif lastDomeWeather == "Blight" then
                WtC:switchImmediate(7)
            elseif lastDomeWeather == "Foggy" then
                WtC:switchImmediate(2)
            end
        end

        debugLog("Reverting faux weathers.")
        setTint(wO.sunDayColor, overcastValues["sunDayColor"])
        setTint(wO.fogSunsetColor, overcastValues["fogSunsetColor"])
        setTint(wO.fogDayColor, overcastValues["fogDayColor"])
        setTint(wO.skyNightColor, overcastValues["skyNightColor"])
        setTint(wO.fogSunriseColor, overcastValues["fogSunriseColor"])
        setTint(wO.ambientSunsetColor, overcastValues["ambientSunsetColor"])
        setTint(wO.ambientSunriseColor, overcastValues["ambientSunriseColor"])
        setTint(wO.ambientDayColor, overcastValues["ambientDayColor"])
        setTint(wO.sunNightColor, overcastValues["sunNightColor"])
        setTint(wO.sunSunriseColor, overcastValues["sunSunriseColor"])
        setTint(wO.sunSunsetColor, overcastValues["sunSunsetColor"])
        setTint(wO.sundiscSunsetColor, overcastValues["sundiscSunsetColor"])
        setTint(wO.skyDayColor, overcastValues["skyDayColor"])
        setTint(wO.ambientNightColor, overcastValues["ambientNightColor"])
        setTint(wO.fogNightColor, overcastValues["fogNightColor"])
        setTint(wO.skySunriseColor, overcastValues["skySunriseColor"])
        wO.cloudTexture=overcastValues["cloudTexture"]

    end


    if isOpenPlaza(cell)==true then

        if (greenTint == true) and (lastDomeWeather~="Blight" or lastDomeWeather~="ashstorm")
        and (not string.find(cell.name:lower(), "arena pit"))
        or (greenTint == true) and (lastDomeWeather~="Blight" or lastDomeWeather~="ashstorm")
        and (not string.find(cell.name:lower(), "molag mar, plaza")) then
            applyGreenTint()
        end

        if currentWeather.index <= 5 and currentWeather.index ~= 3 then
            lastDomeWeather = "other"
            tes3.removeSound{sound="ashstorm", reference=tes3.mobilePlayer}
            tes3.removeSound{sound="Blight", reference=tes3.mobilePlayer}
            debugLog("Player outside open plaza. Removing sounds.")
        end

        if currentWeather.index == 6 or (nextWeather and nextWeather.index == 6) then
            if greenTint == true then
                removeGreenTint()
            end
            prepareFauxAsh()
            WtC:switchImmediate(3)
            tes3.playSound{sound="ashstorm", pitch=0.7, volume=0.6, loop=true, reference=tes3.mobilePlayer}
            lastDomeWeather = "ashstorm"
            debugLog("Weather switched to Ashstorm, sounds added.")
        end

        if currentWeather.index == 7 or (nextWeather and nextWeather.index == 7) then
            if greenTint == true then
                removeGreenTint()
            end
            prepareFauxBlight()
            WtC:switchImmediate(3)
            tes3.playSound{sound="Blight", pitch=0.7, volume=0.6, loop=true, reference=tes3.mobilePlayer}
            lastDomeWeather = "Blight"
            debugLog("Weather switched to Blight, sounds added.")
        end

        if currentWeather.index == 2 or (nextWeather and nextWeather.index == 2) then
            prepareFauxFoggy()
            WtC:switchImmediate(3)
            WtC:updateVisuals()
            lastDomeWeather = "Foggy"
            debugLog("Weather switched to Foggy.")
        end

    end

    lastCell=cell
end

local function onTransition()
    local cell = tes3.getPlayerCell()
    local currentWeather = WtC.currentWeather
    local nextWeather = WtC.nextWeather

    if not cell then return end

    if isOpenPlaza(cell)==true then
        debugLog("Weather transitioned to ash or blight.")

        if (greenTint == true) and (lastDomeWeather~="Blight" or lastDomeWeather~="ashstorm")
        and (not string.find(cell.name:lower(), "arena pit"))
        or (greenTint == true) and (lastDomeWeather~="Blight" or lastDomeWeather~="ashstorm")
        and (not string.find(cell.name:lower(), "molag mar, plaza")) then
            applyGreenTint()
        end

        if currentWeather.index == 6 or (nextWeather and nextWeather.index == 6) then
            if greenTint == true then
                removeGreenTint()
            end
            prepareFauxAsh()
            WtC:switchTransition(3)
            tes3.playSound{sound="ashstorm", pitch=0.7, volume=0.5, loop=true, reference=tes3.mobilePlayer}
            lastDomeWeather = "ashstorm"
            debugLog("Weather switched to Ashstorm, sounds added.")
        end

        if currentWeather.index == 7 or (nextWeather and nextWeather.index == 7) then
            if greenTint == true then
                removeGreenTint()
            end
            prepareFauxBlight()
            WtC:switchTransition(3)
            tes3.playSound{sound="Blight", pitch=0.7, volume=0.5, loop=true, reference=tes3.mobilePlayer}
            lastDomeWeather = "Blight"
            debugLog("Weather switched to Blight, sounds added.")
        end

        if currentWeather.index == 2 or (nextWeather and nextWeather.index == 2) then
            prepareFauxFoggy()
            WtC:switchImmediate(3)
            WtC:updateVisuals()
            lastDomeWeather = "Foggy"
            debugLog("Weather switched to Foggy.")
        end

    end

    lastCell=cell

end

local function onWeatherTrans(e)
    local cell = tes3.getPlayerCell()
    if isOpenPlaza(cell) then
        if (e.to.index == 3) and (lastDomeWeather~="ashstorm" or lastDomeWeather~="Blight" or lastDomeWeather~="Foggy")  then
            WtC:switchTransition(plazaWeathers[math.random(1, #plazaWeathers)])
        end
        if e.to.index <= 5 and e.to.index~=3 then
            debugLog("Resetting faux weather flags.")
            lastDomeWeather = "other"
        elseif e.to.index > 5 then
            onTransition()
        end
    end
end

local function changeFlags(e)
    local cell = tes3.getPlayerCell()
    if isOpenPlaza(cell) then
        if e.to.index <= 5 and e.to.index~=3 then
            debugLog("Resetting faux weather flags and removing sounds.")
            lastDomeWeather = "other"
            if greenTint == true and (not string.find(cell.name:lower(), "arena pit"))
            or greenTint == true and (not string.find(cell.name:lower(), "molag mar, plaza")) then
                applyGreenTint()
            end
            tes3.removeSound{sound="ashstorm", reference=tes3.mobilePlayer}
            tes3.removeSound{sound="Blight", reference=tes3.mobilePlayer}
        end
    end
end

local function getOvercastValues()
    WtC=tes3.getWorldController().weatherController
    local wO =  WtC.weathers[4]
    overcastValues["sunDayColor"] = getWeatherData(wO.sunDayColor)
    overcastValues["fogSunsetColor"] = getWeatherData(wO.fogSunsetColor)
    overcastValues["fogDayColor"] = getWeatherData(wO.fogDayColor)
    overcastValues["skyNightColor"] = getWeatherData(wO.skyNightColor)
    overcastValues["fogSunriseColor"] = getWeatherData(wO.fogSunriseColor)
    overcastValues["ambientSunsetColor"] = getWeatherData(wO.ambientSunsetColor)
    overcastValues["ambientSunriseColor"] = getWeatherData(wO.ambientSunriseColor)
    overcastValues["ambientDayColor"] = getWeatherData(wO.ambientDayColor)
    overcastValues["sunNightColor"] = getWeatherData(wO.sunNightColor)
    overcastValues["sunSunriseColor"] = getWeatherData(wO.sunSunriseColor)
    overcastValues["sunSunsetColor"] = getWeatherData(wO.sunSunsetColor)
    overcastValues["sundiscSunsetColor"] = getWeatherData(wO.sundiscSunsetColor)
    overcastValues["skyDayColor"] = getWeatherData(wO.skyDayColor)
    overcastValues["ambientNightColor"] = getWeatherData(wO.ambientNightColor)
    overcastValues["fogNightColor"] = getWeatherData(wO.fogNightColor)
    overcastValues["skySunriseColor"] = getWeatherData(wO.skySunriseColor)
    overcastValues["cloudTexture"] = wO.cloudTexture
end

local function init()
    event.register("loaded", getOvercastValues, {priority=-170})
    event.register("weatherTransitionStarted", onWeatherTrans, {priority=-170})
    event.register("cellChanged", onCellChanged, {priority=-170})
    event.register("weatherChangedImmediate", onCellChanged, {priority=-170})
    event.register("weatherTransitionFinished", changeFlags, {priority=-170})
end

event.register("initialized", init)

event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\Glass Domes\\mcm.lua")
end)