local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local core = require("openmw.core")
local actor = require("scripts.morrowind_world_randomizer.local.actor")(objectType.npc)
local self = require('openmw.self')
local async = require('openmw.async')

local function deactivate()
    if self.object.count == 0 then
        core.sendGlobalEvent("mwr_deactivateObject", {object = self.object})
    end
end

return {
    engineHandlers = {
        onInactive = deactivate,
    },
    eventHandlers = {
        mwr_actor_setEquipment = async:callback(actor.setEquipment),
        mwr_actor_randomizeInventory = async:callback(actor.randomizeInventory),
        mwr_actor_setDynamicStats = async:callback(actor.setDynamicStats),
        mwr_actor_setAttributeBase = async:callback(actor.setAttributeBase),
        mwr_actor_randomizeSkillBaseValues = async:callback(actor.randomizeSkillBaseValues),
        mwr_actor_randomizeSpells = async:callback(actor.randmizeSpells),
    },
}
