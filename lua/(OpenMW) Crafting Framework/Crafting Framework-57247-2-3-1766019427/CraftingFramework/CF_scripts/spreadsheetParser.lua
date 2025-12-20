-- TSV Parser for Crafting Recipes

protectedRecordIds = {} -- currently unused, but registering your item here might someday prevent it from getting a generated record. let me know if i should actually implement this

ingredientExpMultipliers = {
["ingred_bonemeal_01"] = 0.75,
["ingred_scrap_metal_01"] = 1.2,

}


 -- Mapping für Material-IDs (erweitere nach Bedarf)
materialMapping = {
		["adamantium ore"] = "ingred_adamantium_ore_01",
		["iron ore"] = "T_IngMine_OreIron_01",
		["racer plumes"] = "ingred_racer_plumes_01",
		["coal"] = "T_IngMine_Coal_01",
		["orichalcum ore"] = "T_IngMine_OreOrichalcum_01",
		["dwemer scrap metal"] = "ingred_scrap_metal_01",
		["raw glass"] = "ingred_raw_glass_01",
		["raw ebony"] = "ingred_raw_ebony_01",
		["ebony ore"] = "ingred_raw_ebony_01",
		["daedra heart"] = "ingred_daedras_heart_01",
		["daedric heart"] = "ingred_daedras_heart_01",
		["gold ore"] = "T_IngMine_OreGold_01",
		["silver ore"] = "T_IngMine_OreSilver_01",
		["diamond"] = "ingred_diamond_01",
		["netch leather"] = "ingred_netch_leather_01",
		["bonemeal"] = "ingred_bonemeal_01",
		["stahlrim"] = "ingred_raw_Stalhrim_01",
		["amethyst"] = "T_IngMine_Amethyst_01",
		["ruby"] = "ingred_ruby_01",
		["sapphire"] = "T_IngMine_Sapphire_01",
		["emerald"] = "ingred_emerald_01",
		["midnight agate"] = "T_IngMine_Agate_03",
		["pearl"] = "ingred_pearl_01",
		["trama root"] = "ingred_trama_root_01",
		["small mole crab shell"] = "",
		["garnet"] = "T_IngMine_Garnet_01",
		["resin"] = "ingred_resin_01",
		["lesser soul gem"] = "Misc_SoulGem_Lesser",
		["fire petal"] = "ingred_fire_petal_01",
		["dreugh wax"] = "ingred_dreugh_wax_01",
		["petty soul gem"] = "Misc_SoulGem_Petty",
		["lesser soul gem"] = "Misc_SoulGem_Lesser",
		["common soul gem"] = "Misc_SoulGem_Common",
		["greater soul gem"] = "Misc_SoulGem_Greater",
		["grand soul gem"] = "Misc_SoulGem_Grand",
		["alit hide"] = "ingred_alit_hide_01",
		
		
		-- Weitere Mappings hier hinzufügen oder per expansion lua
	}
	
	-- Mapping für Kategorien basierend auf dem Material-Feld
categoryMapping = {
	--	["H - Iron"] = "Iron",
	--	["H - Steel"] = "Steel",
	--	["H - Silver"] = "Silver",
	--	["H - Dwemer"] = "Dwemer",
	--	["L - Glass"] = "Glass",
	--	["H - Ebony"] = "Ebony",
	--	["H - Daedric"] = "Daedric",
	--	["L - Leather"] = "Leather",
	--	["L - Netch leather"] = "Netch",
	--	["L - Chitin"] = "Chitin",
	--	["L - Boiled"] = "Boiled Leather",
	--	["M - Adamantium"] = "Adamantium",
	--	["M - Orcish"] = "Orcish",
	--	["M - Bonemold"] = "Bonemold",
	--	["M - stahlrim"] = "Stahlrim",
	--	["H - steel"] = "Steel",
	--	["U - Jewelry"] = "Jewelry",
	--	["U - Clothing"] = "Clothing",
	--	["H - Imperial"] = "Imperial",
	--	-- Weitere Mappings hier hinzufügen oder per expansion lua
	}


local function getItemType(id)
	if id then
		id = id:lower()
		if types.Ingredient.records[id] then
			return "Ingredient"
		elseif types.Weapon.records[id] then
			return "Weapon"
		elseif types.Armor.records[id] then
			return "Armor"
		elseif types.Miscellaneous.records[id] then
			return "Miscellaneous"
		elseif types.Repair.records[id] then
			return "Repair"
		elseif types.Probe.records[id] then
			return "Probe"
		elseif types.Potion.records[id] then
			return "Potion"
		elseif types.Lockpick.records[id] then
			return "Lockpick"
		elseif types.Light.records[id] then
			return "Light"
		elseif types.Clothing.records[id] then
			return "Clothing"
		elseif types.Book.records[id] then
			return "Book"
		elseif types.Apparatus.records[id] then
			return "Apparatus"
		end
	end
	return nil
end


function parseRecipes(tsvContent)
	local lines = {}
	for line in tsvContent:gmatch("[^\r\n]+") do
		table.insert(lines, line)

	end
	
	---- Header überspringen (nein)
	--local header = lines[1]
	
	
	categories = {}
	local invalidSkills = {}
	local invalidFactions = {}
   
	
	-- Daten parsen
	for i = 1, #lines do
		local line = lines[i]
		if line and trim(line) ~= "" and line:sub(1, #"Raw data from ") ~= "Raw data from " and line:sub(1, #"item code\tIn-Game Label") ~= "item code\tIn-Game Label" then

			local fields = {}
			--for field in line:gmatch("[^\t]*") do
			--	table.insert(fields, field)
			--end
			local temp = line .. '\t'  -- Tab am Ende hinzufügen
			temp:gsub('([^\t]*)\t', function(field)
				table.insert(fields, field)
				return ''
			end)
			-- Felder extrahieren
			local recordId = (fields[1] or ""):lower()
			local preserveRecordId = nil
			if recordId:sub(1, 1) == "!" then
				preserveRecordId = true
				recordId = recordId:sub(2)
			end
			local inGameLabel = fields[2] or ""
			local weight = tonumber(fields[3]) or 0
			local value = tonumber(fields[4]) or 0
			local armor = tonumber(fields[5]) or 0
			local craftingCategory = fields[11] or ""
			local resultType = types[fields[12]] and fields[12] or "Weapon"
			local isProjectile = fields[12] == "Ammo"
			local recipeName = fields[13] and fields[13] ~= "" and fields[13] or nil
			local tier = tonumber(fields[14]) or 0
			local armorerLevel = tonumber(fields[15]) or 0
			local factionRank = fields[16] and fields[16] ~= "" and tonumber(fields[16]) or nil
			local faction = fields[17] and fields[17] ~= "" and fields[17] or nil
			local count = fields[18] and fields[18] ~= "" and tonumber(fields[18]) or isProjectile and 20 or 1
			local amount1 = tonumber(fields[19]) or 0
			local material1 = fields[20] or ""
			local amount2 = tonumber(fields[21]) or 0
			local material2 = fields[22] or ""
			local amount3 = tonumber(fields[23]) or 0
			local material3 = fields[24] or ""
			local amount4 = tonumber(fields[25]) or 0
			local material4 = fields[26] or ""
			local amount5 = tonumber(fields[27]) or 0
			local material5 = fields[28] or ""
			local description = fields[29] and fields[29] ~= "" and fields[29] or nil
			local externallyDisabled = fields[30] and fields[30] ~= "" and fields[30] or nil
			local craftingSound = fields[31] and fields[31] ~= "" and fields[31] or nil
			local craftingTime = tonumber(fields[32])
			local experience = tonumber(fields[33])
			local firstSkill = fields[34] and fields[34] ~= "" and fields[34] or nil
			local secondLevel = tonumber(fields[35])
			local secondSkill = fields[36] and fields[36] ~= "" and fields[36] or nil
			
			if firstSkill then
				firstSkill = firstSkill:lower()
			end
			if secondSkill then
				secondSkill = secondSkill:lower()
			end
			
			if firstSkill and not core.stats.Skill.records[firstSkill] then
				invalidSkills[firstSkill] = true
				firstSkill = nil
			end
			if secondSkill and not core.stats.Skill.records[secondSkill] then
				invalidSkills[secondSkill] = true
				secondSkill = nil
				secondLevel = nil
			end
			
			if craftingTime and craftingTime <= 0 then
				craftingTime = 1
			end			
			if count <= 0 then
				count = 1
			end
			
			if craftingSound then
				if not core.sound.records[craftingSound] and not vfs.fileExists(craftingSound) then
					print("invalid crafting sound: "..craftingSound)
					craftingSound = nil
				end
			end
			
			if not factionRank or not faction or not core.factions.records[faction] then
				if factionRank and faction then
					invalidFactions[faction] = true
				end
				factionRank = nil
				faction = nil
			end
			
			local record = types[resultType] and types[resultType].record(recordId)
			if recordId ~= "" and not record then
				local revertResultType = resultType
				resultType = getItemType(recordId)
				if resultType then
					record = types[resultType] and types[resultType].record(recordId)
				else
					resultType = revertResultType
				end
			end
			-- Count bestimmen (Projektile = 10, sonst 1)
			
			if record then
				
				
				-- Ingredients erstellen
				local ingredients = {}
				local materials = {
					{material1, amount1},
					{material2, amount2},
					{material3, amount3},
					{material4, amount4},
					{material5, amount5},
				}
				
				for _, data in ipairs(materials) do
					local material, amount = data[1], data[2]
					if amount > 0 and material ~= "" and armorerLevel >= 1 then
						local materialId = materialMapping[material:lower()] or material
						if wildcardFunctions[material] then
							table.insert(ingredients, {
								type = "wildcard",
								func = wildcardFunctions[material],
								count = amount,
								name = material,
							})
						else
							local materialType = getItemType(materialId)
							if materialType then
								table.insert(ingredients, {
									type = materialType,
									id = materialId:lower(),
									count = amount
								})
							else
								print("WARNING: " .. material:lower().." in "..recordId)
							end
						end
					end
				end
				
				-- Recipe erstellen
				local recipe = {
					type = resultType,
					id = recordId,
					name = recipeName,
					count = count,
					level = armorerLevel,
					--tier = tier,
					ingredients = ingredients,
					faction = faction,
					factionRank = factionRank,
					externallyDisabled = externallyDisabled,
					craftingSound = craftingSound,
					craftingTime = craftingTime,
					experience = experience,
					firstSkill  = firstSkill,
					secondLevel = secondLevel,
					secondSkill = secondSkill,
					preserveRecordId = preserveRecordId,
				}
				
				-- Kategorie bestimmen
				local categoryName
				if isProjectile then
					categoryName = "Ammo"
				else
					-- Kategorie aus craftingCategory-Mapping ableiten
					categoryName = categoryMapping[craftingCategory] or craftingCategory
				end
				
				if #recipe.ingredients > 0 and recipe.level >= 1 then
					if types[recipe.type].records[recipe.id] then
						if not categories[categoryName] then
							categories[categoryName] = {}
						end
						table.insert(categories[categoryName], recipe)
					else
						local resultType = getItemType(recipe.id)
						if resultType then
							recipe.type = resultType
							if not categories[categoryName] then
								categories[categoryName] = {}
							end
							table.insert(categories[categoryName], recipe)
						else
							print("Skipped "..tostring(recipe.name).." (invalid)")
						end
					end
				elseif recipe.id ~= "" then
					print("Skipped ".. string.gsub(line, "\t", "|"))
				end
			elseif recordId ~= "" then
				print("Invalid Record: "..resultType.."."..recordId)
			end
		end
	end
	if next(invalidFactions) then
		print("invalid factions:")
		for a in pairs(invalidFactions) do
			print("'"..a.."'")
		end
	end
	if next(invalidSkills) then
		print("invalid skills:")
		for a in pairs(invalidSkills) do
			print("'"..a.."'")
		end
	end
	return categories
end

-- Neue Funktion: Mehrere Categories zusammenführen
function mergeCategories(targetCategories, sourceCategories)
	for categoryName, recipes in pairs(sourceCategories) do
		if not targetCategories[categoryName] then
			targetCategories[categoryName] = {}
		end
		
		-- Set für bereits existierende IDs in der Zielkategorie erstellen
		local existingIds = {}
		for _, recipe in ipairs(targetCategories[categoryName]) do
			existingIds[recipe.name or recipe.id] = true
		end
		
		-- Nur neue Rezepte hinzufügen (keine Duplikate)
		for _, recipe in ipairs(recipes) do
			if not existingIds[recipe.name or recipe.id] then
				table.insert(targetCategories[categoryName], recipe)
				existingIds[recipe.name or recipe.id] = true
			else
				print("Duplicate recipe skipped: " .. (recipe.name or recipe.id) .. " in category " .. categoryName)
			end
		end
	end
end

-- Neue Funktion: Categories für Ausgabe sortieren
function sortCategories(categories)
	-- Kategorien sortieren
	local sortedCategories = {}
	for categoryName, recipes in pairs(categories) do
		-- Recipes innerhalb der Kategorie sortieren
		table.sort(recipes, function(a, b)
			-- Erst nach Typ sortieren (Armor vor Weapon)
			if a.type ~= b.type then
				if a.type == "Armor" and b.type == "Weapon" then
					return true
				elseif a.type == "Weapon" and b.type == "Armor" then
					return false
				else
					return a.type < b.type
				end
			end
			-- Dann nach Level
			if a.level == b.level then
				return (a.name or a.id) < (b.name or b.id)
			end
			return a.level < b.level
		end)
		
		-- Durchschnittslevel der Kategorie berechnen
		local totalLevel = 0
		for _, recipe in ipairs(recipes) do
			totalLevel = totalLevel + recipe.level
		end
		local averageLevel = totalLevel / #recipes
		
		table.insert(sortedCategories, {
			categoryName = categoryName,
			recipes = recipes,
			averageLevel = averageLevel
		})
	end
	
	table.sort(sortedCategories, function(a, b)
		-- Prioritäten extrahieren
		local aPriority = a.categoryName:match("^{(%-?%d+)}")
		local bPriority = b.categoryName:match("^{(%-?%d+)}")
		aPriority = aPriority and tonumber(aPriority) or nil
		bPriority = bPriority and tonumber(bPriority) or nil
		
		-- Sehr hohe Priorität (-10 und kleiner) - über alles
		if aPriority and aPriority <= -20 then
			if bPriority and bPriority <= -20 then
				return aPriority < bPriority
			else
				return true
			end
		elseif bPriority and bPriority <= -20 then
			return false
		end
		
		-- Ammo nach sehr hoher Priorität
		if a.categoryName == "Ammo" then
			return true
		elseif b.categoryName == "Ammo" then
			return false
		end
		if aPriority and aPriority <= -10 then
			if bPriority and bPriority <= -10 then
				return aPriority < bPriority
			else
				return true
			end
		elseif bPriority and bPriority <= -10 then
			return false
		end
		-- Misc nach Ammo
		if a.categoryName == "Misc" then
			return true
		elseif b.categoryName == "Misc" then
			return false
		end
		
		-- Originale misc-Regel (falls noch vorhanden)
		if a.categoryName:lower():sub(1,4) == "misc" then
			return true
		elseif b.categoryName:lower():sub(1,4) == "misc" then
			return false
		end
		
		-- Hohe Priorität (-9 bis -1) - nach Misc, vor Jewelry
		if aPriority and aPriority >= -9 and aPriority <= -1 then
			if bPriority and bPriority >= -9 and bPriority <= -1 then
				return aPriority < bPriority
			else
				return true
			end
		elseif bPriority and bPriority >= -9 and bPriority <= -1 then
			return false
		end
		
		-- Jewelry nach hoher Priorität
		if a.categoryName == "Jewelry" then
			return true
		elseif b.categoryName == "Jewelry" then
			return false
		end
		
		-- Niedrige Priorität (1 bis 9) - nach Jewelry, vor normalem Level-Sort
		if aPriority and aPriority >= 0 and aPriority <= 9 then
			if bPriority and bPriority >= 0 and bPriority <= 9 then
				return aPriority < bPriority
			else
				return true
			end
		elseif bPriority and bPriority >= 0 and bPriority <= 9 then
			return false
		end
		
		-- Sehr niedrige Priorität (10 und höher) - wird im Level-Sort behandelt
		-- Hier modifizieren wir das averageLevel für die Sortierung
		local aLevel = a.averageLevel
		local bLevel = b.averageLevel
		
		-- Für Priorität >= 10: Jede 10er-Stufe = +1 Level
		if aPriority and aPriority >= 10 then
			aLevel = aLevel + math.floor(aPriority / 10)
		end
		if bPriority and bPriority >= 10 then
			bLevel = bLevel + math.floor(bPriority / 10)
		end
		
		-- Rest nach modifiziertem averageLevel
		return aLevel < bLevel
	end)
	
	for i, category in ipairs(sortedCategories) do
		local cleanName = category.categoryName:match("^{%-?%d+}%s*(.+)")
		if not cleanName then
			cleanName = category.categoryName:match("^%[%-?%d+%]%s*(.+)")
		end
		if cleanName then
			category.categoryName = cleanName
		end
	end
	return sortedCategories
end

-- Hilfsfunktion für String trimming
function trim(str)
	return str:match("^%s*(.-)%s*$")
end

-- Ausgabe-Funktion
function printCategories(categories)
	print("categories = {")
	for i, category in ipairs(categories) do
		print("\t{")
		print(string.format('\t\tcategoryName = "%s",', category.categoryName))
		print('\t\trecipes = {')
		
		for j, recipe in ipairs(category.recipes) do
			if #recipe.ingredients >0 and recipe.level then
				print(string.format('\t\t\t{'))
				print(string.format('\t\t\t\ttype = "%s",', recipe.type))
				print(string.format('\t\t\t\tid = "%s",', recipe.id))
				print(string.format('\t\t\t\tcount = %d,', recipe.count))
				print(string.format('\t\t\t\tlevel = %d,', recipe.level))
				if recipe.faction then
					print("\t\t\t\t"..recipe.faction)
					print(string.format('\t\t\t\tfactionRank = %d,', recipe.factionRank))
				end
				print('\t\t\t\tingredients = {')
				
				for k, ingredient in ipairs(recipe.ingredients) do
					local comma = k < #recipe.ingredients and "," or ""
					if ingredient.type == "wildcard" then
						print(string.format('\t\t\t\t\t{ type = "%s", func = %s, count = %d}%s', 
							ingredient.type, tostring(ingredient.func), ingredient.count, comma))
					else
						print(string.format('\t\t\t\t\t{ type = "%s", id = "%s", count = %d}%s', 
							ingredient.type, ingredient.id, ingredient.count, comma))
					end
				end
				
				local recipeComma = j < #category.recipes and "," or ""
				print('\t\t\t\t}')
				print('\t\t\t}' .. recipeComma)
			end
		end
		
		local categoryComma = i < #categories and "," or ""
		print('\t\t}')
		print('\t}' .. categoryComma)
	end
	print("}")
end

-- Hauptlogik: Mehrere Dateien laden und zusammenführen
local allCategories = {}

for filename in vfs.pathsWithPrefix("CF_recipes/") do
	if filename:match("%.lua$") then
		print("Loading file: " .. filename)
		local tsvData = require(filename:sub(1,-5)) --remove extension
		if tsvData then
			local fileCategories = parseRecipes(tsvData)
			mergeCategories(allCategories, fileCategories)
			print("Merged categories from " .. filename)
		end
	end
end

for filename in vfs.pathsWithPrefix("CF_recipes/") do
	if filename:match("%.txt$") then
		print("Loading file: " .. filename)
		local file, errorMsg = vfs.open(filename)
		if file then
			local tsvData = file:read("*all")
			file:close()
			
			if tsvData and tsvData ~= "" then
				local fileCategories = parseRecipes(tsvData)
				mergeCategories(allCategories, fileCategories)
			else
				print("Warning: Empty or invalid data in " .. filename)
			end
		else
			print("Error opening file " .. filename .. ": " .. (errorMsg or "unknown error"))
		end
	end
end

-- Categories für Ausgabe sortieren
local sortedCategories = sortCategories(allCategories)

--printCategories(sortedCategories)
--print(#sortedCategories, sortedCategories[1])
return sortedCategories