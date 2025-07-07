local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')

local trainCount
local currentLevel

local function onInit()
	trainCount = 0
	currentLevel = types.Actor.stats.level(self).current
end

local function onSave()
	return {
		tc = trainCount,
		cl = currentLevel
	}
end

local function onLoad(data)
	trainCount = data.tc
	currentLevel = data.cl
end

interfaces.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
	if source == interfaces.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
		if currentLevel ~= types.Actor.stats.level(self).current then
			onInit()
		end
		if trainCount == 5 then
			ui.showMessage('You\'ve had enough theory. Time to practice on your own.')
			return false
		end
		trainCount = trainCount + 1
	end
	print(string.format("trainCount: %d", trainCount))
end)

return {
	engineHandlers = {
		onInit = onInit,
		onSave = onSave,
		onLoad = onLoad,
	},
	eventHandlers = {
		UiModeChanged = function(data)
			--print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
			if currentLevel ~= types.Actor.stats.level(self).current then
				onInit()
			end
			if trainCount == 5 and data.newMode == 'Training' then
				interfaces.UI.removeMode('Training')
				interfaces.UI.removeMode('Dialogue')
				interfaces.UI.removeMode('Interface')
				ui.showMessage('You\'ve had enough theory. Time to practice on your own.')
			end
		end
	}
}