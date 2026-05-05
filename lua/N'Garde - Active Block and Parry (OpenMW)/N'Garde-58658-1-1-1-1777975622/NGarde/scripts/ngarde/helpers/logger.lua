--simple logging helper
local modInfo = require('scripts.ngarde.modinfo')
Logger = {}
Logger.__index = Logger

---@enum LOG_LEVELS
local LOG_LEVELS = {
    OFF = -1,
    INFO = 0,
    ERROR = 1,
    WARNING = 2,
    DEBUG = 3,
}

function Logger.new()
    local self = setmetatable({}, Logger)
    self.LOG_LEVELS = LOG_LEVELS
    self.logLevel = self.LOG_LEVELS[LOG_LEVELS.OFF]
    return self
end

function Logger.logMessage(self, level, message)
    print(("[%s]:[%s]:%s"):format(modInfo.modKey, level, tostring(message)))
    if type(message) == "table" then
        Logger.tableRecursivePrint(message)
    end
end

function Logger.info(self, message)
    if self.LOG_LEVELS.INFO <= self.logLevel then
        self:logMessage("INFO", message)
    end
end

function Logger.error(self, message)
    if self.LOG_LEVELS.ERROR <= self.logLevel then
        self:logMessage("ERROR", message)
    end
end

function Logger.warning(self, message)
    if self.LOG_LEVELS.WARNING <= self.logLevel then
        self:logMessage("WARNING", message)
    end
end

function Logger.debug(self, message)
    if self.LOG_LEVELS.DEBUG <= self.logLevel then
        self:logMessage("DEBUG", message)
    end
end

function Logger.status(self, message)
    self:logMessage("STATUS", message)
end

function Logger.setLoglevel(self, level)
    self.logLevel = level
end

function Logger.tableRecursivePrint(table)
    for k, v in pairs(table) do
        print(k .. ":" .. tostring(v))
        if type(v) == "table" then
            Helpers.tableRecursivePrint(v)
        end
    end
end

return Logger
