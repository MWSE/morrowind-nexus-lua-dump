local statistic = {}

local messages = require("tew.Happenstance Hodokinesis.messages")
local config = require("tew.Happenstance Hodokinesis.config")

function statistic.increaseLuck()
	tes3.modStatistic{
		reference = tes3.player,
		attribute = tes3.attribute.luck,
		value = 1,
		limit = true,
	}
	if config.showInfoMessages then
		tes3.messageBox{
			message = messages.luckIncreased
		}
	end
end

return statistic