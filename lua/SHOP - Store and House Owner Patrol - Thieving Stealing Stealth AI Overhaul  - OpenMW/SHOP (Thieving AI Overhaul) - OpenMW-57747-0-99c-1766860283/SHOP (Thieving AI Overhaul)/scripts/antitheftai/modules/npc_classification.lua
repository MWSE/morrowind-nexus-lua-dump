--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

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
----------------------------------------------------------------------
-- Anti-Theft Guard AI  •  v0.9 PUBLIC TEST  •  OpenMW ≥ 0.49
----------------------------------------------------------------------
-- NPC Classification and Filtering
----------------------------------------------------------------------

local classification = {}
local settings = require('scripts.antitheftai.SHOPsettings')
local config = require('scripts.antitheftai.modules.config')

-- Filter tables
classification.disabledNpcNames = {}
classification.disabledNpcNameContains = {}
classification.disabledCellNames = {}
classification.disabledCellNameContains = {}
local seenMessages = {}

local function log(...)
    if settings.general:get("enableDebug") then
        local args = {...}
        for i, v in ipairs(args) do
            args[i] = tostring(v)
        end
        local msg = table.concat(args, " ")
        if not seenMessages[msg] then
            print("[NPC-Class]", ...)
            seenMessages[msg] = true
        end
    end
end

-- Parse filter list
local function parseFilterList(filterString)
    local result = {}
    if filterString and filterString ~= "" then
        for name in string.gmatch(filterString, '([^,]+)') do
            name = name:gsub("^%s*(.-)%s*$", "%1")
            result[name:lower()] = true
        end
    end
    return result
end

-- Initialize filters
function classification.initializeFilters(config)
    local disabledNpcNames = parseFilterList(table.concat(config.DISABLED_NPC_NAMES, ","))
    classification.disabledNpcNameContains = parseFilterList(table.concat(config.DISABLED_NPC_NAME_CONTAINS, ","))
    local disabledCellNames = {}
    for _, name in ipairs(config.DISABLED_CELL_NAMES) do
        disabledCellNames[name:lower()] = true
    end
    classification.disabledCellNameContains = parseFilterList(table.concat(config.DISABLED_CELL_NAME_CONTAINS, ","))

    log("Initialized NPC filters:", table.concat(config.DISABLED_NPC_NAMES, ", "))
    log("Initialized NPC contains filters:", table.concat(config.DISABLED_NPC_NAME_CONTAINS, ", "))
    log("Initialized cell filters:", table.concat(config.DISABLED_CELL_NAMES, ", "))
    log("Initialized cell contains filters:", table.concat(config.DISABLED_CELL_NAME_CONTAINS, ", "))

    return disabledNpcNames, disabledCellNames
end

-- Get NPC priority
function classification.getNPCPriority(npc, types, player, cell, config, nearby)
    if not npc or not npc:isValid() then return 999 end

    local npcClass = types.NPC.record(npc).class
    if not npcClass then return 999 end

    local className = npcClass:lower()

    -- Guards first
    if className:find("guard") or className:find("soldier") or
       className:find("archer") or className:find("warrior") or
       className:find("knight") then
        return 1
    end

    -- Check services
    local hasServices = false
    local isMerchant = false

    if types.NPC.getServicesOffered then
        local services = types.NPC.getServicesOffered(npc)
        if services then
            if services.Barter then isMerchant = true end
            if services.Training or services.Spellmaking or
               services.Enchanting or services.Repair or services.Travel then
                hasServices = true
            end
        end
    end

    -- Check class names
    if className:find("merchant") or className:find("trader") or
       className:find("pawnbroker") or className:find("smith") or
       className:find("alchemist") or className:find("bookseller") or
       className:find("clothier") then
        isMerchant = true
    elseif className:find("trainer") or className:find("master") or
           className:find("enchanter") or className:find("spellmaker") or
           className:find("priest") or className:find("healer") or
           className:find("caravaner") or className:find("shipmaster") then
        hasServices = true
    end

    local basePriority
    if hasServices then 
        basePriority = 3
    elseif isMerchant then 
        basePriority = 4
    else 
        basePriority = 2
    end

    -- Check if we're in a guild cell and handle high-rank player restrictions
    if cell and config and not cell.isExterior then
        -- Dynamically detect cell faction from NPCs in the cell
        local cellFaction = nil
        local factionCounts = {}

        -- Count faction occurrences among NPCs in the cell
        for _, actor in ipairs(nearby.actors) do
            if actor.type == types.NPC and actor:isValid() then
                local npcFactions = types.NPC.getFactions(actor)
                for _, factionId in ipairs(npcFactions) do
                    factionCounts[factionId] = (factionCounts[factionId] or 0) + 1
                end
            end
        end

        -- Find the most common faction (must be at least 2 NPCs to consider it a guild cell)
        local maxCount = 0
        for factionId, count in pairs(factionCounts) do
            if count >= 2 and count > maxCount then
                maxCount = count
                cellFaction = factionId
            end
        end
        
        if cellFaction then
            log("Cell", cell.name or "", "detected as", cellFaction, "guild cell (", maxCount, "members)")

            -- Check if player has high rank in this faction
            if player and types.Player and types.Player.factions then
                local playerFactions = types.Player.factions(player)
                for _, pf in ipairs(playerFactions) do
                    if pf.factionId == cellFaction then
                        local playerRank = pf.rank
                        local threshold = config.FACTION_IGNORE_RANK
                        log("Player has rank", playerRank, "in", pf.factionId,
                            "(threshold:", threshold, ")")

                        if playerRank >= threshold then
                            log("Player rank >= threshold – disabling NPC following in this cell")
                            return 999  -- Disable following
                        else
                            log("Player rank < threshold – allowing NPC following in this cell")
                        end
                    end
                end
            end

            -- For guild cells, prefer lowest rank NPCs (except merchants)
            if not isMerchant then
                local npcFactions = types.NPC.getFactions(npc)
                for _, nf in ipairs(npcFactions) do
                    if nf == cellFaction then
                        local rank = types.NPC.getFactionRank(npc, nf)
                        if rank > 0 then
                            -- Lower rank = lower priority number (preferred)
                            basePriority = basePriority - (11 - rank)  -- Invert so rank 1 gets most preference
                            log("Adjusted priority for NPC", npc.id, "in cell faction", nf, "rank", rank, "new priority", basePriority)
                        end
                    end
                end
            end
        end
    end

    -- Adjust for faction rank - NPCs in player's factions are less preferred (higher priority number)
    if player and types.Player and types.Player.factions then
        local playerFactions = types.Player.factions(player)
        local npcFactions = types.NPC.getFactions(npc)
        for _, pf in ipairs(playerFactions) do
            for _, nf in ipairs(npcFactions) do
                if pf.factionId == nf then
                    local rank = types.NPC.getFactionRank(npc, nf)
                    if rank > 0 then
                        -- NPCs in player's faction are penalized (higher priority = less preferred)
                        basePriority = basePriority + rank
                        log("Penalized priority for NPC", npc.id, "in player faction", pf.factionId, "rank", rank, "new priority", basePriority)
                    end
                end
            end
        end
    end

    return math.max(1, basePriority)  -- ensure not negative
end

function classification.getPriorityName(priority)
    if priority == 1 then return "Guard"
    elseif priority == 2 then return "Commoner"
    elseif priority == 3 then return "Service"
    elseif priority == 4 then return "Merchant"
    else return "Unknown"
    end
end

-- Check if NPC is disabled
function classification.isNpcDisabled(npc, disabledNpcNames, types)
    if not npc or not npc:isValid() then return false end
    local npcName = types.NPC.record(npc).name or ""
    local lowerName = npcName:lower()
    if disabledNpcNames[lowerName] then return true end
    for contains in pairs(classification.disabledNpcNameContains) do
        if lowerName:find(contains, 1, true) then return true end
    end

    -- Check for Travel service - completely ignore these NPCs
    -- This prevents Silt Strider caravaners, Boat masters, and Guild Guides from following
    if types and types.NPC and types.NPC.getServicesOffered then
         local services = types.NPC.getServicesOffered(npc)
         if services and services.Travel then
             log("Disabling script for NPC with Travel service:", npc.id)
             return true
         end
    end

    -- Fallback class name check for Travel providers
    local npcClass = types.NPC.record(npc).class
    if npcClass then
        local lowerClass = npcClass:lower()
        if lowerClass:find("caravaner") or lowerClass:find("shipmaster") or lowerClass:find("guild guide") or lowerClass:find("gondolier") then
             log("Disabling script for NPC with Travel class:", lowerClass)
             return true
        end
    end

    -- Check for chargen NPCs if setting is enabled
    local settings = require('scripts.antitheftai.SHOPsettings')
    local enabled = settings.compatibility:get('disableScriptOnChargenNPCs')
    log("Disable chargen setting enabled:", enabled)
    if enabled then
        local record = types.NPC.record(npc)
        local recordId = record and record.id or ""
        log("Checking NPC record ID for chargen:", recordId)
        if recordId:lower():find("chargen", 1, true) then
            log("Disabling script for chargen NPC:", recordId)
            return true
        end
    end

    return false
end

-- Check if cell is disabled
function classification.isCellDisabled(cell, disabledCellNames)
    if not cell then return false end
    local cellName = cell.name or ""
    local lowerName = cellName:lower()
    if disabledCellNames[lowerName] then return true end
    for contains in pairs(classification.disabledCellNameContains) do
        if lowerName:find(contains, 1, true) then return true end
    end
    return false
end

-- Check for slaves and enemies
function classification.shouldDisableCellForSlavesAndEnemies(nearby, types)
    local hasSlaves = false
    local hasEnemies = false

    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC then
            local record = types.NPC.record(actor)
            if record then
                if record.class and record.class:lower() == "slave" then
                    hasSlaves = true
                end
                local fightRating = types.Actor.stats.ai.fight(actor).modified
                if fightRating >= 80 then
                    hasEnemies = true
                end
            end
        end
    end

    return hasSlaves and hasEnemies
end

-- Check for only enemies
function classification.shouldDisableCellForOnlyEnemies(nearby, types)
    local hasEnemies = false
    local hasNonEnemies = false

    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC then
            local fightRating = types.Actor.stats.ai.fight(actor).modified
            if fightRating >= 80 then
                hasEnemies = true
            else
                hasNonEnemies = true
            end
        end
    end

    return hasEnemies and not hasNonEnemies
end

-- Check for publican NPCs
function classification.shouldDisableCellForPublican(nearby, types)
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC then
            local record = types.NPC.record(actor)
            if record and record.class and (record.class:lower() == "publican" or record.class:lower() == "t_glb_publican") then
                return true
            end
        end
    end
    return false
end

-- Detect cell faction from NPCs in the cell
function classification.detectCellFaction(nearby, types)
    local factionCounts = {}

    -- Count faction occurrences among NPCs in the cell
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC and actor:isValid() then
            local npcFactions = types.NPC.getFactions(actor)
            for _, factionId in ipairs(npcFactions) do
                factionCounts[factionId] = (factionCounts[factionId] or 0) + 1
            end
        end
    end

    -- Find the most common faction (must be at least 2 NPCs to consider it a guild cell)
    local maxCount = 0
    local cellFaction = nil
    for factionId, count in pairs(factionCounts) do
        if count >= 2 and count > maxCount then
            maxCount = count
            cellFaction = factionId
        end
    end

    return cellFaction
end

-- Check if player is in a faction
function classification.isPlayerInFaction(factionName, self, types)
    if not factionName or factionName == "" then return false end
    if not types or not types.NPC or not types.NPC.getFactions then
        log("ERROR: types.NPC.getFactions not available")
        return false
    end
    local playerFactions = types.NPC.getFactions(self)
    log("Checking faction:", factionName, "Player factions count:", #playerFactions)
    for _, factionId in ipairs(playerFactions) do
        log("Player faction:", factionId)
        if factionId == factionName then
            log("Player is in faction:", factionName)
            return true
        end
    end
    log("Player is NOT in faction:", factionName)
    return false
end

-- Check if NPC has any services (merchant, trainer, etc.)
function classification.hasServices(npc, types)
    if not npc or not npc:isValid() then return false end

    -- Check services via API
    if types.NPC.getServicesOffered then
        local services = types.NPC.getServicesOffered(npc)
        if services then
            if services.Barter or services.Training or services.Spellmaking or
               services.Enchanting or services.Repair or services.Travel then
                return true
            end
        end
    end

    -- Fallback: check class names
    local npcClass = types.NPC.record(npc).class
    if not npcClass then return false end
    local className = npcClass:lower()

    if className:find("merchant") or className:find("trader") or
       className:find("pawnbroker") or className:find("smith") or
       className:find("alchemist") or className:find("bookseller") or
       className:find("clothier") or className:find("trainer") or
       className:find("master") or className:find("enchanter") or
       className:find("spellmaker") or className:find("priest") or
       className:find("healer") or className:find("caravaner") or
       className:find("shipmaster") then
        return true
    end

    return false
end

-- Check if NPC is a merchant (Barter service or class name)
function classification.isMerchant(npc, types)
    if not npc or not npc:isValid() then return false end

    -- Check services via API
    if types.NPC.getServicesOffered then
        local services = types.NPC.getServicesOffered(npc)
        if services and services.Barter then
            return true
        end
    end

    -- Fallback: check class names
    local npcClass = types.NPC.record(npc).class
    if not npcClass then return false end
    local className = npcClass:lower()

    if className:find("merchant") or className:find("trader") or
       className:find("pawnbroker") or className:find("smith") or
       className:find("alchemist") or className:find("bookseller") or
       className:find("clothier") or className:find("outfitter")  then
        return true
    end

    return false
end

return classification