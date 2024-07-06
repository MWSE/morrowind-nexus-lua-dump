local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType
local log = require("scripts.morrowind_world_randomizer.utils.log")

local core = require("openmw.core")
local self = require('openmw.self')
local Container = require('openmw.types').Container
local async = require('openmw.async')

local function randomizeInventory()
    local items = {}
    for i, item in pairs(Container.content(self):getAll()) do
        table.insert(items, {item = item, count = item.count})
    end
    core.sendGlobalEvent("mwr_updateInventory", {items = items, object = self.object, objectType = objectType.container})
end

return {
    eventHandlers = {
        mwr_container_randomizeInventory = async:callback(randomizeInventory),
    },
}