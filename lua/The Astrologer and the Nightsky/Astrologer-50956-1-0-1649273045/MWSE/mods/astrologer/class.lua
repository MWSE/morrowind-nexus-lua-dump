local seph = require("seph")
local power = require("astrologer.power")

local class = seph.Module:new()

class.classId = "aa_astrologer"

function class:addPower()
	tes3.addSpell{
		reference = tes3.player,
		spell = power.powerId
	}
	tes3.updateMagicGUI{reference = tes3.mobilePlayer}
	class.logger:debug("Power added")
end

function class:addPowerIfMissing()
	if not tes3.hasSpell{reference = tes3.player, spell = power.powerId} then
		self:addPower()
	end
end

function class.onLoaded(eventData)
	if eventData.newGame then
		local updateTimer = nil
		updateTimer = timer.start{
			type = timer.simulate,
			duration = 1.0,
			iterations = -1,
			callback =
				function()
					class.logger:trace("Update timer expired")
					if tes3.worldController.charGenState.value == -1 then
						if tes3.player.object.class.id == class.classId then
							class:addPower()
						end
						updateTimer:cancel()
					end
				end
		}
	elseif tes3.player.object.class.id == class.classId then
		class:addPowerIfMissing()
	end
end

function class:onEnabled()
	event.register(tes3.event.loaded, self.onLoaded)
end

function class:onDisabled()
	event.unregister(tes3.event.loaded, self.onLoaded)
end

return class