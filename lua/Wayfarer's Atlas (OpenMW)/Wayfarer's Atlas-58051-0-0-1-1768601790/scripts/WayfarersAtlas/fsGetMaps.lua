local VFS = require("openmw.vfs")
local OMWUtil = require("openmw.util")
local Core = require("openmw.core")

local FileUtils = require("scripts/WayfarersAtlas/FileUtils")

local MAC_MAPS_PATH = "MWSE/mods/Map and Compass/"
local MAP_FIELDS = {
	path = "string",
	name = "string",
	width = "number",
	height = "number",
}

local l10n = Core.l10n("WayfarersAtlas")

---@param str string
local function uintLe(str, start, length)
	local uint = 0
	for i = 0, length - 1 do
		local byte = str:sub(start + i):byte()
		uint = uint + byte * (256 ^ i)
	end

	return uint
end

-- Reference: https://learn.microsoft.com/en-us/windows/win32/direct3ddds/dx-graphics-dds-pguide
local function parseSizeDDS(handle)
	local content = handle:read(128)
	if not content or #content < 128 then
		return OMWUtil.vector2(0, 0)
	end

	if content:sub(1, 4) ~= "DDS " then
		return OMWUtil.vector2(0, 0)
	end

	local height = uintLe(content, 13, 4)
	local width = uintLe(content, 17, 4)

	return OMWUtil.vector2(width, height)
end

-- Reference: http://www.paulbourke.net/dataformats/tga/
local function parseSizeTGA(handle)
	local content = handle:read(18)
	if not content or #content < 18 then
		return OMWUtil.vector2(0, 0)
	end

	local height = uintLe(content, 13, 2)
	local width = uintLe(content, 15, 2)

	return OMWUtil.vector2(width, height)
end

local function fuzzyEq(a, b, epsilon)
	epsilon = epsilon or 1e-5
	return math.abs(a - b) < epsilon
end

local function round(x)
	if x >= 0.5 then
		return math.ceil(x)
	else
		return math.floor(x)
	end
end

local function isPowOf2Aligned(x)
	local log = math.log(x, 2)
	return fuzzyEq(round(log), log)
end

local function isPowOf2AlignedSize(size)
	return isPowOf2Aligned(size.x) and isPowOf2Aligned(size.y)
end

local function nearestPowOf2(x)
	return 2 ^ math.ceil(math.log(x, 2))
end

local function nearestPowOf2Size(size)
	return OMWUtil.vector2(nearestPowOf2(size.x), nearestPowOf2(size.y))
end

local function mapIdFn(mapPackPath, key)
	return string.format("%s_%s", mapPackPath, tostring(key))
end

local function unexpectedTypeMsg(key, value, expected)
	return l10n("UnexpectedType", {
		item = tostring(key),
		type = type(value),
		expectedType = expected,
	})
end

local function checkMapPack(mapPack)
	if type(mapPack) ~= "table" then
		return false, unexpectedTypeMsg("map pack", mapPack, "table")
	end

	return true
end

local function checkMap(map)
	if type(map) ~= "table" then
		return false, unexpectedTypeMsg("map", map, "table")
	end

	for defKey, defType in pairs(MAP_FIELDS) do
		if type(map[defKey]) ~= defType then
			return false, unexpectedTypeMsg(defKey, map[defKey], defType)
		end
	end

	return true
end

local function fsGetMaps()
	---@type WAY.MapPack[]
	local mapPacks = {}
	---@type table<string, string>
	local errors = {}

	for filePath in VFS.pathsWithPrefix(MAC_MAPS_PATH) do
		filePath = FileUtils.forwardSlashes(filePath)

		local pathRelMapPacksDir = FileUtils.relativePath(MAC_MAPS_PATH, filePath)
		local containsSubDir = pathRelMapPacksDir:find("/.+/") ~= nil

		if containsSubDir or not pathRelMapPacksDir:match("(maps%.lua)$") then
			goto continue
		end

		local mapDefinitions = {}
		table.insert(mapPacks, {
			name = pathRelMapPacksDir:match("[^/]+"),
			path = filePath,
			mapDefinitions = mapDefinitions,
		})

		local withoutExt = FileUtils.stripFileExtension(filePath)
		local ok, ret = pcall(require, withoutExt)
		if not ok then
			errors[filePath] = ret
			goto continue
		end

		local externalMapPack = ret
		ok, errors[filePath] = checkMapPack(externalMapPack)
		if not ok then
			goto continue
		end

		for key, map in pairs(externalMapPack) do
			local mapId = mapIdFn(filePath, key)
			local mapSize = OMWUtil.vector2(-1, -1)
			local mapFileExt = ""
			local size = OMWUtil.vector2(0, 0)

			ok, errors[mapId] = checkMap(map)
			if not ok then
				map = {}
				goto insert
			end

			if not VFS.fileExists(map.path) then
				errors[mapId] = l10n("FileDoesNotExist", { path = map.path })
				goto insert
			end

			mapFileExt = map.path:lower():match("%.(.+)$")
			mapSize = OMWUtil.vector2(map.width, map.height)

			if mapFileExt == "dds" then
				size = parseSizeDDS(VFS.open(map.path))
			elseif mapFileExt == "tga" then
				size = parseSizeTGA(VFS.open(map.path))
			else
				errors[mapId] = l10n("MapImageExtUnsupported", {
					extension = tostring(mapFileExt),
				})
			end

			if not isPowOf2AlignedSize(size) then
				errors[mapId] = l10n("MapImagePow2MAC", {
					size = tostring(size),
					suggestedSize = tostring(nearestPowOf2Size(size)),
				})
			end

			::insert::
			if errors[mapId] then
				mapSize = OMWUtil.vector2(-1, -1)
			end

			mapDefinitions[tostring(key)] = {
				id = mapId,
				name = map.name or "",
				imagePath = map.path or "",
				imageSize = mapSize,
			}
		end
		::continue::
	end

	return errors, mapPacks
end

return fsGetMaps
