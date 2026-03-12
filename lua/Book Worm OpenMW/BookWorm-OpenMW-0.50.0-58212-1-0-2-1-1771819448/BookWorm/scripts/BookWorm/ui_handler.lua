-- scripts/BookWorm/ui_handler.lua
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
 
local types = require('openmw.types')
local core = require('openmw.core')
local ui = require('openmw.ui')
local aux_ui = require('openmw_aux.ui') 
local nearby = require('openmw.nearby')

local L = core.l10n('BookWorm', 'en')
local ui_handler = {} -- Table initialization

function ui_handler.showUnreadList(params)
    local targetObj = (params.mode == "Interface") and params.self or params.target
    if not targetObj then return end

    local unread = {}
    local seen = {}

    -- Helper to process an inventory and add to the unread list
    local function processInventory(inv)
        for _, item in ipairs(inv:getAll(types.Book)) do
            local id = item.recordId:lower()
            if params.utils.isTrackable(id) and not (params.booksRead[id] or params.notesRead[id]) then
                local name = params.utils.getBookName(id)
                if not seen[name] then
                    local skillLabel, _ = params.utils.getSkillInfoLibrary(id)
                    table.insert(unread, { name = name, skill = skillLabel })
                    seen[name] = true
                end
            end
        end
    end

    -- 1. Scan Primary Target Inventory (Merchant, Container, or Player)
    local primaryInv = (targetObj.type == types.Player or targetObj.type == types.NPC or targetObj.type == types.Creature) 
                and types.Actor.inventory(targetObj) 
                or types.Container.inventory(targetObj)
    processInventory(primaryInv)

    -- 2. Scan Nearby Owned Assets (Mirroring handleModeChange Barter logic)
    if params.mode == "Barter" and types.NPC.objectIsInstance(targetObj) then
        local merchantRefId = targetObj.recordId:lower()

        -- Nearby Containers owned by this merchant
        for _, nearObj in pairs(nearby.containers) do
            local ownerId = nearObj.owner and nearObj.owner.recordId and nearObj.owner.recordId:lower()
            if ownerId == merchantRefId then
                if types.Container.capacity(nearObj) > 0 then
                    processInventory(types.Container.inventory(nearObj))
                end
            end
        end

        -- Nearby Loose Books owned by this merchant
        for _, nearObj in pairs(nearby.items) do
            local ownerId = nearObj.owner and nearObj.owner.recordId and nearObj.owner.recordId:lower()
            if ownerId == merchantRefId and nearObj.type == types.Book then
                -- Wrap loose item in a mock inventory table for processInventory
                processInventory({ getAll = function() return {nearObj} end })
            end
        end
    end

    if #unread == 0 then
        ui.showMessage(L('UiHandler_Msg_NoUnread'))
        return
    end

    local displayLimit = (params.cfg and params.cfg.unreadMaxList) or 10
    local lines = {}
    for i = 1, math.min(#unread, displayLimit) do
        local entry = unread[i]
        local lineText = "- " .. entry.name
        
        if entry.skill then
            lineText = lineText .. " (" .. entry.skill .. ")"
        end
        
        table.insert(lines, lineText)
    end

    local finalMsg = table.concat(lines, "\n")
    if #unread > displayLimit then
        finalMsg = finalMsg .. "\n" .. L('UiHandler_Msg_MoreBooks')
    end

    ui.showMessage(finalMsg)
end

function ui_handler.handleModeChange(data, state)
    local p = state
    local foundNewBook = false -- Local state tracking for discovery
    
    if p.isDebug then
        print(string.format("[BookWorm Debug] [ui_handler] handleModeChange: START "))
    end

    if p.activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then
        aux_ui.deepDestroy(p.activeWindow)
        return "CLOSE_LIBRARY" 
    end

    if data.newMode == "Book" or data.newMode == "Scroll" then 
        types.Actor.activeEffects(p.self):remove('invisibility')
        p.reader.mark(data.arg or p.lastLookedAtObj, p.booksRead, p.notesRead, p.utils) 
    
    elseif p.currentRemoteRecordId and data.newMode ~= "Book" and data.newMode ~= "Scroll" then
        core.sendGlobalEvent('BookWorm_CleanupRemote', { 
            recordId = p.currentRemoteRecordId, 
            player = p.self, 
            target = p.currentRemoteTarget 
        })
        return "CLEANUP_GHOST"
    end

    if (data.newMode == "Container" or data.newMode == "Barter") and data.arg then
        local obj = data.arg
        if types.Lockable.objectIsInstance(obj) and types.Lockable.isLocked(obj) then
            return
        end

        local record = obj.type.record(obj)
        local name = record and record.name or L('UiHandler_Label_Container_Fallback')
        local isCorpse = (obj.type == types.NPC or obj.type == types.Creature)
        
        local sourceLabel = ""
        if data.newMode == "Barter" then 
            sourceLabel = L('UiHandler_Label_Barter') 
        elseif isCorpse then
            sourceLabel = L('UiHandler_Label_Loot')
        else
            sourceLabel = L('UiHandler_Label_Container_Format', {name = name:lower()})
        end
        
        local inv = types.Actor.objectIsInstance(obj) and types.Actor.inventory(obj) or types.Container.inventory(obj)
        
        -- Case 1: Primary Target Scan
        if not foundNewBook then
            foundNewBook = p.invScanner.scan(inv, sourceLabel, p.booksRead, p.notesRead, p.utils, p.cfg, p.sessionState, p.self, obj, p.isDebug)
        end

        -- 0.50.0 Nearby Scan Logic
        if p.isDebug then
            print(string.format("[BookWorm Debug] [ui_handler] handleModeChange: check for barter chest logic "))
        end
        if data.newMode == "Barter" and types.NPC.objectIsInstance(obj) then
            
            local merchantRefId = obj.recordId:lower()

            if p.isDebug and merchantRefId then
                print(string.format("[BookWorm Debug] [ui_handler] handleModeChange: START barter chest logic (merchant: %s)",merchantRefId))
            end
            
            -- Case 2: Nearby Containers (Merchant Stocks)
            for _, nearObj in pairs(nearby.containers) do
                if foundNewBook then break end -- Optimization: Stop searching if already found
                
                local ownerId = nearObj.owner and nearObj.owner.recordId and nearObj.owner.recordId:lower()

                if p.isDebug and ownerId then
                    print(string.format("[BookWorm Debug] [ui_handler] handleModeChange: Found container (owner: %s)",ownerId))
                end

                if ownerId == merchantRefId then
                    if types.Container.capacity(nearObj) > 0 then
                        local shopInv = types.Container.inventory(nearObj)
                        local shopLabel = L('UiHandler_Label_ShopStock', {name = nearObj.type.record(nearObj).name})
                        foundNewBook = p.invScanner.scan(shopInv, shopLabel, p.booksRead, p.notesRead, p.utils, p.cfg, p.sessionState, p.self, nearObj, p.isDebug)
                    end
                end
            end

            -- Case 3: Nearby Loose Books (Owned by Merchant)
            for _, nearObj in pairs(nearby.items) do
                if foundNewBook then break end -- Optimization: Stop searching if already found

                local ownerId = nearObj.owner and nearObj.owner.recordId and nearObj.owner.recordId:lower()
                if ownerId == merchantRefId and nearObj.type == types.Book then
                    local looseInv = { getAll = function() return {nearObj} end }
                    foundNewBook = p.invScanner.scan(looseInv, sourceLabel, p.booksRead, p.notesRead, p.utils, p.cfg, p.sessionState, p.self, nearObj, p.isDebug)
                end
            end
        end

    elseif data.newMode == "Interface" and p.activeWindow == nil then
        -- Case 4: Player Inventory Scan
        if not foundNewBook then
            foundNewBook = p.invScanner.scan(types.Actor.inventory(p.self), L('UiHandler_Label_Inventory'), p.booksRead, p.notesRead, p.utils, p.cfg, p.sessionState, p.self, p.self, p.isDebug)
        end
    end

    if p.isDebug then
        print(string.format("[BookWorm Debug] [ui_handler] handleModeChange: END "))
    end
end

return ui_handler