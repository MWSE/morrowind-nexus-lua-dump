local cellMod = {}

local MUSE = require("music.MUSE")
local functions = require("music.functions")

local cellInfo =
{
    folder = "",
    priority = 0,
    queued = false,
    cellNamePart = {},
    cellNameExclude = {}
}

local musicPathCell = "cell/"
local musicTypeCell = "cell"

---------------------------------


local function BuildCellTable()
    for file in lfs.dir("data files/MWSE/config/MS/") do
	
        if file:find("MS_c_", 1, true) and file:find("%.json$") then
            MUSE.DebugLog("Found config (cell): " .. file)

            local fileName = string.gsub(file, ".json", "")
            local MSconfig = mwse.loadConfig("MS/" .. fileName)
            
            if MSconfig and MSconfig.folder then
				local fullPath = "Data Files/Music/MS/cell/" .. MSconfig.folder
                local assignFolderSize = functions.checkFolder(fullPath, ".mp3")
                if(assignFolderSize >= 1) then --assign cell data only if folder has music

                    table.insert(cellInfo, {})

                    local info = cellInfo[#cellInfo]
                    info.folder = MSconfig.folder
                    info.priority = MSconfig.priority
                    info.queued = MSconfig.queued
                    info.cellNamePart = MSconfig.cellNamePart
                    info.cellNameExclude = MSconfig.cellNameExclude
					info.cancelOnExit = MSconfig.cancelOnExit

                    for i=1,#info.cellNamePart do
                        info.cellNamePart[i] = info.cellNamePart[i]:lower()
                    end
                    for i=1,#info.cellNameExclude do
                        info.cellNameExclude[i] = info.cellNameExclude[i]:lower()
                    end
                    
                    MUSE.DebugLog
                    (
                        #cellInfo
                        .. "(folder)" .. info.folder .. "/"
                        .. "(priority)" .. info.priority .. "/"
                        .. "(queued)" .. tostring(info.queued) .. "/"
                        .. "(cellNameParts)" .. #info.cellNamePart .. "/"
                        .. "(cellNameExcludes)" .. #info.cellNameExclude
                    )
                else
					MUSE.DebugLog("Custom folder " .. fullPath .. " is empty or does not exist. Cannot use override.")
                end
            else
                mwse.log("[MUSE] Config file " .. fileName .. " is not valid json. It has been skipped.")
            end
        end
    end

    table.sort(cellInfo, function( a, b ) return a.priority > b.priority end)
end


---------------------------------


function cellMod.OnInitalize()
    BuildCellTable()
end

function cellMod.OnCellEnter()
    ---------
    if(MUSE.musicFolderSetDone == true) then
        return
    end
    ---------

    local cell = tes3.getPlayerCell()
    local cell_id_casefold = cell.id:lower()
    local cellPath = ""

    MUSE.DebugLog("Looking for cell music for: " .. cell.id)
    for _, info in ipairs(cellInfo) do

		local notExcluded = true
        for _, exclude in ipairs(info.cellNameExclude) do
            if(string.find(cell_id_casefold, exclude, 1, true)) then
                MUSE.DebugLog("Cell name exclude found.")
				notExcluded = false
				break
            end
        end

		if notExcluded then
			for _, namePart in ipairs(info.cellNamePart) do
				if(string.find(cell_id_casefold, namePart, 1, true)) then

					cellPath = musicPathCell .. info.folder

					local musicType = musicTypeCell
					if info.cancelOnExit then
						musicType = "cell_low_priority"
					end
					
					if(info.queued == true) then
						MUSE.QueueMusicDir(cellPath, musicType)
						return
					end

					MUSE.SetMusicDir(cellPath, musicType)
					if(MUSE.CheckMusicDir(cellPath) == true) then
						MUSE.ClearQueue()
						MUSE.musicFolderSetDone = true
						return
					end

				end
			end
		end

    end
end

return cellMod