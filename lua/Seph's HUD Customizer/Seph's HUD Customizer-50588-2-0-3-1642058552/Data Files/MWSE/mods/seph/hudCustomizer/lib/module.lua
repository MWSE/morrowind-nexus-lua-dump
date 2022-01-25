local Class = require("seph.hudCustomizer.lib.class")

--- @class Module : Class
--- @field id string The ID of the module. This is the same as the path of your module for the require/include functions, but relative to the mod's folder. This should not be changed manually.
--- @field mod Mod The mod this module belongs to. This should not be changed manually.
--- @field logger MWSELogger The logger of this module. This will automatically be generated during initialization. This should not be changed manually.
--- @field isInitialized boolean Indicates if this module has been initialized successfully. This should not be changed manually.
--- @field isEnabled boolean Indicates if this module has been enabled successfully. This should not be changed manually.
local Module = Class()

Module.id = ""
Module.mod = nil
Module.logger = nil
Module.isInitialized = false
Module.isEnabled = false

--- Callback. Can be overriden to provide functionality. Gets called after this module has been intialized.
function Module:onInitialized() end

--- Callback. Can be overriden to provide functionality. Gets called during the MWSE 'initialized' event.
--- @param eventData table The event data of the MWSE 'initialized' event.
function Module:onMorrowindInitialized(eventData) end

--- Callback. Can be overriden to provide functionality. Gets called after this module has been enabled.
function Module:onEnabled() end

--- Callback. Can be overriden to provide functionality. Gets called after this module has been disabled.
function Module:onDisabled() end

--- Enables the module.
function Module:enable()
    self.isEnabled = true
    self.logger:debug("Enabled")
    if self.onEnabled then
        self:onEnabled()
    end
end

--- Disables the module.
function Module:disable()
    self.isEnabled = false
    self.logger:debug("Disabled")
    if self.onDisabled then
        self:onDisabled()
    end
end

--- Initializes the module.
function Module:initialize()
    event.register("initialized",
        function(eventData)
            if self.onMorrowindInitialized then
                self:onMorrowindInitialized(eventData)
            end
        end
    )
    self.isInitialized = true
    self.logger:debug("Initialized")
    if self.onInitialized then
        self:onInitialized()
    end
end

return Module