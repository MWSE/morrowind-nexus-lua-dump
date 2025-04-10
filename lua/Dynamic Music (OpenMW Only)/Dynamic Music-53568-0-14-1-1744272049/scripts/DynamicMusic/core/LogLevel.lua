--- @class LogLevel
--- @field INFO LogLevel
--- @field DEBUG LogLevel
--- @field WARN LogLevel
--- @field ERROR LogLevel
--- @field FATAL LogLevel
--- @field severity integer
local LogLevel = {}

--- Creates a new LogLevel
--- @param name string The name/Id of this loglevel.
--- @param severity integer The severity of this loglevel. Higher values are more severe.
--- @return LogLevel logLevel A LogLevel instance.
function LogLevel.Create(name, severity)
    local level = {}

    level.name = name
    level.severity = severity

    return level
end

LogLevel.DEBUG = LogLevel.Create("DEBUG", 1)
LogLevel.INFO = LogLevel.Create("INFO",2)
LogLevel.WARN = LogLevel.Create("WARN", 3)
LogLevel.ERROR = LogLevel.Create("ERROR", 4)
LogLevel.FATAL = LogLevel.Create("FATAL", 5)

return LogLevel
