local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require("openmw.interfaces")

local deps = require("scripts.FriendlierFire.utils.dependencies")
deps.checkAll("Friendlier Fire", { {
    plugin = "FollowerDetectionUtil.omwscripts",
    interface = I.FollowerDetectionUtil,
    minVersion = 1.11,
    curVersion = I.FollowerDetectionUtil
        and I.FollowerDetectionUtil.version
        or -1
} })

require("scripts.FriendlierFire.logic.combat")
require("scripts.FriendlierFire.logic.spells")

I.Combat.addOnHitHandler(AttackHandler)

local settings = storage.globalSection('SettingsFriendlierFire_settings')
local hasFollowers = false

local function onUpdate()
    if hasFollowers and settings:get("disableSpells") then
        local newSpells = UpdateActiveSpells()
        RemoveFriendlyHarmfulSpells(newSpells)
    end
end

local function localEnemyTargetChanged(data)
    data.actor:sendEvent("FriendlyFire_TargetChanged", { target = self })
end

local function updateFollowerStatus(data)
    for _, state in pairs(data.followers) do
        if state.followsPlayer then
            hasFollowers = true
            return
        end
    end
    hasFollowers = false
end

updateFollowerStatus({ followers = I.FollowerDetectionUtil.getFollowerList() })

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        OMWMusicCombatTargetsChanged = localEnemyTargetChanged,
        FDU_UpdateFollowerList = updateFollowerStatus,
    }
}
