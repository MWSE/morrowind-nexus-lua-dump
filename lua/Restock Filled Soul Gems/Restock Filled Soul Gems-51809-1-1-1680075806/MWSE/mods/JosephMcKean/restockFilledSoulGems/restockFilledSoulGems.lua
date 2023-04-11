---@diagnostic disable: assign-type-mismatch
local logger = require("JosephMcKean.restockFilledSoulGems.logging").createLogger("restockFilledSoulGems")
local config = require("JosephMcKean.restockFilledSoulGems.config")
local validFilledSoulGems = require("JosephMcKean.restockFilledSoulGems.validFilledSoulGems")

local soulGems = validFilledSoulGems.soulGems
local souls = validFilledSoulGems.souls

function tes3reference:restockNonfilledSoulGems()
	local count
	local maxUnfilledCount = config.maxUnfilledCount
	for _, soulGem in pairs(soulGems) do
		count = math.random(maxUnfilledCount)
		tes3.addItem({ reference = self, item = soulGem, count = count })
		maxUnfilledCount = math.clamp(maxUnfilledCount - count, 0, maxUnfilledCount)
	end
end

function tes3reference:removeOldGems()
	logger:debug("Removing all valid soul gems")
	for _, stack in pairs(self.object.inventory) do
		if stack.object.isSoulGem and table.find(validFilledSoulGems.soulGems, stack.object.id:lower()) then
			local soulGem = stack.object ---@cast soulGem tes3misc
			local removedCount = tes3.removeItem({ reference = self, item = soulGem.id, count = stack.count })
		end
	end
end

function tes3reference:stockSoulGems()
	self:removeOldGems()
	self:restockNonfilledSoulGems()
	local soulGem
	local soul
	local currentCount = 0
	while currentCount < config.maxFilledCount do
		soulGem = table.choice(soulGems)
		soul = table.choice(souls[soulGem])
		local addedCount = tes3.addItem({ reference = self, item = soulGem, soul = soul })
		logger:debug("Adding %s %s (%s)", addedCount, soulGem, soul)
		currentCount = currentCount + 1
	end
end

local function checkIfRestockFilledSoulGems(merchantRef)
	local timestamp = merchantRef.data.restockSoulGems and merchantRef.data.restockSoulGems.timestamp
	local newTimestamp = tes3.getSimulationTimestamp()
	if not timestamp then -- first time talking to this merchant 
		merchantRef.data.restockSoulGems = merchantRef.data.restockSoulGems or {}
		merchantRef.data.restockSoulGems.timestamp = newTimestamp
		merchantRef:stockSoulGems()
		return true
	end
	if newTimestamp - timestamp >= tes3.findGMST(tes3.gmst.fBarterGoldResetDelay).value then
		merchantRef.data.restockSoulGems.timestamp = newTimestamp
		merchantRef:stockSoulGems()
		return true
	end
	return false
end

--- @return boolean result
function tes3reference:isSoulGemsMerchants()
	local obj = self.baseObject or self.object
	local objId = obj.id:lower()
	return config.soulGemsMerchants[objId]
end

local function onMenuDialog(e)
	local serviceActorRef = tes3ui.getServiceActor().reference
	if serviceActorRef:isSoulGemsMerchants() then
		logger:debug("Talking to %s, who is a restock filled soul gems merchant.", serviceActorRef.object.name)
		checkIfRestockFilledSoulGems(serviceActorRef)
	end
end
event.register("uiActivated", onMenuDialog, { filter = "MenuDialog", priority = -1 })
