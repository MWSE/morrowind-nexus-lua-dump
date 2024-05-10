local Class = require("seph.class")
local Version = require("seph.version")
local Config = require("seph.config")
local Mcm = require("seph.mcm")
local Module = require("seph.module")
local tableExtensions = require("seph.table")
local Logger = require("logging.logger")

--- @type table<string, Mod>[] Contains every registered mod indexed by its id.
local mods = {}

--- @class Mod : Class
--- @field id string The ID of the mod. This must be the same as the path of your mod folder for the require/include functions. This must be assigned before running the mod.
--- @field name string The display name of the mod. This must be assigned before running the mod.
--- @field description string The description of the mod. This should be assigned before running the mod.
--- @field author string The author of this mod. This should be assigned before running the mod.
--- @field hyperlink string The hyperlink to your mod's web page. This should be assigned before running the mod.
--- @field version Version The version number of the mod. This must be assigned before running the mod.
--- @field logger MWSELogger The logger of this mod. This will automatically be generated. This should not be changed manually.
--- @field loggers MWSELogger[] Contains loggers for all modules and other components of this mod. This will automatically be generated. This should not be changed manually.
--- @field config Config The config of this mod. This will automatically be generated if it has not been assigned.
--- @field mcm Mcm The MCM of this mod. This will automatically be generated if it has not been assigned.
--- @field modules Module[] The loaded modules of this mod. This will automatically be generated. This should not be changed manually.
--- @field requiredModules string[] The IDs of the modules required by this mod. They should be the same as the path of your file for the require/include functions relative to your mod folder. This should be assigned before running the mod and should not be changed afterwards.
--- @field requiredMwseBuildDate number The minimum build date of MWSE required for this mod. This should be assigned before running the mod and should not be changed afterwards.
--- @field requiredPlugins string[] The names of the plugin files required by this mod. This includes esp, as well as esm files. This should be assigned before running the mod and should not be changed afterwards.
--- @field isRunning boolean Indicates if this mod is already running. This should not be changed manually.
--- @field isEnabled boolean Indicates if this mod has been enabled successfully. This should not be changed manually.
--- @field onRun fun(mod: Mod) Callback. Gets called after this mod has been run.
--- @field onMorrowindInitialized fun(mod: Mod, eventData: initializedEventData) Callback. Gets called during the MWSE 'initialized' event.
--- @field onEnabled fun(mod: Mod) Callback. Gets called after this mod has been enabled.
--- @field onDisabled fun(mod: Mod) Callback. Gets called after this mod has been disabled.
local Mod = Class("seph.Mod")

function Mod:initialize()
    self.id = ""
    self.name = ""
    self.description = ""
    self.author = ""
    self.hyperlink = ""
    self.version = Version()
    self.logger = nil
    self.loggers = {}
    self.config = nil
    self.mcm = nil
    self.modules = {}
    self.requiredModules = {}
    self.requiredMwseBuildDate = nil
    self.requiredPlugins = {}
    self.isRunning = false
    self.isEnabled = false
    self.onRun = nil
    self.onMorrowindInitialized = nil
    self.onEnabled = nil
    self.onDisabled = nil
end

--- Registers the mod. This is called automatically and should not be called manually. An error will be thrown if it is already registered.
function Mod:register()
    if mods[self.id] then
        self.logger:error("Mod is already registered")
        error()
    end
    mods[self.id] = self
end

--- Gets the mod's directory relative to the Morrowind installation directory.
function Mod:getDirectory()
    return "Data Files\\MWSE\\mods\\" .. string.gsub(self.id, "%.", "\\")
end

--- Enables the mod and all its modules.
function Mod:enable()
    for _, module in pairs(self.modules) do
        module:enable()
    end
    self.isEnabled = true
    self.logger:debug("Enabled")
    if self.onEnabled then
        self:onEnabled()
    end
end

--- Disables the mod and all its modules.
function Mod:disable()
    for _, module in pairs(self.modules) do
        module:disable()
    end
    self.isEnabled = false
    self.logger:debug("Disabled")
    if self.onDisabled then
        self:onDisabled()
    end
end

--- Enables or disables the mod and all its modules. Does not enable/disable if it already is enabled/disabled.
--- @param enabled boolean The enabled state this mod should transition to.
function Mod:enableOrDisable(enabled)
    assert(type(enabled) == "boolean", "enabled must be a boolean")
    if self.isEnabled and not enabled then
        self:disable()
    elseif not self.isEnabled and enabled then
        self:enable()
    end
end

--- Creates a new mod specific logger and adds it to the mods logger list.
--- @param name string Optional. The name that will be appended to the logger name.
--- @return MWSELogger
function Mod:createLogger(name)
    assert(name == nil or type(name) == "string", "name must be a string or nil")
    if name == nil or name == "" then
        name = self.id
    else
        name = string.format("%s.%s", self.id, name)
    end
    local logger = Logger.new{name = name, logLevel = tableExtensions.getValueByPath(self, "config.current.logLevel") or "INFO"}
    table.insert(self.loggers, logger)
    return logger
end

--- Updates the log level of all loggers registered in this mod with the log level the user selected in the config.
function Mod:updateLogLevel()
    local logLevel = tableExtensions.getValueByPath(self, "config.current.logLevel") or "INFO"
    for _, logger in pairs(self.loggers) do
        logger:setLogLevel(logLevel)
    end
end

--- Checks if the MWSE build date is greater or equal to the required build date. An error will be raised and a mesage box will be shown if the MWSE build date is less than the required build date.
function Mod:checkRequiredMwseBuildDate()
    assert(self.requiredMwseBuildDate == nil or type(self.requiredMwseBuildDate) == "number", "requiredMwseBuildDate must be a number or nil")
    if self.requiredMwseBuildDate and (mwse.buildDate == nil or mwse.buildDate < self.requiredMwseBuildDate) then
        local message = string.format("'%s' requires a more recent build of MWSE. Please close Morrowind and run 'MWSE-Update.exe' to update MWSE.", self.name)
        event.register("enterFrame",
            function()
                tes3.messageBox{message = message, buttons = {"Okay"}}
            end,
            {doOnce = true}
        )
        self.logger:error(string.format("MWSE build date '%d' is required", self.requiredMwseBuildDate))
        error()
    end
end

--- Checks if all the required plugins are activated. An error will be raised and a mesage box will be shown if any required plugin is not activated.
function Mod:checkRequiredPlugins()
    assert(type(self.requiredPlugins) == "table", "requiredPlugins must be a table")
    for _, plugin in pairs(self.requiredPlugins) do
        if not tes3.isModActive(plugin) then
            local message = string.format("'%s' requires the '%s' plugin to be activated. Please close Morrowind and activate the plugin.", self.name, plugin)
            event.register("enterFrame",
                function()
                    tes3.messageBox{message = message, buttons = {"Okay"}}
                end,
                {doOnce = true}
            )
            self.logger:error(string.format("Plugin '%s' is required and not active", plugin))
            error()
        end
    end
end

--- Initializes the config of this mod. If no config has been provided it will automatically search for a config.lua file to be used instead. This is called automatically and should not be called manually.
function Mod:initializeConfig()
    self.config = self.config or require(string.format("%s.config", self.id))
    if not Config:isClassOf(self.config) then
        self.logger:error("Config is invalid")
        error()
    end
    self.config.mod = self
    self.config.logger = self:createLogger("config")
    self.config:load(true)
    self.logger:debug("Initialized config")
end

--- Initializes the MCM of this mod. If no MCM has been provided it will automatically search for a mcm.lua file to be used instead. This is called automatically and should not be called manually.
function Mod:initializeMcm()
    self.mcm = self.mcm or require(string.format("%s.mcm", self.id))
    if not Mcm:isClassOf(self.mcm) then
        self.logger:error("MCM is invalid")
        error()
    end
    self.mcm.mod = self
    self.mcm.logger = self:createLogger("mcm")
    self.logger:debug("Initialized MCM")
end

--- Initializes and runs all modules of this mod. This is called automatically and should not be called manually.
function Mod:initializeModules()
    assert(type(self.requiredModules) == "table", "requiredModules must be a table")
    self.modules = {}
    for _, requiredModule in pairs(self.requiredModules) do
        assert(type(requiredModule) == "string", "requiredModule must be a string")
        local module = require(string.format("%s.%s", self.id, requiredModule))
        if Module:isClassOf(module) then
            module.id = requiredModule
            module.mod = self
            module.logger = self:createLogger(module.id)
            self.modules[module.id] = module
        else
            self.logger:error(string.format("Module '%s' is invalid", requiredModule))
            error()
        end
    end
    for _, module in pairs(self.modules) do
        module:run()
    end
    self.logger:debug(string.format("Initialized %d modules", table.size(self.modules)))
end

--- Runs the mod. Initializes all of the mods components and registers it to be enabled once Morrowind has been initialized. All the required and optional data of the mod must have been set before calling this function. This must be called before the MWSE 'initialized' event gets triggered and must only be called once.
function Mod:run()
    assert(type(self.id) == "string" and self.id ~= "", "id must be a non-empty string")
    assert(type(self.name) == "string" and self.name ~= "", "name must be a non-empty string")
    assert(type(self.description) == "string", "description must be a string")
    assert(type(self.author) == "string", "author must be a string")
    assert(type(self.hyperlink) == "string", "hyperlink must be a string")
    assert(type(self.version) == "table" or type(self.version) == "number" or type(self.version) == "string", "version must be a Version, table, string or number")

    if self.isRunning then
        self.logger:error("Mod is already running")
        error()
    end

    self.version = Version.fromAny(self.version)
    self.logger = self:createLogger()
    self:checkRequiredMwseBuildDate()
    self:initializeConfig()
    self:initializeMcm()
    self:initializeModules()

    event.register("initialized",
        function(eventData)
            self:checkRequiredPlugins()
            if self.onMorrowindInitialized then
                self:onMorrowindInitialized(eventData)
            end
            if self.config.current.enabled then
                self:enable()
            end
        end
    )

    event.register("modConfigReady",
        function()
            self.mcm:create()
        end
    )

    self:register()
    self.isRunning = true
    self.logger:info(string.format("Running version %s", self.version:toString()))
    if self.onRun then
        self:onRun()
    end
end

return Mod