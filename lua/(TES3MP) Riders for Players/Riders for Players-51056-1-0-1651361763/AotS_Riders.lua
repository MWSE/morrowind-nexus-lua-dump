-- Written by Vidi_Aquam
-- Use only on a 0.8 server running Riders by rotat: https://www.nexusmods.com/morrowind/mods/46868
-- Do what you want with this, but give credit

AotS_guars = {}
AotS_guars.config = {
    {name = "Guar", item = "rot_c_guar00_shirtC3", model = "mountedguar2"},
    {name = "Pack Guar 1", item = "rot_c_guar1B_shirtC3", model = "mountedguar1"},
    {name = "Pack Guar 2", item = "rot_c_guar1A_shirt0", model = "mountedguar1"},
    {name = "Redoran War Guar", item = "rot_c_guar2A_shirt0_redoranwar", model = "mountedguar2"},
    {name = "Guar with Drapery (Fine)", item = "rot_c_guar2B_shirt0_ordinator", model = "mountedguar2"},
    {name = "Guar with Drapery (Simple)", item = "rot_c_guar2C_shirt0_scout", model = "mountedguar2"}
}
AotS_guars.guiId = 45149

local function getFilePath(model)
    return "rot/anim/" .. model .. ".nif"
end

AotS_guars.OnGui = function(eventStatus,pid,idGui,data)
    if idGui == AotS_guars.guiId then
    local selection = tonumber(data)
        if selection == 0 then -- dismount
            for _, entry in ipairs(AotS_guars.config) do
                if inventoryHelper.containsItem(Players[pid].data.inventory, entry.item) then
                    inventoryHelper.removeClosestItem(Players[pid].data.inventory, entry.item, 1)
                    Players[pid]:LoadItemChanges({{refId = entry.item, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.REMOVE)
                end
            end
            Players[pid].data.character.modelOverride = nil
            tes3mp.SetModel(pid, "")
            tes3mp.SendBaseInfo(pid)
        else
            if selection ~= 18446744073709551615 and selection <= #AotS_guars.config then
                local guar = AotS_guars.config[selection]
                if inventoryHelper.containsItem(Players[pid].data.inventory, guar.item) == false then
                    inventoryHelper.addItem(Players[pid].data.inventory, guar.item, 1)
                    Players[pid]:LoadItemChanges({{refId = guar.item, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.ADD)
                end
                logicHandler.RunConsoleCommandOnPlayer(pid, "player->equip ".. guar.item, false)

                Players[pid].data.character.modelOverride = getFilePath(guar.model)
                Players[pid]:LoadCharacter()
            end
        end
    end
end

AotS_guars.ShowMenu = function(pid)
    local list = "* DISMOUNT *\n"
    local options = AotS_guars.config
    for i=1, #options do
        list = list .. options[i].name
        if not (i == #options) then
            list = list .. "\n"
        end
    end
    return tes3mp.ListBox(pid, AotS_guars.guiId, "Select a mount to ride.", list)
end

customCommandHooks.registerCommand("ride", function(pid, cmd) AotS_guars.ShowMenu(pid) end)
customEventHooks.registerHandler("OnGUIAction", AotS_guars.OnGui)