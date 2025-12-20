--[[
╭───────────────────────────────────────────────────────────────────╮
│ Sun's Dusk - mommy's Spreadsheet / TSV Parser						│
│ Food / Drink / Wake / Warmth values								│
╰───────────────────────────────────────────────────────────────────╯
]]

dbConsumables = {}

local spellDiffs = {
	["SummonGhost"] = "summonancestralghost",
	["SummonTwilight"] = "summonwingedtwilight",
	["SummonSkeleton"] = "summonskeletalminion",
	["WeaknessToCorprus"] = "weaknesstocorprusdisease",
	["ResistCorprus"] = "resistcorprusdisease",
	["FortifyMagickaMultiplier"] = "fortifymaximummagicka",
	["SummonLeastBonewalker"] = "summonbonewalker",
	["CureCorprus"] = "curecorprusdisease",
	["FortifyAttackBonus"] = "fortifyattack",
	["Restore Stamina"] = "restorefatigue",
	["Restore Health"] = "restorehealth",
}

local function getItemType(id)
	if not id then
		return nil
	end
	id = id:lower()

	if types.Ingredient.records[id] then
		return "Ingredient"
	end

	if types.Miscellaneous.records[id] then
		return "Miscellaneous"
	end

	if types.Potion.records[id] then
		return "Potion"
	end

	return nil
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Core TSV parser													│
-- ╰────────────────────────────────────────────────────────────────────╯

local function parseRecipes(tsvContent)
	local lines = {}

	for line in tsvContent:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	-- Daten parsen
	for i = 1, #lines do
		local line = lines[i]

		if line
			and trim(line) ~= ""
			and line:sub(1, #"Raw data from ") ~= "Raw data from "
			and line:sub(1, #"Item Type\tItem ID") ~= "Item Type\tItem ID"
		then

			-- Split by tabs without allocating per-char in a loop body
			local fields = {}
			local temp = line .. "\t"
			temp:gsub("([^\t]*)\t", function(field)
				table.insert(fields, field)
				return ""
			end)
			
			-- Felder extrahieren
			local recordType = (fields[1] or ""):lower()
			if recordType == "alchemy" then
				recordType = "potion"
			end
			
			recordType = recordType:gsub("^%l", string.upper)
			local recordId = (fields[2] or ""):lower()
			
			local record = types[recordType] and types[recordType].records[recordId:lower()]
			
			--print(inGameLabel)			
			--	local dataSource = 	
			local consumeCategory	  	= (fields[5] or ""):lower()
			local foodValue 		  	= tonumber(fields[6]) or 0
			local drinkValue		  	= tonumber(fields[7]) or 0
			local wakeValue 		  	= tonumber(fields[8]) or 0	
			local warmthValue 		  	= tonumber(fields[9]) or 0	
			local isToxic				= (fields[10] or ""):lower()=="true"
			local isGreenPact   		= (fields[11] or ""):lower()=="true"
			local isCookedMeal 			= (fields[12] or ""):lower()=="true"
			local ingredientClass		= (fields[13] or ""):lower()
			if ingredientClass == "" then
				ingredientClass = nil
			end
			local ingredientRank		= tonumber(fields[14]) or 1
			local alchEffect1			= fields[16] and fields[16] ~= "" and (spellDiffs[fields[16]] or fields[16]:lower()) or nil
			local alchEffect2			= fields[17] and fields[17] ~= "" and (spellDiffs[fields[17]] or fields[17]:lower()) or nil
			local alchEffect3			= fields[18] and fields[18] ~= "" and (spellDiffs[fields[18]] or fields[18]:lower()) or nil
					
			-- --alchEffect1 = "Restore Health"
			-- if spellDiffs[alchEffect1] then
			-- 	alchEffect1 = spellDiffs[alchEffect1]
			-- else -- not in lookup table
			-- 	alchEffect1 = alchEffect1:lower()
			-- end
			-- if alchEffect1 == "" then
			-- 	alchEffect1 = nil
			-- end
			
			if record then
				dbConsumables[recordId] = {
					recordType			= recordType, 
					--localizedName		= types[recordType].records[recordId:lower()].name, 
					consumeCategory		= consumeCategory, 
					foodValue			= foodValue, 
					drinkValue			= drinkValue, 
					wakeValue			= wakeValue,
					warmthValue			= warmthValue,
					isToxic				= isToxic,
					isGreenPact			= isGreenPact,
					isCookedMeal		= isCookedMeal,
					ingredientClass		= ingredientClass,
					ingredientRank		= ingredientRank,
					alchEffect1			= alchEffect1,
					alchEffect2			= alchEffect2,
					alchEffect3			= alchEffect3,
				}
				local debugString = recordId.." = {"
				for a,b in pairs(dbConsumables[recordId]) do
					debugString = debugString..a.." = "..recordType..", "
				end
				debugString = debugString:sub(1, -3).."}"
				log(6, debugString)
			else
				log(6, "skipped unknown id: " .. tostring(recordId) .. " (type: " .. recordType .. ")")
			end
		end
	end
end						

function trim(str)
	return str:match("^%s*(.-)%s*$")
end

for filename in vfs.pathsWithPrefix("SD_food_and_drinks/") do
	if filename:match("%.txt$") then
		local file, errorMsg = vfs.open(filename)
		if file then
			log(5, "[SD] Loading file: " .. filename)
			local tsvData = file:read("*all")
			parseRecipes(tsvData)
			file:close()
		else
			log(3, "[SD] Error opening file " .. filename .. ": " .. (errorMsg or "unknown error"))
		end
	end
end