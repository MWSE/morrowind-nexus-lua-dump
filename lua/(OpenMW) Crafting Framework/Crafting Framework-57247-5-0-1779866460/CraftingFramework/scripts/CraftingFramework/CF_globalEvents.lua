-- collects registerGlobalEvent calls from recipe files for the global side.
-- recipe files: registerGlobalEvent("Name", version, handler(data))
-- handler gets the CraftingFramework_getItem payload plus data.defaultHandler.

local vfs = require('openmw.vfs')

local registeredEvents = {}
local registeredVersions = {}

function registerGlobalEvent(name, version, handler)
	version = version or 0
	local existing = registeredVersions[name] or -1
	if version >= existing then
		registeredEvents[name] = handler
		registeredVersions[name] = version
		return true
	end
	return false
end

wildcardFunctions = setmetatable({}, { __newindex = function() end })
registerWildcard = function()end
registerProfession = function()end
registerStation = function()end
wildcards = setmetatable({}, { __newindex = function() end })
wildcardNames = setmetatable({}, { __newindex = function() end })
wildcardIcons = setmetatable({}, { __newindex = function() end })
wildcardStrict = setmetatable({}, { __newindex = function() end })
craftingSounds = setmetatable({}, { __newindex = function() end })

-- zzz files iterate allProfessions at file scope
allProfessions = {}

-- recipe files that fail (e.g. missing player-side modules) are skipped
for filename in vfs.pathsWithPrefix("CF_recipes/") do
	if filename:match("%.lua$") then
		local ok, err = pcall(require, filename:sub(1, -5))
		if not ok then
			print("\27[91m ERROR in " .. filename:sub(12) .. ": " .. tostring(err))
		end
	end
end

return registeredEvents