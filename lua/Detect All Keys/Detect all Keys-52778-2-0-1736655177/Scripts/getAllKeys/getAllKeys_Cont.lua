local util = require("openmw.util")
local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local inv = nil

if (core.API_REVISION < 69) then return {} end
local function checkIsKey(record)
    if record.isKey == true then
        return false -- it is a key, but already tracked so we don't need to add a new itemcheck
    end

    local icon = record.icon:lower()
    local model = record.model:lower()
    local name = record.name:lower()
    local id = record.id:lower()

    if string.find(icon, "key") or string.find(model, "key") or
        string.find(name, "key") or string.find(id, "key") then
        return true -- record contains the word "key"
    end

    return false -- record does not contain the word "key"
end

local function onActive()
    if (self.type == types.Container) then
        if types.Container.record(self).isOrganic or
            types.Container.record(self).isRespawning then return end
        if (types.Container.capacity(self) == 0) then
            return -- if capacity is 0, than this is a plant and shouldn't have any keys.
        end

    end
    inv = types.Container.content(self)
    if (inv) then
        local itemcheck = inv:find("ZHAC_PlaceholderKey")
        local hasKey = false
        if (itemcheck) then
            local miscItems = inv:getAll(types.Miscellaneous)
            for i, item in ipairs(miscItems) do
                if (checkIsKey(types.Miscellaneous.record(item))) then
                  hasKey = true
                end
            end
        end
        if hasKey then
         core.sendGlobalEvent("addKeyToInventory", self)
        end
    end
end

return {engineHandlers = {onActive = onActive, onActivated = onActivated}}
