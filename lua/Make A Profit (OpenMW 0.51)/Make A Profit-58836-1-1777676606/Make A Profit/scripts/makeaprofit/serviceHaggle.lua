local self  = require('openmw.self')
local core  = require('openmw.core')
local ui    = require('openmw.ui')
local types = require('openmw.types')
local I     = require('openmw.interfaces')

local mapUtil = require('scripts.MakeAProfit.util')

local ServiceHaggle = {}

local trackedGold       = nil
local activeServiceMode = nil

-- UI modes
local SERVICE_MODES = {
	Travel         = true,
	Training       = true,
	MerchantRepair = true,
	SpellBuying    = true,
	SpellCreation  = true,
	Enchanting     = true, -- NPC only
}

local function getPlayerGold()
	local goldItem = types.Actor.inventory(self):find('gold_001')
	return goldItem and goldItem.count or 0
end

-- roll for service haggle
local function rollServiceHaggle(cost)
	local merc = self.type.stats.skills.mercantile(self).modified
	local pers = self.type.stats.attributes.personality(self).modified
	local luck = self.type.stats.attributes.luck(self).modified
	local fatigue = mapUtil.getFatigueTerm(self)
	
	local power = (merc + pers * 0.2 + luck * 0.1) * fatigue
	local successChance = math.max(5, math.min(95,
		math.floor(power / 10) * 5 + 10))
	
	local roll = math.random(1, 100)
	
	local outcome
	local refundPct = 0
	
	if roll <= 5 then
		outcome = 'crit_fail'
	elseif roll >= 96 then
		outcome = 'crit_success'
		refundPct = S_SERVICE_CRIT_DISCOUNT or 30
	elseif roll <= successChance then
		outcome = 'success'
		refundPct = S_SERVICE_DISCOUNT or 15
	else
		outcome = 'fail'
	end
	
	local refund = math.floor(cost * refundPct / 100)
	return outcome, refund
end

function ServiceHaggle.onModeEnter(newMode, oldMode)
	if not S_ENABLE_SERVICE_HAGGLE then return end
	if not SERVICE_MODES[newMode] then return end
	
	if newMode == 'Enchanting' and oldMode ~= 'Dialogue' then return end
	
	activeServiceMode = newMode
	trackedGold = getPlayerGold()
end

function ServiceHaggle.onModeLeave(oldMode)
	if oldMode == activeServiceMode then
		activeServiceMode = nil
		trackedGold = nil
	end
end

-- detects gold drops and rolls the haggle
function ServiceHaggle.onFrame()
	if not activeServiceMode or not trackedGold then return end
	if not S_ENABLE_SERVICE_HAGGLE then return end
	
	local currentGold = getPlayerGold()
	local spent = trackedGold - currentGold
	
	if spent > 0 then
		local outcome, refund = rollServiceHaggle(spent)
		
		if S_SHOW_MESSAGES then
			if outcome == 'crit_success' then
				ui.showMessage('Masterful haggle! '
					.. refund .. ' gold returned.')
			elseif outcome == 'success' then
				ui.showMessage('Successful haggle. '
					.. refund .. ' gold returned.')
			elseif outcome == 'crit_fail' then
				ui.showMessage(
					'Critical haggle failure! '
					.. 'The merchant laughs at your attempt.')
			else
				ui.showMessage('Haggle failed.')
			end
		end
		
		if refund > 0 then
			core.sendGlobalEvent('MAP_ServiceRefund', {
				player = self,
				amount = refund,
			})
			I.SkillProgression.skillUsed('mercantile', {
				useType = I.SkillProgression.SKILL_USE_TYPES.Mercantile_Success,
			})
		end
		
		trackedGold = currentGold
	elseif spent < 0 then
		trackedGold = currentGold
	end
end

return ServiceHaggle