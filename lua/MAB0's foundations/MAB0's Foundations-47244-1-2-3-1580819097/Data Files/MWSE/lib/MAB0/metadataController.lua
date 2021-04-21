local this = {
  data = nil
}

local stringUtils = require( "MAB0.string" )
local tableUtils = require( "MAB0.table" )
local versionUtils = require( "MAB0.version" )

local function get()
  return this.data
end

local function getEventName( eventName )
  assert( type( eventName ) == "string", "The specified event name must be a string" )

  for _, e in pairs( this.data.events ) do
    if( e == eventName ) then return this.data.eventPrefix .. eventName end
  end

  assert( false, string.format( "The specified event : '%s' does not exist", eventName ) )
end

local function assertModuleNameIsCorrect( moduleName )
  assert( type( moduleName ) == "string", "The specified module name must be a string" )

  for k, _ in pairs( this.data.modules ) do
    if( k == moduleName ) then return end
  end

  assert( false, string.format( "The specified module : '%s' does not exist", moduleName ) )
end

local function getModulePath( moduleName )
  assertModuleNameIsCorrect( moduleName )

  return this.data.modPath .. moduleName
end

local function getModulePersistentDataPropertyString( moduleName )
  assertModuleNameIsCorrect( moduleName )

  return this.data.modPath .. moduleName
end

local function getModDirectoryFromModPath()
  local modPathTable = stringUtils.explodePropertyStringInTable( this.data.modPath )
  local modDirectory = ""
  local separator = ""

  for _, property in pairs( modPathTable ) do
    modDirectory = string.format( "%s%s%s", modDirectory, separator, property )
    separator = "/"
  end

  return modDirectory
end

local function getModuleFilePath( moduleName )
  assertModuleNameIsCorrect( moduleName )

  local modDir = string.format( "Data Files/MWSE/mods/%s", getModDirectoryFromModPath() )

	for file in lfs.dir( modDir ) do
		local path = string.format( "%s/%s", modDir, file )
		local fileAttributes = lfs.attributes( path )
		if ( fileAttributes.mode == "file" and file == string.format( "%s.lua", moduleName ) ) then
			return path
		end
	end
end

local function assertModulesCorrectness( data )
  assert( tableUtils.isNilOrTable( data.modules ), "The metadata table 'modules' property must be nil or a table" )

  if( data.modules ) then
    for _, m in pairs( data.modules ) do
      assert( not stringUtils.isNilOrNotStringOrEmpty( m ), "The metadata table 'modules' property must be a table containing string properties as module names" )
    end
  end
end

local function assertEventsCorrectness( data )
  assert( stringUtils.isNilOrNotEmpty( data.eventPrefix ), "The metadata table 'eventPrefix' property must be either nil or a non empty string" )

  if( data.eventPrefix ) then
    assert( type( data.events ) == "table", "The metadata table 'events' property must be a table" )

    for _, e in pairs( data.events ) do
      assert( not stringUtils.isEmpty( e ), "The metadata table 'events' property must contains non empty strings as event names" )
    end
  end
end

local function assertRequireVersionCorrectness( version )
  assert( type( version ) == "table", "The metadata table 'requires' property must have a 'version' table property" )

  for _, v in pairs( { "major", "minor", "patch" } ) do
    assert( type( version[ v ] ) == "number", string.format( "The metadata table 'requires' property must have a 'version.%s' number property", v ) )
  end
end

local function assertRequiresCorrectness( data )
  assert( tableUtils.isNilOrTable( data.requires ), "The metadata table 'requires' property must be nil or a table" )

  if( not data.requires ) then return end

  for k, v in pairs( data.requires ) do
    assertRequireVersionCorrectness( v )

    local m = require( k )
    assert( m ~= nil, string.format( "The module %s could not be loaded while checking dependencies requirements for %s", k, data.modName ) )
    assert( versionUtils.areRequiredAndProvidedVersionsCompatible( v, m.version ),
            string.format( "The module %s current version is %s. It is not compatible with the required version %s",
                           k, versionUtils.toString( m.version ), versionUtils.toString( v ) ) )
  end
end

local function assertDataCorrectness( data )
  assert( data ~= nil, "The metadata controller must be constructed with a metadata table" )
  assert( not stringUtils.isNilOrNotStringOrEmpty( data.modPath ), "The metadata table 'modPath' property must be a non empty string" )
  assertRequiresCorrectness( data )
  assertModulesCorrectness( data )
  assertEventsCorrectness( data )
end

-- kinda hacky but it works pretty well, allow one to require that thing multiple time without having the same instance
-- no need to suffer with lfs. Time will tell us if it is flawed or not...
local function unrequire()
  local name = "MAB0.metadataController"

  -- here is the 'sloppy' part, dunno if it could cause some sort of corruption...
  -- as a plain LUA module I guess not, but...
  package.loaded[ name ] = nil
  _G[ name ] = nil
end

local function registerMetadataControllerForModName( controller )
  _G[ "MAB0" ] = _G[ "MAB0" ] or {}
  _G[ "MAB0" ][ "metadataControllers" ] = _G[ "MAB0" ][ "metadataControllers" ] or {}
  _G[ "MAB0" ][ "metadataControllers" ][ this.data.modName ] = controller
end

return {
  getMetadataControllerByModName = function( modName )
    unrequire()

    return _G[ "MAB0" ][ "metadataControllers" ][ modName ]
  end,

  new = function( data )
    assertDataCorrectness( data )

    this.data = data

    local interface = {
      get = get,
      getEventName = getEventName,
      getModulePath = getModulePath,
      getModulePersistentDataPropertyString = getModulePersistentDataPropertyString,
      getModuleFilePath = getModuleFilePath
    }

    registerMetadataControllerForModName( interface )

    unrequire()

    return interface
  end
}