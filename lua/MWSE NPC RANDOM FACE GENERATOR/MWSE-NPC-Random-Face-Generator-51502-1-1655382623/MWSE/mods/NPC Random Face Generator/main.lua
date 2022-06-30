
local nameTable = {
	"random",
	"rng",
	"Bandit",
	"Griefer",
	"Bounty Hunter",
	"Guard",
	"Guard Captain",
	"Imperial Archer",
	"Legion Archer",
	"Legion Battlemage",
	"Legion Captain",
	"Legion Soldier",
	"Ordinator",
	"Ordinator Guard",
	"Ordinator in Mourning",
	"War Ordinator",
	"High Ordinator",
	"Hlaalu Guard",
	"Hlaalu Sharpshooter Guard",
	"Indoril Guard",
	"Redoran Guard",
	"Redoran Watchman",
	"Royal Guard",
	"Duke's Guard",
	"Telvanni Guard",
	"Telvanni Sharpshooter",
	"Telvanni War Wizard",
	"Buoyant Armiger",
	"Smuggler",
	"Egg Miner",
	"Miner",
	"Female Imperial Innocent",
	"Female Nord Innocent",
	"Rogue Necromancer",
	"Necromancer's Apprentice",
	"Skaal Honor Guard",
	"Skaal Hunter",
	"Skaal Tracker",
	"Thirsk Worker",
	"Reaver",
	"Berserker",
	"Fryse Hag",
	"Worshipper",
	"Roamer",
	"Roamer Chief",
	"Wandering Idiot",
	"Wandering Lunatic",
	"Insane Wanderer",
	"Gibbering Lunatic",
	"Confused Lunatic",
	"Dreamer",
	"Dreamer Guard",
	"Dreamer Prophet",
	"Dreamer Worker",
	"Cattle",
	"Assassin",
	"Dark Brotherhood Journeyman",
	"Dark Brotherhood Apprentice",
	"Dark Brotherhood Operator",
	"Dark Brotherhood Punisher",
	"Dark Brotherhood Assassin",
	"Dead Body",
	"Dead Hero",
	"Dead Adventurer",
	"Dead Dreamer",
	"Dead Egg Miner",
	"Dead Miner",
	"Dead Elite Ordinator",
	"Dead Ordinator",
	"Dead Smuggler",
	"Dead Warlock",
	"RNG"
	}


local AFheadTable = {
	"b_n_argonian_f_head_01",
	"b_n_argonian_f_head_02",
	"b_n_argonian_f_head_03"
}

local AMheadTable = {
	"b_n_argonian_m_head_01",
	"b_n_argonian_m_head_02",
	"b_n_argonian_m_head_03"
}

local BFheadTable = {
	"b_n_breton_f_head_01",
	"b_n_breton_f_head_02",
	"b_n_breton_f_head_03",
	"b_n_breton_f_head_04",
	"b_n_breton_f_head_05",
	"B_N_Breton_F_Head_06"
}

local BMheadTable = {
	"b_n_breton_m_head_01",
	"b_n_breton_m_head_02",
	"b_n_breton_m_head_03",
	"b_n_breton_m_head_04",
	"b_n_breton_m_head_05",
	"b_n_breton_m_head_06",
	"B_N_Breton_M_Head_07",
	"B_N_Breton_M_Head_08"
}

local DFheadTable = {
	"b_n_dark elf_f_head_01",
	"b_n_dark elf_f_head_02",
	"b_n_dark elf_f_head_03",
	"b_n_dark elf_f_head_04",
	"b_n_dark elf_f_head_05",
	"b_n_dark elf_f_head_06",
	"b_n_dark elf_f_head_07",
	"b_n_dark elf_f_head_08",
	"b_n_dark elf_f_head_09",
	"b_n_dark elf_f_head_10"
}

local DMheadTable = {
	"b_n_dark elf_m_head_01",
	"b_n_dark elf_m_head_02",
	"b_n_dark elf_m_head_03",
	"b_n_dark elf_m_head_04",
	"b_n_dark elf_m_head_05",
	"b_n_dark elf_m_head_06",
	"b_n_dark elf_m_head_07",
	"b_n_dark elf_m_head_08",
	"b_n_dark elf_m_head_09",
	"b_n_dark elf_m_head_10",
	"b_n_dark elf_m_head_11",
	"b_n_dark elf_m_head_12",
	"b_n_dark elf_m_head_13",
	"b_n_dark elf_m_head_14",
	"b_n_dark elf_m_head_15"
}

local HFheadTable = {
	"b_n_high elf_f_head_01",
	"b_n_high elf_f_head_02",
	"b_n_high elf_f_head_03",
	"b_n_high elf_f_head_04",
	"b_n_high elf_f_head_05",
	"B_N_High Elf_F_Head_06"
}

local HMheadTable = {
	"b_n_high elf_m_head_01",
	"b_n_high elf_m_head_02",
	"b_n_high elf_m_head_03",
	"b_n_high elf_m_head_04",
	"b_n_high elf_m_head_05",
	"B_N_High Elf_M_Head_06"
}

local IFheadTable = {
	"b_n_imperial_f_head_01",
	"b_n_imperial_f_head_02",
	"b_n_imperial_f_head_03",
	"b_n_imperial_f_head_04",
	"b_n_imperial_f_head_05",
	"B_N_Imperial_F_Head_06",
	"B_N_Imperial_F_Head_07"
}

local IMheadTable = {
	"b_n_imperial_m_head_01",
	"b_n_imperial_m_head_02",
	"b_n_imperial_m_head_03",
	"b_n_imperial_m_head_04",
	"b_n_imperial_m_head_05",
	"B_N_Imperial_M_Head_06",
	"B_N_Imperial_M_Head_07"
}

local KFheadTable = {
	"b_n_khajiit_f_head_01",
	"b_n_khajiit_f_head_02",
	"b_n_khajiit_f_head_03",
	"B_N_Khajiit_F_Head_04"
}

local KMheadTable = {
	"b_n_khajiit_m_head_01",
	"b_n_khajiit_m_head_02",
	"b_n_khajiit_m_head_03",
	"B_N_Khajiit_M_Head_04"
}

local NFheadTable = {
	"b_n_nord_f_head_01",
	"b_n_nord_f_head_02",
	"b_n_nord_f_head_03",
	"b_n_nord_f_head_04",
	"b_n_nord_f_head_05",
	"B_N_Nord_F_Head_06",
	"B_N_Nord_F_Head_07",
	"B_N_Nord_F_Head_08"
}

local NMheadTable = {
	"b_n_nord_m_head_01",
	"b_n_nord_m_head_02",
	"b_n_nord_m_head_03",
	"b_n_nord_m_head_04",
	"b_n_nord_m_head_05",
	"B_N_Nord_M_Head_06",
	"B_N_Nord_M_Head_07",
	"B_N_Nord_M_Head_08",
	"B_N_Nord_M_Head_09",
	"B_N_Nord_M_Head_10",
	"B_N_Nord_M_Head_11",
	"B_N_Nord_M_Head_12",
	"B_N_Nord_M_Head_13",
}

local OFheadTable = {
	"b_n_orc_f_head_01",
	"b_n_orc_f_head_02",
	"b_n_orc_f_head_03"
}

local OMheadTable = {
	"b_n_orc_m_head_01",
	"b_n_orc_m_head_02",
	"b_n_orc_m_head_03",
	"B_N_Orc_M_Head_04"
}

local RFheadTable = {
	"b_n_redguard_f_head_01",
	"b_n_redguard_f_head_02",
	"b_n_redguard_f_head_03",
	"b_n_redguard_f_head_04",
	"b_n_redguard_f_head_05",
	"B_N_Redguard_F_Head_06"
}

local RMheadTable = {
	"b_n_redguard_m_head_01",
	"b_n_redguard_m_head_02",
	"b_n_redguard_m_head_03",
	"b_n_redguard_m_head_04",
	"b_n_redguard_m_head_05",
	"B_N_Redguard_M_Head_06"
}

local WFheadTable = {
	"b_n_wood elf_f_head_01",
	"b_n_wood elf_f_head_02",
	"b_n_wood elf_f_head_03",
	"b_n_wood elf_f_head_04",
	"b_n_wood elf_f_head_05",
	"B_N_Wood Elf_F_Head_06"
}

local WMheadTable = {
	"b_n_wood elf_m_head_01",
	"b_n_wood elf_m_head_02",
	"b_n_wood elf_m_head_03",
	"b_n_wood elf_m_head_04",
	"b_n_wood elf_m_head_05",
	"B_N_Wood Elf_M_Head_06",
	"B_N_Wood Elf_M_Head_07",
	"B_N_Wood Elf_M_Head_08"
}

local AFhairTable = {
	"b_n_argonian_f_hair01",
	"b_n_argonian_f_hair02",
	"b_n_argonian_f_hair03",
	"b_n_argonian_f_hair04",
	"b_n_argonian_f_hair05"
}

local AMhairTable = {
	"b_n_argonian_f_hair01",
	"b_n_argonian_f_hair02",
	"b_n_argonian_f_hair03",
	"b_n_argonian_f_hair04",
	"b_n_argonian_f_hair05",
	"b_n_argonian_f_hair06"
}

local BFhairTable = {
	"b_n_breton_f_hair_01",
	"b_n_breton_f_hair_03",
	"b_n_breton_f_hair_04",
	"b_n_breton_f_hair_05"
}

local BMhairTable = {
	"b_n_breton_m_hair_01",
	"b_n_breton_m_hair_03",
	"b_n_breton_m_hair_04",
	"b_n_breton_m_hair_05"
}

local DFhairTable = {
	"b_n_dark elf_f_hair_01",
	"b_n_dark elf_f_hair_02",
	"b_n_dark elf_f_hair_03",
	"b_n_dark elf_f_hair_04",
	"b_n_dark elf_f_hair_05",
	"b_n_dark elf_f_hair_06",
	"b_n_dark elf_f_hair_07",
	"b_n_dark elf_f_hair_08",
	"b_n_dark elf_f_hair_09",
	"b_n_dark elf_f_hair_10",
	"b_n_dark elf_f_hair_11",
	"b_n_dark elf_f_hair_12",
	"b_n_dark elf_f_hair_13",
	"b_n_dark elf_f_hair_14",
	"b_n_dark elf_f_hair_15",
	"b_n_dark elf_f_hair_16",
	"b_n_dark elf_f_hair_17",
	"b_n_dark elf_f_hair_18",
	"b_n_dark elf_f_hair_19",
	"b_n_dark elf_f_hair_20",
	"b_n_dark elf_f_hair_21",
	"b_n_dark elf_f_hair_22",
	"b_n_dark elf_f_hair_23",
	"b_n_dark elf_f_hair_24"
}

local DMhairTable = {
	"b_n_dark elf_m_hair_01",
	"b_n_dark elf_m_hair_02",
	"b_n_dark elf_m_hair_03",
	"b_n_dark elf_m_hair_04",
	"b_n_dark elf_m_hair_05",
	"b_n_dark elf_m_hair_06",
	"b_n_dark elf_m_hair_07",
	"b_n_dark elf_m_hair_08",
	"b_n_dark elf_m_hair_09",
	"b_n_dark elf_m_hair_10",
	"b_n_dark elf_m_hair_11",
	"b_n_dark elf_m_hair_12",
	"b_n_dark elf_m_hair_13",
	"b_n_dark elf_m_hair_14",
	"b_n_dark elf_m_hair_15",
	"b_n_dark elf_m_hair_16",
	"b_n_dark elf_m_hair_17",
	"b_n_dark elf_m_hair_18",
	"b_n_dark elf_m_hair_19",
	"b_n_dark elf_m_hair_20",
	"b_n_dark elf_m_hair_21",
	"b_n_dark elf_m_hair_22",
	"b_n_dark elf_m_hair_23",
	"b_n_dark elf_m_hair_24",
	"b_n_dark elf_m_hair_25",
	"b_n_dark elf_m_hair_26"
}

local HFhairTable = {
	"b_n_high elf_f_hair_01",
	"b_n_high elf_f_hair_02",
	"b_n_high elf_f_hair_03",
	"b_n_high elf_f_hair_04"
}

local HMhairTable = {
	"b_n_high elf_m_hair_01",
	"b_n_high elf_m_hair_02",
	"b_n_high elf_m_hair_03",
	"b_n_high elf_m_hair_04",
	"b_n_high elf_m_hair_05"
}

local IFhairTable = {
	"b_n_imperial_f_hair_01",
	"b_n_imperial_f_hair_02",
	"b_n_imperial_f_hair_03",
	"b_n_imperial_f_hair_04",
	"b_n_imperial_f_hair_05",
	"B_N_Imperial_F_Hair_06",
	"B_N_Imperial_F_Hair_07"
}

local IMhairTable = {
	"b_n_imperial_m_hair_00",
	"b_n_imperial_m_hair_01",
	"b_n_imperial_m_hair_02",
	"b_n_imperial_m_hair_03",
	"b_n_imperial_m_hair_04",
	"b_n_imperial_m_hair_05",
	"B_N_Imperial_M_Hair_06",
	"B_N_Imperial_M_Hair_07",
	"B_N_Imperial_M_Hair_08",
	"B_N_Imperial_M_Hair_09"
}

local KFhairTable = {
	"b_n_khajiit_f_hair01",
	"b_n_khajiit_f_hair02",
	"b_n_khajiit_f_hair03",
	"b_n_khajiit_f_hair04",
	"b_n_khajiit_f_hair05"
}

local KMhairTable = {
	"b_n_khajiit_m_hair01",
	"b_n_khajiit_m_hair02",
	"b_n_khajiit_m_hair03",
	"b_n_khajiit_m_hair04",
	"b_n_khajiit_m_hair05"
}

local NFhairTable = {
	"b_n_nord_f_hair_01",
	"b_n_nord_f_hair_02",
	"b_n_nord_f_hair_03",
	"b_n_nord_f_hair_04",
	"b_n_nord_f_hair_05",
	"B_N_Nord_F_hair_06"
}

local NMhairTable = {
	"b_n_nord_m_hair00",
	"b_n_nord_m_hair01",
	"b_n_nord_m_hair02",
	"b_n_nord_m_hair03",
	"b_n_nord_m_hair04",
	"b_n_nord_m_hair05",
	"B_N_Nord_M_Hair06",
	"B_N_Nord_M_Hair07",
	"B_N_Nord_M_hair08"
}

local OFhairTable = {
	"b_n_orc_f_hair01",
	"b_n_orc_f_hair02",
	"b_n_orc_f_hair03",
	"b_n_orc_f_hair04",
	"b_n_orc_f_hair05"
}

local OMhairTable = {
	"b_n_orc_m_hair_01",
	"b_n_orc_m_hair_02",
	"b_n_orc_m_hair_03",
	"b_n_orc_m_hair_04",
	"b_n_orc_m_hair_05"
}

local RFhairTable = {
	"b_n_redguard_f_hair_01",
	"b_n_redguard_f_hair_02",
	"b_n_redguard_f_hair_03",
	"b_n_redguard_f_hair_04",
	"b_n_redguard_f_hair_05"
}

local RMhairTable = {
	"b_n_redguard_m_hair_00",
	"b_n_redguard_m_hair_01",
	"b_n_redguard_m_hair_02",
	"b_n_redguard_m_hair_03",
	"b_n_redguard_m_hair_04",
	"b_n_redguard_m_hair_05",
	"B_N_Redguard_M_Hair_06"
}

local WFhairTable = {
	"b_n_wood elf_f_hair_01",
	"b_n_wood elf_f_hair_02",
	"b_n_wood elf_f_hair_03",
	"b_n_wood elf_f_hair_04",
	"b_n_wood elf_f_hair_05"
}

local WMhairTable = {
	"b_n_wood elf_m_hair_01",
	"b_n_wood elf_m_hair_02",
	"b_n_wood elf_m_hair_03",
	"b_n_wood elf_m_hair_04",
	"b_n_wood elf_m_hair_05",
	"b_n_wood elf_m_hair_06"
}

local raceTable = {
	["argonian"] = true,
	["breton"] = true,
	["dark elf"] = true,
	["high elf"] = true,
	["imperial"] = true,
	["khajiit"] = true,
	["nord"] = true,
	["orc"] = true,
	["redguard"] = true,
	["wood elf"] = true
}

local parts = {
	head = 0,
	hair = 1
}

local checkName
local function nameCheck()
	for _, value in pairs(nameTable) do
		if value == checkName then
			return true
		end
	end
	return false
end

local function onBodyPartAssigned(e)
	if (e.reference == tes3.player) or (e.mobile == tes3.mobilePlayer) then
		return
	end
	if (raceTable[e.reference.baseObject.race.id:lower()] == nil) then
		return
	end
	if (e.index ~= tes3.activeBodyPart.head) and (e.index ~= tes3.activeBodyPart.hair) then
		return
	end

	if e.object then
		if e.object.objectType == tes3.objectType.armor and e.object.slot == tes3.armorSlot.helmet then
			if e.bodyPart.part == parts.head then
				return
			elseif e.bodyPart.part == parts.hair then
				return
			end
		end
	end

	if (e.bodyPart.vampiric == true) then
		return
	end

	checkName = e.reference.object.name
	if nameCheck() == false then
		return
	end

	local randomHair
	local randomHead
	local checkRace = e.reference.object.race.id
	local checkSex = e.reference.baseObject.female

	if (e.index == tes3.activeBodyPart.head) then

		if (e.reference.data.rngHead ~= nil) then
			e.bodyPart = tes3.getObject(e.reference.data.rngHead)
			return
		end

		if checkRace == "Argonian" and checkSex == true then
			randomHead = table.choice(AFheadTable)

		elseif checkRace == "Argonian" and checkSex == false then
			randomHead = table.choice(AMheadTable)

		elseif checkRace == "Breton" and checkSex == true then
			randomHead = table.choice(BFheadTable)

		elseif checkRace == "Breton" and checkSex == false then
			randomHead = table.choice(BMheadTable)

		elseif checkRace == "Dark Elf" and checkSex == true then
			randomHead = table.choice(DFheadTable)

		elseif checkRace == "Dark Elf" and checkSex == false then
			randomHead = table.choice(DMheadTable)

		elseif checkRace == "High Elf" and checkSex == true then
			randomHead = table.choice(HFheadTable)

		elseif checkRace == "High Elf" and checkSex == false then
			randomHead = table.choice(HMheadTable)

		elseif checkRace == "Imperial" and checkSex == true then
			randomHead = table.choice(IFheadTable)

		elseif checkRace == "Imperial" and checkSex == false then
			randomHead = table.choice(IMheadTable)

		elseif checkRace == "Khajiit" and checkSex == true then
			randomHead = table.choice(KFheadTable)

		elseif checkRace == "Khajiit" and checkSex == false then
			randomHead = table.choice(KMheadTable)

		elseif checkRace == "Nord" and checkSex == true then
			randomHead = table.choice(NFheadTable)

		elseif checkRace == "Nord" and checkSex == false then
			randomHead = table.choice(NMheadTable)

		elseif checkRace == "Orc" and checkSex == true then
			randomHead = table.choice(OFheadTable)

		elseif checkRace == "Orc" and checkSex == false then
			randomHead = table.choice(OMheadTable)

		elseif checkRace == "Redguard" and checkSex == true then
			randomHead = table.choice(RFheadTable)

		elseif checkRace == "Redguard" and checkSex == false then
			randomHead = table.choice(RMheadTable)

		elseif checkRace == "Wood Elf" and checkSex == true then
			randomHead = table.choice(WFheadTable)

		elseif checkRace == "Wood Elf" and checkSex == false then
			randomHead = table.choice(WMheadTable)
		end
		e.reference.data.rngHead = e.reference.data.rngHead or randomHead
		e.bodyPart = tes3.getObject(randomHead)
	end

	if (e.index == tes3.activeBodyPart.hair) then

		if (e.reference.data.rngHair ~= nil) then
			e.bodyPart = tes3.getObject(e.reference.data.rngHair)
			return
		end

		if checkRace == "Argonian" and checkSex == true then
			randomHair = table.choice(AFhairTable)

		elseif checkRace == "Argonian" and checkSex == false then
			randomHair = table.choice(AMhairTable)

		elseif checkRace == "Breton" and checkSex == true then
			randomHair = table.choice(BFhairTable)

		elseif checkRace == "Breton" and checkSex == false then
			randomHair = table.choice(BMhairTable)

		elseif checkRace == "Dark Elf" and checkSex == true then
			randomHair = table.choice(DFhairTable)

		elseif checkRace == "Dark Elf" and checkSex == false then
			randomHair = table.choice(DMhairTable)

		elseif checkRace == "High Elf" and checkSex == true then
			randomHair = table.choice(HFhairTable)

		elseif checkRace == "High Elf" and checkSex == false then
			randomHair = table.choice(HMhairTable)

		elseif checkRace == "Imperial" and checkSex == true then
			randomHair = table.choice(IFhairTable)

		elseif checkRace == "Imperial" and checkSex == false then
			randomHair = table.choice(IMhairTable)

		elseif checkRace == "Khajiit" and checkSex == true then
			randomHair = table.choice(KFhairTable)

		elseif checkRace == "Khajiit" and checkSex == false then
			randomHair = table.choice(KMhairTable)

		elseif checkRace == "Nord" and checkSex == true then
			randomHair = table.choice(NFhairTable)

		elseif checkRace == "Nord" and checkSex == false then
			randomHair = table.choice(NMhairTable)

		elseif checkRace == "Orc" and checkSex == true then
			randomHair = table.choice(OFhairTable)

		elseif checkRace == "Orc" and checkSex == false then
			randomHair = table.choice(OMhairTable)

		elseif checkRace == "Redguard" and checkSex == true then
			randomHair = table.choice(RFhairTable)

		elseif checkRace == "Redguard" and checkSex == false then
			randomHair = table.choice(RMhairTable)

		elseif checkRace == "Wood Elf" and checkSex == true then
			randomHair = table.choice(WFhairTable)

		elseif checkRace == "Wood Elf" and checkSex == false then
			randomHair = table.choice(WMhairTable)
		end
		e.reference.data.rngHair = e.reference.data.rngHair or randomHair
		e.bodyPart = tes3.getObject(randomHair)
	end
end

local function initialized()
    event.register("bodyPartAssigned", onBodyPartAssigned)
end
event.register("initialized", initialized)