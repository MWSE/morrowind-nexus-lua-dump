-- Companion Detection Module
-- Detects vanilla companion NPCs (NPCs following player via AI packages)
-- Excludes them from anti-theft script reactions

local companionDetection = {}

-- Cache for companion status to avoid repeated checks
local companionCache = {}

-- Check if an NPC is a vanilla companion
-- @param npc - The NPC actor to check
-- @param player - The player actor
-- @param state - The script state (contains our guard info)
-- @return true if NPC is a companion, false otherwise
function companionDetection.isCompanion(npc, player, state)
    if not npc or not npc:isValid() then
        return false
    end
    
    local npcId = npc.id
    
    -- Check cache first
    if companionCache[npcId] ~= nil then
        return companionCache[npcId]
    end
    
    -- If this is our script's guard, it's NOT a companion
    if state and state.guard and state.guard:isValid() and state.guard.id == npcId then
        companionCache[npcId] = false
        return false
    end
    
    -- Check if NPC has AI Follow package targeting the player
    -- In OpenMW Lua, we can check AI packages via types.Actor
    local types = require('openmw.types')
    
    -- Get AI packages for the NPC
    local hasFollowPackage = false
    
    -- Check if NPC is following the player via AI package
    -- We check the active AI state to see if they're following
    if types.Actor and types.Actor.getAiSequence then
        local sequence = types.Actor.getAiSequence(npc)
        if sequence then
            for _, package in ipairs(sequence) do
                if package.type == 'Follow' and package.target == player then
                    hasFollowPackage = true
                    break
                end
            end
        end
    elseif types.Actor and types.Actor.activeAI then
        -- Fallback to activeAI if getAiSequence is not available (older OpenMW versions)
        local aiState = types.Actor.activeAI(npc)
        if aiState then
            -- Check if the AI state indicates following behavior
            -- The exact implementation depends on OpenMW's AI system
            -- For now, we'll use a heuristic: if NPC is very close to player and not in combat
            local distance = (npc.position - player.position):length()
            
            -- Companions typically stay within ~300 units of player
            if distance < 300 then
                -- Additional check: companions usually have high disposition
                local disposition = types.NPC.getBaseDisposition(npc, player) or 0
                
                -- If NPC is close and has high disposition, likely a companion
                -- Threshold: 70+ disposition and within 300 units
                if disposition >= 70 then
                    hasFollowPackage = true
                end
            end
        end
    end
    
    -- Cache the result
    companionCache[npcId] = hasFollowPackage
    
    return hasFollowPackage
end

return companionDetection
