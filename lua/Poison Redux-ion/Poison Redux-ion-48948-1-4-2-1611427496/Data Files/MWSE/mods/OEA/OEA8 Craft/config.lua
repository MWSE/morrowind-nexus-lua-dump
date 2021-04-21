local defaultConfig = {
	Messages =
		true,
	useLabels =
		false,
	SkillBuff =
		true,
	StatChange =
		true,
	World =
		true,
	Batchings =
		"1",
	Startup =
		true,
	Excise = 
		false,
	Combat = 
		true,
	Menu = 
		false,
	ResistLife =
		true,
	MultiHit = 
		1
	}

for class, _ in pairs(tes3.dataHandler.nonDynamicData.classes) do
 	local Var
	local Cent

	local Var = ("Resist_%s"):format(_)

	if (("%s"):format(_) == "Alchemist") then Cent = 30
	elseif (("%s"):format(_) == "Alchemist Service") then Cent = 30
	elseif (("%s"):format(_) == "Apothecary") then Cent = 30
	elseif (("%s"):format(_) == "Apothecary Service") then Cent = 30
	elseif (("%s"):format(_) == "Assassin") then Cent = 20
	elseif (("%s"):format(_) == "Assassin Service") then Cent = 20
	elseif (("%s"):format(_) == "Bard") then Cent = 20
	elseif (("%s"):format(_) == "Scout") then Cent = 20
	elseif (("%s"):format(_) == "Nightblade") then Cent = 10
	elseif (("%s"):format(_) == "Nightblade Service") then Cent = 10
	elseif (("%s"):format(_) == "Rogue") then Cent = 10
	elseif (("%s"):format(_) == "Witch") then Cent = 10
	else Cent = 0
	end

	defaultConfig[Var] = Cent
end

local config = mwse.loadConfig("Poison_Redux-ion", defaultConfig)
return config