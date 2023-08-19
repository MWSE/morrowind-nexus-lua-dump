local function updateCheatObjects()
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
    local cellName = tes3.player.cell.name:lower()
    local cell = tes3.player.cell
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
local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("MUNDIS")
    local page = template:createPage()
    local category = page:createCategory("Settings")
    category:createButton({
        buttonText = "Toggle Cheats",
        description = "",
        callback = function(self)
            if not tes3.player.data.Mundis then
                tes3.player.data.Mundis = {}
                tes3.player.data.Mundis.cheats= true
                tes3.messageBox("MUNDIS Cheats Enabled!")
                updateCheatObjects()
            else
                if tes3.player.data.Mundis.cheats ~= true then
                    tes3.player.data.Mundis.cheats= true
                    tes3.messageBox("MUNDIS Cheats Enabled!")
                    updateCheatObjects()
                else
                    tes3.player.data.Mundis.cheats= false
                    tes3.messageBox("MUNDIS Cheats Disabled!")
                    updateCheatObjects()
                end
            end
            
        end
    })
    category:createButton({
        buttonText = "Toggle Legacy Summon",
        description = "If Legacy Summon is enabled, the summon spell will attempt to teleport to a predetermined location, if it can't find one, it will use the position in front of you.",
        callback = function(self)
            if not tes3.player.data.Mundis then
                tes3.player.data.Mundis = {}
                tes3.player.data.Mundis.legacySummon= true
                tes3.messageBox("Legacy Summon Enabled!")
            else
                if tes3.player.data.Mundis.legacySummon ~= true then
                    tes3.player.data.Mundis.legacySummon= true
                    tes3.messageBox("Legacy Summon Enabled!")
                else
                    tes3.player.data.Mundis.legacySummon= false
                    tes3.messageBox("Legacy Summon Disabled!")
                end
            end
            
        end
    })
    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)