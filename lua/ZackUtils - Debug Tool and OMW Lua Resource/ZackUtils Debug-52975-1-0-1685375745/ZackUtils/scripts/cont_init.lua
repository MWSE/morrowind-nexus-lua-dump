local storage = require("openmw.storage")
local self = require("openmw.self")
local types = require("openmw.types")
local Actor = types.Actor
local playerSettings = storage.globalSection("SettingsDebugMode")
local util = require("openmw.util")
local core = require("openmw.core")

local hasInitItem = false
local wasInited = false

local function initCont()
    if(wasInited == true) then
        return false
    end
    core.sendGlobalEvent("ZackUtilsAddItem",{itemId = "key_skeleton",count=1,actor=self})
    hasInitItem = true
    wasInited = true
end
local function onUpdate(dt)
    if (hasInitItem) then
        core.sendGlobalEvent("removeItemCount",{itemId = "key_skeleton",count=1,actor=self})
        hasInitItem = false
    end
end
return {
    eventHandlers = {
        initCont = initCont,
    },
    engineHandlers = { onInit = onInit, onLoad = onInit, onUpdate = onUpdate, onInputAction = onInputAction, }
}
