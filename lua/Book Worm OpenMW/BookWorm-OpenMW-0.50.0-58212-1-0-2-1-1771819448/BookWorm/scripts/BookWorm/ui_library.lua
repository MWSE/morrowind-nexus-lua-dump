-- ui_library.lua
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

local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local async = require('openmw.async')
local I = require('openmw.interfaces') 

local L = core.l10n('BookWorm', 'en')
local ui_library = {} 

local function nameMatchesLetter(name, char)
    local upperName = string.upper(name)
    local upperChar = string.upper(char)
    if upperName:sub(1,1) == upperChar then return true end
    if upperName:sub(1, 4) == "THE " and upperName:sub(5, 5) == upperChar then return true end
    if upperName:sub(1, 3) == "AN " and upperName:sub(4, 4) == upperChar then return true end
    if upperName:sub(1, 2) == "A " and upperName:sub(3, 3) == upperChar then return true end
    return false
end

function ui_library.createWindow(params)
    local dataMap = params.dataMap
    local currentPage = params.currentPage
    local itemsPerPage = params.itemsPerPage
    local utils = params.utils
    local mode = params.mode
    local master = params.masterTotals 
    local activeFilter = params.activeFilter
    local searchString = params.searchString or ""
    local isSearchActive = params.isSearchActive
    
    local prevK = (params.prevPageKey or "I"):upper()
    local nextK = (params.nextPageKey or "O"):upper()
    local openTomesK = (params.openTomesKey or "K"):upper()
    local openLettersK = (params.openLettersKey or "L"):upper()
    local closeK = (mode == "TOMES" and openTomesK or openLettersK)
    
    local isNone = (activeFilter == utils.FILTER_NONE)
    local contentItems = {}
    local playerName = types.Player.record(self).name or L('Library_Default_PlayerName')
    
    -- FIXED: Used named keys 'player' and 'mode' to satisfy LuaUtil::cast<std::string>(key) in l10n.cpp
    local titleText = L('Library_Title_Format', {player = string.upper(playerName), mode = mode})
    
    local sortedData = {}
    local counts = { combat = 0, magic = 0, stealth = 0, lore = 0 }
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local availableLetters = {}

    for id, _ in pairs(dataMap) do
        local name = utils.getBookName(id)
        local _, cat = utils.getSkillInfoLibrary(id)
        counts[cat] = (counts[cat] or 0) + 1
        for i = 1, #alphabet do
            local char = alphabet:sub(i, i)
            if not availableLetters[char] and nameMatchesLetter(name, char) then availableLetters[char] = true end
        end
    end

    local timestamps = {}
    for id, ts in pairs(dataMap) do 
        local name = utils.getBookName(id)
        local _, cat = utils.getSkillInfoLibrary(id)
        local match = true
        if not isNone then
            if #activeFilter == 1 then match = nameMatchesLetter(name, activeFilter)
            else match = (cat == activeFilter) end
        end
        if match and searchString ~= "" then
            match = string.find(name:lower(), searchString:lower(), 1, true) ~= nil
        end
        if match then
            table.insert(sortedData, { id = id, name = name, ts = ts })
            table.insert(timestamps, ts)
        end
    end
    
    table.sort(timestamps, function(a, b) return a > b end)
    local newThreshold = timestamps[math.min(5, #timestamps)] or 0
    table.sort(sortedData, function(a, b) return a.name < b.name end)
    
    local totalItems = #sortedData
    local maxPages = math.max(1, math.ceil(totalItems / itemsPerPage))
    local activePage = math.min(math.max(1, currentPage), maxPages)

    local ribbonContent = {}
    local intervalSize = util.vector2(2, 2)
    local grayColor = util.color.rgb(0.5, 0.5, 0.5)
    for i = 1, #alphabet do
        local char = alphabet:sub(i, i)
        local isActive = (activeFilter == char)
        local isAvailable = availableLetters[char]
        local charColor = isAvailable and utils.blackColor or grayColor
        local charHover = isAvailable and util.color.rgb(0.8, 0.6, 0.1) or grayColor
        table.insert(ribbonContent, {
            type = ui.TYPE.Container,
            template = isActive and I.MWUI.templates.box or nil, 
            props = { padding = 2 },
            content = ui.content({{
                type = ui.TYPE.Text,
                props = { text = char, textSize = 15, textColor = charColor, font = "DefaultBold" },
                events = {
                    mouseClick = (isAvailable and not isSearchActive) and async:callback(function() self:sendEvent('BookWorm_ChangeFilter', { filter = char }) end) or nil,
                }
            }})
        })
        if i < #alphabet then table.insert(ribbonContent, { props = { size = intervalSize } }) end
    end

    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = titleText, textSize = 26, font = "DefaultBold", textColor = utils.inkColor }})
    
    local searchLabel = ""
    local searchColor = utils.inkColor
    if isSearchActive then
        -- Use explicit tostring to ensure the C++ bridge receives a string type
        searchLabel = L('Library_Search_Active', {text = tostring(searchString)})
        searchColor = util.color.rgb(0.6, 0.2, 0.1)
    elseif searchString ~= "" then
        -- Explicitly cast the lowercased string
        local lowerSearch = tostring(searchString):lower()
        searchLabel = L('Library_Search_Results', {text = lowerSearch})
    else
        searchLabel = L('Library_Search_Hint')
    end
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = searchLabel, textSize = 14, textColor = searchColor, font = "DefaultBold" }})

    table.insert(contentItems, { type = ui.TYPE.Flex, props = { horizontal = true, arrange = ui.ALIGNMENT.Center }, content = ui.content(ribbonContent) })
    -- FIXED: Named keys 'current' and 'total'
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = L('Library_Page_Format', {current = activePage, total = maxPages}), textSize = 14, textColor = utils.inkColor }})
    
    -- FIXED: Named key 'key'
    local navText = (activePage > 1 and L('Library_Nav_Prev', {key = prevK}) or "") .. L('Library_Nav_Close', {key = closeK}) .. (activePage < maxPages and L('Library_Nav_Next', {key = nextK}) or "")
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = navText, textSize = 16, textColor = utils.inkColor, font = "DefaultBold" }})
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = " ", textSize = 10 }})

    local startIdx = ((activePage - 1) * itemsPerPage) + 1
    local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
    for i = startIdx, endIdx do
        local entry = sortedData[i]
        -- skillLabel is now localized via utils using core.l10n('SKILLS')
        local skillLabel, category = utils.getSkillInfoLibrary(entry.id)
        local normalColor = utils.getSkillColor(category)
        local hoverColor = util.color.rgb(0.8, 0.6, 0.1)
        local isNew = (entry.ts >= newThreshold and entry.ts > 0)
        local entryName = (isNew and L('Library_Entry_New') or "") .. entry.name
        
        -- FIXED: Named key 'name'
        local displayText = L('Library_Entry_Format', {name = entryName})
        if mode == "TOMES" then
            if skillLabel then 
                -- FIXED: Named keys 'name' and 'skill' - using localized label from utils
                displayText = L('Library_Entry_Skill_Format', {name = displayText, skill = skillLabel}) 
            end
        end
        local textProps = { text = displayText, textSize = 18, textColor = normalColor, font = "DefaultBold" }
        table.insert(contentItems, { 
            type = ui.TYPE.Text, 
            events = {
                mouseClick = not isSearchActive and async:callback(function() self:sendEvent('BookWorm_RemoteRead', { recordId = entry.id }) end) or nil,
                mouseMove = not isSearchActive and async:callback(function() textProps.textColor = hoverColor end) or nil,
                mouseLeave = not isSearchActive and async:callback(function() textProps.textColor = normalColor end) or nil
            },
            props = textProps
        })
    end
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = " ", textSize = 10 }})

    if mode == "TOMES" then
        local function createFilterBox(labelKey, count, max, category)
            local isActive = (activeFilter == category)
            return {
                type = ui.TYPE.Container,
                template = isActive and I.MWUI.templates.box or nil, 
                props = { padding = 3 },
                content = ui.content({{
                    type = ui.TYPE.Text,
                    -- FIXED: Named keys 'label', 'count', and 'max'
                    props = { text = L('Library_Filter_Count_Format', {label = L(labelKey), count = count, max = max}), textColor = utils.getSkillColor(category), font = isActive and "DefaultBold" or "Default", textSize = 14 },
                    events = { mouseClick = not isSearchActive and async:callback(function() self:sendEvent('BookWorm_ChangeFilter', { filter = category }) end) or nil }
                }})
            }
        end
        table.insert(contentItems, {
            type = ui.TYPE.Flex,
            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
            content = ui.content({
                createFilterBox('Library_Cat_Lore', counts.lore, master.lore, "lore"),
                { props = { size = util.vector2(10, 0) } },
                createFilterBox('Library_Cat_Combat', counts.combat, master.combat, "combat"),
                { props = { size = util.vector2(10, 0) } },
                createFilterBox('Library_Cat_Magic', counts.magic, master.magic, "magic"),
                { props = { size = util.vector2(10, 0) } },
                createFilterBox('Library_Cat_Stealth', counts.stealth, master.stealth, "stealth")
            })
        })
        
        local isSkillFilter = (not isNone and #activeFilter > 1)
        local divisor = isSkillFilter and master[activeFilter] or master.totalTomes
        local perc = math.floor((totalItems / divisor) * 100)
        
        local footerLabel = ""
        if isSkillFilter then 
            -- FIXED: Named key 'skill' - use activeFilter directly (localized name handled in L call)
            footerLabel = L('Library_Footer_Skill_Tomes', {skill = activeFilter})
        else 
            footerLabel = L('Library_Footer_Total_Tomes')
        end

        -- FIXED: Named key 'filter'
        if not isNone and #activeFilter == 1 then footerLabel = L('Library_Footer_Filtered', {filter = activeFilter}) end
        if searchString ~= "" then footerLabel = L('Library_Footer_Found') end
        
        -- FIXED: Named keys 'label', 'found', 'total', and 'percent'
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = L('Library_Footer_Stats_Format', {label = footerLabel, found = totalItems, total = divisor, percent = perc}), textSize = 16, textColor = utils.inkColor }})
        -- FIXED: Named key 'key'
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = L('Library_Export_Tomes_Hint', {key = openTomesK}), textSize = 12, textColor = util.color.rgb(0.4, 0.4, 0.4) }})
    else
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = L('Library_Letter_Filter_Hint'), textSize = 12, textColor = util.color.rgb(0.4, 0.4, 0.4), font = "Default" } })
        local perc = math.floor((totalItems / master.totalLetters) * 100)
        
        local footerLabel = L('Library_Footer_Total_Letters')
        -- FIXED: Named key 'filter'
        if not isNone and #activeFilter == 1 then footerLabel = L('Library_Footer_Filtered', {filter = activeFilter}) end
        if searchString ~= "" then footerLabel = L('Library_Footer_Found') end
        
        -- FIXED: Named keys 'label', 'found', 'total', and 'percent'
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = L('Library_Footer_Stats_Format', {label = footerLabel, found = totalItems, total = master.totalLetters, percent = perc}), textSize = 16, textColor = utils.inkColor }})
        -- FIXED: Named key 'key'
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = L('Library_Export_Letters_Hint', {key = openLettersK}), textSize = 12, textColor = util.color.rgb(0.4, 0.4, 0.4) }})
    end

    return ui.create({
        layer = 'Windows',
        type = ui.TYPE.Container,
        props = { 
            relativePosition = util.vector2(0.5, 0.5), 
            anchor = util.vector2(0.5, 0.5), 
            size = util.vector2(750, 780) 
        },
        content = ui.content({
            -- Layer 1: Independent Background
            {
                type = ui.TYPE.Widget,
                props = { 
                    size = util.vector2(750, 780),
                    -- Shift the entire widget container up by 50 pixels
                    position = util.vector2(0, -50) 
                },
                content = ui.content({
                    { 
                        type = ui.TYPE.Image, 
                        props = { 
                            resource = ui.texture({path = 'textures/background.dds'}), 
                            size = util.vector2(750, 780), 
                            color = utils.overlayTint
                        } 
                    }
                })
            },
            -- Layer 2: Centered Text Content
            { 
                type = ui.TYPE.Flex, 
                props = { 
                    column = true, 
                    arrange = ui.ALIGNMENT.Center, 
                    align = ui.ALIGNMENT.Center, 
                    padding = 60, 
                    size = util.vector2(750, 780) 
                }, 
                content = ui.content(contentItems) 
            }
        })
    })
end

return ui_library