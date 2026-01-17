local storage = require("openmw.storage")
local self = require("openmw.self")

local State = require("scripts.FollowerDetectionUtil.model.state")
require("scripts.FollowerDetectionUtil.logic.ai")

local settings = storage.globalSection("SettingsFollowerDetectionUtil_settings")
local updateTime = math.random() * math.max(0, settings:get('checkFollowersEvery'))
local state = State:new(GetLeader())
local followers = {}

-- +-----------------+
-- | Engine handlers |
-- +-----------------+

local function onUpdate(dt)
    updateTime = updateTime + dt
    local checkEvery = math.max(0, settings:get('checkFollowersEvery'))

    if updateTime < checkEvery then return end

    if checkEvery == 0 then
        updateTime = 0
    else
        while updateTime > checkEvery do
            updateTime = updateTime - checkEvery
        end
    end

    local leader = nil
    if not self.type.isDead(self) then
        leader = GetLeader()
    end

    state:setLeader(leader)
end

local function onSave()
    return followers
end

local function onLoad(saveData)
    if saveData then
        followers = saveData
    end
end

-- +----------------+
-- | Event handlers |
-- +----------------+

local function died()
    state:setLeader(nil)
end

local function startAIPackage(pkg)
    if (pkg.type == "Follow" or pkg.type == "Escort") and pkg.target:isValid() then
        state:setLeader(pkg.target)
    end
end

local function removeAIPackage(pkgType)
    if pkgType == "Follow" or pkgType == "Escort" then
        state:setLeader(nil)
    end
end

local function updateFollowerList(data)
    followers = data.followers
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Died = died,
        StartAIPackage = startAIPackage,
        RemoveAIPackage = removeAIPackage,
        FDU_UpdateFollowerList = updateFollowerList,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getState = function() return state end,
        getFollowerList = function() return followers end,
    },
}