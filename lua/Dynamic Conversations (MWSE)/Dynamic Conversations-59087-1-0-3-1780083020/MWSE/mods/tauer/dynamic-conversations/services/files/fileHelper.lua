local FILE_TYPE = require("tauer.dynamic-conversations.services.files.enums.FILE_TYPE")

local logger = mwse.Logger.new()

--- Encapsulates file-related helper functions
---@class fileHelper
local this = {}

---@type string
this.fileExtensionRegex = "^.+(%..+)$"

--- Gets all files of the specified type in the given directory
---@public
---@param dir string The directory to search in
---@param fileType FILE_TYPE The file type/extension to filter by
---@return string[]|nil files An array of file names matching the specified type, or nil if the directory is invalid
function this.getAllFilesInDirectory(dir, fileType)
	if not this.isDirectory(dir) then
		logger:error("%s is not a valid directory", dir)
		return nil
	end

	local files = {}

	for file in lfs.dir(dir) do
		---@cast fileType +string
		if file:lower():endswith(fileType:lower()) then
			table.insert(files, file)
		end
	end

	if table.empty(files) then
		logger:debug("Found no files at %s", dir)
	end

	return files
end

--- Checks if the given file path matches the specified file type
---@public
---@param filePath filePath The file path to check
---@param fileType FILE_TYPE The file type/extension to check against
function this.isFileType(filePath, fileType)
	local extension = filePath:match(this.fileExtensionRegex)
	return extension == fileType
end

--- Gets the file name without its extension from a given file path
---@public
---@param filePath string The full file path
---@return string fileName The file name without its extension
function this.getFileName(filePath)
	-- Remove directory part
	local fileName = filePath:match("^.+/(.+)$") or filePath
	-- Remove extension part
	local fileNameWithoutExtension = fileName:match("(.+)%..+$") or fileName
	return fileNameWithoutExtension
end

--- Checks if the given file is a valid NIF animation file
---@public
---@param filePath filePath The file path to check
---@return boolean isValid true if the file is a valid NIF animation file, false otherwise
function this.isValidAnimationFile(filePath)
	return this.isFileType(filePath, FILE_TYPE.nif) and filePath:sub(1, 1) ~= "x"
end

---@private
---@param path string
---@return boolean
function this.isDirectory(path)
	return lfs.attributes(path, "mode") == "directory"
end

return this
