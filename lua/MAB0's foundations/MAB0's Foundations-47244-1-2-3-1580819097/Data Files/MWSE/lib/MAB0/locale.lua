-- exposes localized string access utilities. The way to use it is simple, create a new instance :
-- local locale = require( "MAB0.locale" ).new( localizedTable )
-- where localizedTable is a table having a string property corresponding to a language string returned by tes3.getLanguage for instance
-- { eng = { ... } }
-- Then, to access to a localized string corresponding to your current locale :
-- locale.getLocalizedString( propertyString )
-- where propertyString is a path to a string property contained in the localizedTable for instance :
-- mcm.fancyMcmVars.domains.earthString maps to
-- { fra = { fancyMcmVars = { domains = { earthString = "Terre" } } } }
-- if your current locale is "fra" aka French

local this = {
  table
}

local function getDefaultLocale()
  if( this.table ) then
    return this.table[ "eng" ]
  end

  return nil
end

local function getLocaleOrDefault( language )
  if( not this.table ) then return nil end

  if( not this.table[ language ] ) then
    return getDefaultLocale()
  end

  return this.table[ language ]
end

local function getCurrentLocale()
  return getLocaleOrDefault( tes3.getLanguage() )
end

local function getLocalizedString( key )
  local utils = require( "MAB0.utils" )

  local propertyPath = utils.table.explodePropertyStringInTable( key )
  local undefinedString = "--- undefined string ---"

  if( propertyPath == nil ) then return undefinedString end

  local value = getCurrentLocale()

  if( value == nil ) then
    mwse.log( "bad localized table provided" )
      return undefinedString
  end

  for _, property in ipairs( propertyPath ) do
    value = value[ property ]
    if( value == nil ) then
      mwse.log( "bad property path specified" )
      return undefinedString
    end
  end

  if( not value or type( value ) ~= "string" ) then
    mwse.log( "bad property path specified" )
    return undefinedString
  end

  return value
end

-- kinda hacky but it works pretty well, allow one to require that thing multiple time without having the same instance
-- no need to suffer with lfs. Time will tell us if it is flawed or not...
local function unrequire()
  local name = "MAB0.locale"

  -- here is the 'sloppy' part, dunna if it could cause some sort of corruption...
  -- as a plain LUA module I guess not, but...
  package.loaded[ name ] = nil
  _G[ name ] = nil
end

return {
  new = function( localizedTable )
    this.table = localizedTable

    unrequire()

    return {
      getLocalizedString = getLocalizedString
    }
  end
}