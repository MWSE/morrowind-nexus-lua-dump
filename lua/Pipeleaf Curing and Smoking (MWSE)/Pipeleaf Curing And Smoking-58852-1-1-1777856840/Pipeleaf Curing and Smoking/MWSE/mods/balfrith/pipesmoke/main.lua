--Get the Crafting Framework API and check that it exists
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end


--Register your materials
local materials = {

	{
        id = "ingred_tobacco",
        name = "Siyat",
        ids = {
            "T_IngFlor_Siyat_01",
			"T_IngFlor_Tobacco_01"
        }
    }
}
CraftingFramework.Material:registerMaterials(materials)

--Register Tools
CraftingFramework.Tool:new{
    id = "grinder",
    name = "Grinder",
    ids = {
        "AB_App_Grinder",
		"T_Imp_Grinder_01"
    },
}

CraftingFramework.Tool:new{
    id = "calcinator",
    name = "Calcinator",
    ids = {
        "AB_App_EbCalc",
		"apparatus_a_calcinator_01",
		"apparatus_g_calcinator_01",
		"apparatus_j_calcinator_01",
		"apparatus_m_calcinator_01",
		"apparatus_sm_calcinator_01",
		"T_De_Ebony_Calcinator",
		"T_De_PunavitSamovar_01"
    },
}

CraftingFramework.Tool:new{
	id = "pipe",
	name = "Pipe",
	ids = {
		"T_Com_Pipe_01",
		"T_Com_Pipe_02",
		"T_Imp_ColPipeCob_01",
		"T_De_HackloPipe_01",
		"T_Imp_NibPipeBamb_01",
		"T_We_BonewarePipe_01"
	},
}

CraftingFramework.SoundType.register{
  id = "smokeSound",
  soundPaths = {
    "pipeleaf\\pipeCrackle.wav",
  }
}

--Create List of Recipes
local recipes = {
--				Curing Recipes
	{ --				Cured Hackle-Lo
	name = "Cured Hackle-Lo",
	id = "cure_hackle_lo",
	craftableId = "b_ps_CuredHackleLo",
	resultAmount = 4,
	toolRequirements = {
		{
		tool = "grinder",
		},
		{
		tool = "calcinator",
		},
	},
	materials = {
		{ 
			material = "ingred_hackle-lo_leaf_01",
			count = 1,
		},
	},
	category = "Curing",
	description = "Drying and grinding the leaves removes most of their effects, leaving only their ability to restore fatigue.",
	},

	{ --				Cured Fire Petals
	name = "Cured Fire Petals",
	id = "cure_fire_petals",
	craftableId = "b_ps_CuredFirePetal",
	resultAmount = 4,
	toolRequirements = {
		{
		tool = "grinder",
		},
		{
		tool = "calcinator",
		},
	},
	materials = {
		{ 
			material = "ingred_fire_petal_01",
			count = 1,
		},
	},
	category = "Curing",
	description = "Drying and grinding the petals removes most of their effects, leaving only their ability to resist fire.",
	},

	{ --				Cured Bittergreen
	name = "Cured Bittergreen Petals",
	id = "cure_bittergreen",
	craftableId = "b_ps_CuredBittergreen",
	resultAmount = 4,
	toolRequirements = {
		{
		tool = "grinder",
		},
		{
		tool = "calcinator",
		},
	},
	materials = {
		{ 
			material = "ingred_bittergreen_petals_01",
			count = 1,
		},
	},
	category = "Curing",
	description = "Drying and grinding the petals removes most of their effects, leaving only their ability to restore intelligence.",
	},

	{ --				Cured Siyat
	name = "Cured Siyat",
	id = "cure_siyat",
	craftableId = "T_IngFood_Siyat_02",
	resultAmount = 4,
	toolRequirements = {
		{
		tool = "grinder",
		},
		{
		tool = "calcinator",
		},
	},
	materials = {
		{ 
			material = "ingred_tobacco",
			count = 1,
		},
	},
	category = "Curing",
	description = "Drying and grinding the leaves removes most of their effects, leaving only their ability to restore fatigue.",
	},

--				Smoking Recipes
	{ --				Smoke Hackle-Lo
	name = "Smoke Hackle-Lo",
	id = "smoke_hackle_lo",
	previewMesh = "Sky\\m\\Sky_Misc_Pipe_02.nif",
	materials = {
		{ 
			material = "b_ps_CuredHackleLo",
			count = 1,
		},
	},
	category = "Smoking",
	soundType = "smokeSound",
	description = "The common mer's pipeleaf. Slightly harsher in flavor than the western siyat, cured Hackle-Lo has the same resorative effect on vigor as its cyrodiilic counterpart.",
	noResult = true,
	uncarryable = true,
	craftCallback = function()
		tes3.applyMagicSource({
			reference = tes3.player,
			castChance = 100,
			bypassResistances = true,
			name = "Hackle-Lo Pipeleaf: 2 pts",
			effects = {
				{
					id = 77,
					duration = 300,
					min = 2,
					max = 2,
				}
			}
		})
	end,
	},

	{ --				Smoke Fire Petals
	name = "Smoke Fire Petals",
	id = "smoke_fire_petals",
	previewMesh = "Sky\\m\\Sky_Misc_Pipe_02.nif",
	materials = {
		{ 
			material = "b_ps_CuredFirePetal",
			count = 1,
		},
	},
	category = "Smoking",
	soundType = "smokeSound",
	description = "Cured Fire Petals tend to burn faster and hotter than other blends. It has an earthy taste with strong notes of spice, and grants a minor resistance to fire and heat when consumed.",
	noResult = true,
	uncarryable = true,
	craftCallback = function()
		tes3.applyMagicSource({
			reference = tes3.player,
			castChance = 100,
			bypassResistances = true,
			name = "Fire Petal Pipeleaf: 5 pts",
			effects = {
				{
					id = 90,
					duration = 300,
					min = 5,
					max = 5,
				}
			}
		})
	end,
	},
	{ --				Smoke Bittergreen
	name = "Smoke Bittergreen",
	id = "smoke_bittergreen",
	previewMesh = "Sky\\m\\Sky_Misc_Pipe_02.nif",
	materials = {
		{ 
			material = "b_ps_CuredBittergreen",
			count = 1,
		},
	},
	category = "Smoking",
	soundType = "smokeSound",
	description = "Something of an acquired taste. To no one's surprise, cured bittergreen has a bitter, herbal flavor. It bolsters the user's intelligence.",
	noResult = true,
	uncarryable = true,
	craftCallback = function()
		tes3.applyMagicSource({
			reference = tes3.player,
			castChance = 100,
			bypassResistances = true,
			name = "Bittergreen Pipeleaf",
			effects = {
				{
					id = 79,
					attribute = 1,
					duration = 300,
					min = 3,
					max = 3,
				}
			}
		})
	end,
	},
	{ --				Smoke Siyat
	name = "Smoke Siyat",
	id = "smoke_siyat",
	previewMesh = "Sky\\m\\Sky_Misc_Pipe_02.nif",
	materials = {
		{ 
			material = "T_IngFood_Siyat_02",
			count = 1,
		},
	},
	category = "Smoking",
	soundType = "smokeSound",
	description = "The common man's pipeleaf. A mellow and slightly sweet smoke with faint hints of vanilla, cured Siyat has a restorative effect on the user's vigor.",
	noResult = true,
	uncarryable = true,
	craftCallback = function()
		tes3.applyMagicSource({
			reference = tes3.player,
			castChance = 100,
			bypassResistances = true,
			name = "Siyat Pipeleaf: 2 pts",
			effects = {
				{
					id = 77,
					duration = 300,
					min = 2,
					max = 2,
				}
			}
		})
	end,
	},
		}

--Register your MenuActivator

--    CraftingFramework.MenuActivator:new{
--        id = "T_Com_Pipe_01",
--        type = "equip",
--        name = "Pipe Smoking",
--        recipes = recipes
--    }
	
--	CraftingFramework.MenuActivator:new{
--        id = "T_Com_Pipe_02",
--        type = "equip",
--        name = "Pipe Smoking",
--        recipes = recipes
--    }

CraftingFramework.MenuActivator:new{
    id = "PipeSmokingMenu",
    type = "event",
    name = "Pipe Smoking",
    recipes = recipes
}


local function onActivatePipe(e)
	if e.reference ~= tes3.player then return end
	if not tes3.menuMode() then return end
	local pipeTool = CraftingFramework.Tool.getTool("pipe")
	if pipeTool and pipeTool:itemIsTool(e.item) then
		event.trigger("PipeSmokingMenu")
		return true
	end
end

event.register("equip", onActivatePipe)