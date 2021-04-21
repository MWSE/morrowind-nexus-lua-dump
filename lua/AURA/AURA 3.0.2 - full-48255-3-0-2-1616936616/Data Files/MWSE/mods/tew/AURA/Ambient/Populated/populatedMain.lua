local data = require("tew\\AURA\\Ambient\\Populated\\populatedData")
local config = require("tew\\AURA\\config")
local debugLogOn = config.debugLogOn
local modversion = require("tew\\AURA\\version")
local version = modversion.version
local popVol = config.popVol/200
local popDir = "tew\\AURA\\Populated\\"
local path, playedFlag, time, timeLast, typeCellLast

local function debugLog(string)
    if debugLogOn then
       mwse.log("[AURA "..version.."] PA: "..string.format("%s", string))
    end
end

local arrays = {
    ["Ashlander"] = {},
    ["Daedric"] = {},
    ["Dark Elf"] = {},
    ["Dwemer"] = {},
    ["Imperial"] = {},
    ["Nord"] = {},
    ["Night"] = {}
}

local function getPopulatedCell(maxCount, cell)
    local count = 0
    for npc in cell:iterateReferences(tes3.objectType.NPC) do
        if (npc.object.mobile) and (not npc.object.mobile.isDead) then
            count = count + 1
        end
        if count >= maxCount then debugLog("Enough people in a cell. Count: "..count) return true end
    end
    if count < maxCount then debugLog("Too few people in a cell. Count: "..count) return false end
end

local function getTypeCell(maxCount, cell)
    local count = 0
    local typeCell
    for stat in cell:iterateReferences(tes3.objectType.static) do
        for cellType, typeArray in pairs(data.statics) do
            for _, statName in ipairs(typeArray) do
                if string.startswith(stat.object.id:lower(), statName) then
                    count = count + 1
                    typeCell = cellType
                    if count >= maxCount then debugLog("Enough statics. Cell type: "..typeCell) return typeCell end
                end
            end
        end
    end
    if count == 0 then debugLog("Too few statics. Count: "..count) return nil end
end

local function playPopulated()
    timer.start{duration=0.86, type=timer.real, callback=function()
        playedFlag = 1
        debugLog("Playing populated track: "..path)
        tes3.playSound{
        soundPath = path,
        reference = tes3.player,
        volume = 1.0*popVol,
        loop=true
        }
    end}
end

for populatedType, _ in pairs(arrays) do
    for soundfile in lfs.dir("Data Files\\Sound\\"..popDir.."\\"..populatedType) do
        if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".wav") then
            table.insert(arrays[populatedType], soundfile)
            debugLog("Adding populated file: "..soundfile)
        end
    end
end

local function cellCheck()
    local cell = tes3.getPlayerCell()

    if (not cell) or (not cell.name) or (cell.isInterior and not cell.behavesAsExterior and not string.find(cell.name, "Plaza")) then
        debugLog("Player in interior cell or in the wilderness. Returning.")
        if playedFlag == 1 then
            timer.start{duration=0.82, type=timer.real, callback=function()
                debugLog("Inappropriate cell. Removing sounds.")
                tes3.removeSound{reference = tes3.player}
                timeLast = nil
                playedFlag = 0
            end}
        end
        playedFlag = 0
        return
    end

    if not config.moduleAmbientInterior then
        if playedFlag == 1 then
            timer.start{duration=0.82, type=timer.real, callback=function()
                debugLog("Not using IA module. Removing sounds.")
                tes3.removeSound{reference = tes3.player}
                timeLast = nil
                playedFlag = 0
            end}
        end
    end

    local gameHour=tes3.worldController.hour.value
    if gameHour < 6 or gameHour > 21 then time = "Night"
    else time = "Day" end

    local typeCell = getTypeCell(5, cell)

    if typeCell == typeCellLast
    and time == timeLast then
        debugLog("Same conditions. Returning.")
        return
    end

    if playedFlag == 1 then
        timer.start{duration=0.82, type=timer.real, callback=function()
            debugLog("Different time. Removing sounds.")
            tes3.removeSound{reference = tes3.player}
            timeLast = nil
            playedFlag = 0
        end}
    end

    if typeCell ~= nil and getPopulatedCell(3, cell) == true then
        if typeCell~="Daedric" and
        typeCell~="Dwemer" and
        time == "Night" then
            debugLog("Found appropriate cell at night. Playing populated night ambient sound.")
            path = popDir.."\\Night\\"..arrays["Night"][math.random(1, #arrays["Night"])]
            playPopulated()
            timeLast = time
            typeCellLast = typeCell
            playedFlag = 1
            return
        else
            debugLog("Found appropriate cell at day. Playing populated ambient day sound.")
            path = popDir..typeCell.."\\"..arrays[typeCell][math.random(1, #arrays[typeCell])]
            playPopulated()
            timeLast = time
            typeCellLast = typeCell
            playedFlag = 1
            return
        end
    end

    playedFlag = 0
    debugLog("No appropriate cell detected.")
end

local function populatedTimer()
    timeLast = nil
    typeCellLast = nil
    timer.start({duration=0.5, callback=cellCheck, iterations=-1, type=timer.game})
end


event.register("cellChanged", cellCheck, { priority = -190 })
event.register("loaded", populatedTimer)

