local common = require("TeamVoluptuousVelks.DeeperDagothUr.common")

local journalId = "C3_DestroyDagoth"
local ballistaId = "DDU_DwemerBallistaTop"
local cellIds = {
    ["Dagoth Ur"] = true,
    ["Red Mountain Region"] = true
}
local ballistaTimers = {}

local function getLoadedBallistae()
    local cells = tes3.getActiveCells()
    local ballistae = {}
    for _, cell in pairs(cells) do
        for ref in cell:iterateReferences() do
            -- Check that the reference is an activator.
            if (ref.object.objectType == tes3.objectType.activator) then
                -- Check that the object is a ballista
                if (ref.object.id == ballistaId) then
                    table.insert(ballistae, ref)
                end
            end
        end
    end
    return ballistae
end

local function isWithinFireZone(reference, target)
    common.debug("Ballista: Checking ballista firezone.")
    
    if (reference.position.z <= target.position.z) then
        common.debug("Ballista: Checking ballista firezone: Within height")
        local distance = reference.position:distance(target.position)
        if (distance >= 400 and distance <= 5000) then
            common.debug("Ballista: Checking ballista firezone: Within zone")
            return true
        end
    end
    return false
end

local function isBallistaDelayed(ballista, timestamp)
    common.debug("Ballista: Checking ballista timer.")
    
    if (ballistaTimers[ballista] == nil) then
        return false
    elseif (timestamp - ballistaTimers[ballista] <= .10) then
        return true
    end
    return false
end

local function onSimulate(e)
    common.debug("==============================")
    common.debug("Ballista: Simulating ballista!")

    -- Get the loaded Ballistae
    local mobilePlayer = tes3.mobilePlayer

    -- Check if player has levitation active.
    local isLevitationActive = tes3.isAffectedBy({
        reference = mobilePlayer,
        effect = tes3.effect.levitate
    })

    if (isLevitationActive ~= true) then
        common.debug("Ballista: Levitation not active.")
        return
    end

    local ballistae = getLoadedBallistae()

    if (ballistae == nil) then
        common.debug("Ballista: Could not find a ballista.")
        return
    end

    for _, ballista in pairs(ballistae) do 
        common.debug("Ballista: Iterating ballista.")
        if (isBallistaDelayed(ballista, e.timestamp) == false) then
            -- Check if ballista is within distance parameters
            if(isWithinFireZone(ballista, tes3.player)) then
                common.debug("Ballista: Firing ballista.")
                
                local spell = tes3.getObject(common.data.spellIds.dispelLevitationJavelin)

                if (spell == nil) then
                    common.debug("Ballista: Spell not found.") 
                else   
                    tes3.cast({
                        reference = ballista,
                        target = mobilePlayer,
                        spell = spell
                    })

                    ballistaTimers[ballista] = e.timestamp
                end

            end
        end
    end
end

local function detachNodeFromPlayer()    
    -- detach the LookAtTarget from the player
    local node = tes3.player.sceneNode:getObjectByName("LookAtTarget")
    if (node ~= nil) then
        node.parent:detachChild(node)
    end
end

local function onReferenceSceneNodeCreated(e)
    if e.reference.id == ballistaId then
        local node = e.reference.sceneNode:getObjectByName("LookAtTarget")

        -- detach the LookAtTarget from the reference
        node.parent:detachChild(node)
    
        -- then attach the LookAtTarget to the player
        tes3.player.sceneNode:attachChild(node)
    end
end

event.register("referenceSceneNodeCreated", onReferenceSceneNodeCreated)

local function onCellChanged(e)
    if (e.previousCell ~= nil) then
        if (cellIds[e.previousCell.id] == true) then
            event.unregister("simulate", onSimulate)
            detachNodeFromPlayer()
        end
    end
    
    if (cellIds[e.cell.id] == true) then
        event.register("simulate", onSimulate)
    end
end

local function onJournal(e)
    if (e.topic.id ~= journalId) then
        return
    end

    event.unregister("cellChanged", onCellChanged)
    event.unregister("journal", onJournal)
    detachNodeFromPlayer()
end

local function onLoaded(e)
    local journalIndex = tes3.getJournalIndex(journalId) 
    if (journalIndex == nil or journalIndex < 5) then
        event.register("cellChanged", onCellChanged)
        event.register("journal", onJournal)
    end
end

event.register("loaded", onLoaded)