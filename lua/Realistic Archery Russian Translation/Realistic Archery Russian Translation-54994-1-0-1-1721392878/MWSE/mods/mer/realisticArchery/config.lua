local inMemConfig

local this = {}

--Static Config (stored right here)
this.static = {
    modName = "Реалистичная стрельба",
    modDescription = [[
Снаряды всегда наносят урон при попадании в цель, но точность их траектории теперь зависит от навыка меткости стрелка.
Как и в ванильном расчете шанса попадания, усталость, ловкость и удача атакующего также влияют на точность снарядов. Кроме того, снаряды более точны, если нападающий крадется.
Это касается как игрока, так и NPC и существ. Для существ, у которых нет навыка Меткость, вместо него используется их уровень.

На коротких дистанциях урон от снарядов снижается. Расстояние, необходимое для достижения максимального урона, тем меньше, чем выше навык меткости атакующего.
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