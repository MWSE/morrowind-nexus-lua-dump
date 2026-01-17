local types = require('openmw.types')
local core = require('openmw.core')

local companionDetection = {}

----------------------------------------------------------------------
-- HELPER: Get Player
----------------------------------------------------------------------
local function getPlayer(npc)
    -- In OpenMW, we can't context-switch requires, so we must rely on what's available
    -- or pass the player object IN if possible.
    -- However, we can TRY to require things inside pcall to avoid crash on load.
    
    local successNearby, nearby = pcall(require, 'openmw.nearby')
    if successNearby and nearby.players and #nearby.players > 0 then
         return nearby.players[1]
    end

    local successWorld, world = pcall(require, 'openmw.world')
    if successWorld and world.players and #world.players > 0 then
        return world.players[1]
    end

    local successSelf, selfModule = pcall(require, 'openmw.self')
    if successSelf and selfModule.type == types.Player then
        return selfModule
    end

    return nil
end

----------------------------------------------------------------------
-- LOGGING
----------------------------------------------------------------------
local function log(...)
    print("[CompanionDetection]", ...)
end

-- Detects vanilla companion NPCs (NPCs following player via AI packages)
-- Excludes them from anti-theft script reactions
-- @param npc - The NPC actor to check
-- @return true if NPC is a companion, false otherwise
function companionDetection.isCompanion(npc)
    if not npc or not npc:isValid() then
        return false
    end
    
    local npcId = npc.id
    local recordId = npc.recordId and npc.recordId:lower() or ""

    -- 1. Check Record ID for Summons
    if recordId:find("_summon$") or recordId:find("_summ$") then
        return true
    end

    -- 2. Check AI Packages (Preferred)
    local aiChecked = false
    
    -- [Method A] types.Actor.activeAI (Current package)
    if types.Actor.activeAI then
        local status, aiState = pcall(types.Actor.activeAI, npc)
        if status and aiState then
            aiChecked = true
            if aiState.package and (aiState.package.type == 'Follow' or aiState.package.type == 'Escort') then
                return true
            end
        end
    end

    -- [Method B] types.Actor.getAiSequence (Full stack)
    if types.Actor.getAiSequence then
        local status, sequence = pcall(types.Actor.getAiSequence, npc)
        if status and sequence then
            aiChecked = true
            for _, pkg in ipairs(sequence) do
                if pkg and (pkg.type == "Follow" or pkg.type == "Escort") then
                    return true
                end
            end
        end
    end

    -- 3. Heuristic Fallback for Local Scripts (Where AI checks might fail/return nil on other actors)
    -- Only use this if AI checks failed or returned no results (due to access restrictions)
    local player = getPlayer(npc)
    if player then
        local dist = (npc.position - player.position):length()
        if dist < 400 then
            -- Fallback: Disposition Check
            -- High disposition + Close proximity = Likely Companion
            local disposition = types.NPC.getDisposition(npc, player)
            if disposition and disposition >= 80 then
                 return true
            end
        end
    end
    
    return false
end

return companionDetection
