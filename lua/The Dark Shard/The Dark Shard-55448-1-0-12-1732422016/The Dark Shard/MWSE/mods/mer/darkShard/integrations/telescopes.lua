local Telescope = require("mer.darkShard.components.Telescope")
local CraftingFramework = require("CraftingFramework")

local observatories = {
    "afq_dwrv_scope00",
}

---@class DarkShard.TelescopeData
---@field droppedObjectId string
---@field scale number

---@type table<string, DarkShard.TelescopeData> Key: activatorID
local telescopes = {
    afq_telescope_a_01 =  {
        droppedObjectId = "afq_telescope_m_01",
        scale = 1.0
    }
}

for _, id in ipairs(observatories) do
    Telescope.registerObservatory(id)
end

for activatorId, data in pairs(telescopes) do
    Telescope.registerTelescope(activatorId)
    CraftingFramework.RefDropper.register{
        droppedObjectId = data.droppedObjectId,
        replacerId = activatorId,
        scale = data.scale,
        onDrop = function (self, reference)
            reference.data.afq_Telescope_miscId = data.droppedObjectId
        end
    }
end

