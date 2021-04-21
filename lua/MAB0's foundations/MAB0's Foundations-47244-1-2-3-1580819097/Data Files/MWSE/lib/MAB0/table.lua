local stringExtensions = require( "MAB0.string" )

local this = {}

function this.isNilOrTable( value )
  return ( value == nil ) or ( type( value ) == "table" )
end

function this.unique( array )
  assert( type( array ) == "table", "'unique' must be provided with a table type argument" )

  local hash, result = {}, {}

  for k, v in pairs( array ) do
    assert( type( k ) == "number", "'unique' only works with number indexed tables" )

    if( not hash[ v ] ) then
      result[ #result + 1 ] = v
      hash[ v ] = true
    end
  end

  return result
end

function this.firstPair( table )
  local next = pairs( table )

  return next( table )
end

function this.findIf( table, predicate )
  for k, v in pairs( table ) do
    if( predicate( k, v ) ) then return k, v end
  end
end

function this.reduce( table, reducer, initialValue )
  local result = initialValue

  for k, v in pairs( table ) do
    result = reducer( k, v, result )
  end

  return result
end

function this.countIf( table, predicate )
  return this.reduce( table, function( k, v, r ) return predicate( k, v ) and r + 1 or r end, 0 )
end

function this.count( table )
  return this.reduce( table, function( _, _, r ) return  r + 1 end, 0 )
end

function this.forEach( table, action )
  for k, v in pairs( table )do
    action( k, v )
  end
end

local function normalizePropertyString( string )
  if( stringExtensions.isNilOrNotStringOrEmpty( string ) ) then
    return string
  end

  local result = string

  while( string.sub( result, 1, 1 ) == "." ) do
    result = string.sub( result, 2 )
  end

  while( string.sub( result, -1 ) == '.' ) do
    result = string.sub( result, 1, -2 )
  end

  local index = string.find( result, ".", 1, true )
  if( index ~= nil )then
    while( string.sub( result, index + 1, index + 1 ) == "." ) do
      result = string.sub( result, 1, index - 1 ) .. string.sub( result, index + 1, string.len( result ) )
      index = string.find( result, ".", 1, true )
    end
  end

  return result
end

-- Explodes a normalized property string inside a table
-- A property string like "prop1.prop2.prop3" would give a table 't' structured as
-- t = { prop1, prop2, prop3 }
function this.explodePropertyStringInTable( string )
  local function recursiveTableInsert( rightString, result )
    local index = string.find( rightString, ".", 2, true )

    if( index == nil ) then
      table.insert( result, rightString )
      return
    end

    local left = string.sub( rightString, 1, index - 1 )
    table.insert( result, left )

    local right = string.sub( rightString, index + 1, string.len( rightString) )

    -- tail recursion
    recursiveTableInsert( right, result )
  end

  local normalizedString = normalizePropertyString( string )

  local result = nil

  if( ( type( normalizedString ) == "string" ) and ( normalizedString.len( normalizedString ) > 0 ) )then
    result = {}

    recursiveTableInsert( normalizedString, result )
  end

  return result
end

-- Takes a property string and turn it into a nested table structure then returns a reference to the outermost and innermost nested tables
-- A property string like "prop1.prop2.prop3" would give a table 't' structured as
-- t = { -- t is the outermost table returned to the user in that example
--   prop1 = {
--     prop2 = {
--       prop3 = {} -- this is the innermost table that is retturned to the user in that example
--     }
--   }
-- }
function this.createNestedTablesFromPropertyString( string )
  local normalizedString = normalizePropertyString( string )

  if( ( normalizedString == nil ) or ( normalizedString == "" ) ) then return nil end

  local outermostTable = {}

  local function nestTableRecursively( table, subString )
    local index = string.find( subString, '.', 1, true )

    if( index == nil ) then table[ subString ] = {} return table[ subString ] end

    local left = string.sub( subString, 1, index - 1 )

    table[ left ] = {}

    return nestTableRecursively( table[ left ], string.sub( subString, index + 1 ) )
  end

  return outermostTable, nestTableRecursively( outermostTable, normalizedString )
end

return this