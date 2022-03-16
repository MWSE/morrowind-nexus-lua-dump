local this = {}

--[[
    Warning: We assume that the table enumRelativePositions is an enumeration.
]]--
this.enumRelativePositions = {
    below = 1,
    above  = 2
}

this.availableUISetups = {
    -- {showGameTime = true, showRealTime = true},
    {showGameTime = true, showRealTime = false},
    {showGameTime = false, showRealTime = true}
}
this.numAvailableUISetups = table.getn(this.availableUISetups)

return this