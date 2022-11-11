local circletsWares = nil

local function addToLeveledList(listName)
	tes3.getObject(listName):insert(circletsWares, 1)
end

event.register("initialized", function()
	if not tes3.isModActive("Wares-base.esm") then 
		mwse.log('[kd_ciclets] skipping wares integration.')
		return 
	end

	mwse.log('[kd_ciclets] Found Wares! Adding circlets to leveled lists.')
	circletsWares = tes3.getObject('_KDcirclets_wares')

	addToLeveledList('aa_trader_accessories')
	addToLeveledList('aa_loot_CORPSE_mage')
	addToLeveledList('aa_loot_CLOTHIER')
	addToLeveledList('aa_loot_BATTLMAG')
	addToLeveledList('aa_loot_MAGE')
	addToLeveledList('aa_loot_SORC')
	addToLeveledList('aa_loot_MONK')
	addToLeveledList('aa_loot_NOBLE')

end)