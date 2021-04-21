local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local journalId = common.data.journalIds.aFriendAvenged
local journalIndex = nil
local onJournal = nil

local mageId = common.data.npcIds.mage
local mage = nil

local armigerId = common.data.npcIds.genericArmiger
local armiger1 = nil
local armiger2 = nil
local armiger3 = nil
local armiger4 = nil

local weakCultistId = common.data.npcIds.weakCultist
local cultistId = common.data.npcIds.cultist
local cultist = nil

local cultActivatorId = common.data.objectIds.cultActivator

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
    common.debug("A Friend Avenged: Triggering Tunnel Fight.")

    tes3.worldController.flagTeleportingDisabled = true

    local cultists = {}
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist1))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist2))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist3))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist4))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist5))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist6))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist7))
    table.insert(cultists, spawnCultist(common.data.markerIds.underworks.secondSkirmish.cultist8))

    for _, cultistRef in pairs(cultists) do
        mwscript.startCombat({
            reference = mage,
            target = cultistRef
        })
        mwscript.startCombat({
            reference = armiger1,
            target = cultistRef
        })
        mwscript.startCombat({
            reference = armiger2,
            target = cultistRef
        })
        mwscript.startCombat({
            reference = armiger3,
            target = cultistRef
        })
        mwscript.startCombat({
            reference = armiger4,
            target = cultistRef
        })
    end

    common.debug("A Friend Avenged: Triggering Timer.")
    
    timer.start({
        duration = 5,
        iterations = 1,
        callback = function()
            common.debug("A Friend Avenged: Killing Armiger 3 & 4.")
            
            armiger3.mobile:applyHealthDamage(9999)
            armiger4.mobile:applyHealthDamage(9999)
    
            timer.start({
                duration = 5,
                iterations = 1,
                callback = function()
                    common.debug("A Friend Avenged: Spawning Powerful Cultist.")

                    local cultistsLeaderReference = tes3.getReference(common.data.markerIds.underworks.secondSkirmish.cultistLeader)
                    cultist = tes3.createReference({
                        object = cultistId,
                        position = cultistsLeaderReference.position,
                        orientation = cultistsLeaderReference.orientation,
                        cell = tes3.player.cell
                    })
    
                    timer.start({
                        duration = 5,
                        iterations = 1,
                        callback = function()
                            common.debug("A Friend Avenged: Killing Armiger 1 & 2.")
                            
                            armiger1.mobile:applyHealthDamage(9999)
                            armiger2.mobile:applyHealthDamage(9999)
    
                            timer.start({
                                duration = 7,
                                iterations = 1,
                                callback = function()
                                    common.debug("A Friend Avenged: Killing Mage & equipping artifact.")
                                    
                                    tes3.messageBox(common.data.messageBoxes.mageDeathDialogue)
                        
                                    mwscript.addItem({
                                        reference = tes3.player,
                                        item = common.data.objectIds.artifactChargedRing
                                    })
                                    mwscript.equip({
                                        reference = tes3.player,
                                        item = common.data.objectIds.artifactChargedRing
                                    })
                        
                                    mage.mobile:applyHealthDamage(9999999)
    
                                    timer.start({
                                        duration = 10,
                                        iterations = 1,
                                        callback = function()
                                            common.debug("A Friend Avenged: Removing cultists... Retreating.")
                                            
                                            tes3.fadeOut({
                                                duration = 2
                                            })

                                            timer.start({
                                                duration = 2,
                                                iterations = 1,
                                                callback = function()
                                                    cultist:disable()
                                                    for _,cultistRef in pairs(cultists) do
                                                        cultistRef:disable()
                                                    end
                                        
                                                    timer.delayOneFrame({
                                                        callback = function()
                                                            cultist.deleted = true
                                                            for _,cultistRef in pairs(cultists) do
                                                                cultistRef.deleted = true
                                                            end
                                                        end
                                                    })
                                        
                                                    tes3.messageBox(common.data.messageBoxes.cultistRetreatDialogue)
                                        
                                                    timer.start({
                                                        duration = 3,
                                                        iterations = 1,
                                                        callback = function ()
                                                            common.debug("A Friend Avenged: Processing retreat.")
        
                                                            tes3.worldController.flagTeleportingDisabled = false
                                                            
                                                            tes3.fadeIn({
                                                                duration = 2
                                                            })
        
                                                            tes3.updateJournal({
                                                                id = journalId,
                                                                index = 100
                                                            })
                                                        end
                                                    })
                                                end
                                            })
                                        end
                                    })
                                end
                            })
                        end
                    })
                end
            })
        end
    })
end

local function onSimulate(e)
    if (tes3.player.data.fortifiedMolarMar.variables.hasSpawnedActorsForSecondTunnelFight ~= true) then
        local mageReference = tes3.getReference(common.data.markerIds.underworks.secondSkirmish.mage)
        mage = tes3.createReference({
            object = mageId,
            position = mageReference.position,
            orientation = mageReference.orientation,
            cell = tes3.player.cell
        })

        local armiger1Reference = tes3.getReference(common.data.markerIds.underworks.secondSkirmish.mage)
        armiger1 = tes3.createReference({
            object = armigerId,
            position = armiger1Reference.position,
            orientation = armiger1Reference.orientation,
            cell = tes3.player.cell
        })
        local armiger2Reference = tes3.getReference(common.data.markerIds.underworks.secondSkirmish.mage)
        armiger2 = tes3.createReference({
            object = armigerId,
            position = armiger2Reference.position,
            orientation = armiger2Reference.orientation,
            cell = tes3.player.cell
        })
        local armiger3Reference = tes3.getReference(common.data.markerIds.underworks.secondSkirmish.mage)
        armiger3 = tes3.createReference({
            object = armigerId,
            position = armiger3Reference.position,
            orientation = armiger3Reference.orientation,
            cell = tes3.player.cell
        })
        local armiger4Reference = tes3.getReference(common.data.markerIds.underworks.secondSkirmish.mage)
        armiger4 = tes3.createReference({
            object = armigerId,
            position = armiger4Reference.position,
            orientation = armiger4Reference.orientation,
            cell = tes3.player.cell
        })
        common.debug("A Friend Avenged: Simulate Event DoOnce complete.")

        tes3.player.data.fortifiedMolarMar.variables.hasSpawnedActorsForSecondTunnelFight = true
    end

    local cultActivator = tes3.getReference(cultActivatorId)
    if (tes3.player.position:distance(cultActivator.position) < 2500) then
        event.unregister("simulate", onSimulate)
        common.debug("A Friend Avenged: Unregistering Tunnel Simulate Event.")

        triggerTunnelFight()
    end
end


local function onCellChanged(e)
    if (e.cell.id == common.data.cellIds.underworks) then
        event.register("simulate", onSimulate)
        common.debug("A Friend Avenged: Registering Simulate Event.")
    elseif (e.previousCell and e.previousCell.id == common.data.cellIds.underworks) then
        event.unregister("simulate", onSimulate)
        common.debug("A Friend Avenged: Unregistering Tunnel Simulate Event.")
    end
end

local function onArmigersSimulate(e) 
    event.unregister("simulate", onArmigersSimulate)
    local mage = tes3.getReference(common.data.npcIds.mage)   
    if (mage) then
        mage:disable()
        timer.delayOneFrame({
            callback = function()
                common.debug("A Friend Mourned: Armiger Deleted.")
                mage.deleted = true
            end
        })
    end
end

local function onCellChangedToArmigersStronghold(e)
    if (e.cell.id == common.data.cellIds.armigersStronghold) then
        event.register("simulate", onArmigersSimulate)
        common.debug("A Friend Avenged: Registering Simulate Event.")
    elseif (e.previousCell and e.previousCell.id == common.data.cellIds.armigersStronghold) then
        event.unregister("simulate", onArmigersSimulate)
        common.debug("A Friend Avenged: Unregistering Tunnel Simulate Event.")
    end
end

local function isBadGuy()
    for journalId, index in pairs(common.data.bannedJournals) do
        local currentIndex = tes3.getJournalIndex({id = journalId})
        if (currentIndex >= index) then
            return true
        end
    end
    return false
end

local function onShrineActivate(e)
    local targetId = e.target.object.id

    if (targetId == "ac_shrine_gnisis_mv") then
        targetId = "ac_shrine_gnisis"
    end

    if (common.data.playerData.shrines[targetId] ~= nil) then
        common.debug("A Friend Avenged: Target ID: " .. targetId)
        common.debug("A Friend Avenged: Shrine Activated.")

        if (isBadGuy() == true) then
            tes3.messageBox(common.data.messageBoxes.shrinesBadGuyDialogue)

            mwscript.removeItem({
                reference = tes3.player,
                item = common.data.objectIds.amulet
            })

            tes3.updateJournal({
                id = journalId,
                index = 140
            })

            event.unregister("activate", onShrineActivate)
            return
        end
        
        if (tes3.player.data.fortifiedMolarMar.shrines[targetId] == true) then
            return
        end

        local isAmuletEquipped = mwscript.hasItemEquipped({
            reference = tes3.player,
            item = common.data.objectIds.amulet
        })

        if (isAmuletEquipped == true) then
            common.debug("A Friend Avenged: Amulet is equipped.")
            
            tes3.player.data.fortifiedMolarMar.shrines[targetId] = true

            local done = true
            for shrineId, state in pairs(common.data.playerData.shrines) do
                if (tes3.player.data.fortifiedMolarMar.shrines[shrineId] == nil or tes3.player.data.fortifiedMolarMar.shrines[shrineId] == false) then
                    done = false
                end
            end

            if (done == true) then
                event.unregister("activate", onShrineActivate)
                common.debug("A Friend Avenged: Unregistering Shrine Activate Event.")

                tes3.messageBox(common.data.messageBoxes.shrinesCompletedDialogue)
                tes3.updateJournal({
                    id = journalId,
                    index = 60
                })
            else
                tes3.messageBox(common.data.messageBoxes.shrinesInProgressDialogue)   
            end
        else
            tes3.messageBox(common.data.messageBoxes.shrinesNoAmuletDialogue)
        end
    end
end

local function processJournalIndexValue()
    if (journalIndex == 20) then
        -- Player has been told to speak to the Mage about the amulet.
    elseif (journalIndex == 40) then
        -- Player has been told to purify the amulet by walking the Pilgrim's Path.
        event.register("activate", onShrineActivate)
        common.debug("A Friend Avenged: Registering Shrine Activate Event.")
    elseif (journalIndex == 60) then
        -- Player has been told to return to the Mage.
    elseif (journalIndex == 80) then
        -- Player has been instructed to meet the Mage at the previous cultist location.
        event.register("cellChanged", onCellChanged)        
    elseif (journalIndex == 100) then
        -- Player has been given the artifact.  
        event.unregister("cellChanged", onCellChanged) 
        event.register("cellChanged", onCellChangedToArmigersStronghold)        
    elseif (journalIndex == 120) then
        -- Player has reported the situation to Indaram.
        event.unregister("cellChanged", onCellChangedToArmigersStronghold) 
        event.unregister("journal", onJournal)
        common.debug("A Friend Avenged: Unregistered Journal Event.")
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
        if (journalIndex == nil or journalIndex < 120) then
            event.register("journal", onJournal)
            common.debug("A Friend Avenged: Registered Journal Event.")
            processJournalIndexValue()
        end
        registered = true
    end
end

event.register("loaded", onLoaded)