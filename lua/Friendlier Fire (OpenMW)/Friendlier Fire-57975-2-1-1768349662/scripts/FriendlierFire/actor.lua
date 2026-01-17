local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require('openmw.interfaces')

require("scripts.FriendlierFire.logic.combat")
require("scripts.FriendlierFire.logic.spells")
require("scripts.FriendlierFire.logic.ai")

I.Combat.addOnHitHandler(AttackHandler)

local sectionOther = storage.globalSection('SettingsFriendlierFire_other')
local isFollower = I.FollowerDetectionUtil.getState().followsPlayer

local function onUpdate()
    if sectionOther:get("disableSpells") and isFollower then
        local newSpells = UpdateActiveSpells()
        RemoveFriendlyHarmfulSpells(newSpells)
    end
end

local function startAIPackage(pkg)
    TargetChanged(pkg)
end

local function updateFollowerStatus(data)
    isFollower = data.followers[self.id].followsPlayer
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
