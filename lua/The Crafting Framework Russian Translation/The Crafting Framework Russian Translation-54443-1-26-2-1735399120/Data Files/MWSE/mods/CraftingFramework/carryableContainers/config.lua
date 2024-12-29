---@class CarryableContainers.config
local config = {}
config.configPath = "carryableContainers"
config.registeredItemFilters = {}
config.registeredContainers = {}

---MCM
---@class CarryableContainers.config.MCM
local mcmDefault = {
    enabled = true,
    logLevel = "INFO",
    enableInfiniteStorage = false,
}
---@type CarryableContainers.config.MCM
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end

---Persistent
---@class CarryableContainers.config.persistent
local persistentDefault = {
    ---@type table<string, string> key: container copy id, value: container base id
    miscCopyToBaseMapping = {},
    miscCopyToContainerMapping = {},
    containerToMiscCopyMapping = {},
    ---@type table<string, string> A map between original and copied misc container Ids. Used to register copied containers on load
    containerCopies = {},
}
---@type CarryableContainers.config.persistent
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or {}
        table.copymissing(tes3.player.data[config.configPath], persistentDefault)
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or {}
        table.copymissing(tes3.player.data[config.configPath], persistentDefault)
        tes3.player.data[config.configPath][key] = value
    end
})

return config