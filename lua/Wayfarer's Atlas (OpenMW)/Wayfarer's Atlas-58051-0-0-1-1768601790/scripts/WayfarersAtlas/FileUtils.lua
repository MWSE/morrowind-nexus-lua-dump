local FileUtils = {}

---@param path string
function FileUtils.forwardSlashes(path)
	return path:gsub("\\", "/")
end

---@param path string
function FileUtils.backSlashes(path)
	return path:gsub("/", "\\")
end

-- If the directory is non-empty and doesn't have a trailing slash, adds one.
-- Converts to forward slashes.
---@param dir string
function FileUtils.dir(dir)
	dir = FileUtils.forwardSlashes(dir)

	if dir:match("([^/]+)") and dir:sub(-1, -1) ~= "/" then
		dir = dir .. "/"
	end

	return dir
end

-- Appends the path to the provided relative directory.
-- Converts to forward slashes.
---@param relativeDir string
---@param basePath string
function FileUtils.appendPath(relativeDir, basePath)
	return FileUtils.dir(relativeDir) .. FileUtils.forwardSlashes(basePath):match("^/?(.*)$")
end

-- Returns the base path relative to the provided relative directory.
-- Converts to forward slashes.
---@param relativeDir string
---@param basePath string
function FileUtils.relativePath(relativeDir, basePath)
	relativeDir = FileUtils.dir(relativeDir)
	basePath = FileUtils.forwardSlashes(basePath)

	local subPath = basePath:lower():match("^" .. relativeDir:lower() .. "(.+)$")
	if subPath then
		return basePath:sub(-#subPath, -1)
	else
		return basePath
	end
end

---@param filePath string
function FileUtils.stripFileExtension(filePath)
	local fileExtension = filePath:match("(%..+)$")
	if fileExtension then
		return filePath:sub(1, #filePath - #fileExtension)
	else
		return filePath
	end
end

---@param path string
function FileUtils.fileName(path)
	return FileUtils.stripFileExtension(path):match("([^/\\]+)$")
end

return FileUtils
