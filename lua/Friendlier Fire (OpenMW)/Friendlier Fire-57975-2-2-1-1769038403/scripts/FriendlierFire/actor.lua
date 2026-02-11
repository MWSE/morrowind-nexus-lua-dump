local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require('openmw.interfaces')

require("scripts.FriendlierFire.logic.combat")
require("scripts.FriendlierFire.logic.spells")
require("scripts.FriendlierFire.logic.ai")

I.Combat.addOnHitHandler(AttackHandler)

local settings = storage.globalSection('SettingsFriendlierFire_settings')
local isFollower = I.FollowerDetectionUtil.getState().followsPlayer

local function onUpdate()
    if settings:get("disableSpells") and isFollower then
        local newSpells = UpdateActiveSpells()
        RemoveFriendlyHarmfulSpells(newSpells)
    end
end

local function startAIPackage(pkg)
    TargetChanged(pkg)
end

local function updateFollowerStatus(data)
    isFollower = data.followers[self.id] and data.followers[self.id].followsPlayer or false
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        StartAIPackage = startAIPackage,
        FriendlyFire_TargetChanged = TargetChanged,
        FDU_UpdateFollowerList = updateFollowerStatus
    }
}
