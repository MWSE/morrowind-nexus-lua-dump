local seph = require("seph")
local interop = require("seph.npcSoulTrapping.interop")

local blackSoulGem = seph.Module:new()

blackSoulGem.item = nil
blackSoulGem.soulGemIdToReplace = "misc_soulgem_grand"

function blackSoulGem:onMorrowindInitialized(eventData)
	self.item = tes3.createObject{
		objectType = tes3.objectType.miscItem,
		id = "AB_Misc_SoulGemBlack",
		name = "Black Soul Gem",
		icon = "seph\\blackSoulGem.dds",
		mesh = "seph\\blackSoulGem.nif",
		value = self.mod.config.current.blackSoulGem.value,
		weight = 2.0,
		getIfExists = true
	}
	self.item.value = self.mod.config.current.blackSoulGem.value
	tes3.addSoulGem{item = self.item}
end

---@param soulGem tes3misc
function blackSoulGem.isBlackSoulGem(soulGem)
	local defineAzuraAsBlackSoulGem = blackSoulGem.mod.config.current.blackSoulGem.defineAzuraAsBlackSoulGem
	return soulGem.id:lower() == blackSoulGem.item.id:lower() or
		(defineAzuraAsBlackSoulGem and soulGem.id:lower() == "misc_soulgem_azura") or
		(interop.blackSoulGems[soulGem.id:lower()] == true)
end

---@param eventData leveledItemPickedEventData
function blackSoulGem.onLeveledItemPicked(eventData)
	local swapChance = blackSoulGem.mod.config.current.blackSoulGem.swapChance
	if (eventData.pick and eventData.pick.id:lower() == blackSoulGem.soulGemIdToReplace) and math.random(1, 100) <= swapChance then
		eventData.pick = blackSoulGem.item
		blackSoulGem.logger:debug("Replaced grand soul gem with black soul gem")
	end
end

function blackSoulGem:onEnabled()
	event.register(tes3.event.leveledItemPicked, self.onLeveledItemPicked)
end

function blackSoulGem:onDisabled()
	event.unregister(tes3.event.leveledItemPicked, self.onLeveledItemPicked)
end

return blackSoulGem