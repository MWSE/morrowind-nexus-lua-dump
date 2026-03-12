-- scripts/BookWorm/inventory_scanner.lua
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
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core') 
local self = require('openmw.self')

local L = core.l10n('BookWorm', 'en')
local inventory_scanner = {}

function inventory_scanner.scan(inv, sourceLabel, booksRead, notesRead, utils, cfg, sessionState, player, owner, isDebug)
    local didShowMessage = false -- Local state at start

    if isDebug then
        print(string.format("[BookWorm Debug] [inventory_scanner] START: inventory_scanner.scan "))
    end

    if not inv or not utils or not sessionState then return didShowMessage end
    
    if isDebug then
        for _, item in ipairs(inv:getAll()) do
            print(string.format("[BookWorm Debug] [inventory_scanner] All Item: %s (Count: %d) in %s", item.recordId, item.count, sourceLabel))
        end    
    end

    local isPlayerInv = (owner == player)
    local currentMsg = ""
    local skillLabelForSound = nil -- Track for sound logic

    for _, item in ipairs(inv:getAll(types.Book)) do
        if isDebug then
            print(string.format("[BookWorm Debug] [inventory_scanner] Scanning Item: %s (Count: %d) in %s", item.recordId, item.count, sourceLabel))
        end

        local id = item.recordId:lower()
        if utils.isTrackable(id) and not (booksRead[id] or notesRead[id]) then
            local bookName = utils.getBookName(id)
            local skillLabel, _ = utils.getSkillInfo(id)
            local isNote = utils.isLoreNote(id)
            
            if isNote then
                currentMsg = L('InvScanner_Msg_Letter', {source = sourceLabel, name = bookName})
                skillLabelForSound = nil
            elseif skillLabel then
                local labelText = L('InvScanner_Msg_RareTome') 
                if cfg.showSkillNames then
                    labelText = L('InvScanner_Msg_SkillTome', {skill = skillLabel})
                end
                currentMsg = L('InvScanner_Msg_Discovery_Complex', {label = labelText, source = sourceLabel, name = bookName})
                skillLabelForSound = skillLabel
            else
                currentMsg = L('InvScanner_Msg_Discovery_Simple', {source = sourceLabel, name = bookName})
                skillLabelForSound = nil
            end

            if not isPlayerInv then
                if cfg.displayNotificationMessage then
                    ui.showMessage(currentMsg)
                    didShowMessage = true -- Set state to true
                end

                if cfg.playNotificationSounds then
                    if skillLabel and cfg.playSkillNotificationSounds then 
                        ambient.playSound("skillraise") 
                    else
                        ambient.playSound("Book Open")
                    end
                end
                return didShowMessage -- Return boolean
            end
        end
    end

    -- handle player inventory here. we only consider last item in the book list (= latest)
    if isPlayerInv then
        if isDebug then
            print(string.format("[BookWorm Debug] [inventory_scanner] inventory_scanner.scan: Last message: %s. ",currentMsg))
        end

        local shouldDisplay = true
        if cfg.throttleInventoryNotifications then
            if currentMsg == sessionState.InventoryDiscoveryMessage then
                shouldDisplay = false
            else
                sessionState.InventoryDiscoveryMessage = currentMsg
            end
        end

        if shouldDisplay and currentMsg ~= "" then
            if cfg.displayNotificationMessage then
                ui.showMessage(currentMsg)
                didShowMessage = true -- Set state to true
            end

            if cfg.playNotificationSounds then
                if skillLabelForSound and cfg.playSkillNotificationSounds then 
                    ambient.playSound("skillraise") 
                else
                    ambient.playSound("Book Open")
                end
            end
        else
            if isDebug then
                print(string.format("[BookWorm Debug] [inventory_scanner] inventory_scanner.scan: Throttle player inventory messages. "))
            end
            -- Note: We still return didShowMessage (which is false here)
        end
    end

    if isDebug then
        print(string.format("[BookWorm Debug] [inventory_scanner] END: inventory_scanner.scan "))
    end

    return didShowMessage -- Return boolean at end
end

return inventory_scanner
