local function onRefNodeCreated(e)
    if not tes3.player then return end

    local playerIsSkeleton = tes3.player.object.race.id == "skeletonrace"
    local targetIsUndead = e.reference.object.type == tes3.creatureType.undead
    

    if playerIsSkeleton and targetIsUndead then
        timer.delayOneFrame(function()
            if e.reference and e.reference.mobile then
                e.reference.mobile.fight = 0
            end
        end)
    end
end

event.register("referenceSceneNodeCreated", onRefNodeCreated)