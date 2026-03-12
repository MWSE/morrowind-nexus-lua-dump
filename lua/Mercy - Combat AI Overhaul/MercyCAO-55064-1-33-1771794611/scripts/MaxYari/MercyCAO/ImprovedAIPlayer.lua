mp = "scripts/MaxYari/MercyCAO/"

local core = require("openmw.core")
local ui = require("openmw.ui")
local nearby = require("openmw.nearby")
local omwself = require("openmw.self")
local selfObject = omwself.object
local types = require("openmw.types")

local gutils = require(mp .. "scripts/gutils")
local selfActor = gutils.Actor:new(omwself)

DebugLevel = 2

if core.API_REVISION < 64 then
    return ui.showMessage("Mercy: CAO requiers a newer version of OpenMW, please update.")
end

gutils.print("Hi! Mercy: CAO BETA is now E-N-G-A-G-E-D", 0)

local actorI = 1
local actors = nil

local function onUpdate(dt)
    
    local use = omwself.controls.use

    if not actors then
        actors = nearby.actors 
        actorI = 1
    end
    local actor = actors[actorI]
    if actor then
        if actor.type == types.NPC then
            actor:sendEvent('PlayerUse', { source = selfObject, use = use })
        end
        actorI = actorI + 1
    else
        actors = nil
    end

    -- Some experimental stuff
    -- local Attribute = {}
    -- for i, attribute in pairs(core.stats.Attribute.records) do
    --     Attribute[attribute.name] = attribute
    -- end
    -- if omwself.controls.use > 0 then
    --     types.Actor.activeEffects(omwself):set(100,core.magic.EFFECT_TYPE.FortifyAttribute, "speed")
    -- else
    --     types.Actor.activeEffects(omwself):set(0,core.magic.EFFECT_TYPE.FortifyAttribute, "speed")
    -- end
end

local function onCombatTargetsChanged(e)
    if e.actor == omwself.object then return end
    e.actor:sendEvent('OMWMusicHackCombatTargetsChanged', { targets = e.targets })
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = { 
        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,
    }
}
