-- local async = require('openmw.async')
-- local core = require('openmw.core')
-- local time = require('openmw_aux.time')
local types = require('openmw.types')
-- local util = require('openmw.util')
local world = require('openmw.world')

local I = require('openmw.interfaces')
local ModInfo = require('scripts.sw4.modinfo')

local FreighterState = {
  currentPlanet = nil,
  liveButtonToCellMap = {},
  replacementFreighterId = nil,
  replacementDoorId = nil,
  replacementLightSpeed = nil,
  travelActive = false,
  repairedShip = false,
  replacementDoorInstance = nil,
}

local FreighterStaticData = require('Scripts.SW4.data.freighterStaticData')
local FreighterCell = world.getCellByName(FreighterStaticData.CellName)

local FreighterManager = require('Scripts.SW4.freighter.freighterManager')(FreighterState, FreighterCell)

return {
  interfaceName = 'SW4_FreighterController',
  interface = {
    FreighterState = FreighterState,
  },
  engineHandlers = {
    onSave = function()
      return {
        currentPlanet = FreighterState.currentPlanet,
        replacementLightSpeed = FreighterState.replacementLightSpeed,
        replacementFreighterId = FreighterState.replacementFreighterId,
        replacementDoorId = FreighterState.replacementDoorId,
        replacementDoorInstance = FreighterState.replacementDoorInstance,
        travelActive = FreighterState.travelActive,
        repairedShip = FreighterState.repairedShip,
        liveButtonToCellMap = FreighterState.liveButtonToCellMap,
      }
    end,
    onLoad = function(saveData)
      FreighterState.currentPlanet = saveData.currentPlanet
      FreighterState.replacementDoorId = saveData.replacementDoorId
      FreighterState.replacementDoorInstance = saveData.replacementDoorInstance
      FreighterState.replacementFreighterId = saveData.replacementFreighterId
      FreighterState.replacementLightSpeed = saveData.replacementLightSpeed
      FreighterState.travelActive = saveData.travelActive
      FreighterState.liveButtonToCellMap = saveData.liveButtonToCellMap
      FreighterState.repairedShip = saveData.repairedShip

      --- Instantiate new records and overrides as early and infrequently as possible!
      --- onPlayerAdded may be tempting but could trigger re-initializations of the callback functions
      --- Which it should handle but we want to minimize anyway
    end,
    onActivate = function(object, actor)
      for _, onActivateHandler in ipairs {
        FreighterManager.activateFreighterEntrance,
        FreighterManager.activateTravelButton,
        FreighterManager.activateExitDoor
      } do
        if onActivateHandler(object, actor) then break end
      end
    end,
    onObjectActive = function(object)
      for _, onObjectActiveHandler in ipairs {
        I[ModInfo.name .. '_RecordReplacer'].replaceSubscribedObjects,
        FreighterManager.disableShipQuestActors,
      } do
        if onObjectActiveHandler(object) then break end
      end
    end,
    --- Player is passed as the first argument to this function, but right now we don't actually use it.
    onPlayerAdded = function(_)
      FreighterManager.createReplacementFreighterRecords()
    end,
  },
  eventHandlers = {
    SW4_PlayerCellChanged = function(cellChangeData)
      for _, cellChangeHandler in ipairs { FreighterManager.handleFreighterEntry, } do
        if cellChangeHandler(cellChangeData) then break end
      end
    end,
  }
}
