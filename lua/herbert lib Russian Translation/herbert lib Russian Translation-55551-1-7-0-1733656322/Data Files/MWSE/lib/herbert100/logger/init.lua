--[[ # Logger 

Based on the `mwseLogger` made by Merlord.

Current version made by herbert100.

many suggestions and feature ideas given by C3pa

credit to Greatness7 as well, for the ideas of adding a `format` parameter and allowing functions to be passed to log messages.
]]
local Class = require("herbert100.Class")
local utils = require("herbert100.utils")
local tbl_ext = require("herbert100.tbl_ext")

local colors = require("herbert100.logger.colors")
local socket = require("socket")
local fmt = string.format

local LOG_LEVEL = {
    NONE  = 0,
    ERROR = 1,
    WARN  = 2,
    INFO  = 3,
    DEBUG = 4,
    TRACE = 5
}

local LEVEL_STRINGS = table.invert(LOG_LEVEL)

local COLORS = {
	NONE  = "white",
	WARN  = "bright yellow",
	ERROR = "bright red",
	INFO  = "white",
    DEBUG = "bright green",
    TRACE = "bright white",
}

---@type table<string, herbert.Logger[]>
local loggers_by_mod_name = {}

local communal_keys = {
    mod_name = true,
    mod_dir = true,
    include_line_number = true,
    write_to_file = true,
    level = true,
    include_timestamp = true,
    format = true,
}


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
---@field mod_name string? the name of the mod this logger is for. will be automatically retrieved if not provided
---@field mod_dir string? the name of the mod this logger is for. will be automatically retrieved if not provided
---@field file_path string? path to the file. will be retrieved if not provided
---@field level herbert.Logger.LEVEL? the log level to set this object to. Default: "LEVEL.INFO"
---@field module_name string|false? the module this logger belongs to, or `nil` if it's a general purpose logger
---@field include_line_number boolean? should the current line be printed when writing log messages? Default: `true`
---@field include_timestamp boolean? should the current time be printed when writing log messages? Default: `false`
---@field write_to_file string|boolean|nil whether to write the log messages to a file, or the name of the file to write to. if `false` or `nil`, messages will be written to `MWSE.log`
---@field format nil|(fun(self: herbert.Logger, record: herbert.Logger.Record): string) a way to specify how logging messages should be formatted


---@class herbert.Logger : herbert.Class
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
---@field new fun(params_or_mod_name: herbert.Logger.new_params|string|nil): herbert.Logger
local Logger = {LEVEL = LOG_LEVEL}

-- create a new logger by passing in a table with parameters or by passing in a string with just the `mod_name`
---@param params_or_mod_name herbert.Logger.new_params|string|nil
---@return herbert.Logger
function Logger.new(params_or_mod_name)
    return {}
end

Class.new({ name="Logger",
    fields={
        {"mod_name", eq=true},
        {"file_path", eq=true},
        {"mod_dir", eq=true},
        {"module_name", eq=true},
        {"level", factory=function() return 3 end, converter=function (v)
            -- if type(v) ~= "number" then return LOG_LEVEL[v] end
            return LOG_LEVEL[v] or LEVEL_STRINGS[v] and v
        end},
        {"include_line_number", default = true},
        {"write_to_file", default = false},
        {"include_timestamp", default = false},
        {"format", tostring=false},
    },
    obj_metatable={
        -- gonna override this later so that it's exactly equal to `Logger.debug`. this is needed for line number stuff to work properly
        __call = function(self, ...) self:debug(...) end,
        -- __index = Logger,
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
        __concat = function(self, str) 
            return self.new(tbl_ext.append_missing({module_name=str}, self)) 
        end,
    },
    -- create a new object, or return an existing one 
    ---@param params herbert.Logger.new_params|string?
    ---@return herbert.Logger|boolean|nil
    new_obj_func=function(params)
        local log
        if not params then
            log = {}
        elseif type(params) == "string" then
            log = {mod_name=params}
        else
            log = {
                ---@diagnostic disable-next-line: undefined-field
                mod_name = params.mod_name or params.name, -- support old constructor
                ---@diagnostic disable-next-line: undefined-field
                level = params.level or params.logLevel,  -- support old constructor
                file_path = params.file_path,
                mod_dir = params.mod_dir,
                module_name = params.module_name,
            }
        end

        if log.mod_name ~= nil and log.module_name == nil then
            local index = log.mod_name:find("/", 1, true)
            if index then
                log.module_name = log.mod_name:sub(index+1)
                log.mod_name = log.mod_name:sub(1, index-1)
            end
        end
        if log.mod_name == nil or log.mod_dir == nil or log.file_path == nil then
            local mod_info = utils.get_mod_info(2)
            if mod_info then
                log.mod_dir = log.mod_dir or mod_info.mod_dir
                log.mod_name = log.mod_name or mod_info.short_mod_name or mod_info.mod_name
                if log.file_path == nil then
                    local relative_path_start = mod_info.dir_has_author_name and 3 or 2
                    local relevant_parts = tbl_ext.splice(mod_info.lua_parts, relative_path_start)
                    log.file_path = table.concat(relevant_parts, "/")
                end
            end
        end

        assert(log.mod_name ~= nil, "[Logger: ERROR] Could not create a Logger because mod_name was nil.")
        assert(type(log.mod_name) == "string", "[Logger: ERROR] Could not create a Logger. mod_name must be a string.")

        -- if log.mod_dir and not log.level then
        --     -- use package system directly, so we don't cause circular import chains
        --     local cfg = package.loaded[log.mod_dir .. ".config"] or package.loaded[log.mod_dir .. ".config.init"]
        --     if cfg then
        --         log.level = cfg.log_level or cfg.logLevel
        --     end
        -- end

        return Logger.get(log) or log
    end,
    -- initialize the created object
    init=function(self, params)
        local logger_tbl = tbl_ext.getset(loggers_by_mod_name, self.mod_name, {})
        
        -- if the logger is already in the logger table, dont do anything
        if tbl_ext.any(logger_tbl, rawequal, self) then return end

        

        -- if there are already loggers with this `mod_name`, get the most recent one, and then
        -- update this new loggers values to those of the most recent logger.
        -- this is so that loggers "inherit" parameters from their siblings
        for k, sibling_val in pairs(logger_tbl[#logger_tbl] or {}) do
            if communal_keys[k] and rawget(self, k) == nil then
                rawset(self, k, sibling_val)
            end
        end

        table.insert(logger_tbl, self)


        -- only print the warning after trying to import values from prior loggers
        if not self.mod_dir then
            self.mod_dir = self.mod_name
            -- who logs the logger?
            if self.module_name then
                print(fmt("[Logger: WARN] mod_dir for %q (module %q) was nil!", self.mod_name, self.module_name))
            else
                print(fmt("[Logger: WARN] mod_dir for %q was nil!", self.mod_name))
            end
        end

        if type(params) ~= "table" then return end
        
        for k, param_value in pairs(params) do
            if communal_keys[k] then
                -- `new_value` may differ from `param_value` if it got updated in `new_obj_func`
                local new_value = rawget(self, k)
                if new_value == nil then
                    new_value = param_value
                end
                -- doing it this way so that we can respect custom set functions (i.e., `set_write_to_file`)
                Logger["set_" .. k](self, new_value)
            end
        end
    end,
    
}, Logger)


-- updates a key for all loggers
---@param self herbert.Logger
---@param key string|number
---@param value any
local function update_key(self, key, value)
    for _, logger in ipairs(loggers_by_mod_name[self.mod_name]) do
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

    local relevant_loggers = update_all_loggers and loggers_by_mod_name[self.mod_name] or {self}

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
                    log.mod_dir:gsub("[%./]", "\\"), 
                    log.file_path:gsub("%.lua$", ""):gsub("[%./]", "\\")
                )
            else
                filename = fmt("Data Files\\MWSE\\mods\\%s.log", log.mod_dir:gsub("[%./]", "\\"))
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
    -- make sure it's a valid logging level
    if LEVEL_STRINGS[level] then
        update_key(self, "level", level)
    end

end



--[[Get a previously registered logger with the specified `mod_dir`.]]
---@param mod_dir string name of the mod
---@param file_path string? the relative filepath of this logger
---@return herbert.Logger? logger
function Logger.get_by_dir(mod_dir, file_path)

    local _, logger_tbl = tbl_ext.any(loggers_by_mod_name, function(loggers)
        return loggers[1] and loggers[1].mod_dir == mod_dir 
    end)
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
function Logger.get(p)
    if not p then return end

    if Class.is_instance_of(p, Logger) then 
        ---@diagnostic disable-next-line: return-type-mismatch
        return p 
    elseif type(p) == "string" then
        p = {mod_name=p}
    elseif not p.mod_name then 
        return
    end

    local logger_tbl = loggers_by_mod_name[p.mod_name]

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
---@param mod_name_or_logger string|herbert.Logger
function Logger.get_loggers(mod_name_or_logger)
    if type(mod_name_or_logger) == "string" then
        return loggers_by_mod_name[mod_name_or_logger]
    elseif Class.is_instance_of(mod_name_or_logger, Logger) then
        return loggers_by_mod_name[mod_name_or_logger.mod_name]
    end
end



---@param level herbert.Logger.LEVEL
---@param offset integer? for the line number to be accurate, this method assumes it's getting called 2 levels deep (i.e.). the offset adjusts this
---@return herbert.Logger.Record record
function Logger:make_record(level, offset, ...)
    return {
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
---@param msg string|table|any|fun(...):...
---@param ... string|table|any|fun(...):...
---@return string
function Logger:format(record, msg, ...)

    local n, arg1 = select("#", ...), (select(1, ...))
    if n == 0 then
        -- dont change the message
    elseif type(msg) == "function" then
        -- everything was passed as a function
        msg = fmt(msg(...))
    elseif type(arg1) == "function" then
        -- formatting parameters were passed as a function
        if n == 1 then
            msg = fmt(msg, arg1())
        else
            msg =  fmt(msg, arg1(select(2, ...)))
        end
    else
        -- nothing was passed as a function, format the message normally
        msg = fmt(msg, ...)
    end
    return fmt("[%s] %s", make_header(self, record), msg)
end

-- calls format on the record and writes it to the appropriate location
---@param record herbert.Logger.Record
---@param ... any
function Logger:write_record(record, ...)
    local str = self:format(record, ...)
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
            self:write_record(self:make_record(level), msg, ...)
        end
    end
end

-- i am a very good programmer
Logger.none = nil

-- update `call` to be the same as `debug`. this is so that the line numbers are pulled correctly when using the metamethod.
Logger.__secrets.obj_metatable.__call = Logger.debug


function Logger:assert(condition, msg, ...)
    if condition then return end

    -- cant call `Logger:error` because we need the call to `debug.getinfo` to produce the correct line number. super hacky :/
    local str = self:format(self:make_record(LOG_LEVEL.ERROR), msg, ...)

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
    if version then
        self:write_record(self:make_record(LOG_LEVEL.INFO), "Initialized version %s.", version)
    else
        self:write_record(self:make_record(LOG_LEVEL.INFO), "Mod initialized.")
    end
end



-- =============================================================================
-- BACKWARDS COMPATIBILITY
-- =============================================================================


-- support the old way

---@deprecated use `set_level` instead
Logger.setLogLevel = Logger.set_level

---@deprecated use `Logger.get` instead
Logger.getLogger = Logger.get


---@deprecated you can now write `logger.level <= Logger.LEVEL.DEBUG`. or, you can just pass all the arguments in with a function. e.g.,
    -- logger("objectType = %s. my_data = %s", function() return table.find(tes3.objectType, objType), json.encode(my_data) end)
    -- this function will only be evaluated at the appropriate logging level, so there's no performance hit.
function Logger:doLog(level_str)
    -- make sure they gave us a valid logging level, and that we are at or below that logging level
    return LOG_LEVEL[level_str] and LOG_LEVEL[level_str] <= self.level
        or false
end
---@type mwseMCMDropdownOption[]
local mcm_log_options = {} ---@type mwseMCMDropdownOption[]

for str, lvl in pairs(LOG_LEVEL) do
    mcm_log_options[lvl + 1] = {label=str, value=lvl}
end

local mcm_log_level_keys = {"log_level", "logLevel", "loggingLevel", "logging_level", "loggerLevel", "logger_level"}

--- get the log level key to use for the given config
---@param cfg table config to search for 
local function get_cfg_log_level_key(cfg)
    for _, key in ipairs(mcm_log_level_keys) do
        if cfg[key] ~= nil then return key end
    end
    return "log_level"
end

local default_MCM_description = "\z
    Изменение текущих настроек ведения журнала событий. Вероятно, вы можете игнорировать эту настройку. Рекомендуется использовать значение 'INFO', \n\z
    если вы не занимаетесь отладкой. Каждый уровень включает в себя все сообщения предудущего уровня. \z
    Описание уровней :\n\n\t\z
    \z
    NONE: Выключен. Никакие записи о событиях и ошибках не будут записаны в журнал mwse.log.\n\n\t\z
    \z
    ERROR: Сообщения об ошибках будут выводиться в журнал.\n\n\t\z
    \z
    WARN: Предупреждающие сообщения будут выводиться в журнал.\n\n\t\z
    \z
    INFO: Некоторые базовые события мода будут выводиться в журнал.\n\n\t\z
    \z
    DEBUG: Большая часть внутренних процесов будет записываться в журнал. Вы можете заметить снижение производительности.\n\n\t\z
    \z
    TRACE: Еще больше внутренних операций будет записано в журнал. Файл журнала может быть трудно прочитать, если только вы не ищете что-то конкретное.\z
    \z
"

---@class herbert.Logger.add_to_MCM_params
---@field component mwseMCMPage|mwseMCMSideBarPage|mwseMCMCategory The Page/Category to which this setting will be added.
---@field config_key string|integer|nil default: `log_level`
---@field config table? the config to store the log_level in. Recommended. If not provided, the `log_level` will reset to "INFO" each time the mod is launched.
---@field label string? the label to be shown for the setting. Default: "Log Settings"
---@field description string? The description to show for the log settings. Usually not necesssary. If not provided, a default one will be provided.

--- Add this logger to the passed MCM category/page. You can pass arguments in a table or directly as function parameters.
---@param params herbert.Logger.add_to_MCM_params|mwseMCMCategory The parameters, or the Page/Category to which this setting will be added.
---@param ... any for backwrds compatibility
---@return mwseMCMDropdown newly_created_setting
function Logger:add_to_MCM(params, ...)

    ---@type mwseMCMCategory, table, boolean?, string?, string? integer|string?
    local parent_comp, config, create_category, label, description, config_key

    --backwards compatibility
    if params.componentType then
        parent_comp, config = params, ...
    elseif params then
        parent_comp = params.component
        config = params.config
        label, description = params.label, params.description
        config_key = params.config_key
    end

    label = label or "Уровень журнала"
    description = description or default_MCM_description

    config = assert(config or parent_comp.config, "Error: config not provided!")
    config_key = config_key or get_cfg_log_level_key(config)


    self:set_level(config[config_key])
    config[config_key] = self.level

    if create_category == true or create_category == nil and parent_comp.componentType ~= "Category" then
        parent_comp = parent_comp:createCategory{config=config, label="Настройки журнала", description=description}
    end

    
    return parent_comp:createDropdown{ 
        label = label,
        description = description,
        config = config,
        configKey = config_key,
        defaultSetting = parent_comp.defaultConfig and parent_comp.defaultConfig[config_key] or LOG_LEVEL.INFO,
        options = mcm_log_options, 
        converter = function(new_value)
            self:set_level(new_value)
            self("updated log level to %s", self:get_level_str())
            return new_value
        end
    }
end

return Logger ---@type herbert.Logger