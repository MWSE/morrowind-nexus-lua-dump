local this = {}

function this.isNilOrNotStringOrEmpty( value )
  return ( value == nil ) or ( type( value ) ~= "string" ) or ( ( type( value ) == "string" ) and ( #value == 0 ) )
end

function this.isEmpty( value )
  return ( type( value ) == "string" ) and ( #value == 0 )
end

function this.isNilOrNotEmpty( value )
  return ( value == nil ) or ( ( type( value ) == "string" ) and ( #value > 0 ) )
end

return this