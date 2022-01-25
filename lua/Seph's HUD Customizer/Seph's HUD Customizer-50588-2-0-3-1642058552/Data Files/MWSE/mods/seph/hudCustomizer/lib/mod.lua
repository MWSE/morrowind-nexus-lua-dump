local Class = require("seph.hudCustomizer.lib.class")
local Version = require("seph.hudCustomizer.lib.version")
local Logger = require("logging.logger")
local Config = require("seph.hudCustomizer.lib.config")
local Mcm = require("seph.hudCustomizer.lib.mcm")
local Module = require("seph.hudCustomizer.lib.module")
local tableExt = require("seph.hudCustomizer.lib.table")

--- @class Mod : Class
--- @field id string The ID of the mod. This should be the same as the path of your mod folder for the require/include functions. This should always be assigned before the initialize function gets called.
--- @field name string The display name of the mod. This should always be assigned before the initialize function gets called.
--- @field description string The description of the mod. This should be assigned before the initialize function gets called.
--- @field author string The author of this mod. This should be assigned before the initialize function gets called.
--- @field hyperlink string The hyperlink to your mod's web page. This should be assigned before the initialize function gets called.
--- @field version Version The version number of the mod. This should always be assigned before the initialize function gets called.
--- @field logger MWSELogger The logger of this mod. This will automatically be generated during initialization. This should not be changed manually.
--- @field loggers MWSELogger[] Contains loggers for all modules and other components of this mod. This will automatically be generated during initialization. This should not be changed manually.
--- @field config Config The config of this mod. This will automatically be generated during initialization if it has not been assigned.
--- @field mcm Mcm The MCM of this mod. This will automatically be generated during initialization if it has not been assigned.
--- @field modules Module[] The loaded modules of this mod. This will automatically be generated during initialization. This should not be changed manually.
--- @field moduleIds string[] The IDs of the modules of this mod. They should be the same as the path of your file for the require/include functions relative to your mod folder. This should always be assigned before initializiation and should not be changed afterwards.
--- @field isInitialized boolean Indicates if this mod has been initialized successfully. This should not be changed manually.
--- @field isEnabled boolean Indicates if this mod has been enabled successfully. This should not be changed manually.
local Mod = Class()

Mod.id = ""
Mod.name = ""
Mod.description = ""
Mod.author = ""
Mod.hyperlink = ""
Mod.version = nil
Mod.logger = nil
Mod.loggers = {}
Mod.config = nil
Mod.mcm = nil
Mod.modules = {}
Mod.moduleIds = {}
Mod.isInitialized = false
Mod.isEnabled = false

--- Callback. Can be overriden to provide functionality. Gets called after this mod and all modules have been intialized.
function Mod:onInitialized() end

--- Callback. Can be overriden to provide functionality. Gets called during the MWSE 'initialized' event.
--- @param eventData table The event data of the MWSE 'initialized' event.
function Mod:onMorrowindInitialized(eventData) end

--- Callback. Can be overriden to provide functionality. Gets called after this mod has been enabled.
function Mod:onEnabled() end

--- Callback. Can be overriden to provide functionality. Gets called after this mod has been disabled.
function Mod:onDisabled() end

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
    self:onEnabled()
end

--- Disables the mod and all its modules.
function Mod:disable()
    for _, module in pairs(self.modules) do
        module:disable()
    end
    self.isEnabled = false
    self.logger:debug("Disabled")
    self:onDisabled()
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

--- Creates a new mod or module specific logger and adds it to the mods logger list.
--- @param name string Optional. The name that will be appended to the logger name.
--- @return MWSELogger
function Mod:createLogger(name)
    assert(name == nil or type(name) == "string", "name must be a string or nil")
    if name == nil or name == "" then
        name = self.id
    else
        name = string.format("%s.%s", self.id, name)
    end
    local logger = Logger.new{name = name, logLevel = tableExt.getValueByPath(self, "config.current.logLevel") or "INFO"}
    table.insert(self.loggers, logger)
    return logger
end

--- Updates the log level of all loggers registered in this mod with the log level the user selected in the config.
function Mod:updateLogLevel()
    local logLevel = tableExt.getValueByPath(self, "config.current.logLevel") or "INFO"
    for _, logger in pairs(self.loggers) do
        logger:setLogLevel(logLevel)
    end
end

--- Initializes the config of this mod. If no config has been provided it will automatically search for a config.lua file to be included or create a basic one. This should not be called manually.
function Mod:initializeConfig()
    self.config = self.config or include(string.format("%s.config", self.id))
    if not Config:isClassOf(self.config) then
        self.logger:warn("Config not found or invalid, creating default")
        self.config = Config()
        self:updateLogLevel()
    end
    self.config.mod = self
    self.config.logger = self:createLogger("config")
    self.config:load(true)
    self.logger:debug("Initialized config")
end

--- Initializes the MCM of this mod. If no MCM has been provided it will automatically search for a mcm.lua file to be included or create a basic one. This should not be called manually.
function Mod:initializeMcm()
    self.mcm = self.mcm or include(string.format("%s.mcm", self.id))
    if not Mcm:isClassOf(self.mcm) then
        self.logger:warn("MCM not found or invalid, creating default")
        self.mcm = Mcm()
    end
    self.mcm.mod = self
    self.mcm.logger = self:createLogger("mcm")
    self.logger:debug("Initialized MCM")
end

--- Initializes all modules of this mod. This should not be called manually.
function Mod:initializeModules()
    self.modules = {}
    for _, moduleId in pairs(self.moduleIds) do
        assert(type(moduleId) == "string", "moduleId must be a string")
        local module = include(string.format("%s.%s", self.id, moduleId))
        if Module:isClassOf(module) then
            module.id = moduleId
            module.mod = self
            module.logger = self:createLogger(module.id)
            self.modules[module.id] = module
        else
            self.logger:warn(string.format("Module '%s' not found or invalid", moduleId))
        end
    end
    for _, module in pairs(self.modules) do
        module:initialize()
    end
    self.logger:debug(string.format("Initialized %d modules", table.size(self.modules)))
end

--- Initializes the mod.
function Mod:initialize()
    assert(type(self.id) == "string" and self.id ~= "", "id must be a non-empty string")
    assert(type(self.name) == "string" and self.name ~= "", "name must be a non-empty string")
    assert(type(self.description) == "string", "description must be a string")
    assert(type(self.author) == "string", "author must be a string")
    assert(type(self.hyperlink) == "string", "hyperlink must be a string")
    assert(type(self.version) == "table" or type(self.version) == "number" or type(self.version) == "string", "version must be a Version, table, string or number")
    assert(type(self.moduleIds) == "table", "moduleIds must be a table")

    self.isInitialized = false
    self.isEnabled = false
    self.version = Version.fromAny(self.version)
    self.logger = self:createLogger()
    self:initializeConfig()
    self:initializeMcm()
    self:initializeModules()

    event.register("initialized",
        function(eventData)
            self:onMorrowindInitialized(eventData)
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

    self.isInitialized = true
    self.logger:info(string.format("Initialized version %s", self.version:toString()))
    self:onInitialized()
end

return Mod