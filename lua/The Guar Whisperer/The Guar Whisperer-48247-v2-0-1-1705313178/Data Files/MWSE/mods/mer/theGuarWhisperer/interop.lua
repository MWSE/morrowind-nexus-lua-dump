local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local function eat(e)
    local guar = GuarCompanion.get(e.reference)
    if guar then
        guar.needs:modHunger(-e.amount)
    end
end

event.register("Ashfall:Eat", eat)