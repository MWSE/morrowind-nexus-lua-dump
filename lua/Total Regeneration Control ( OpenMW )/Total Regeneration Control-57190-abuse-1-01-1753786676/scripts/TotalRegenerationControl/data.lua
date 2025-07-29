local types = require('openmw.types')

local settings_import = require("scripts.TotalRegenerationControl.settings")
local settings_import_player = require("scripts.TotalRegenerationControl.settings_player")

local M = {}

M.settingsMap = {
	common = {
		MAGICKA = settings_import.magickaSettings,
		HEALTH = settings_import.healthSettings,
		FATIGUE = settings_import.fatigueSettings,
		MAGICKA_TRESHOLD = settings_import.magickaTresholdSettings,
		HEALTH_TRESHOLD = settings_import.healthTresholdSettings,
		FATIGUE_TRESHOLD = settings_import.fatigueTresholdSettings,
		IS_ENABLED = settings_import.isEnabledSettings,
	},
	player = {
		MAGICKA = settings_import_player.magickaSettings,
		HEALTH = settings_import_player.healthSettings,
		FATIGUE = settings_import_player.fatigueSettings,
		MAGICKA_TRESHOLD = settings_import_player.magickaTresholdSettings,
		HEALTH_TRESHOLD = settings_import_player.healthTresholdSettings,
		FATIGUE_TRESHOLD = settings_import_player.fatigueTresholdSettings,
		IS_ENABLED = settings_import_player.isEnabledSettings,
	}
}
------------------------------------------------------------
-- Какой % от атрибута восстанавливает показатель/устанавливает порог расхода показателя
function M.getPercent(settingsCategory, resource)
    local settings = M.settingsMap[settingsCategory][resource]
    return {
		WILLPOWER = settings:get('willpower') or 0,
		INTELLIGENCE = settings:get('intelligence') or 0,
		ENDURANCE = settings:get('endurance') or 0,
		STRENGTH = settings:get('strength') or 0,
        AGILITY = settings:get('agility') or 0,
		SPEED = settings:get('speed') or 0,
		PERSONALITY = settings:get('personality') or 0,
		LUCK = settings:get('luck') or 0,
	}
end

-- Получить значение атрибута персонажа
function M.getAttribute(actor)
	return {
	WILLPOWER = types.Actor.stats.attributes['willpower'](actor).base + types.Actor.stats.attributes['willpower'](actor).modifier,
	INTELLIGENCE = types.Actor.stats.attributes['intelligence'](actor).base + types.Actor.stats.attributes['intelligence'](actor).modifier,
	ENDURANCE = types.Actor.stats.attributes['endurance'](actor).base + types.Actor.stats.attributes['endurance'](actor).modifier,
	STRENGTH = types.Actor.stats.attributes['strength'](actor).base + types.Actor.stats.attributes['strength'](actor).modifier,
    AGILITY = types.Actor.stats.attributes['agility'](actor).base + types.Actor.stats.attributes['agility'](actor).modifier,
	SPEED = types.Actor.stats.attributes['speed'](actor).base + types.Actor.stats.attributes['speed'](actor).modifier,
	PERSONALITY = types.Actor.stats.attributes['personality'](actor).base + types.Actor.stats.attributes['personality'](actor).modifier,
	LUCK = types.Actor.stats.attributes['luck'](actor).base + types.Actor.stats.attributes['luck'](actor).modifier,
	}
end

-- Получить значение показателей персонажа
function M.getDynamic(actor)
	return {
	MAGICKA_CURRENT = types.Actor.stats.dynamic.magicka(actor).current,
	MAGICKA_MAX = types.Actor.stats.dynamic.magicka(actor).base + types.Actor.stats.dynamic.magicka(actor).modifier,
	HEALTH_CURRENT = types.Actor.stats.dynamic.health(actor).current,
	HEALTH_MAX = types.Actor.stats.dynamic.health(actor).base + types.Actor.stats.dynamic.health(actor).modifier,
	FATIGUE_CURRENT = types.Actor.stats.dynamic.fatigue(actor).current,
	FATIGUE_MAX = types.Actor.stats.dynamic.fatigue(actor).base + types.Actor.stats.dynamic.health(actor).modifier,
	}
end

-- для цикла for
M.ATTRIBUTES = {
    "WILLPOWER", "INTELLIGENCE", "ENDURANCE",
    "STRENGTH", "AGILITY", "SPEED",
    "PERSONALITY", "LUCK"
}

return M