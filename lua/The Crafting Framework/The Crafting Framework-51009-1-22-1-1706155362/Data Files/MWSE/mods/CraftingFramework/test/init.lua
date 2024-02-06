if not include("unitwind") then return end
local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Unit Tests")
logger:debug("Initialising Crafting Framework tests")
local rootDir = "Data Files/MWSE/mods/CraftingFramework/test/"
local folders = {
    "components"
}

for _, folder in pairs(folders) do
    local dir = string.format("%s%s", rootDir, folder)
    logger:debug("Loading files from %s", dir)
    for file in lfs.dir(dir) do
        logger:debug("Loading %s", file)
        local path = string.format("%s/%s", dir, file)
        local fileAttributes = lfs.attributes(path)
        if (fileAttributes.mode == "file" and file:sub(-4, -1) == ".lua") then
            logger:debug("Running %s", file)
            dofile(path)
        else
            logger:debug("Skipping %s", file)
        end
    end
end
