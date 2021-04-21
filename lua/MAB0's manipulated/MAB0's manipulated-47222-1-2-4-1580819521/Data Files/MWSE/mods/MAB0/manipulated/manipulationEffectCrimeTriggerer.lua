local this = {
  modulesData = nil,
  affectedVictims = nil
}

local function assertModuleDataCorrectness( moduleData )
  local printMessage = function()
    tes3.messageBox( "Error with manipulated initialization. Check MWSE.log." )

    return true
  end

  local isTable = function() return ( type( moduleData ) == "table" ) end
  local hasMagicEffectIdProperty = function() return type( moduleData.magicEffectId ) == "number" end

  local _
  _ = isTable() or ( printMessage() and assert( false, "Error when initializing manipulationEffectCrimerTriggerer. 'moduleData' must be a table." ) )
  _ = hasMagicEffectIdProperty() or ( printMessage() and assert( false, "Error when initializing manipulationEffectCrimerTriggerer. 'moduleData' must have a number property named magicEffectId." ) )
end

local function targetIsNPC( spellTickData )
  -- in some circumstances, target may ben not set.
  if( spellTickData.target == nil ) then
    return false
  end

  return ( spellTickData.target.object.objectType == tes3.objectType.npc )
         and ( not spellTickData.target.mobile.inCombat )
end

local function casterIsPlayer( spellTickData )
  return spellTickData.caster == tes3.player
end

local function isCriminalEffect( spellTickData )
  for _, effect in pairs( this.modulesData ) do
    if( spellTickData.effectId == effect.magicEffectId ) then
      return true
    end
  end

  return false
end

local function makeVictimEntry( spellTickData )
  return {
    serialNumber = spellTickData.sourceInstance.serialNumber,
    effectIndex = spellTickData.effectIndex,
    targetId = spellTickData.target.object.id
  }
end

local function areVictimEntriesEqual( left, right )
  if( ( left.serialNumber == right.serialNumber )
      and ( left.effectIndex == right.effectIndex )
      and ( left.targetId == right.targetId ) ) then
    return true
  end
end

local function findVictim( entry )
  for _, victim in pairs( this.affectedVictims ) do
    if( areVictimEntriesEqual( entry, victim ) ) then return true end
  end
end

local function removeVictim( entry )
  local remainingVictims = {}

  for i = #this.affectedVictims, 1, -1 do
    if( areVictimEntriesEqual( entry, this.affectedVictims[ i ] ) ) then
      this.affectedVictims[ i ] = nil
    else
      table.insert( remainingVictims, this.affectedVictims[ i ] )
    end
  end

  this.affectedVictims = remainingVictims
end

local function scheduleAffectedVictimsTablePrune( spellTickData, entry )
  timer.start( {
    type = timer.simulate,
    duration = spellTickData.sourceInstance.source.effects[ spellTickData.effectIndex + 1 ].duration + 1,
    callback = function()
      removeVictim( entry )
    end
  } )
end

local function reportCrime( spellTickData )
  this.affectedVictims = this.affectedVictims or {}

  local entry = makeVictimEntry( spellTickData )

  if( not findVictim( entry ) ) then
    tes3.triggerCrime( {
      criminal = tes3.player,
      type = tes3.crimeType.attack,
      value = 40,
      victim = spellTickData.target
    } )

    table.insert( this.affectedVictims, entry )
    scheduleAffectedVictimsTablePrune( spellTickData, entry )
  end
end

local function onSpellTick( spellTickData )
  if( targetIsNPC( spellTickData ) and casterIsPlayer( spellTickData ) and isCriminalEffect( spellTickData ) ) then
    reportCrime( spellTickData )
  end
end

return {
  new = function()
    return {
      appendModuleData = function( moduleData )
        assertModuleDataCorrectness( moduleData )

        this.modulesData = this.modulesData or {}

        table.insert( this.modulesData, moduleData )
      end,

      start = function()
        event.register( "spellTick", onSpellTick )
      end,

      stop = function()
        event.unregister( "spellTick", onSpellTick )
      end
    }
  end,
}