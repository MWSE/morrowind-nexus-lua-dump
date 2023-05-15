--Create List of Recipes
local pearlRecipes = {
    {
        id = "rem_adbeamblcraft_w_blue",
        craftableId = "rem_w_adbeambl_blue",
        materials = {
            { material = "remcraft_beambl_blue", count = 1 },
            { material = "remcraft_pearl_ultima", count = 1 },
        },
        category = "Beam Blades",
        name = "Advanced Blue Beam Blade"
    },
    {
        id = "rem_adbeamblcraft_w_green",
        craftableId = "rem_w_adbeambl_green",
        materials = {
            { material = "remcraft_beambl_green", count = 1 },
            { material = "remcraft_pearl_ultima", count = 1 },
        },
        category = "Beam Blades",
        name = "Advanced Green Beam Blade"
    },
    {
        id = "rem_adbeamblcraft_w_purple",
        craftableId = "rem_w_adbeambl_purple",
        materials = {
            { material = "remcraft_beambl_purple", count = 1 },
            { material = "remcraft_pearl_ultima", count = 1 },
        },
        category = "Beam Blades",
        name = "Advanced Purple Beam Blade"
    },
    {
        id = "rem_adbeamblcraft_w_red",
        craftableId = "rem_w_adbeambl_red",
        materials = {
            { material = "remcraft_beambl_red", count = 1 },
            { material = "remcraft_pearl_ultima", count = 1 },
        },
        category = "Beam Blades",
        name = "Advanced Red Beam Blade"
    },
    {
        id = "rem_adbeamblcraft_w_yellow",
        craftableId = "rem_w_adbeambl_yellow",
        materials = {
            { material = "remcraft_beambl_yellow", count = 1 },
            { material = "remcraft_pearl_ultima", count = 1 },
        },
        category = "Beam Blades",
        name = "Advanced Yellow Beam Blade"
    },
}

local function registerRecipes(e)
    ---@type CraftingFramework.MenuActivator
    if e.menuActivator then
      e.menuActivator:registerRecipes(pearlRecipes)
    end
end
event.register("rem_f_dwrv_workbench:Registered", registerRecipes)