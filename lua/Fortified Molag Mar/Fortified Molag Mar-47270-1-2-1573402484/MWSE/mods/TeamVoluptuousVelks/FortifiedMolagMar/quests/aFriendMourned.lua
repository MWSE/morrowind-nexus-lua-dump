local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local journalId = common.data.journalIds.aFriendMourned
local journalIndex = nil
local onJournal = nil

local enchantedBarrierId = common.data.objectIds.enchantedBarrier
local armigerId = common.data.npcIds.armiger
local grateAId = common.data.objectIds.grateA
local grateBId = common.data.objectIds.grateB
local ritualActivatorId = common.data.objectIds.ritualSiteActivator
local evidenceActivatorId = common.data.objectIds.evidenceActivator

local function updateJournalIndexValue(index)
    journalIndex = index or tes3.getJournalIndex({id = journalId}) 
end

local function onStageTwoSimulate(e)
    local evidenceActivator = tes3.getReference(evidenceActivatorId)
    if (tes3.player.position:distance(evidenceActivator.position) < 500) then
        event.unregister("simulate", onStageTwoSimulate)

        tes3.updateJournal({
            id = journalId,
            index = 30
        })
    end
end

local function onStageOnePostSimulate(e)
    local ritualActivator = tes3.getReference(ritualActivatorId)
    if (tes3.player.position:distance(ritualActivator.position) < 500) then
        event.unregister("simulate", onStageOnePostSimulate)
        event.register("simulate", onStageTwoSimulate)

        tes3.updateJournal({
            id = journalId,
            index = 25
        })
    end
end

local function onStageOneSimulate(e)
    event.unregister("simulate", onStageOneSimulate)

    local armiger = tes3.getReference(armigerId)   
    if (armiger) then
        armiger:disable()
        timer.delayOneFrame({
            callback = function()
                common.debug("A Friend Mourned: Armiger Deleted.")
                armiger.deleted = true
            end
        })
    end
    local swordBlade = tes3.getReference(common.data.objectIds.brokenSwordBlade)
    if (swordBlade) then
        local count = mwscript.getItemCount({
            reference = tes3.player,
            item = common.data.objectIds.brokenSwordBlade
        })
        if (count == 0) then
            swordBlade:disable()
            timer.delayOneFrame({
                callback = function()
                    common.debug("A Friend Mourned: Sword Blade Deleted.")
                    swordBlade.deleted = true
                end
            })
        end
    end
    local swordHilt = tes3.getReference(common.data.objectIds.brokenSwordHilt)
    if (swordHilt) then
        local count = mwscript.getItemCount({
            reference = tes3.player,
            item = common.data.objectIds.brokenSwordHilt
        })
        if (count == 0) then
            swordHilt:disable()
            timer.delayOneFrame({
                callback = function()
                    common.debug("A Friend Mourned: Sword Hilt Deleted.")
                    swordHilt.deleted = true
                end
            })
        end
    end

    local grateA = tes3.getReference(grateAId)
    if (grateA) then
        tes3.createReference({
            object = grateBId,
            position = grateA.position,
            orientation = grateA.orientation,
            cell = grateA.cell
        })
        common.debug("A Friend Mourned: Grate B Created.")

        grateA:disable()
        timer.delayOneFrame({
            callback = function()
                common.debug("A Friend Mourned: Grate A Deleted.")
                grateA.deleted = true
            end
        })
    end
    
    event.unregister("simulate", onStageOnePostSimulate)
    event.register("simulate", onStageOnePostSimulate)
end

local function onStageTwoCellChanged(e)
    if (e.cell.id == common.data.cellIds.underworks) then
        event.register("simulate", onStageTwoSimulate)
        common.debug("A Friend Mourned: Registering Simulate Event.")
    elseif (e.previousCell and e.previousCell.id == common.data.cellIds.underworks) then
        event.unregister("simulate", onStageTwoSimulate)
        common.debug("A Friend Mourned: Unregistering Simulate Event.")
    end
end

local function onStageOneCellChanged(e)
    if (e.cell.id == common.data.cellIds.underworks) then
        event.register("simulate", onStageOneSimulate)
        common.debug("A Friend Mourned: Registering Simulate Event.")
    elseif (e.previousCell and e.previousCell.id == common.data.cellIds.underworks) then
        event.unregister("simulate", onStageOneSimulate)
        common.debug("A Friend Mourned: Unregistering Simulate Event.")
    end
end

local function onActivate(e)
    local enchantedBarrier = tes3.getReference(enchantedBarrierId)
    if (e.activator == tes3.player and e.target == enchantedBarrier) then
        event.unregister("activate", onActivate)
        common.debug("A Friend Mourned: Unregistering Activate Event.")

        tes3.messageBox(common.data.messageBoxes.enchantedBarrierActivate)

        tes3.updateJournal({
            id = journalId,
            index = 40
        })
    end
end

local function processJournalIndexValue()
    if (journalIndex == 20) then
        -- Player has been asked to retrieve the buoyant armiger's body 
        -- and investigate the area.
        event.unregister("activate", onActivate)
        event.register("activate", onActivate)
        event.register("cellChanged", onStageOneCellChanged)
        common.debug("A Friend Mourned: Registered Activate Event.")
    elseif (journalIndex == 25) then
        -- Player has found the armiger is missing.
        event.unregister("cellChanged", onStageOneCellChanged)
        event.unregister("activate", onActivate)
        event.register("cellChanged", onStageTwoCellChanged)
        event.register("activate", onActivate)
        common.debug("A Friend Mourned: Registered Activate Event.")
    elseif (journalIndex == 30) then
        -- Player has found evidence of a daedric cult.
        event.unregister("cellChanged", onStageTwoCellChanged)
        event.unregister("activate", onActivate)
        event.register("activate", onActivate)
        common.debug("A Friend Mourned: Registered Activate Event.")
    elseif (journalIndex == 40) then
        -- Player has found the enchanted barrier.
        event.unregister("cellChanged", onStageTwoCellChanged)
        event.unregister("activate", onActivate)
        common.debug("A Friend Mourned: Registered Activate Event.")
    elseif (journalIndex == 60) then
        -- Player has reported back to Indaram.
        event.unregister("journal", onJournal)
        common.debug("A Friend Mourned: Unregistered Journal Event.")
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
        if (journalIndex == nil or journalIndex < 60) then
            event.register("journal", onJournal)
            common.debug("A Friend Mourned: Registered Journal Event")
            processJournalIndexValue()
        end
        registered = true
    end
end

event.register("loaded", onLoaded)