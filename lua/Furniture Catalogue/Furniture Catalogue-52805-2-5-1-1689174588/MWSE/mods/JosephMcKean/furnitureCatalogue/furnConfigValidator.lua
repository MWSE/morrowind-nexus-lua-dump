-- This is the validator for the furniture recipes,
-- 
-- mainly to:
-- 
--  Lowercase id and newId
--  Delete the deplicate recipe
--  Auto generate newIds
--      Check if the newId is shorter than 32 characters
--  Check if there is any carryable object included
--
-- then returns the total recipe count
--
-- This can be run directly from the terminal: 
-- $ cd mods
-- $ lua54 JosephMcKean/furnitureCatalogue/furnConfigValidator.lua
-- 
-- This will also run when Morrowind initialized
--
print("Reading furnConfig...")
local furnConfig = io.input("JosephMcKean\\furnitureCatalogue\\furnConfig.lua")
if not furnConfig then return end

print("Creating new furnConfig...")
local newFurnConfig = io.output("JosephMcKean\\furnitureCatalogue\\furnConfigNew.lua")
if not newFurnConfig then return end

-- Converts id and newId to lowercased
---@param line string 
---@param id string
---@param newId string
---@return string
local function lowerIds(line, id, newId)
	---@param match string?
	local function lower(match)
		if not match then return end
		local lowered = match:lower()
		if match ~= lowered then print("Lowercasing id", match, "to", lowered) end
		return lowered
	end
	line = line:gsub(id, lower) -- lower id
	line = line:gsub(newId, lower) -- lower newId
	return line
end

local furnitureList = {}

---@param index string
---@param id string
---@return boolean
local function checkForDuplicate(index, id)
	if furnitureList[id] then
		print("Found duplicate", id, furnitureList[id], index)
		return true
	end
	furnitureList[id] = index
	return false
end

---@param line string 
---@param id string
---@param newId string
---@return string
local function generateNewId(line, id, newId)
	---@param match string?
	local function jsmkify(match)
		if not match then return end
		local idLen = id:len()
		local prefix = "jsmk_fc_"
		local prefixLen = prefix:len()
		local maxLen = 31
		local subLen = idLen + prefixLen - maxLen
		local subbedId = ""
		local subbedLen = 0

		---@return string
		local function subUnderScore()
			subbedId, subbedLen = id:gsub("_", "", subLen)
			newId = prefix .. subbedId
			if subbedLen < subLen then
				subLen = subLen - subbedLen
				newId = prefix:sub(1, prefixLen - subLen) .. subbedId
			end
			return newId
		end

		newId = prefix .. id
		if newId:len() > maxLen then
			newId = subUnderScore()

			if newId:len() > maxLen then print("newId", newId, "too long") end
		end

		return newId
	end
	line = line:gsub(newId, jsmkify, 1) -- lower newId
	return line
end

while true do
	-- Typically a line of furnConfig looks like this
	--
	-- ```Lua
	-- ["067"] = { id = "barrel_02", newId = "jsmk_fc_barrel_02", name = "Barrel", category = "Containers", cost = 40 }, -- MW
	-- ```
	local line = io.read()
	if not line then break end
	local index = line:match("%[\"(.*)\"%] =")
	local id = line:match("id = \"(.*)\", newId")
	local newId = line:match("newId = \"(.*)\", name")
	local isDuplicate = false
	if id then
		line = lowerIds(line, id, newId)
		isDuplicate = checkForDuplicate(index, id)
		line = generateNewId(line, id, newId)
	end
	if not isDuplicate then newFurnConfig:write(line .. "\n") end
end
io.close()

print("New furnConfig created.")
