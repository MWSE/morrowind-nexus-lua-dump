local S = require('scripts.BMSO.settings')

-- If some NPCs have too high or too low trading skills, you can override their level here, like the commented line for Arrille
local npcLevelOverrides = {
    --["arrille"] = 5,
}

local function getDescriptionIfOpenMWTooOld(key)
    if not S.isLuaApiRecentEnough then
        if S.isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

local function debugPrint(str, ...)
    if S.globalStorage:get("debugMode") then
        local arg = {...}
        if arg ~= nil then
            print(string.format("DEBUG: " .. str, unpack(arg)))
        else
            print("DEBUG: " .. str)
        end
    end
end

return {
    npcLevelOverrides = npcLevelOverrides,
    getDescriptionIfOpenMWTooOld = getDescriptionIfOpenMWTooOld,
    debugPrint = debugPrint,
}

