local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    -- Armor:
    { id = "mdsm_spacemagehelm", description = "The surface of this helm reflects a distorted image of the Aurbis.", itemType = "armor" },

    -- Clothing:
    { id = "mdsm_spacemageboots", description = "Black leather boots with gold trim and accents.", itemType = "clothing" },
    { id = "mdsm_spacemageglovel", description = "A black leather glove with gold trim.", itemType = "clothing" },
    { id = "mdsm_spacemageglover", description = "A black leather glove with gold trim.", itemType = "clothing" },
    { id = "mdsm_spacemagerobe", description = "The blue, crushed velvet material of this robe is decorated with gold ornamentation.", itemType = "clothing" },

    --Quest:
    { id = "mdsm_bk_notetoyagrum", description = "A note addressed to Yagrum Bagarn charging him with a crime.", itemType = "quest" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)