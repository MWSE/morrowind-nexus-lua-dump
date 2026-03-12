-- transition_handler.lua
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
 
local input = require('openmw.input')
local I = require('openmw.interfaces')
local aux_ui = require('openmw_aux.ui')

local transition_handler = {}

function transition_handler.check(state)
    local uiMode = I.UI.getMode()
    local remoteId, _ = state.remote.get()

    -- Seamless Menu Transitions
    if state.activeWindow or (uiMode == "Book" or uiMode == "Scroll") and remoteId then
        if input.isActionPressed(input.ACTION.Inventory) or input.isActionPressed(input.ACTION.GameMenu) then
            local targetMode = input.isActionPressed(input.ACTION.Inventory) and "Interface" or "MainMenu"
            
            if state.activeWindow then 
                aux_ui.deepDestroy(state.activeWindow)
            end
            
            if remoteId then
                state.remote.cleanup(state.self)
            end
            
            state.remote.handleAudio() -- Manages suppressCloseSound logic
            I.UI.setMode(targetMode)
            return true -- Transition occurred
        end
    end
    return false
end

return transition_handler