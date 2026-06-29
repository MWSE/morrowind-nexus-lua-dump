-- Utils.lua
local Utils = {}
local core = require('openmw.core')
local ScheduleConfig = require('scripts.ProceduralChatter.data.ScheduleConfig')

function Utils.log(fmt, ...)
    if ScheduleConfig.DEBUG_MODE then
        if select('#', ...) > 0 then
            print(string.format(fmt, ...))
        else
            print(fmt)
        end
    end
end


function Utils.isObjValid(obj)
    local ok, valid = pcall(function()
        return obj and obj.isValid and obj:isValid()
    end)
    return ok and valid == true
end

local function shouldClearConversationForTeleport(obj, cell)
    if not obj then return false end
    -- Exterior / empty-cell teleports are hard relocations.
    if cell == "" then return true end

    local targetCellName = nil
    if type(cell) == "string" then
        targetCellName = string.lower(cell)
    else
        pcall(function()
            targetCellName = string.lower(cell and cell.name or "")
        end)
    end
    local currentCellName = nil
    pcall(function()
        currentCellName = string.lower(obj.cell and obj.cell.name or "")
    end)
    if not targetCellName or targetCellName == "" then return false end
    if not currentCellName then return false end
    return targetCellName ~= currentCellName
end

local function clearConversationBeforeTeleport(obj)
    if not obj then return end
    pcall(function()
        obj:sendEvent("PC_ClearMovementState", { preserveSchedule = true })
    end)
    pcall(function()
        core.sendGlobalEvent("PC_SetBusy", { npc = obj, npcId = obj.id, busy = false })
    end)
    pcall(function() obj:sendEvent("PC_Stop", {}) end)
    pcall(function() obj:sendEvent("PC_Return", {}) end)
end

function Utils.tryTeleport(obj, cell, pos, opts)
    if not Utils.isObjValid(obj) then
        return false, "Object is not available"
    end
    if shouldClearConversationForTeleport(obj, cell) then
        clearConversationBeforeTeleport(obj)
    end
    local ok, err = pcall(function()
        obj:teleport(cell, pos, opts)
    end)
    return ok, err
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.lerpAngle(a1, a2, t)
    local diff = a2 - a1
    while diff > math.pi do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    return a1 + diff * t
end

--- Unified NPC collection for a cell.
-- Merges cell:getAll(types.NPC) with world.activeActors fallback.
-- Safe to call from both global and local script contexts.
-- @param cell  cell object
-- @param opts  optional { useActiveActors = bool } (default true)
-- @return array of NPC actor objects
function Utils.collectCellNpcs(cell, opts)
    opts = opts or {}
    local result = {}
    local seen = {}
    if not cell then return result end

    local types = require('openmw.types')
    local playerId = nil
    pcall(function()
        local world = require('openmw.world')
        local player = world and world.players and world.players[1]
        playerId = player and player.id or nil
    end)

    -- Primary: direct cell scan
    local okCell, cellActors = pcall(function() return cell:getAll(types.NPC) end)
    if okCell and cellActors then
        for _, npc in ipairs(cellActors) do
            if npc and npc.id and npc.id ~= playerId and not seen[npc.id] then
                seen[npc.id] = true
                result[#result + 1] = npc
            end
        end
    end

    -- Fallback: merge activeActors that are in the same cell
    if opts.useActiveActors ~= false then
        local targetCellName = ""
        pcall(function() targetCellName = string.lower(cell.name or "") end)

        local world
        pcall(function() world = require('openmw.world') end)
        if world then
            local okActive, activeActors = pcall(function() return world.activeActors end)
            if okActive and activeActors then
                for _, actor in ipairs(activeActors) do
                    local isNpc = false
                    pcall(function() isNpc = types.NPC.objectIsInstance(actor) end)
                    if isNpc and actor and actor.id and actor.id ~= playerId and not seen[actor.id] then
                        local sameCell = false
                        pcall(function()
                            sameCell = (actor.cell == cell) or
                                (targetCellName ~= "" and string.lower(actor.cell and actor.cell.name or "") == targetCellName)
                        end)
                        if sameCell then
                            seen[actor.id] = true
                            result[#result + 1] = actor
                        end
                    end
                end
            end
        end
    end

    return result
end

return Utils
