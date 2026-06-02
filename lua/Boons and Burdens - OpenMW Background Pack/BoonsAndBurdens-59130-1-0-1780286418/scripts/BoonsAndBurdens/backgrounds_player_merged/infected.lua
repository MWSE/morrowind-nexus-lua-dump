---@omw-context player
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
-- local self = require("openmw.self")
local core = require("openmw.core")

local vampireWindow = require("scripts.BoonsAndBurdens.ui.infected")

local bgPicked = false

I.CharacterTraits.addTrait {
    id = "BaB_infected",
    type = "background",
    name = "Infected",
    description = (
        "Something bit you on the road here. You felt feverish the next morning and convinced yourself it was nothing. " ..
        "It wasn't nothing. You have three days before the disease runs its course - or you find a cure.\n" ..
        "\n" ..
        "> You start with a Porphyric Hemophilia disease"
    ),
    doOnce = function()
        bgPicked = true
    end,
}

return {
    eventHandlers = {
        CharacterTraits_allTraitsPicked = function()
            if bgPicked then
                vampireWindow.show()
                ---@diagnostic disable-next-line: missing-fields
                I.UI.setMode('Interface', { windows = {} })
                core.sendGlobalEvent('Pause', 'ui')
            end
        end,
    }
}
