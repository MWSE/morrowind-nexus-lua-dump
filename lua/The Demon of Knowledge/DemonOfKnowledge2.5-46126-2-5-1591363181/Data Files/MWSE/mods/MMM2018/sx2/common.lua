local this = {}

this.inscriptionSkillId = "Hermes:Inscription"

this.itemIds = {
	Occulomicon = "sx2_ibook01",
	Oracle = "sx2_light_book_black",
	PortalLocator = "",
	Portal = "sx2_portal_vaer",
	quill = "sx2_quillSword",
	papernado = "sx2_papernado_01",
	summonedPapernado = "sx2_papernado_02"
}



this.spellIds = {
	Deathword = "sx2_lore_summon",
	Blink01 = "sx2_blink_spell",
	Blink02 = "sx2_blink_02"
}

this.journalIds = {
	portal = "",
	quest01 = "sx2_mq1",
	quest02 = "sx2_mq2",
	quest03 = "sx2_mq3",
	quest04 = "sx2_mq4",
	quest05 = "sx2_mq5",
	quest06 = "sx2_mq6"
		
}

this.globalIds = {
	inscriptionSkill = "sx2_inscription_active"
}

this.indicatorIds = {
	doorGlow = "sx2_doorglow",
	locationGlow = "sx2_locationglow"
}


local function loaded(e)
	--Persistent data stored on player reference 
	-- ensure data table exists
	local data = tes3.getPlayerRef().data
	data.herme_data = data.herme_data or {}
	
	--local shortcut
	this.data = data.herme_data
	print("[Demon of Knowledge: INFO] player data loaded")
	event.trigger("Herme:dataReady")
end
	
	
event.register("loaded", loaded )

return this