local common = require("OperatorJack.SimpleCombatMechanics.common")
local config = require("OperatorJack.SimpleCombatMechanics.config")

local function handleAssistGuards(mobile, reference)
    for _, cellReference in pairs(common.getReferencesNearPoint(reference.position, config.interactiveBystandersAssistGuardsSearchDistance)) do
        if (cellReference.object.objectType == tes3.objectType.npc) then
            local npcReference = cellReference
            local isEnemy = false
            for hostileMobile in tes3.iterate(mobile.hostileActors) do
                if (npcReference.mobile == hostileMobile) then
                    isEnemy = true
                end
            end

            if (isEnemy == false) then         
                for hostileMobile in tes3.iterate(mobile.hostileActors) do
                    if (hostileMobile) then
                        local levelDiff = npcReference.object.level - hostileMobile.reference.object.level
                        if (levelDiff > config.interactiveBystandersAssistGuardsLowerLimit) then
                            npcReference.mobile:startCombat(hostileMobile)
                        end
                    end
                end
            end
        end
    end
end

local function handleWeaklingsFlee(mobile, reference)
    for _, cellReference in pairs(common.getReferencesNearPoint(reference.position, config.interactiveBystandersFleeSearchDistance)) do
        if (cellReference.object.objectType == tes3.objectType.npc) then

            local npcReference = cellReference
            local levelDiff = reference.object.level - npcReference.object.level

            if (levelDiff > config.interactiveBystandersFleeLowerLimit and
                npcReference.object.isGuard == false) then
                    npcReference.mobile.flee = 1000000000
                    npcReference.mobile.actionData.aiBehaviorState = 6 -- Flee
                    npcReference.mobile:startCombat(mobile)
                
                common.debug(string.format("%s is supposed to be fleeing!", npcReference))
            end
        end
    end
end

local function onAttack(e)
    if (config.enableInteractiveBystanders == false) then
        return
    end

    local reference = e.reference
    local mobile = reference.mobile

    if (mobile.actorType == tes3.actorType.creature) then
        return
    end

    if (config.enableInteractiveBystandersAssistGuards == true and
        reference.object.isGuard == true) then
        -- Combatant is a guard. Check if nearby actors should help.
        handleAssistGuards(mobile, reference)
        return
    end
    
    if (config.enableInteractiveBystandersWeaklingsFlee == true and
        reference.object.isGuard == false) then
        -- Combatant is not a guard and is in a city. Check if nearby actors should flee.
        handleWeaklingsFlee(mobile, reference)
        return
    end
end
event.register("attack", onAttack)