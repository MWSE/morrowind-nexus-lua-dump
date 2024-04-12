local storage = require('openmw.storage')
local C = require("scripts.BMSO.common")

local globalStorage = storage.globalSection("SettingsGlobal" .. C.MOD_NAME)

local function debugPrint(str)
    if globalStorage:get("debugMode") then
        print(string.format("DEBUG: %s", str))
    end
end

return {
    debugPrint = debugPrint,
    globalStorage = globalStorage,
}