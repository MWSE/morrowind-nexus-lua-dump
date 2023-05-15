local recipes = {
	{
        id = "vozhb_cart_01_ashfall",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_1000_c",
		name = "Advanced Bushcrafting",
		description = "Repair the cart using bushcrafted parts.",
		toolRequirements = {
			{
				tool = "knife",
				conditionPerUse = 150,
			},
			{
				tool = "hammer",
				conditionPerUse = 25,
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
			{ skill = "Bushcrafting", requirement = 50 }
		},
		category = "Bushcrafting",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_ashfall_alter",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_1000",
		name = "Magical Bushcrafting",
		description = "Repair the cart using magically bushcrafted parts.",
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
			{ skill = "Bushcrafting", requirement = 25 },
			{ skill = "alteration", requirement = 25 },
		},
		category = "Bushcrafting",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_ashfall_myst",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_c",
		name = "Telekinetic Bushcrafting",
		description = "Repair the cart magically manipulating bushcrafted parts.",
		toolRequirements = {
            {
                tool = "knife",
                conditionPerUse = 50
            },
			{
                tool = "hammer",
                conditionPerUse = 10
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
			{ skill = "Bushcrafting", requirement = 25 },
			{ skill = "mysticism", requirement = 25 },
		},
		category = "Bushcrafting",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_ashfall_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Bushcrafting and Enchantment",
		description = "Repair the cart using bushcrafted parts and clever enchantments to increase utility.",
		toolRequirements = {
            {
                tool = "knife",
                conditionPerUse = 150
            },
			{
                tool = "hammer",
                conditionPerUse = 25
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
			{ skill = "Bushcrafting", requirement = 50 },
			{ skill = "enchant", requirement = 50 },
		},
		category = "Bushcrafting",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_ashfall_alter_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Magical Bushcrafting and Enchantment",
		description = "Repair the cart using magically bushcrafted parts and clever enchantments to increase utility.",
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
			{ skill = "Bushcrafting", requirement = 25 },
			{ skill = "alteration", requirement = 25 },
			{ skill = "enchant", requirement = 50 },
		},
		category = "Bushcrafting",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_ashfall_myst_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Telekinetic Bushcrafting and Enchantment",
		description = "Repair the cart magically manipulating bushcrafted parts and apply clever enchantments to increase utility.",
		toolRequirements = {
            {
                tool = "knife",
                conditionPerUse = 50
            },
			{
                tool = "hammer",
                conditionPerUse = 10
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
			{ skill = "Bushcrafting", requirement = 25 },
			{ skill = "mysticism", requirement = 25 },
			{ skill = "enchant", requirement = 50 },
		},
		category = "Bushcrafting",
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

local ash = tes3.isModActive("ashfall.esp")
if ash then 
	event.register("HandcartCartTriggered:Registered", registerRecipes)
end