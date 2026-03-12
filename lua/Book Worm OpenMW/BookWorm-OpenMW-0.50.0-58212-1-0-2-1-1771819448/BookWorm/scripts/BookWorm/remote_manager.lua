-- remote_manager.lua
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
 
local core = require('openmw.core')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local remote_manager = {}

-- State encapsulated to keep player.lua clean
local state = {
    recordId = nil,
    target = nil,
    suppressCloseSound = false
}

-- Initiates the "Ghost" process with global.lua
function remote_manager.request(id, player, isNote)
    state.recordId = id:lower()
    local uiMode = isNote and "Scroll" or "Book"
    core.sendGlobalEvent('BookWorm_RequestRemoteObject', { 
        recordId = state.recordId, 
        player = player, 
        mode = uiMode 
    })
end

-- Sets local references once the engine creates the object
function remote_manager.set(id, target)
    state.recordId = id
    state.target = target
end

-- Returns current ghost data for UI handlers
function remote_manager.get()
    return state.recordId, state.target
end

-- Tells global.lua to delete the ghost and reverts state
function remote_manager.cleanup(player)
    if state.recordId then
        core.sendGlobalEvent('BookWorm_CleanupRemote', { 
            recordId = state.recordId, 
            player = player, 
            target = state.target 
        })
        state.recordId = nil
        state.target = nil
    end
end

-- Manages audio transitions to prevent double "Book Close" sounds
function remote_manager.handleAudio(forceSuppress)
    if forceSuppress ~= nil then 
        state.suppressCloseSound = forceSuppress 
        return 
    end
    
    if not state.suppressCloseSound then 
        ambient.playSound("Book Close") 
    end
    state.suppressCloseSound = false
end

return remote_manager