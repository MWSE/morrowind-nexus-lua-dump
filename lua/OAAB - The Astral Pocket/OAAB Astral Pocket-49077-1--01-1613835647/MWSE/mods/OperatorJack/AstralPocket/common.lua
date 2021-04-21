local this = {}

this.spellIds = {
	TeleportToAstralPocket = "OJ_AP_TeleportToAstralPocket"
}

this.spellDescriptions = {
	TeleportToAstralPocket = "Teleports the Caster to the Astral Pocket, at a cost."
}

this.bookIds = {
	AstrologicalElements = "OJ_AP_AstrologicalElementsBook",
	NelasNote = "OJ_AP_NelasNote"
}

this.journalIds = {
	QuestOne = "OJ_AP_AstrologicalElementsJournal"
}

this.cell = { id = "Astral Pocket", position = { 2025, -110, 14439}, orientation = { x = 0, y = 0, z = 138}}

this.doorId = "OJ_AS_ReturnDoor"

local function loaded(e)
	--Persistent data stored on player reference 
	-- ensure data table exists
	local data = tes3.getPlayerRef().data
	data.OJ_AP_data = data.OJ_AP_data or {}

	--local shortcut
	this.data = data.OJ_AP_data
	print("[Astral Pocket: INFO] Player data loaded.")
end
event.register("loaded", loaded )

return this