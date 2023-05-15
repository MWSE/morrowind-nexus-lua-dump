---@class Settings
local this = {}

---@class PortraitProfile
---@field enable boolean
---@field path string
---@field width integer
---@field height integer
---@field cropWidth number

---@class Config
this.defaultConfig = {
    enable = true,
    useCharacterProfile = true,
    ---@type PortraitProfile
    global = {
        enable = true,
        path = "MWSE/mods/longod/CustomPortrait/portrait.dds",
        width = 512,
        height = 512,
        cropWidth = 0.5,
    },
}
this.config = nil ---@type Config
this.configPath = "longod.CustomPortrait"
this.showPortrait = true -- toggle portrait

---@return Config
function this.Load()
    this.config = this.config or mwse.loadConfig(this.configPath, this.defaultConfig)
    return this.config
end

---@return Config
function this.Default()
    return table.deepcopy(this.defaultConfig)
end

---@param self Settings
---@return PortraitProfile?
function this.GetCharacterProfile(self)
    if not tes3.onMainMenu() and tes3.player and tes3.player.data then
        if tes3.player.data.customPortrait == nil then
            -- not yet allocated
            -- mwse.log("player.data.customPortrait not found")
            return table.deepcopy(self.Load().global)
        end
        return tes3.player.data.customPortrait
    end
    return nil
end

---@param self Settings
---@param characterProfile PortraitProfile?
function this.SetCharacterProfile(self, characterProfile)
    local config = self.Load()
    if config.enable and config.useCharacterProfile then
        if not tes3.onMainMenu() and tes3.player and tes3.player.data then
            if tes3.player.data.customPortrait == nil then
                --mwse.log("set to player.data.customPortrait")
                tes3.player.data.customPortrait = characterProfile
                return tes3.player.data.customPortrait
            end
        end
    end
    return nil
end

---@param self Settings
---@return PortraitProfile?
function this.GetProfile(self)
    local config = self.Load()
    if config.enable then
        if config.useCharacterProfile and not tes3.onMainMenu() and tes3.player and tes3.player.data then
            local profile = tes3.player.data.customPortrait
            if profile == nil then
                profile = self:SetCharacterProfile(self:GetCharacterProfile())
            end
            if profile then
                -- table.copymissing(profile, self.defaultConfig.global) -- if table layout changed
                if profile.enable then
                    return profile
                end
            end
        end
        if config.global and config.global.enable then
            return config.global
        end
    end
    return nil
end

return this
