local stationID = "ek_rm_table_alch" 
local apparati = { "ek_mortar", "ek_calc", "ek_retort", "ek_alem" }

local function activate(e)
    if e.activator == tes3.player
        and e.target.object.id == stationID
    then
        for _, apparatus in ipairs(apparati) do
            tes3.addItem({ reference = tes3.player, item = apparatus, count = 1, playSound = false, updateGUI = false })
            tes3ui.forcePlayerInventoryUpdate()
        end

        tes3.showAlchemyMenu()

        timer.delayOneFrame(function()
            for _, apparatus in ipairs(apparati) do
                tes3.removeItem({ reference = tes3.player, item = apparatus, count = 1, playSound = false, updateGUI = false })
            end
            tes3ui.forcePlayerInventoryUpdate()
        end)
    end
end
event.register("activate", activate)