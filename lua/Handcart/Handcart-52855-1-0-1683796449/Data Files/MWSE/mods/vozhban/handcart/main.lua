--Get the Crafting Framework API and check that it exists
local crafting = include("CraftingFramework.interop")
if not crafting then return end
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

--Register your materials
local materials = {
    {
        id = "wood",
        name = "Wood",
        ids = {
            "mc_log_oak",
            "mc_log_hickory",
            "mc_log_pine",
            "mc_log_swirlwood",
            "mc_log_ash",
            "mc_log_cypress",
            "mc_log_parasol",
            "mc_log_scrap"
        }
    },
	
	{
        id = "woodscrap",
        name = "Any Wood Source",
        ids = {
            "Misc_Com_Wood_Bowl_01",
            "Misc_Com_Wood_Bowl_02",
            "Misc_Com_Wood_Bowl_03",
            "Misc_Com_Wood_Bowl_04",
            "Misc_Com_Wood_Bowl_05",
            "misc_com_wood_cup_01",
            "misc_com_wood_cup_02",
            "misc_com_wood_fork",
            "misc_com_wood_spoon_01",
            "misc_com_wood_spoon_02",
            "wooden staff",
            "mc_log_hickory",
            "mc_log_pine",
            "mc_log_swirlwood",
            "mc_log_ash",
            "mc_log_cypress",
            "mc_log_parasol",
            "mc_log_scrap",
			"ashfall_firewood",
			"ashfall_bowl_01",
			"ashfall_carve_guar",
			"ashfall_cup_01",
			"ashfall_wood_fork",
			"ashfall_wood_knife",
			"ashfall_wood_ladle",
			"ashfall_wood_plate",
			"ashfall_wood_spoon"
        }
    },
	
	{
        id = "resin",
        name = "Resin",
        ids = {
            "ingred_resin_01",
            "ingred_shalk_resin_01",
            "t_ingcrea_beetleresin_01",
            "t_ingcrea_yethresin_01",
            "ab_ingflor_telvanniresin",
            "t_ingcrea_beetleresin_01",
            "t_ingcrea_yethresin_01"
        }
    },
	
	{
        id = "azurastar",
        name = "Azura's Star",
        ids = {
            "Misc_SoulGem_Azura",
            "NC_SoulGem_AzuraB",
        }
    },
	
}
crafting.registerMaterials(materials)

local tools = {
    {
        id = "knife",
        name = "Knife",
        requirement = function(itemStack)
            return itemStack.object.objectType == tes3.objectType.weapon
            and itemStack.object.type == tes3.weaponType.shortBladeOneHand
        end,
    },
    {
        id = "hammer",
        name = "Repair Hammer",
        requirement = function(itemStack)
            local isRepairItem = itemStack.object.objectType == tes3.objectType.repairItem
            local isHammer = itemStack.object.id:lower():find("hammer") ~= nil
            return isRepairItem and isHammer
        end,
    },
	{
        id = "carpentrytools",
        name = "Woodworking Kit",
        ids = { "mc_carpentry_kit", },
    },
}
crafting.registerTools(tools)

CraftingFramework.CarryableContainer.register{
	itemId = "vozhb_cart_01_1000",
	capacity = 1000,
	hasCollision = true,
}

CraftingFramework.CarryableContainer.register{
	itemId = "vozhb_cart_01_1500",
	capacity = 1500,
	hasCollision = true,
	weightModifier = 0.5,
}
	
CraftingFramework.CarryableContainer.register{
	itemId = "vozhb_cart_01_3000",
	capacity = 3000,
	hasCollision = true,
	weightModifier = 0.1,
}


--Create List of Recipes
local recipes = {
    {
        id = "vozhb_cart_01_vanilla",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_c",
		name = "Improbable Ingenuity",
		description = "Repair the cart using whatever materials you can scavenge and some ingenious use of tools.",
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
                material = "woodscrap",
                count = 60,
            },
        },
		soundType = "Wood",
		customRequirements = {
			{
				getLabel = function()
					return "Ingenuity"
				end,
				description = "Should be skilled enough with repair tools or intelligent enough to figure it out. (Sum of Armorer and Intelligence at least 75)",
				check = function()
					local intelligence = tes3.mobilePlayer.intelligence.current
					local armorer = tes3.mobilePlayer.armorer.current
					if intelligence + armorer > 74 then
						return true
					else
						return false, "You fail to come up with a way to turn kitchenware into proper wheels"
					end
				end
			},
		},
		category = "Ingenuity",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_vanilla_alter",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_c",
		name = "Alteration",
		description = "Repair the cart using whatever materials you can scavenge and your proficiency in alteration magic.",
        materials = {
            {
                material = "woodscrap",
                count = 40,
            },
        },
		soundType = "Wood",
		skillRequirements = {
			{ skill = "alteration", requirement = 25 }
		},
		customRequirements = {
			{
				getLabel = function()
					return "Ingenuity"
				end,
				description = "Shoud be intelligent and skilled enough to apply alteration in practice. (Sum of Alteration and Intelligence at least 75)",
				check = function()
					local intelligence = tes3.mobilePlayer.intelligence.current
					local alteration = tes3.mobilePlayer.alteration.current
					if intelligence + alteration > 74 then
						return true
					else
						return false, "You fail to come up with a way to transform kitchenware into proper wheels"
					end
				end
			}
		},
		category = "Ingenuity",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_vanilla_myst",
		craftableId = "vozhb_cart_01_1000",
        --placedObject = "vozhb_cart_01_c",
		name = "Telekinetic Manipulations",
		description = "Repair the cart using whatever materials you can scavenge and manipulating tools via mysticism.",
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
                material = "woodscrap",
                count = 60,
            },
        },
		soundType = "Wood",
		skillRequirements = {
			{ skill = "mysticism", requirement = 25 }
		},
		customRequirements = {
			{
				getLabel = function()
					return "Ingenuity"
				end,
				description = "Shoud be intelligent and skilled enough to apply mysticism in practice. (Sum of Mystcism and Intelligence at least 75)",
				check = function()
					local intelligence = tes3.mobilePlayer.intelligence.current
					local mysticism = tes3.mobilePlayer.mysticism.current
					if intelligence + mysticism > 74 then
						return true
					else
						return false, "You fail to come up with a way to turn kitchenware into proper wheels"
					end
				end
			}
		},
		category = "Ingenuity",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_vanilla_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Worldy Ingenuity and Enchantment",
		description = "Repair the cart using whatever materials you can scavenge and some ingenious use of tools with clever enchantments to increase utility.",
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
                material = "woodscrap",
                count = 60,
            },
			{ 
                material = "Misc_SoulGem_Grand",
                count = 1,
            },
        },
		soundType = "Wood",
		customRequirements = {
			{
				getLabel = function()
					return "Ingenuity"
				end,
				description = "Shoud be skilled enough with repair tools or intelligent enough to figure it out. (Sum of Armorer and Intelligence at least 75)",
				check = function()
					local intelligence = tes3.mobilePlayer.intelligence.current
					local armorer = tes3.mobilePlayer.armorer.current
					if intelligence + armorer > 74 then
						return true
					else
						return false, "You fail to come up with a way to turn kitchenware into proper wheels"
					end
				end
			}
		},
		skillRequirements = {
			{ skill = "enchant", requirement = 50 }
		},
		category = "Ingenuity",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_vanilla_alter_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Alteration and Enchantment",
		description = "Repair the cart using whatever materials you can scavenge and your proficiency in alteration magic with clever enchantments to increase utility.",
        materials = {
            {
                material = "woodscrap",
                count = 40,
            },
			{ 
                material = "Misc_SoulGem_Grand",
                count = 1,
            },
        },
		soundType = "Wood",
		skillRequirements = {
			{ skill = "alteration", requirement = 25 },
			{ skill = "enchant", requirement = 50 }
		},
		customRequirements = {
			{
				getLabel = function()
					return "Ingenuity"
				end,
				description = "Shoud be intelligent and skilled enough to apply alteration in practice. (Sum of Alteration and Intelligence at least 75)",
				check = function()
					local intelligence = tes3.mobilePlayer.intelligence.current
					local alteration = tes3.mobilePlayer.alteration.current
					if intelligence + alteration > 74 then
						return true
					else
						return false, "You fail to come up with a way to transform kitchenware into proper wheels"
					end
				end
			}
		},
		category = "Ingenuity",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_vanilla_myst_ench",
		craftableId = "vozhb_cart_01_1500",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_grand_c",
		name = "Telekinesis and Enchantment",
		description = "Repair the cart using whatever materials you can scavenge and manipulating tools via mysticism with clever enchantments to increase utility.",
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
                material = "woodscrap",
                count = 60,
            },
			{ 
                material = "Misc_SoulGem_Grand",
                count = 1,
            },
        },
		soundType = "Wood",
		skillRequirements = {
			{ skill = "mysticism", requirement = 25 },
			{ skill = "enchant", requirement = 50 }
		},
		customRequirements = {
			{
				getLabel = function()
					return "Ingenuity"
				end,
				description = "Shoud be intelligent and skilled enough to apply mysticism in practice. (Sum of Mystcism and Intelligence at least 75)",
				check = function()
					local intelligence = tes3.mobilePlayer.intelligence.current
					local mysticism = tes3.mobilePlayer.mysticism.current
					if intelligence + mysticism > 74 then
						return true
					else
						return false, "You fail to come up with a way to turn kitchenware into proper wheels"
					end
				end
			}
		},
		category = "Ingenuity",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
	{
        id = "vozhb_cart_01_vanilla_azura",
		craftableId = "vozhb_cart_01_3000",
		previewMesh = "vozhb/vozhb_cart_01.nif",
        --placedObject = "vozhb_cart_01_az_c",
		name = "Grandmaster Wasteful Enchantment",
		description = "Repair the cart using only some scrap enchanted with sacrifice of a unique artifact.",
        materials = {
            {
                material = "woodscrap",
                count = 10,
            },
			{ 
                material = "azurastar",
                count = 1,
            },
        },
		soundType = "Wood",
		skillRequirements = {
			{ skill = "enchant", requirement = 100 }
		},
		customRequirements = {
			{
			getLabel = function()
				return "Madness"
			end,
			description = "Shoud be mad enough to sacrifice Azura's Star for a handcart.",
			check = function()
				return true
			end
			}
		},
		category = "Unique",
		previewScale = 2,
		craftCallback = function() 
			event.trigger("HandcartCartRepaired")
			event.clear("HandcartCartRepaired")
		end,
    },
}

--Register your MenuActivator
crafting.registerMenuActivator{
    --id = "vozhb_cart_01_damaged",
    id = "HandcartCartTriggered",
    --type = "activate",
    type = "event",
	name = "Damaged Handcart",
    recipes = recipes,
	craftButtonText = "Repair",
	recipeHeaderText = "Repair options"
}

local function cartActivated(e)
	if (e.activator == tes3.player) then
        --tes3.messageBox({ message = "Activated " .. e.target.object.id })
		if (e.target.object.id == "vozhb_cart_01_damaged") then
			event.trigger("HandcartCartTriggered")
			--tes3.messageBox("Damaged Cart")
			event.register("HandcartCartRepaired", function()
				--tes3.messageBox("Function Called")
				local ref = e.target
				ref:disable()
				timer.delayOneFrame(function()
					ref:delete()
				end)
				local menu = tes3ui.findMenu("CF_Menu")
				if menu then
					menu:destroy()
					tes3ui.leaveMenuMode()
				end
			end)
			--tes3.messageBox("Event Registered")
		end
    end
end
event.register("activate", cartActivated)
