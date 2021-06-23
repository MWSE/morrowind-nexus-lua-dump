local lineages = require("mtrLineage.lineagesList")

local this = {}
function this.addLineage(params)
    assert(
        params.id, 
        "Lineage must have an id")
    assert(
        params.name, 
        string.format("Lineage '%s' must have a name.", params.id)
    )
    assert(
        params.description,
        string.format("Lineage '%s' must have a description.", params.id)
    )
    assert( 
        (params.doOnce or params.callback), 
        string.format("Lineage '%s' must have a doOnce or callback function (or both).", params.id )
    )
    lineages[params.id] = params
    mwse.log("Lineage %s added successfully", params.name)
end

return this
