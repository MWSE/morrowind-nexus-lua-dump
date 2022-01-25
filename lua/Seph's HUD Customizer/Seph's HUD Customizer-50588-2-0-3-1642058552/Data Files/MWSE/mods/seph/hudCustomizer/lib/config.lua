local Class = require("seph.hudCustomizer.lib.class")
local Version = require("seph.hudCustomizer.lib.version")

--- @class ConfigUpdate : table
--- @field type string Determines the type of ConfigUpdate. Possible values are "file" and "version".
--- @field callback function The function to call when this ConfigUpdate gets applied. It has 2 parameters of type Config and ConfigUpdate respectively.
--- @field saveConfig boolean Optional. Defaults to false. Indicates if the current config should be saved immediately after this update has been applied. This does not update the config version. The config will be saved after applying all updates regardless of this setting.
--- @field fileName string Only valid for ConfigUpdates of type "file". File-type ConfigUpdates will trigger if a config file named as fileName exists in the MWSE config directory.
--- @field deleteFile boolean Optional. Defaults to false. Only valid for ConfigUpdates of type "file". Indicates if the config file defined in fileName should be deleted after this update has been applied.
--- @field version Version Only valid for ConfigUpdates of type "version". Version-type ConfigUpdates will trigger if the config file already exists and the current config's version is lower than this.

--- @class Config : Class
--- @field mod Mod The mod this config belongs to. This should not be changed manually.
--- @field logger MWSELogger The logger of this config. This will automatically be generated during initialization. This should not be changed manually.
--- @field current table The currently active config values. These are the values that will be saved or overriden when loaded.
--- @field default table The default config values. This should contain values for every possible non-dynamic config field.
--- @field persistent table The config fields that should always be present in the config and can not be removed. The assigned values are defaults only. Do not assign this directly or remove fields from it. Add fields to this table to expand it.
--- @field updates ConfigUpdate[] An array containing ConfigUpdates in the order they should execute in. This should always be assigned before initializiation.
--- @field autoClean boolean Indicates if the config should automatically be cleaned before saving it.
local Config = Class()

Config.mod = nil
Config.logger = nil
Config.current = {}
Config.default = {}
Config.persistent = {version = {major = 0, minor = 0, patch = 0}, enabled = true, logLevel = "INFO"}
Config.updates = {}
Config.autoClean = false

--- Callback. Can be overriden to provide functionality. Gets called before the config has been loaded from file.
function Config:onLoad() end

--- Callback. Can be overriden to provide functionality. Gets called after the config has been loaded from file.
function Config:onLoaded() end

--- Callback. Can be overriden to provide functionality. Gets called before the config has been saved to file.
function Config:onSave() end

--- Callback. Can be overriden to provide functionality. Gets called after the config has been saved to file.
function Config:onSaved() end

--- Callback. Can be overriden to provide functionality. Gets called after the config has been updated.
function Config:onUpdated() end

--- Gets the version from the current config.
--- @return Version
function Config:getVersion()
    return Version.fromAny(self.current.version)
end

--- Adds missing persistent config fields to the current config.
function Config:updatePersistentFields()
    table.copymissing(self.current, self.persistent)
end

--- Sets the current config version to the mod version.
function Config:updateVersion()
    self.current.version = self.mod.version:toTable()
end

--- Removes fields from the current config that do not exist in the default config. This can be used to purge old and/or unused config fields.
--- @param ignored table Optional. Defaults to an empty table. An array style table with indices to ignore at top level while cleaning the config. This can be used to preserve dynamic config data.
function Config:clean(ignored)
    assert(ignored == nil or type(ignored) == "table", "ignored must be a table or nil")
    local field = ""
    local function removeMissing(from, source, ignored)
        for index, value in pairs(from) do
            if not table.find(ignored or {}, index) and self.persistent[index] == nil then
                if source[index] == nil then
                    from[index] = nil
                    self.logger:debug(string.format("Cleaned field '%s'", field .. tostring(index)))
                elseif type(value) == "table" then
                    local previousField = field
                    field = string.format("%s%s.", field, tostring(index))
                    removeMissing(value, source[index])
                    field = previousField
                end
            end
        end
    end
    removeMissing(self.current, self.default, ignored)
    self.logger:debug("Cleaned")
end

--- Applies a single ConfigUpdate to this config, if applicable. Returns a boolean indicating if the update has been applied.
--- @param update ConfigUpdate The ConfigUpdate to apply to this config.
--- @return boolean
function Config:applyUpdate(update)
    assert(type(update) == "table", "update must be a table")
    assert(type(update.type) == "string" and update.type ~= "", "type must be a non-empty string")
    assert(type(update.callback) == "function", "callback must be a function")
    assert(update.saveConfig == nil or type(update.saveConfig) == "boolean", "saveConfig must be a boolean or nil")
    if update.type == "file" then
        assert(type(update.fileName) == "string" and update.fileName ~= "", "fileName must be a non-empty string")
        assert(update.deleteFile == nil or type(update.deleteFile) == "boolean", "deleteFile must be a boolean or nil")
        local filePath = string.format("%s\\Data Files\\MWSE\\config\\%s", tes3.installDirectory, update.fileName)
        if lfs.fileexists(filePath) then
            update.callback(self, update)
            self.logger:debug(string.format("Applied update for file '%s'", update.fileName))
            if update.saveConfig then
                self:save(false)
            end
            if update.deleteFile then
                assert(os.remove(filePath), string.format("unable to delete file '%s'", filePath))
                self.logger:debug(string.format("Deleted file '%s'", update.fileName))
            end
            return true
        end
    elseif update.type == "version" then
        assert(type(update.version) == "table" or type(update.version) == "number" or type(update.version) == "string", "version must be a Version, table, string or number")
        local version = Version.fromAny(update.version)
        if self:exists() and version:isGreaterThan(self:getVersion()) then
            update.callback(self, update)
            self.logger:debug(string.format("Applied update for version %s", version:toString()))
            if update.saveConfig then
                self:save(false)
            end
            return true
        end
    end
    return false
end

--- Updates the current config with the applicable updates defined in this config and saves it to file.
function Config:update()
    local updateCount = 0
    for _, update in ipairs(self.updates) do
        if self:applyUpdate(update) then
            updateCount = updateCount + 1
        end
    end
    if updateCount > 0 then
        self.mod:updateLogLevel()
        self.logger:debug(string.format("Applied %d updates", updateCount))
        self:save(true)
        if self.onUpdated then
            self:onUpdated()
        end
    end
end

--- Checks if the file of this config exists.
--- @return boolean
function Config:exists()
    return lfs.fileexists(string.format("%s\\Data Files\\MWSE\\config\\%s.json", tes3.installDirectory, self.mod.id))
end

--- Sets the current config to the default config. Also sets the current config version to the mod version.
function Config:reset()
    self.current = table.deepcopy(self.default)
    self:updatePersistentFields()
    self:updateVersion()
    self.mod:updateLogLevel()
    self.logger:debug("Reset")
end

--- Saves the current config to file. If desired it also sets the current config version to the mod version.
--- @param updateVersion boolean Optional. Defaults to true. The config will be updated after loading if this is true.
function Config:save(updateVersion)
    self:updatePersistentFields()
    if updateVersion == nil or updateVersion then
        self:updateVersion()
    end
    self.mod:updateLogLevel()
    if self.autoClean then
        self:clean()
    end
    if self.onSave then
        self:onSave()
    end
    mwse.saveConfig(self.mod.id, self.current)
    self.logger:debug("Saved")
    if self.onSaved then
        self:onSaved()
    end
end

--- Loads the current config from file. If desired it also updates the config.
--- @param update boolean Optional. Defaults to true. The config will be updated after loading if this is true.
function Config:load(update)
    if self.onLoad then
        self:onLoad()
    end
    self.current = mwse.loadConfig(self.mod.id, self.default)
    self:updatePersistentFields()
    self.mod:updateLogLevel()
    self.logger:debug("Loaded")
    if self.onLoaded then
        self:onLoaded()
    end
    if update == nil or update then
        self:update()
    end
end

return Config