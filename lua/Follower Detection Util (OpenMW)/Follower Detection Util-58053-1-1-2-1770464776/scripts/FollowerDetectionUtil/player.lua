require("scripts.FollowerDetectionUtil.utils.consts")

local followers = {}

local function updateFollowerList(data)
    followers = data.followers
end

return {
    eventHandlers = {
        FDU_UpdateFollowerList = updateFollowerList,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        version = ModVersion,
        getFollowerList = function() return followers end,
    },
}
