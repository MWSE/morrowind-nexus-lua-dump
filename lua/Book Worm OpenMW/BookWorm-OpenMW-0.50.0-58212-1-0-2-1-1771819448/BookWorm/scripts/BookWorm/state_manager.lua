-- state_manager.lua
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
local types = require('openmw.types')
local self = require('openmw.self')

local state_manager = {}

function state_manager.buildMasterList(utils)
    local totals = { combat = 0, magic = 0, stealth = 0, lore = 0, totalTomes = 0, totalLetters = 0 }
    
    for _, record in ipairs(types.Book.records) do
        local id = record.id:lower()
        if utils.isTrackable(id) then
            if record.isScroll then
                totals.totalLetters = totals.totalLetters + 1
            else
                totals.totalTomes = totals.totalTomes + 1
                -- Use internal IDs for counting logic
                local _, cat = utils.getSkillInfoExport(id)
                if totals[cat] ~= nil then
                    totals[cat] = totals[cat] + 1
                end
            end
        end
    end
    return totals
end

-- Filter data during load using isTrackable to ensure only valid, non-blacklisted items enter the state
function state_manager.processLoad(data, utils)
    local state = { books = {}, notes = {} }
    if data then
        local saveMarker = data.saveTimestamp or 0
        if data.booksRead then
            for id, ts in pairs(data.booksRead) do 
                local lowerId = id:lower()
                -- Use isTrackable to filter out blacklisted or invalid items
                if ts <= saveMarker and utils.isTrackable(lowerId) then 
                    state.books[lowerId] = ts 
                end 
            end
        end
        if data.notesRead then
            for id, ts in pairs(data.notesRead) do 
                local lowerId = id:lower()
                -- Use isTrackable to filter out blacklisted or invalid items
                if ts <= saveMarker and utils.isTrackable(lowerId) then 
                    state.notes[lowerId] = ts 
                end 
            end
        end
    end
    return state
end

function state_manager.exportBooks(books, utils)
    print(string.format("--- BOOKWORM: BOOK EXPORT [%s] ---", types.Player.record(self).name))
    for id, ts in pairs(books) do 
        -- Use the Export variant for raw ID
        local skillId, _ = utils.getSkillInfoExport(id)
        local label = skillId and (skillId:sub(1,1):upper() .. skillId:sub(2)) or "Lore"
        print(string.format("[%0.1f] [%s] %s (%s)", ts, label, utils.getBookName(id), id)) 
    end
end

function state_manager.exportLetters(notes, utils)
    print(string.format("--- BOOKWORM: LETTER EXPORT [%s] ---", types.Player.record(self).name))
    for id, ts in pairs(notes) do 
        print(string.format("[%0.1f] [Note] %s (%s)", ts, utils.getBookName(id), id)) 
    end
end

return state_manager