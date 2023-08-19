local function cellChanged(e)
    local cell = e.cell
    local cellName = cell.name:lower()


    local cheatIds = {
        aa_light_velothi_brazier_177_ch = 1,
        mundis_man_button = 2,
        mdoor_cheat = 3,
        aa_cheatdj = 4,
        mundis_power_deposit2x = 5,
        mundis_power_est = 6,
        mundis_switch_button = 7,
        mundis_cheatshopsbutton = 8,
        aaz_crate_clothes = 9,
        mundis_cheatenable = 10,
        zhac_mundis_buttonpanel = 11,
        zhac_button_mundis_curr = 12,
        zhac_button_mundis_next = 13,
        zhac_button_mundis_prev = 14,
    }
    if string.sub(cellName, 1, 6) == "mundis" then
        for ref in cell:iterateReferences() do
            local id = ref.baseObject.id
            if cheatIds[id] then
                if not tes3.player.data.Mundis then
                    tes3.player.data.Mundis = {}
                    tes3.player.data.Mundis.cheats= false
                end
                if tes3.player.data.Mundis.cheats ~= true then
                    ref:disable()
                else
                    ref:enable()
                end
            end
        end
    end
end

event.register(tes3.event.cellChanged, cellChanged)
