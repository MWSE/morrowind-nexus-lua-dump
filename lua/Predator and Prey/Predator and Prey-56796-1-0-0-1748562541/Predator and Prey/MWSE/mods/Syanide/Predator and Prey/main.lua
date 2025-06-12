local config = require("Syanide.Predator and Prey.config")

local function isPredator(creature)
    local baseId = creature.reference.baseObject.id:lower()
    return config.predators[baseId] == true
end

local function isPrey(creature)
    local baseId = creature.reference.baseObject.id:lower()
    return config.prey[baseId] == true
end

local function isConflicted(creature)
    local id = creature.reference.baseObject.id:lower()
    return config.predators[id] and config.prey[id]
end


local function onSimulate()
    local mobileList = tes3.findActorsInProximity({ reference = tes3.player, range = config.checkRadius })
    if not mobileList then return end

    for _, predator in pairs(mobileList) do
        if isConflicted(predator) then
            mwse.log("[Predator and Prey] Skipping conflicted creature '%s'", predator.reference.baseObject.id)
        elseif predator
            and predator.actorType == tes3.actorType.creature
            and predator.reference
            and predator.reference.object
            and isPredator(predator)
        then
            local closestPrey = nil
            local closestDistance = math.huge

            for _, potentialPrey in pairs(mobileList) do
                if potentialPrey ~= predator
                    and potentialPrey.actorType == tes3.actorType.creature
                    and isPrey(potentialPrey)
                    and not potentialPrey.dead
                then
                    local dist = tes3vector3.distance(predator.position, potentialPrey.position)
                    if dist < config.checkRadius then
                        local hasLOS = tes3.testLineOfSight({
                            reference1 = predator.reference,
                            reference2 = potentialPrey.reference
                        })
                        if hasLOS and dist < closestDistance then
                            closestDistance = dist
                            closestPrey = potentialPrey
                        end
                    end
                end
            end

            if closestPrey then
                predator:startCombat(closestPrey)
            end
        end
    end
end

event.register("simulate", onSimulate)
mwse.log("[Predator and Prey] Initialized!")
