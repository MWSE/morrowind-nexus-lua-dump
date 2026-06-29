-- ------------------------------ Evening Star : quest watcher --------------
-- sun's dusk has no onQuestUpdate job list,
-- so this standalone player script relays each update to es_favor_sources as a custom event.

local self = require('openmw.self')

return {
	engineHandlers = {
		onQuestUpdate = function(questId, stage)
			self:sendEvent("EveningStar_questUpdate", { quest = questId, stage = stage })
		end,
	},
}
