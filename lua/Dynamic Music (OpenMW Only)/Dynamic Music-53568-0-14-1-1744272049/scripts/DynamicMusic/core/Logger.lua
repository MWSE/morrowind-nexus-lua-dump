local LogLevel = require('scripts.DynamicMusic.core.LogLevel')

--- @class Logger
--- @field _printerDB [LogLevel, function]
local Logging = {}

Logging._logLevel = LogLevel.INFO

--- @param message string
--- @param logLevel LogLevel
function Logging.log(message, logLevel)
    if(logLevel.severity >= Logging._logLevel.severity)then
        print(message)
    end
end

-- Prints an info message.
---@param message string The message to print.
function Logging.info(message)
    Logging.log(message, LogLevel.INFO)
end

-- Prints a debug message.
---@param message string The message to print.
function Logging.debug(message)
    Logging.log(message, LogLevel.DEBUG)
end

-- Prints a warning message.
---@param message string The message to print.
function Logging.warn(message)
    Logging.log(message, LogLevel.WARN)
end

-- Prints an error message.
---@param message string The message to print.
function Logging.error(message)
    Logging.log(message, LogLevel.ERROR)
end

-- Prints a fatal message.
---@param message string The message to print.
function Logging.fatal(message)
    Logging.log(message, LogLevel.FATAL)
end

-- Sets the Log Level
---@param logLevel LogLevel The log level.
function Logging.setLogLevel(logLevel)
    Logging._logLevel = logLevel
end

return Logging