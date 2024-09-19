---@class SkillsModule.config
---@field playerData table<string, SkillsModule.Skill.data>
local config = {
    configPath = "SkillsModule"
}
config.metadata = toml.loadMetadata("Skills Module") --[[@as MWSE.Metadata]]

---@class SkillsModule.MCM
local mcmDefault = {
    logLevel = "INFO",
    fOtherSkillBonus = 1.25,
}
---@type SkillsModule.MCM
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)
---Save the current config.mcm to the config file
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end

setmetatable(config, {
    __index = function(_, k)
        if k == "playerData" then
            if not tes3.player then
                mwse.log("Tried to access `tes3.player.data.otherSkills` before player was loaded")
                return
            end
            tes3.player.data.otherSkills = tes3.player.data.otherSkills or {}
            return tes3.player.data.otherSkills
        end
    end
})
return config