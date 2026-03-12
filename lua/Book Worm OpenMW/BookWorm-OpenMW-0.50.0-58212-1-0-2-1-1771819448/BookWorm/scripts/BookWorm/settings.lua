-- scripts/BookWorm/settings.lua
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

local I = require('openmw.interfaces')

-- Match the engine's usage example in scripts/omw/settings/player.lua
I.Settings.registerPage({
    key = "BookWorm",
    l10n = "BookWorm", 
    name = "Settings_Page_Name", -- Key in l10n/BookWorm/en.yaml
    description = "Settings_Page_Desc" -- Key in l10n/BookWorm/en.yaml
})

-- UI Settings Group
I.Settings.registerGroup({
    key = "Settings_BookWorm_UI",
    page = "BookWorm",
    l10n = "BookWorm",
    name = "Settings_GroupUI_Name",
    permanentStorage = true, -- Stored in permanent storage (Main Menu context)
    order = 1,
    settings = {
        {
            key = "itemsPerPage",
            name = "Settings_ItemsPerPage_Name",
            description = "Settings_ItemsPerPage_Desc",
            type = "number", -- Required by engine for 'number' renderer
            default = 20,
            renderer = "number",
            argument = { min = 5, max = 30, step = 1 },
            order = 1
        },
        {
            key = "unreadMaxList",
            name = "Settings_UnreadMaxList_Name",
            description = "Settings_UnreadMaxList_Desc",
            type = "number",
            default = 10,
            renderer = "number",
            argument = { min = 1, max = 30, step = 1 },
            order = 2
        },
    }
})

-- Keybindings Group
I.Settings.registerGroup({
    key = "Settings_BookWorm_Keys",
    page = "BookWorm",
    l10n = "BookWorm",
    name = "Settings_GroupKeys_Name",
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = "openTomesKey",
            name = "Settings_OpenTomes_Name",
            description = "Settings_OpenTomes_Desc",
            type = "string", -- Required for 'textLine' renderer
            default = "k",
            renderer = "textLine",
            order = 1
        },
        {
            key = "openLettersKey",
            name = "Settings_OpenLetters_Name",
            description = "Settings_OpenLetters_Desc",
            type = "string",
            default = "l",
            renderer = "textLine",
            order = 2
        },
        {
            key = "prevPageKey",
            name = "Settings_PrevPage_Name",
            description = "Settings_PrevPage_Desc",
            type = "string",
            default = "i",
            renderer = "textLine",
            order = 3
        },
        {
            key = "nextPageKey",
            name = "Settings_NextPage_Name",
            description = "Settings_NextPage_Desc",
            type = "string",
            default = "o",
            renderer = "textLine",
            order = 4
        },
        {
            key = "listUnreadKey",
            name = "Settings_ListUnread_Name",
            description = "Settings_ListUnread_Desc",
            type = "string",
            default = "p",
            renderer = "textLine",
            order = 5
        }
    }
})

-- Notifications Group
I.Settings.registerGroup({
    key = "Settings_BookWorm_Notif",
    page = "BookWorm",
    l10n = "BookWorm",
    name = "Settings_GroupNotif_Name",
    permanentStorage = true,
    order = 3,
    settings = {
         {
            key = "displayNotificationMessage",
            name = "Settings_DisplayNotif_Name",
            description = "Settings_DisplayNotif_Desc",
            type = "boolean",
            default = true,
            renderer = "checkbox",
            order = 1
        },
        {
            key = "displayNotificationMessageOnReading",
            name = "Settings_DisplayNotifRead_Name",
            description = "Settings_DisplayNotifRead_Desc",
            type = "boolean",
            default = true,
            renderer = "checkbox",
            order = 2
        },
        {
            key = "throttleInventoryNotifications",
            name = "Settings_Throttle_Name",
            description = "Settings_Throttle_Desc",
            type = "boolean",
            default = true,
            renderer = "checkbox",
            order = 3
        },
        {
            key = "playNotificationSounds",
            name = "Settings_PlaySounds_Name",
            description = "Settings_PlaySounds_Desc",
            type = "boolean",
            default = true,
            renderer = "checkbox",
            order = 4
        },
        {
            key = "recognizeSkillBooks",
            name = "Settings_RecognizeSkill_Name",
            description = "Settings_RecognizeSkill_Desc",
            type = "boolean",
            default = true,
            renderer = "checkbox",
            order = 5
        },
        {
            key = "showSkillNames",
            name = "Settings_ShowSkillNames_Name",
            description = "Settings_ShowSkillNames_Desc",
            type = "boolean",
            default = true,
            renderer = "checkbox",
            order = 6
        },
        {
            key = "playSkillNotificationSounds",
            name = "Settings_PlaySkillSounds_Name",
            description = "Settings_PlaySkillSounds_Desc",
            type = "boolean",
            default = true,
            renderer = "checkbox",
            order = 7
        }
    }
})