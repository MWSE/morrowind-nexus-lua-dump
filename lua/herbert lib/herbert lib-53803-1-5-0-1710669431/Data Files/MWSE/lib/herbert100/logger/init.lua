--[[ # Logger 

Based on the `mwseLogger` made by Merlord.

Current version made by herbert100.

many suggestions and feature ideas given by C3pa

credit to Greatness7 as well, for the ideas of adding a `format` parameter and allowing functions to be passed to log messages.
]]

local colors = require("herbert100.logger.colors")
local socket = require("socket")
local fmt = string.format

local launch_time = socket.gettime()
-- local launch_time = 0

---@alias herbert.Logger.LEVEL
---|0                       NONE: Nothing will be printed
---|1                       ERROR: Error messages will be printed
---|2                       WARN: Warning messages will be printed
---|3                       INFO: Only crucial information will be printed
---|4                       DEBUG: Debug messages will be printed
---|5                       TRACE: Many debug messages will be printed
---|`Logger.LEVEL.NONE`     Nothing will be printed
---|`Logger.LEVEL.ERROR`    Error messages will be printed
---|`Logger.LEVEL.WARN`     Warning messages will be printed
---|`Logger.LEVEL.INFO`     Crucial information will be printed
---|`Logger.LEVEL.DEBUG`    Debug messages will be printed
---|`Logger.LEVEL.TRACE`    Many debug messages will be printed


---@class herbert.Logger.Record
---@field msg string|any|fun(...):... arguments passed to Logger:debug, Logger:info, etc
---@field args any[] arguments passed to Logger:debug, Logger:info, etc
---@field level herbert.Logger.LEVEL logging level
---@field line_number integer? the line number, if enabled for this logger
---@field timestamp number? the timestamp of this message


---@class herbert.Logger.new_params
---@field mod_name string? the name of the mod this logger is for
---@field mod_dir string? the name of the mod this logger is for
---@field level herbert.Logger.LEVEL? the log level to set this object to. Default: "LEVEL.INFO"
---@field module_name string|false? the module this logger belongs to, or `nil` if it's a general purpose logger
---@field include_line_number boolean? should the current line be printed when writing log messages? Default: `true`
---@field include_timestamp boolean? should the current time be printed when writing log messages? Default: `false`
---@field write_to_file string|boolean|nil whether to write the log messages to a file, or the name of the file to write to. if `false` or `nil`, messages will be written to `MWSE.log`
---@field format nil|(fun(self: herbert.Logger, record: herbert.Logger.Record): string) a way to specify how logging messages should be formatted


---@class herbert.Logger
---@operator call (herbert.Logger.new_params?): herbert.Logger
---@field mod_name string the name of the mod this logger is for
---@field level herbert.Logger.LEVEL
---@field file_path string the relative path to the file this logger was defined in.
---@field mod_dir string
---@field module_name string? the module this logger belongs to, or `nil` if it's a general purpose logger
---@field include_timestamp boolean? should the current time be printed when writing log messages? Default: `false`
---@field include_line_number boolean should the current time be printed when writing log messages? Default: `false`
---@field file file*? the file the log is being written to, if `write_to_file == true`, otherwise its nil.
---@field error fun(...): string write an error message
---@field warn fun(...): string write an warn message
---@field info fun(...): string write an info message
---@field debug fun(...): string write a debug message
---@field trace fun(...): string write a trace message
local Logger = {
    LEVEL = {
        NONE  = 0,
        ERROR = 1,
        WARN  = 2,
        INFO  = 3,
        DEBUG = 4,
        TRACE = 5
    },
    -- mod_name = nil,
    -- mod_dir = nil,
    module_name = nil,
    -- file_path = nil,
    include_line_number = true,
    level = 3,
    include_timestamp = false,
}
setmetatable(Logger, { __tostring = function() return "Logger" end })

local LOG_LEVEL = Logger.LEVEL
local LEVEL_STRINGS = table.invert(Logger.LEVEL)

local COLORS = {
	NONE  = "white",
	WARN  = "bright yellow",
	ERROR = "bright red",
	INFO  = "white",
    DEBUG = "bright green",
    TRACE = "bright white",
}

---@type table<string, herbert.Logger[]>
local loggers = {}

local communal_keys = {
    mod_name = true,
    mod_dir = true,
    include_line_number = true,
    write_to_file = true,
    level = true,
    include_timestamp = true,
    format = true,
}

-- metatable used by log objects
local log_metatable = {
    -- gonna override this later so that it's exactly equal to `Logger.debug`. this is needed for line number stuff to work properly
    __call = function(self, ...) self:debug(...) end,
    __index = Logger,
    __lt = function(num, self) return num < self.level end,
    __le = function(num, self) return num <= self.level end,
    __len = function(self) return self.level end,
    __newindex = function(self, k, v)
        if k == "logLevel" then
            -- this will upgrade everybody's log level
            self:setLogLevel(v)
        else
            rawset(self, k, v)
        end
    end,
    __concat = function(self, str) return self:new(str) end,
    
    __tostring = function(self)
        return fmt("Logger(mod_name: %q, module_name: %s, mod_dir: %q, level: %i (%s))",
            self.mod_name, self.module_name and fmt("%q", self.module_name), self.mod_dir, self.level, self:get_level_str()
        )
    end,
}

-- these will be checked against `new_info.source` to see whether we've gone too far up the stack when trying to get the filepath
-- of the file constructing this logger
local badfile_paths = {
    [string.lower("@Data Files\\MWSE\\core\\initialize.lua")] = true,
    [string.lower("@Data Files\\MWSE\\core\\startLuaMods.lua")] = true,
    [string.lower("@.\\Data Files\\MWSE\\lib\\herbert100\\logger\\init.lua")] = true,
    [string.lower("=[C]")] = true,
}


---@return string? mod_name, string? module_name, string? mod_dir
local function get_mod_info_from_source()

    -- =========================================================================
    -- generate relevant mod information
    -- =========================================================================

    

    -- iterate up a few times to get the correct path when people use logger factories
    -- i.e., we want to handle the case where a mod constructs a logger by 
    -- calling another function that constructs that logger

    local info, new_info
    local i = 2
    repeat
        i = i + 1
        info = new_info
        new_info = debug.getinfo(i, "S")
    until not new_info or badfile_paths[new_info.source:lower()]

    local src = info and info.source
    if not src then return end


    -- parts of the path without "@^\Data Files\MWSE\mods\"
    local lua_parts = table.filterarray(src:split("\\/"), function(i) return i >= 5 end)
    
    -- this happens if the logger is being constructed in a tail-recursive way
    if #lua_parts == 0 then return end

    local has_author_name = false


    -- first check for metadata when `lua_parts[1]` is the mod author directory
    local metadata = tes3.getLuaModMetadata(lua_parts[1] .. "." .. lua_parts[2]) ---@type MWSE.Metadata?
    if metadata then
        has_author_name = true
    else
        -- then check for metadata when `lua_parts[1]` is the mod root directory
        metadata = tes3.getLuaModMetadata(lua_parts[1])
    end
    if metadata then
        has_author_name = has_author_name or false
    else
        local one_dir_up = table.concat({"Data Files", "MWSE", "mods", lua_parts[1]}, "\\")
        local lfs = require("lfs")
        has_author_name = not (lfs.fileexists(one_dir_up .. "\\main.lua") or lfs.fileexists(one_dir_up .. "\\init.lua"))
        
    end


    -- =========================================================================
    -- use mod information to generate logger fields
    -- =========================================================================

    -- `mod_name` and `file_path` don't want the author folder, but `mod_dir `does.
    local mod_name, file_path, mod_dir
    if metadata then
        local package = metadata.package
        if package then
            ---@diagnostic disable-next-line: undefined-field
            mod_name = package.short_name or package.shortName or package.name
        end
        if metadata.tools and metadata.tools.mwse then
            mod_dir = metadata.tools.mwse["lua-mod"]
        end
    end

    -- actual mod information starts at index 2 if there's an author name
    local cutoff

    if has_author_name and #lua_parts > 2 then
        -- e.g. mod_dir = "herbert100.more quickloot"
        mod_dir = mod_dir or (lua_parts[1] .. "." .. lua_parts[2])
        cutoff = 2
    else
        -- e.g. mod_dir = "Expeditious Exit"
        mod_dir = mod_dir or lua_parts[1]
        cutoff = 1
    end
    -- if the module name doesn't exist, use the mod folder name (excluding the author name)
    mod_name = mod_name or lua_parts[cutoff]

    
    --[[ generate module name by combining everything together, ignoring the mod root.
        examples: 
            "herbert100/more quickloot/common.lua" ~> `file_path = "common.lua"`
            "herbert100/more quickloot/managers/organic.lua" ~> `file_path = "managers/organic.lua"`
    ]]
    file_path = table.concat(table.filterarray(lua_parts, function(i) return i > cutoff end), "/")

    return mod_name, file_path, mod_dir
end


--[[##Create a new logger for a mod with the specified `mod_name`. 

New objects can be created in the following ways:
- `log = Logger.new("modname")`
- `log = Logger.new{mod_name = "modname", level = LEVEL?, ...}`

In addition to `mod_name`, you may specify
- `level`: the logging level to start this logger at. This is the same as making a new logger and then calling `log:set_level(level)`
- `write_to_file`: either a boolean saying we should write to a file, or the name of a file to write to. If false (the default), then log messages will be written to `MWSE.log`
]]
---@param params herbert.Logger.new_params|string?
---@return herbert.Logger
function Logger.new(params, params2)
    if type(params) == "table" then
        if params == Logger then
            params = params2
        elseif getmetatable(params) == log_metatable then
            if type(params2) == "string" then
                params2 = {module_name=params2}
            end
            params2 = params2 or {} -- make sure `params2` exists
            for k,v in pairs(params) do
                if Logger[k] ~= v and params2[k] == nil then
                    params2[k] = v
                end
            end
            params = params2 -- rest of the code only cares about `params`
        end
    end
    if type(params) == "string" then
        params = {mod_name=params}
    end
    params = params or {}

    ---@diagnostic disable-next-line: undefined-field
    local mod_name = params.mod_name or params.name -- support old constructor
    local module_name = params.module_name
    -- do some error checking to make sure `params` are correct
    

    local src_mod_name, file_path, srcmod_dir = get_mod_info_from_source()

    local mod_dir = params.mod_dir or srcmod_dir
    
    -- use the folder name if no mod name was provided
    if mod_name and module_name == nil then
        local index = mod_name:find("/", 1, true)
        if index then
            -- mwse.log("index found in %q! updating mod name to %q and module name to %q",
            --     mod_name, mod_name:sub(1, index-1), mod_name:sub(index+1) or "N/A"
            -- )
            module_name = mod_name:sub(index+1)
            mod_name = mod_name:sub(1, index-1)
        end
    end
    mod_name = mod_name or src_mod_name


    assert(mod_name ~= nil, "[Logger: ERROR] Could not create a Logger because mod_name was nil.")
    assert(type(mod_name) == "string", "[Logger: ERROR] Could not create a Logger. mod_name must be a string.")

    

    -- first try to get it
    local log = Logger.get{mod_name=mod_name, module_name=module_name, file_path=file_path}

    if log then return log end

    -- now we know the log doesn't exist

    ---@diagnostic disable-next-line: missing-fields
    log = {
        mod_name = mod_name,
        mod_dir = mod_dir,
        module_name = module_name or nil,   -- make sure these are saved as `nil` instead of `false`, so `Logger.get` works properly
        file_path = file_path or nil,       -- make sure these are saved as `nil` instead of `false`, so `Logger.get` works properly
        level = Logger.level, -- we'll set it with the dedicated function so we can do fancy stuff
    }

    local logger_tbl = table.getset(loggers, mod_name, {})

    -- if there are already loggers with this `mod_name`, get the most recent one, and then
    -- update this new loggers values to those of the most recent logger.
    -- this is so that loggers "inherit" parameters from their siblings
    if #logger_tbl > 0 then
        local latest = logger_tbl[#logger_tbl]
        for k in pairs(communal_keys) do
            if rawget(log, k) == nil and rawget(latest, k) ~= nil then
                -- mwse.log("updating log[%s] = latest[%s] == %s", k, k, latest[k])
                log[k] = latest[k]
            end
        end
    end

    table.insert(logger_tbl, log)


    -- only print the warning after trying to import values from prior loggers
    if not log.mod_dir then
        log.mod_dir = mod_name
        -- who logs the logger?
        if log.module_name then
            print(fmt("[Logger: WARN] mod_dir for %q (module %q) was nil!", log.mod_name, log.module_name))
        else
            print(fmt("[Logger: WARN] mod_dir for %q was nil!", log.mod_name))
        end
    end


    setmetatable(log, log_metatable)
    -- support old syntax
    ---@diagnostic disable-next-line: undefined-field
    if params.logLevel then
        ---@diagnostic disable-next-line: deprecated, undefined-field
        log:setLogLevel(params.logLevel)
    end
    
    for k, v in pairs(params) do
        if communal_keys[k] then
            -- doing it this way so that we can respect custom set functions (i.e., `set_write_to_file`)
            -- for example, the code below will evaluate to 
            -- `log:set_write_to_file(rawget(log, "write_to_file") or v),
            -- rawget is used because some of the `params` got changed in the constructor, so the values stored in 
            -- `log` should take precedence over the ones stored in `params`
            -- `rawget` also ensures we don't look up missing (default) values in `Logger`
            Logger["set_" .. k](log, rawget(log, k) or v)
        end
    end
    

    return log
end

getmetatable(Logger).__call = Logger.new
getmetatable(Logger).__concat = Logger.new
log_metatable.__concat = Logger.new

-- updates a key for all loggers
---@param self herbert.Logger
---@param key string|number
---@param value any
local function update_key(self, key, value)
    for _, logger in ipairs(loggers[self.mod_name]) do
        logger[key] = value
    end
end

-- autogenerate methods to set communal keys. some of these will be overwritten later on.
-- the substring stuff is to to convert the first letter to uppercase, e.g. "set_level" instead of "setlevel"
for key in pairs(communal_keys) do
    Logger["set_" .. key] = function(self, value)
        update_key(self, key, value)
    end
end

---@param write_to_file string|boolean
---@param update_all_loggers boolean? should we update every other logger? Default: true
function Logger:set_write_to_file(write_to_file, update_all_loggers)
    if write_to_file == nil then return end

    if update_all_loggers == nil then update_all_loggers = true end

    local relevant_loggers = update_all_loggers and loggers[self.mod_name] or {self}

    if not write_to_file then
        for _, log in ipairs(relevant_loggers) do
            if log.file then 
                log.file:close()
                log.file = nil
            end
        end
        return
    end
    for _, log in ipairs(relevant_loggers) do
        local filename = write_to_file
        -- if it's `true` instead of a `string`, we should generate a valid filename.
        if write_to_file == true then
            if log.module_name then
                filename = fmt("Data Files\\MWSE\\mods\\%s\\%s.log",
                    log.mod_dir:gsub("%.", "\\"), 
                    log.module_name:gsub("%.lua$", ""):gsub("%.", "\\")
                )
            else
                filename = "Data Files\\MWSE\\mods\\" .. log.mod_dir:gsub("%.", "\\") .. ".log"
            end
        end
        -- close old file
        if log.file then
            log.file:close()
        end
        log.file = io.open(filename, "w")
    end
end

--[[Change the current logging level. You can specify a string or number.
e.g. to set the `log.level` to "DEBUG", you can write any of the following:
1) `log:set_level("DEBUG")`
2) `log:set_level(4)`
3) `log:set_level(Logger.LEVEL.DEBUG)`
]]
---@param self herbert.Logger
---@param level herbert.Logger.LEVEL
function Logger:set_level(level)
    -- no error message if `level` is `nil`
    if not level then return end
    if type(level) == "string" then
        level = LOG_LEVEL[level]
    end
    if not LEVEL_STRINGS[level] then return end

    update_key(self, "level", level)
end



--[[Get a previously registered logger with the specified `mod_dir`.]]
---@param mod_dir string name of the mod
---@param file_path string? the relative filepath of this logger
---@return herbert.Logger? logger
function Logger.get_by_dir(mod_dir, file_path)
    local logger_tbl ---@type herbert.Logger[]

    for _, loggers_by_mod_name in pairs(loggers) do
        if loggers_by_mod_name[1] and loggers_by_mod_name[1].mod_dir == mod_dir then
            logger_tbl = loggers_by_mod_name
            break
        end
    end

    if not logger_tbl then return end

    if not file_path then 
        return logger_tbl[1]
    end

    for _, log in ipairs(logger_tbl) do
        if log.file_path == file_path then
            return log
        end
    end
end

---@class herbert.Logger.get.params
---@field mod_name string
---@field module_name string|false? this will only be checked if it's not `nil`. `false` means: don't don't match module names.
---@field file_path string? this will only be checked if it evaluates to `true`.


-- get a new logger. you can pass either a `mod_name`, or a table containing a `mod_name`, `module_name`, and/or `file_path`.
-- the `module_name`s and `file_path`s of loggers will only be checked if the corresponding parameter evaluates to `true`
---@param p herbert.Logger.get.params|string
---@return herbert.Logger? logger
function Logger.get(p, p2)
    if not p then return end

    if type(p) == "table" and (p == Logger or getmetatable(p) == log_metatable) then
        p = p2
    end
    if type(p) == "string" then
        p = {mod_name=p}
    elseif not p.mod_name then 
        return
    end

    local logger_tbl = loggers[p.mod_name]

    if not logger_tbl then return end

    local module_name, file_path = p.module_name, p.file_path

    if module_name == nil and not file_path then 
        return logger_tbl[1]
    end

    for _, logger in ipairs(logger_tbl) do
        -- only check for equality if the relevant parameter was passed
        if  (file_path == nil or file_path == logger.file_path)
        and (module_name == nil or module_name == logger.module_name)
        then
            return logger
        end
    end
end


function Logger:get_level_str()
    return LEVEL_STRINGS[self.level]
end

--- returns all the loggers associated with this mod_name (can pass a Logger as well)
function Logger.get_loggers(mod_name) 
    return loggers[mod_name]
end



---@param args any[] arguments passed to Logger:debug, Logger:info, etc
---@param level herbert.Logger.LEVEL
---@param offset integer? for the line number to be accurate, this method assumes it's getting called 2 levels deep (i.e.). the offset adjusts this
---@return herbert.Logger.Record record
function Logger:make_record(msg, args, level, offset)
    return {
        msg = msg,
        args = args, 
        level = level,
        timestamp = self.include_timestamp and socket.gettime() or nil,
        line_number = self.include_line_number and debug.getinfo(3 + (offset or 0), "l").currentline or nil
    }
end

---@param logger herbert.Logger
---@param record herbert.Logger.Record
---@return string
local function make_header(logger, record)
    -- we're going to shove various things into here, and then making the string via
    -- `table.concat(header_t, " | ")
    local header_t = {}
    local name
    if logger.module_name then
        name = fmt("%s (%s)", logger.mod_name, logger.module_name)
    else
        name = logger.mod_name
    end
    if record.line_number then
        if logger.file_path then
            header_t = {name, fmt("%s:%i", logger.file_path, record.line_number)}
        else
            header_t = {fmt("%s:%i", name, record.line_number)}
        end
    else
        header_t = {name, logger.file_path}

    end
    local level_str = LEVEL_STRINGS[record.level]

    if mwse.getConfig("EnableLogColors") then
        -- e.g. turn "ERROR" into "ERROR" (but written in red)
        level_str = colors(fmt("%%{%s}%s", COLORS[level_str], level_str))
    end
    table.insert(header_t, level_str)

    if record.timestamp then
        local timestamp = record.timestamp - launch_time ---@type number
        local milliseconds = math.floor((timestamp % 1) * 1000)
        
        timestamp = math.floor(timestamp)
        local seconds = timestamp % 60
        local minutes = math.floor(timestamp / 60)
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60

        local formatted_time

       if hours ~= 0 then
            -- format time components into H:M:S.MS string
            formatted_time = fmt("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        else
            -- format time components into M:S.MS string
            formatted_time = fmt("%02d:%02d.%03d", minutes, seconds, milliseconds)
        end
        table.insert(header_t, formatted_time)
    end
    return table.concat(header_t, " | ")
end

-- default formatter. can be overridden by users
---@param record herbert.Logger.Record
---@return string
function Logger:format(record)

    local msg = record.msg
    local args = record.args
    local n = #args
    if n == 0 then
        -- dont change the message
    elseif type(msg) == "function" then
        -- everything was passed as a function
        msg = fmt(msg(table.unpack(args)))
    elseif type(args[1]) == "function" then
        -- formatting parameters were passed as a function
        if n == 1 then
            msg = fmt(msg, args[1]())
        else
            msg =  fmt(msg, args[1](table.unpack(args, 2)))
        end
    else
        -- nothing was passed as a function, format the message normally
        msg = fmt(msg, table.unpack(args))
    end
    return fmt("[%s] %s", make_header(self, record), msg)
end

-- calls format on the record and writes it to the appropriate location
---@param record herbert.Logger.Record
function Logger:write_record(record)
    local str = self:format(record)
    if self.file then
        self.file:write(str, "\n")
        self.file:flush()
    else
        print(str)
    end
end

-- make the logging functions
for level_str, level in pairs(LOG_LEVEL) do
    -- e.g., "DEBUG" -> "debug"
    ---@param self herbert.Logger
    Logger[string.lower(level_str)] = function(self, msg, ...)
        if self.level >= level then 
            self:write_record(self:make_record(msg, {...}, level))
        end
    end
end

-- i am a very good programmer
Logger.none = nil

-- update `call` to be the same as `debug`. this is so that the line numbers are pulled correctly when using the metamethod.
---@diagnostic disable-next-line: undefined-field
log_metatable.__call = Logger.debug


function Logger:assert(condition, msg, ...)
    if condition then return end

    -- cant call `Logger:error` because we need the call to `debug.getinfo` to produce the correct line number. super hacky :/
    local str = self:format(self:make_record(msg, {...}, LOG_LEVEL.ERROR))

    if self.level >= LOG_LEVEL.ERROR then
        if self.file then
            self.file:write(str, "\n")
            self.file:flush()
        else
            print(str)
        end
    end

    assert(condition, str)

end

function Logger:write_init_message(version)
    if self.level < Logger.LEVEL.INFO then return end

    if not version then
        local metadata = tes3.getLuaModMetadata(self.mod_dir)
        if metadata then
            version = metadata.package.version
        end
    end
    -- need to do it this way so the call to `debug.getinfo` produces the correct line number. super hacky :/
    local msg, args
    if version then
        msg, args = "Initialized version %s.", {version}
    else
        msg, args = "Mod initialized.", {}
    end
    self:write_record(self:make_record(msg, args, LOG_LEVEL.INFO))
end



-- =============================================================================
-- BACKWARDS COMPATIBILITY
-- =============================================================================


-- support the old way

---@deprecated use `set_level` instead
---@param level_str string
function Logger:setLogLevel(level_str)
    local level = level_str and LOG_LEVEL[level_str]
    if not level then return end

    update_key(self, "level", level)
end


-- support the old way

---@deprecated use `Logger.get` instead
Logger.getLogger = Logger.get


---@deprecated you can now write `logger.level <= Logger.LEVEL.DEBUG`. or, you can just pass all the arguments in with a function. e.g.,
    -- logger("objectType = %s. my_data = %s", function() return table.find(tes3.objectType, objType), json.encode(my_data) end)
    -- this function will only be evaluated at the appropriate logging level, so there's no performance hit.
function Logger:doLog(level_str)
    -- make sure they gave us a valid logging level, and that we are at or below that logging level
    return LOG_LEVEL[level_str] and LOG_LEVEL[level_str] <= self.level
end

local mcm_log_options = {}
for lvl = Logger.LEVEL.NONE, Logger.LEVEL.TRACE do
    local str = table.find(Logger.LEVEL,lvl)
    table.insert(mcm_log_options, {label=str, value=str})
end

local mcm_log_level_keys = {"logLevel", "log_level", "loggingLevel", "logging_level", "loggerLevel", "logger_level"}

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
    if cfg then
        return mwse.mcm.createTableVariable{ id=get_cfg_log_level_key(cfg), table=cfg, 
            converter=function(new_value) 
                log:set_level(new_value)
                log("updated log level to %s", log:get_level_str())
                return new_value
            end
        }
    end
    return mwse.mcm.createCustom{
        getter=function() return log:get_level_str() end,
        setter=function(_, new_value) 
            log:set_level(new_value)
            log("updated log level to %s", log:get_level_str())
        end,
    }
end

local old_levels = { [-1] = "NONE", [0] = "WARN", "INFO", "DEBUG", "TRACE", }
local default_MCM_description = "\z
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

---@class herbert.Logger.add_to_MCM_params
---@field component mwseMCMPage|mwseMCMSideBarPage|mwseMCMCategory The Page/Category to which this setting will be added.
---@field config table? the config to store the log_level in. Recommended. If not provided, the `log_level` will reset to "INFO" each time the mod is launched.
---@field create_category boolean? should a subcategory be made for the log settings? Default: a new category will be created, so long as `component` is not a `mwseMCMCategory`
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
        create_category = create_category or component_or_params.create_category

        label = component_or_params.label
        description = component_or_params.description
    end

    component = component or component_or_params
    label = label or "Logging Level"


    
    if description == nil then 
        description = default_MCM_description
    elseif description == false then 
        description = nil
    end

    
    if config then
        local key = get_cfg_log_level_key(config)
        if key then
            local config_log_level = config[key] 

            -- convert old log levels to new ones
            if type(config_log_level) == "number" then
                config_log_level = old_levels[config_log_level]
            end
            self:set_level(config_log_level)
            config[key] = self:get_level_str()
        end
    end
    

    
        

    local log_settings -- this is where the new setting will be added.
    
    -- if `create_category == true` or `create_category` wasn't specified, and we aren't creating this component inside a category
    if create_category == true or create_category == nil and component.componentType ~= "Category" then
        log_settings = component:createCategory{label="Log Settings", description = description}
    else
        log_settings = component
    end

    
    local setting = log_settings:createDropdown{label=label, description=description, 
        options=mcm_log_options, variable=make_MCM_variable(self, config)
    }
    description = nil
    log_settings = nil
    create_category = nil
    config = nil
    return setting
end

return Logger ---@type herbert.Logger