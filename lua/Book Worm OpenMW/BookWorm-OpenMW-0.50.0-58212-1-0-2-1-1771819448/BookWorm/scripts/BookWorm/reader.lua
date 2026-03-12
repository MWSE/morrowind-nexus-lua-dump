-- reader.lua
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
local storage = require('openmw.storage')

local L = core.l10n('BookWorm', 'en')
local reader = {}

local notifSettings = storage.playerSection("Settings_BookWorm_Notif")

function reader.mark(obj, booksRead, notesRead, utils)
    if not obj or obj.type ~= types.Book or not utils.isTrackable(obj.recordId) then return end
    
    local id = obj.recordId:lower()
    local isNote = utils.isLoreNote(id)
    local targetTable = isNote and notesRead or booksRead
    
    local bookName = utils.getBookName(id)
    local recognizeSkills = notifSettings:get("recognizeSkillBooks")
    local showNames = notifSettings:get("showSkillNames")
    local canShow = notifSettings:get("displayNotificationMessageOnReading")

    if targetTable[id] then 
        if canShow then
            -- ICU Named: (Already read) {name}
            ui.showMessage(L('Reader_Msg_AlreadyRead', {name = bookName}))
        end
    else
        targetTable[id] = core.getSimulationTime()
        
        if canShow then
            local skillId, _ = utils.getSkillInfo(id)
            if skillId and recognizeSkills then
                local labelText = L('Reader_Msg_RareTome')
                if showNames then
                    local skillLabel = skillId:sub(1,1):upper() .. skillId:sub(2)
                    -- ICU Named: {skill} tome
                    labelText = L('Reader_Msg_SkillTome', {skill = skillLabel})
                end
                -- ICU Named: Marked as read: {name} ({label})
                ui.showMessage(L('Reader_Msg_MarkedRead_Complex', {name = bookName, label = labelText}))
            else
                -- ICU Named: Marked as read: {name}
                ui.showMessage(L('Reader_Msg_MarkedRead_Simple', {name = bookName}))
            end
        end
    end
end

return reader