local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local journalId = common.data.journalIds.aFriendLost
local journalIndex = nil
local onJournal = nil

local armigerId = common.data.npcIds.armiger
local armiger = nil

local function updateJournalIndexValue(index)
    journalIndex = index or tes3.getJournalIndex({id = journalId}) 
end

local function onActivate(e)
    if (e.activator == tes3.player and e.target == armiger) then
        event.unregister("activate", onActivate)
        common.debug("A Friend Lost: Unregistering Activate Event.")

        tes3.updateJournal({
            id = journalId,
            index = 60
        })
    end
end

local onSimulateDoOnce = false
local function onSimulate(e)
    if (onSimulateDoOnce == false) then
        local grateReference = tes3.getReference(common.data.objectIds.grateC)
        if (grateReference) then
            grateReference:disable()

            timer.delayOneFrame({
                callback = function()
                    grateReference.deleted = true
                end
            })
        end
        
        onSimulateDoOnce = true
    end

    if (tes3.player.position:distance(armiger.position) < 500) then
        event.unregister("simulate", onSimulate)
        common.debug("A Friend Lost: Unregistering Simulate Event.")

        tes3.updateJournal({
            id = journalId,
            index = 40
        })
    end
end

local function onCellChanged(e)
    if (e.cell.id == common.data.cellIds.underworks) then
        armiger = armiger or tes3.getReference(armigerId)    
        event.register("simulate", onSimulate)
        common.debug("A Friend Lost: Registering Simulate Event.")
    elseif (e.previousCell.id == common.data.cellIds.underworks) then
        armiger = nil
        event.unregister("simulate", onSimulate)
        common.debug("A Friend Lost: Unregistering Simulate Event.")
    end
end

local function processJournalIndexValue()
    if (journalIndex == 20) then
        -- Player has been asked to look for the buoyant armiger.
        event.register("cellChanged", onCellChanged)
        common.debug("A Friend Lost: Registering CellChanged Event.")
    elseif (journalIndex == 40) then
        -- Player has found the buoyant armiger's body in the Underworks.
        event.unregister("cellChanged", onCellChanged)
        common.debug("A Friend Lost: Unregistering CellChanged Event.")
        event.register("activate", onActivate)
        common.debug("A Friend Lost: Registering Activate Event.")
    elseif (journalIndex == 60) then
        -- Player found the amulet on the armiger's body.
    elseif (journalIndex == 80) then
        -- Player has completed the quest.
        event.unregister("journal", onJournal)
        common.debug("A Friend Lost: Unregistering Journal Event.")
    end
end

onJournal = function(e)
    if (e.topic.id ~= journalId) then
        return
    end

    common.debug("A Friend Lost: Updating Journal Index to: " .. e.index)

    updateJournalIndexValue(e.index)
    processJournalIndexValue()
end

local registered = false
local function onLoaded(e)
    if (registered == false) then
        updateJournalIndexValue()
        if (journalIndex == nil or journalIndex < 80) then
            common.debug("A Friend Lost: Registering Journal Event.")

            event.register("journal", onJournal)
            processJournalIndexValue()
        end
        registered = true
    end
end

event.register("loaded", onLoaded)