local this = {
  mcm = nil,
  metadataController = nil,
  manipulationEffectCrimeTriggererModule = nil
}

local function createManipulationEffectCrimeTriggerer()
  this.manipulationEffectCrimeTriggererModule = require( this.metadataController.getModulePath( this.metadataController.get().modules.manipulationEffectCrimeTriggerer ) ).new()
end

local function appendModuleDataToManipulationEffectCrimeTriggerer()
  if( this.mcm.getConfig().calmHumanoidEnabled == true ) then
    this.manipulationEffectCrimeTriggererModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.calm ) ) )
  end

  if( this.mcm.getConfig().commandHumanoidEnabled == true ) then
    this.manipulationEffectCrimeTriggererModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.command ) ) )
  end

  if( this.mcm.getConfig().demoralizeHumanoidEnabled == true ) then
    this.manipulationEffectCrimeTriggererModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.demoralize ) ) )
  end

  if( this.mcm.getConfig().frenzyHumanoidEnabled == true ) then
    this.manipulationEffectCrimeTriggererModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.frenzy ) ) )
  end

  if( this.mcm.getConfig().rallyHumanoidEnabled == true ) then
    this.manipulationEffectCrimeTriggererModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.rally ) ) )
  end

  if( this.mcm.getConfig().charmEnabled == true ) then
    this.manipulationEffectCrimeTriggererModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.charm ) ) )
  end
end

local function ensureInitializationIsDone()
  if( this.metadataController == nil ) then
    tes3.messageBox( "Error with MAB0's manipulated mod initialization. Refer to MWSE.log" )

    return false
  end

  return true
end

local function onRegisterMcm()
  this.mcm = require( "MAB0.manipulated.mcm" ).new()
end
event.register( "modConfigReady", onRegisterMcm )

local function onInitialized()
  this.metadataController = require( "MAB0.metadataController" ).new( {
    modName = "manipulated",
    modPath = "MAB0.manipulated.",
    requires = {
      [ "MAB0.version" ] = { major = 1, minor = 0, patch = 1 }
    },
    modules = {
      calm = "calm",
      charm = "charm",
      command = "command",
      demoralize = "demoralize",
      frenzy = "frenzy",
      rally = "rally",
      manipulationEffectCrimeTriggerer = "manipulationEffectCrimeTriggerer"
    }
  } )
end
event.register( "initialized", onInitialized )

local function start()
  if( this.manipulationEffectCrimeTriggererModule ~= nil ) then return end
  if( ensureInitializationIsDone() == false ) then return end

  createManipulationEffectCrimeTriggerer()
  appendModuleDataToManipulationEffectCrimeTriggerer()

  this.manipulationEffectCrimeTriggererModule.start()
end
event.register( "loaded", start )

local function stop()
  if( this.manipulationEffectCrimeTriggererModule == nil ) then return end

  this.manipulationEffectCrimeTriggererModule.stop()

  this.manipulationEffectCrimeTriggererModule = nil
end
event.register( "load", stop )