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

local vfs = require('openmw.vfs')
local settings = require("scripts.ErnRadiantTheft.settings")
local world = require('openmw.world')
local types = require('openmw.types')

-- macguffins is a list of {category, type, record}.
local macguffins = {}

local function getRecord(itemtype, id)
    if itemtype == "Miscellaneous" then
        return types.Miscellaneous.records[id]
    end
    if itemtype == "Armor" then
        return types.Armor.records[id]
    end
    if itemtype == "Potion" then
        return types.Potion.records[id]
    end
    if itemtype == "Ingredient" then
        return types.Ingredient.records[id]
    end
    if itemtype == "Book" then
        return types.Book.records[id]
    end
    if itemtype == "Clothing" then
        return types.Clothing.records[id]
    end
    if itemtype == "Weapon" then
        return types.Weapon.records[id]
    end
    if itemtype == "Apparatus" then
        return types.Apparatus.records[id]
    end
    error("unknown type: " .. itemtype)
    return nil
end

-- filter returns true if the npc can have the macguffin.
local function filter(macguffin, npcRecord)
    -- don't pick macguffins that will be sold by the mark.
    local typeToService = {
        Miscellaneous = "Misc",
        Armor = "Armor",
        Potion = "Potions",
        Ingredient = "Ingredients",
        Book = "Books",
        Clothing = "Clothing"
    }
    local service = typeToService[macguffin.type]
    if service == nil then
        service = macguffin.type
    end
    if npcRecord.servicesOffered[service] then
        settings.debugPrint("not valid; would sell the macguffin")
        return false
    end

    -- only use trade_secrets category if they are a merchant
    if macguffin.category == "trade_secrets" then
        local isMerchant = (string.lower(npcRecord.class) == "merchant")
        for k, _ in pairs(npcRecord.servicesOffered) do
            isMerchant = true
        end
        if isMerchant == false then
            settings.debugPrint("not valid; trade_secrets but not a merchant")
            return false
        end
    end

    -- only use forgery and blackmail categories if they are not poor
    local poor = {
        farmer = true,
        commoner = true,
        herder = true,
        hunter = true,
        miner = true,
        pauper = true,
        slave = true,
    }
    if poor[string.lower(npcRecord.class)] and (macguffin.category == "blackmail" or macguffin.category == "forgery") then
        settings.debugPrint("not valid; blackmail or forgery but poor")
        return false
    end

    -- don't pick respawning npcs.
    if npcRecord.isRespawning then
        --settings.debugPrint("not valid; respawns")
        return false
    end

    -- guards have bad names. also, don't steal from slaves.
    if (string.lower(npcRecord.class) == "guard") or (string.lower(npcRecord.class) == "slave") then
        return false
    end

    -- don't pick NPCs that are in the guild.
    -- this is funky because we need to find or create the npc to figure that out.
    local inThievesGuild = false
    local inst = world.createObject(npcRecord.id, 1)
    for _, factionId in pairs(types.NPC.getFactions(inst)) do
        if factionId == "Thieves Guild" then
            inThievesGuild = true
            break
        end
    end
    inst:remove()
    if inThievesGuild then
        settings.debugPrint("not valid; in thieves guild")
        return false
    end

    return true
end

local function loadMacguffins()
    -- read allow list.
    local handle = nil
    local err = nil
    handle, err = vfs.open("scripts\\" .. settings.MOD_NAME .. "\\macguffins.txt")
    if handle == nil then
        error(err)
        return
    end

    for line in handle:lines() do
        -- there should be three fields: category, itemtype, itemrecordid.
        local split = {}
        for token in string.gmatch(line, "[^,]+") do
            table.insert(split, token)
        end

        if #split ~= 3 then
            error("line doesn't have 3 fields: " .. line)
        else
            -- this line is ok. strip spaces.
            split[1] = string.gsub(split[1], "%s", "")
            split[2] = string.gsub(split[2], "%s", "")
            split[3] = string.gsub(split[3], "%s", "")

            local record = getRecord(split[2], split[3])
            if record == nil then
                settings.debugPrint("couldn't find record for line: " .. line)
            else
                table.insert(macguffins, {
                    category = string.lower(split[1]),
                    type = split[2],
                    record = record,
                })
            end
        end
    end
    settings.debugPrint("Loaded " .. tostring(#macguffins) .. " macguffins into the allowlist.")
end

loadMacguffins()

return {
    macguffins = macguffins,
    filter = filter,
}
