local jsonParser = require("scripts.CraftingFramework.parsers.jsonParser")
local tsvParser = require("scripts.CraftingFramework.parsers.tsvParser")
local yamlParser = require("scripts.CraftingFramework.parsers.yamlParser")
local luaParser = require("scripts.CraftingFramework.parsers.luaParser")

usedUids = {}

ingredientExpMultipliers = {
	["ingred_bonemeal_01"] = 0.75,
	["ingred_scrap_metal_01"] = 1.2,
}

-- TSV-only material aliases
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
	["fire petal"] = "ingred_fire_petal_01",
	["dreugh wax"] = "ingred_dreugh_wax_01",
	["petty soul gem"] = "Misc_SoulGem_Petty",
	["lesser soul gem"] = "Misc_SoulGem_Lesser",
	["common soul gem"] = "Misc_SoulGem_Common",
	["greater soul gem"] = "Misc_SoulGem_Greater",
	["grand soul gem"] = "Misc_SoulGem_Grand",
	["alit hide"] = "ingred_alit_hide_01",
}

-- category aliases keyed off the recipe's material field
categoryMapping = {
}

function mergeCategories(targetCategories, sourceCategories)
	for categoryName, recipes in pairs(sourceCategories) do
		if not targetCategories[categoryName] then
			targetCategories[categoryName] = {}
		end
		-- duplicates are allowed: recipe.uid disambiguates
		for _, recipe in ipairs(recipes) do
			table.insert(targetCategories[categoryName], recipe)
		end
	end
end

function mergeProfessions(targetProfessions, sourceProfessions)
	for professionName, categories in pairs(sourceProfessions) do
		if not targetProfessions[professionName] then
			targetProfessions[professionName] = {}
		end
		mergeCategories(targetProfessions[professionName], categories)
	end
end

-- stamp source filename, stripped past last cf_recipes/
local function tagSource(professions, filename)
	local stripped = filename:match(".*[Cc][Ff]_[Rr][Ee][Cc][Ii][Pp][Ee][Ss]/(.*)$") or filename
	for _, categories in pairs(professions) do
		for _, recipes in pairs(categories) do
			for _, recipe in ipairs(recipes) do
				recipe.sourceFile = stripped
			end
		end
	end
end

function sortCategories(categories)
	local sortedCategories = {}
	for categoryName, recipes in pairs(categories) do
		-- armor before weapon, then by level, then by name
		table.sort(recipes, function(a, b)
			if a.type ~= b.type then
				if a.type == "Armor" and b.type == "Weapon" then
					return true
				elseif a.type == "Weapon" and b.type == "Armor" then
					return false
				else
					return a.type < b.type
				end
			end
			if a.level == b.level then
				return (a.displayName) < (b.displayName)
			end
			return a.level < b.level
		end)

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

	-- categoryName may carry a "{N}" priority prefix:
	--   <= -20  pinned to top
	--   "Ammo" comes next, then -10..-19
	--   "Misc" / misc* comes next
	--   -1..-9 then "Jewelry" then 0..9
	--   >= 10   sorted by averageLevel + floor(priority/10)
	table.sort(sortedCategories, function(a, b)
		local aPriority = a.categoryName:match("^{(%-?%d+)}")
		local bPriority = b.categoryName:match("^{(%-?%d+)}")
		aPriority = aPriority and tonumber(aPriority) or nil
		bPriority = bPriority and tonumber(bPriority) or nil

		if aPriority and aPriority <= -20 then
			if bPriority and bPriority <= -20 then
				return aPriority < bPriority
			else
				return true
			end
		elseif bPriority and bPriority <= -20 then
			return false
		end

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
		if a.categoryName == "Misc" then
			return true
		elseif b.categoryName == "Misc" then
			return false
		end

		if a.categoryName:lower():sub(1, 4) == "misc" then
			return true
		elseif b.categoryName:lower():sub(1, 4) == "misc" then
			return false
		end

		if aPriority and aPriority >= -9 and aPriority <= -1 then
			if bPriority and bPriority >= -9 and bPriority <= -1 then
				return aPriority < bPriority
			else
				return true
			end
		elseif bPriority and bPriority >= -9 and bPriority <= -1 then
			return false
		end

		if a.categoryName == "Jewelry" then
			return true
		elseif b.categoryName == "Jewelry" then
			return false
		end

		if aPriority and aPriority >= 0 and aPriority <= 9 then
			if bPriority and bPriority >= 0 and bPriority <= 9 then
				return aPriority < bPriority
			else
				return true
			end
		elseif bPriority and bPriority >= 0 and bPriority <= 9 then
			return false
		end

		local aLevel = a.averageLevel
		local bLevel = b.averageLevel
		if aPriority and aPriority >= 10 then
			aLevel = aLevel + math.floor(aPriority / 10)
		end
		if bPriority and bPriority >= 10 then
			bLevel = bLevel + math.floor(bPriority / 10)
		end
		return aLevel < bLevel
	end)

	-- strip the {N} or [N] priority prefix from the visible name
	for i, category in ipairs(sortedCategories) do
		local cleanName = category.categoryName:match("^{%-?%d+}%s*(.+)")
		if not cleanName then
			cleanName = category.categoryName:match("^%[%-?%d+%]%s*(.+)")
		end
		if cleanName then
			category.categoryName = cleanName
		end
		-- stamp category onto each recipe
		for _, recipe in ipairs(category.recipes) do
			recipe.category = category.categoryName
		end
	end
	return sortedCategories
end

function trim(str)
	return str:match("^%s*(.-)%s*$")
end

function printCategories(categories)
	print("categories = {")
	for i, category in ipairs(categories) do
		print("\t{")
		print(string.format('\t\tcategoryName = "%s",', category.categoryName))
		print('\t\trecipes = {')

		for j, recipe in ipairs(category.recipes) do
			if #recipe.ingredients > 0 and recipe.level then
				print(string.format('\t\t\t{'))
				print(string.format('\t\t\t\ttype = "%s",', recipe.type))
				print(string.format('\t\t\t\tid = "%s",', recipe.id))
				print(string.format('\t\t\t\tcount = %d,', recipe.count))
				print(string.format('\t\t\t\tlevel = %d,', recipe.level))
				if recipe.faction then
					print("\t\t\t\t" .. recipe.faction)
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

allProfessions = {}

-- gather cf_recipes/ files from vfs
local recipeFilenames = {}
for filename in vfs.pathsWithPrefix("") do
	local lower = filename:lower()
	if lower:sub(1, 11) == "cf_recipes/" or lower:find("/cf_recipes/", 1, true) then
		table.insert(recipeFilenames, filename)
	end
end

-- zzz-prefixed lua files load last so they can override anything
local luaRecipes = {}
local deferredLuaFilenames = {}
for _, filename in ipairs(recipeFilenames) do
	if filename:match("%.lua$") then
		local basename = filename:match("([^/]+)$")
		if basename and basename:lower():sub(1, 3) == "zzz" then
			table.insert(deferredLuaFilenames, filename)
		else
			local ok, data = pcall(require,filename:sub(1, -5))
			if ok then
				table.insert(luaRecipes, { data = data, filename = filename })
			else
				print("\27[91m ERROR in "..filename..": "..tostring(data))
			end
		end
	end
end

for _, entry in ipairs(luaRecipes) do
	local data = entry.data
	local fileProfessions
	if type(data) == "table" then
		fileProfessions = luaParser(data)
	elseif type(data) == "string" then
		fileProfessions = tsvParser(data, false)
	end
	if fileProfessions then
		tagSource(fileProfessions, entry.filename)
		mergeProfessions(allProfessions, fileProfessions)
	end
end

for _, filename in ipairs(recipeFilenames) do
	if filename:match("%.txt$") or filename:match("%.tsv$") then
		local file, errorMsg = vfs.open(filename)
		if file then
			local tsvData = file:read("*all")
			file:close()

			if tsvData and tsvData ~= "" then
				local fileProfessions = tsvParser(tsvData, true)
				tagSource(fileProfessions, filename)
				mergeProfessions(allProfessions, fileProfessions)
			else 
			--	print("Warning: Empty or invalid data in " .. filename)
			end
		else
			print("Error opening file " .. filename .. ": " .. (errorMsg or "unknown error"))
		end
	end

	if filename:match("%.json$") then
		local file, errorMsg = vfs.open(filename)
		if file then
			local json = file:read("*all")
			file:close()

			if json and json ~= "" then
				local fileProfessions = jsonParser(json)
				tagSource(fileProfessions, filename)
				mergeProfessions(allProfessions, fileProfessions)
			else
				print("Warning: Empty or invalid json data in " .. filename)
			end
		else
			print("Error opening file " .. filename .. ": " .. (errorMsg or "unknown error"))
		end
	end
	if filename:match("%.ya?ml$") then
		local file = vfs.open(filename)
		if file then
			local yaml = file:read("*all")
			file:close()
			if yaml and yaml ~= "" then
				local fileProfessions = yamlParser.parseYamlRecipes(yaml)
				tagSource(fileProfessions, filename)
				mergeProfessions(allProfessions, fileProfessions)
			end
		end
	end
end

-- allProfessions is global so deferred (zzz) lua files can modify it
for _, filename in ipairs(deferredLuaFilenames) do
	local ok, data = pcall(require, filename:sub(1, -5))
	if ok then
		local fileProfessions
		if type(data) == "table" then
			fileProfessions = luaParser(data)
		elseif type(data) == "string" then
			fileProfessions = tsvParser(data)
		end
		if fileProfessions then
			tagSource(fileProfessions, filename)
			mergeProfessions(allProfessions, fileProfessions)
		end
	else
		print("\27[91m ERROR in "..filename..": "..tostring(data))
	end
end

-- collect unique sourceFiles and skills for MCM dynamic groups
local fileSet = {}
local skillSet = {}
for _, categories in pairs(allProfessions) do
	for c, recipes in pairs(categories) do
		for _, recipe in ipairs(recipes) do
			if recipe.sourceFile then
				fileSet[recipe.sourceFile] = true
			end
			if recipe.skill then
				skillSet[recipe.skill] = true
			end
			if recipe.secondSkill then
				skillSet[recipe.secondSkill] = true
			end
		end
	end
end

allSourceFiles = {}
for f in pairs(fileSet) do table.insert(allSourceFiles, f) end
table.sort(allSourceFiles)

allDetectedSkills = {}
for s in pairs(skillSet) do table.insert(allDetectedSkills, s) end
table.sort(allDetectedSkills)

if registerDynamicExpMults then
	registerDynamicExpMults(allSourceFiles, allDetectedSkills)
end

local sortedProfessions = {}
for professionName, categories in pairs(allProfessions) do
	sortedProfessions[professionName] = sortCategories(categories)
end

return sortedProfessions