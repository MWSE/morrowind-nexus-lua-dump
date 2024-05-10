--[[
	Mod: RZZ Редикюль Зеленого Змея
	Author: Borivit
    Version: 4.6
]]--
--local aux_util = require('rzz_cwa.util')
RZZ_Version = 4.6
i18n = mwse.loadTranslations("rzz_cwa")
local win = require("rzz_cwa.window")
local isort = require("rzz_cwa.inventorysort")
local func = require("rzz_cwa.functions")
local myMenuRZZ
is_maldito = false
isMagPlus = false
RZZ_activate = false
local manekenTip = false
local is_amulet_combat = false
local nameEffects = {
	[0] = i18n("main.nameEffects.0"), --waterBreathing	0
	[1] = i18n("main.nameEffects.1"), --swiftSwim	1
	[2] = i18n("main.nameEffects.2"), --waterWalking	2
	[3] = i18n("main.nameEffects.3"), --shield	3
	[4] = i18n("main.nameEffects.4"), --fireShield	4
	[5] = i18n("main.nameEffects.5"), --lightningShield	5
	[6] = i18n("main.nameEffects.6"), --frostShield	6
	[7] = i18n("main.nameEffects.7"), --burden	7
	[8] = i18n("main.nameEffects.8"), --feather	8
	[9] = i18n("main.nameEffects.9"), --jump	9
	[10] = i18n("main.nameEffects.10"), --levitate	10
	[11] = i18n("main.nameEffects.11"), --slowFall	11
	[12] = i18n("main.nameEffects.12"), --lock	12
	[13] = i18n("main.nameEffects.13"), --open	13
	[14] = i18n("main.nameEffects.14"),--fireDamage	14
	[15] = i18n("main.nameEffects.15"),--shockDamage	15
	[16] = i18n("main.nameEffects.16"),--frostDamage	16
	[17] = i18n("main.nameEffects.17"), --drainAttribute	17
	[18] = i18n("main.nameEffects.18"), --drainHealth	18
	[19] = i18n("main.nameEffects.19"), --drainMagicka	19
	[20] = i18n("main.nameEffects.20"), --drainFatigue	20
	[21] = i18n("main.nameEffects.21"), --drainSkill	21
	[22] = i18n("main.nameEffects.22"), --damageAttribute	22
	[23] = i18n("main.nameEffects.23"), --damageHealth	23
	[24] = i18n("main.nameEffects.24"), --damageMagicka	24
	[25] = i18n("main.nameEffects.25"), --damageFatigue	25
	[26] = i18n("main.nameEffects.26"), --damageSkill	26
	[27] = i18n("main.nameEffects.27"), --poison	27
	[28] = i18n("main.nameEffects.28"), --weaknesstoFire	28
	[29] = i18n("main.nameEffects.29"), --weaknesstoFrost	29
	[30] = i18n("main.nameEffects.30"), --weaknesstoShock	30
	[31] = i18n("main.nameEffects.31"), --weaknesstoMagicka	31
	[32] = i18n("main.nameEffects.32"), --weaknesstoCommonDisease	32
	[33] = i18n("main.nameEffects.33"), --weaknesstoBlightDisease	33
	[34] = i18n("main.nameEffects.34"), --weaknesstoCorprusDisease	34
	[35] = i18n("main.nameEffects.35"), --weaknesstoPoison	35
	[36] = i18n("main.nameEffects.36"),--weaknesstoNormalWeapons	36
	[37] = i18n("main.nameEffects.37"), --disintegrateWeapon	37
	[38] = i18n("main.nameEffects.38"), --disintegrateArmor	38
	[39] = i18n("main.nameEffects.39"), --invisibility	39
	[40] = i18n("main.nameEffects.40"), --chameleon	40
	[41] = i18n("main.nameEffects.41"), --light	41
	[42] = i18n("main.nameEffects.42"), --sanctuary	42
	[43] = i18n("main.nameEffects.43"), --nightEye	43
	[44] = i18n("main.nameEffects.44"), --charm	44
	[45] = i18n("main.nameEffects.45"), --paralyze	45
	[46] = i18n("main.nameEffects.46"), --silence	46
	[47] = i18n("main.nameEffects.47"), --blind	47
	[48] = i18n("main.nameEffects.48"), --sound	48
	[49] = i18n("main.nameEffects.49"), --calmHumanoid	49
	[50] = i18n("main.nameEffects.50"), --calmCreature	50
	[51] = i18n("main.nameEffects.51"), --frenzyHumanoid	51
	[52] = i18n("main.nameEffects.52"), --frenzyCreature	52
	[53] = i18n("main.nameEffects.53"), --demoralizeHumanoid	53
	[54] = i18n("main.nameEffects.54"), --demoralizeCreature	54
	[55] = i18n("main.nameEffects.55"), --rallyHumanoid	55
	[56] = i18n("main.nameEffects.56"), --rallyCreature	56
	[57] = i18n("main.nameEffects.57"), --dispel	57
	[58] = i18n("main.nameEffects.58"),--soultrap	58
	[59] = i18n("main.nameEffects.59"), --telekinesis	59
	[60] = i18n("main.nameEffects.60"), --mark	60
	[61] = i18n("main.nameEffects.61"), --recall	61
	[62] = i18n("main.nameEffects.62"), --divineIntervention	62
	[63] = i18n("main.nameEffects.63"), --almsiviIntervention	63
	[64] = i18n("main.nameEffects.64"), --detectAnimal	64
	[65] = i18n("main.nameEffects.65"), --detectEnchantment	65
	[66] = i18n("main.nameEffects.66"), --detectKey	66
	[67] = i18n("main.nameEffects.67"), --spellAbsorption	67
	[68] = i18n("main.nameEffects.68"), --reflect	68
	[69] = i18n("main.nameEffects.69"), --cureCommonDisease	69
	[70] = i18n("main.nameEffects.70"), --cureBlightDisease	70
	[71] = i18n("main.nameEffects.71"), --cureCorprusDisease	71
	[72] = i18n("main.nameEffects.72"), --curePoison	72
	[73] = i18n("main.nameEffects.73"), --cureParalyzation	73
	[74] = i18n("main.nameEffects.74"), --restoreAttribute	74
	[75] = i18n("main.nameEffects.75"), --restoreHealth	75
	[76] = i18n("main.nameEffects.76"), --restoreMagicka	76
	[77] = i18n("main.nameEffects.77"), --restoreFatigue	77
	[78] = i18n("main.nameEffects.78"), --restoreSkill	78
	[79] = i18n("main.nameEffects.79"), --fortifyAttribute	79
	[80] = i18n("main.nameEffects.80"), --fortifyHealth	80
	[81] = i18n("main.nameEffects.81"), --fortifyMagicka	81
	[82] = i18n("main.nameEffects.82"), --fortifyFatigue	82
	[83] = i18n("main.nameEffects.83"), --fortifySkill	83
	[84] = i18n("main.nameEffects.84"), --fortifyMaximumMagicka	84
	[85] = i18n("main.nameEffects.85"), --absorbAttribute	85
	[86] = i18n("main.nameEffects.86"), --absorbHealth	86
	[87] = i18n("main.nameEffects.87"), --absorbMagicka	87
	[88] = i18n("main.nameEffects.88"), --absorbFatigue	88
	[89] = i18n("main.nameEffects.89"), --absorbSkill	89
	[90] = i18n("main.nameEffects.90"), --resistFire	90
	[91] = i18n("main.nameEffects.91"), --resistFrost	91
	[92] = i18n("main.nameEffects.92"), --resistShock	92
	[93] = i18n("main.nameEffects.93"), --resistMagicka	93
	[94] = i18n("main.nameEffects.94"), --resistCommonDisease	94
	[95] = i18n("main.nameEffects.95"), --resistBlightDisease	95
	[96] = i18n("main.nameEffects.96"), --resistCorprusDisease	96
	[97] = i18n("main.nameEffects.97"), --resistPoison	97
	[98] = i18n("main.nameEffects.98"), --resistNormalWeapons	98
	[99] = i18n("main.nameEffects.99"), --resistParalysis	99
	[100] = i18n("main.nameEffects.100"), --removeCurse	100
	[101] = i18n("main.nameEffects.101"), --turnUndead	101
	[102] = i18n("main.nameEffects.102"), --summonScamp	102
	[103] = i18n("main.nameEffects.103"), --summonClannfear	103
	[104] = i18n("main.nameEffects.104"), --summonDaedroth	104
	[105] = i18n("main.nameEffects.105"), --summonDremora	105
	[106] = i18n("main.nameEffects.106"), --summonAncestralGhost	106
	[107] = i18n("main.nameEffects.107"), --summonSkeletalMinion	107
	[108] = i18n("main.nameEffects.108"), --summonBonewalker	108
	[109] = i18n("main.nameEffects.109"), --summonGreaterBonewalker	109
	[110] = i18n("main.nameEffects.110"), --summonBonelord	110
	[111] = i18n("main.nameEffects.111"), --summonWingedTwilight	111
	[112] = i18n("main.nameEffects.112"), --summonHunger	112
	[113] = i18n("main.nameEffects.113"), --summonGoldenSaint	113
	[114] = i18n("main.nameEffects.114"), --summonFlameAtronach	114
	[115] = i18n("main.nameEffects.115"), --summonFrostAtronach	115
	[116] = i18n("main.nameEffects.116"), --summonStormAtronach	116
	[117] = i18n("main.nameEffects.117"), --fortifyAttack	117
	[118] = i18n("main.nameEffects.118"), --commandCreature	118
	[119] = i18n("main.nameEffects.119"), --commandHumanoid	119
	[120] = i18n("main.nameEffects.120"), --boundDagger	120
	[121] = i18n("main.nameEffects.121"), --boundLongsword	121
	[122] = i18n("main.nameEffects.122"), --boundMace	122
	[123] = i18n("main.nameEffects.123"), --boundBattleAxe	123
	[124] = i18n("main.nameEffects.124"), --boundSpear	124
	[125] = i18n("main.nameEffects.125"), --boundLongbow	125
	[126] = i18n("main.nameEffects.126"), --eXTRASPELL	126
	[127] = i18n("main.nameEffects.127"), --boundCuirass	127
	[128] = i18n("main.nameEffects.128"), --boundHelm	128
	[129] = i18n("main.nameEffects.129"), --boundBoots	129
	[130] = i18n("main.nameEffects.130"), --boundShield	130
	[131] = i18n("main.nameEffects.131"), --boundGloves	131
	[132] = i18n("main.nameEffects.132"), --corprus	132
	[133] = i18n("main.nameEffects.133"), --vampirism	133
	[134] = i18n("main.nameEffects.134"), --summonCenturionSphere	134
	[135] = i18n("main.nameEffects.135"), --sunDamage	135
	[136] = i18n("main.nameEffects.136"), --stuntedMagicka	136
	[137] = i18n("main.nameEffects.137"), --summonFabricant	137
	[138] = i18n("main.nameEffects.138"), --callWolf	138
	[139] = i18n("main.nameEffects.139"), --callBear	139
	[140] = i18n("main.nameEffects.140"), --summonBonewolf	140
	[141] = i18n("main.nameEffects.141"), --sEffectSummonCreature04	141
	[142] = i18n("main.nameEffects.142"), --sEffectSummonCreature05	142
}

cosaLegenda = { --Ленендарные предметы 
	[0] = "daedric_scourge_unique", 			--Бич даэдра
	[1] = "mehrunes'_razor_unique", 			--Бритва Мехруна
	[2] = "mace of molag bal_unique", 			--Будава Молаг Бала
	[3] = "sunder", 							--Разделитель
	[4] = "warhammer_crusher_unique", 			--Крушитель черепов
	[5] = "katana_goldbrand_unique", 			--Золотой меч
	[6] = "dagger_fang_unique", 				--Клык Хайнектнамет
	[7] = "keening", 							--Разрубатель
	[8] = "longsword_umbra_unique", 			--Меч Умбры
	[9] = "daedric_crescent_unique", 			--Даэдрический полумесяц
	[10] = "staff_magnus_unique", 				--Посох Магнуса
	[11] = "staff_hasedoki_unique", 			--Посох Хаседоки
	[12] = "claymore_iceblade_unique", 			--Ледяной клинок монарха
	[13] = "claymore_chrysamere_unique",		--Хризамер
	[14] = "spear_mercy_unique", 				--Копье горькой милости
	[15] = "longbow_shadows_unique", 			--Лук теней
	[16] = "ebony_bow_auriel", 					--Лук Ауриэля
	[17] = "dwarven_hammer_volendrung", 		--Волендранг
	
	[18] = "daedric_helm_clavicusvile", 		--Маска Клавикуса
	[19] = "bloodworm_helm_unique", 			--Шлем дождевого червя
	[20] = "helm_bearclaw_unique", 				--Шлем Орейна
	[21] = "lords_cuirass_unique", 				--Кольчуга повелителя
	[22] = "dragonbone_cuirass_unique", 		--Кираса кости дракона
	[23] = "ebon_plate_cuirass_unique", 		--Эбонитовая кольчуго
	[24] = "cuirass_savior_unique", 			--Кираса из шкуры спасителя
	[25] = "spell_breaker_unique", 				--Разрушитель заклятий
	[26] = "towershield_eleidon_unique",		--Символ Элеидона
	[27] = "ebony_bow_auriel", 					--Щит Ауриэля
	[28] = "gauntlet_fists_l_unique", 			--Кулаки Рандагульфа
	[29] = "gauntlet_fists_r_unique", 			--Кулаки Рандагульфа
	[30] = "wraithguard_jury_rig", 				--Призрачный страж
	[31] = "wraithguard", 						--Призрачный страж
	[32] = "boots_apostle_unique", 				--Ботинки апостола
	[33] = "boots of blinding speed[unique]", 	--Сапоги ослепляющей скорости
	
	[34] = "necromancers_amulet_uniq", 			--Амулет некроманта
	[35] = "ring_wind_unique", 					--Колцо ветра
	[36] = "ring_mentor_unique", 				--Кольцо учителя
	[37] = "ring_khajiit_unique", 				--Кольцо Хаджита
	[38] = "ring_warlock_unique", 				--Кольцо Чернокнижника
	[39] = "ring_marara_unique", 				--Кольцо Марары
	[40] = "ring_vampiric_unique", 				--Вампирическое кольцо 
	[41] = "ring_phynaster_unique", 			--Кольцо Финастера
	[42] = "ring_surrounding_unique", 			--Кольцо Окружения
	[43] = "ring_denstagmer_unique", 			--Кольцо Денстагмера
	---------------------------------
	[44] = "Bipolar Blade",						--Биполярный клинок
	[45] = "tenpaceboots",						--Ботинки Легкой Походки
	[46] = "Mace of Slurring",					--Булава Порока
	[47] = "glass dagger_symmachus_unique",		--Кинжал Симмаха
	[48] = "robe_lich_unique",					--Мантия Лича
	[49] = "daedric warhammer_ttgd",			--Правосудие Велота
	[50] = "ebony_shield_auriel",				--Щит Ауриэля
	[51] = "nerevarblade_01_flame",				--Истинное Пламя
	[52] = "Sword of Almalexia",				--Огонь Надежды
	[53] = "ring of azura",						--Кольцо Азуры
	[54] = "moon_and_star",						--Луна-и-Звезда
	[55] = "BM_Mace_Aevar_UNI",					--Булава Аэвара каменного певца
	[56] = "lightofday_unique",					--Свет дня
	[57] = "mazed_band_end",					--Лента Лабиринта Барилзара
	[58] = "stendar_hammer_unique",				--Молот Стендарра 
	[59] = "Sheogorath's Signet Ring",			--Кольцо-печатка Шигората
	[60] = "katana_bluebrand_unique", 			--Золотой меч
	
	--[] = "",
}

local apparatusN = {
	[0] = i18n("main.app.secret"),
	[1] = i18n("main.app.grand"),
	[2] = i18n("main.app.master"),
	[3] = i18n("main.app.gildia"),
	[4] = i18n("main.app.ayuda"),
	[5] = i18n("main.app.alumno"),
}

local apparatusId = {
	[0] = "_sm_",
	[1] = "_g_",
	[2] = "_m_",
	[3] = "_gmb_",
	[4] = "_j_",
	[5] = "_a_",
}

function cerrarMenu() --закрываем меню
	myMenuRZZ.hide()
end

local function cosort() --сортировка инвентаря
	isort.cosort()
	cerrarMenu()
	tes3.messageBox{ message = i18n("main.cosort") }
end

local function resort() --Возврат игроку предметов
	isort.resort()
	cerrarMenu()
	tes3.messageBox{ message = i18n("main.resort") }
end

local function Freez() --Заморозка предметов в инвентаре
	isort.Freez()
	cerrarMenu()
	tes3.messageBox{ message = i18n("main.freez") }
end

local function antiFreez() --Разморозка предметов в инвентаре
	isort.antiFreez()
	cerrarMenu()
	tes3.messageBox{ message = i18n("main.antifreez") }
end

local function returnSpell() --выход из тайника
	cerrarMenu()
	local basura = tes3.getReference("A_RZZ_basura")
	local maneken = tes3.getReference("A_RZZ_Maneken_f")
	local tomb = tes3.getObject("A_RZZ_chest_tomb_1")--редикюль
	
	if (basura) then basura:delete() end
	if (maneken) then maneken:delete() end
	RZZ_activate = nil
	isCombat = nil
	func.FloraTimeInicio()
	
	for i, stack in pairs(tes3.player.object.inventory) do
		if (stack.object) then
			if string.find(stack.object.id,'A_RZZ_dagger_soultrap') then
				tes3.transferItem{from=tes3.player, to=tomb.id, item=stack.object, count=stack.count, playSound=false}
				goto continue
			end
			if string.find(stack.object.id,'A_RZZ_goldensaint') then
				tes3.transferItem{from=tes3.player, to=tomb.id, item=stack.object, count=stack.count, playSound=false}
				goto continue
			end
			::continue::
		end
	end
	
	tes3.cast({ 
		reference = tes3.player,
		target = tes3.player,
		spell = "A_RZZ_Recall", 
		instant = true 
	})
	
	tes3.positionCell {
		reference = tes3.player,
		cell = data.A_RZZ.cell,
		position = {data.A_RZZ.position.x, data.A_RZZ.position.y, data.A_RZZ.position.z},
		orientation = {0, 0, data.A_RZZ.orientation.z}
	}
end

local function llamarRZZ() --вызов сундука 
	local cell = tes3.getPlayerCell()
	local tomb_rzz = tes3.createReference{object="A_RZZ_chest_tomb_2", position=tes3.player.position, orientation=tes3.player.orientation, cell=cell}
	if (tomb_rzz) then
		func.Maldicion(true)
		cerrarMenu()
	end
end

local function devolverRZZ() --возврат сундука
	func.Maldicion()
	local tomb_rzz = tes3.getReference("A_RZZ_chest_tomb_2")
	if (tomb_rzz) then tomb_rzz:delete() end
	cerrarMenu()
end

local function telportRZZ() --переход в тайник
	func.metka()
	cerrarMenu()
	RZZ_activate = nil
	if (not is_maldito) then
		tes3.positionCell {
			reference = tes3.player,
			cell = i18n("main.cellName"),
			position = {-334, 460, 95},
			orientation = {0, 0, 180}
		}
	else
		tes3.messageBox{ message = i18n("main.maldicion") }
	end
end

MenuRZZ_1 = function() --меню главного сундука
	local width = 360
	local bwp = 0.65
	myMenuRZZ = win.new('myMenuRZZ')                	-- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))	-- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, '')					-- добавим блок номер 2
	myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_1.p1"), returnSpell, bwp)  
	myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_1.p2"), function() func.abrirRZZ("A_RZZ_chest_tomb_1") end, bwp)
	myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_1.p3"), cosort, bwp)
	if not data.A_RZZ.isFreez then
		myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_1.p4"), Freez, bwp)
	else
		myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_1.p5"), MenuRZZ_1_1, bwp)
	end
	myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_1.p6"), func.Medico, bwp)
	myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_1.p7"), MenuRZZ_1_2, bwp)
	myMenuRZZ.addBlockButton(2, i18n("main.btn.cancel"), cerrarMenu, bwp) -- кнопка назад
	myMenuRZZ.show()                            -- а теперь выведем окно
end

MenuRZZ_1_1 = function() --Подтверждение разморозки предметов
	cerrarMenu()
	local width = 600
	myMenuRZZ = win.new('myMenuRZZ')                	-- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ_1_1.title"), 45)	-- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, '', 30)					-- добавим блок номер 2	
	myMenuRZZ.addBlockButton(2, i18n("main.btn.si"), antiFreez, false, 0, 0.46)
	myMenuRZZ.addBlockButton(2, i18n("main.btn.no"), cerrarMenu, false, 0, 0.55) -- кнопка назад
	myMenuRZZ.show()                            -- а теперь выведем окно
end

MenuRZZ_1_2 = function() --Подтверждение возврата предметов
	cerrarMenu()
	local width = 600
	myMenuRZZ = win.new('myMenuRZZ')                	-- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ_1_2.title"), 45)	-- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, '', 30)					-- добавим блок номер 2	
	myMenuRZZ.addBlockButton(2, i18n("main.btn.si"), resort, false, 0, 0.46)
	myMenuRZZ.addBlockButton(2, i18n("main.btn.no"), cerrarMenu, false, 0, 0.55) -- кнопка назад
	myMenuRZZ.show()                            -- а теперь выведем окно
end

MenuRZZ_2 = function() --меню заклинания
  local width = 360
  myMenuRZZ = win.new('myMenuRZZ')                	-- создадим новое окно
  myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title")) 	-- добавим блок номер 1
  myMenuRZZ.addBlock(2, width, '')					-- добавим блок номер 2
  myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_2.p1"), telportRZZ)  
  myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_2.p2"), llamarRZZ)
  myMenuRZZ.addBlockButton(2, i18n("main.btn.cancel"), cerrarMenu) -- кнопка назад
  myMenuRZZ.show()                            -- а теперь выведем окно
end

MenuRZZ_3 = function() -- меню призываемого сундука
  local width = 360
  myMenuRZZ = win.new('myMenuRZZ')                -- создадим новое окно
  myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))  -- добавим блок номер 1
  myMenuRZZ.addBlock(2, width, '')-- добавим блок номер 2
  myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_3.p1"), devolverRZZ)  
  myMenuRZZ.addBlockButton(2, i18n("main.menuRZZ_3.p2"), function() func.abrirRZZ("A_RZZ_chest_tomb_2") end)
  myMenuRZZ.addBlockButton(2, i18n("main.btn.cancel"), cerrarMenu) -- кнопка назад
  myMenuRZZ.show() -- а теперь выведем окно
end

MenuRZZ_4 = function() -- меню ингредиентов
	local width = 300
	myMenuRZZ = win.new('myMenuRZZ')                -- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))  -- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, "")				-- добавим блок номер 2
	myMenuRZZ.addScrollPane(2, width)
	local mumia_1 = tes3.getReference("A_RZZ_mumia_1")
	local list = {}
	local list_test = nil
	for i, eim in pairs(mumia_1.object.inventory) do
		if (eim.object) then
			if (eim.object.objectType == tes3.objectType.ingredient) then
				local effects = eim.object.effects
				for i = 1,#effects do
				  local neff = nameEffects[effects[i]] or nil
				  if neff and not list[effects[i]] then
					list[effects[i]] = true
					myMenuRZZ.addScrollPaneTxt(neff, function() func.itemSort(mumia_1, "A_RZZ_crate_7", effects[i], tes3.objectType.ingredient, true) end)
					list_test = true
					break
				  end
				end
			end
		end
	end
	myMenuRZZ.ScrollPaneSort()
	myMenuRZZ.addBlock(3, width, "") -- добавим блок номер 3
	myMenuRZZ.addBlockButton(3, i18n("main.btn.abrirTodo"), function() func.abrirRZZ("A_RZZ_mumia_1") end)
	myMenuRZZ.addBlockButton(3, i18n("main.btn.cancel"), cerrarMenu)  --кнопка назад
	if list_test then myMenuRZZ.show() -- а теперь выведем окно
	else func.abrirRZZ("A_RZZ_mumia_1")
	end
end

MenuRZZ_5 = function() -- меню зелий
	local width = 300
	myMenuRZZ = win.new('myMenuRZZ')                -- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))  -- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, "")				-- добавим блок номер 2
	myMenuRZZ.addScrollPane(2, width)
	local mumia_2 = tes3.getReference("A_RZZ_mumia_2")
	local list = {}
	local list_test = nil
	for i, eim in pairs(mumia_2.object.inventory) do
		if (eim.object) then
			if (eim.object.objectType == tes3.objectType.alchemy) then
				local effects = eim.object.effects
				for i = 1,#effects do
					local neff = nameEffects[effects[i].id] or nil
					if neff and not list[effects[i].id] then
						list[effects[i].id] = true
						myMenuRZZ.addScrollPaneTxt(neff, function() func.itemSort(mumia_2, "A_RZZ_crate_8", effects[i].id, tes3.objectType.alchemy, true) end)
						list_test = true
						break
					end
				end
			end
		end
	end
	myMenuRZZ.ScrollPaneSort()
	myMenuRZZ.addBlock(3, width, "") -- добавим блок номер 3
	myMenuRZZ.addBlockButton(3, i18n("main.btn.abrirTodo"), function() func.abrirRZZ("A_RZZ_mumia_2") end)
	myMenuRZZ.addBlockButton(3, i18n("main.btn.cancel"), cerrarMenu)  --кнопка назад
	if list_test then myMenuRZZ.show() -- а теперь выведем окно
	else func.abrirRZZ("A_RZZ_mumia_2")
	end
end

MenuRZZ_6 = function() -- меню свитков
	local width = 300
	myMenuRZZ = win.new('myMenuRZZ')                -- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))  -- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, "")				-- добавим блок номер 2
	myMenuRZZ.addScrollPane(2, width)
	local small_3 = tes3.getReference("A_RZZ_chest_small_3")
	local list = {}
	local list_test = nil
	for i, eim in pairs(small_3.object.inventory) do
		if (eim.object) then
			if (eim.object.enchantment and eim.object.objectType == tes3.objectType.book) then
				local effects = eim.object.enchantment.effects
				for i = 1,#effects do
					local neff = nameEffects[effects[i].id] or nil
					if neff and not list[effects[i].id] then
						list[effects[i].id] = true
						myMenuRZZ.addScrollPaneTxt(neff, function() func.itemSort(small_3, "A_RZZ_chest_small_3_tmp", effects[i].id, tes3.objectType.book) end)
						list_test = true
						break
					end
				end
			end
		end
	end
	myMenuRZZ.ScrollPaneSort()
	myMenuRZZ.addBlock(3, width, "") -- добавим блок номер 3
	myMenuRZZ.addBlockButton(3, i18n("main.btn.abrirTodo"), function() func.abrirRZZ("A_RZZ_chest_small_3") end)
	myMenuRZZ.addBlockButton(3, i18n("main.btn.cancel"), cerrarMenu)  --кнопка назад
	if list_test then myMenuRZZ.show() -- а теперь выведем окно
	else func.abrirRZZ("A_RZZ_chest_small_3")
	end
end

MenuRZZ_7 = function() -- меню колец и амулетов
	local width = 300
	myMenuRZZ = win.new('myMenuRZZ')                -- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))  -- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, "")				-- добавим блок номер 2
	myMenuRZZ.addScrollPane(2, width)
	local small_9 = tes3.getReference("A_RZZ_chest_small_9")
	local list = {}
	local list_test = nil
	for i, eim in pairs(small_9.object.inventory) do
		if (eim.object) then
			if (eim.object.enchantment and eim.object.objectType == tes3.objectType.clothing) then
				local effects = eim.object.enchantment.effects
				for i = 1,#effects do
					local neff = nameEffects[effects[i].id] or nil
					if neff and not list[effects[i].id] then
						list[effects[i].id] = true
						myMenuRZZ.addScrollPaneTxt(neff, function() func.itemSort(small_9, "A_RZZ_chest_small_9_tmp", effects[i].id, tes3.objectType.clothing) end)
						list_test = true
						break
					end
				end
			end
		end
	end
	myMenuRZZ.ScrollPaneSort()
	myMenuRZZ.addBlock(3, width, "") -- добавим блок номер 3
	myMenuRZZ.addBlockButton(3, i18n("main.btn.abrirTodo"), function() func.abrirRZZ("A_RZZ_chest_small_9") end)
	myMenuRZZ.addBlockButton(3, i18n("main.btn.cancel"), cerrarMenu)  --кнопка назад
	if list_test then myMenuRZZ.show() -- а теперь выведем окно
	else func.abrirRZZ("A_RZZ_chest_small_9")
	end
end

MenuRZZ_8 = function() -- меню редких предметов
	local width = 300
	myMenuRZZ = win.new('myMenuRZZ')                -- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))  -- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, "")				-- добавим блок номер 2
	myMenuRZZ.addScrollPane(2, width)
	local small_12 = tes3.getReference("A_RZZ_chest_small_12")
	local list_test = {}
	for i, eim in pairs(small_12.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			if not list_test[0] then 
				for i = 0,#cosaLegenda do
					if obj_id == cosaLegenda[i] then
						myMenuRZZ.addScrollPaneTxt(i18n("main.raro.legenda"), function() func.legendRaroSort(small_12, "A_RZZ_chest_s_12_tmp", "legenda") end)
						list_test[0] = true
						goto continue
					end
				end
			end
			if not list_test[1] then 
				if eim.object.objectType == tes3.objectType.weapon or eim.object.objectType == tes3.objectType.ammunition then
					myMenuRZZ.addScrollPaneTxt(i18n("main.raro.weapon"), function() func.weaponRaroSort(small_12, "A_RZZ_chest_s_12_tmp", "weapon") end)
					list_test[1] = true
					goto continue
				end
			end
			if not list_test[2] then 
				if eim.object.objectType == tes3.objectType.armor then
					myMenuRZZ.addScrollPaneTxt(i18n("main.raro.armor"), function() func.armorRaroSort(small_12, "A_RZZ_chest_s_12_tmp", "armor") end)
					list_test[2] = true
					goto continue
				end
			end
			if not list_test[3] then 
				if eim.object.objectType == tes3.objectType.clothing then
					if (string.find(obj_id,'[Rr]ing') or string.find(eim.object.mesh,'[Rr]ing') or string.find(eim.object.mesh,'RING')) then
						myMenuRZZ.addScrollPaneTxt(i18n("main.raro.ring"), function() func.ringRaroSort(small_12, "A_RZZ_chest_s_12_tmp", "ring") end)
						list_test[3] = true
						goto continue
					end
				end
			end
			if not list_test[4] then 
				if eim.object.objectType == tes3.objectType.clothing then
					if (string.find(obj_id,'[Aa]mulet') or string.find(eim.object.mesh,'[Aa]mulet') or string.find(eim.object.mesh,'AMULET') or string.find(obj_id,'Crystal_Ball') or string.find(obj_id,'Daedric_special')) then
						myMenuRZZ.addScrollPaneTxt(i18n("main.raro.amulet"), function() func.amuletRaroSort(small_12, "A_RZZ_chest_s_12_tmp", "amulet") end)
						list_test[4] = true
						goto continue
					end
				end
			end
			if not list_test[5] then 
				if eim.object.objectType == tes3.objectType.clothing then
					if (not string.find(obj_id,'[Rr]ing') and not string.find(eim.object.mesh,'[Rr]ing') and not string.find(eim.object.mesh,'RING')) then
						if (not string.find(obj_id,'[Aa]mulet') and not string.find(eim.object.mesh,'[Aa]mulet') and not string.find(eim.object.mesh,'AMULET') and not string.find(obj_id,'Crystal_Ball') and not string.find(obj_id,'Daedric_special')) then
							myMenuRZZ.addScrollPaneTxt(i18n("main.raro.ropa"), function() func.ropaRaroSort(small_12, "A_RZZ_chest_s_12_tmp", "ropa") end)
							list_test[5] = true
							goto continue
						end
					end
				end
			end
			if not list_test[6] then 
				if (eim.object.objectType ~= tes3.objectType.weapon and eim.object.objectType ~= tes3.objectType.clothing and eim.object.objectType ~= tes3.objectType.armor and eim.object.objectType ~= tes3.objectType.weapon and eim.object.objectType ~= tes3.objectType.ammunition) then
					myMenuRZZ.addScrollPaneTxt(i18n("main.raro.cosa"), function() func.miscRaroSort(small_12, "A_RZZ_chest_s_12_tmp", "miscitem") end)
					list_test[6] = true
					goto continue
				end
			end
		end
		::continue::
	end
	
	myMenuRZZ.ScrollPaneSort()
	myMenuRZZ.addBlock(3, width, "") -- добавим блок номер 3
	myMenuRZZ.addBlockButton(3, i18n("main.btn.cancel"), cerrarMenu)  --кнопка назад
	if list_test[0] or list_test[1] or list_test[2] or list_test[3] or list_test[4] or list_test[5] or list_test[6] then 
		myMenuRZZ.show() -- а теперь выведем окно
	else 
		cerrarMenu()
		tes3.messageBox{ message = "Редкие предметы отсутствуют" }
	end
end

MenuRZZ_9 = function() -- меню алхимических аппаратов
	local width = 300
	myMenuRZZ = win.new('myMenuRZZ')                -- создадим новое окно
	myMenuRZZ.addBlock(1, width, i18n("main.menuRZZ.title"))  -- добавим блок номер 1
	myMenuRZZ.addBlock(2, width, "")				-- добавим блок номер 2
	myMenuRZZ.addScrollPane(2, width)
	local barrel_1 = tes3.getReference("A_RZZ_barrel_1")
	local list = {}
	local list_test = nil
	for i, eim in pairs(barrel_1.object.inventory) do
		if (eim.object) then
			if (eim.object.objectType == tes3.objectType.apparatus) then
				
				for i = 0,#apparatusId do
					
					if string.find(eim.object.id, apparatusId[i]) and not list[i]  then
						list[i] = true
						myMenuRZZ.addScrollPaneTxt(apparatusN[i], function() func.appSort(barrel_1, "A_RZZ_barrel_1_tmp", apparatusId[i]) end)
						list_test = true
						break
					end
				end
			end
		end
	end
	
	myMenuRZZ.ScrollPaneSort()
	myMenuRZZ.addBlock(3, width, "") -- добавим блок номер 3
	myMenuRZZ.addBlockButton(3, i18n("main.btn.abrirTodo"), function() func.abrirRZZ("A_RZZ_barrel_1") end)
	myMenuRZZ.addBlockButton(3, i18n("main.btn.cancel"), cerrarMenu)  --кнопка назад
	if list_test then myMenuRZZ.show() -- а теперь выведем окно
	else func.abrirRZZ("A_RZZ_barrel_1")
	end
end

local function eActivate(e)
	----------Вызов утилизатора мусора----------
	if (e.target.object.id == "A_RZZ_active_bell_01") then
		if ( not isManeken) then
			if (llamada == nil) then
				local cell = tes3.getPlayerCell()
				local vector_pos = tes3vector3.new(-346, 250, 25)
				local vector_orient = tes3vector3.new(0, 0, 205)
				basura = tes3.createReference{object="A_RZZ_basura", position=vector_pos, orientation=vector_orient, cell=cell}
				llamada = true
			else
				llamada = nil
				basura = tes3.getReference("A_RZZ_basura")
				if (basura) then basura:delete() end
			end
		else
			if (llamadaM == nil) then
				local cell = tes3.getPlayerCell()
				local vector_pos = tes3vector3.new(-346, 200, 25)
				local vector_orient = tes3vector3.new(0, 0, 205)
				maneken = tes3.createReference{
					object="A_RZZ_Maneken_f", 
					position=vector_pos, 
					orientation=vector_orient, 
					cell=cell,
					scale = 1
				}
				llamadaM = true
			else
				llamadaM = nil
				maneken = tes3.getReference("A_RZZ_Maneken_f")
				if (maneken) then maneken:delete() end
				isManeken = nil
				isCombat = nil
			end
		end
	end
	----------Вызов меню главного сундука----------
	if (string.find(e.target.object.id, "A_RZZ_chest_tomb_1")) then
		if (not RZZ_activate) then
			timer.delayOneFrame(function()
				if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
				MenuRZZ_1() --Открываем меню
			end)
			return false
		end
		RZZ_activate = nil
		isCombat = nil
	end
	----------Вызов меню призываемого сундука----------
	if (string.find(e.target.object.id, "A_RZZ_chest_tomb_2")) then
		if (not RZZ_activate) then
			timer.delayOneFrame(function()
				if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
				MenuRZZ_3() --Открываем меню
			end)
			return false
		end
		RZZ_activate = nil
	end
	----------Активация плагина----------
	if (e.target.object.id == "A_RZZ_text_note") then
		if (data.A_RZZ.LoadRZZ) then
			func.addRZZSpell()
			return
		end
		if (not data.A_RZZ.LoadRZZ) then
			tes3.messageBox{ message = i18n("main.modActivate") }
			func.addRZZSpell()
			--data.A_RZZ.Load = true
			data.A_RZZ.LoadRZZ = true
			tes3.addItem({ 
				reference = "A_RZZ_flora_gold", 
				item = "A_RZZ_goldensaint", 
				count = 2, 
				playSound = false
			})
			tes3.addItem({ 
				reference = "A_RZZ_flora_gold", 
				item = "A_RZZ_dagger_soultrap", 
				count = 2, 
				playSound = false
			})
			tes3.addItem({ 
				reference = "A_RZZ_flora_gold", 
				item = "Gold_001", 
				count = 22222, 
				playSound = false
			})
		end
	end
	----------Запрет активации декораций----------
	if (string.find(e.target.object.id, "[Mm]uestra")) then
		if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
		return false
	end
	----------Меню ингредиентов----------
	if (string.find(e.target.object.id, "A_RZZ_mumia_1")) then
		if (not RZZ_activate) then
			func.resetSort(e.target.object.id, "A_RZZ_crate_7")
			timer.delayOneFrame(function()
				if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
				MenuRZZ_4() --Открываем меню
			end)
			return false
		end
		RZZ_activate = nil
	end
	----------Меню зелий----------
	if (string.find(e.target.object.id, "A_RZZ_mumia_2")) then
		if (not RZZ_activate) then
			func.resetSort(e.target.object.id, "A_RZZ_crate_8")
			timer.delayOneFrame(function()
				if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
				MenuRZZ_5() --Открываем меню
			end)
			return false
		end
		RZZ_activate = nil
	end
	----------Меню свитков----------
	if (string.find(e.target.object.id, "A_RZZ_chest_small_3")) then
		if (not RZZ_activate) then
			func.resetSort(e.target.object.id, "A_RZZ_chest_small_3_tmp")
			timer.delayOneFrame(function()
				if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
				MenuRZZ_6() --Открываем меню
			end)
			return false
		end
		RZZ_activate = nil
	end
	----------Меню колец и амулетов----------
	if (string.find(e.target.object.id, "A_RZZ_chest_small_9")) then
		if (not RZZ_activate) then
			func.resetSort(e.target.object.id, "A_RZZ_chest_small_9_tmp")
			timer.delayOneFrame(function()
				if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
				MenuRZZ_7() --Открываем меню
			end)
			return false
		end
		RZZ_activate = nil
	end
	----------Меню редких предметов----------
	if (string.find(e.target.object.id, "A_RZZ_Button") or string.find(e.target.object.id, "A_RZZ_chest_small_12")) then
		if (not RZZ_activate) then
			func.resetSort("A_RZZ_chest_small_12", "A_RZZ_chest_s_12_tmp")
			if not string.find(e.target.object.id, "A_RZZ_chest_small_12") then
				timer.delayOneFrame(function()
					if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
					MenuRZZ_8() --Открываем меню
				end)
			else
				func.abrirRZZ("A_RZZ_chest_small_12")
			end
			return false
		end
		RZZ_activate = nil
	end
	----------Меню алхимических аппаратов----------
	if (string.find(e.target.object.id, "A_RZZ_barrel_1")) then
		if (not RZZ_activate) then
			func.resetSort(e.target.object.id, "A_RZZ_barrel_1_tmp")
			timer.delayOneFrame(function()
				if tes3ui.menuMode then tes3ui.leaveMenuMode() end --закрываем контейнер
				MenuRZZ_9() --Открываем меню
			end)
			return false
		end
		RZZ_activate = nil
	end
	----------Обновление цветочка----------
	--[[
	if (string.find(e.target.object.id, "A_RZZ_flora_gold")) then
		local flora_gold = tes3.getReference("A_RZZ_flora_gold")
		local count = tes3.getItemCount({ 
			reference = "A_RZZ_flora_gold",
			item = "A_RZZ_goldensaint"
		})
		tes3.messageBox{ message = "Count->" .. tostring(count) }
		if (count <= 0) then FloraTimeInicio() end
	end
	--]]
end
--[[
local function onUIObjectTooltip(e) --скрываем helpMenu
	if e.reference and string.find(e.reference.id,'[Mm]uestra') then
		e.tooltip.absolutePosAlignX = 4
		e.tooltip.absolutePosAlignY = 4
	else
		e.tooltip.absolutePosAlignX = nil
		e.tooltip.absolutePosAlignY = nil
	end
	--tes3.messageBox{ message = "ok_0->" .. e.reference.id }
end
--]]
local function saveCallback(e) --чистим локацию при сохранении
	local basura = tes3.getReference("A_RZZ_basura")
	local maneken = tes3.getReference("A_RZZ_Maneken_f")
	local tomb_rzz = tes3.getReference("A_RZZ_chest_tomb_2")
	
	if (basura) then basura:delete() end
	if (maneken) then maneken:delete() end
	if (tomb_rzz) then tomb_rzz:delete() end
	isCombat = nil
	isManeken = nil
	llamadaM = nil
	tes3.player.modified = true
	
	func.Maldicion()
	func.FloraTimeInicio()
	func.FloraTimeRenovacion()
	
	if (data.A_RZZ.LoadRZZ) then
		func.addRZZSpell()
	end
end

local function spellCastCallback(e) --запрет заклинания RZZ в тайнике
	local cell = tes3.getPlayerCell()
	if (i18n("main.cellName") == tostring(cell) or isCombat or is_maldito) then
		if (e.source.id == "A_RZZ_Enter") then
			tes3.removeEffects({ reference = tes3.player, castType = 0, removeSpell = false })
			msg = i18n("main.isCellRZZ")
			if (isCombat) then msg = i18n("main.isCombat") end
			if (is_maldito) then msg = i18n("main.is_maldito") end
			tes3.messageBox{ message = msg }
		end
		if (e.source.id == "recall" or e.source.id == "A_RMS_Recall" or e.source.id == "A_RMS_ReturnSpell") then
			for i, stack in pairs(tes3.player.object.inventory) do
				if (stack.object) then
					if string.find(stack.object.id,'A_RZZ_dagger_soultrap') then
						tes3.transferItem{from=tes3.player, to="A_RZZ_chest_tomb_1", item=stack.object, count=stack.count, playSound=false}
						goto continue
					end
					if string.find(stack.object.id,'A_RZZ_goldensaint') then
						tes3.transferItem{from=tes3.player, to="A_RZZ_chest_tomb_1", item=stack.object, count=stack.count, playSound=false}
						goto continue
					end
					::continue::
				end
			end
		end
	else
		if (e.source.id == "A_RZZ_Enter") then
			tes3.removeEffects({ reference = tes3.player, castType = 0, removeSpell = false })
			MenuRZZ_2()
		end
	end
end

local function loadedCallback(e)
	data = tes3.player.data
	data.A_RZZ = data.A_RZZ or {}
	tes3.player.modified = true
	if (data.A_RZZ.LoadRZZ) then
		func.addRZZSpell()
	end
end

local function combatStartedCallback(e)
	isCombat = true
end

local function combatStoppedCallback(e)
	isCombat = nil
end
--[[
local function menuEnterCallback(e)
	tes3.messageBox{ message = "ok_0." .. e.menu.name }
end
--]]
local function ManekenMod(e)
	local cell = tes3.getPlayerCell()
	if( e.pressed and e.isShiftDown ) then
		if (i18n("main.cellName") == tostring(cell)) then
			if (not isManeken) then
				isManeken = true
				tes3.messageBox{ message = i18n("main.activManOn") }
				is_amulet_combat = nil
			else
				isManeken = nil
				tes3.messageBox{ message = i18n("main.activManOff") }
			end
		end
	end
end

local function cellActivatedCallback(e)--Вкл./откл. увеличенную магию
	if not data then
		data = tes3.player.data
		data.A_RZZ = data.A_RZZ or {}
		tes3.player.modified = true
	end
	if i18n("main.cellName") == tostring(e.cell) then
		--tes3.messageBox{ message = "test" .. tostring(e.cell) }
		if not isMagPlus then func.MagPlus(true) end
		func.FloraTimeRenovacion()
	else
		if isMagPlus then func.MagPlus(false) end
	end
end

local function equippedCallback(e)
	--tes3.messageBox{ message = "test_1->" .. tostring(e.item.id) }
	if e.item.id == "A_RZZ_dagger_soultrap" then --Вкл. магический эффект ритуального клинка
		local isAffectedBy = tes3.isAffectedBy({ reference = tes3.player, object = "A_RZZ_Ritual" })
		if not isAffectedBy then
			tes3.addSpell({ reference = tes3.player, spell = "A_RZZ_Ritual" })
		end
	end
end

local function unequippedCallback(e)--Откл. магический эффект ритуального клинка
	--tes3.messageBox{ message = "test_2->" .. tostring(e.item.id) }
	if e.item.id == "A_RZZ_dagger_soultrap" then
		timer.delayOneFrame(function()
			local isAffectedBy = tes3.isAffectedBy({ reference = tes3.player, object = "A_RZZ_Ritual" })
			if isAffectedBy then
				tes3.removeSpell({ reference = tes3.player, spell = "A_RZZ_Ritual" })
			end
		end)
	end
end

local function damageCallback(e)--Подстраховка жизни в тренеровочном бою
	--tes3.messageBox{ message = "damage->" .. tostring(e.damage) .. "health->" .. tostring(e.mobile.health.current)}
	--tes3.messageBox{ message = "Atack->" .. tostring(e.attackerReference) .. "health->" .. tostring(e.attacker.health.current)}
	--tes3.messageBox{ message = "damage->" .. tostring(e.damage)}
	--tes3.messageBox{ message = "magic->" .. tostring(e.activeMagicEffect)}
	--tes3.messageBox{ message = "mobile0->" .. tostring(e.mobile.reference.id)}
	--if string.find(e.mobile.reference.id, 'A_RZZ_Maneken_f') then--A_RZZ_Maneken_f
		--tes3.messageBox{ message = "mobile1->" .. tostring(e.mobile.reference)}
		--tes3.messageBox{ message = "damage->" .. tostring(e.damage) .. "fatigue->" .. tostring(e.mobile.fatigue.current)}
	--end
	local cell = tes3.getPlayerCell()
	if i18n("main.cellName") == tostring(cell) and e.mobile and e.attackerReference then
		if is_amulet_combat == "start" then
			--отслеживание урона наносимого игроку
			if (e.damage > e.mobile.health.current or e.mobile.health.current <= 30) and string.find(tostring(e.mobile.reference.id), 'Player') then
				
				e.damage = 0 --e.mobile.health.current - 20
				e.mobile.health.current = 20
				
				tes3.messageBox{ message = i18n("main.finCombat_1")}
				e.attacker:stopCombat(true)
				for i, stack in pairs(e.attacker.object.inventory) do
					if (stack.object) then
						if (stack.object.objectType == tes3.objectType.weapon) then
							mwscript.removeItem{reference=e.attackerReference, item=stack.object.id, count=stack.count}
						end
						if string.find(stack.object.id,'A_RZZ_amulet of war') then
							mwscript.removeItem{reference=e.attackerReference, item='A_RZZ_amulet of war', count=stack.count}
						end
					end
				end
				
				local isAffectedBy = tes3.isAffectedBy({ reference = tes3.player, object = "A_RZZ_Restore" })
					
				if not isAffectedBy then--наложение заклинания восстановления
					tes3.cast({ 
						reference = e.attackerReference,
						target = tes3.player,
						spell = "A_RZZ_Restore_2", 
						instant = true 
					})
					tes3.cast({ 
						reference = e.attackerReference,
						target = e.attackerReference,
						spell = "A_RZZ_Restore", 
						instant = true 
					})
					is_amulet_combat = nil
				end
			end
			---[[отслеживание урона возвращаемого игроку
			if e.attacker.health.current <= 45 and string.find(tostring(e.attackerReference), 'Player') and maneken then
				
				e.damage = 0
				tes3.messageBox{ message = i18n("main.finCombat_2")}
				mwscript.stopCombat({ reference=maneken.object.id, target=tes3.player })--maneken:stopCombat(true)
				for i, stack in pairs(maneken.object.inventory) do
					if (stack.object) then
						if (stack.object.objectType == tes3.objectType.weapon) then
							mwscript.removeItem{reference=maneken.object.id, item=stack.object.id, count=stack.count}
						end
						if string.find(stack.object.id,'A_RZZ_amulet of war') then
							mwscript.removeItem{reference=maneken.object.id, item='A_RZZ_amulet of war', count=stack.count}
						end
					end
				end
				
				local isAffectedBy = tes3.isAffectedBy({ reference = e.attackerReference, object = "A_RZZ_Restore" })
					
				if not isAffectedBy then--наложение заклинания восстановления
					tes3.cast({ 
						reference = e.attackerReference,
						target = tes3.player,
						spell = "A_RZZ_Restore_2", 
						instant = true 
					})
					tes3.cast({ 
						reference = e.attackerReference,
						target = maneken,
						spell = "A_RZZ_Restore", 
						instant = true 
					})
					is_amulet_combat = nil
				end
			end--]]
			---[[отслеживание урона наносимого манекену
			if (e.damage > e.mobile.health.current or e.mobile.health.current <= 150) and string.find(tostring(e.mobile.reference.id), 'A_RZZ_Maneken_f') then
				
				e.damage = 0
				
				tes3.messageBox{ message = i18n("main.finCombat_3")}
				e.mobile:stopCombat(true)
				e.mobile.fatigue.current = 400
				for i, stack in pairs(e.mobile.object.inventory) do
					if (stack.object) then
						if (stack.object.objectType == tes3.objectType.weapon) then
							mwscript.removeItem{reference=e.mobile.reference.id, item=stack.object.id, count=stack.count}
						end
						if string.find(stack.object.id,'A_RZZ_amulet of war') then
							mwscript.removeItem{reference=e.mobile.reference.id, item='A_RZZ_amulet of war', count=stack.count}
						end
					end
				end
				
				local isAffectedBy = tes3.isAffectedBy({ reference = e.mobile.reference.id, object = "A_RZZ_Restore" })
					
				if not isAffectedBy then--наложение заклинания восстановления
					tes3.cast({ 
						reference = e.mobile.reference.id,
						target = e.mobile.reference.id,
						spell = "A_RZZ_Restore", 
						instant = true 
					})
					tes3.cast({ 
						reference = e.mobile.reference.id,
						target = tes3.player,
						spell = "A_RZZ_Restore_2", 
						instant = true 
					})
					is_amulet_combat = nil
				end
			end--]]
			---[[отслеживание урона возвращаемого манекену
			if e.attacker.health.current <= 150 and string.find(tostring(e.attackerReference), 'A_RZZ_Maneken_f') then
				
				tes3.messageBox{ message = i18n("main.finCombat_4")}
				e.attacker:stopCombat(true)
				for i, stack in pairs(e.attacker.object.inventory) do
					if (stack.object) then
						if (stack.object.objectType == tes3.objectType.weapon) then
							mwscript.removeItem{reference=e.attackerReference, item=stack.object.id, count=stack.count}
						end
						if string.find(stack.object.id,'A_RZZ_amulet of war') then
							mwscript.removeItem{reference=e.attackerReference, item='A_RZZ_amulet of war', count=stack.count}
						end
					end
				end
				
				local isAffectedBy = tes3.isAffectedBy({ reference = e.attackerReference, object = "A_RZZ_Restore" })
					
				if not isAffectedBy then--наложение заклинания восстановления
					tes3.cast({ 
						reference = e.attackerReference,
						target = e.attackerReference,
						spell = "A_RZZ_Restore", 
						instant = true 
					})
					tes3.cast({ 
						reference = e.attackerReference,
						target = tes3.player,
						spell = "A_RZZ_Restore_2", 
						instant = true 
					})
					is_amulet_combat = nil
				end
			end--]]
		end
		if (not is_amulet_combat or is_amulet_combat == "stop") then
			---[[отслеживание урона наносимого манекену вне боя
			if (e.damage > e.mobile.health.current or e.mobile.health.current <= 150) and string.find(tostring(e.mobile.reference.id), 'A_RZZ_Maneken_f') then
				e.damage = 0
				e.mobile:stopCombat(true)
				e.mobile.fatigue.current = 3000
				e.mobile.health.current = 1095
			end--]]
		end
	end
end

local function attackHitCallback(e)
	if e.targetMobile then
		local cell = tes3.getPlayerCell()
		if i18n("main.cellName") == tostring(cell) then
			if (not is_amulet_combat or is_amulet_combat == "stop") and maneken then
				is_amulet_combat = "stop"
				for i, stack in pairs(maneken.object.inventory) do
					if (stack.object) then
						if string.find(stack.object.id,'A_RZZ_amulet') then --провека на наличие амулета
							is_amulet_combat = "start"
							--tes3.messageBox{ message = "Амулет добавлен" }
							break
						end
					end
				end
			--end
				--tes3.messageBox{ message = "isCombat->" .. tostring(is_amulet_combat) .. ", fatigue->" .. tostring(e.targetMobile.fatigue.current)}
				--tes3.messageBox{ message = "isCombat->" .. tostring(is_amulet_combat) .. ", health->" .. tostring(e.targetMobile.health.current)}
				if (not is_amulet_combat or is_amulet_combat == "stop") and string.find(tostring(e.targetMobile.reference.id), 'A_RZZ_Maneken_f') then
					if (e.targetMobile.health.current <= 150) then
						e.targetMobile.health.current = 1095
					end
					if (e.targetMobile.fatigue.current <= 1000) then
						e.targetMobile.fatigue.current = 3000
					end
				end
			end
		end
	end
end

--[[
local function Traductor()
	--tes3.messageBox(i18n("rzztest") .. tostring(tes3.objectType.clothing))
end
--]]
local function registerModConfig()--Добавляем конфиг
	local config = require("rzz_cwa.mcm")
	mwse.registerModConfig(i18n("mcm.title"), config)
end
event.register("modConfigReady", registerModConfig)

local function onInitialized()
	--event.register("keyDown", MenuRZZ_4, {filter = 44}) -- z
	--event.register("keyDown", onCastMark, {filter = 16}) -- q
	event.register("activate", eActivate)
	--event.register("uiObjectTooltip", onUIObjectTooltip)
	event.register("save", saveCallback)
	event.register("spellCast", spellCastCallback)
	event.register("loaded", loadedCallback)
	event.register("combatStarted", combatStartedCallback)
	event.register("combatStopped", combatStoppedCallback)
	--event.register("menuEnter", menuEnterCallback)
	event.register("keyDown", ManekenMod, {filter = tes3.scanCode.f}) -- f
	--event.register("keyDown", ManekenStop, {filter = 57}) -- space
	event.register("cellActivated", cellActivatedCallback)
	event.register("equipped", equippedCallback)
	event.register("unequipped", unequippedCallback)
	event.register("damage", damageCallback)
	event.register("attackHit", attackHitCallback)
	--event.register("keyDown", Traductor, {filter = tes3.scanCode.z}) -- z
end
event.register("initialized", onInitialized)
mwse.log("[RZZ] Loaded successfully. " .. string.format("Version: %.1f",RZZ_Version))
