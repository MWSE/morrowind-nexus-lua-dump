local backgrounds = require("mer.characterBackgrounds.backgroundsList")

local this = {}
function this.addBackground(params)
    assert(
        params.id, 
        "Background must have an id")
    assert(
        params.name, 
        string.format("Background '%s' must have a name.", params.id)
    )
    assert(
        params.description,
        string.format("Background '%s' must have a description.", params.id)
    )
    assert( 
        (params.doOnce or params.callback), 
        string.format("Background '%s' must have a doOnce or callback function (or both).", params.id )
    )
    backgrounds[params.id] = params
    mwse.log("Background %s added successfully", params.name)
end

return this
