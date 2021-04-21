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
            --mwse.log("Found config: " .. file)

            local fileName = string.gsub(file, ".json", "")

            local MSconfig = mwse.loadConfig("MS/" .. fileName)

            local assignFolderSize = functions.checkFolder("data files/music/" .. "MS" .. "/" .. "cell" .. "/" .. MSconfig.folder, ".mp3")
            if(assignFolderSize >= 1) then --assign cell data only if folder has music

                table.insert(cellInfo, {})

                cellInfo[#cellInfo].folder = MSconfig.folder
                cellInfo[#cellInfo].priority = MSconfig.priority
                cellInfo[#cellInfo].queued = MSconfig.queued
                cellInfo[#cellInfo].cellNamePart = MSconfig.cellNamePart
                cellInfo[#cellInfo].cellNameExclude = MSconfig.cellNameExclude

                MUSE.DebugLog
                (
                    #cellInfo
                    .. "(folder)" .. cellInfo[#cellInfo].folder .. "/"
                    .. "(priority)" .. cellInfo[#cellInfo].priority .. "/"
                    .. "(queued)" .. tostring(cellInfo[#cellInfo].queued ) .. "/"
                    .. "(cellNameParts)" .. #cellInfo[#cellInfo].cellNamePart .. "/"
                    .. "(cellNameExcludes)" .. #cellInfo[#cellInfo].cellNameExclude
                )

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

    local cellPath = ""

    MUSE.DebugLog("Looking for cell music.")
    for i=1, #cellInfo do

        for e=1, #cellInfo[i].cellNameExclude do
            if(string.find(cell.id:lower(), cellInfo[i].cellNameExclude[e]:lower(), 1, true)) then
                MUSE.DebugLog("Cell name exclude found.")
                return
            end
        end

        for p=1, #cellInfo[i].cellNamePart do
            if(string.find(cell.id:lower(), cellInfo[i].cellNamePart[p]:lower(), 1, true)) then

                cellPath = musicPathCell .. cellInfo[i].folder

                if(cellInfo[i].queued == true) then
                    MUSE.QueueMusicDir(cellPath, musicTypeCell)
                    return
                end

                MUSE.SetMusicDir(cellPath, musicTypeCell)
                if(MUSE.CheckMusicDir(cellPath) == true) then
                    MUSE.ClearQueue()
                    MUSE.musicFolderSetDone = true
                    return
                end

            end
        end

    end
end

return cellMod