local config = require("Syanide.Stay On the Roads.config")

local config = require("Syanide.Stay On the Roads.config")

local function isBlacklisted(creature)
    local id = creature.reference.object.id:lower()
    for _, blacklistedId in ipairs(config.blacklist) do
        if blacklistedId:lower() == id then
            return true
        end
    end
    return false
end


local function shouldAttack(creature)
    return creature.fight >= config.fightThreshold
end

local function onSimulate()
    local mobileList = tes3.findActorsInProximity({ reference = tes3.player, range = config.checkRadius })
    if not mobileList then return end

    for _, mobile in pairs(mobileList) do
        if mobile and mobile.reference and mobile.reference.object and mobile.actorType == tes3.actorType.creature and not isBlacklisted(mobile) then

            if shouldAttack(mobile) then
                local closestTarget = nil
                local closestDistance = math.huge

                for _, target in pairs(mobileList) do
                    if target and target ~= mobile and not target.dead and (
                        target.actorType == tes3.actorType.npc or target == tes3.mobilePlayer
                    ) then
                        local dist = tes3vector3.distance(mobile.position, target.position)
                        if dist < config.checkRadius then
                            local hasLOS = tes3.testLineOfSight({
                                reference1 = mobile.reference,
                                reference2 = target.reference
                            })
                            if hasLOS and dist < closestDistance then
                                closestDistance = dist
                                closestTarget = target
                            end
                        end
                    end
                end

                if closestTarget then
                    mobile:startCombat(closestTarget)
                end
            end
        end
    end
end



mwse.log("[Stay On the Roads] Initialized!")
event.register("simulate", onSimulate)