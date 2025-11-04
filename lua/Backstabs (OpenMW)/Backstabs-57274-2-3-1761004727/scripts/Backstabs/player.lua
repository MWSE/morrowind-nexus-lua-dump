local animation = require("openmw.animation")
local storage = require("openmw.storage")
local ambient = require("openmw.ambient")
local nearby = require("openmw.nearby")
local input = require("openmw.input")
local async = require("openmw.async")
local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local I = require('openmw.interfaces')
require("scripts.Backstabs.backstabLogic")

local l10n = core.l10n("Backstabs")
local sectionOnBackstab = storage.playerSection("SettingsBackstabs_onBackstab")
local sectionToggles = storage.globalSection("SettingsBackstabs_toggles")

local InvisStatus = 0

input.registerActionHandler(input.actions.Sneak.key, async:callback(function()
    if sectionToggles:get("requireCrouching") then
        for _, actor in pairs(nearby.actors) do
            actor:sendEvent("playerSneaking", not self.controls.sneak)
        end
    end
end))

I.Combat.addOnHitHandler(function(attack)
    if not sectionToggles:get("playerCanBeBackstabbed") then return end
    DoBackstab(attack)
end)

local function onLoad()
    -- always check your API version
    if core.API_REVISION < 87 then
        ui.showMessage(l10n("messageOutdatedLuaAPI"), { showInDualogue = true })
    end
end

local function updateInvis()
    -- skip if invisibility status hasn't changed
    if InvisStatus == types.Actor.activeEffects(self):getEffect("invisibility").magnitude then return end
    -- skip the status update if the swing animation is playing
    if SwingAnimations[animation.getActiveGroup(self, animation.BONE_GROUP.RightArm)] then return end

    InvisStatus = types.Actor.activeEffects(self):getEffect("invisibility").magnitude

    for _, actor in pairs(nearby.actors) do
        actor:sendEvent("playerInvisible", InvisStatus == 1)
    end
end

local function onBackstab(damageMult)
    if sectionOnBackstab:get("playSFX") then ambient.playSound("critical damage") end
    if sectionOnBackstab:get("showMessage") then
        if damageMult == math.huge then
            ui.showMessage(l10n("messageInstakill"))
        else
            ui.showMessage(
                l10n("messageSuccessfulBackstab1") ..
                tostring(damageMult) ..
                l10n("messageSuccessfulBackstab2"))
        end
    end
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onUpdate = updateInvis,
    },
    eventHandlers = {
        onBackstab = onBackstab,
    }
}
