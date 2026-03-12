-- scripts/BookWorm/input_handler.lua
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
local ambient = require('openmw.ambient')
local ui_library = require('scripts.BookWorm.ui_library')
local aux_ui = require('openmw_aux.ui') 

local input_handler = {}

local function matchesFilter(id, name, params)
    local searchMatch = true
    if params.searchString and params.searchString ~= "" then
        searchMatch = string.find(name:lower(), params.searchString:lower(), 1, true) ~= nil
    end
    if not searchMatch then return false end
    local isNone = (params.activeFilter == params.utils.FILTER_NONE)
    if isNone then return true end
    if #params.activeFilter == 1 then
        local uName = string.upper(name)
        local uChar = string.upper(params.activeFilter)
        if uName:sub(1,1) == uChar then return true end
        if uName:sub(1, 4) == "THE " and uName:sub(5, 5) == uChar then return true end
        if uName:sub(1, 3) == "AN " and uName:sub(4, 4) == uChar then return true end
        if uName:sub(1, 2) == "A " and uName:sub(3, 3) == uChar then return true end
        return false
    else
        local _, cat = params.utils.getSkillInfoLibrary(id)
        return cat == params.activeFilter
    end
end

function input_handler.toggleWindow(params)
    if params.activeWindow then 
        if params.isJump or params.isFilterChange or params.isSearchChange then 
            aux_ui.deepDestroy(params.activeWindow)
        elseif params.activeMode == params.mode then 
            aux_ui.deepDestroy(params.activeWindow)
            ambient.playSound("Book Close") 
            return nil, nil 
        else
            aux_ui.deepDestroy(params.activeWindow)
            ambient.playSound("book page2") 
        end 
    else
        ambient.playSound("Book Open") 
    end
    local data = (params.mode == "TOMES") and params.booksRead or params.notesRead
    local page = (params.mode == "TOMES") and params.bookPage or params.notePage
    return ui_library.createWindow({
        dataMap = data, currentPage = page, itemsPerPage = params.itemsPerPage, 
        utils = params.utils, mode = params.mode, masterTotals = params.masterTotals,
        activeFilter = params.activeFilter, searchString = params.searchString,
        isSearchActive = params.isSearchActive,
        -- AUDIT: Pass dynamic keys
        openTomesKey = params.openTomesKey,
        openLettersKey = params.openLettersKey,
        prevPageKey = params.prevPageKey,
        nextPageKey = params.nextPageKey
    }), params.mode
end

function input_handler.handlePagination(key, params)
    local data = (params.activeMode == "TOMES") and params.booksRead or params.notesRead
    local filteredCount = 0
    for id, _ in pairs(data) do
        local name = params.utils.getBookName(id)
        if matchesFilter(id, name, params) then filteredCount = filteredCount + 1 end
    end
    local maxPages = math.max(1, math.ceil(filteredCount / params.itemsPerPage))
    local currentPage = (params.activeMode == "TOMES") and params.bookPage or params.notePage
    local newPage = currentPage
    if key.code == input.KEY.O and currentPage < maxPages then newPage = currentPage + 1
    elseif key.code == input.KEY.I and currentPage > 1 then newPage = currentPage - 1
    else return params.activeWindow, currentPage end
    aux_ui.deepDestroy(params.activeWindow) 
    ambient.playSound("book page2") 
    return ui_library.createWindow({
        dataMap = data, currentPage = newPage, itemsPerPage = params.itemsPerPage, 
        utils = params.utils, mode = params.activeMode, masterTotals = params.masterTotals,
        activeFilter = params.activeFilter, searchString = params.searchString,
        isSearchActive = params.isSearchActive,
        -- AUDIT: Pass dynamic keys
        openTomesKey = params.openTomesKey,
        openLettersKey = params.openLettersKey,
        prevPageKey = params.prevPageKey,
        nextPageKey = params.nextPageKey
    }), newPage
end

return input_handler