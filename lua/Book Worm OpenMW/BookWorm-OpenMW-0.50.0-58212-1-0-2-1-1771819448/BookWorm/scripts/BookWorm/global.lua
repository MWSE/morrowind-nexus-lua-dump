-- global.lua
--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org>.
--]]
 
local world = require('openmw.world')
local types = require('openmw.types')

-- Snapshot storage: [player.id] = { [recordId] = originalCount }
local playerSnapshots = {}

return {
    eventHandlers = {
        onObjectUse = function(data)
            if data.object.type == types.Book then
                data.actor:sendEvent('BookWorm_ManualMark', data.object)
            end
        end,
        
        BookWorm_RequestRemoteObject = function(data)
            local player = data.player
            local inv = types.Actor.inventory(player)
            
            -- 1. Take Snapshot
            local currentCount = inv:countOf(data.recordId)
            
            if not playerSnapshots[player.id] then playerSnapshots[player.id] = {} end
            playerSnapshots[player.id][data.recordId] = currentCount
            
            -- 2. Create the Ghost
            local tempObj = world.createObject(data.recordId)
            
            player:sendEvent('BookWorm_OpenRemoteUI', { 
                target = tempObj, 
                mode = data.mode,
                recordId = data.recordId
            })
        end,
        
        BookWorm_CleanupRemote = function(data)
            local player = data.player
            local recordId = data.recordId
            local snapshotCount = playerSnapshots[player.id] and playerSnapshots[player.id][recordId]
            
            if snapshotCount ~= nil then
                local inv = types.Actor.inventory(player)
                local currentCount = inv:countOf(recordId)
                
                -- 1. THE INVENTORY FIX:
                if currentCount > snapshotCount then
                    local books = inv:getAll(types.Book)
                    for _, item in ipairs(books) do
                        if item.recordId == recordId and 
                           item ~= data.target and 
                           item:isValid() and 
                           item.count >= 1 then 
                            
                            item:remove(1)
                            break 
                        end
                    end
                end
                
                -- 2. THE MEMORY FIX:
                if data.target and data.target:isValid() then
                    if data.target.count > 0 then
                        data.target:remove()
                    end
                end
                
                playerSnapshots[player.id][recordId] = nil
            end
        end
    }
}