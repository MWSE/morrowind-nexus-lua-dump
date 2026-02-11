--[[
╭───────────────────────────────────────────────────────────────────╮
│ Sun's Dusk - Statics / Interactables Parser                       │
│ Heat Sources / Cooking Spots / Wells / Woodcutting                │
╰───────────────────────────────────────────────────────────────────╯

TSV Format:
RecordID	StaticType	Allow	P1	P2	P3	P4	P5	P6	P7	P8	P9	P10

Columns with '=' are parsed as key=value, others use positional mapping:
light_torch_01	heatsource	true	500	temperatureMod=6	2	ignoresMaxTemp=true

RecordType is auto-detected from game data.
StaticType (heatsource, well, woodcutting, etc.) becomes the key for the data subtable.

World Object References:
Use & prefix with contentfile/refnum for specific placed objects.
TSV:     &morrowind.esm/1f7c4	heatsource	true	500
Parsed via core.getFormId() to get object.id for runtime lookup: dbStatics[object.id]

Schema rows define field names for custom StaticTypes (columns 2-3 left blank):
@alientech			powerLevel	radiationType	stability

Known StaticTypes and their param mappings:
  heatsource:  P1=radius, P2=temperatureMod, P3=comfort, P4=ignoresMaxTemp
  cookingspot: (no named params)
  well:        P1=waterType
  woodcutting: P1=treeSize

Extra params beyond named fields become numeric indices [n].
Unknown StaticTypes get all params as numeric indices [1]-[10].
]]

dbStatics = {}

local core = require('openmw.core')

--local function log(_, ...)
--	print(...)
--end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Record type detection                                              │
-- │ Ordered list for predictable lookup (common types first)           │
-- ╰────────────────────────────────────────────────────────────────────╯

local typeSearchOrder = {}

-- Add priority types (if they exist)
for _, typeName in ipairs({ "Static", "Activator", "Light", "NPC", "Creature" }) do
	if types[typeName] and types[typeName].records then
		table.insert(typeSearchOrder, typeName)
	end
end

-- Add remaining types
for typeName, typeTable in pairs(types) do
	local found = false
	for _, existing in ipairs(typeSearchOrder) do
		if existing == typeName then
			found = true
			break
		end
	end
	if not found and typeTable.records and typeName:lower():sub(1,4) ~= "esm4" then
		table.insert(typeSearchOrder, typeName)
	end
end

local function findRecordType(id)
	if not id then return nil end
	id = id:lower()
	
	for _, recordType in ipairs(typeSearchOrder) do
		if types[recordType].records[id] then
			return recordType
		end
	end
	
	return nil
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ StaticType field mappings                                          │
-- │ Named fields are mapped first, extra params become [n] indices     │
-- │ Modders: add your own StaticTypes here or use @schema rows in TSV  │
-- ╰────────────────────────────────────────────────────────────────────╯

local staticTypeFields = {
	heatsource = {"radius", "temperatureMod", "comfort", "ignoresMaxTemp"},
	cookingspot = {},
	well = {"liquidType"},
	woodcutting = {"treeSize"},
}

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Value parsing helpers                                              │
-- ╰────────────────────────────────────────────────────────────────────╯

local function parseValue(str)
	if str == nil or str == "" then
		return nil
	end
	
	local lower = str:lower()
	if lower == "true" then return true end
	if lower == "false" then return false end
	
	local num = tonumber(str)
	if num then return num end
	
	return str
end

local function parseKeyValue(str)
	if str == nil or str == "" then
		return nil, nil
	end
	
	local key, val = str:match("^([^=]+)=(.*)$")
	if key then
		return key, parseValue(val)
	end
	
	return nil, nil
end

local function trim(str)
	return str:match("^%s*(.-)%s*$")
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Core TSV parser                                                    │
-- ╰────────────────────────────────────────────────────────────────────╯

local function parseStatics(tsvContent)
	local lines = {}

	for line in tsvContent:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	for i = 1, #lines do
		local line = lines[i]

		if line and trim(line) ~= "" then
			-- Remove comments (everything after #)
			line = line:match("^[^#]*")
			
			-- Split by tabs
			local fields = {}
			local temp = line .. "\t"
			temp:gsub("([^\t]*)\t", function(field)
				table.insert(fields, field)
				return ""
			end)

			-- Check for schema definition: @staticType			field1	field2	...
			if fields[1] and fields[1]:match("^@") then
				local staticType = fields[1]:sub(2):lower()
				local fieldNames = {}
				for j = 4, 13 do
					local name = fields[j] and trim(fields[j]) or ""
					if name ~= "" then
						table.insert(fieldNames, name:lower())
					end
				end
				staticTypeFields[staticType] = fieldNames
				log(6, "[SD] Schema defined: " .. staticType .. " = {" .. table.concat(fieldNames, ", ") .. "}")

			-- Skip header and comments
			elseif not fields[1]:match("^RecordID") and not fields[1]:match("^#") then
				local rawId       = fields[1] or ""
				local staticType  = (fields[2] or ""):lower()
				local allow       = (fields[3] or ""):lower() ~= "false"

				-- Check for world object reference: &contentfile/refnum
				local contentFile, refNum = rawId:match("^&([^/]+)/(%x+)$")
				local recordId, recordType

				if contentFile and refNum then
					-- World object reference - convert to object.id via core.getFormId
					local formId = core.getFormId(contentFile, tonumber(refNum))
					if formId then
						recordId = formId:sub(8)
						--if world then ...
						--recordType = tostring(object.type)
						--print(formId, recordId, recordType)
					else
						log(6, "[SD] skipped invalid formId: " .. rawId)
					end
				else
					-- Base record - validate against game data
					recordId = rawId:lower()
					recordType = findRecordType(recordId)
					if not (recordType and types[recordType] and types[recordType].records[recordId]) then
						if staticType ~= "" and recordId ~= "" then
							log(6, "[SD] skipped unknown id: " .. recordId .. " (type: " .. tostring(recordType) .. ")")
						end
						recordId = nil
					end
				end

				if staticType ~= "" and recordId then
					if not dbStatics[recordId] then
						dbStatics[recordId] = {}
					end

					dbStatics[recordId].recordType = recordType

					if not allow then
						dbStatics[recordId][staticType] = false
						log(6, "[SD] " .. rawId .. "." .. staticType .. " = blocked")
					else
						local data = dbStatics[recordId][staticType]
						if not data or data == false then
							data = {}
						end

						local fieldNames = staticTypeFields[staticType]
						local numNamedFields = fieldNames and #fieldNames or 0

						-- Process each column individually
						for j = 1, 10 do
							local raw = fields[3 + j] or ""
							local key, val = parseKeyValue(raw)
							
							if key and val ~= nil then
								-- Has '=' - use as key=value
								data[key] = val
							else
								-- No '=' - use positional mapping
								local val = parseValue(raw)
								if val ~= nil then
									if fieldNames and j <= numNamedFields then
										data[fieldNames[j]] = val
									else
										data[j] = val
									end
								end
							end
						end

						dbStatics[recordId][staticType] = data

						local debugParts = {}
						for k, v in pairs(data) do
							table.insert(debugParts, tostring(k) .. "=" .. tostring(v))
						end
						log(6, "[SD] " .. rawId .. "." .. staticType .. " = {" .. table.concat(debugParts, ", ") .. "}")
					end
				end
			end
		end
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Load all TSV files                                                 │
-- ╰────────────────────────────────────────────────────────────────────╯

for filename in vfs.pathsWithPrefix("SD_statics/") do
	if filename:match("%.txt$") and not filename:match("/%._") then
		local file, errorMsg = vfs.open(filename)
		if file then
			log(5, "[SD] Loading statics file: " .. filename)
			local tsvData = file:read("*all")
			parseStatics(tsvData)
			file:close()
		else
			log(3, "[SD] Error opening file " .. filename .. ": " .. (errorMsg or "unknown error"))
		end
	end
end