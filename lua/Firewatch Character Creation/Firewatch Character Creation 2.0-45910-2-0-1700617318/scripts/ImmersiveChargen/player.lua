local ui       = require("openmw.ui")
local input    = require("openmw.input")
local I        = require("openmw.interfaces")
local core     = require("openmw.core")
local nearby   = require("openmw.nearby")
local self     = require("openmw.self")
local types  = require('openmw.types')
local ambient  = require('openmw.ambient')
local _, async = pcall(require, "openmw.async")
local function showMessageICG(message)
    ui.showMessage(message)
end
if types.Player.isCharGenFinished(self) then
    return
end
local function enableControlsICG(state)
    if state == nil then
        state = true
    end
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, state)
end
local function enableCameraControlsICG()
    types.Player.setControlSwitch(self,input.CONTROL_SWITCH.ViewMode, true)
    types.Player.setControlSwitch(self,input.CONTROL_SWITCH.VanityMode, true)
    types.Player.setControlSwitch(self,input.CONTROL_SWITCH.Jumping, true)
end
local function removeNumbers(obj)
    local hexString = obj.id
    local pattern = "0x%x+0"                             -- Match the hexadecimal part between '0x' and '0'
    local result = string.gsub(hexString, pattern, "0x") -- Replace the matched pattern with "0x"
    local test = core.getFormId(obj.contentFile, tonumber(result))
    if not nearby.getObjectByFormId(test):isValid() then
        error("Got invalid ID: " .. test)
    end
    core.sendGlobalEvent("setDisabledDebug",{object = obj,state = false})
    return "{\"" .. (result or
            hexString) ..
        "\", \"" ..
        obj.contentFile ..
        "\"},"                -- Return the result if matched, otherwise return the original string
end
local function IC_playSound(soundId)
    ambient.playSound(soundId)
end
local function waitUntilOutside()
    if self.cell.isExterior then
        core.sendGlobalEvent("finishChargen")
    else
        async:newUnsavableSimulationTimer(0.1, waitUntilOutside)
    end
end

local function onQuestUpdate(quid, stage)
    if quid:lower() == "a1_1_findspymaster" and stage == 1 then
        core.sendGlobalEvent("exitDoorUnlock")
        async:newUnsavableSimulationTimer(0.1, waitUntilOutside)
    end
end
return {
    interfaceName = "IChargen",
    interface = {
        version = 1,
        removeNumbers = removeNumbers
    },
    eventHandlers = {
        showMessageICG = showMessageICG,
        enableControlsICG = enableControlsICG,
        enableCameraControlsICG = enableCameraControlsICG,
        IC_playSound = IC_playSound,
    },
    engineHandlers = {
        onQuestUpdate = onQuestUpdate,
    }
}
