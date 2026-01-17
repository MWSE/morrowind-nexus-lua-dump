--[[
    Kezyma's Mechanics Remastered - Global Script
    OpenMW Port

    Global coordination script. Regeneration is handled in local scripts
    (player.lua, actor.lua) since only local scripts can modify actor stats.
]]

print('[Mechanics Remastered] Global script loaded')

local function onInit()
    print('[Mechanics Remastered] Initialized')
end

local function onLoad()
    print('[Mechanics Remastered] Save loaded')
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
    }
}
