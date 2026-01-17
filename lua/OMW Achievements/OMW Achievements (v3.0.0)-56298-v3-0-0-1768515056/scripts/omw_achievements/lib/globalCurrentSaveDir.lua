local world = require('openmw.world')

local function getCurrentSaveDir(data)
    local players = world.players
    for i = 1, #players do
        players[i]:sendEvent('createStorage', data)
    end
end

local function clearStorage()
    local players = world.players
    for i = 1, #players do
        players[i]:sendEvent('clearStorage')
    end
end

local function achievementSyncGlobal()
    local players = world.players
    for i = 1, #players do
        players[i]:sendEvent('achievementSync')
    end
end

return {
    eventHandlers = {
        getCurrentSaveDir = getCurrentSaveDir,
        clearStorage = clearStorage,
        achievementSyncGlobal = achievementSyncGlobal
    }
}