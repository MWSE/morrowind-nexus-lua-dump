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
        name = "Синий фокусирующий кристалл",
        ids = {
            "rem_m_focuscr_blue"
        }
    },
    {
        id = "remcraft_crystal_green",
        name = "Зеленый фокусирующий кристалл",
        ids = {
            "rem_m_focuscr_green"
        }
    },
    {
        id = "remcraft_crystal_purple",
        name = "Фиолетовый фокусирующий кристалл",
        ids = {
            "rem_m_focuscr_purple"
        }
    },
    {
        id = "remcraft_crystal_red",
        name = "Красный фокусирующий кристалл",
        ids = {
            "rem_m_focuscr_red"
        }
    },
    {
        id = "remcraft_crystal_yellow",
        name = "Желтый фокусирующий кристалл",
        ids = {
            "rem_m_focuscr_yellow"
        }
    },
    {
        id = "remcraft_beambl_hilt",
        name = "Древний конденсатор",
        ids = {
            "rem_w_beambl_hilt"
        }
    },
    {
        id = "remcraft_beambl_blue",
        name = "Синий лучевой меч",
        ids = {
            "rem_w_beambl_blue"
        }
    },
    {
        id = "remcraft_beambl_green",
        name = "Зеленый лучевой меч",
        ids = {
            "rem_w_beambl_green"
        }
    },
    {
        id = "remcraft_beambl_purple",
        name = "Фиолетовый лучевой меч",
        ids = {
            "rem_w_beambl_purple"
        }
    },
    {
        id = "remcraft_beambl_red",
        name = "Красный лучевой меч",
        ids = {
            "rem_w_beambl_Red"
        }
    },
    {
        id = "remcraft_beambl_yellow",
        name = "Желтый лучевой меч",
        ids = {
            "rem_w_beambl_yellow"
        }
    },
    {
        id = "remcraft_pearl_ultima",
        name = "Ультима, Величайший Жемчуг",
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
		category = "Лучевые мечи",
        name = "Синий лучевой меч"
    },
    {
        id = "rem_beamblcraft_w_green",
        craftable = { id = "rem_w_beambl_green"},
		materials = {
            { material = "remcraft_crystal_green", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Лучевые мечи",
        name = "Зеленый лучевой меч"
    },
    {
        id = "rem_beamblcraft_w_purple",
        craftable = { id = "rem_w_beambl_purple"},
		materials = {
            { material = "remcraft_crystal_purple", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Лучевые мечи",
        name = "Фиолетовый лучевой меч"
    },
    {
        id = "rem_beamblcraft_w_red",
        craftable = { id = "rem_w_beambl_red"},
		materials = {
            { material = "remcraft_crystal_red", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Лучевые мечи",
        name = "Красный лучевой меч"
    },
    {
        id = "rem_beamblcraft_w_yellow",
        craftable = { id = "rem_w_beambl_yellow"},
		materials = {
            { material = "remcraft_crystal_yellow", count = 1 },
            { material = "remcraft_beambl_hilt", count = 1 },
        },
		category = "Лучевые мечи",
        name = "Желтый лучевой меч"
    },
}
mwse.log("[Rem's Beam Blades] Registering Recipes")
--Register your MenuActivator
CraftingFramework.MenuActivator:new{
    id = "rem_f_dwrv_workbench",
    type = "activate",
	name = "Двемерский верстак",
    recipes = recipes
}
mwse.log("[Rem's Beam Blades] Registered Recipes")