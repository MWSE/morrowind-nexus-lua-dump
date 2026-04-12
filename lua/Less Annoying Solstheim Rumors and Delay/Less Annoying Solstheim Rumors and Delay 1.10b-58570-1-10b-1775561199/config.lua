local defaultConfig = {
    requiredPlayerLevel = 10, -- минимальный уровень игрока для появления сплетен
	hasSonOnSolstheimChance = 20, -- вероятность того, что случайный имперец расскажет о сыне-легионере
    canDiscussNewMineChance = 50, -- вероятность того, что данмер-обыватель/трактирщик будет обсуждать новую шахту
    agentRumorChance = 70,   -- вероятность того, что агент расскажет о проблемах в Форте
    checkIsInMournhold = true -- проверять, находится ли игрок в Морнхолде
}

local configPath = "Less Annoying Solstheim Rumors & Delay"
local config = mwse.loadConfig(configPath, defaultConfig)

return config