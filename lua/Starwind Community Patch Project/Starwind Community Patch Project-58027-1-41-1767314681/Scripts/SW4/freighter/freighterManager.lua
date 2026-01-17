local async = require('openmw.async')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')

local I = require('openmw.interfaces')

local FreighterManager = {}
local FreighterStaticData = require('scripts.sw4.data.freighterStaticData')
local FreighterState, FreighterCell
local ModInfo = require('scripts.sw4.modinfo')

--- Disables all planets which the player is not actually on
--- Bit edge casey since not all planets have a corresponding freighter,
--- but this shouldn't *break* anything per se
--- I don't think. :D
function FreighterManager.activateCurrentPlanet()
    if not FreighterState.currentPlanet then return end

    local localActivators = FreighterCell:getAll(types.Activator)

    for _, activator in ipairs(localActivators) do
        for cellId, planetData in pairs(FreighterStaticData.Destinations) do
            if activator.recordId == planetData.planetActivator then
                activator.enabled = (cellId == FreighterState.currentPlanet)
                break
            end
        end
    end
end

function FreighterManager.notifyTravelEnded(activatorData)
    activatorData.activator.enabled = false

    for _, player in ipairs(world.players) do
        if player.cell.name == FreighterStaticData.CellName then
            player:sendEvent('SW4_UIMessage', string.format('You have reached %s.', activatorData.cellDest))
            FreighterState.travelActive = false
        end
    end
end

--- Callback to disable the lightspeed activator after travel is complete and notify relevant players
FreighterManager.LightSpeedActivatorCallback =
    async:registerTimerCallback('SW4_TravelEndCallback',
        FreighterManager.notifyTravelEnded)

--- Search the freighter cell for the lightspeed activator
--- Throws if it's unable to locate the activator
---@return core.gameObject lightspeedActivator The lightspeed activator object
function FreighterManager.findLightSpeedActivator()
    local replacementLightSpeed = FreighterState.replacementLightSpeed

    for _, object in ipairs(FreighterCell:getAll(types.Activator)) do
        if object.recordId == replacementLightSpeed then
            object.enabled = true
            return object
        end
    end

    error('Failed to find lightspeed activator in freighter cell!')
end

--- Sends the player to the freighter cell and plays the door sound
function FreighterManager.playerEnterFreighter(actor)
    actor:sendEvent('SW4_AmbientEvent', {
        soundFile = FreighterStaticData.Sfx.Door,
        options = {},
    })

    async:newUnsavableSimulationTimer(0.1 * time.second, function()
        actor:teleport(FreighterStaticData.CellName, FreighterStaticData.InteriorTeleportPosition,
            FreighterStaticData.InteriorTeleportRotation)
    end)
end

--- Handles activation of all freighter travel buttons,
--- notifying players, triggering the lightspeed activator, and playing the travel sound
function FreighterManager.activateTravelButton(object)
    local targetCell = FreighterState.liveButtonToCellMap[object.recordId]
    if not targetCell then return end

    if FreighterState.travelActive then return end

    FreighterState.currentPlanet = targetCell
    FreighterManager.activateCurrentPlanet()

    local ambientData = {
        soundFile = FreighterStaticData.Sfx.Travel,
        options = {},
    }

    -- local travelDelay = math.random(15, 45)
    -- local travelStr = string.format('You will reach your destination in %d minutes. Please enjoy the trip.', travelDelay)
    -- Maybe if we later come up with interesting things to do in the ship, we can make up an excuse to increase travel times.
    -- For now I think it's a bad idea since it would be boring and you'd just sleep through it.
    -- Or maybe fight through it...
    local targetPlanet = object.type.records[object.recordId].name
    local travelStr = string.format("Engaging warp drive, on course for %s.", targetPlanet)

    for _, player in ipairs(world.players) do
        if player.cell.name == FreighterStaticData.CellName then
            player:sendEvent('SW4_AmbientEvent', ambientData)
            player:sendEvent('SW4_UIMessage', travelStr)
        end
    end

    local lightSpeedActivator = FreighterManager.findLightSpeedActivator()
    assert(lightSpeedActivator, 'Failed to locate lightspeed activator in freighter cell!')

    time.newSimulationTimer(time.second * 5,
        FreighterManager.LightSpeedActivatorCallback,
        {
            activator = lightSpeedActivator,
            cellDest = targetPlanet,
        })

    FreighterState.travelActive = true
end

--- Activation handler for the ship 'door'
--- plays the door sound and teleports the player out of the freighter
function FreighterManager.activateExitDoor(door, actor)
    if door.recordId ~= FreighterState.replacementDoorId or FreighterState.travelActive then return end

    local teleportTarget = FreighterStaticData.Destinations[FreighterState.currentPlanet]
    assert(teleportTarget, "Could not find current planet in cell data!")

    actor:sendEvent('SW4_AmbientEvent', {
        soundFile = FreighterStaticData.Sfx.Door,
        options = {},
    })

    -- Maybe can deduplicate this and enterShip later
    async:newUnsavableSimulationTimer(0.05 * time.second, function()
        actor:teleport(FreighterState.currentPlanet,
            teleportTarget.teleportTo.pos,
            util.transform.rotateZ(math.rad(teleportTarget.teleportTo.rot),
                util.transform.identity))
    end)

    return true
end

--- Handles freighter activation by teleporting the player into the freighter,
--- playing necessary sounds and journal checks, and updating the interior state of the freighter
--- TESTING:
--- player->additem sw_envirofilter 3
--- journal sw_tarischap1-2 10
---@param object core.gameObject Object which was activated
---@param actor types.Actor Actor whom activated the ship (hopefully, a player, but we're not picky)
function FreighterManager.activateFreighterEntrance(object, actor)
    local freighterId = FreighterState.replacementFreighterId
    if not freighterId or object.recordId ~= freighterId then return end

    -- When activating the freighter, set the current planet
    -- Before actually doing any handling of said planet
    -- We want the freighter to be up-to-date at all times
    -- So even if this isn't necessary due to an invalid activation
    -- It's still necessary for diagesis
    -- We should also apply the `activateCurrentPlanet` function
    -- When handling other teleports, when possible
    FreighterState.currentPlanet = actor.cell.name:lower()

    if not types.Player.objectIsInstance(actor) then return end

    local playerQuests = actor.type.quests(actor)
    local shipQuest = playerQuests['sw_tarischap1-2']
    local shipQuestProgress = shipQuest.stage

    if shipQuestProgress < 10 then
        actor:sendEvent('SW4_UIMessage', 'I wonder whose ship this is. . .')
    elseif shipQuestProgress == 10 then
        local inventory = actor.type.inventory(actor)
        local environmentFilterCount = inventory:countOf('sw_envirofilter')
        if environmentFilterCount >= 3 then
            inventory:find('sw_envirofilter'):remove(environmentFilterCount)

            -- Still need to add the topic "head to ship"
            for _, activeActor in ipairs(world.activeActors) do
                if activeActor.recordId == 'sw_shademanaan1' then
                    core.sound.say('sound/ig/kellishipfix.wav', activeActor, 'It\'s all fixed up! Let\'s check it out.')
                    break
                end
            end

            actor:sendEvent('SW4_UIMessage', 'You repair the ship!')
            shipQuest:addJournalEntry(15, actor)
            playerQuests['sw_shipown']:addJournalEntry(15, actor)
        else
            actor:sendEvent('SW4_UIMessage',
                string.format('This ship needs repairs! Components %d/3',
                    environmentFilterCount))
        end
    else
        FreighterManager.playerEnterFreighter(actor)
        return true
    end
end

--- Appropriately sets state for all current planets
function FreighterManager.handleFreighterEntry(cellChangeData)
    local newCell = cellChangeData.player.cell

    if newCell.name ~= FreighterStaticData.CellName then return end

    FreighterManager.activateCurrentPlanet()
end

local SWTarisChap1_2Actors = {
    ['sw_shademanaan1'] = true,
    ['sw_shipquester'] = true,
}

-- Disables relevant NPCs when sw_tarischap1-2 is over 10 and the player repairs the ship
function FreighterManager.disableShipQuestActors(object)
    if not SWTarisChap1_2Actors[object.recordId] or not FreighterState.repairedShip then return end

    object.enabled = false
    object:remove()
    return true
end

function FreighterManager.createReplacementFreighterRecords()
    assert(FreighterState, 'FreighterState is nil!')

    local RecordReplacer = I[ModInfo.name .. '_RecordReplacer']

    -- Create a replacement activator for the freighter itself, so we don't use the original script at all
    if not FreighterState.replacementFreighterId then
        FreighterState.replacementFreighterId = RecordReplacer.newRecord {
            recordType = 'activator',
            recordData = {
                name = 'Freighter',
                model = FreighterStaticData.Models.Freighter,
            },
        }
    end

    for recordId, _ in pairs(FreighterStaticData.ShipsToReplace) do
        RecordReplacer.subscribeToReplacement {
            originalRecordId = recordId,
            replacementRecordId = FreighterState.replacementFreighterId,
        }
    end

    for recordId, replaceThisDoor in pairs(FreighterStaticData.DoorsToRemove) do
        if replaceThisDoor then
            FreighterState.replacementDoorId = RecordReplacer.replaceRecord {
                recordId = recordId,
                recordType = 'activator',
                recordData = {
                    model = FreighterStaticData.Models.Door,
                    name = 'Ship Exit Door',
                },
            }
        else
            RecordReplacer.subscribeToDeletion(recordId)
        end
    end

    -- Replace lightspeed activator since it self-deletes
    FreighterState.replacementLightSpeed = RecordReplacer.replaceRecord {
        recordId = 'sw_lightspeedact',
        recordType = 'activator',
        recordData = {
            model = FreighterStaticData.Models.LightSpeed,
        },
    }

    for recordId, targetCell in pairs(FreighterStaticData.ButtonRecordIdsToDestinationCells) do
        local newButtonRecordId = RecordReplacer.replaceRecord {
            recordId = recordId,
            recordType = 'activator',
            recordData = {
                template = types.Activator.records[recordId],
                mwscript = '',
            },
        }

        FreighterState.liveButtonToCellMap[newButtonRecordId] = targetCell
    end
end

return function(freighterState, freighterCell)
    assert(freighterState, 'SW4Freighter: FreighterState is nil!')
    assert(freighterCell, 'SW4Freighter: FreighterCell is nil!')

    FreighterState = freighterState
    FreighterCell = freighterCell

    return FreighterManager
end
