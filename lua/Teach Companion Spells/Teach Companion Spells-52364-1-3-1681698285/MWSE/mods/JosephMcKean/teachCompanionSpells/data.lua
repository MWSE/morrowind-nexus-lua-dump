local data = {}

data.GUI_ID = {
	MenuDialog = tes3ui.registerID("MenuDialog"),
	MenuDialog_Teach_Spells = tes3ui.registerID("MenuDialog_service_teach_spells"),
	MenuDialog_TopicList = tes3ui.registerID("MenuDialog_topics_pane"),
	MenuDialog_Divider = tes3ui.registerID("MenuDialog_divider"),
	MenuTeachSpells = tes3ui.registerID("MenuTeachSpells"),
	MenuTeachSpells_block_main = tes3ui.registerID("MenuTeachSpells_block_main"),
	MenuTeachSpells_block_my = tes3ui.registerID("MenuTeachSpells_block_my"),
	MenuTeachSpells_block_your = tes3ui.registerID("MenuTeachSpells_block_your"),
	MenuTeachSpells_List_my = tes3ui.registerID("MenuTeachSpells_List_my"),
	MenuTeachSpells_List_your = tes3ui.registerID("MenuTeachSpells_List_your"),
	MenuTeachSpells_Icons_my = tes3ui.registerID("MenuTeachSpells_Icons_my"),
	MenuTeachSpells_Icons_your = tes3ui.registerID("MenuTeachSpells_Icons_your"),
	MenuTeachSpells_Spells_my = tes3ui.registerID("MenuTeachSpells_Spells_my"),
	MenuTeachSpells_Spells_your = tes3ui.registerID("MenuTeachSpells_Spells_your"),
	MenuTeachSpells_spell = tes3ui.registerID("MenuTeachSpells_Spells_spell"),
	MenuTeachSpells_ok = tes3ui.registerID("MenuTeachSpells_ok"),
	MenuTeachSpells_helptext = tes3ui.registerID("MenuTeachSpells_helptext"),
	MenuTeachSpells_help_block = tes3ui.registerID("MenuTeachSpells_help_block"),
}

data.GUI_text = {
	MenuTeachSpells_label_my = "Your spells",
	MenuTeachSpells_ok = "OK",
	MenuDialog_Teach_Spells = "Teach Spells",
	helpLabelText = "Teach spells to each other",
	helpLabelTextDisabled = "You don't have any spell to teach",
}

return data
