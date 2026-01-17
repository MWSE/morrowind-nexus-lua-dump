local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require("openmw.interfaces")

require("scripts.FriendlierFire.logic.combat")
require("scripts.FriendlierFire.logic.spells")
require("scripts.FriendlierFire.utils.dependencies")

CheckDependencies(self, {
    ["FollowerDetectionUtil.omwscripts"] = I.FollowerDetectionUtil == nil
})
I.Combat.addOnHitHandler(AttackHandler)

local sectionOther = storage.globalSection('SettingsFriendlierFire_other')
local hasFollowers = false

local function onUpdate()
    if sectionOther:get("disableSpells") and hasFollowers then
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
