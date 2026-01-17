
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
        name = common.config.metadata.package.name,
        moduleName = serviceName,
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
    local fullPath = "Data Files/MWSE/mods/" .. path .. "/"
    for file in lfs.dir(fullPath) do
        if isLuaFile(file) and not isInitFile(file) then
            logger:debug("Executing file: %s", file)
            dofile(fullPath .. file)
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

---Positions a reference behind the player
---@param e { object: any, distanceBehind: number }
---@return tes3reference #The created reference
function common.placeBehindPlayer(e)
    local forwardVector = tes3.getPlayerEyeVector()
    -- Invert it to get the backward direction
    local backwardVector = -forwardVector
    -- Calculate the new position
    local position = tes3.player.position:copy() + backwardVector * e.distanceBehind
    return tes3.createReference{
        object = e.object,
        position = position,
        --facing player
        orientation = tes3.player.orientation:copy(),
        cell = tes3.player.cell
    }
end

return common