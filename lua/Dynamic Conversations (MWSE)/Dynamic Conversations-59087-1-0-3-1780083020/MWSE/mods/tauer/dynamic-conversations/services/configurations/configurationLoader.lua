local configurationValidator = require("tauer.dynamic-conversations.services.configurations.configurationValidator")

local logger = mwse.Logger.new()

--- Loads conversation configurations from JSON files
---@class configurationLoader : initializedService
local this = {}

---@private
---@type string
this.configurationsBasePath = "data files\\mwse\\config\\Dynamic Conversations\\conversations\\"

---@private
---@type {[conversationId]: conversationConfiguration}
this.configurations = {}

---@public
---@return boolean
function this.initialize()
	this.loadAll()
	return true
end

--- Retrieves all loaded conversation configurations
--- @public
--- @return {[conversationId]: conversationConfiguration} configurations A dictionary of all loaded conversation configurations with their IDs as keys
function this.getAll()
	return this.configurations
end

--- Loads a specific conversation configuration by its ID
--- @public
--- @param configurationId conversationId The ID of the conversation configuration to load
--- @return conversationConfiguration|nil configuration The loaded conversation configuration, or nil if not found
function this.get(configurationId)
	return this.configurations[configurationId]
end

--- Loads a single conversation configuration from a specified file path. This file does not need to be in the standard configurations directory.
---@public
---@param path filePath The file path of the conversation configuration to load
---@return conversationConfiguration|nil configuration The loaded conversation configuration, or nil if not found or invalid
function this.loadConfiguration(path)
	local configuration = mwse.loadConfig(path)
	if configuration and this.validate(path, configuration) then
		return this.postProcessConfiguration(path, configuration)
	end
end

---@private
function this.loadAll()
	local paths = this.recursiveGetPaths(this.configurationsBasePath)
	if not paths then
		return {}
	end

	for _, file in pairs(paths) do
		local configuration = this.load(file)
		if configuration then
			this.configurations[configuration.id] = configuration
		end
	end
end

---@private
---@param currentPath string
---@param prefix? string
---@param filePaths? string[]
---@return string[]|nil
function this.recursiveGetPaths(currentPath, prefix, filePaths)
	local paths = filePaths or {}
	local pathPrefix = prefix or ""

	for fileOrDirectory in lfs.dir(currentPath) do
		if fileOrDirectory ~= "." and fileOrDirectory ~= ".." then
			local fullPath = currentPath .. fileOrDirectory

			local attribute = lfs.attributes(fullPath)
			if not attribute then
				logger:error(string.format("Could not get attributes for file '%s'", fullPath))
				return nil
			end

			if attribute.mode == "directory" then
				this.recursiveGetPaths(fullPath .. "\\", pathPrefix .. fileOrDirectory .. "\\", paths)
			else
				table.insert(paths, pathPrefix .. fileOrDirectory)
			end
		end
	end

	return paths
end

---@private
---@param configurationPath string
---@return string
function this.getConfigurationPathWithoutExtension(configurationPath)
	local pathWithoutExtension = string.gsub(configurationPath, ".json", "")
	return string.format("Dynamic Conversations\\conversations\\%s", pathWithoutExtension)
end

---@private
---@param file string
---@return conversationConfiguration|nil
function this.load(file)
	local configuration = mwse.loadConfig(this.getConfigurationPathWithoutExtension(file), nil)
	if configuration and this.validate(file, configuration) then
		return this.postProcessConfiguration(file, configuration)
	end
end

---@private
---@param file string
---@param configuration conversationConfiguration
---@return boolean
function this.validate(file, configuration)
	local valid, reason = configurationValidator.validate(configuration)
	if not valid then
		logger:warn(string.format("Configuration '%s' is invalid. %s.", file, reason))
	end
	return valid
end

---@private
---@param file string
---@param configuration conversationConfiguration
---@return conversationConfiguration
function this.postProcessConfiguration(file, configuration)
	configuration.id = string.gsub(file, ".json", "")
	this.loadCallbacks(configuration)
	return configuration
end

---@private
---@param configuration conversationConfiguration
function this.loadCallbacks(configuration)
	configuration.callbacks = {}
	if not configuration.onCompletion then
		return
	end

	if configuration.onCompletion.journalEntry then
		table.insert(configuration.callbacks, this.loadNativeCallback("journalEntryCallback"))
	end

	if configuration.onCompletion.questIndex then
		table.insert(configuration.callbacks, this.loadNativeCallback("questIndexCallback"))
	end

	if configuration.onCompletion.startCombat then
		table.insert(configuration.callbacks, this.loadNativeCallback("startCombatCallback"))
	end

	if configuration.onCompletion.customCallbacks then
		for _, path in pairs(configuration.onCompletion.customCallbacks) do
			local callback = require(path)
			if type(callback.Execute) == "function" then
				table.insert(configuration.callbacks, callback)
			end
		end
	end
end

function this.loadNativeCallback(name)
	return require(string.format("tauer.dynamic-conversations.services.conversations.callbacks.%s", name))
end

return this
