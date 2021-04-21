local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local journalId = common.data.journalIds.aFriendReturned
local journalIndex = nil
local onJournal = nil

local mageId = common.data.npcIds.mage
local mage = nil

local armigerId = common.data.npcIds.genericArmiger
local armiger1 = nil
local armiger2 = nil

local weakCultistId = common.data.npcIds.weakCultist
local cultistId = common.data.npcIds.cultist
local cultist = nil

local cultActivatorId = common.data.objectIds.cultActivator

local enchantedBarrierId = common.data.objectIds.enchantedBarrier

local function updateJournalIndexValue(index)
    journalIndex = index or tes3.getJournalIndex({id = journalId}) 
end

local function spawnCultist(id)
    local reference = tes3.getReference(id)
    return tes3.createReference({
        object = weakCultistId,
        position = reference.position,
        orientation = reference.orientation,
        cell = tes3.player.cell
    })
end

local function triggerTunnelFight()
    common.debug("A Friend Returned: Triggering Tunnel Fight.")

    tes3.worldController.flagTeleportingDisabled = true

    local cultists = {}
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.firstSkirmish.cultist1))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.firstSkirmish.cultist2))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.firstSkirmish.cultist3))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.firstSkirmish.cultist4))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.firstSkirmish.cultist5))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.firstSkirmish.cultist6))

    for _, cultistRef in pairs(cultists) do
        mwscript.startCombat({
            reference = armiger1,
            target = cultistRef
        })
        mwscript.startCombat({
            reference = armiger2,
            target = cultistRef
        })
    end

    common.debug("A Friend Returned: Triggering Timer.")

    local combatTimer = nil
    combatTimer = timer.start({
        duration = 5,
        iterations = -1,
        callback = function()
            common.debug("A Friend Returned: Checking for deadcount.")
        
            local deadCount = 0
            for _, cultistRef in pairs(cultists) do
                if (cultistRef.mobile.isDead == true) then
                    deadCount = deadCount + 1
                end
            end
            if (deadCount > 4) then
                common.debug("A Friend Returned: Met deadcount.")
            
                combatTimer:cancel()

                local cultistLeaderReference = tes3.getReference(common.data.markerIds.underworks.firstSkirmish.cultistLeader)
                cultist = tes3.createReference({
                    object = cultistId,
                    position = cultistLeaderReference.position,
                    orientation = cultistLeaderReference.orientation,
                    cell = tes3.player.cell
                })

                mwscript.startCombat({
                    reference = armiger1,
                    target = cultist
                })
                mwscript.startCombat({
                    reference = armiger2,
                    target = cultist
                })

                timer.start({
                    duration = 3,
                    iterations = 1,
                    callback = function()
                        tes3.messageBox(common.data.messageBoxes.mageSkirmishDialogue)
                    end
                })

                combatTimer = timer.start({
                    duration = 30,
                    iterations = 1,
                    callback = function()
                        common.debug("A Friend Returned: Teleporting out.")

                        tes3.fadeOut({
                            duration = 2
                        })

                        timer.start({
                            duration = 3,
                            iterations = 1,
                            callback = function ()
                                mage:disable()
                                armiger1:disable()
                                armiger2:disable()
                                cultist:disable()
        
                                timer.delayOneFrame({
                                    callback = function()
                                        mage.deleted = true
                                        armiger1.deleted = true
                                        armiger2.deleted = true
                                        cultist.deleted = true
                                    end
                                })

                                tes3.fadeIn({
                                    duration = 2
                                })
                    
                                tes3.worldController.flagTeleportingDisabled = false

                                local orientationRad = tes3vector3.new(
                                    math.rad(0),
                                    math.rad(0),
                                    math.rad(245)
                                )
        
                                tes3.positionCell({
                                    cell =common.data.cellIds.armigersStronghold,
                                    position = {4743, 4645, 15875},
                                    orientation = orientationRad,
                                    reference = tes3.player
                                })
        
                                tes3.updateJournal({
                                    id = journalId,
                                    index = 80
                                })
                            end
                        })
                    end
                })
            end
        end
    })
end

local function onFightSimulate(e)
    local cultActivator = tes3.getReference(cultActivatorId)
    if (tes3.player.position:distance(cultActivator.position) < 2500) then
        event.unregister("simulate", onFightSimulate)

        triggerTunnelFight()
    end
end

local function onUnderworksStageTwoSimulate(e)
    if (journalIndex ~= 50) then
        return
    end

    if (tes3.player.position:distance(mage.position) < 500) then
        common.debug("A Friend Returned: Casting spell on barrier.")
        event.unregister("simulate", onUnderworksStageTwoSimulate)

        local enchantedBarrier = tes3.getReference(enchantedBarrierId)
        local spell = tes3.getObject(common.data.spellIds.dispelEnchantedBarrier)

        tes3.cast({
            reference = mage,
            target = mage,
            spell = spell
        })

        common.debug("A Friend Returned: Casted spell on barrier.")

        timer.start({
            iterations = 1,
            duration = 4,
            callback = function()
                enchantedBarrier:disable()
                common.debug("A Friend Returned: Barrier Disabled.")
        
                timer.delayOneFrame({
                    callback = function()
                        common.debug("A Friend Returned: Barrier Deleted.")
                        enchantedBarrier.deleted = true
                    end
                })
        
                tes3.updateJournal({
                    id = journalId,
                    index = 60
                })
                common.debug("A Friend Returned: Journal Updated.")
        
                event.unregister("simulate", onFightSimulate)
                event.register("simulate", onFightSimulate)
                common.debug("A Friend Returned: Registering Simulate Event in Callback.")
        
            end
        })
    end
end

local function onUnderworksStageOneSimulate(e)
    event.unregister("simulate", onUnderworksStageOneSimulate)
    if (tes3.player.data.fortifiedMolarMar.variables.hasSpawnedActorsByEnchantedBarrier == true) then
        return
    end
    
    local mageMarker = tes3.getReference(common.data.markerIds.underworks.barrier.mage)
    mage = tes3.createReference({
        object = mageId,
        position = mageMarker.position,
        orientation = mageMarker.orientation,
        cell = tes3.player.cell
    })

    local armiger1Marker = tes3.getReference(common.data.markerIds.underworks.barrier.armiger1)
    armiger1 = tes3.createReference({
        object = common.data.npcIds.barrierArmiger1,
        position = armiger1Marker.position,
        orientation = armiger1Marker.orientation,
        cell = tes3.player.cell
    })
    
    local armiger2Marker = tes3.getReference(common.data.markerIds.underworks.barrier.armiger2) 
    armiger2 = tes3.createReference({
        object = common.data.npcIds.barrierArmiger2,
        position = armiger2Marker.position,
        orientation = armiger2Marker.orientation,
        cell = tes3.player.cell
    })

    tes3.player.data.fortifiedMolarMar.variables.hasSpawnedActorsByEnchantedBarrier = true

    event.unregister("simulate", onUnderworksStageTwoSimulate)
    event.register("simulate", onUnderworksStageTwoSimulate)
end

local function onCellChangedStageThree(e)
    if (e.cell.id == common.data.cellIds.underworks) then
        event.register("simulate", onFightSimulate)
        common.debug("A Friend Returned: Registering Simulate Event.")
    elseif (e.previousCell and e.previousCell.id == common.data.cellIds.underworks) then
        event.unregister("simulate", onFightSimulate)
        common.debug("A Friend Returned: Unregistering Simulate Event.")
    end
end
local function onCellChangedStageTwo(e)
    if (e.cell.id == common.data.cellIds.underworks) then
        event.register("simulate", onUnderworksStageTwoSimulate)
        common.debug("A Friend Returned: Registering Simulate Event.")
    elseif (e.previousCell and e.previousCell.id == common.data.cellIds.underworks) then
        event.unregister("simulate", onUnderworksStageTwoSimulate)
        common.debug("A Friend Returned: Unregistering Simulate Event.")
    end
end
local function onCellChangedStageOne(e)
    if (e.cell.id == common.data.cellIds.underworks) then
        event.register("simulate", onUnderworksStageOneSimulate)
        common.debug("A Friend Returned: Registering Simulate Event.")
    elseif (e.previousCell and e.previousCell.id == common.data.cellIds.underworks) then
        event.unregister("simulate", onUnderworksStageOneSimulate)
        common.debug("A Friend Returned: Unregistering Simulate Event.")
    end
end

local function processJournalIndexValue()
    if (journalIndex == 20) then
        -- Player has been asked to speak with the Mage.
    elseif (journalIndex == 40) then
        -- Player has been told to meet the Mage at the enchanted barrier.
        event.register("cellChanged", onCellChangedStageOne)
    elseif (journalIndex == 50) then
        -- Player has talked to the Mage by the enchanted barrier.
        event.unregister("cellChanged", onCellChangedStageOne)
        event.register("cellChanged", onCellChangedStageTwo)
    elseif (journalIndex == 60) then
        event.unregister("cellChanged", onCellChangedStageTwo)
        event.register("cellChanged", onCellChangedStageThree)
        -- Player has been told to continue through the tunnel.
    elseif (journalIndex == 80) then
        -- Player has been teleported out by the group Amvisi Intervention spell.
        event.unregister("cellChanged", onCellChangedStageThree)
    elseif (journalIndex == 100) then
        -- Player has completed the quest.
        event.unregister("journal", onJournal)
    elseif (journalIndex == 110) then
        -- Player has completed the quest.
        event.unregister("journal", onJournal)
    end
end

onJournal = function(e)
    if (e.topic.id ~= journalId) then
        return
    end

    updateJournalIndexValue(e.index)
    processJournalIndexValue()
end

local registered = false
local function onLoaded(e)
    if (registered == false) then
        updateJournalIndexValue()
        if (journalIndex == nil or journalIndex < 100) then
            event.register("journal", onJournal)
            processJournalIndexValue()
        end
        registered = true
    end
end

event.register("loaded", onLoaded)