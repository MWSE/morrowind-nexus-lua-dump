local async = require("openmw.async")
local storage = require("openmw.storage")
local MOD_ID = "QuickStack"
local settingsGlobal = "SettingsGlobal" .. MOD_ID
local modSettings = storage.globalSection(settingsGlobal)

local debugOn = modSettings:get("debugOn")
local function updateDebugs(_, key)
    if key == "debugOn" then
        debugOn = modSettings:get("debugOn")
    end
end

--Add debug fully?
--Add new options for user custom (custom distance for nearby search, toggle verify prompt)

--Add copy here due to i10n/YAML being a PAIN IN MY FUCKING DICK

modSettings:subscribe(async:callback(updateDebugs))

local function msg(...)
    if debugOn then
        print("[QuickStack]: " .. ...)
    end
end

return {
    MOD_ID = MOD_ID,
    msg = msg,
    scriptCheckInterval = .5,
    settingsGlobal = settingsGlobal
}
