---@param ref tes3reference
local function isDiseased(ref)
    return tes3.hasSpell({ reference = ref, spell = "md24_greatnewdisease" })
end


---@param ref tes3reference
local function isDancing(ref)
    if ref.tempData.md24_dancing then
        local group = tes3.getAnimationGroups({ reference = ref })
        return group == tes3.animationGroup.idle9
    end
    return false
end


---@param ref tes3reference
local function startDancing(ref)
    if ref == nil then return end

    if ref.object.race.isBeast
        or ref.mobile.inCombat
    then
        return
    end

    -- Play the dancing animation
    tes3.playAnimation({
        reference = ref,
        mesh = "md24\\r\\belly_dance.nif",
        group = tes3.animationGroup.idle9,
    })

    -- Set dancing flag
    ref.tempData.md24_dancing = true
end


---@param ref tes3reference
local function stopDancing(ref)
    if ref == nil then return end

    local mesh = "base_anim.nif"
    if ref.object.race.isBeast then
        mesh = "base_animkna.nif"
    elseif ref.object.female then
        mesh = "base_anim_female.nif"
    end

    -- Interrupt the animation
    tes3.playAnimation({
        reference = ref,
        mesh = mesh,
        group = tes3.animationGroup.idle,
    })

    -- Clear the dancing flag
    ref.tempData.md24_dancing = nil
end


---@param position tes3vector3
local function findActor(position)
    local actors = tes3.findActorsInProximity({ position = position, range = 128 })
    for _, actor in pairs(actors) do
        if actor.position:distance(position) <= 8 then
            return actor.reference
        end
    end
end


local function blowKiss(ref)
    if ref == nil then return end

    local angle = ref.mobile:getViewToActor(tes3.mobilePlayer)
    ref.facing = ref.facing + math.rad(angle)

    tes3.playAnimation({
        reference = ref,
        mesh = "md24\\k\\blow_kiss.nif",
        group = tes3.animationGroup.idle9,
        loopCount = 0,
    })
end


local function teleportExit()
    local ref = tes3.getReference("md24_Furn_ParadoxScale")
    if ref then
        tes3.positionCell({
            reference = tes3.player,
            cell = ref.cell,
            position = ref.position,
            orientation = ref.orientation,
        })
    end
end


--- Start/stop dancing animations when signaled.
---
---@param e referenceActivatedEventData
local function onReferenceActivated(e)
    if e.reference.id == "md24_start_dancing" then
        startDancing(findActor(e.reference.position))
    end
    if e.reference.id == "md24_stop_dancing" then
        stopDancing(findActor(e.reference.position))
    end
    if e.reference.id == "md24_anim_blow" then
        blowKiss(findActor(e.reference.position))
    end
    if e.reference.id == "md24_teleport_return" then
        timer.start({ duration = 0.5, callback = teleportExit })
    end
end
event.register("referenceActivated", onReferenceActivated)


--- Cancel dancing animations when combat is started.
---
---@param e combatStartedEventData
local function onCombatStarted(e)
    local ref = e.actor.reference
    if ref.tempData.md24_dancing then
        stopDancing(ref)
    end
end
event.register("combatStarted", onCombatStarted)


--- Make diseased NPCs dance when loading a new cell.
---
local function onCellChanged(e)
    local index = tes3.getJournalIndex({ id = "md24_j_disease" })
    if (index < 15) or (index >= 100) then
        return
    end

    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.npc) do
            if not (ref.disabled or ref.deleted)
                and (ref.mobile and ref.sceneNode)
            then
                if isDiseased(ref) and not isDancing(ref) then
                    startDancing(ref)
                end
            end
        end
    end
end
event.register("cellChanged", onCellChanged)
event.register("loaded", onCellChanged)


--- Set a global variable for dialogue filtering when talking to a diseased npc.
---
---@param e activateEventData
local function onActivate(e)
    if e.activator ~= tes3.player
        or e.target.object.objectType ~= tes3.objectType.npc
    then
        return
    end

    local index = tes3.getJournalIndex({ id = "md24_j_disease" })
    if (index < 15) then
        return
    end

    if e.target.mobile.inCombat then
        return
    end

    if e.activator.mobile.bounty > 100 then
        return
    end

    local md24_globSpeakerState = tes3.findGlobal("md24_globSpeakerState")
    md24_globSpeakerState.value = isDiseased(e.target) and 1 or 2
end
event.register("activate", onActivate)
