local cultures = require("mtrCultures.culturesList")

local this = {}
function this.addCulture(params)
    assert(
        params.id,
        "Culture must have an id")
    assert(
        params.name,
        string.format("Culture '%s' must have a name.", params.id)
    )
    assert(
        params.description,
        string.format("Culture '%s' must have a description.", params.id)
    )
    assert(
        (params.doOnce or params.callback),
        string.format("Culture '%s' must have a doOnce or callback function (or both).", params.id )
    )
    cultures[params.id] = params
    mwse.log("Culture %s added successfully", params.name)
end

function this.getCurrentCulture()
    local cultureId = tes3.player
        and tes3.player.data.mtrCultures
        and tes3.player.data.mtrCultures.currentCulture
    if cultureId then
        local culture = cultures[cultureId]

        if culture then
            culture.getName = function(self)
                return self.name
            end

            culture.getDescription = function(self)
                if type(self.description) == "function" then
                    return self.description()
                else
                    return self.description
                end
            end

            return culture
        end

    end
end


return this
