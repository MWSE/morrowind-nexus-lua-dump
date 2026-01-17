local core = require('openmw.core')
local world = require('openmw.world')
local I = require("openmw.interfaces")
local T = require('openmw.types')

local mS = require('scripts.NCG.config.settings')
mS.initGlobalSettings()
local log = require('scripts.NCG.util.log')
local mDef = require('scripts.NCG.config.definition')

local function handleBitterCup(bitterCup, player)
    local vars = world.mwscript.getLocalScript(bitterCup).variables

    if vars.maxatt == 0 then
        log("Bitter Cup not used")
        return
    end

    local Attributes = core.stats.Attribute.records
    player:sendEvent(mDef.events.modAttributes, {
        { attrId = Attributes[vars.maxatt].id, value = 20 },
        { attrId = Attributes[vars.minatt].id, value = -20 },
    })

    -- In case another Bitter Cup is found
    vars.maxatt = 0
    vars.minatt = 0

    log("Bitter Cup used")
end

I.Activation.addHandlerForType(T.Miscellaneous, function(object, actor)
    if object.recordId == "artifact_bittercup_01" and actor.type == T.Player then
        log("Bitter Cup activated")
        actor:sendEvent(mDef.events.onBitterCupActivated, object)
    end
end)

return {
    eventHandlers = {
        [mDef.events.onBitterCupHandled] = function(data) handleBitterCup(data.bitterCup, data.player) end,
    }
}