local data = require("tew.AURA.Ambient.Interior.interiorData")
local config = require("tew.AURA.config")
local sounds = require("tew.AURA.sounds")
local common = require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local findWholeWords = tewLib.findWholeWords
local intVol = config.intVol/200
local interiorMusic = config.interiorMusic

local played = false
local musicPath, lastMusicPath
local moduleName = "interior"
local debugLog = common.debugLog

local disabledTaverns = config.disabledTaverns
local function isEnabled(cellName)
    if disabledTaverns[cellName] and disabledTaverns[cellName] == true then
        return false
    else
        return true
    end
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

local function getPopulatedCell(maxCount, cell)
    local count = 0
    for npc in cell:iterateReferences(tes3.objectType.NPC) do
        if (npc.object.mobile) and (not npc.object.mobile.isDead) then
            count = count + 1
        end
        if count >= maxCount then --[[debugLog("Enough people in a cell. Count: "..count)]] return true end
    end
    if count < maxCount then --[[debugLog("Too few people in a cell. Count: "..count)]] return false end
end

local musicArrays = {
    ["imp"] = {},
    ["dar"] = {},
    ["nor"] = {},
}

local function playMusic()
    if not interiorMusic then return end
    lastMusicPath = musicPath
    --debugLog("Playing music track: "..musicPath)
    tes3.streamMusic{
        path = musicPath,
        --crossfade = 0,
    }
    played = true
end

for folder in lfs.dir("Data Files\\Music\\tew\\AURA") do
    if folder ~= "Special" then
        for soundfile in lfs.dir("Data Files\\Music\\tew\\AURA\\"..folder) do
            if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".mp3") then
                table.insert(musicArrays[folder], soundfile)
                debugLog("Adding music file: "..soundfile)
            end
        end
    end
end

local function onMusicSelection()
    local cell = tes3.getPlayerCell()

    if not (cell) or not (cell.isInterior) or not (cell.name) or (cell.behavesAsExterior) then return end

    if not isEnabled(cell.name) then debugLog("Tavern blacklisted: "..cell.name..". Returning.") return end

    if getPopulatedCell(3, cell) == false then return end

    for race, _ in pairs(data.tavernNames) do
        for _, pattern in ipairs(data.tavernNames[race]) do
            if string.find(cell.name, pattern) then
                while musicPath == lastMusicPath do
                    musicPath = "tew\\AURA\\"..race.."\\"..musicArrays[race][math.random(1, #musicArrays[race])]
                end
                playMusic()
                return
            end
        end
    end

    for npc in cell:iterateReferences(tes3.objectType.npc) do
        if (npc.object.class.id == "Publican"
        or npc.object.class.id == "T_Sky_Publican"
        or npc.object.class.id == "T_Cyr_Publican")
        and (npc.object.mobile and not npc.object.mobile.isDead) then

            local race = npc.object.race.id
            if race ~= "Imperial"
            and race ~= "Nord"
            and race ~= "Dark Elf" then
                race = "Dark Elf"
            end

            race = string.sub(race, 1, 3):lower()

            while musicPath == lastMusicPath do
                musicPath = "tew\\AURA\\"..race.."\\"..musicArrays[race][math.random(1, #musicArrays[race])]
            end

            playMusic()
            return
        end
    end

end

local function cellCheck()

    if interiorMusic then
        onMusicSelection()
    end

	-- Gets messy otherwise
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		debugLog("Player waiting or travelling. Returning.")
		timer.start{
			duration = 1,
			callback = cellCheck,
		}
		return
	end

    local cell = tes3.getPlayerCell()

    if not (cell) or (cell.isOrBehavesAsExterior) then
        debugLog("Exterior cell. Removing sound.")
        sounds.removeImmediate{module = moduleName}
        if interiorMusic and played == true then
            debugLog("Removing music.")
            tes3.streamMusic {
                path = "tew\\AURA\\Special\\silence.mp3",
            }
            played = false
        end
        return
    end

    sounds.removeImmediate{module = moduleName}

    -- First check if the cell type can be determined by architecture
    local typeCell = getTypeCell(5, cell)
    if typeCell ~= nil then
        debugLog("Found appropriate cell. Playing interior ambient sound.")
        sounds.playImmediate{module = moduleName, type = typeCell, volume = intVol}
        return
    end

    -- A little override to ensure that taverns with non-native publicans get covered too
    if getPopulatedCell(2, cell) == false then debugLog ("Too few people in a cell. Returning.") return end
    for race, taverns in pairs(data.tavernNames) do
        for _, pattern in ipairs(taverns) do
            if string.find(cell.name, pattern) then
                debugLog("Found appropriate tavern. Playing interior ambient sound for race type: "..race)
                sounds.playImmediate{module = moduleName, race = race, volume = intVol}
                return
            end
        end
    end

    -- If at this point there's no-one inside, let's bail out
    if getPopulatedCell(1, cell) == false then debugLog ("Too few people in a cell. Returning.") return end

    -- Now performing pattern match for cell names
    for cellType, nameTable in pairs(data.names) do
        for _, pattern in pairs(nameTable) do
            if findWholeWords(cell.name, pattern) then
                debugLog("Found appropriate cell. Playing interior ambient sound for interior type: "..cellType)
                sounds.playImmediate{module = moduleName, type = cellType, volume = intVol}
                return
            end
        end
    end

    -- Determine tavern type per race
    for npc in cell:iterateReferences(tes3.objectType.npc) do
        if (npc.object.class.id == "Publican"
        or npc.object.class.id == "T_Sky_Publican"
        or npc.object.class.id == "T_Cyr_Publican")
        and (npc.object.mobile and not npc.object.mobile.isDead) then

            local race = npc.object.race.id
            if race ~= "Imperial"
            and race ~= "Nord"
            and race ~= "Dark Elf" then
                race = "Dark Elf"
            end
            race = string.sub(race, 1, 3):lower()
            debugLog("Found appropriate tavern. Playing interior ambient sound for race type: "..race)

            sounds.playImmediate{module = moduleName, race = race, volume = intVol}
            return
        end
    end

    debugLog("No appropriate cell detected. Removing sounds.")
    sounds.removeImmediate{module = moduleName}
end

-- Make sure any law-breakers, murderes and maniacs are covered
-- Meaning the death of a publican means we recheck conditions
local function deathCheck(e)
    if e.reference and e.reference.baseObject == tes3.objectType.npc
    and (e.reference.object.class.id == "Publican"
    or  e.reference.object.class.id == "T_Sky_Publican"
    or  e.reference.object.class.id == "T_Cyr_Publican") then
        cellCheck()
        if interiorMusic then
            onMusicSelection()
        end
    end
end

local function onCOC()
	-- sounds.removeImmediate{module = moduleName}
    cellCheck()
end


event.register("cellChanged", cellCheck, { priority = -200 })
event.register("weatherTransitionImmediate", onCOC, {priority=-160})
event.register("weatherChangedImmediate", onCOC, {priority=-160})
event.register("death", deathCheck)
if interiorMusic then
    event.register("musicSelectTrack", onMusicSelection)
end