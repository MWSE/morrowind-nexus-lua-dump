---@diagnostic disable: inject-field
local defns = require("herbert100.animated containers.defns")

local default = require("herbert100.animated containers.config.default")

local version_str = toml.loadMetadata("Animated Containers Rewritten").package
    .version
local major, minor, patch = table.unpack(string.split(version_str, "%."))
default.version = tonumber(major) + tonumber(minor) / 10 + tonumber(patch) / 100

local config = mwse.loadConfig(defns.mod_name, default) --[[@as herbert.AC.config]]

if config.version < 0.6 then
    if config.auto_close == true then
        config.auto_close = defns.auto_close.if_nonempty
    elseif config.auto_close == false then
        config.auto_close = defns.auto_close.never
    end

    config.version = default.version
end
-- lol
mwse.Logger.new():setLevel(config.log_level)

return config
