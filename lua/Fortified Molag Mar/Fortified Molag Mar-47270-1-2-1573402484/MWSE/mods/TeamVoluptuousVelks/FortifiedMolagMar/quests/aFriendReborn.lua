local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local journalId = common.data.journalIds.aFriendReborn
local journalIndex = nil
local onJournal = nil

local armigerId = common.data.npcIds.genericArmiger
local weakCultistId = common.data.npcIds.weakCultist

local indaramId = common.data.npcIds.indaram
local indaram = nil

local cultistId = common.data.npcIds.cultist
local cultist = nil

local dremoraLordTimer = nil

local function updateJournalIndexValue(index)
    journalIndex = index or tes3.getJournalIndex({id = journalId}) 
end

local function spawnArmiger(id)
    local reference = tes3.getReference(id)
    return tes3.createReference({
        object = armigerId,
        position = reference.position,
        orientation = reference.orientation,
        cell = tes3.player.cell
    })
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

local function onBattleStageThreeSimulate(e)
    event.unregister("simulate", onBattleStageThreeSimulate)

    timer.start({
        iterations = 1,
        duration = 20,
        callback = function()

            local vivecReference = tes3.getReference(common.data.markerIds.battlements.vivec)
            local vivec = tes3.createReference({
                object = common.data.npcIds.vivec,
                position = vivecReference.position,
                orientation = vivecReference.orientation,
                cell = tes3.player.cell
            })

            timer.start({
                iterations = 1,
                duration = 3,
                callback = function()
                    local dremoraLord = tes3.getReference(common.data.npcIds.dremoraLord)
                    tes3.cast({
                        reference = vivec,
                        target = dremoraLord,
                        spell = common.data.spellIds.annihilate
                    })

                    timer.start({
                        iterations = 1,
                        duration = 3,
                        callback = function()
                            dremoraLordTimer:cancel()

                            dremoraLord:disable()
                            timer.delayOneFrame({
                                callback = function()
                                    dremoraLord.deleted = true
                                end
                            })
                            
                            tes3.createReference({
                                object = common.data.objectIds.dremoraLordAshes,
                                position = dremoraLord.position,
                                orientation = dremoraLord.orientation,
                                cell = tes3.player.cell
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

local function onBattleStageTwoSimulate(e)
    event.unregister("simulate", onBattleStageTwoSimulate)

    timer.start({
        iterations = 1,
        duration = 15,
        callback = function()
            local forcefield = tes3.getReference(common.data.objectIds.battlementForcefield)
            
            local spell = tes3.getObject(common.data.spellIds.gateExplosion)
            tes3.cast({
                reference = forcefield,
                target = forcefield,
                spell = spell
            })

            timer.start({
                iterations = 1,
                duration = 2,
                callback = function()
                    local dremoraLordReference = tes3.getReference(common.data.markerIds.battlements.dremoraLord2)
                    local dremoraLord = tes3.getReference(common.data.npcIds.dremoraLord)
                    tes3.positionCell({
                        reference = dremoraLord,
                        position = dremoraLordReference.position,
                        orientation = dremoraLordReference.orientation,
                        cell = dremoraLordReference.cell
                    })
        
                    forcefield:disable()
        
                    timer.delayOneFrame({
                        callback = function()
                            forcefield.deleted = true
                        end
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

local function onBattleStageOneSimulate(e)
    event.unregister("simulate", onBattleStageOneSimulate)

    indaram = tes3.getReference(indaramId)

    local armigers = {}
    local cultists = {}

    local indaramMarker = tes3.getReference(common.data.markerIds.battlements.indaram)

    table.insert(armigers, spawnArmiger(common.data.markerIds.battlements.armiger1))
    table.insert(armigers, spawnArmiger(common.data.markerIds.battlements.armiger2))
    table.insert(armigers, spawnArmiger(common.data.markerIds.battlements.armiger3))
    table.insert(armigers, spawnArmiger(common.data.markerIds.battlements.armiger4))

    table.insert(cultists, spawnCultist(common.data.markerIds.battlements.cultist1))
    table.insert(cultists, spawnCultist(common.data.markerIds.battlements.cultist2))
    table.insert(cultists, spawnCultist(common.data.markerIds.battlements.cultist3))
    table.insert(cultists, spawnCultist(common.data.markerIds.battlements.cultist4))
    table.insert(cultists, spawnCultist(common.data.markerIds.battlements.cultist5))
    table.insert(cultists, spawnCultist(common.data.markerIds.battlements.cultist6))


    local forcefieldReference = tes3.getReference(common.data.markerIds.battlements.forcefield)
    tes3.createReference({
        object = common.data.objectIds.battlementForcefield,
        position = forcefieldReference.position,
        orientation = forcefieldReference.orientation,
        cell = tes3.player.cell,
        scale = 2
    })       

    local cultistLeaderReference = tes3.getReference(common.data.markerIds.battlements.cultistLeader)
    cultist = tes3.createReference({
        object = cultistId,
        position = cultistLeaderReference.position,
        orientation = cultistLeaderReference.orientation,
        cell = tes3.player.cell
    })

    local deadArmigerReference = tes3.getReference(common.data.markerIds.battlements.deadArmiger)
    local deadArmiger = tes3.createReference({
        object = common.data.npcIds.armiger,
        position = deadArmigerReference.position,
        orientation = deadArmigerReference.orientation,
        cell = tes3.player.cell
    })

    common.debug("A Friend Reborn: Stage One: Creating References.")

    for _, armiger in pairs(armigers) do
        for _, cultistRef in pairs(cultists) do
            mwscript.startCombat({
                reference = armiger,
                target = cultistRef
            })
            mwscript.startCombat({
                reference = cultistRef,
                target = armiger
            })
        end
    end

    common.debug("A Friend Reborn: Stage One: Starting Combat.")

    timer.start({
        iterations = 1,
        duration = 10,
        callback = function()
            common.debug("A Friend Reborn: Stage One: Casting Summon.")

            tes3.cast({
                reference = cultist,
                target = deadArmiger,
                spell = "fireball"
            })

            timer.start({
                iterations = 1,
                duration = 3,
                callback = function()
                    common.debug("A Friend Reborn: Stage One: Creating Dremora Lord.")

                    local spell = tes3.getObject(common.data.spellIds.gateExplosion)
                    tes3.cast({
                        reference = deadArmiger,
                        target = deadArmiger,
                        spell = spell
                    })

                    timer.start({
                        duration = 2,
                        iterations = 1,
                        callback = function()
                            deadArmiger:disable()
                            cultist:disable()
        
                            timer.delayOneFrame({
                                callback = function()
                                    deadArmiger.deleted = true
                                    cultist.deleted = true
                                end
                            })
        
                            local dremoraLordReference = tes3.getReference(common.data.markerIds.battlements.dremoraLord)
                            local dremoraLord = tes3.createReference({
                                object = common.data.npcIds.dremoraLord,
                                position = dremoraLordReference.position,
                                orientation = dremoraLordReference.orientation,
                                cell = tes3.player.cell
                            })
        
                            for _, armiger in pairs(armigers) do
                                mwscript.startCombat({
                                    reference = armiger,
                                    target = dremoraLord
                                })
                                mwscript.startCombat({
                                    reference = dremoraLord,
                                    target = armiger
                                })
                            end
        
                            dremoraLordTimer = timer.start({
                                iterations = -1,
                                duration = 3,
                                callback = function ()
                                    tes3.cast({
                                        reference = dremoraLord,
                                        target = tes3.player,
                                        spell = common.data.spellIds.firesOfOblivion
                                    })
                                end
                            })
        
                            local actors = common.getActorsNearTargetPosition(tes3.player.cell, dremoraLord.position, 200)
        
                            common.debug("A Friend Reborn: Stage One: Killing nearby actors.")
        
                            for _, actor in pairs(actors) do
                                if (actor ~= dremoraLord) then
                                    actor.mobile:applyHealthDamage(9999999)
                                end
                            end
             
                            tes3.updateJournal({
                                id = journalId,
                                index = 60
                            })
                        end
                    })
                end
            })
        end
    })
end

local function onCellChanged(e)
    if (e.cell.id == common.data.cellIds.battlements) then
        local indaramMarker = tes3.getReference(common.data.markerIds.battlements.indaram)
        tes3.positionCell({
            reference = indaramId,
            position = indaramMarker.position,
            orientation = indaramMarker.orientation,
            cell = tes3.player.cell
        })
        
        event.unregister("cellChanged", onCellChanged)
        common.debug("A Friend Reborn: Unregistering CellChanged Event.")
    end
end

local function processJournalIndexValue()
    if (journalIndex == 20) then
        -- Player has been told to meet Indaram on the battlements.
        event.register("cellChanged", onCellChanged)
        common.debug("A Friend Reborn: Registering CellChanged Event.")
    elseif (journalIndex == 40) then
        -- Player conversation with Indaram interrupted by battle.
        event.register("simulate", onBattleStageOneSimulate)
        common.debug("A Friend Reborn: Registering Stage One Simulate Event.")
    elseif (journalIndex == 60) then
        -- The Dreamora lord was summoned.
        event.register("simulate", onBattleStageTwoSimulate)
        common.debug("A Friend Reborn: Registering Stage Two Simulate Event.")
    elseif (journalIndex == 80) then
        -- Molar Mar was breached.
        event.register("simulate", onBattleStageThreeSimulate)
        common.debug("A Friend Reborn: Registering Stage Three Simulate Event.")
    elseif (journalIndex == 100) then
        -- Player has been saved by Vivec.
    elseif (journalIndex == 120) then
        -- Player has received reward from Vivec.
    end
end

onJournal = function(e)
    if (e.topic.id ~= journalId) then
        return
    end

    common.debug("A Friend Reborn: Updating Journal Index to: " .. e.index)

    updateJournalIndexValue(e.index)
    processJournalIndexValue()
end

local registered = false
local function onLoaded(e)
    if (registered == false) then
        updateJournalIndexValue()
        if (journalIndex == nil or journalIndex < 80) then
            common.debug("A Friend Reborn: Registering Journal Event.")

            event.register("journal", onJournal)
            processJournalIndexValue()
        end
        registered = true
    end
end

event.register("loaded", onLoaded)