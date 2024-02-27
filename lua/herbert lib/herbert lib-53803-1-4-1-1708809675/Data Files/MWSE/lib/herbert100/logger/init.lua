--[[ # Logger 

Based on the `mwseLogger` made by Merlord.

Current version made by herbert100.
]]

local colors = require("herbert100.logger.colors")
local inspect = require "inspect"
local sf = string.format

local Logger_metatable = {
    -- make new loggers by calling `Logger`
    __call=function (cls, ...) return cls.new(...) end, -- gonna override this later
    __tostring = function(self) return "Logger" end
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
---@operator call (herbert.Logger.new_params?): herbert.Logger
---@field mod_name string the name of the mod this logger is for
---@field level herbert.Logger.LEVEL
---@field mod_dir string
---@field module_name string? the module this logger belongs to, or `nil` if it's a general purpose logger
---@field use_colors boolean should colors be used when writing log statements? Default: `false`
---@field write_to_file boolean if true, we will write the log contents to a file with the same name as this mod.
---@field include_timestamp boolean? should the current time be printed when writing log messages? Default: `false`
---@field include_line_number boolean should the current time be printed when writing log messages? Default: `false`
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
setmetatable(Logger, Logger_metatable)


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


local communal_keys = {
    mod_name = true,
    mod_dir = true,
    -- module_name = false,
    include_line_number = true,
    use_colors = true,
    write_to_file = true,
    level = true,
    include_timestamp = true,
}
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
        return sf("Logger(mod_name=%q, module_name=%s, mod_dir=%q, level=%i (%s))",
            self.mod_name, self.module_name and sf("%q", self.module_name), self.mod_dir, self.level, self:get_level_str()
        )
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


---@return string? mod_name, string? module_name, string? mod_dir
local function get_mod_info_from_source()

    -- =========================================================================
    -- generate relevant mod information
    -- =========================================================================

    local src = debug.getinfo(3, "S").source
    if not src then return end
    -- parts of the path without "@^\Data Files\MWSE\mods\"
    local lua_parts = table.filterarray(src:split("\\/"), function (i) return i >= 5 end)
    ---@type herbert.lib.utils.mod_info
    ---@diagnostic disable-next-line: missing-fields
    
    local has_author_name = false

    ---@type MWSE.Metadata?
    local metadata = tes3.getLuaModMetadata(lua_parts[1] .. "." .. lua_parts[2])
    if metadata then
        has_author_name = true
    else
        metadata = tes3.getLuaModMetadata(lua_parts[1])
    end
    if metadata then
        has_author_name = has_author_name or false
    else
        local one_dir_up = table.concat({"Data Files", "MWSE", "mods", lua_parts[1]}, "\\")
        has_author_name = not (lfs.fileexists(one_dir_up .. "\\main.lua") or lfs.fileexists(one_dir_up .. "\\init.lua"))
        
    end


    -- =========================================================================
    -- use mod information to generate logger fields
    -- =========================================================================

    -- `mod_name` and `module_name` don't want the author folder, but `mod_dir `does.
    local mod_name, module_name, mod_dir
    if metadata then
        local package = metadata.package ---@diagnostic disable-next-line: undefined-field
        mod_name = package.short_name or package.shortName or package.name 
    end

    -- actual mod information starts at index 2 if there's an author name
    local cutoff = has_author_name and 2 or 1

    -- if the module name doesn't exist, use the mod folder name (excluding the author name)
    mod_name = mod_name or lua_parts[cutoff]
    --[[ generate module name by combining everything together, ignoring the mod root.
        examples: 
            "herbert100/more quickloot/common.lua" ~> `module_name = "common.lua"`
            "herbert100/more quickloot/managers/organic.lua" ~> `module_name = "managers/organic.lua"`
    ]]
    module_name = table.concat(table.filterarray(lua_parts, function(i) return i > cutoff end), "/")
    if has_author_name then
        -- e.g. mod_dir = "herbert100.more quickloot"
        mod_dir = lua_parts[1] .. "." .. lua_parts[2]
    else
        -- e.g. mod_dir = "Expeditious Exit"
        mod_dir = lua_parts[1]
    end
    return mod_name, module_name, mod_dir
end


---@class herbert.Logger.new_params
---@field mod_name string? the name of the mod this logger is for
---@field mod_dir string? the name of the mod this logger is for
---@field level herbert.Logger.LEVEL|herbert.Logger.LEVEL_STRING|nil the log level to set this object to. Default: "INFO"
---@field module_name string? the module this logger belongs to, or `nil` if it's a general purpose logger
---@field use_colors boolean? should colors be used when writing log statements? Default: `false`
---@field include_line_number boolean? should the current line be printed when writing log messages? Default: `true`
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
---@param params herbert.Logger.new_params|string?
---@return herbert.Logger
function Logger.new(params, params2)
    -- if it's just a string, treat it as the `mod_name`
    if not params then
        params = {}
    elseif type(params) == "string" then
        params = {mod_name=params} 

    -- check if the user typed "Logger:new" instead of "Logger.new"
    elseif params == Logger then
        params = params2 or {}
        -- mwse.log("new was called on logger. making params = %s", inspect(params))

    -- check if the user called "log:new" (i.e., if they called `new` on a logger object)
    elseif getmetatable(params) == log_metatable then
        -- so, let's combine the data from the given logger
        -- mwse.log("logger made with logmetatable!")
        params2 = params2 or {} -- make sure `params2` exists
        table.copymissing(params2, params) -- copy over the stuff
        params = params2 -- rest of the code only cares about `params`
    end

    local mod_name, module_name = params.mod_name, params.module_name
    -- do some error checking to make sure `params` are correct
    
    
    local src_mod_name, src_module_name, src_mod_dir = get_mod_info_from_source()

    local mod_dir = params.mod_dir or src_mod_dir
    
    if mod_name then
        if not module_name then
            mod_name, module_name = get_mod_and_module_names(mod_name)
        end
    else
        mod_name = src_mod_name
    end
    module_name = module_name or src_module_name

    assert(mod_name ~= nil, "Error: Could not create a Logger because mod_name was nil.")
    assert(type(mod_name) == "string", "Error: Could not create a Logger. mod_name must be a string.")

    if not mod_dir then
        mod_dir = mod_name
        -- who logs the logger?
        mwse.log("[Logger: ERROR] mod_dir for %q (module %q) was nil! this isn't supposed to happen!!", mod_name, module_name)
    end

    -- first try to get it
    local log = Logger.get(mod_name, module_name)

    if log then return log end

    -- now we know the log doesn't exist

    log = {
        mod_name = mod_name,
        mod_dir = mod_dir,
        module_name = module_name,
        include_line_number = true,
        use_colors=params.use_colors or false,
        write_to_file = params.write_to_file or false,
        level = Logger.LEVEL.INFO, -- we'll set it with the dedicated function so we can do fancy stuff
        include_timestamp = params.include_timestamp or false,
    }

    -- mwse.log("making new log = %s", inspect(log))
    
    -- if there are already loggers with this `mod_name`, get the most recent one, and then
    -- update this new loggers values to those of the most recent logger. (if those values weren't specified in `params`)
    local logger_tbl = loggers[mod_name]
    if logger_tbl and #logger_tbl > 0 then
        -- mwse.log("logger tbl for %q is %s", mod_name, inspect(logger_tbl, {depth=2}))
        local latest = logger_tbl[#logger_tbl]
        -- mwse.log("latest logger is %s", inspect(latest, {depth=1}))
        
        for k in pairs(communal_keys) do
            if params[k] == nil then
                -- mwse.log("setting Logger(%s (%s))[%q] = %s", mod_name, module_name, k, latest[k])
                -- `log` metatable hasn't been set, so custom `__newindex` function won't be called
                log[k] = latest[k]
            end
        end
    else
        -- this is the first logger with this `mod_name`, so we should intialize the array
        logger_tbl = {}
        loggers[mod_name] = logger_tbl
    end

    -- mwse.log("updated log. it's now %s", inspect(log))

    table.insert(logger_tbl, log)

    setmetatable(log, log_metatable)
    -- this will update the logging level of all other registered loggers, but only if `params.level` exists and is valid 
    log:set_level(params.level)

    if params.write_to_file == nil then
        log:set_write_to_file(log.write_to_file, true)
    else
        log:set_write_to_file(params.write_to_file)
    end


    return log
end

Logger_metatable.__call = Logger.new

-- failsafe
for k in pairs(communal_keys) do
    Logger["set_" .. k] = function(self, v)
        for _, logger in ipairs(loggers[self.mod_name]) do
            logger[k] = v
        end
    end
end

---@param write_to_file string|boolean
---@param only_this_logger boolean? should we only update this logger? Default: false
function Logger:set_write_to_file(write_to_file, only_this_logger)
    if write_to_file == nil then return end

    local relevant_loggers = only_this_logger and {self} or loggers[self.mod_name]

    if not write_to_file then
        for _, log in ipairs(relevant_loggers) do
            if log.file then 
                log.file:close()
                rawset(log, "file", nil)
            end
            rawset(log, "write_to_file", false)
        end
        return
    end
    for _, log in ipairs(relevant_loggers) do
        local filename
        if write_to_file == true then
            if log.module_name then
                filename = sf("%s\\%s.log",log.mod_dir, log.module_name)
            else
                filename = log.mod_dir .. ".log"
            end
        else
            filename = write_to_file
        end
        -- close old file
        if log.file then
            log.file:close()
        end
       rawset(log, "file", io.open(filename, "w"))
       rawset(log, "write_to_file", true)
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
---@param mod_dir string name of the mod
---@param module_name string the name of the module
---@return herbert.Logger? logger
function Logger.get_by_dir(mod_dir, module_name)
    local logger_tbl

    for _, loggers_by_mod_name in pairs(loggers) do
        if loggers_by_mod_name[1].mod_dir == mod_dir then
            logger_tbl = loggers_by_mod_name
            break
        end
    end

    if not logger_tbl then return end

    if not module_name then 
        return logger_tbl[1]
    end

    for _, log in ipairs(logger_tbl) do
        if log.module_name == module_name then
            return log
        end
    end
end

---@param mod_name string name of the mod
---@param module_name string? the name of the module
---@return herbert.Logger? logger
function Logger.get(mod_name, module_name)
    local logger_tbl = loggers[mod_name]
    if not logger_tbl then 
        return 
    end
    if not module_name then 
        return logger_tbl[1]
    end

    for _, log in ipairs(logger_tbl) do
        if log.module_name == module_name then
            return log
        end
    end
end


function Logger:get_level_str()
    return table.find(Logger.LEVEL, self.level)
end

--- returns all the loggers associated with this mod_name (can pass a Logger as well)
function Logger.get_loggers(mod_name) 
    return loggers[mod_name]
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
    if lvl then 
        for _, logger in ipairs(loggers[self.mod_name]) do
            -- mwse.log("setting Logger(%s (%s)).level = %s", logger.mod_name, logger.module_name, lvl)

            logger.level = lvl
        end
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
    if self.include_line_number then
        local lineno = debug.getinfo(4,"l").currentline
        if self.module_name ~= nil then
            header_t = {self.mod_name, sf("%s:%i", self.module_name, lineno)}
            -- header_t[1] = sf("%s |%s:%i | ", self.mod_name, self.module_name, lineno)
        else
            header_t = {sf("%s:%i", self.mod_name, lineno)}
        end
    else
        header_t = {self.mod_name, self.module_name}
    end
    
    if self.use_colors then
        -- e.g. turn "ERROR" into "ERROR" (but written in red)
        log_str = colors(sf("%%{%s}%s", COLORS[log_str], log_str))
    end
    table.insert(header_t, log_str)
    if self.include_timestamp then
        local socket = require("socket")
        local timestamp = socket.gettime()
        local milliseconds = math.floor((timestamp % 1) * 1000)
        timestamp = math.floor(timestamp)

        -- convert timestamp to a table containing time components
        local timeTable = os.date("*t", timestamp)

        -- format time components into H:M:S:MS string
        local formattedTime = sf(": %02d:%02d:%02d.%03d", timeTable.hour, timeTable.min, timeTable.sec, milliseconds)
        table.insert(header_t, formattedTime)
    end
    return table.concat(header_t," | ")
end


---@class herbert.Logger.record
---@field level herbert.Logger.LEVEL
---@field line_number integer?
---@field time any?

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
            if n == 2 then
                s = sf("[%s] %s", header, sf( s1, s2() ) )
            else
                s = sf( "[%s] %s", header, sf(s1, s2(select(3, ...))))

                -- the commented out code works, but comes with a performance hit
                -- and (at the moment) i don't think it's worth it

                -- local params = debug.getinfo(s2, "u").nparams
                -- need to offset by 2 because `s1` and `s2` are counted in `n`
                -- if n - 2 > params then
                    -- pass arguments `3, ..., (3 + params - 1)` to `s2`
                    -- then pass the remaining arugments `(3 + params), ...` to `sf`
                    -- s = sf( "[%s] %s", header, sf( s1, s2(select(3, ...)), select(3 + params, ...) ) )
                -- else
                    -- pass all arguments to `s2`
                    -- this has to be done separately to allow `s2` to return multiple values
                    -- s = sf( "[%s] %s", header, sf(s1, s2(select(3, ...))))
                -- end
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
---@param ... any the strings to write the log
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
---@param ... any the strings to write the log
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
---@param ... any the strings to write the log
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
---@param ... any the strings to write the log
function Logger:debug(...)
    if self.level >= LOG_LEVEL.DEBUG then self:write("DEBUG", ...) end
end

log_metatable.__call = Logger.debug

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
---@param ... any the strings to write the log
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

--- get the log level key to use for the given config
---@param cfg table? config to search for 
local function get_cfg_log_level_key(cfg)
    if not cfg then return end
    for _, key in ipairs(mcm_log_level_keys) do
        if cfg[key] then return key end
    end
    return "log_level"
end

-- makes an MCM variable for the log settings
---@param log herbert.Logger
---@param cfg table? config table
---@return mwseMCMVariable
local function make_MCM_variable(log, cfg)
    local k = get_cfg_log_level_key(cfg)
    return mwse.mcm.createCustom{
        getter=function () return log:get_level_str() end,
        setter=function (_, newValue) 
            log:set_level(newValue)
            log("updated log level to %s", log:get_level_str())

            if k then cfg[k] = log:get_level_str() end
        end,
    }
end


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
---@return mwseMCMDropdown newly_created_setting
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

    
    if config then
        local key = get_cfg_log_level_key(config)
        if key then
            
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
            if config_log_level then
                self:set_level(config_log_level)
            end
            config[key] = self:get_level_str()
        end
    end
    

    
        

    local log_settings -- this is where the new setting will be added.
    
    -- if `createCategory == true` or `createCategory` wasn't specified, and we aren't creating this component inside a category
    if create_category == true or (create_category == nil and component.componentType ~= "Category") then
        log_settings = component:createCategory{label="Log Settings", description = description}
    else
        log_settings = component
    end

    
    local setting = log_settings:createDropdown{label =label, description = description, options = mcm_log_options, variable = make_MCM_variable(self,config) }
    description = nil
    log_settings = nil
    create_category = nil
    config = nil
    return setting
end

function Logger:write_init_message(version)
    if self.level < Logger.LEVEL.INFO then return end

    if not version then
        local metadata = tes3.getLuaModMetadata(self.mod_dir)
        if metadata then
            version = metadata.package.version
        end
    end
    -- need to do it this way so the call to `debug.getinfo` lines up. super hacky :/
    if version then
        self:write("INFO", "Initialized version %s.", version)
    else
        self:write("INFO", "Mod initialized.")
    end
end

return Logger ---@type herbert.Logger