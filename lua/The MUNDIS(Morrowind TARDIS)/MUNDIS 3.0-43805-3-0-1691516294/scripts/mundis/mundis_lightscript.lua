local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local storage = require("openmw.storage")
local myModData = storage.globalSection('MundisData')
local placedDark = false

local function stringContains(mainString, subString)
    return string.find(mainString, subString, 1, true) ~= nil
end
local function onActive()
    if core.API_REVISION == 29 then return end
    if self.recordId == "aa_light_velothi_brazier_177" then
        if placedDark == false then
            core.sendGlobalEvent("MundisCreateObject", { objectId = "zhac_brazier_off", sourceObject = self })
            placedDark = true
        end
        core.sendGlobalEvent("MundisSetObjState", { obj = self.object, state = myModData:get("MUNDISPowered") == true })
    elseif self.recordId == "zhac_brazier_off" then
        core.sendGlobalEvent("MundisSetObjState", { obj = self.object, state = not myModData:get("MUNDISPowered") })
    elseif self.type == types.Light then
        if stringContains(self.cell.name,"MUNDIS") and self.recordId ~= "aa_light_velothi_brazier_177_ch" then
            
        core.sendGlobalEvent("MundisSetObjState", { obj = self.object, state = myModData:get("MUNDISPowered") == true })
        end
    end
end
local function onLoad(data)
    if not data then return end
    placedDark = data.placedDark
end
local function onSave()
    if not placedDark then return end
    return { placedDark = placedDark }
end

local function sendSound(sound)

end
return {
    engineHandlers = {
        onActivated = onActivated,
        onActive = onActive,
    },
    eventHandlers = {
        onMessageSent = onMessageSent,
        sendSound = sendSound,
        onLoad = onLoad,
        onSave = onSave
    }
}
