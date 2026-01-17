local followers = {}

local function onSave()
    return followers
end

local function onLoad(saveData)
    if saveData then
        followers = saveData
    end
end

local function updateFollowerList(data)
    followers = data.followers
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        FDU_UpdateFollowerList = updateFollowerList,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getFollowerList = function() return followers end,
    },
}
