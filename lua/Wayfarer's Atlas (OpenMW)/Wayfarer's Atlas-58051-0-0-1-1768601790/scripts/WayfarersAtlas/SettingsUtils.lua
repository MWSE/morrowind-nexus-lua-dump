local SettingsUtils = {}

function SettingsUtils.join(...)
	return table.concat({ ... }, ".")
end

function SettingsUtils.groupKey(scope)
	return SettingsUtils.join("Settings/", scope)
end

function SettingsUtils.scopeMapPack(mapPack)
	return SettingsUtils.join("mapPack", mapPack.path)
end

function SettingsUtils.scopeMapDefinition(mapPack, mapDefinition)
	return SettingsUtils.join(SettingsUtils.scopeMapPack(mapPack), mapDefinition.id)
end

return SettingsUtils
