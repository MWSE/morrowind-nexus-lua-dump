local interiorMod = {}
--Dungeon and tileset

local MUSE = require("music.MUSE")
local functions = require("music.functions")

local hostilesFound = 0
local hostilesDeadFound = 0
local friendlyFound = 0

local musicTypeDungeon = "Dungeon"
local musicPathDungeon = "general/"
local musicFolderDungeonDefault = "Dungeon General"

local musicTypeTileset = "Tileset"
local musicPathTileset = "interior/"


---------------------------------


local tilesetInfo =
{
    folder = "",
    priority = "",
    tilesetPart = {},
    requiresHostiles = false,
    inMods = {},
    regions = {},
    combatOv = "",

    staticsFound = 0
}


---------------------------------


local function BuildTilesetTable()
    for file in lfs.dir("data files/MWSE/config/MS/") do

        if file:find("MS_t_", 1, true) and file:find("%.json$") then

			MUSE.DebugLog("Found config (tileset): " .. file)


			local fileName = string.gsub(file, ".json", "")
			local MSconfig = mwse.loadConfig("MS/" .. fileName)


			local assignFolderSize = functions.checkFolder("data files/music/" .. "MS" .. "/" .. "interior" .. "/" .. MSconfig.folder, ".mp3")
            if(assignFolderSize >= 1) then --assign tileset data only if folder has music
                table.insert(tilesetInfo, {})

                tilesetInfo[#tilesetInfo].folder = MSconfig.folder
                tilesetInfo[#tilesetInfo].priority = MSconfig.priority
                tilesetInfo[#tilesetInfo].tilesetPart = MSconfig.tilesetPart
                tilesetInfo[#tilesetInfo].staticsFound = 0

                if(MSconfig.requireHostiles ~= nil) then tilesetInfo[#tilesetInfo].requiresHostiles = MSconfig.requireHostiles
                else tilesetInfo[#tilesetInfo].requiresHostiles = false end

                if(MSconfig.inMods ~= nil) then tilesetInfo[#tilesetInfo].inMods = MSconfig.inMods end
                if(MSconfig.regions ~= nil) then tilesetInfo[#tilesetInfo].regions = MSconfig.regions end
                if(MSconfig.combatOv ~= nil) then tilesetInfo[#tilesetInfo].combatOv = MSconfig.combatOv 
                else tilesetInfo[#tilesetInfo].combatOv = "" end

				MUSE.DebugLog
				(
					#tilesetInfo .. " (folder)" .. tilesetInfo[#tilesetInfo].folder .. "/" 
					.. "(priority)" .. tilesetInfo[#tilesetInfo].priority .. "/"
                    .. "(requiresHostiles)" .. tostring(tilesetInfo[#tilesetInfo].requiresHostiles) .. "/"
                    .. "(tilesetParts)" .. #tilesetInfo[#tilesetInfo].tilesetPart
                    --.. "(inMods)" .. tilesetInfo[#tilesetInfo].inMods .. "/"
                    --.. "(regions)" .. tilesetInfo[#tilesetInfo].regions .. "/"
				)
			end

		end

	end
end

local function LookForHostiles()
    local cell = tes3.getPlayerCell()

    hostilesFound = 0
    hostilesDeadFound = 0

	--Scan for hostile actors
	if (cell.isInterior) then
		for cre in cell:iterateReferences(tes3.objectType.creature) do --Check creatures
			if(cre ~= nil and cre.mobile ~= nil) then
				if(cre.mobile.fight >= 83) then
					hostilesFound = hostilesFound + 1
					if(cre.mobile.health.current <= 0) then
						hostilesDeadFound = hostilesDeadFound +1
					end
				end
			end
        end

		for npc in cell:iterateReferences(tes3.objectType.npc) do --Check NPCs
			if(npc ~= nil and npc.mobile ~= nil) then
				if(npc.mobile.fight >= 90) then
					hostilesFound = hostilesFound + 1
					if(npc.mobile.health.current <= 0) then
						hostilesDeadFound = hostilesDeadFound +1
					end
				end
			end
		end
        MUSE.DebugLog("Hostiles/dead: " .. hostilesFound .. "/" .. hostilesDeadFound)

        --If all hostiles are dead and there are friendly npcs, it's not a dungeon
		if(hostilesFound <= hostilesDeadFound) then
			for npc in cell:iterateReferences(tes3.objectType.npc) do
				if(npc ~= nil and npc.mobile ~= nil) then
					if(npc.mobile.fight < 90) then
						hostilesFound = 0
						hostilesDeadFound = 0
						MUSE.DebugLog("Undungeoning")
						break
					end
				end
			end
		end
	end
end

local function IterateStatics(index, inmods)
    local cell = tes3.getPlayerCell()

    for sta in cell:iterateReferences(tes3.objectType.static) do
        for s=1, #tilesetInfo[index].tilesetPart do
            if (sta.id:find(tilesetInfo[index].tilesetPart[s])) then
                if(inmods ~= "") then
                    if(sta.sourceMod == inmods) then
                        tilesetInfo[index].staticsFound = tilesetInfo[index].staticsFound + 1 + tilesetInfo[index].priority
                    end
                else
                    tilesetInfo[index].staticsFound = tilesetInfo[index].staticsFound + 1 + tilesetInfo[index].priority
                end
            end
        end
    end
end


local regionChecked = false

local function ScanTileset()
    local cell = tes3.getPlayerCell()

    for i=1, #tilesetInfo do
        if(tilesetInfo[i].regions ~= nil) then
            for r=1, #tilesetInfo[i].regions do
                if (MUSE.regionCurrent == tilesetInfo[i].regions[r]) then
                    regionChecked = true
                end
            end
            if(regionChecked == false) then break end
        end

        --Check statics from mods required
        if(tilesetInfo[i].inMods ~= nil) then
            for m=1, #tilesetInfo[i].inMods do
                IterateStatics(i, tilesetInfo[i].inMods[m])
            end
        end

        ----------

        --Check statics no mod required
        if(tilesetInfo[i].inMods == nil) then
            IterateStatics(i, "")
        end

        MUSE.DebugLog("Tileset scanned, " .. tilesetInfo[i].folder .. "/" .. tilesetInfo[i].staticsFound)

        regionChecked = false
    end
end

local function TilesetInfoClean() --Clear after scanning
    for s=1, #tilesetInfo do
		tilesetInfo[s].staticsFound = 0
	end
end


---------------------------------


local function TilesetMusic()
    MUSE.DebugLog("Looking for automatic tileset music.")

    if(MUSE.tilesetDisabledCurrent ~= true) then
        local pathTileset = ""
        MUSE.DebugLog("Scanning tileset...")
        ScanTileset()

        table.sort(tilesetInfo, function( a, b ) return a.staticsFound > b.staticsFound end)

        if(tilesetInfo[1].staticsFound == 0) then
            MUSE.DebugLog("Nothing in main tileset...")
            return
        end

        if(tilesetInfo[1].requiresHostiles == true) then
            LookForHostiles()
            if(hostilesFound == 0) then TilesetInfoClean() return end
        end

        pathTileset = musicPathTileset .. tilesetInfo[1].folder

        MUSE.DebugLog("Found tileset, " .. pathTileset)

        MUSE.SetMusicDir(pathTileset, musicTypeTileset)
        if(MUSE.CheckMusicDir(pathTileset) == true) then
            MUSE.ClearQueue()
            TilesetInfoClean()
            MUSE.musicFolderSetDone = true
            return
        end
        TilesetInfoClean()
    end
end

local function DungeonMusic()
    MUSE.DebugLog("Looking for automatic dungeon music.")
    LookForHostiles()

    local pathDungeon = ""
    if(MUSE.dungeonOvCurrent == "") then
        pathDungeon = musicPathDungeon .. musicFolderDungeonDefault
    else
        pathDungeon = musicPathDungeon .. MUSE.dungeonOvCurrent .. "/"
        if(MUSE.CheckMusicDir(pathDungeon) == false) then pathDungeon = musicPathDungeon .. musicFolderDungeonDefault end
    end

    if(hostilesFound > 0) then
        MUSE.SetMusicDir(pathDungeon, musicTypeDungeon)
        if(MUSE.CheckMusicDir(pathDungeon) == true) then
            MUSE.ClearQueue()
            MUSE.musicFolderSetDone = true
            return end
    end
end


---------------------------------


function interiorMod.OnInitalize()
    BuildTilesetTable()
end

function interiorMod.OnCellEnter()
	---------
	if(MUSE.musicFolderSetDone == true) then
        return
    end

    local cell = tes3.getPlayerCell()
	if (cell.isInterior == false) then return end

    TilesetMusic()
    if(MUSE.musicFolderSetDone == true) then return end
    DungeonMusic()

end

return interiorMod