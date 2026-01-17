local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require("openmw.interfaces")

require("scripts.TargetTheLeader.utils.dependencies")

CheckDependencies(self, {
    ["FollowerDetectionUtil.omwscripts"] = I.FollowerDetectionUtil == nil
})

local settings = storage.playerSection('SettingsTargetTheLeader_settings')

local function localEnemyTargetChanged(data)
    local followerList = I.FollowerDetectionUtil.getFollowerList()
    local ignoreSummons = settings:get("ignoreSummons")

    for _, target in ipairs(data.targets) do
        if not followerList[target.id] then goto continue end

        local summonTargeted = string.find(target.recordId, "_summon$")
            or string.find(target.recordId, "_summ$")
        if summonTargeted and not ignoreSummons then goto continue end

        data.actor:sendEvent('RemoveAIPackages', 'Combat')
        data.actor:sendEvent("StartAIPackage", { type = 'Combat', target = self })

        ::continue::
    end
end

return {
    eventHandlers = {
        OMWMusicCombatTargetsChanged = localEnemyTargetChanged,
    }
}
