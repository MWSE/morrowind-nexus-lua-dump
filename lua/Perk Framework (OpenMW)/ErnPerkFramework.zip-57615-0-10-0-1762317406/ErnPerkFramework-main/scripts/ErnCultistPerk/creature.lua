--[[
ErnPerkFramework for OpenMW.
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
local nearby = require('openmw.nearby')
local ns = require("scripts.ErnCultistPerk.namespace")
local pself = require("openmw.self")
local types = require("openmw.types")
local interfaces = require("openmw.interfaces")

local function onActive()
    local creatureRecord = pself.type.records[pself.recordId]

    if creatureRecord.type == types.Creature.TYPE.Daedra then
        -- exclude Daedra that have a Follow AI package, because
        -- they are probably Summoned.
        local following = false
        local func = function(param)
            if param.type == "Follow" then
                following = true
            end
        end
        interfaces.AI.forEachPackage(func)

        if not following then
            for _, player in ipairs(nearby.players) do
                player:sendEvent(ns .. "daedraSpawned", { creature = pself })
            end
        end
    end
end

local function calmDaedra(data)
    print("Calming " .. pself.type.records[pself.recordId].name)
    types.Actor.stats.ai.fight(pself).base = 30
    pself:sendEvent('RemoveAIPackages', 'Combat')
end


return {
    eventHandlers = {
        [ns .. "calmDaedra"] = calmDaedra,
    },
    engineHandlers = {
        onActive = onActive
    }
}
