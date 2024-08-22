--[[ Enemy abilities ]]--



local function summonDeathwords(e)
	tes3.runLegacyScript({ command = "PlaceAtMe sx2_ghost_01 3 100 0", reference = e.caster})
end


event.register( "spellCasted", summonDeathwords { filter = tes3.getObject("sx2_lore_summon") )