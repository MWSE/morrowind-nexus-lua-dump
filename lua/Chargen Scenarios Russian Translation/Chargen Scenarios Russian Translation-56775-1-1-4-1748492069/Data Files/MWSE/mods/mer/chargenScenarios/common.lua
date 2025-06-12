
---@class ChargenScenarios.Common
local common  = {}
common.config = require("mer.chargenScenarios.config")

---@type table<number, ChargenScenariosScenario>
common.registeredScenarios = {}

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

function common.modEnabled()
    return common.config.mcm.enabled == true
end

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

---@class ChargenScenariosClass
---@field new fun(self: any, data: table)
---@field get fun(id: string):any

---@param list table a list of constructor data
---@param classType ChargenScenariosClass a class object with a new() method
---@return table|nil #a list of constructed objects
function common.convertListTypes(list, classType)
    if list == nil then
        return nil
    end
    local newList = {}
    for _, item in ipairs(list) do
        if classType.get and type(item) == "string" then
            item = classType.get(item)
        else
            item = classType:new(item)
        end
        table.insert(newList, item)
    end
    return newList
end

return common