local fileHelper = require("tauer.dynamic-conversations.services.files.fileHelper")
local FILE_TYPE = require("tauer.dynamic-conversations.services.files.enums.FILE_TYPE")

--- A generic loader for rules defined in Lua files
---@class ruleLoader
local this = {}

--- Loads all rules from the specified directory
---@public
---@param directory string The relative path to the directory containing the rule files
---@return rule[] rules The loaded rules
function this.loadRules(directory)
	local fullPath = string.format("data files\\mwse\\mods\\tauer\\dynamic-conversations\\%s", directory)

	local rules = {}

	local files = fileHelper.getAllFilesInDirectory(fullPath, FILE_TYPE.lua)
	if not files then
		return rules
	end

	for _, file in pairs(files) do
		local rule = this.loadRule(file, directory)
		table.insert(rules, rule)
	end

	return rules
end

---@private
---@param fileName string
---@param directory string
---@return rule
function this.loadRule(fileName, directory)
	local ruleName = fileName:gsub(".lua", "")
	local basePath = string.format("tauer.dynamic-conversations.%s", directory:gsub("\\", "."))

	---@type rule
	local rule = require(string.format("%s.%s", basePath, ruleName))
	rule.name = ruleName

	return rule
end

return this
