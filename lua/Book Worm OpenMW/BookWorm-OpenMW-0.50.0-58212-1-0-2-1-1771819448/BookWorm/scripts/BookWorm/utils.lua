-- utils.lua
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
local util = require('openmw.util')
local storage = require('openmw.storage')
local core = require('openmw.core') 

local L = core.l10n('BookWorm', 'en')
local SKILL_L = core.l10n('SKILLS') -- Localized skill names from engine
local utils = {}

local notifSettings = storage.playerSection("Settings_BookWorm_Notif")

utils.FILTER_NONE = "UNSELECTED_FILTER_STATE"

utils.inkColor = util.color.rgb(0.15, 0.1, 0.05)      
utils.combatColor = util.color.rgb(0.6, 0.2, 0.1)    
utils.magicColor = util.color.rgb(0.0, 0.35, 0.65)   
utils.stealthColor = util.color.rgb(0.1, 0.5, 0.2)   
utils.blackColor = util.color.rgb(0, 0, 0)
utils.overlayTint = util.color.rgba(1, 1, 1, 0.3)

utils.blacklist = {
    ["sc_paper plain"] = true, 
    ["sc_paper_plain_01"] = true,
    ["sc_note_01"] = true, 
    ["sc_scroll"] = true,
    ["bk_a1_1_caiuspackage"] = true,
    ["bk_a1_1_caiusorders"] = true,
    ["char_gen_sheet"] = true,
    ["char_gen_papers"] = true,
    ["chargen statssheet"] = true,
    ["sc_messenger_note"] = true,
    ["text_paper_roll_01"] = true,
    ["t_sc_blank"] = true,
    ["t_sc_crumpledpaper_01"] = true,
}

utils.skillCategories = {
    armorer = "combat", athletics = "combat", axe = "combat", block = "combat", 
    bluntweapon = "combat", heavyarmor = "combat", longblade = "combat", 
    mediumarmor = "combat", spear = "combat",
    alchemy = "magic", alteration = "magic", conjuration = "magic", destruction = "magic", 
    enchant = "magic", illusion = "magic", mysticism = "magic", restoration = "magic", 
    unarmored = "magic",
    acrobatics = "stealth", lightarmor = "stealth", marksman = "stealth", 
    mercantile = "stealth", security = "stealth", shortblade = "stealth", 
    sneak = "stealth", speechcraft = "stealth", handtohand = "stealth"
}

function utils.isTrackable(id)
    local lowerId = id:lower()
    if utils.blacklist[lowerId] then return false end
    local record = types.Book.record(lowerId)
    if not record then return false end
    if record.enchant ~= nil then return false end
    return true
end

function utils.getBookName(id)
    local record = types.Book.record(id)
    return record and record.name or L('Utils_Name_Fallback', {id = id})
end

-- Used for Notifications (Localized)
function utils.getSkillInfo(id)
    if not notifSettings:get("recognizeSkillBooks") then return nil, "lore" end
    if not utils.isTrackable(id) then return nil, "unknown" end
    local record = types.Book.record(id)
    if record and record.skill then
        local skillId = record.skill:lower()
        return SKILL_L(record.skill), utils.skillCategories[skillId] or "unknown"
    end
    return nil, "lore"
end

-- Used for Library UI (Localized)
function utils.getSkillInfoLibrary(id)
    if not utils.isTrackable(id) then return nil, "unknown" end
    local record = types.Book.record(id)
    if record and record.skill then
        local skillId = record.skill:lower()
        return SKILL_L(record.skill), utils.skillCategories[skillId] or "unknown"
    end
    return nil, "lore"
end

-- Used for Export to Log (Strict English/Internal ID)
function utils.getSkillInfoExport(id)
    if not utils.isTrackable(id) then return nil, "unknown" end
    local record = types.Book.record(id)
    if record and record.skill then
        local skillId = record.skill:lower()
        -- Return raw skill identifier (e.g. "acrobatics")
        return record.skill, utils.skillCategories[skillId] or "unknown"
    end
    return nil, "lore"
end

function utils.getSkillColor(category)
    if category == "combat" then return utils.combatColor
    elseif category == "magic" then return utils.magicColor
    elseif category == "stealth" then return utils.stealthColor
    end
    return utils.blackColor
end

function utils.isLoreNote(id)
    if not utils.isTrackable(id) then return false end
    local record = types.Book.record(id)
    return record and record.isScroll
end

return utils