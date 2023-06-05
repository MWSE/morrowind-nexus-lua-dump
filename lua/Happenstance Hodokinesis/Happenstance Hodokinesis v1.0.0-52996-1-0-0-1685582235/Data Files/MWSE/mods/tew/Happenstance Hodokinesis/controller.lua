-- This is our main controller for determining what we want to do. --

local controller = {}

--
local constants = require("tew.Happenstance Hodokinesis.constants")
local conditions = require("tew.Happenstance Hodokinesis.conditions")
local helper = require("tew.Happenstance Hodokinesis.helper")
local data = require("tew.Happenstance Hodokinesis.data")
local dataHandler = require("tew.Happenstance Hodokinesis.dataHandler")
local random = require("tew.Happenstance Hodokinesis.random")
local messages = require("tew.Happenstance Hodokinesis.messages")
--

function controller.roll()
	-- This is a base chance for either a bonus or a malus to be applied, based on the player's Luck. --
	local boon = helper.calcBoon()

	local day = tes3.worldController.daysPassed.value

	-- This is a table to hold our applicable conditions. --
	local currentConditions = {}

	-- Let's run our condition checks and see if anything is worth doing. --
	-- TODO: maybe some fallback?
	for _, conditionCheck in pairs(conditions) do
		local isActive, action = conditionCheck(boon)
		if isActive then
			-- Write off our action and the param to act upon. --
			table.insert(currentConditions, action)
		end
	end

	-- Roll a dice to get a randomised applicable action to take. --
	local rolledAction = table.choice(currentConditions)
	if (not rolledAction) or (0.2 > math.random()) then
		rolledAction = table.choice(random.actions[boon])
	end

	-- If we got a hit, i.e. there are some applicable conditions, let's run the action. --
	if rolledAction then
		if dataHandler.getUsedPerDay(day) < helper.getUsageLimit() then
			local rollSound = tes3.getSound(constants.SOUND_ROLL)
			local castSound = tes3.getSound(constants.SOUND_CAST)
			rollSound:play()
			timer.start{
				type=timer.real,
				iterations = 1,
				duration = 2.3,
				persist = false,
				callback = function()
					helper.cast(
						"Happenstance Hodokinesis",
						{{ id = tes3.effect.dispel, duration = 1, min = 0, max = 0 }},
						tes3.player,
						data.vfx.mysticism
					)
					castSound:play()
					dataHandler.setUsedPerDay(day)
					if boon and tes3.mobilePlayer.luck.current < 100 then
						local increase = helper.calcActionChance()/10
						dataHandler.setLuckProgress(increase)
					end
					rolledAction()
				end
			}
		else
			helper.showMessage(messages.aleaInactive)
		end
	end
end


--
return controller