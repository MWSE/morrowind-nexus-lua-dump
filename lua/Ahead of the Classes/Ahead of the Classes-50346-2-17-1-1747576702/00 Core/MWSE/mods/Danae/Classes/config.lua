
---@class AheadOfTheClasses.Config
local config = {}

---@class AheadOfTheClasses.Config.MCM
local mcmDefault = {
    enableSpells = true,
    enableGear = true,
}

---@type AheadOfTheClasses.Config.MCM
config.mcm = mwse.loadConfig("AheadOfTheClasses", mcmDefault)

config.save = function()
    mwse.saveConfig("AheadOfTheClasses", config.mcm)
end

return config