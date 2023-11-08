-- get the current mtrByTheDivines data
local function getData()
    local data = tes3.player.data.mtrByTheDivines or {}
    return data
end

-- start the mod
local function onInit(e)
    local interop = require("mtrByTheDivines.interop")

--GREAT SAGE
local greatSage = {
    id = "greatSage",
    name = "The Great Sage",
    description = (
        "The Great Sage - Gyron Vardengroet is an immortal Breton wizard of legend that was born in the early years of the Second Era, and was prophesied by the Divines as a champion that would be sent down to guide others and bring wisdom. \n\nThe power of Third Eye Open is bestowed upon followers of the Great Sage, providing a significant enhancement to magical apptitude for a limited time."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "vss_BTD_greatSage"
        }
    end,
}
interop.addBelief(greatSage)

end

event.register("initialized", onInit)