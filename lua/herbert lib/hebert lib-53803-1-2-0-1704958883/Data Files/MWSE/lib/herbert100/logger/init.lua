--[[ # Logger 

Based on the `mwseLogger` made by Merlord.

Current version made by herbert100.
]]


local colors = require("herbert100.logger.colors")

local sf = string.format

local logger_metatable = {
    -- make new loggers by calling `Logger`
    __call=function (cls, ...) return cls.new(...) end,
    __tostring = function(self) return ("Logger") end
}


---@alias herbert.Logger.LEVEL
---|0                       NONE: Nothing will be printed
---|1                       ERROR: Error messages will be printed
---|2                       WARN: Warning messages will be printed
---|3                       INFO: Only crucial information will be printed
---|4                       DEBUG: Debug messages will be printed
---|5                       TRACE: Many debug messages will be printed


---@type table<string, herbert.Logger[]>
local loggers = {}


--[[## Logger

### Creating a new `Logger`

To create a new logger for a mod with the specified `mod_name`, you can write one of the following four things:
1) `log = Logger("MODNAME")`
2) `log = Logger{mod_name="MODNAME", level=LEVEL?, ...}`
3) `log = Logger.new("MODNAME")`
4) `log = Logger.new{mod_name="MODNAME", level=LEVEL?, ...}`

tring representing a numerical code (ie "NONE", "PROBLEMS", ..., "TRACE")

### Writing log messages

- you can log things by writing `log:info`, `log:warn`, `log:error`, `log:debug`, etc.
- additionally, you can write debug messages by typing `log(str)`

**Passing multiple parameters:**
If multiple parameters are passed, then `string.format` will be called on the first parameter. You have two options for formatting strings:
1) pass the formatting options as regular arguments.
    - e.g., `log:trace("The %s today is %i %s", "weather", 20, "degrees")`
    - So, `log:trace(s, ...)` and `log:trace(string.format(s, ...))` will print the same things.
    - the only difference is that in the first case, `string.format` will be called AFTER the `log.level` is checked.
2) pass the formatting options as a `function`.
    - e.g., `log:trace("The %s today is %i, %s", function() return "weather", 20, "degrees" end)
    - So, `log:trace(s, func)` and `log:trace(string.format(s, func() )) will print the same things.
    - The key difference is that both `string.format` AND `func` will only be called after the `log.level` is checked.
    - This could be very nice for performance reasons, if you're printing complicated debugging messages.


**Passing a single parameter:**
If only a single parameter is passed, `string.format` will NOT be called. This is to avoid unexpected errors from writing strings 
that inadvertently contain formatting specifiers.



### Updating the `log.level`

Once a `log` has been created, the log level can be changed by using the `log:set_level(Logger.LEVEL)` method.
You can specify a string or number.
e.g. to set the `log.level` to "DEBUG", you can write any of the following:
1) `log:set_level("DEBUG")`
2) `log:set_level(2)`
3) `log:set_level(Logger.LEVEL.DEBUG)`

### Accessing the `log.level`

The current logging level can be accessed by writing `log.level` or `#log`.

The `log.level` is stored internally as an `integer`, so that you can easily check to see if the `log.level` is above a certain value.
The log levels are:
NONE = 0
ERROR = 1
WARN = 2
INFO = 3
DEBUG = 4
TRACE = 5

So, to check if the logging level is "DEBUG" or higher, you can write
- `#log >= 4`

Additionally, you can write
- `log >= 4`

**NOTE:** The `log` **must** be on the `>=` side of the comparison if using this syntax. Writing `log <= 4` will result in an error. 
]]
---@class herbert.Logger
---@field mod_name string the name of the mod this logger is for
---@field level herbert.Logger.LEVEL
---@field module_name string? the module this logger belongs to, or `nil` if it's a general purpose logger
---@field use_colors boolean should colors be used when writing log statements? Default: `false`
---@field write_to_file boolean if true, we will write the log contents to a file with the same name as this mod.
---@field include_timestamp boolean should the current time be printed when writing log messages? Default: `false`
---@field file file*? the file the log is being written to, if `write_to_file == true`, otherwise its nil.
---@field LEVEL table<herbert.Logger.LEVEL_STRING, herbert.Logger.LEVEL>
local Logger = {
    LEVEL = {
        NONE = 0,
        ERROR = 1,
        WARN = 2,
        INFO = 3,
        DEBUG = 4,
        TRACE = 5
    }
}
setmetatable(Logger, logger_metatable)


---|`Logger.LEVEL.NONE`     Nothing will be printed
---|`Logger.LEVEL.ERROR`    Error messages will be printed
---|`Logger.LEVEL.WARN`     Warning messages will be printed
---|`Logger.LEVEL.INFO`     Crucial information will be printed
---|`Logger.LEVEL.DEBUG`    Debug messages will be printed
---|`Logger.LEVEL.TRACE`    Many debug messages will be printed




---@alias herbert.Logger.LEVEL_STRING
---|"NONE"      Nothing will be printed
---|"ERROR"     Error messages will be printed
---|"WARN"      Warning messages will be printed
---|"INFO"      Crucial information will be printed
---|"DEBUG"     Debug messages will be printed
---|"TRACE"     Many debug messages will be printed




-- metatable used by log objects
local log_metatable = {
    __call = function(self, ...) self:debug(...) end,
    __lt = function(num, self) return num < self.level end,
    __le = function(num, self) return num <= self.level end,
    __len = function(self) return self.level end,
    __index = Logger,
    ---@param self herbert.Logger
    ---@param str string
    __concat = function(self, str)
        return self:make_child(str)
    end,
    __tostring = function(self)
        if self.module_name then 
            return sf(
                "Logger(mod_name=\"%s\", module_name=\"%s\", level=%i, levelStr=%s)",
                self.mod_name, self.module_name, self.level, table.find(Logger.LEVEL, self.level)
            )
        else
            return sf(
                    "Logger(mod_name=\"%s\", level=%i, levelStr=%s)",
                    self.mod_name, self.level, table.find(Logger.LEVEL, self.level)
                )
        end
    end,
}

local function get_mod_and_module_names(mod_name)
    local actual_mod_name, module_name
    local index = mod_name:find("/")
    if index then
        actual_mod_name = mod_name:sub(1,index-1)
        module_name = mod_name:sub(index+1)
    else
        actual_mod_name = mod_name
    end
    return actual_mod_name, module_name
end


---@class herbert.Logger.new_params
---@field mod_name string the name of the mod this logger is for
---@field level herbert.Logger.LEVEL|herbert.Logger.LEVEL_STRING|nil the log level to set this object to. Default: "INFO"
---@field module_name string? the module this logger belongs to, or `nil` if it's a general purpose logger
---@field use_colors boolean? should colors be used when writing log statements? Default: `false`
---@field include_timestamp boolean? should the current time be printed when writing log messages? Default: `false`
---@field write_to_file string|boolean|nil whether to write the log messages to a file, or the name of the file to write to. if `false` or `nil`, messages will be written to `MWSE.log`


--[[##Create a new logger for a mod with the specified `mod_name`. 

New objects can be created in the following ways:
- `log = Logger("MODNAME")`
- `log = Logger{mod_name="MODNAME", level=LEVEL?, ...}`
- `log = Logger.new("MODNAME")`
- `log = Logger.new{mod_name="MODNAME", level=LEVEL?, ...}`

In addition to `mod_name`, you may specify
- `use_colors`: whether to use colors when printing log messages.
- `level`: the logging level to start this logger at. This is the same as making a new logger and then calling `log:set_level(level)`
- `write_to_file`: either a boolean saying we should write to a file, or the name of a file to write to. If false (the default), then log messages will be written to `MWSE.log`
]]
---@param params herbert.Logger.new_params
function Logger.new(params)
    -- if it's just a string, treat it as the `mod_name`
    if type(params) == "string" then
        params = {mod_name=params} 
    end
    -- do some error checking to make sure `params` are correct
    assert(params.mod_name ~= nil, "Error: Could not create a Logger because mod_name was nil.")
    assert(type(params.mod_name) == "string", "Error: Could not create a Logger. mod_name must be a string.")

    local mod_name, module_name = params.mod_name, params.module_name
    if module_name == nil then
        mod_name, module_name = get_mod_and_module_names(mod_name)
    end

    local log ---@type herbert.Logger

    -- first try to get it
    log = Logger.get(mod_name, module_name)

    if log then return log end

    -- now we know the log doesn't exist

    log = {
        mod_name = mod_name,
        module_name = module_name,
        use_colors=params.use_colors or false,
        write_to_file = params.write_to_file or false,
        level = Logger.LEVEL.INFO, -- we'll set it with the dedicated function so we can do fancy stuff
        include_timestamp = params.include_timestamp or false,
    }

    
    -- if there are already loggers with this `mod_name`, get the most recent one, and then
    -- update this new loggers values to those of the most recent logger. (if those values weren't specified in `params`)
    if loggers[mod_name] and #loggers[mod_name] > 0 then
        local parent = loggers[mod_name][#loggers[mod_name]]
        for _, k in ipairs{"use_colors", "write_to_file", "include_timestamp"} do
            if params[k] == nil then
                log[k] = parent[k]
            end
        end
        -- set the default value to the parent log level, we will call `set_level` later
        -- this will do the the following:
        -- if `params.level` was invalid, nothing will happen and `parent.level` will be used.
        -- if `params.level` was valid, then every logger registered to this mod will be updated.
        log.level = parent.level
    else
        -- this is the first logger with this `mod_name`, so we should intialize the array
        loggers[mod_name] = {}
    end

    table.insert(loggers[mod_name], log)

    setmetatable(log, log_metatable)
    log:set_level(params.level)

    if params.write_to_file == nil then
        log:set_write_to_file(log.write_to_file, true)
    else
        log:set_write_to_file(params.write_to_file)
    end


    return log
end



---@param write_to_file string|boolean
---@param only_this_logger boolean? should we only update this logger? Default: false
function Logger:set_write_to_file(write_to_file, only_this_logger)
    if write_to_file == nil then return end

    local _loggers = only_this_logger and {self} or loggers[self.mod_name]

    if write_to_file == false then
        for _, log in ipairs(_loggers) do
            if log.file then
                log.file:close()
                log.file = nil
            end
            log.write_to_file = false
        end
        return
    end

    for _, log in ipairs(_loggers) do
        local filename
        if write_to_file == true then
            if log.module_name then
                filename = sf("%s\\%s.log",log.mod_name,log.module_name)
            else
                filename = log.mod_name .. ".log"
            end
        else
            filename = write_to_file
        end
        if log.file then
            log.file:close()
        end
        log.file = io.open(filename, "w")
        log.write_to_file = true
    end
end




local COLORS = {
	NONE =  "white",
	WARN =  "bright yellow",
	ERROR =  "bright red",
	INFO =  "white",
    DEBUG = "bright green",
    TRACE =  "bright white",
}

--[[Get a previously registered logger with the specified `mod_name`.

**Note:** Calling `Logger.new(mod_name)` will also return a previously registered logger if it exists.
The difference between `.get` and `.new` is that if a logger does not exist, `.new` will create one, while `.get` will not.
]]
---@param mod_name string name of the mod
---@param module_name string the name of the module
---@return herbert.Logger? logger
function Logger.get(mod_name, module_name)
    if module_name == nil then
        mod_name, module_name = get_mod_and_module_names(mod_name)
    end
    if loggers[mod_name] then
        for _, log in ipairs(loggers[mod_name]) do
            if log.module_name == module_name then
                return log
            end
        end
    end
end


function Logger:get_level_str()
    return table.find(Logger.LEVEL, self.level)
end

--- returns all the loggers associated with this mod_name (can pass a Logger as well)
function Logger.get_loggers(mod_name_or_logger) 
    return type(mod_name_or_logger) == "table"  and loggers[mod_name_or_logger.mod_name]
        or loggers[mod_name_or_logger] 
        or false
end

function Logger:make_child(module_name)
    return self.new{
        mod_name=self.mod_name,
        level=self.level,
        module_name=module_name,
        use_colors=self.use_colors,
        write_to_file=self.write_to_file,
        include_timestamp=self.include_timestamp
    }
end


local LOG_LEVEL = Logger.LEVEL



--[[Change the current logging level. You can specify a string or number.
e.g. to set the `log.level` to "DEBUG", you can write any of the following:
1) `log:set_level("DEBUG")`
2) `log:set_level(4)`
3) `log:set_level(Logger.LEVEL.DEBUG)`
]]
---@param self herbert.Logger
---@param level herbert.Logger.LEVEL|herbert.Logger.LEVEL_STRING
function Logger:set_level(level)
    

    local lvl -- the actual level we should use, instead of a string or something
    if LOG_LEVEL[level] then
        lvl = LOG_LEVEL[level]

    elseif type(level) == "number" then 
        if LOG_LEVEL.NONE <= level and level <= LOG_LEVEL.TRACE then
            ---@diagnostic disable-next-line: assign-type-mismatch
            lvl = level
        end

    elseif type(level) == "string" then
        lvl = LOG_LEVEL[level:upper()]
    end

    if not lvl then return end

    for _, log in ipairs(loggers[self.mod_name]) do
        log.level = lvl
    end
end


---@param include_timestamp boolean Whether logs should use timestamps
function Logger:set_include_timestamp(include_timestamp)
    -- we need to know what to do
    if include_timestamp then
        for _, log in ipairs(loggers[self.mod_name]) do
            log.include_timestamp = include_timestamp
        end
    end
end

--- for internal use only. it generates the header message that will be enclosed in square brackets when printing log messages.
function Logger:_make_header(log_str)
    local header_t = {}
    
    if self.module_name ~= nil then
        header_t[1] = sf("%s (%s):", self.mod_name, self.module_name)
    else
        header_t[1] = sf("%s:", self.mod_name)
    end
    if self.use_colors then
        -- e.g. turn "ERROR" into "ERROR" (but written in red)
        log_str = colors(sf("%%{%s}%s", COLORS[log_str], log_str))
    end
    header_t[#header_t+1] = log_str
    if self.include_timestamp then
        local socket = require("socket")
        local timestamp = socket.gettime()
        local milliseconds = math.floor((timestamp % 1) * 1000)
        timestamp = math.floor(timestamp)

        -- convert timestamp to a table containing time components
        local timeTable = os.date("*t", timestamp)

        -- format time components into H:M:S:MS string
        local formattedTime = sf(": %02d:%02d:%02d.%03d", timeTable.hour, timeTable.min, timeTable.sec, milliseconds)
        header_t[#header_t+1] = formattedTime
    end
    return table.concat(header_t," ")
end

--- write to log. only used internally
---@param log_str herbert.Logger.LEVEL_STRING
function Logger:write(log_str, ...)
    local s
    local n, header = select("#",...), self:_make_header(log_str)
    if n == 1 then
        s = sf("[%s] %s", header, ...)
    else
        local s1, s2 = ...
        if type(s1) == "function" then
            if n == 2 then
                s = sf( "[%s] %s", header, sf( s1(s2) ) )
            else
                s = sf( "[%s] %s", header, sf( s1(select(2, ...)) ) )
            end

        elseif type(s2) == "function" then
            if n > 2 then
                s = sf("[%s] %s", header, sf( s1, s2(select(3, ...)) ) )
            else
                s = sf("[%s] %s", header, sf( s1, s2() ) )
            end

        else
            s = sf("[%s] %s", header, sf(...) )
        end
    end

    
    if self.write_to_file ~= false then
        self.file:write(s .. "\n"); self.file:flush()
    else
       print(s)
    end
end





--[[ Write an error message, if the current `log.level` permits it. 

If one parameter is passed, that paramter will be printed normally.

**Passing multiple parameters:**
1) If you type `log:debug(str, ...)`, then the output will be the same as
```log:debug(string.format(str,...))```
2) If you type `log:debug(func, ...)`, then the output will be the same as 
```log:debug(func, ...) == log:debug(string.format(func(...)))```
3) If you type `log:debug(str, func, ...)` then the output will be the same as 
```log:debug(string.format(str, func(...) ))```

**Note:** there is an advantage to using this syntax: functions will be called _only_ if you're at the appropriate logging level. 
So, it's fine to pass functions that take a long time to compute. they will only be evaluated if the logging level is high enough.
]]
---@param ... string the strings to write the log
function Logger:error(...)
    if self.level >= LOG_LEVEL.ERROR then self:write("ERROR", ...) end
end


--[[ Write a warning message, if the current `log.level` permits it. 

If one parameter is passed, that paramter will be printed normally.

**Passing multiple parameters:**
1) If you type `log:debug(str, ...)`, then the output will be the same as
```log:debug(string.format(str,...))```
2) If you type `log:debug(func, ...)`, then the output will be the same as 
```log:debug(func, ...) == log:debug(string.format(func(...)))```
3) If you type `log:debug(str, func, ...)` then the output will be the same as 
```log:debug(string.format(str, func(...) ))```

**Note:** there is an advantage to using this syntax: functions will be called _only_ if you're at the appropriate logging level. 
So, it's fine to pass functions that take a long time to compute. they will only be evaluated if the logging level is high enough.
]]
---@param ... string the strings to write the log
function Logger:warn(...)
    if self.level >= LOG_LEVEL.WARN then self:write("WARN", ...) end
end

--[[ Write an info message, if the current `log.level` permits it. 

If one parameter is passed, that paramter will be printed normally.

**Passing multiple parameters:**
1) If you type `log:debug(str, ...)`, then the output will be the same as
```log:debug(string.format(str,...))```
2) If you type `log:debug(func, ...)`, then the output will be the same as 
```log:debug(func, ...) == log:debug(string.format(func(...)))```
3) If you type `log:debug(str, func, ...)` then the output will be the same as 
```log:debug(string.format(str, func(...) ))```

**Note:** there is an advantage to using this syntax: functions will be called _only_ if you're at the appropriate logging level. 
So, it's fine to pass functions that take a long time to compute. they will only be evaluated if the logging level is high enough.
]]
---@param ... string the strings to write the log
function Logger:info(...)
    if self.level >= LOG_LEVEL.INFO then self:write("INFO", ...) end
end


--[[ Write a debug message, if the current `log.level` permits it. 

If one parameter is passed, that paramter will be printed normally.

**Passing multiple parameters:**
1) If you type `log:debug(str, ...)`, then the output will be the same as
```log:debug(string.format(str,...))```
2) If you type `log:debug(func, ...)`, then the output will be the same as 
```log:debug(func, ...) == log:debug(string.format(func(...)))```
3) If you type `log:debug(str, func, ...)` then the output will be the same as 
```log:debug(string.format(str, func(...) ))```

**Note:** there is an advantage to using this syntax: functions will be called _only_ if you're at the appropriate logging level. 
So, it's fine to pass functions that take a long time to compute. they will only be evaluated if the logging level is high enough.
]]
---@param ... string the strings to write the log
function Logger:debug(...)
    if self.level >= LOG_LEVEL.DEBUG then self:write("DEBUG", ...) end
end

--[[ Write a trace message, if the current `log.level` permits it. 

If one parameter is passed, that paramter will be printed normally.

**Passing multiple parameters:**
1) If you type `log:debug(str, ...)`, then the output will be the same as
```log:debug(string.format(str,...))```
2) If you type `log:debug(func, ...)`, then the output will be the same as 
```log:debug(func, ...) == log:debug(string.format(func(...)))```
3) If you type `log:debug(str, func, ...)` then the output will be the same as 
```log:debug(string.format(str, func(...) ))```

**Note:** there is an advantage to using this syntax: functions will be called _only_ if you're at the appropriate logging level. 
So, it's fine to pass functions that take a long time to compute. they will only be evaluated if the logging level is high enough.
]]
---@param ... string the strings to write the log
function Logger:trace(...)
    if self.level >= LOG_LEVEL.TRACE then self:write("TRACE", ...) end
end


do

    -- =========================================================================
    -- table log formatting
    -- =========================================================================
---@class herbert.Logger.write_params
---@field sep string? the separator to use between different values in `args`. This gets passed directly to `table.concat`.
---@field key_sep string? the separator to use between keys and values for entries in associative arrays. the default is "=", so that associative array entries will be printed "k=v"
---@field msg string? if passed, this is the message that will be formatted using `args`. otherwise, only `args` will be printed
---@field args table this is what will be passed to `string.format` or `table.concat`. if it's a `table`, it will be unpacked. if it's a `function`, it will be called and then unpacked. using a function is more efficient in the case that the message may not always be printed (e.g. debug messages)

---@param log_str herbert.Logger.LEVEL_STRING
---@param params herbert.Logger.write_params|fun(...):herbert.Logger.write_params
function Logger:writet(log_str, params, ...)
    local header = self:_make_header(log_str)
    local s
    if type(params) == "function" then
        params = params(...)
    end
    local args, arr
    if type(params.args) == "function" then
        args = params.args(table.unpack(params))
    else
        args = params.args
    end
    if params[1] then
        arr = params
    else
        arr = args
    end



    if params.msg then
        s = sf("[%s] %s", header, sf(params.msg, unpack(arr)))
    else
        local sep = params.sep or "\n\t"
        local key_sep = params.key_sep or "="
        local tbl = {}
        for _ ,v in ipairs(arr) do
            table.insert(tbl,v)
        end
        local starting_index
        if arr == args then
            starting_index = #args
        end
        -- `next, args, #arr` means "start iterating at the first non-integer index"
        for k,v in next, args, starting_index do
            table.insert(tbl, sf("%s%s%s", k, key_sep, v))
        end
        s = sf("[%s] %s", header, table.concat(tbl, sep))
    end

    
    if self.write_to_file ~= false then
        self.file:write(s .. "\n"); self.file:flush()
    else
       print(s)
    end
end






--[[## Write a warning message by passing in options as a table. 

The two main syntaxes are:
1) `sep`: defaults to "\n\t". The separator to use when printing multiple strings/numbers.
2) `msg`: If passed, then this message will be formatted with `string.format`, using `args` as the format parameters.

There are two ways to pass `args`:
1) As a table, e.g.,  `log:debug{args={"string1", "string2"}}`
2) As a function that returns a table, e.g., `log:debug{args=function() return {"string1", "string2"} end}`

Here are some examples:
- `log:warnt{msg="This %s message", args={"is a"}}` 
    --> "This is a message"
- `log:warnt{msg="The date is %s and the weather is %i degrees", args=function() return {"Tuesday", 20} end}`
    --> "The date is Tuesday and the weather is 20 degrees"
- `log:warnt{args={"Hello", "World", "It's lovely outside"}}`
    --> "Hello\n\tWorld\n\tIt's lovely outside"
- `log:warnt{sep=", ", args={"number1 = 10", "number2 = 15", "number3 = 20"}}`
    --> "number1 = 10, number2 = 15, number3 = 20"
]]
---@param self herbert.Logger
---@param write_params herbert.Logger.write_params
function Logger:warnt(write_params)
    if self.level >= LOG_LEVEL.WARN then 
        self:writet("WARN", write_params)
    end
end


--[[## Write an error message by passing in options as a table. 

The two main syntaxes are:
1) `sep`: defaults to "\n\t". The separator to use when printing multiple strings/numbers.
2) `msg`: If passed, then this message will be formatted with `string.format`, using `args` as the format parameters.

There are two ways to pass `args`:
1) As a table, e.g.,  `log:debug{args={"string1", "string2"}}`
2) As a function that returns a table, e.g., `log:debug{args=function() return {"string1", "string2"} end}`

Here are some examples:
- `log:warnt{msg="This %s message", args={"is a"}}` 
    --> "This is a message"
- `log:warnt{msg="The date is %s and the weather is %i degrees", args=function() return {"Tuesday", 20} end}`
    --> "The date is Tuesday and the weather is 20 degrees"
- `log:warnt{args={"Hello", "World", "It's lovely outside"}}`
    --> "Hello\n\tWorld\n\tIt's lovely outside"
- `log:warnt{sep=", ", args={"number1 = 10", "number2 = 15", "number3 = 20"}}`
    --> "number1 = 10, number2 = 15, number3 = 20"
]]
---@param write_params herbert.Logger.write_params
function Logger:errort(write_params, ...)
    if self.level >= LOG_LEVEL.ERROR then 
        self:writet("ERROR", write_params, ...)
    end
end

--[[## Write an info message by passing in options as a table. 

The two main syntaxes are:
1) `sep`: defaults to "\n\t". The separator to use when printing multiple strings/numbers.
2) `msg`: If passed, then this message will be formatted with `string.format`, using `args` as the format parameters.

There are two ways to pass `args`:
1) As a table, e.g.,  `log:debug{args={"string1", "string2"}}`
2) As a function that returns a table, e.g., `log:debug{args=function() return {"string1", "string2"} end}`

Here are some examples:
- `log:warnt{msg="This %s message", args={"is a"}}` 
    --> "This is a message"
- `log:warnt{msg="The date is %s and the weather is %i degrees", args=function() return {"Tuesday", 20} end}`
    --> "The date is Tuesday and the weather is 20 degrees"
- `log:warnt{args={"Hello", "World", "It's lovely outside"}}`
    --> "Hello\n\tWorld\n\tIt's lovely outside"
- `log:warnt{sep=", ", args={"number1 = 10", "number2 = 15", "number3 = 20"}}`
    --> "number1 = 10, number2 = 15, number3 = 20"
]]
---@param self herbert.Logger
---@param write_params herbert.Logger.write_params
function Logger:infot(write_params, ...)
    if self.level >= LOG_LEVEL.INFO then 
        self:writet("INFO", write_params, ...)
    end
end

--[[## Write a debug message by passing in options as a table. 

The two main syntaxes are:
1) `sep`: defaults to "\n\t". The separator to use when printing multiple strings/numbers.
2) `msg`: If passed, then this message will be formatted with `string.format`, using `args` as the format parameters.

There are two ways to pass `args`:
1) As a table, e.g.,  `log:debug{args={"string1", "string2"}}`
2) As a function that returns a table, e.g., `log:debug{args=function() return {"string1", "string2"} end}`

Here are some examples:
- `log:warnt{msg="This %s message", args={"is a"}}` 
    --> "This is a message"
- `log:warnt{msg="The date is %s and the weather is %i degrees", args=function() return {"Tuesday", 20} end}`
    --> "The date is Tuesday and the weather is 20 degrees"
- `log:warnt{args={"Hello", "World", "It's lovely outside"}}`
    --> "Hello\n\tWorld\n\tIt's lovely outside"
- `log:warnt{sep=", ", args={"number1 = 10", "number2 = 15", "number3 = 20"}}`
    --> "number1 = 10, number2 = 15, number3 = 20"
]]
---@param self herbert.Logger
---@param write_params herbert.Logger.write_params
function Logger:debugt(write_params, ...)
    if self.level >= LOG_LEVEL.DEBUG then 
        self:writet("DEBUG", write_params, ...)
    end
end

--[[## Write a trace message by passing in options as a table. 

The two main syntaxes are:
1) `sep`: defaults to "\n\t". The separator to use when printing multiple strings/numbers.
2) `msg`: If passed, then this message will be formatted with `string.format`, using `args` as the format parameters.

There are two ways to pass `args`:
1) As a table, e.g.,  `log:debug{args={"string1", "string2"}}`
2) As a function that returns a table, e.g., `log:debug{args=function() return {"string1", "string2"} end}`

Here are some examples:
- `log:warnt{msg="This %s message", args={"is a"}}` 
    --> "This is a message"
- `log:warnt{msg="The date is %s and the weather is %i degrees", args=function() return {"Tuesday", 20} end}`
    --> "The date is Tuesday and the weather is 20 degrees"
- `log:warnt{args={"Hello", "World", "It's lovely outside"}}`
    --> "Hello\n\tWorld\n\tIt's lovely outside"
- `log:warnt{sep=", ", args={"number1 = 10", "number2 = 15", "number3 = 20"}}`
    --> "number1 = 10, number2 = 15, number3 = 20"
]]
---@param self herbert.Logger
---@param write_params herbert.Logger.write_params
function Logger:tracet(write_params, ...)
    if self.level >= LOG_LEVEL.TRACE then 
        self:writet("TRACE", write_params, ...)
    end
end

end


local mcm_log_options = {}
for lvl = Logger.LEVEL.NONE, Logger.LEVEL.TRACE do
    local str = table.find(Logger.LEVEL,lvl)
    table.insert(mcm_log_options, {label=str, value=str})
end

local mcm_log_level_keys = { "logLevel", "log_level", "loggingLevel", "logging_level", "loggerLevel", "logger_level" }

---@class herbert.Logger.add_to_MCM_params
---@field component mwseMCMPage|mwseMCMSideBarPage|mwseMCMCategory The Page/Category to which this setting will be added.
---@field config table? the config to store the log_level in. Recommended. If not provided, the `log_level` will reset to "INFO" each time the mod is launched.
---@field createCategory boolean? should a subcategory be made for the log settings? Default: a new category will be created, so long as `component` is not a `mwseMCMCategory`
---@field label string? the label to be shown for the setting. Default: "Log Settings"
---@field description string? The description to show for the log settings. Usually not necesssary. If not provided, a default one will be provided.

--- Add this logger to the passed MCM category/page. You can pass arguments in a table or directly as function parameters.
---@param component_or_params herbert.Logger.add_to_MCM_params|table The parameters, or the Page/Category to which this setting will be added.
---@param config table? the config to store the log_level in 
---@param create_category boolean? should a subcategory be made for the log settings? makes it easier to read the description. default: true
function Logger:add_to_MCM(component_or_params, config, create_category)

    local label, description, component

    -- if it's not a page or category
    if type(component_or_params) == "table" and not component_or_params.componentType then 
        component = component_or_params.component
        config = config or component_or_params.config
        create_category = create_category or component_or_params.createCategory

        label = component_or_params.label
        description = component_or_params.description
    end

    component = component or component_or_params
    label = label or "Logging Level"


    if description == nil then 
        description = "\z
            Change the current logging settings. You can probably ignore this setting. A value of 'PROBLEMS' or 'INFO' is recommended, \n\z
            unless you're troubleshooting something. Each setting includes all the log messages of the previous setting. Here is an \z
            explanation of the options:\n\n\t\z
            \z
            NONE: Absolutely nothing will be printed to the log.\n\n\t\z
            \z
            ERROR: Error messages will be printed to the log.\n\n\t\z
            \z
            WARN: Warning messages will be printed to the log.\n\n\t\z
            \z
            INFO: Some basic behavior of the mod will be logged, but nothing extreme.\n\n\t\z
            \z
            DEBUG: A lot of the inner workings will be logged. You may notice a decrease in performance.\n\n\t\z
            \z
            TRACE: Even more internal workings will be logged. The log file may be hard to read, unless you have a specific thing you're looking for.\z
        \z
    "
    elseif description == false then 
        description = nil
    end

    
    local key
    if config then
        for _, log_level_key in ipairs(mcm_log_level_keys) do
            if config[log_level_key] then
                key = log_level_key
                break
            end
        end

        local config_log_level = config[key]

        -- convert old log levels to new ones
        if type(config_log_level) == "number" then

            if config_log_level == -1 then -- used to be "NONE"
                config_log_level = "NONE"
            elseif config_log_level == 0 then -- used to be "PROBLEMS"
                config_log_level = "WARN"
            elseif config_log_level == 1 then -- used to be "INFO"
                config_log_level = "INFO"
            elseif config_log_level == 2 then -- used to be "DEBUG"
                config_log_level = "DEBUG"
            elseif config_log_level == 3 then -- used to be "TRACE"
                config_log_level = "TRACE"
            end
            -- save the new `log_level` to the appropriate setting
            config[key] = config_log_level
        end


        self:set_level(config_log_level)
    -- `set_level` makes sure the value passed is a number, so it's chill
    end
    

    
        

    local log_settings -- this is where the new setting will be added.
    
    -- if `createCategory == true` or `createCategory` wasn't specified, and we aren't creating this component inside a category
    if create_category == true or (create_category == nil and component.componentType ~= "Category") then
        log_settings = component:createCategory{label="Log Settings", description = description}
    else
        log_settings = component
    end

    
    log_settings:createDropdown{label =label, description = description, options = mcm_log_options,
        variable = mwse.mcm.createCustom{
            getter=function () return self:get_level_str() end,
            setter=function (_, newValue) 
                self:set_level(newValue)
                self("updated log level to %s", self:get_level_str())

                if config and key then
                    config[key] = self:get_level_str()
                end
            end,
        },
    }
end


return Logger