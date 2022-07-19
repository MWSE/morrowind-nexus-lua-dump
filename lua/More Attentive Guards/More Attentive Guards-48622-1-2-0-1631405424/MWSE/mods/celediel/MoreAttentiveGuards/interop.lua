local this = {}

local guard
this.setGuardFollower = function(g)
    guard = g
end

this.getGuardFollower = function()
    return guard
end

return this
