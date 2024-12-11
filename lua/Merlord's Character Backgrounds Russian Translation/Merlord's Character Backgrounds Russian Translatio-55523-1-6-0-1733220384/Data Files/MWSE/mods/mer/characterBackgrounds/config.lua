
---@class CharacterBackgrounds.Config
local config = {}

config.configPath = "character_backgrounds"

---@class CharacterBackgrounds.Config.mcm
config.mcmDefault = {
    ---@type boolean Enable the mod
    enableBackgrounds = true,
    ---@type table<string, boolean> Whitelist of food that can be eaten by the green pact
    greenPactAllowed = {},
    ---@type number The interval in hours between rat king summons
    ratKingInterval = 24,
    ---@type number The chance for a rat to spawn each interval
    ratKingChance = 3,
    ---@type number The amount of gold the "Adopted by Nobles" background starts with
    inheritanceAmount = 2000,
    ---@type string The mod's log level
    logLevel = "INFO",
}

---@type CharacterBackgrounds.Config.mcm
config.mcm = mwse.loadConfig(config.configPath, config.mcmDefault)

---@class CharacterBackgrounds.Config.persistent
---@field currentBackground? string The id of the current background
---@field inBGMenu boolean Whether the background menu is open
---@field chargenFinished boolean Whether the player has finished chargen
local persistentDefault = {
}
---@type CharacterBackgrounds.Config.persistent
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data.merBackgrounds = tes3.player.data.merBackgrounds or {}
        table.copymissing(tes3.player.data.merBackgrounds, persistentDefault)
        return tes3.player.data.merBackgrounds[key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data.merBackgrounds = tes3.player.data.merBackgrounds or {}
        table.copymissing(tes3.player.data.merBackgrounds, persistentDefault)
        tes3.player.data.merBackgrounds[key] = value
    end
})

return config