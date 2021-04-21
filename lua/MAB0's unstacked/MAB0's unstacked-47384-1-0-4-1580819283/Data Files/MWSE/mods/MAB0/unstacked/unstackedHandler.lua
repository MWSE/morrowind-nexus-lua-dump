local tableExtensions = require( "MAB0.table" )
local timerExtensions = require( "MAB0.timer" )

local this = {
  modulesData = nil,
  activeModule = nil,
  collectionContext = nil
}

local function assertModuleDataCorrectness( moduleData )
  local printMessage = function()
    tes3.messageBox( "Error with unstacked initialization. Check MWSE.log." )

    return true
  end

  local hasMustHandleSpellHitDataFunction = function() return ( type( moduleData.mustHandleSpellHitData ) == "function" ) end
  local hasGetExtraPropertyTableForEffectCollectionFunction = function() return ( type( moduleData.getExtraPropertyTableForEffectCollection ) == "function" ) end
  local hasGetMustIgnoreSpellTickCallbackFunction = function() return ( type( moduleData.getMustIgnoreSpellTickCallback ) == "function" ) end

  local _
  _ = hasMustHandleSpellHitDataFunction() or ( printMessage() and assert( false, "Error when initializing unstackedHandler. 'moduleData' must have a 'mustHandleSpellHitData' function." ) )
  _ = hasGetExtraPropertyTableForEffectCollectionFunction() or ( printMessage() and assert( false, "Error when initializing unstackedHandler. 'moduleData' must have a 'getExtraPropertyTableForEffectCollection' function." ) )
  _ = hasGetMustIgnoreSpellTickCallbackFunction() or ( printMessage() and assert( false, "Error when initializing unstackedHandler. 'moduleData' must have a 'getMustIgnoreSpellTickCallback' function." ) )
end

local function getHandlingModule( spellResistData )
  for _, moduleData in pairs( this.modulesData ) do
    if( moduleData.mustHandleSpellHitData( spellResistData ) ) then
      return moduleData
    end
  end
end

local function appendPropertiesToCollectedEffectInfo( collectedEffectInfo, propertyTable )
  if( propertyTable == nil ) then return end

  for k,v in pairs( propertyTable ) do
    collectedEffectInfo[ k ]= v
  end
end

local function collectEffect( serialNumber, target, extraPropertyTable, effectInfoTable )
  this.collectionContext = this.collectionContext or {}
  this.collectionContext[ serialNumber ] = this.collectionContext[ serialNumber ] or {}
  local collectedEffectInfo = this.collectionContext[ serialNumber ]

  collectedEffectInfo.targets = collectedEffectInfo.targets or {}
  table.insert( collectedEffectInfo.targets, target )

  appendPropertiesToCollectedEffectInfo( collectedEffectInfo, extraPropertyTable )

  collectedEffectInfo.effects = collectedEffectInfo.effects or {}
  table.insert( collectedEffectInfo.effects, effectInfoTable )
end

local function getEffectCount( spellHitData )
  return tableExtensions.countIf( spellHitData.source.effects, function( _, v ) return v.id ~= -1 end )
end

local function areAllEffectCollected( spellHitData )
  local maxEffectCount = getEffectCount( spellHitData )
  local currentCollectedEffectCount = #this.collectionContext[ spellHitData.sourceInstance.serialNumber ].effects

  return maxEffectCount == currentCollectedEffectCount
end

local function getEffectIdFromSpellEventData( spellHitData )
  local source = spellHitData.source
  local fixedEffectIndex = spellHitData.effectIndex + 1

  return source.effects[ fixedEffectIndex ].id
end

local function getEffectAttributeIdFromSpellEventData( spellHitData )
  local source = spellHitData.source
  local fixedEffectIndex = spellHitData.effectIndex + 1

  return source.effects[ fixedEffectIndex ].attribute
end

local function getEffectSkillIdFromSpellEventData( spellHitData )
  local source = spellHitData.source
  local fixedEffectIndex = spellHitData.effectIndex + 1

  return source.effects[ fixedEffectIndex ].skill
end

local function isSpellHitEffectInfoTableContaining( spellTickData, spellHitEffectInfoTable )
  local effectId = spellTickData.effectId
  local attributeId = getEffectAttributeIdFromSpellEventData( spellTickData )
  local skillId = getEffectSkillIdFromSpellEventData( spellTickData )

  return tableExtensions.findIf( spellHitEffectInfoTable, function( _, v )
    return ( v.id == effectId ) and ( v.attributeId == attributeId ) and ( v.skillId == skillId )
  end ) ~= nil
end

local function doEffectInvalidationIfNeeded( spellTickData, spellHitEffectInfoTable )
  if( not isSpellHitEffectInfoTableContaining( spellTickData, spellHitEffectInfoTable ) ) then return end

  spellTickData.effectInstance.state = tes3.spellState.ending
end

local function makeOnSpellTickFunctionInCollectedEffectInfo( serialNumber, target )
  local collectedEffectInfo = this.collectionContext[ serialNumber ]
  local mustIgnoreSpellTick = this.activeModule.getMustIgnoreSpellTickCallback( collectedEffectInfo, serialNumber )

  function collectedEffectInfo.onSpellTick( spellTickData )
    if( tableExtensions.countIf( collectedEffectInfo.targets, function( _, v ) return target == v end ) == 0 ) then return true end

    if( mustIgnoreSpellTick( spellTickData ) == true ) then return end

    doEffectInvalidationIfNeeded( spellTickData, collectedEffectInfo.effects )
  end

  return collectedEffectInfo.onSpellTick
end

local function enableSpellTick( serialNumber, target )
  event.register( "spellTick", makeOnSpellTickFunctionInCollectedEffectInfo( serialNumber, target ) )
end

local function disableSpellTickAndCleanup( serialNumber )
  event.unregister( "spellTick", this.collectionContext[ serialNumber ].onSpellTick )
  this.collectionContext[ serialNumber ] = nil
end

local function scheduleEffectInvalidation( serialNumber, target )
  timerExtensions.delayForFrameCount( 1, function() enableSpellTick( serialNumber, target ) end )
  timerExtensions.delayForFrameCount( 2, function() disableSpellTickAndCleanup( serialNumber ) end )
end

local function scheduleEffectInvalidationAfterCollection( spellHitData, serialNumber, target )
  if( areAllEffectCollected( spellHitData ) ) then
    scheduleEffectInvalidation( serialNumber, target )
  end
end

local function onSpellHit( spellHitData )
  local serialNumber = spellHitData.sourceInstance.serialNumber
  local target = spellHitData.target

  collectEffect( serialNumber,
                 target,
                 this.activeModule.getExtraPropertyTableForEffectCollection( spellHitData ),
                 {
                   id = getEffectIdFromSpellEventData( spellHitData ),
                   attributeId = getEffectAttributeIdFromSpellEventData( spellHitData ),
                   skillId = getEffectSkillIdFromSpellEventData( spellHitData ),
                   instance = spellHitData.effectInstance
                 } )

  scheduleEffectInvalidationAfterCollection( spellHitData, serialNumber, target )
end

local function onSpellResist( spellResistData )
  this.activeModule = getHandlingModule( spellResistData )

  if( this.activeModule == nil ) then return end

  onSpellHit( spellResistData )
end

return {
  new = function()
    this.modulesData = this.modulesData or {}

    return {
      appendModuleData = function( moduleData )
        assertModuleDataCorrectness( moduleData )

        table.insert( this.modulesData, moduleData )
      end,

      start = function()
        event.register( "spellResist", onSpellResist )
      end,

      stop = function()
        event.unregister( "spellResist", onSpellResist )
      end
    }
  end

}