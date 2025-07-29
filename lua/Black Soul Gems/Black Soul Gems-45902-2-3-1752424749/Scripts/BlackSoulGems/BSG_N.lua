local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local anim = require('openmw.animation')
local function isTrapped()
    local soulTrap = types.Actor.activeEffects(self):getEffect("soultrap")
    return soulTrap and soulTrap.magnitude > 0
end
local wasTrapped = false
local lastHealth = -1
local function onLoad()
    lastHealth = types.Actor.stats.dynamic.health(self).current
end
local function onUpdate(dt)
    local health = types.Actor.stats.dynamic.health(self).current
    if lastHealth == -1 then
        lastHealth = health
        return
    end
    if health <= 0 and lastHealth > 0 and isTrapped() then --I just died
        core.sendGlobalEvent("NPCTrapped", self)
    end
    if isTrapped() and not wasTrapped then
        wasTrapped = true
    elseif not isTrapped() then
        wasTrapped = false
    end
    lastHealth = health
end
local function BSG_addVfx(info)
     anim.addVfx(self, types.Static.records[info].model)
end
return {
    engineHandlers = {
        onLoad = onLoad,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        BSG_addVfx = BSG_addVfx
    }
}
