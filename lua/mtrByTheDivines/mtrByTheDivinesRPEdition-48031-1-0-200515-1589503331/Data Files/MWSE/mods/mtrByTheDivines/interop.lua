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

return this
