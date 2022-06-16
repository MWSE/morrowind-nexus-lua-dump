local inMemConfig

local this = {}

--Static Config (stored right here)
this.static = {
    modName = "Realistic Archery",
    modDescription = [[
Projectiles always do damage when they hit the target, but the accuracy of their trajectory is now based on the shooter's marksman skill.
Like the vanilla hit chance calculation, the attacker's fatigue, agility and luck also affect projectile accuracy. In addition, projectiles are more accurate when the attacker is sneaking.
This affects the player as well as NPCs and creatures. For creatures which don't have a Marksman skill, their level is used instead.

At short distances, the damage of projectiles is reduced. The distance needed to achieve max damage is smaller the higher the marksman skill of the attacker.
]],
}

--MCM Config (stored as JSON)
this.configPath = "realisticArchery"
this.mcmDefault = {
    enabled = true,
    logLevel = "INFO",
    maxNoise = 10,
    minDistanceFullDamage = 1000,
    sneakReduction = 30,
    maxCloseRangeDamageReduction = 90,
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

return this