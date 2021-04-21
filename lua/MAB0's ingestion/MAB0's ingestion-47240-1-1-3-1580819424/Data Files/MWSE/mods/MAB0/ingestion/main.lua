local this = {
  mcm = nil,
  metadataController = nil,
  ingestionModule = nil
}

local function createIngestion()
  this.ingestionModule = require( this.metadataController.getModulePath( this.metadataController.get().modules.ingestion ) ).new()
end

local function ensureInitializationIsDone()
  if( this.metadataController == nil ) then
    tes3.messageBox( "Error with MAB0's ingestion mod initialization. Refer to MWSE.log" )

    return false
  end

  return true
end

local function onRegisterMcm()
  this.mcm = require( "MAB0.ingestion.mcm" ).new()
end
event.register( "modConfigReady", onRegisterMcm )

local function onInitialized()
  this.metadataController = require( "MAB0.metadataController" ).new( {
    modName = "ingestion",
    modPath = "MAB0.ingestion.",
    requires = {
      [ "MAB0.version" ] = { major = 1, minor = 0, patch = 1 }
    },
    modules = {
      ingestion = "ingestion"
    },
    eventPrefix = "MAB0.ingestion.",
    events = {
      afterRestUnderInfluenceDataFound = "afterRestUnderInfluenceDataFound"
    }
  } )
end
event.register( "initialized", onInitialized )

local function start()
  if( this.ingestionModule ~= nil ) then return end
  if( ensureInitializationIsDone() == false ) then return end

  if( this.mcm.getConfig().enableIngestion == false ) then return end

  createIngestion()

  this.ingestionModule.start()
end
event.register( "loaded", start )

local function stop()
  if( this.ingestionModule == nil ) then return end

  this.ingestionModule.stop()

  this.ingestionModule = nil
end
event.register( "load", stop )