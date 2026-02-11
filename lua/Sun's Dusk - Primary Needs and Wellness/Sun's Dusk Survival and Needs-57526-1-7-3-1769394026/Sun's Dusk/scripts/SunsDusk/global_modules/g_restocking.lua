-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Restocking															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

--each itemPool shares a startstock, maxstock and restockperday

-- wood and camping
table.insert(G_restocking, {
    itemPool 		= { "sd_wood_publican" },
	itemType 		= "Ingredient",
    serviceRequired = "Ingredients",
    classPatterns 	= { "publican", "innkeeper", "trader", "merchant" },
    startStock 		= 6,
    maxStock 		= 6,
    restockPerDay 	= 3,
})
table.insert(G_restocking, {
    itemPool 		= { "sd_wood_merchant" },
	itemType 		= "Miscellaneous",
    serviceRequired = "Misc",
    classPatterns 	= { "publican", "innkeeper", "trader", "merchant" },
    startStock 		= 6,
    maxStock 		= 6,
    restockPerDay 	= 3,
})
table.insert(G_restocking, {
    itemPool 		= { "sd_campingitem_tent" },
	itemType 		= "Ingredient",
    serviceRequired = "Ingredients",
    classPatterns 	= { "publican", "innkeeper", "trader", "merchant" },
    startStock 		= 8,
    maxStock 		= 8,
    restockPerDay 	= 4,
})
table.insert(G_restocking, {
    itemPool 		= { "sd_campingitem_bedroll" },
	itemType 		= "Ingredient",
    serviceRequired = "Ingredients",
    classPatterns 	= { "publican", "innkeeper", "trader", "merchant" },
    startStock 		= 8,
    maxStock 		= 8,
    restockPerDay 	= 4,
})
-- bathing (towels)
table.insert(G_restocking, {
    itemPool = { 
		"misc_de_cloth10",             -- vanilla
		"misc_de_cloth11",             -- vanilla
		"misc_de_foldedcloth00",       -- vanilla
		"ab_misc_decloth01large",      -- OAAB
		"ab_misc_decloth01small",      -- OAAB
		"ab_misc_decloth02large",      -- OAAB
		"ab_misc_decloth02small",      -- OAAB
		"t_com_clothbrownfolded_01",   -- TD
		"t_com_clothbrown_01",         -- TD
		"t_com_clothgreenfolded_01",   -- TD
		"t_com_clothgreen_01",         -- TD
		"t_com_clothplainfolded_01",   -- TD
		"t_com_clothplain_01",         -- TD
		"t_com_clothplain_02",         -- TD
		"t_com_clothpurplefolded_01",  -- TD
		"t_com_clothpurple_01",        -- TD
		"t_com_clothredfolded_01",     -- TD
		"t_com_clothred_01",           -- TD
		"t_com_clothyellowfolded_01",  -- TD
		"t_com_clothyellow_01",        -- TD
	},
	itemType 		= "Miscellaneous",
    serviceRequired = "Misc",
    classPatterns 	= { "trader", "merchant", "pawnbroker", "soap seller" },
    startStock 		= 0.5,
    maxStock 		= 4,
    restockPerDay 	= 0.5,
})
-- soap
table.insert(G_restocking, {
    itemPool = { 
		"t_com_soap_01", 	-- TD
		"t_com_soap_02", 	-- TD
		"t_com_soap_03", 	-- TD
		"t_com_soap_04", 	-- TD
		"t_com_soap_05", 	-- TD
		"ab_misc_soap01", 	-- OAAB
	},
	itemType 		= "Miscellaneous",
    serviceRequired = "Misc",
    classPatterns 	= { "trader", "merchant", "pawnbroker", "soap seller" },
    startStock 		= 2,
    maxStock 		= 2,
    restockPerDay 	= 3,
})
-- Baths of Vvardenfell
table.insert(G_restocking, {
    itemPool = { 
		"s3_towel",
		"ab_misc_comtowelblack01",     -- OAAB
		"ab_misc_comtowelblack01",     -- OAAB
		"ab_misc_comtowelblue01",      -- OAAB
		"ab_misc_comtowelblue02",      -- OAAB
		"ab_misc_comtowelbrown01",     -- OAAB
		"ab_misc_comtowelbrown02",     -- OAAB
		"ab_misc_comtowelburgy01",     -- OAAB
		"ab_misc_comtowelburgy02",     -- OAAB
		"ab_misc_comtowelgreen01",     -- OAAB
		"ab_misc_comtowelgreen02",     -- OAAB
		"ab_misc_comtowelwhite01",     -- OAAB
		"ab_misc_comtowelwhite02",     -- OAAB			
	},
	itemType 		= "Miscellaneous",
    serviceRequired = "Misc",
    classPatterns 	= { "soap seller" },
    startStock 		= 2,
    maxStock 		= 2,
    restockPerDay 	= 4,
})
table.insert(G_restocking, {
    itemPool = { 
		"s3_soapinv_01", -- "tigers tail", (UNOFFICIAL)			
		"s3_soapinv_02", -- "star icon",
		"s3_soapinv_03", -- "Moonflower",
		"s3_soapinv_04", -- "Sea Breeze",
		"s3_soapinv_05", -- "Divine",
		"s3_soapinv_06", -- "Ocean Deep",
		"s3_soapinv_07", -- "Midnight Musk",
		"s3_soapinv_08", -- "Resolve",
	},
	itemType 		= "Ingredient",
    serviceRequired = "Ingredients",
    classPatterns 	= { "soap seller" },
    startStock 		= 2,
    maxStock 		= 2,
    restockPerDay 	= 2,
})
table.insert(G_restocking, {
    itemPool = {
		"ingred_sload_soap_01", -- sload soap

	},
	itemType 		= "Ingredient",
    serviceRequired = "Ingredients",
    classPatterns 	= { "publican", "innkeeper", "trader", "merchant" },
    startStock 		= 2,
    maxStock 		= 4,
    restockPerDay 	= 0.5,
})
-- teacups
table.insert(G_restocking, {
    itemPool = { 
		"misc_com_redware_cup",
		"misc_de_pot_redware_03",
		"t_com_copperkettle_01",
		"t_com_coppetteapot_01",
		"ab_misc_deceramiccup_01",
		"ab_misc_deceramiccup_02",
		"ab_misc_deceramicflask_01",
		"ab_misc_kettleceremonial",
		"ab_misc_debugteapot",
	},
	itemType 		= "Miscellaneous",
    serviceRequired = "Misc",
    classPatterns 	= { "trader", "merchant", "alchemist" },
    startStock 		= 0.5,
    maxStock 		= 4,
    restockPerDay 	= 0.5,
})
table.insert(G_restocking, {
    itemPool = { 
		"sd_teapot_red", 
		"sd_wash_basin_red", 
		"misc_com_redware_cup", 
	},
	itemType 		= "Miscellaneous",
    serviceRequired = "Misc",
    classPatterns 	= { "trader", "merchant", "alchemist", "pawnbroker", "soap seller" },
    startStock 		= 1,
    maxStock 		= 2,
    restockPerDay 	= 1,
})
-- books
table.insert(G_restocking, {
    itemPool = { "sd_book_3_cook_1" }, -- add other cooking recipes and whatnot here
	itemType 		= "Book",
    serviceRequired = "Books",
    classPatterns 	= { "trader", "merchant", "pawnbroker", "bookseller" },
    startStock 		= 1,
    maxStock 		= 1,
    restockPerDay 	= 1,
})
table.insert(G_restocking, {
    itemPool = { 
		"sd_book_cook_food_egg",
		"sd_book_cook_food_egg_g",
		"sd_book_cook_food_f",
		"sd_book_cook_food_f_g_h",
		"sd_book_cook_food_f_g_salt",
		"sd_book_cook_food_f_salt",
		"sd_book_cook_food_fruit",
		"sd_book_cook_food_fruit_g_h",
		"sd_book_cook_food_g",
		"sd_book_cook_food_g_salt",
		"sd_book_cook_food_g_spice",
		"sd_book_cook_food_m",
		"sd_book_cook_food_m_f",
		"sd_book_cook_food_m_fruit",
		"sd_book_cook_food_m_g",
		"sd_book_cook_food_m_meat",
		"sd_book_cook_food_m_salt",
		"sd_book_cook_food_m_soup",
		"sd_book_cook_food_m_spice",
		"sd_book_cook_food_meat",
		"sd_book_cook_food_meat_g_h",
		"sd_book_cook_food_meat_salt",
		"sd_book_cook_food_meat_soup",
		"sd_book_cook_food_meat_spice", 
	},
	itemType 		= "Book",
    serviceRequired = "Books",
    classPatterns 	= { "trader", "merchant", "pawnbroker", "bookseller" },
    startStock 		= 0.5,
    maxStock 		= 1,
    restockPerDay 	= 0.5,
})
table.insert(G_restocking, {
    itemPool = { 
		"sd_pouch",
		"sd_backpack",
		"sd_backpack_traveler",
		"sd_backpack_adventurer",
		"sd_backpack_velvetblue",
		"sd_backpack_satchelbrown",
	},
	itemType 		= "Miscellaneous",
    serviceRequired = "Misc",
    classPatterns 	= { "trader", "merchant", "pawnbroker" },
    startStock 		= 0.25,
    maxStock 		= 1,
    restockPerDay 	= 0.25,
})


-- verify pools
for i = #G_restocking, 1, -1 do
    local group = G_restocking[i]
    local typeTable = types[group.itemType]
    
    if not typeTable then
        log(5, "[G_restocking] Invalid itemType: " .. tostring(group.itemType) .. " - deleting group " .. i)
        table.remove(G_restocking, i)
    else
        for j = #group.itemPool, 1, -1 do
            local itemId = group.itemPool[j]
            if not typeTable.records[itemId] then
               log(5, "[G_restocking] Item not found in " .. group.itemType .. ".records: " .. itemId)
                table.remove(group.itemPool, j)
            end
        end
        
        if #group.itemPool == 0 then
            log(5, "[G_restocking] No valid items remain in group " .. i .. " - deleting group")
            table.remove(G_restocking, i)
        end
    end
end


-- ========== ACTIVATE NPC ==========
local function activateNPC(npc, player)
	local npcRecordId = npc.recordId
	local npcId = npc.id
	local record = types.NPC.record(npcRecordId)
	local className = record.class:lower()
	if types.Actor.isDead(npc) then
		saveData.restockingNPCs[npcId] = nil
		return
	end
	local now = world.getGameTime() / (24 * 60 * 60)
    
    if not saveData.restockingNPCs[npcId] then
        saveData.restockingNPCs[npcId] = {
            lastRestock = now,
            initialized = false,
        }
    end
    
    local npcData = saveData.restockingNPCs[npcId]
    local daysSinceRestock = now - npcData.lastRestock
    local didProcess = false
    
    for _, config in ipairs(G_restocking) do
        local serviceMatch = record.servicesOffered[config.serviceRequired]
        
        -- Check if className matches any pattern in the array
        local classMatch = false
        for _, pattern in ipairs(config.classPatterns) do
            if className:find(pattern) then
                classMatch = true
                break
            end
        end
        
        if serviceMatch and classMatch then
            didProcess = true
            
            -- Count current stock across entire pool
            local currentStock = 0
            local poolSet = {}
            for _, itemId in ipairs(config.itemPool) do
                poolSet[itemId] = true
            end
            
            for _, item in pairs(types.NPC.inventory(npc):getAll(types[config.itemType])) do
                if poolSet[item.recordId] then
                    currentStock = currentStock + item.count
                end
            end
            
            local toAdd = 0
            
            if not npcData.initialized then
                toAdd = math.max(0, config.startStock - currentStock)
				if math.random()< toAdd%1 then
					toAdd = toAdd + 1
				end
				toAdd = math.floor(toAdd)
            elseif currentStock < config.maxStock then
                local restockAmount = math.min(daysSinceRestock, 1.0) * config.restockPerDay
                toAdd = math.floor(restockAmount)
                
                if math.random() < (restockAmount % 1) then
                    toAdd = toAdd + 1
                end
                toAdd = math.min(toAdd, config.maxStock - currentStock)
            end

            for i = 1, toAdd do
                local itemId = config.itemPool[math.random(#config.itemPool)]
                local tempItem = world.createObject(itemId, 1)
                tempItem:moveInto(types.NPC.inventory(npc))
            end
        end
    end
    
    if didProcess then
        npcData.initialized = true
        npcData.lastRestock = now
    end
	
--[[
	local missingTents
	local missingBedrolls
	for a,b in pairs(record.servicesOffered) do
		print(a,b)
	end
	if record.servicesOffered["Ingredients"] then
		if className:find("publican") then
			missingTents = 5
			missingBedrolls = 5
		end
	end
	if missingTents then
		for _, item in pairs(types.NPC.inventory(npc):getAll(types.Miscellaneous)) do
			if item.recordId == "sd_campingitem_bedroll" then
				missingBedrolls = missingBedrolls - item.count
			elseif item.recordId == "sd_campingitem_tent" then
				missingTents = missingTents - item.count
			end
		end
		if missingTents > 0 then
			local tempItem = world.createObject("sd_campingitem_tent", missingTents)
			tempItem:moveInto(types.NPC.inventory(npc))
		end
		if missingBedrolls > 0 then
			local tempItem = world.createObject("sd_campingitem_bedroll", missingBedrolls)
			tempItem:moveInto(types.NPC.inventory(npc))
		end
	end
	]]
end

I.Activation.addHandlerForType(types.NPC, activateNPC)

G_onLoadJobs.restocking = function(data)
	saveData.restockingNPCs			= saveData.restockingNPCs		or {}
end