local regionMod = {}

local MUSE = require("music.MUSE")
local functions = require("music.functions")

local musicPathRegion = "region/"
local musicTypeRegion = "Region"

---------------------------------


local function BuildRegionalOverridesTable()
    for file in lfs.dir("data files/MWSE/config/MS/") do

        if file:find("MS_r_", 1, true) and file:find("%.json$") then
            MUSE.DebugLog("Found config (region): " .. file)

            local fileName = string.gsub(file, ".json", "")
            local MSconfig = mwse.loadConfig("MS/" .. fileName)

            if MSconfig and MSconfig.folder then
				local fullPath = "Data Files/Music/MS/region/" .. MSconfig.folder
                local assignFolderSize = functions.checkFolder(fullPath, ".mp3")
                if(assignFolderSize >= 1) then --assign region data only if folder has music

                    if (#MSconfig.regionName > 0) then
                        for namePart in pairs(MSconfig.regionName) do
                            table.insert(MUSE.regionInfo, {})
                            MUSE.regionInfo[#MUSE.regionInfo].musicFolder = MSconfig.folder
                            MUSE.regionInfo[#MUSE.regionInfo].regionName = MSconfig.regionName[namePart]

                            MUSE.DebugLog
                            (
                                #MUSE.regionInfo
                                .. "(folder)" .. MUSE.regionInfo[#MUSE.regionInfo].musicFolder .. "/" 
                                .. "(regionName)" .. MUSE.regionInfo[#MUSE.regionInfo].regionName
                            )
                        end
                    end
                else
					MUSE.DebugLog("Custom folder " .. fullPath .. " is empty or does not exist. Cannot use override.")
                end
            else
                mwse.log("[MUSE] Config file " .. fileName .. " is not valid json. It has been skipped.")
            end

        end

    end
end

local function BuildGeneralOverridesTable()
    for file in lfs.dir("data files/MWSE/config/MS/") do

        if file:find("MS_o_", 1, true) and file:find("%.json$") then

            MUSE.DebugLog("Found config (general override): " .. file)

            local fileName = string.gsub(file, ".json", "")
            local MSconfig = mwse.loadConfig("MS/" .. fileName)

            if MSconfig and MSconfig.regionName then

                for i=1, #MSconfig.regionName do
                    local index = 0

                    for o=1, #MUSE.regionInfo do --Check if region override definiton already exists

                        if(MUSE.regionInfo[o].regionName == MSconfig.regionName[i]) then

                            index = o
                        end

                    end

                    if(index == 0) then
                        table.insert(MUSE.regionInfo, {})
                        index = #MUSE.regionInfo

                        MUSE.regionInfo[index].musicFolder = ""
                        MUSE.regionInfo[index].regionName = MSconfig.regionName[i]
                    end

                    --------
                    if(MSconfig.dungeonFolder ~= nil) then MUSE.regionInfo[index].dungeonOv = MSconfig.dungeonFolder
                    else MUSE.regionInfo[index].dungeonOv = "" end

                    if(MSconfig.dungeonDisable ~= nil) then
                        if(MSconfig.dungeonDisable == true) then MUSE.regionInfo[index].dungeonOv = "disabled" end
                    end

                    --------
                    if(MSconfig.combatFolder ~= nil) then MUSE.regionInfo[index].combatOv = MSconfig.combatFolder
                        else MUSE.regionInfo[index].combatOv = "" end
                    if(MSconfig.combatDisable ~= nil) then MUSE.regionInfo[index].combatDisabled = MSconfig.combatDisable
                        else MUSE.regionInfo[index].combatDisabled = false end

                    --------
                    if(MSconfig.airFolder ~= nil) then MUSE.regionInfo[index].airOv = MSconfig.airFolder
                        else MUSE.regionInfo[index].airOv = "" end
                    if(MSconfig.depthsFolder ~= nil) then MUSE.regionInfo[index].depthsOv = MSconfig.depthsFolder
                        else MUSE.regionInfo[index].depthsOv = "" end

                    --------
                    if(MSconfig.tilesetDisable ~= nil) then MUSE.regionInfo[index].tilesetDisabled = MSconfig.tilesetDisable
                        else MUSE.regionInfo[index].tilesetDisabled = false end

                    --------
                    if(MSconfig.queued ~= nil) then MUSE.regionInfo[index].queued = MSconfig.queued
                        else MUSE.regionInfo[index].queued = false end

                    if(MSconfig.queuedList ~= nil) then MUSE.regionInfo[index].queuedList = MSconfig.queuedList
                    else MUSE.regionInfo[index].queuedList = {region = true, cell = true, dungeon = false, tileset = false} end

                    MUSE.DebugLog
                    (
                        index .. " (folder)" .. MUSE.regionInfo[index].musicFolder .. "/" 
                        .. "(regionName)" .. MUSE.regionInfo[index].regionName .. "/"
                        .. "(dungeonOv)" .. MUSE.regionInfo[index].dungeonOv .. "/"
                        .. "(combatOV)" .. MUSE.regionInfo[index].combatOv .. "/"
                        .. "(airOv)" .. MUSE.regionInfo[index].airOv .. "/"
                        .. "(depthsOv)" .. MUSE.regionInfo[index].depthsOv .. "/"
                        .. "(tilesetDisabled)" .. tostring(MUSE.regionInfo[index].tilesetDisabled) .. "/"
                        .. "(queued)" .. tostring(MUSE.regionInfo[index].queued) .. "/"
                        .. string.format("(queuedList) '%s'/'%s'/'%s'/'%s'",
                        tostring(MUSE.regionInfo[index].queuedList.region),tostring(MUSE.regionInfo[index].queuedList.cell)
                        ,tostring(MUSE.regionInfo[index].queuedList.dungeon),tostring(MUSE.regionInfo[index].queuedList.tileset))
                    )
                end
            else
                mwse.log("[MUSE] Config file " .. fileName .. " is not valid json. It has been skipped.")
            end

        end

    end
end


---------------------------------


function regionMod.OnInitalize()
    BuildRegionalOverridesTable()
    BuildGeneralOverridesTable()
end

function regionMod.OnCellEnter()
    ---------
    if(MUSE.musicFolderSetDone == true) then
        return
    end
    ---------

    local cell = tes3.getPlayerCell()

    if(tes3.getRegion() ~= nil) then
        MUSE.regionCurrent = tes3.getRegion().name
    else
        MUSE.regionCurrent = "No region"
    end

    ---------
    --Region auto name
    MUSE.DebugLog("Looking for automatic region music.")
    MUSE.DebugLog("Current region: " .. MUSE.regionCurrent)

    local overridesFound = false
    --Assign general overrides
    for i=1, #MUSE.regionInfo do
        if(MUSE.regionCurrent == MUSE.regionInfo[i].regionName) then

            if (MUSE.regionInfo[i].dungeonOv ~= "" and MUSE.regionInfo[i].dungeonOv ~= nil) then MUSE.dungeonOvCurrent = MUSE.regionInfo[i].dungeonOv else MUSE.dungeonOvCurrent = "" end
            if (MUSE.regionInfo[i].tilesetDisabledCurrent ~= nil) then  MUSE.tilesetDisabledCurrent = MUSE.regionInfo[i].tilesetDisabled end
            if (MUSE.regionInfo[i].combatOv ~= "" and MUSE.regionInfo[i].combatOv ~= nil) then MUSE.combatOvCurrent = MUSE.regionInfo[i].combatOv else MUSE.combatOvCurrent = "" end
            if (MUSE.regionInfo[i].airOv ~= "" and MUSE.regionInfo[i].airOv ~= nil) then MUSE.airOvCurrent = MUSE.regionInfo[i].airOv else MUSE.airOvCurrent = "" end
            if (MUSE.regionInfo[i].depthsOv ~= "" and MUSE.regionInfo[i].depthsOv ~= nil) then MUSE.depthsOvCurrent = MUSE.regionInfo[i].depthsOv else MUSE.depthsOvCurrent = "" end
            if (MUSE.regionInfo[i].combatDisabled ~= nil) then  MUSE.combatDisable = MUSE.regionInfo[i].combatDisabled end
            MUSE.DebugLog
            (
                "Region overrides detected (regionName)" .. MUSE.regionInfo[i].regionName .. "/"
                .. "(dungeonOv)" .. tostring(MUSE.regionInfo[i].dungeonOv) .. "/"
                .. "(combatOV)" .. tostring(MUSE.combatOvCurrent) .. "/"
                .. "(airOv)" .. tostring(MUSE.airOvCurrent) .. "/"
                .. "(depthsOv)" .. tostring(MUSE.depthsOvCurrent) .. "/"
                .. "(tilesetDisabled)" .. tostring(MUSE.regionInfo[i].tilesetDisabled) .. "/"
            )
            overridesFound = true
        end
    end

    --Clear overrides
    if(overridesFound == false) then
        MUSE.combatOvCurrent = "" MUSE.dungeonOvCurrent = "" MUSE.airOvCurrent = "" MUSE.depthsOvCurrent = "" MUSE.tilesetDisabledCurrent = false MUSE.combatDisable = false
    end

    overridesFound = false

    local pathRegionAuto = musicPathRegion .. MUSE.regionCurrent

    if(MUSE.settingsConfig.regionQueue == true) then MUSE.QueueMusicDir(pathRegionAuto, musicTypeRegion)
    else MUSE.SetMusicDir(pathRegionAuto, musicTypeRegion) end
    if(MUSE.CheckMusicDir(pathRegionAuto) == true) then

        MUSE.musicFolderSetDone = true
        return
    end

    ---------
    --Region override
    MUSE.DebugLog("Looking for regional override music.")

    for i=1, #MUSE.regionInfo do
        if(MUSE.regionCurrent == MUSE.regionInfo[i].regionName) then
            local pathRegionOv = musicPathRegion .. MUSE.regionInfo[i].musicFolder

            if(MUSE.settingsConfig.regionQueue == true) then MUSE.QueueMusicDir(pathRegionOv, musicTypeRegion)
            else MUSE.SetMusicDir(pathRegionOv, musicTypeRegion) end

            if(MUSE.CheckMusicDir(pathRegionOv) == false) then
                return
            end

            MUSE.musicFolderSetDone = true
            return
        end
    end

    ---------
    --Vanilla

    if(MUSE.settingsConfig.regionQueue == true) then MUSE.QueueMusicDir("Explore", musicTypeRegion)
    else MUSE.SetMusicDir("Explore", musicTypeRegion) end

    MUSE.musicFolderSetDone = true
end

return regionMod