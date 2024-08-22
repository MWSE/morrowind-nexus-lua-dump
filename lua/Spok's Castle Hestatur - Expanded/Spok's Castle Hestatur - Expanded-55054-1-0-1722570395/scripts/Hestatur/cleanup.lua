local list = require("scripts.Hestatur.cellList")
local world = require("openmw.world")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")
local extList = {

    "Esm3ExteriorCell:6:26",
    "Esm3ExteriorCell:5:26",
    "Esm3ExteriorCell:6:25",
}
local function checkSuffixAndPrefix(suffix, mainString)
    -- Check if the suffix ends with '*'
    if string.sub(suffix, -1) == '*' then
        -- Remove the '*' from the suffix for comparison
        suffix = string.sub(suffix, 1, -2)
    end

    -- Check if the mainString starts with the modified suffix
    if suffix == mainString then
        return true
    end
    if string.sub(mainString, 1, string.len(suffix)) == suffix then
        return true
    else
        return false
    end
end
local cleanedCells = {}
local initCells = {}
local cleanupState = false --no need for clean up yet.
local daedraList = {
    "winged twilight",
    "scamp",
    "hunger",
    "golden saint",
    "dremora",
    "zhac_hestatur_dremora",
    "zhac_hestatur_bonewalke",
    "zhac_hestatur_dremgen_*",
   -- "ab_dae_darkseducer",
    "daedroth"
}
local objList = {
    "zhac_hest_pre_*",
    "zhac_forcefield_*",
    "ex_dae_*",
    "light_dae_*",
    "zhac_hestatur_redwall",
    "zhac_hestatur_daedramarker",
    "ab_in_daecolumn02",
    "zhac_wall_invis",
    "ab_furn_6thrug*",
    "ab_furn_dae*",
    "sound_daedric_chant00",
    "dead random male",
    "dead random female",
}
local function isCastleFree()
    return cleanupState
end
local function listContains(list, value)
    for index, objListItem in ipairs(list) do
        if objListItem == value then
            return true
        end
    end
    return false
end
local function getObjInCell(cell, id)
    for index, value in ipairs(cell:getAll()) do
        if value.recordId == id then
            return value
        end
    end
end
local magedata = {
    {"iniel",	"sadrith mora, wolverine hall: mage's guild"},
    {"erranil",	"Ald-ruhn, Guild of Mages"},
    {"masalinie merian",	"Balmora, Guild of Mages"},
    {"emelia duronia",	"Caldera, Guild of Mages"},
    {"flacassia fauseius",	"Vivec, Guild of Mages"}
}
local function magesSwap()
    for index, value in ipairs(magedata) do
        local npc = value[1]
        local cellId = value[2]
        local cell = world.getCellById(cellId)
        local npcObj = getObjInCell(cell, npc)
        if npcObj then
            local newActor = world.createObject(npc .. "_hest")
            newActor:teleport(cell, npcObj.position, npcObj.rotation)
            npcObj:remove()
            print('swapped')
        end
    end
end
local function cleanupCell(cellId)
    local cell = world.getCellById(cellId)

    for index, obj in ipairs(cell:getAll()) do

            for i, objListItem in ipairs(objList) do
                if obj.recordId == "zhac_hestat_cube_activat" then
                elseif checkSuffixAndPrefix(objListItem, obj.recordId:lower()) then
                    obj:remove()
                else

                end
            end
            for i, objListItem in ipairs(daedraList) do
                if checkSuffixAndPrefix(objListItem, obj.recordId:lower()) then
                    obj:remove()

                end
            end
    end
    cleanedCells[cellId] = true
end
local function onCellChange_Hest(cellId)
    if listContains(list, cellId) then
        if cleanupState and not cleanedCells[cellId] then
            if listContains(extList, cellId) then
                for index, value in ipairs(extList) do
                    cleanupCell(value)
                end
            else
                cleanupCell(cellId)
                initCells[cellId] = true
                core.sendGlobalEvent("reEnableAllLayers", cellId)
                core.sendGlobalEvent("turnCellLightsOn_Hest", cellId)
            end
        elseif cleanupState and cleanedCells[cellId] and not I.Hestatur_Light.getCellLightState(cellId) == true then
            initCells[cellId] = true
            cleanupCell(cellId)
            core.sendGlobalEvent("reEnableAllLayers", cellId)
            core.sendGlobalEvent("turnCellLightsOn_Hest", cellId)
        end
        if not initCells[cellId] and not cleanupState then
            initCells[cellId] = true
            core.sendGlobalEvent("setLayerInCellToDefault", cellId)
            core.sendGlobalEvent("turnCellLightsOff_Hest", cellId)
        end
    end
end
local function runCleanUp(enableLayers)
    cleanupState = true
    local player = world.players[1]
    if player then
        cleanupCell(player.cell.id)
    end
    for index, value in ipairs(list) do
        -- core.sendGlobalEvent("turnCellLightsOn_Hest",value)
    end
    if enableLayers then
        for index, value in ipairs(list) do
            core.sendGlobalEvent("reEnableAllLayers", value)
        end
    end
end

return {
    interfaceName = "cleanup",
    interface = {
        isCastleFree = isCastleFree,
        cleanupCell = cleanupCell,
    },
    eventHandlers = {
        runCleanUp = runCleanUp,
        magesSwap = magesSwap,
        onCellChange_Hest = onCellChange_Hest,
    },
    engineHandlers = {
        onSave = function()
            return { cleanedCells = cleanedCells, initCells = initCells, cleanupState = cleanupState, }
        end,
        onLoad = function(data)
            if not data then
                return
            end
            cleanupState = data.cleanupState
            cleanedCells = data.cleanedCells
            initCells = data.initCells
        end

    }

}
