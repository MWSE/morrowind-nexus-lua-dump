---@class BeenThereConfig
local config = {}
config.modName = "Been There, Done That"
config.configPath = "beenThere"
config.modDescription = [[
    This mod will display the text \"(Cleared)\" on the tooltips of doors
    leading to dungeons that you have previously cleared.
]]
config.minActorAiFightTrigger = 82

---@alias BeenThere.dungeonStatus
---| '"invalid"' # The cell did not have any hostiles when first entered
---| '"uncleared"' # The dungeon has enemies which need to be cleared
---| '"cleared"' # The dungeon has been cleared


---@class BeenThereConfig.persistent
local persistentDefault = {
    ---@type table<string, BeenThere.dungeonStatus> # A table of dungeon IDs and their status
    dungeons = {}
}

---@class BeenThereConfig.mcm
local mcmDefault = {
    enabled = true,
    logLevel = "INFO"
}

---@type BeenThereConfig.mcm
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)
---Save the current config.mcm to the config file
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end

---@type BeenThereConfig.persistent
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        tes3.player.data[config.configPath][key] = value
    end
})

return config