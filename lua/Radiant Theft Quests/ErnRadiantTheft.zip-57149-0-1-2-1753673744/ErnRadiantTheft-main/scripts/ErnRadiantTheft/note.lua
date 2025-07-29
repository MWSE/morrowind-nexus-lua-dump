--[[
ErnRadiantTheft for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local settings = require("scripts.ErnRadiantTheft.settings")
local aux_util = require('openmw_aux.util')
local types = require("openmw.types")
local common = require("scripts.ErnRadiantTheft.common")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)
local world = require('openmw.world')

local function giveNote(player, number, category, itemRecord, npcRecord, cell)
    local cellName = cell.name
    if cellName == "" or cellName == nil then
        cellName = cell.region
    end

    local additionalID = npcRecord.class
    if math.random(2) == 1 then
        additionalID = npcRecord.race
    end

    local recordFields = {
        enchant = nil,
        enchantCapacity = 0,
        icon = "icons\\m\\tx_parchment_02.dds",
        isScroll = true,
        model = "meshes\\m\\text_parchment_02.nif",
        name = localization("heist_" .. category .. "_name", { number = number }),
        skill = nil,
        text = localization("heist_" .. category .. "_body",
            { item = itemRecord.name, npc = npcRecord.name, additionalID = additionalID, location = cellName }),
    }

    local draftRecord = types.Book.createRecordDraft(recordFields)
    local record = world.createRecord(draftRecord)
    local noteInstance = world.createObject(record.id)
    noteInstance:moveInto(player)
end

return {
    giveNote = giveNote,
}
