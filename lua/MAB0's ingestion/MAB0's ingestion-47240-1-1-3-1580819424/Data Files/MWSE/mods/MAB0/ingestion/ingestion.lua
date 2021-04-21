local localeStrings = require( "MAB0.ingestion.localeStrings" )
local locale = require( "MAB0.locale" ).new( localeStrings )
local timerExtensions = require( "MAB0.timer" )

local this = {
  justIngestedData = nil,
  underInfluenceData = nil,
  enableActiveMagicEffectTracking = false,
  lastGameHourInMenu = nil
}

local function isFromPlayer( equipData )
  return equipData.reference == tes3.player
end

local function isAnIngredientOrAPotion( equipData )
  local objectType = equipData.item.objectType

  return ( objectType == tes3.objectType.alchemy ) or ( objectType == tes3.objectType.ingredient )
end

local function hasPlayerJustIngestedSomething()
  return this.justIngestedData or this.underInfluenceData
end

local function getFormatStringArgumentFromObjectType( objectType )
  if( objectType == tes3.objectType.ingredient ) then
    return locale.getLocalizedString( "messageBox.justIngestedAnIngredientArg" )
  end

  return locale.getLocalizedString( "messageBox.justIngestedAPotionArg" )
end

local function getJustIngestedString()
  return string.format( locale.getLocalizedString( "messageBox.justIngestedFormatString" ), getFormatStringArgumentFromObjectType( this.justIngestedData.objectType ) )
end

local function getUnderInfluenceString()
  if( this.underInfluenceData.objectType ~= nil ) then
    return string.format( locale.getLocalizedString( "messageBox.underInfluenceFormatString" ), getFormatStringArgumentFromObjectType( this.underInfluenceData.objectType ) )
  end

  return locale.getLocalizedString( "messageBox.underInfluenceGenericString" )
end

local function getStringByIngestionType()
  if( this.justIngestedData ) then
    return getJustIngestedString()
  elseif( this.underInfluenceData ) then
    return getUnderInfluenceString()
  end
end

local function ingestItem( equipData )
  this.justIngestedData = {
    objectType = equipData.item.objectType
  }
end

local function attemptIngestItem( equipData )
  if( hasPlayerJustIngestedSomething() ) then
    tes3.messageBox( getStringByIngestionType() )

    equipData.block = true

    return
  end

  ingestItem( equipData )
end

local function onEquip( equipData )
  if( not isFromPlayer( equipData ) ) then return end
  if( not isAnIngredientOrAPotion( equipData ) ) then return end

  attemptIngestItem( equipData )
end

local function getRestHourCount()
  return tes3.getGlobal( "GameHour" ) - this.lastGameHourInMenu
end

local function isPlayerTarget( spellTickData )
  return spellTickData.target == tes3.player
end

local function hasAlchemicalSource( spellTickData )
  return spellTickData.sourceInstance.sourceType == tes3.magicSourceType.alchemy
end

local function getAfterRestEventName()
  local metadataController = require( "MAB0.metadataController" ).getMetadataControllerByModName( "ingestion" )
  local metadata = metadataController.get()

  return metadataController.getEventName( metadata.events.afterRestUnderInfluenceDataFound )
end

local function collectSpellTickForOneFrame( spellTickData )
  if( not isPlayerTarget( spellTickData ) ) then return end
  if( not hasAlchemicalSource( spellTickData ) ) then return end

  if( ( spellTickData.sourceInstance.serialNumber == this.underInfluenceData.sourceInstanceSerialNumber )
      and ( spellTickData.effectIndex == this.underInfluenceData.sourceEffectIndex ) ) then
    event.trigger( getAfterRestEventName(), { [ "spellTickData" ] = spellTickData } )
  end
end

local function findRemainingUnderInfluenceSpellEffect()
  timerExtensions.delayForFrameCount( 1,  function()
    event.register( "spellTick", collectSpellTickForOneFrame )
  end )

  timerExtensions.delayForFrameCount( 2, function()
    event.unregister( "spellTick", collectSpellTickForOneFrame )
    event.trigger( getAfterRestEventName(), { [ "spellTickData" ] = nil } )
  end )
end

local function resetIngestionData()
  this.underInfluenceData = nil
  this.justIngestedData = nil
  this.enableActiveMagicEffectTracking = false
  this.lastGameHourInMenu = tes3.getGlobal( "GameHour" )
end

local function createUnderInfluenceTracking()
  if( this.underInfluenceData.duration <= 0 ) then
    timerExtensions.delayForFrameCount( 1, resetIngestionData )
  else
    local trackingTimer = timer.start( {
      duration = this.underInfluenceData.duration,
      type = timer.simulate,
      callback = resetIngestionData
    } )

    this.underInfluenceData.trackingTimer = trackingTimer
  end
end

local function updateUnderInfluenceDataAndTracking( newTimerDuration )
  this.underInfluenceData.trackingTimer:cancel()

  if( newTimerDuration == 0 ) then
    resetIngestionData()
  else
    this.underInfluenceData.duration = newTimerDuration
    createUnderInfluenceTracking()
  end
end

local function getRemainingDurationForEffect( spellTickData, hourCount )
  local duration = spellTickData.source.effects[ spellTickData.effectIndex + 1 ].duration
  local timeActive = spellTickData.effectInstance.timeActive
  local secondCount = hourCount * 3600

  timeActive = ( ( timeActive + secondCount ) > duration ) and duration or ( timeActive + secondCount )

  spellTickData.effectInstance.timeActive = timeActive

  return duration - timeActive
end

local function registerForUnderInfluenceInvalidation( hourCount )
  event.register( getAfterRestEventName(), function( afterRestUnderInfluenceDataFoundData )
    local spellTickData = afterRestUnderInfluenceDataFoundData.spellTickData

    if( spellTickData == nil ) then
      resetIngestionData()
    else
      updateUnderInfluenceDataAndTracking( getRemainingDurationForEffect( spellTickData, hourCount ) )
    end
  end, { doOnce = true } )
end

local function invalidateExistingUnderInfluenceData( hourCount )
  if( this.underInfluenceData == nil ) then return end

  registerForUnderInfluenceInvalidation( hourCount )
  findRemainingUnderInfluenceSpellEffect()
end

local function handleRest()
  local hourCount = getRestHourCount()
  if( hourCount < 1 ) then return end

  invalidateExistingUnderInfluenceData( hourCount )
end

local function processNextFrame()
  if( not this.justIngestedData ) then return end
  if( this.enableActiveMagicEffectTracking == true ) then return end

  -- necessary to wait a frame in case exploitable effect active time invalidated fired
  timerExtensions.delayForFrameCount( 1, function() this.enableActiveMagicEffectTracking = true end )
end

local function onMenuExit()
  handleRest()
  processNextFrame()
end

local function onSimulate()
  processNextFrame()
end

local function getLongestEffectData( spellTickData )
  local maxDurationEffect = nil
  local maxDurationEffectIndex = 0

  for i = 1, #spellTickData.source.effects do
    local effect = spellTickData.source.effects[ i ]
    if( not maxDurationEffect or ( effect.duration > maxDurationEffect.duration ) ) then
      maxDurationEffect = effect
      maxDurationEffectIndex = i - 1
    end
  end

  return {
    sourceInstanceSerialNumber = spellTickData.sourceInstance.serialNumber,
    sourceEffectIndex = maxDurationEffectIndex,
    duration = maxDurationEffect.duration
  }
end

local function createUnderInfluenceData( spellTickData )
  local longestEffectData = getLongestEffectData( spellTickData )

  this.underInfluenceData = {
    sourceInstanceSerialNumber = longestEffectData.sourceInstanceSerialNumber,
    sourceEffectIndex = longestEffectData.sourceEffectIndex,
    duration = longestEffectData.duration,
    objectType = this.justIngestedData.objectType
  }

  this.justIngestedData = nil
end

local function areUnderInfluenceDataCreated()
  return ( ( not this.justIngestedData )
           or ( this.enableActiveMagicEffectTracking == false ) )
end

local function onSpellTick( spellTickData )
  if( areUnderInfluenceDataCreated() ) then return end
  if( not isPlayerTarget( spellTickData ) ) then return end
  if( not hasAlchemicalSource( spellTickData ) ) then return end

  createUnderInfluenceData( spellTickData )
  createUnderInfluenceTracking()

  this.enableActiveMagicEffectTracking = false
end

local function areEffectInvalidatedDataAndUnderInfluenceDataMatching( effectActiveTimeInvalidatedData )
  return this.underInfluenceData
         and ( effectActiveTimeInvalidatedData.effectData.sourceInstanceSerialNumber == this.underInfluenceData.sourceInstanceSerialNumber )
         and ( effectActiveTimeInvalidatedData.effectData.sourceEffectIndex == this.underInfluenceData.sourceEffectIndex )
end

local function onExploitableEffectActiveTimeInvalidated( effectActiveTimeInvalidatedData )
  if( not areEffectInvalidatedDataAndUnderInfluenceDataMatching( effectActiveTimeInvalidatedData ) ) then return end

  updateUnderInfluenceDataAndTracking( effectActiveTimeInvalidatedData.effectData.newEffectRemainingTime )
end

local function onMenuEnter()
  this.lastGameHourInMenu = tes3.getGlobal( "GameHour" )
end

local function getExploitableEffectActiveTimeInvalidatedEventName()
  local exploitableMetadataController = require( "MAB0.metadataController" ).getMetadataControllerByModName( "exploitable" )

  if( exploitableMetadataController == nil ) then
    return nil
  end

  local exploitableMetadata = exploitableMetadataController.get()

  return exploitableMetadataController.getEventName( exploitableMetadata.events.effectActiveTimeInvalidated )
end

local function registerExploitableModEvents()
  local eventName = getExploitableEffectActiveTimeInvalidatedEventName()

  if( eventName == nil ) then
    return
  end

  event.register( eventName , onExploitableEffectActiveTimeInvalidated )
end

local function unregisterExploitableModEvents()
  local eventName = getExploitableEffectActiveTimeInvalidatedEventName()

  if( eventName == nil ) then
    return
  end

  event.unregister( eventName, onExploitableEffectActiveTimeInvalidated )
end

local function startCrossModInterop()
  registerExploitableModEvents()
end

local function stopCrossModInterop()
  unregisterExploitableModEvents()
end

local function initializeUnderInfluenceDataWithEffectData( effectData )
  this.underInfluenceData = this.underInfluenceData or {}

  this.underInfluenceData.sourceInstanceSerialNumber = effectData.sourceInstanceSerialNumber
  this.underInfluenceData.sourceEffectIndex = effectData.sourceEffectIndex
  this.underInfluenceData.duration = effectData.duration
end

local function collectOrphanActiveAlchemySpellTick( spellTickData )
  if( not isPlayerTarget( spellTickData ) ) then return end
  if( not hasAlchemicalSource( spellTickData ) ) then return end

  local effectData = getLongestEffectData( spellTickData )
  if( ( this.underInfluenceData == nil ) or ( effectData.duration > this.underInfluenceData.duration ) ) then
    initializeUnderInfluenceDataWithEffectData( effectData )
  end

  createUnderInfluenceTracking()
end

local function handleOrphanActiveAlchemicalEffects()
  timerExtensions.delayForFrameCount( 1,  function()
    event.register( "spellTick", collectOrphanActiveAlchemySpellTick )
  end )

  timerExtensions.delayForFrameCount( 2, function()
    event.unregister( "spellTick", collectOrphanActiveAlchemySpellTick )
  end )
end

local function start()
  resetIngestionData()
  handleOrphanActiveAlchemicalEffects()

  event.register( "equip", onEquip )
  event.register( "menuExit", onMenuExit )
  event.register( "simulate", onSimulate )
  event.register( "spellTick", onSpellTick )
  event.register( "menuEnter", onMenuEnter )

  startCrossModInterop()
end

local function stop()
  event.unregister( "equip", onEquip )
  event.unregister( "menuExit", onMenuExit )
  event.unregister( "simulate", onSimulate )
  event.unregister( "spellTick", onSpellTick )
  event.unregister( "menuEnter", onMenuEnter )

  stopCrossModInterop()
end

return {
  new = function()
    return {
      start = start,
      stop = stop
    }
  end
}