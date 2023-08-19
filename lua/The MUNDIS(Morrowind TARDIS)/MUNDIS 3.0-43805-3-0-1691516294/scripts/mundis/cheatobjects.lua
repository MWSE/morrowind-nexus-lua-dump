local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")
local myModData = storage.globalSection('MundisData')
local LocIndex = 0

local cheatObjects = {}
local cheatIds = {
    aa_light_velothi_brazier_177_ch = 1,
    mundis_man_button = 2,
    mdoor_cheat = 3,
    aa_cheatdj = 4,
    mundis_power_deposit2x = 5,
    mundis_power_est = 6,
    mundis_switch_button = 7,
    mundis_cheatshopsbutton = 8,
    aaz_crate_clothes = 9,
    mundis_cheatenable = 10,
    zhac_mundis_buttonpanel = 11,
    zhac_button_mundis_curr = 12,
    zhac_button_mundis_next = 13,
    zhac_button_mundis_prev = 14,
}
local cellData = {}
local function setCheatState(obj)
    if cheatIds[obj.recordId] and obj.cell.name ~= "MUNDIS Cheat Room" then
        local cheatState = myModData:get("enableCheats")
        if core.API_REVISION == 29 then
            if not cheatState then
                --cellData[obj.id ] = obj.cell.name
                obj:teleport("MUNDIS Hall",obj.position)
            elseif   cheatState == true then

             --   obj:teleport(  cellData[obj.id ],obj.position)
            end
            return
        else
            if cheatState == true then
                obj.enabled = true
            else
                obj.enabled = false
            end
        end
    end
end
local function onObjectActive(obj)
    if cheatIds[obj.recordId] then
        setCheatState(obj)
    end
end
local function onSave()
return {cellData = cellData}
end
local function onLoad(data)
if data then
    cellData = data.cellData
end

end
return {
    interfaceName = "MundisGlobalCheat",
    interface = {
        version = 1,
        getLocIndex = getLocIndex,
        setCheatState = setCheatState,
    },
    eventHandlers = {
        teleportMundis = teleportMundis,
        setNextDest = setNextDest,
        exitMundisFunc = exitMundisFunc,
        checkButtonText = checkButtonText,
        MUNDISInit = MUNDISInit,
        startTPTimer = startTPTimer,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onInit,
        onObjectActive = onObjectActive,
    }
}
