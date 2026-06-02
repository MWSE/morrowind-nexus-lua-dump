--Get the Crafting Framework API and check that it exists
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

--Create List of Recipes
local recipes = {
    {
        id = "ABstaffCraft_w_ResinStaff",
        craftable = { id = "AB_w_ResinStaff"},
		materials = {
            { material = "Misc_SoulGem_Grand", count = 2 },
            { material = "AB_IngFlor_TelvanniResin", count = 10 },
        },
		category = "Посохи"
    },
    {
        id = "ABstaffEnchant_w_ResinStaffDevouring",
        craftable = { id = "AB_w_ResinStaffDevouring"},
        materials = {
            { material = "AB_w_ResinStaff", count = 1 },
        },
        category = "Зачаровать"
    },
    {
        id = "ABstaffEnchant_w_ResinStaffFire",
        craftable = { id = "AB_w_ResinStaffFire"},
		materials = {
            { material = "AB_w_ResinStaff", count = 1 },
        },
		category = "Зачаровать"
    },
    {
        id = "ABstaffEnchant_w_ResinStaffTerror",
        craftable = { id = "AB_w_ResinStaffTerror"},
		materials = {
            { material = "AB_w_ResinStaff", count = 1 },
        },
		category = "Зачаровать"
    },
    {
        id = "ABstaffRecharge_w_ResinStaffDevouring",
        craftable = { id = "AB_w_ResinStaffDevouring"},
		materials = {
            { material = "AB_w_ResinStaffDevouring", count = 1 },
        },
		category = "Перезарядить"
    },
    {
        id = "ABstaffRecharge_w_ResinStaffFire",
        craftable = { id = "AB_w_ResinStaffFire"},
		materials = {
            { material = "AB_w_ResinStaffFire", count = 1 },
        },
		category = "Перезарядить"
    },
    {
        id = "ABstaffRecharge_w_ResinStaffTerror",
        craftable = { id = "AB_w_ResinStaffTerror"},
		materials = {
            { material = "AB_w_ResinStaffTerror", count = 1 },
        },
		category = "Перезарядить"
    },
}

--Register your MenuActivator
CraftingFramework.MenuActivator:new{
    id = "AB_Furn_StaffTable_a",
    type = "activate",
	name = "Зачарователь посохов",
    recipes = recipes
}