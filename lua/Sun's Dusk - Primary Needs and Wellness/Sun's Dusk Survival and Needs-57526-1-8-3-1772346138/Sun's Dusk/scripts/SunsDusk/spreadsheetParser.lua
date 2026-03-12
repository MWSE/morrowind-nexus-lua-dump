--[[
╭───────────────────────────────────────────────────────────────────╮
│ Sun's Dusk - mommy's Spreadsheet / TSV Parser						│
│ Food / Drink / Wake / Warmth values								│
╰───────────────────────────────────────────────────────────────────╯
]]

dbConsumables = {}

local spellDiffs = {
	["summonghost"] = "summonancestralghost",
	["summontwilight"] = "summonwingedtwilight",
	["summonskeleton"] = "summonskeletalminion",
	["weaknesstocorprus"] = "weaknesstocorprusdisease",
	["resistcorprus"] = "resistcorprusdisease",
	["fortifymagickamultiplier"] = "fortifymaximummagicka",
	["summonleastmonewalker"] = "summonbonewalker",
	["curecorprus"] = "curecorprusdisease",
	["fortifyattackbonus"] = "fortifyattack",
	["restore stamina"] = "restorefatigue",
	["restore health"] = "restorehealth",
}

--local function getItemType(id)
--	if not id then
--		return nil
--	end
--	id = id:lower()
--
--	if types.Ingredient.records[id] then
--		return "Ingredient"
--	end
--
--	if types.Miscellaneous.records[id] then
--		return "Miscellaneous"
--	end
--
--	if types.Potion.records[id] then
--		return "Potion"
--	end
--
--	return nil
--end
-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Core TSV parser													│
-- ╰────────────────────────────────────────────────────────────────────╯

local function parseRecipes(tsvContent)
	-- Daten parsen
	for line in tsvContent:gmatch("[^\r\n]+") do
		-- Iterator-based field extraction with early bailout
		local f = (line .. "\t"):gmatch("([^\t]*)\t")
		
		local recordType = (f() or ""):lower()
		if recordType == "alchemy" then recordType = "potion" end
		recordType = recordType:gsub("^%l", string.upper)
		
		local recordId = (f() or ""):lower()
		
		-- Early bailout if record doesn't exist
		if not (types[recordType] and types[recordType].records[recordId]) then
			goto continue
		end
		
		f() f() -- skip fields 3-4
		dbConsumables[recordId] = {
			recordType      = recordType,
			consumeCategory = (f() or ""):lower(),
			foodValue       = (tonumber(f()) or 0)/200,
			drinkValue      = (tonumber(f()) or 0)/200,
			wakeValue       = (tonumber(f()) or 0)/200,
			warmthValue     = (tonumber(f()) or 0),
			isToxic         = (f() or ""):lower() == "true",
			isGreenPact     = (f() or ""):lower() == "true",
			isCookedMeal    = (f() or ""):lower() == "true",
		}
		-- Fields requiring conditional transforms
		local t = dbConsumables[recordId]
		local ingredientClass = (f() or ""):lower()
		if ingredientClass ~= "" then
			t.ingredientClass = ingredientClass
		else
			goto continue
		end
		t.ingredientRank = tonumber(f()) or 1
		f() -- skip field 15
		local e = (f() or ""):lower()
		t.alchEffect1 = e ~= "" and (spellDiffs[e] or e) or nil
		e = (f() or ""):lower()
		t.alchEffect2 = e ~= "" and (spellDiffs[e] or e) or nil
		e = (f() or ""):lower()
		t.alchEffect3 = e ~= "" and (spellDiffs[e] or e) or nil
		
		::continue::
	end
end

for filename in vfs.pathsWithPrefix("SD_food_and_drinks/") do
	if filename:match("%.txt$") and not filename:match("/%._") then
		local file, errorMsg = vfs.open(filename)
		if file then
			log(5, "[SD] Loading file: " .. filename)
			local tsvData = file:read("*all")
			parseRecipes(tsvData)
			file:close()
			tsvData = nil
		end
	end
end
