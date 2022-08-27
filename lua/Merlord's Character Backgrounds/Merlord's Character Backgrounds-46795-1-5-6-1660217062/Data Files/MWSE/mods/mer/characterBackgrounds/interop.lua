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

function this.getCurrentBackground()
    local backgroundId = tes3.player
        and tes3.player.data.merBackgrounds
        and tes3.player.data.merBackgrounds.currentBackground
    if backgroundId then
        local background = backgrounds[backgroundId]

        if background then
            background.getName = function(self)
                return self.name
            end

            background.getDescription = function(self)
                if type(self.description) == "function" then
                    return self.description()
                else
                    return self.description
                end
            end

            return background
        end

    end
end


return this
