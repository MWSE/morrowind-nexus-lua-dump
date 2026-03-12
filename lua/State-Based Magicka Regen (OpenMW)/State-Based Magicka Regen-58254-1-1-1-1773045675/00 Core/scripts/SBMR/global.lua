local core = require("openmw.core")
local world = require('openmw.world')
local T = require("openmw.types")
local I = require("openmw.interfaces")

local mDef = require("scripts.SBMR.config.definition")
local mStore = require("scripts.SBMR.config.store")
local mObj = require("scripts.SBMR.util.objects")
local log = require("scripts.SBMR.util.log")

mStore.registerGroups()

local state = {
    actors = {},
}

local magicka = T.Actor.stats.dynamic.magicka
local lastCheckTime = 0

local function updateArguments(arguments)
    for key, argument in pairs(arguments) do
        I.Settings.updateRendererArgument(mStore.settings[key].section.key, mStore.settings[key].key, argument)
    end
end

local function onUpdate(dt)
    if dt == 0 or not mStore.settings.enabled.value then return end
    lastCheckTime = lastCheckTime + dt
    if lastCheckTime < 1 then return end
    lastCheckTime = 0

    local actors = state.actors
    local activeActors = {}
    for _, actor in ipairs(world.activeActors) do
        activeActors[actor.id] = true
        if actors[actor.id] and actors[actor.id].lastActiveTime then
            local passedTime = (core.getGameTime() - actors[actor.id].lastActiveTime) / core.getGameTimeScale()
            actors[actor.id].lastActiveTime = nil
            log(string.format("%s was inactive during %d seconds, re-adding the script", mObj.objectId(actor), passedTime))
            actor:addScript(mDef.scripts.actor, { passedTime = passedTime })
        elseif magicka(actor).current < magicka(actor).base then
            if not actors[actor.id] then
                log(string.format("%s needs regen, attaching the script", mObj.objectId(actor)))
                actor:addScript(mDef.scripts.actor)
                actors[actor.id] = { object = actor }
            end
        elseif actors[actor.id] then
            log(string.format("%s has fully regenerated, removing the script", mObj.objectId(actor)))
            actor:removeScript(mDef.scripts.actor)
            actors[actor.id] = nil
        end
    end
    for id, data in pairs(actors) do
        if not data.lastActiveTime and not activeActors[id] then
            log(string.format("%s became inactive, removing the script", mObj.objectId(data.object)))
            data.lastActiveTime = core.getGameTime()
            data.object:removeScript(mDef.scripts.actor)
        end
    end
end

local function onInit()

end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data then
        state = data.state
        log(string.format("Loading State-Based Magicka Regen save v%s...", data.version))
    end
    mObj.fixObjects({ actors = state.actors })
    onInit()
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
        getSettings = function() return mStore.settings end,
    },
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        [mDef.events.update_arguments] = updateArguments,
    }
}
