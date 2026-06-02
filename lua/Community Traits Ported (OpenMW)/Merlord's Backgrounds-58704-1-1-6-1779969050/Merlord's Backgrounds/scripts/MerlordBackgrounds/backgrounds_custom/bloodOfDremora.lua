---@diagnostic disable: assign-type-mismatch
local self = require("openmw.self")
local core = require("openmw.core")

local player
local script

local function onInit(scriptData)
    player = scriptData.player
    script = scriptData.script
end

local function onDeath()
    core.sound.playSound3d("dremora moan", self)
    player:sendEvent("MerlordsTraits_dremoraDied")
    core.sendGlobalEvent(
        "MerlordsTraits_onScriptedActorDeath",
        {
            script = script,
            actor = self,
            clearInventory = true,
        }
    )
end

core.sound.playSound3d("dremora scream", self)

return {
    engineHandlers = {
        onInit = onInit,
    },
    eventHandlers = {
        Died = onDeath,
    }
}
