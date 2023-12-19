---@diagnostic disable: undefined-doc-name, param-type-mismatch

-- local LOG_LEVEL_STRINGS = {[0] = "NONE",  "INFO", "DEBUG", "TRACE"}
local Class = require("herbert100.Class")
local colors = require("herbert100.Logger.colors")
local loggers = {} ---@type table<string, Herbert_Logger>

---@class Herbert_Logger.new_params
---@field mod_name string the name of the mod this logger is for
---@field log_level Herbert_Logger.LOG_LEVELS? the log level to set this object to
---@field use_colors boolean?should colors be used when writing log statements?
---@field write_to_file boolean? if true, we will write the log contents to a file with the same name as this mod.

---@alias Herbert_Logger.LOG_LEVELS
---|"NONE"
---|"PROBLEMS"
---|"INFO"
---|"DEBUG"
---|"TRACE"
---|LOG_LEVEL

---@enum Herbert_Logger.LOG_LEVEL
local LOG_LEVEL = {NONE = -1, PROBLEMS = 0, INFO = 1, DEBUG = 2, TRACE = 3}
local COLORS = {
	NONE =  "white",
	WARN =  "bright yellow",
	ERROR =  "bright red",
	INFO =  "white",
    DEBUG = "bright green",
    TRACE =  "bright white",
}
--[[##Create a new logger for a mod with the specified `mod_name`. New objects can be created in the following ways:
- `log = Herbert_Logger("MOD_NAME")`
- `log = Herbert_Logger{mod_name="MOD_NAME", level=LEVEL?, ...}`
- `log = Herbert_Logger.new("MOD_NAME")`
- `log = Herbert_Logger.new{mod_name="MOD_NAME", level=LEVEL?, ...}`

Additionally you can add logging options to an MCM page/category by 
- passing in the component (and config table) to the constructor
- calling the `log:add_to_MCM(PAGE,CONFIG)` method.



Once a `log` has been created:
- The log level can be changed by using the `log:set_level(LOG_LEVEL)` method. `LOG_LEVEL` can be either
    - the numerical code of the `LOG_LEVEL` (ie -1,0, ..., 3), 
    - the string representing a numerical code (ie "NONE", "PROBLEMS", ..., "TRACE")

- you can log things by writing `log:info`, `log:warn`, `log:error`, `log:debug`, etc.
    - additionally, you can write debug messages by typing `log(str)`
    - all printing methods accept multiple parameters: 
        - if you write `log:info(str1,str2, ...)` then each string will be printed on a new line.

- as mentioned above, you can add it to an MCM page/category by using the `log:add_to_MCM` method.

- you can get the current `log_level` by typing either `log.level` or `#log`.
- if you want to test whether the log level is greater than a given number, you can write `log > NUMBER`.
    - NOTE: currently only the greater than option is supported, so you cant use the above syntax to test if the log is less than some number.
    - testing if the log level is smaller than some number can be done by writing `#log < NUMBER`.


]]
---@class Herbert_Logger : Class
---@field level Herbert_Logger.LOG_LEVEL
---@field use_colors boolean? should colors be used when writing log statements? default: false
---@field write_to_file boolean? if true, we will write the log contents to a file with the same name as this mod.
---@field mod_name string the name of the mod this logger is for
---@field file file? the file the log is being written to, if `write_to_file == true`, otherwise its nil.
local Herbert_Logger = Class({name = "Herbert Logger",
    obj_metatable = {
        __call = function(self, ...) self:debug(...) end,
        __lt = function(num, self) return num < self.level end,
        __le = function(num, self) return num <= self.level end,
        __len = function(self) return self.level end,
    },
    --- make a new object. we need to redefine this so that we can block object creation if the logger already exists
    ---@param params string|Herbert_Logger.new_params # either the parameters to make a new `Logger`, or just a string with the mod name. `params` will not be modified.
    ---@return Herbert_Logger obj
    new_obj_func = function(params)
        if type(params) == "string" then params = {mod_name=params} end

        -- if a logger for the given mod has already been made, then return that logger and move on
        if loggers[params.mod_name] then return loggers[params.mod_name] end

        local obj = { mod_name = params.mod_name, use_colors=params.use_colors, write_to_file = params.write_to_file}
        
        loggers[params.mod_name] = obj
        
        return obj -- this gets sent right into the `init` method below, but it's metatable gets set first.
    end,

    init = function(obj, params)
        obj:set_level(params.log_level)

        if obj.write_to_file then
            obj.file = io.open(obj.mod_name .. ".log", "w")
        else
            obj.write_to_file = false
        end
    end,

}, {use_colors = false, level = LOG_LEVEL.INFO, LOG_LEVELS = LOG_LEVEL, write_to_file = false})

--- get a previously registered logger, if it exists
---@param mod_name string name of the mod
---@return Herbert_Logger? logger
function Herbert_Logger.get(mod_name) return loggers[mod_name] end

--- write to log
---@param LOG_STR Herbert_Logger.LOG_LEVELS
function Herbert_Logger:write(LOG_STR,...)
    local s
    if select("#",...) == 1 then
        if self.use_colors then 
            s = string.format("[%s: %s] %s",
                self.mod_name, 
                
                colors(string.format("%%{%s}%s", COLORS[LOG_STR], LOG_STR)), 
                ...
            )
        else
            s = string.format("[%s: %s] %s", self.mod_name, LOG_STR, ...)
        end
    else
        if self.use_colors then 
            s = table.concat({
                string.format("[%s: %s] ", 
                    self.mod_name, 
                    colors(string.format("%%{%s}%s", COLORS[LOG_STR], LOG_STR))
                ),
                ...
            },"\n\t")
        else
            s = table.concat({
                string.format("[%s: %s] ", self.mod_name, LOG_STR), 
                ...
            },"\n\t")
        end
    end
    if self.write_to_file ~= false then
        ---@diagnostic disable-next-line: undefined-field
        self.file:write(s .. "\n"); self.file:flush()
    else
       print(s)
    end
end

--- set the `LOG_LEVEL` of this logger. you can specify a string or number.
---@param self Herbert_Logger
---@param log_level Herbert_Logger.LOG_LEVELS
function Herbert_Logger:set_level(log_level)
    if type(log_level) == "number" then 
        self.level = log_level
    elseif type(log_level) == "string" and LOG_LEVEL[log_level] then 
        self.level = LOG_LEVEL[log_level]
    end
end


--- write an error message, if the current `log_level` permits it. multiple arguments can be passed. each one will print on a new line.
---@param ... string the strings to write the log
function Herbert_Logger:error(...)
    if self.level >= LOG_LEVEL.PROBLEMS then self:write("ERROR", ...) end
end


--- write a warning message, if the current `log_level` permits it. multiple arguments can be passed. each one will print on a new line.
---@param ... string the strings to write the log
function Herbert_Logger:warn(...)
    if self.level >= LOG_LEVEL.PROBLEMS then self:write("WARN", ...) end
end

--- write an info message, if the current `log_level` permits it. multiple arguments can be passed. each one will print on a new line.
---@param ... string the strings to write the log
function Herbert_Logger:info(...)
    if self.level >= LOG_LEVEL.INFO then self:write("INFO", ...) end
end


--- write a debug message, if the current `log_level` permits it. multiple arguments can be passed. each one will print on a new line.
---@param ... string the strings to write the log
function Herbert_Logger:debug(...)
    if self.level >= LOG_LEVEL.DEBUG then self:write("DEBUG", ...) end
end

--- write a trace message, if the current `log_level` permits it. multiple arguments can be passed. each one will print on a new line.
---@param ... string the strings to write the log
function Herbert_Logger:trace(...)
    if self.level >= LOG_LEVEL.TRACE then self:write("TRACE", ...) end
end



--- add this logger to the passed MCM category/page.
---@param component mwseMCMPage|mwseMCMSideBarPage|mwseMCMCategory
---@param config table? the config to store the log_level in 
---@param create_category boolean? should a subcategory be made for the log settings? makes it easier to read the description. default: true
function Herbert_Logger:add_to_MCM(component, config,create_category)

    -- `set_level` makes sure the value passed is a number, so it's chill
    if config then self:set_level(config.log_level) end

    local log_options = {}
    local i
    for str, num in pairs(LOG_LEVEL) do
        i = num + 2 -- `LOG_LEVEL` starts at -1, and we want `log_options` to start at 1.
        log_options[i] = {label = str, value = num}
    end
        
    local log_desc = "\z
        Change the current logging settings. You can probably ignore this setting. A value of 'PROBLEMS' or 'INFO' is recommended, \n\z
        unless you're troubleshooting something. Each setting includes all the log messages of the previous setting. Here is an \z
        explanation of the options:\n\n\t\z
        \z
        NONE: Absolutely nothing will be printed to the log.\n\n\t\z
        \z
        PROBLEMS: If the mod has any problems, those will be written to the log. Nothing else will be written to the log.\n\n\t\z
        \z
        INFO: Some basic behavior of the mod will be logged, but nothing extreme.\n\n\t\z
        \z
        DEBUG: A lot of the inner workings will be logged. You may notice a decrease in performance.\n\n\t\z
        \z
        TRACE: Even more internal workings will be logged. The log file may be hard to read, unless you have a specific thing you're looking for.\z
        \z
    "

    local log_settings -- this is where the new setting will be added.
    
    -- if `create_category == true` or `create_category` wasn't specified,
    if create_category == true or create_category == nil then
        log_settings = component:createCategory{label="Log Settings", description = log_desc}
    else
        log_settings = component
    end
    log_settings:createDropdown{
        label = "Logging level",
        description = log_desc,
        options = log_options,
        variable = (config and mwse.mcm.createTableVariable{ id = "log_level", table = config}) or nil,
        callback = function (dropdown)
            self:set_level(dropdown.variable.value)
            self("updated log level to " .. self.level)
        end
    }
end
return Herbert_Logger