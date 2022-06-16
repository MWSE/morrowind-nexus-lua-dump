local debug = require 'robocroque.factionalbounties.debug'

local this = {}

function this.getBounty (factionName)
    return tes3.player.data.factionBounties[factionName]
end

function this.setBounty (factionName, bounty)
    tes3.player.data.factionBounties[factionName] = bounty
end

function this.addBounty (factionName, bounty)
    local currentBounty = this.getBounty(factionName)

    if (currentBounty == nil) then
        currentBounty = 0
    end

    this.setBounty(factionName, currentBounty + bounty)
end

return this