local this = {}

function this.xor( cond1, cond2 )
  return ( cond1 or cond2 ) and ( not ( cond2 and cond1 ) )
end

return this