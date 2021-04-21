local this = {}

function this.pairInteger( a, b )
  if( ( type( a ) ~= "number" ) or ( type( b ) ~= "number" ) ) then return nil end

  a, b = math.floor( a ), math.floor( b )

  return ( ( a + b ) * ( a + b + 1) ) / 2 + b
end

return this