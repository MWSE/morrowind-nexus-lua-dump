local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

local config = include("rev_REPL.replicasConfig")

local materials = {
    {
        id = "steel",
        name = "Steel",
        ids = {
            "rev_repl_ingot_steel",
        }
    },    
    {
        id = "cloth",
        name = "Cloth",
        ids = {
            "misc_clothbolt_03",
            "misc_clothbolt_02",
            "misc_clothbolt_01",
        }
    },
}

CraftingFramework.Material:registerMaterials(materials)

local replicaTable = CraftingFramework.MenuActivator:new{
	id = "rev_repl_table",
	type = "activate",
	recipes = config.recipes,
	name = "Replica Crafting Table",
}


local function journalCallback(e)

	for i, v in ipairs(config.replicas) do
		if v.quest == e.topic.id and v.index == e.index then
			tes3.messageBox("Replica recipe unlocked: " .. tes3.getObject(v.id).name)
			local recipe = CraftingFramework.Recipe.getRecipe(v.id)
			recipe:learn()
		end
	end
end

local function equipCallback(e)
	if e.itemData and e.itemData.data.rev_replica then
		tes3.messageBox({message = "Replica items are purely for display."})
		e.block = true
	end
end

local function barterCallback(e)
	if e.selling then
		for i,v in ipairs(e.selling) do
			if v.itemData and v.itemData.data.rev_replica then
				tes3.messageBox("Replica items cannot be sold.")
				e.block = true				
			end
		end
	end
end

local function allowSales(e)
	if e.mobile.object ~= nil then
		if e.mobile.object.baseObject.id == "alusaron" or e.mobile.object.baseObject.id == "meldor" or e.mobile.object.baseObject.id == "tuveso beleth" or e.mobile.object.baseObject.id == "hodlismod" then
			e.mobile.object.aiConfig.bartersMiscItems = true
		end
	end
end

event.register(tes3.event.journal, journalCallback)
event.register(tes3.event.equip, equipCallback)
event.register(tes3.event.barterOffer, barterCallback)
event.register(tes3.event.mobileActivated, allowSales)
