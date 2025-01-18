local defaultConfig = {

	preserveTooltip = true,
    editSummonUndeadEffects = true,
	replaceSummonUndeadSpells = true,
	bountyValue = 1500,
	
	crafting = {
		experienceGain = 50
	},
	
	necromancers = {
		["sharn gra-muzgob"] = true,
		["dedaenc"] = true,
		["daris adram"] = true,
		["treras dres"] = true,
		["tirer belvayn"] = true,
		["milyn faram"] = true,
		["kofutto gilgar"] = true,
		["sorkvild the raven"] = true,
		["goris the maggot king"] = true,
		["delvam andarys"] = true,
		["telura ulver"] = true
	},
	
	summonTeachers = {
		["heem-la"] = true,
		["malven romori"] = true,
		["ferise varo"] = true,
		["uleni heleran"] = true,
		["playersavegame"] = true
	}
}

for npc in tes3.iterateObjects(tes3.objectType.npc) do
	if npc.class.id == "Necromancer" then
		defaultConfig.necromancers[npc.id:lower()] = true
	end
end

local mwseConfig = mwse.loadConfig("NecroCraft", defaultConfig)

return mwseConfig;
