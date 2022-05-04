local beliefs = require("mtrByTheDivines.beliefsList")

local this = {}
function this.addBelief(params)
    assert(
        params.id,
        "Belief must have an id")
    assert(
        params.name,
        string.format("Belief '%s' must have a name.", params.id)
    )
    assert(
        params.description,
        string.format("Belief '%s' must have a description.", params.id)
    )
    assert(
        (params.doOnce or params.callback),
        string.format("Belief '%s' must have a doOnce or callback function (or both).", params.id )
    )
    beliefs[params.id] = params
    mwse.log("Belief %s added successfully", params.name)
end

function this.getCurrentBelief()
    local beliefId = tes3.player
        and tes3.player.data.mtrBeliefs
        and tes3.player.data.mtrBeliefs.currentBelief
    if beliefId then
        local belief = beliefs[beliefId]

        if belief then
            belief.getName = function(self)
                return self.name
            end

            belief.getDescription = function(self)
                if type(self.description) == "function" then
                    return self.description()
                else
                    return self.description
                end
            end

            return belief
        end

    end
end


return this
