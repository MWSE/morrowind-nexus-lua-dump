local recipes = {
    {
        id = "vozhb_cart_01_mc",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_c",
		name = "Carpentry",
		description = "Repair the cart skillfuly using quality materials and tools.",
		toolRequirements = {
            {
                tool = "carpentrytools",
            },
        },
		materials = {
            { 
                material = "wood",
                count = 20,
            },
			{ 
                material = "resin",
                count = 6,
            },
        },
		soundType = "Wood",
		--knownByDefault = false,
		skillRequirements = {
			{ skill = "mc_Woodworking", requirement = 50 }
		},
		category = "Carpentry",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_mc_alter",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_c",
		name = "Magical Carpentry",
		description = "Repair the cart skillfuly using quality materials and alteration.",
		materials = {
            { 
                material = "wood",
                count = 10,
            },
			{ 
                material = "resin",
                count = 4,
            },
        },
		soundType = "Wood",
		--knownByDefault = false,
		skillRequirements = {
			{ skill = "mc_Woodworking", requirement = 25 },
			{ skill = "alteration", requirement = 25 }
		},
		category = "Carpentry",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_mc_myst",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_c",
		name = "Telekinetic Carpentry",
		description = "Repair the cart skillfuly manipulating quality materials and tools via mysticism.",
		toolRequirements = {
            {
                tool = "carpentrytools",
            },
        },
		materials = {
            { 
                material = "wood",
                count = 20,
            },
			{ 
                material = "resin",
                count = 6,
            },
        },
		soundType = "Wood",
		--knownByDefault = false,
		skillRequirements = {
			{ skill = "mc_Woodworking", requirement = 25 },
			{ skill = "mysticism", requirement = 25 }
		},
		category = "Carpentry",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_mc_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Carpentry and Enchantment",
		description = "Repair the cart skillfuly using quality materials and tools with clever enchantments to increase utility.",
		toolRequirements = {
            {
                tool = "carpentrytools",
            },
        },
		materials = {
            { 
                material = "wood",
                count = 20,
            },
			{ 
                material = "resin",
                count = 6,
            },
			{ 
                material = "Misc_SoulGem_Grand",
                count = 1,
            },
        },
		soundType = "Wood",
		--knownByDefault = false,
		skillRequirements = {
			{ skill = "mc_Woodworking", requirement = 50 },
			{ skill = "enchant", requirement = 50 }
		},
		category = "Carpentry",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_mc_alter_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Magical Carpentry and Enchantment",
		description = "Repair the cart skillfuly using quality materials and alteration with clever enchantments to increase utility.",
		materials = {
            { 
                material = "wood",
                count = 10,
            },
			{ 
                material = "resin",
                count = 4,
            },
			{ 
                material = "Misc_SoulGem_Grand",
                count = 1,
            },
        },
		soundType = "Wood",
		--knownByDefault = false,
		skillRequirements = {
			{ skill = "mc_Woodworking", requirement = 25 },
			{ skill = "alteration", requirement = 25 },
			{ skill = "enchant", requirement = 50 }
		},
		category = "Carpentry",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_mc_myst_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Telekinetic Carpentry and Enchantment",
		description = "Repair the cart skillfuly manipulating quality materials and tools via mysticism with clever enchantments to increase utility.",
		toolRequirements = {
            {
                tool = "carpentrytools",
            },
        },
		materials = {
            { 
                material = "wood",
                count = 20,
            },
			{ 
                material = "resin",
                count = 6,
            },
			{ 
                material = "Misc_SoulGem_Grand",
                count = 1,
            },
        },
		soundType = "Wood",
		--knownByDefault = false,
		skillRequirements = {
			{ skill = "mc_Woodworking", requirement = 25 },
			{ skill = "mysticism", requirement = 25 },
			{ skill = "enchant", requirement = 50 }
		},
		category = "Carpentry",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
}

local function registerRecipes(e)
    ---@type CraftingFramework.MenuActivator
    if e.menuActivator then
        e.menuActivator:registerRecipes(recipes)
    end
end

--local mc = tes3.isModActive("Morrowind Crafting 3.1a.ESP")
--if mc then
	event.register("HandcartCartTriggered:Registered", registerRecipes)
--end