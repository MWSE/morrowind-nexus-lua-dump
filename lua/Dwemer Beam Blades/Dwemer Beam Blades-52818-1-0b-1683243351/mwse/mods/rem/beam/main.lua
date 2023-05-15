mwse.log("Started Rem's Beam Blades")

--Get the Crafting Framework API and check that it exists
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then 
    mwse.log("[Rem's Beam Blades] ERROR: Could not find Crafting Framework. Cannot continue.")
    return 
end

local materials = {
    {
        id = "remcraft_crystal_blue",
        name = "Blue Focus Crystal",
        ids = {
            "rem_m_focuscr_blue"
        }
    },
    {
        id = "remcraft_crystal_green",
        name = "Green Focus Crystal",
        ids = {
            "rem_m_focuscr_green"
        }
    },
    {
        id = "remcraft_crystal_purple",
        name = "Purple Focus Crystal",
        ids = {
            "rem_m_focuscr_purple"
        }
    },
    {
        id = "remcraft_crystal_red",
        name = "Red Focus Crystal",
        ids = {
            "rem_m_focuscr_red"
        }
    },
    {
        id = "remcraft_crystal_yellow",
        name = "Yellow Focus Crystal",
        ids = {
            "rem_m_focuscr_yellow"
        }
    },
    {
        id = "remcraft_beambl_hilt",
        name = "Derelict Capacitor",
        ids = {
            "rem_w_beambl_hilt"
        }
    },
    {
        id = "remcraft_beambl_blue",
        name = "Blue Beam Blade",
        ids = {
            "rem_w_beambl_blue"
        }
    },
    {
        id = "remcraft_beambl_green",
        name = "Green Beam Blade",
        ids = {
            "rem_w_beambl_green"
        }
    },
    {
        id = "remcraft_beambl_purple",
        name = "Purple Beam Blade",
        ids = {
            "rem_w_beambl_purple"
        }
    },
    {
        id = "remcraft_beambl_red",
        name = "Red Beam Blade",
        ids = {
            "rem_w_beambl_Red"
        }
    },
    {
        id = "remcraft_beambl_yellow",
        name = "Yellow Beam Blade",
        ids = {
            "rem_w_beambl_yellow"
        }
    },
    {
        id = "remcraft_pearl_ultima",
        name = "Ultima Pearl",
        ids = {
            "pearl_ultima"
        }
    },

}
mwse.log("[Rem's Beam Blades] Registering Materials")
CraftingFramework.Material:registerMaterials(materials)
mwse.log("[Rem's Beam Blades] Registered Materials")
--Create List of Recipes
local recipes = {
    {
        id = "rem_beamblcraft_w_blue",
        craftable = { id = "rem_w_beambl_blue"},
		materials = {
            { material = "remcraft_crystal_blue", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Beam Blades",
        name = "Blue Beam Blade"
    },
    {
        id = "rem_beamblcraft_w_green",
        craftable = { id = "rem_w_beambl_green"},
		materials = {
            { material = "remcraft_crystal_green", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Beam Blades",
        name = "Green Beam Blade"
    },
    {
        id = "rem_beamblcraft_w_purple",
        craftable = { id = "rem_w_beambl_purple"},
		materials = {
            { material = "remcraft_crystal_purple", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Beam Blades",
        name = "Purple Beam Blade"
    },
    {
        id = "rem_beamblcraft_w_red",
        craftable = { id = "rem_w_beambl_red"},
		materials = {
            { material = "remcraft_crystal_red", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Beam Blades",
        name = "Red Beam Blade"
    },
    {
        id = "rem_beamblcraft_w_yellow",
        craftable = { id = "rem_w_beambl_yellow"},
		materials = {
            { material = "remcraft_crystal_yellow", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Beam Blades",
        name = "Yellow Beam Blade"
    },
}
mwse.log("[Rem's Beam Blades] Registering Recipes")
--Register your MenuActivator
CraftingFramework.MenuActivator:new{
    id = "rem_f_dwrv_workbench",
    type = "activate",
	name = "Dwemer Workbench",
    recipes = recipes
}
mwse.log("[Rem's Beam Blades] Registered Recipes")