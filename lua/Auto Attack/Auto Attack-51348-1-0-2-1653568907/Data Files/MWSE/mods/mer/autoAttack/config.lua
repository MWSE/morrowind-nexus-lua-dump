local inMemConfig

local this = {}

--Static Config (stored right here)
this.static = {
    modName = "Auto Attack",
    modDescription =
    [[A mod that allows you to attack automatically with a hotkey.]],
    useKeyOptionIndex = 5,
    deviceMouse = 1,
    deviceKeyboard = 0,
    buttonDown = 128,
}

--MCM Config (stored as JSON)
this.configPath = "autoAttack"
this.mcmDefault = {
    enabled = true,
    logLevel = "INFO",
    hotKey = {
        keyCode = tes3.scanCode.q,
        isAltDown = true
    },
    maxSwing = 100,
    displayMessages = true
}
this.save = function(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(this.configPath, inMemConfig)
end

this.mcm = setmetatable({}, {
    __index = function(_, key)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.mcmDefault)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.mcmDefault)
        inMemConfig[key] = value
        mwse.saveConfig(this.configPath, inMemConfig)
    end
})


-- local persistentDefault =
-- }

-- this.persistent = setmetatable({}, {
--     __index = function(_, key)
--         if not tes3.player then return end
--         tes3.player.data[this.configPath] = tes3.player.data[this.configPath] or persistentDefault
--         return tes3.player.data[this.configPath][key]
--     end,
--     __newindex = function(_, key, value)
--         if not tes3.player then return end
--         tes3.player.data[this.configPath] = tes3.player.data[this.configPath] or persistentDefault
--         tes3.player.data[this.configPath][key] = value
--     end
-- })

return this