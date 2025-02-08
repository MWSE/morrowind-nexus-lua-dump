---@class RCME.Common
local common = {}
common.config = require("mer.RightClickMenuExit.config")
local i18n = mwse.loadTranslations("mer.RightClickMenuExit")

---@type RCME.i18n
common.messages = setmetatable({}, {
    __index = function(_, key)
        return function(data)
            return i18n(key, data)
        end
    end,
})

local MWSELogger = require("logging.logger")

---@type table<string, mwseLogger>
common.loggers = {}
function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("%s - %s",
            common.config.metadata.package.name, serviceName),
        logLevel = common.config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

---@return string #The version of the mod
function common.getVersion()
    return common.config.metadata.package.version
end

local function isLuaFile(file) return file:sub(-4, -1) == ".lua" end
local function isInitFile(file) return file == "init.lua" end
function common.initAll(path)
    path = "Data Files/MWSE/mods/" .. path .. "/"
    for file in lfs.dir(path) do
        if isLuaFile(file) and not isInitFile(file) then
            logger:debug("Executing file: %s", file)
            dofile(path .. file)
        end
    end
end

return common