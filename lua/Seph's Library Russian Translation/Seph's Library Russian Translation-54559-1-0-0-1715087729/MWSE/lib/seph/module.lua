local Class = require("seph.class")

--- @class Module : Class
--- @field id string The ID of the module. This is the same as the path of your module for the require/include functions, but relative to the mod's folder. This should not be changed manually.
--- @field mod Mod The mod this module belongs to. This should not be changed manually.
--- @field logger MWSELogger The logger of this module. This will automatically be generated by the mod. This should not be changed manually.
--- @field isRunning boolean Indicates if this module is already running. This should not be changed manually.
--- @field isEnabled boolean Indicates if this module has been enabled successfully. This should not be changed manually.
--- @field onRun fun(module: Module) Callback. Gets called after this module has been initialized and run by the mod.
--- @field onMorrowindInitialized fun(module: Module, eventData: initializedEventData) Callback. Gets called during the MWSE 'initialized' event.
--- @field onEnabled fun(module: Module) Callback. Gets called after this module has been enabled.
--- @field onDisabled fun(module: Module) Callback. Gets called after this module has been disabled.
local Module = Class("seph.Module")

function Module:initialize()
    self.id = ""
    self.mod = nil
    self.logger = nil
    self.isRunning = false
    self.isEnabled = false
    self.onLoaded = nil
    self.onMorrowindInitialized = nil
    self.onEnabled = nil
    self.onDisabled = nil
end

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

--- Runs the module. This is called automatically by the mod after it initialized all its modules and should not be called manually.
function Module:run()
    if self.isRunning then
        self.logger:error("Module is already running")
        error()
    end
    event.register("initialized",
        function(eventData)
            if self.onMorrowindInitialized then
                self:onMorrowindInitialized(eventData)
            end
        end
    )
    self.isRunning = true
    self.logger:debug("Running")
    if self.onRun then
        self:onRun()
    end
end

return Module