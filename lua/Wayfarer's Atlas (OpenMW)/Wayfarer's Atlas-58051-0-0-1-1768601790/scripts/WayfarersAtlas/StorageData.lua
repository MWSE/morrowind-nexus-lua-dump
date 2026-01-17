local Storage = require("openmw.storage")
local Async = require("openmw.async")

local defaultSave = require("scripts/WayfarersAtlas/defaultSave")
local defaultConfig = require("scripts/WayfarersAtlas/defaultConfig")
local SettingsUtils = require("scripts/WayfarersAtlas/SettingsUtils")
local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Dictionary = Immutable.Dictionary

local SaveSection = Storage.playerSection("WAY.Storage")
SaveSection:setLifeTime(Storage.LIFE_TIME.Persistent)

local ConfigSection = Storage.playerSection("Settings/WayfarersAtlas")

local ModStorage = {}
ModStorage.__index = ModStorage

function ModStorage.new()
	local self = setmetatable({}, ModStorage)

	local function update()
		self._config = Dictionary.merge(defaultConfig, ConfigSection:asTable())
	end

	ConfigSection:subscribe(Async:callback(update))
	update()

	return self
end

---@return WAY.StorageData
function ModStorage:getSave()
	local data = SaveSection:asTable().data or {}
	return Dictionary.merge(defaultSave, data)
end

---@param data WAY.StorageData
function ModStorage:setSave(data)
	SaveSection:set("data", data)
end

---@return WAY.Config
function ModStorage:getConfig()
	return self._config
end

---@param mapPack WAY.MapPack
function ModStorage:getMapPackData(mapPack)
	local groupKey = SettingsUtils.groupKey(SettingsUtils.scopeMapPack(mapPack))
	local groupSection = Storage.playerSection(groupKey)

	return function(key)
		return groupSection:get(SettingsUtils.join(groupKey, key))
	end
end

---@param mapPack WAY.MapPack
---@param mapDefinition WAY.MapDefinition
function ModStorage:getMapDefinitionData(mapPack, mapDefinition)
	local groupKey = SettingsUtils.groupKey(SettingsUtils.scopeMapDefinition(mapPack, mapDefinition))
	local groupSection = Storage.playerSection(groupKey)

	return function(key)
		return groupSection:get(SettingsUtils.join(groupKey, key))
	end
end

function ModStorage:subscribeMapPack(mapPack, callback)
	local groupKey = SettingsUtils.groupKey(SettingsUtils.scopeMapPack(mapPack))
	local groupSection = Storage.playerSection(groupKey)

	groupSection:subscribe(Async:callback(callback))
end

function ModStorage:subscribeMapDefinition(mapPack, mapDefinition, callback)
	local groupKey = SettingsUtils.groupKey(SettingsUtils.scopeMapDefinition(mapPack, mapDefinition))
	local groupSection = Storage.playerSection(groupKey)

	groupSection:subscribe(Async:callback(callback))
end

function ModStorage:updateVersions(updaters, data)
	for i = data.version or 1, #updaters do
		data = updaters[i](data)
		data.version = i + 1
	end

	return data
end

return ModStorage
