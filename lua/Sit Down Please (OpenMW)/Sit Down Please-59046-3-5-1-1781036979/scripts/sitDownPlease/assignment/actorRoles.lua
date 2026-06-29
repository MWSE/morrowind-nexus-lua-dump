-- assignment/actorRoles.lua
---@omw-context none
-- Shared actor role/classification helpers used by assignment and local seeker validation.

local M = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

function M.isFactionLeader(actor, typesApi, coreApi)
    if not (actor and typesApi and typesApi.NPC and typesApi.NPC.objectIsInstance and typesApi.NPC.objectIsInstance(actor)) then
        return false
    end
    if not (typesApi.NPC.getFactions and typesApi.NPC.getFactionRank) then return false end
    if not (coreApi and coreApi.factions and coreApi.factions.records) then return false end

    local okFactions, factionIds = pcall(typesApi.NPC.getFactions, actor)
    if not okFactions or not factionIds then return false end

    for _, factionId in ipairs(factionIds) do
        local factionRec = coreApi.factions.records[factionId] or coreApi.factions.records[lower(factionId)]
        if factionRec and factionRec.ranks then
            local maxRank = #factionRec.ranks
            local okRank, rank = pcall(typesApi.NPC.getFactionRank, actor, factionId)
            if okRank and rank == maxRank and rank > 0 then
                return true
            end
        end
    end

    return false
end

function M.looksLikeVampire(actor, rec, typesApi)
    local recordId = lower(actor and actor.recordId)
    local cls = lower(rec and rec.class)
    local name = lower(rec and rec.name)
    if recordId:find("vampire", 1, true) or cls:find("vampire", 1, true) or name:find("vampire", 1, true) then
        return true
    end

    local okEffects, hasEffect = pcall(function()
        if not (typesApi and typesApi.Actor and typesApi.Actor.activeEffects and actor) then return false end
        local effects = typesApi.Actor.activeEffects(actor)
        if not effects or not effects.getEffect then return false end
        local vamp = effects:getEffect("vampirism")
        return vamp ~= nil and (tonumber(vamp.magnitude or 0) or 0) > 0
    end)
    return okEffects and hasEffect == true
end

return M
