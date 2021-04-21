local this = {
  mcm = nil,
  metadataController = nil,
  unstackedHandlerModule = nil
}

local function ensureInitializationIsDone()
  if( this.metadataController == nil ) then
    tes3.messageBox( "Error with MAB0's unstacked mod initialization. Refer to MWSE.log" )

    return false
  end

  return true
end

local function createUnstackedHandler()
  this.unstackedHandlerModule = require( this.metadataController.getModulePath( this.metadataController.get().modules.unstackedHandler ) ).new()
end

local function appendModuleDataToUnstackedHandler()
  if( this.mcm.getConfig().spellUnstackedEnabled == true ) then
    this.unstackedHandlerModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.spellUnstacked ) ) )
  end

  if( this.mcm.getConfig().enchantUnstackedEnabled == true ) then
    this.unstackedHandlerModule.appendModuleData( require( this.metadataController.getModulePath( this.metadataController.get().modules.enchantUnstacked ) ) )
  end
end

local function onRegisterMcm()
  this.mcm = require( "MAB0.unstacked.mcm" ).new()
end
event.register( "modConfigReady", onRegisterMcm )

local function onInitialized()
  this.metadataController = require( "MAB0.metadataController" ).new( {
    modName = "unstacked",
    modPath = "MAB0.unstacked.",
    requires = {
      [ "MAB0.version" ] = { major = 1, minor = 1, patch = 1 }
    },
    modules = {
      unstackedHandler = "unstackedHandler",
      spellUnstacked = "spellUnstacked",
      enchantUnstacked = "enchantUnstacked"
    }
  } )
end
event.register( "initialized", onInitialized )

local function start()
  if( this.unstackedHandlerModule ~= nil ) then return end
  if( ensureInitializationIsDone() == false ) then return end

  createUnstackedHandler()
  appendModuleDataToUnstackedHandler()

  this.unstackedHandlerModule.start()
end
event.register( "loaded", start )

local function stop()
  if( this.unstackedHandlerModule == nil ) then return end

  this.unstackedHandlerModule.stop()
  this.unstackedHandlerModule = nil
end
event.register( "load", stop )