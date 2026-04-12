local config = require("HP_SA.config")
local log = mwse.Logger.new()
local util = require("HP_SA.util")

local interop = {}

-- Here we define the NPC powers. NPC races must be in lower case
interop.NPCpowers = {
    ["argonian"]    = "racial_argonian_npc",
    ["breton"]      = "racial_breton_npc",
    ["dark elf"]    = "racial_darkelf_npc",
    ["high elf"]    = "racial_highelf_npc",
    ["imperial"]    = "racial_imperial_npc",
    ["khajiit"]     = "racial_khajiit_npc",
    ["nord"]        = "racial_nord_npc",
    ["orc"]         = "racial_orc_npc",
    ["redguard"]    = "racial_redguard_npc",
    ["wood elf"]    = "racial_woodelf_npc",
    ["t_cyr_ayleid"]		= "racial_ayleid_npc",
    ["t_els_cathay"]		= "racial_khajiit_npc",
    ["t_els_cathay-raht"]	= "racial_khajiit_npc",
	["t_els_dagi-raht"]		= "racial_khajiit_npc_3",
	["t_els_ohmes"]			= "racial_khajiit_npc_2",
	["t_els_ohmes-raht"]	= "racial_khajiit_npc_2",
	["t_els_suthay"]		= "racial_khajiit_npc_2",
    ["t_cnq_chimeriquey"]	= "racial_chimeri_npc",
    ["t_yok_duadri"]		= "racial_duadri_npc",
    ["t_val_imga"]			= "racial_imga_npc",
    ["t_cnq_keptu"]			= "racial_keptu_npc",
    ["t_sky_reachman"]		= "racial_reachman_npc",
    ["t_hr_riverfolk"]		= "racial_riverfolk_npc",
    ["t_pya_seaelf"]		= "racial_seaelf_npc",
    ["t_aka_tsaesci"]		= "racial_tsaesci_npc",
    ["t_yne_ynesai"]		= "racial_ynesai_npc"
}

-- Here we define the player character powers. As before, races must be in lower case
interop.PCpowers = {
    ["argonian"]    = "racial_argonian_power",
    ["breton"]      = "racial_breton_power",
    ["dark elf"]    = "racial_darkelf_power",
    ["high elf"]    = "racial_highelf_power",
    ["imperial"]    = "racial_imperial_power_2",
    ["khajiit"]     = "racial_khajiit_power",
    ["nord"]        = "racial_nord_power",
    ["orc"]         = "racial_orc_power",
    ["redguard"]    = "racial_redguard_power",
    ["wood elf"]    = "racial_woodelf_power",
	["t_cyr_ayleid"]		= "racial_ayleid_power",
    ["t_els_cathay"]		= "racial_khajiit_power",
    ["t_els_cathay-raht"]	= "racial_khajiit_power",
	["t_els_dagi-raht"]		= "racial_khajiit_power_3",
	["t_els_ohmes"]			= "racial_khajiit_power_2",
	["t_els_ohmes-raht"]	= "racial_khajiit_power_2",
	["t_els_suthay"]		= "racial_khajiit_power_2",
    ["t_cnq_chimeriquey"]	= "racial_chimeri_power",
    ["t_yok_duadri"]		= "racial_duadri_power",
    ["t_val_imga"]			= "racial_imga_power",
    ["t_cnq_keptu"]			= "racial_keptu_power",
    ["t_sky_reachman"]		= "racial_reachman_power",
    ["t_hr_riverfolk"]		= "racial_riverfolk_power",
    ["t_pya_seaelf"]		= "racial_seaelf_power",
    ["t_aka_tsaesci"]		= "racial_tsaesci_power",
    ["t_yne_ynesai"]		= "racial_ynesai_power"
}

-- Container for all playable races

interop.allRaces = {}

-- Playable races list
interop.thisModRaces = {
    ["argonian"]    = true,
    ["breton"]      = true,
    ["dark elf"]    = true,
    ["high elf"]    = true,
    ["imperial"]    = true,
    ["khajiit"]     = true,
    ["nord"]        = true,
    ["orc"]         = true,
    ["redguard"]    = true,
    ["wood elf"]    = true,
	["t_cyr_ayleid"]		= true,
    ["t_els_cathay"]		= true,
    ["t_els_cathay-raht"]	= true,
	["t_els_dagi-raht"]		= true,
	["t_els_ohmes"]			= true,
	["t_els_ohmes-raht"]	= true,
	["t_els_suthay"]		= true,
    ["t_cnq_chimeriquey"]	= true,
    ["t_yok_duadri"]		= true,
    ["t_val_imga"]			= true,
    ["t_cnq_keptu"]			= true,
    ["t_sky_reachman"]		= true,
    ["t_hr_riverfolk"]		= true,
    ["t_pya_seaelf"]		= true,
    ["t_aka_tsaesci"]		= true,
    ["t_yne_ynesai"]		= true
}

-- Missing races list. Included as a failsafe (and also as a secret list :D)
interop.notThisModRaces = {}

-- Races to names table. It is initialized automaticaly

interop.raceIDtoName = {}

-- Vanilla list
interop.onlyVanilla = {
    ["argonian"]    = false,
    ["breton"]      = false,
    ["dark elf"]    = false,
    ["high elf"]    = false,
    ["imperial"]    = false,
    ["khajiit"]     = false,
    ["nord"]        = false,
    ["orc"]         = false,
    ["redguard"]    = false,
    ["wood elf"]    = false,
}


interop.onlyDarkElf = {
    ["dark elf"]    = false,
}


interop.topics = {
    ["argonian"]    = "argonian",
    ["breton"]      = "breton",
    ["dunmer"]      = "dark elf",
    ["altmer"]      = "high elf",
    ["bosmer"]      = "wood elf",
    ["imperial"]    = "imperial",
    ["khajiit"]     = "khajiit",
    ["nord"]        = "nord",
    ["orc"]         = "orc",
    ["redguard"]    = "redguard",
    ["ayleid"]          = "t_cyr_ayleid",
    ["wild elves"]      = "t_cyr_ayleid",
    ["chimeri-quey"]    = "t_cnq_chimeriquey",
    ["keptu-quey"]      = "t_cnq_keptu",
    ["riverfolk"]       = "t_hr_riverfolk",
    ["reachmen"]        = "t_sky_reachman",
    ["sea elf"]         = "t_pya_seaelf",
    ["maormer"]         = "t_pya_seaelf",
}

interop.missingTopic = {
    ["argonian"]    = false,
    ["breton"]      = false,
    ["dark elf"]    = false,
    ["high elf"]    = false,
    ["imperial"]    = false,
    ["khajiit"]     = false,
    ["nord"]        = false,
    ["orc"]         = false,
    ["redguard"]    = false,
    ["wood elf"]    = false,
	["t_cyr_ayleid"]		= false,
    ["t_els_cathay"]		= true, -- missing
    ["t_els_cathay-raht"]	= true, -- missing
	["t_els_dagi-raht"]		= true, -- missing
	["t_els_ohmes"]			= true, -- missing
	["t_els_ohmes-raht"]	= true, -- missing
	["t_els_suthay"]		= true, -- missing
    ["t_cnq_chimeriquey"]	= false,
    ["t_yok_duadri"]		= true, -- missing
    ["t_val_imga"]			= true, -- missing
    ["t_cnq_keptu"]			= true, -- missing
    ["t_sky_reachman"]		= false,
    ["t_hr_riverfolk"]		= false,
    ["t_pya_seaelf"]		= false,
    ["t_aka_tsaesci"]		= false,
    ["t_yne_ynesai"]		= false
}

interop.khajiits = {
    ["t_els_cathay"]		= true, -- missing
    ["t_els_cathay-raht"]	= true, -- missing
	["t_els_dagi-raht"]		= true, -- missing
	["t_els_ohmes"]			= true, -- missing
	["t_els_ohmes-raht"]	= true, -- missing
	["t_els_suthay"]		= true, -- missing
}

-- Here we can define new powers, if needed
---@type SpellMaker.params[]
interop.newPowers = {
 {  id = "glitterstorm_st_veloth_power",
    name = "Veloth's Steps",
    castType = tes3.spellType.power,
    effects = {
        { id = tes3.effect.waterWalking,                                                duration = 10, rangeType = tes3.effectRange["self"] },
        { id = tes3.effect.feather,                                                     duration = 10, min=5, max=5, rangeType = tes3.effectRange["self"] },
        { id = tes3.effect.fortifyAttribute,    attribute = tes3.attribute.speed,       duration = 10, min=5, max=5, rangeType = tes3.effectRange["self"] },
        { id = tes3.effect.fortifyAttribute,    attribute = tes3.attribute.endurance,   duration = 10, min=5, max=5, rangeType = tes3.effectRange["self"] },
        { id = tes3.effect.fortifyAttribute,    attribute = tes3.attribute.willpower,   duration = 10, min=5, max=5, rangeType = tes3.effectRange["self"]},
        },
    },
}


return interop