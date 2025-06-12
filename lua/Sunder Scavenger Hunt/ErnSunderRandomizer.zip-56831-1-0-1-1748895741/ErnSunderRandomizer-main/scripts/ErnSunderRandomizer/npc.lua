--[[
ErnSunderRandomizer for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local self = require("openmw.self")
local types = require("openmw.types")
local common = require("scripts.ErnSunderRandomizer.common")
local settings = require("scripts.ErnSunderRandomizer.settings")

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

local function onActive()
    id = self.id
    if id == false then
        error("no id")
        return
    end

    recordID = ""

    if self.type == types.NPC then
        record = types.NPC.record(self)
        if record == nil then
            error("NPC " .. id .. " has no record?")
            return
        end
        recordID = types.NPC.record(self).id
    elseif self.type == types.Creature then
        record = types.Creature.record(self)
        if record == nil then
            error("Creature " .. id .. " has no record?")
            return
        end
        recordID = types.Creature.record(self).id
    else
        error("script applied to bad object")
    end

    if string.lower(recordID) == "dagoth vemyn" then
        common.hideItemOnce(self, "sunder")
    end

    -- TODO: If the NPC has a clue item, randomly place it in a container
    -- they own inside this cell (if any).
end

return {
    engineHandlers = {
        onActive = onActive
    }
}
