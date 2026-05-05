local world = require("openmw.world")

local function selectedDagothUr(player)
    local item = world.createObject("MTR_ByTheDivines_DagothUr", 1)
    ---@diagnostic disable-next-line: discard-returns
    item:moveInto(player)
end

return {
    eventHandlers = {
        CharacterTraits_selectedDagotUr = selectedDagothUr,
    }
}
