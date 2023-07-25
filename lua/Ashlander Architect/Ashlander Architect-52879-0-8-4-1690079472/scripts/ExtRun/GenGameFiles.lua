local lfs = require("lfs")

local expectedHash = "544daa033c060fd5c9bba1b5ce692a4a981db9d079dead41b41659e1b051f948"
-- Define the search directory
local searchDirectory = "~/Downloads"

-- Define the destination directory for extracted files
local extractDestination = "~/extracted/files/"


-- Function to execute a command and capture its output
local function executeCommand(command)
  print(command)
  local handle = io.popen(command)
  local output = handle:read("*a")
  handle:close()
  return output
end

-- Function to calculate the hash of a file
local function calculateFileHash(filePath)
  local command = string.format("sha256sum \"%s\"", filePath)
  local output = executeCommand(command)
  local hash = string.match(output, "^(%w+)")
  return hash
end

-- Function to search for an Inno Setup file in the specified directory
local function findInnoSetupFile(directory)
  for file in lfs.dir(directory) do
    local filePath = directory .. "/" .. file
    if lfs.attributes(filePath, "mode") == "file" then
      local hash = calculateFileHash(filePath)
      if hash == expectedHash then
        return filePath
      end
    end
  end
  return nil
end

-- Function to extract the desired files from the innoextracted directory
local function extractFiles(sourceDirectory, destinationDirectory)
  -- Extract files from app/Data Files directory
  local dataFilesDirectory = sourceDirectory .. "/app/Data Files"
  local destinationDataFilesDirectory = destinationDirectory .. "/Data Files"
  local commandDataFiles = string.format("cp -r \"%s\" \"%s\"", dataFilesDirectory, destinationDataFilesDirectory)
  executeCommand(commandDataFiles)

  -- Extract Morrowind.ini file
  local morrowindIniFile = sourceDirectory .. "/app/Morrowind.ini"
  local destinationMorrowindIniFile = destinationDirectory .. "/Morrowind.ini"
  local commandMorrowindIni = string.format("cp \"%s\" \"%s\"", morrowindIniFile, destinationMorrowindIniFile)
  executeCommand(commandMorrowindIni)
end

-- Expand ~ notation to the actual home directory path
searchDirectory = string.gsub(searchDirectory, "^~", os.getenv("HOME"))
extractDestination = string.gsub(extractDestination, "^~", os.getenv("HOME"))

-- Create the destination directory if it doesn't exist
lfs.mkdir(extractDestination)
print(extractDestination)
-- Find the Inno Setup file in the specified directory
local innoSetupFilePath = findInnoSetupFile(searchDirectory)

if innoSetupFilePath then
  -- Construct the command to extract the Inno Setup file using innoextract
  local command = string.format("innoextract -d \"%s\" \"%s\"", extractDestination, innoSetupFilePath)

  -- Execute the command
  local output = executeCommand(command)

  -- Extract the desired files
  local sourceDirectory = string.gsub(innoSetupFilePath, "%.exe$", "")
  extractFiles(sourceDirectory, extractDestination)

  -- Display the output
  print(output)
else
  print("Inno Setup file not found.")
end