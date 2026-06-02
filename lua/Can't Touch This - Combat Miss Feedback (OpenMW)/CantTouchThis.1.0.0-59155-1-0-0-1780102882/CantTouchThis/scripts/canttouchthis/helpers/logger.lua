--simple logging helper
---@omw-context all
local async             = require('openmw.async')
local storage           = require('openmw.storage')
local SettingsConstants = require('scripts.canttouchthis.helpers.settings_constants')
local debugSettings     = storage.globalSection(SettingsConstants.debugSettingsGroupKey)
local modInfo           = require('scripts.canttouchthis.modinfo')
local aux_util          = require('openmw_aux.util')
Logger                  = {}
Logger.__index          = Logger

---@enum LOG_LEVELS
local LOG_LEVELS        = {
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
    self:readDebugSettings()
    debugSettings:subscribe(
        async:callback(function(groupname, key)
            self:readDebugSettings(groupname, key)
        end))
    return self
end

function Logger.logMessage(self, level, message)
    print(("[%s]:[%s]:%s"):format(modInfo.modKey, level, tostring(message)))
    if type(message) == "table" then
        print(("[%s]:[%s]:%s"):format(modInfo.modKey, level, "table contents:"))
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
    print(aux_util.deepToString(table, 4))
end

function Logger.readDebugSettings(self, groupname, key)
    if key == SettingsConstants.debugLogsKey or key == nil then
        self.debugLogs = SettingsConstants.readSetting(debugSettings, SettingsConstants.debugLogsKey)
        if self.debugLogs then
            self:setLoglevel(self.LOG_LEVELS.DEBUG)
            -- self:debug("Enabling debug logs")
        else
            self:setLoglevel(self.LOG_LEVELS.OFF)
        end
    end
end

return Logger
