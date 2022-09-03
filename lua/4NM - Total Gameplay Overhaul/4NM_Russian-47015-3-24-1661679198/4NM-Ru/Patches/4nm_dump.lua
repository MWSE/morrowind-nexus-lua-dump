local cf = mwse.loadConfig("4NM", {en = true, m = false, m1 = false, m2 = false, m30 = false, m3 = false, m4 = false, m5 = false, m6 = false, m7 = false, m8 = false, m9 = false, m10 = false, m11 = false,
scroll = true, lab = true, spmak = true, lin = 15, UIsp = false, UIen = false, UIcol = 0, fatbar = true,
full = true, pmult = 1, min = 80, max = 120, skillp = true, levmod = true, trmod = true, expfat = 3, enchlim = true, durlim = true, alc = true, barter = true, stels = true, Spd = true, hit = true, traum = true,
pvp = true, pvp1 = true, par = true, nosave = true, Proj = true, spellhit = true, aspell = true, ammofix = false, AIsec = 2,
dash = 100, charglim = 100, moment = 100, metlim = 100, mshmax = 100, rfmax = 100, col = 100, crit = 30, upgm = false, agr = true, smartcw = true, autoammo = true, mcs = true, maniac = false,
autoshield = true, smartpoi = true, raycon = true, metret = true, mbkik = 3, mbdod = 4, mbret = 4, mbhev = 2, mbmet = 3, mbcharg = 2, mbray = 4, mbsum = 4, mbshot = 2, mbarc = 2,
autoarb = false, autokik = true, autocharg = false, ray = true,
kikkey = {keyCode = 28}, pkey = {keyCode = 60}, ekey = {keyCode = 42}, dwmkey = {keyCode = 29}, gripkey = {keyCode = 56},
magkey = {keyCode = 157}, tpkey = {keyCode = 54}, cpkey = {keyCode = 207}, telkey = {keyCode = 209}, cwkey = {keyCode = 211},
poisonkey = {keyCode = 25}, parkey = {keyCode = 38}, totkey = {keyCode = 44}, bwkey = {keyCode = 45}, reflkey = {keyCode = 46}, detkey = {keyCode = 47}, markkey = {keyCode = 48},
q1 = {keyCode = 79}, q2 = {keyCode = 80}, q3 = {keyCode = 81}, q4 = {keyCode = 75}, q5 = {keyCode = 76}, q6 = {keyCode = 77}, q7 = {keyCode = 71}, q8 = {keyCode = 72}, q9 = {keyCode = 73}, q0 = {keyCode = 156}})

local p, mp, inv, p1, p3, ad, pp, D, P, DM, MB, AC, mc, rf, n, md, pow, wc, ic, crot, QS		local MT = {__index = function(t, k) t[k] = {} return t[k] end}		local AF = setmetatable({}, MT)		local FR = {}
--local SS = setmetatable({}, MT)		local BSS = setmetatable({}, MT)		local SSN = {}
local M = {}	local B = {}	local S = {}	local SN = {}	local SNC = {}		local Matr = tes3matrix33.new()		local W = {}	local N = {}	local MP = {}		local DOM = {}
local V = {up = tes3vector3.new(0,0,1), down = tes3vector3.new(0,0,-1), nul = tes3vector3.new(0,0,0)}	local KSR = {}	local PRR = {}		local R = {}	local G = {cpg = 0}		
local com, last, pred, arm, arp		local A = {}		local ID33 = tes3matrix33.new(1,0,0,0,1,0,0,0,1)
local CPR = {}		local CPRS = {}		local CPS = {0,0,0,0,0,0,0,0,0,0}
local AT = {[0] = {t="l",s=21,p="lig0",snd="Light Armor Hit"}, [1] = {t="m",s=2,p="med0",snd="Medium Armor Hit"}, [2] = {t="h",s=3,p="hev0",snd="Heavy Armor Hit"}, [3] = {t="u",s=17}}
local WT = {[-1]={s=26,p1="hand1",p2="hand2",p3="hand3",p4="hand4",p5="hand5",p6="hand6",p8="hand8",pc="hand12"},
[0]={s=22,p1="short1",p2="short2",p3="short3",p4="short4",p5="short5",p6="short6",p7="short7",p8="short8",p9="short9",p="short0",pc="short13",h1=true,dw=true,pso=1},
[1]={s=5,p1="long1a",p2="long2a",p3="long3a",p4="long4a",p5="long5a",p6="long6a",p7="long7a",p8="long8a",p9="long9a",p="long0",pc="long9",h1=true,dw=true,pso=1},
[2]={s=5,p1="long1b",p2="long2b",p3="long3b",p4="long4b",p5="long5b",p6="long6b",p7="long7b",p8="long8b",p9="long9b",p="long0",pso=1},
[3]={s=4,p1="blu1a",p2="blu2a",p3="blu3a",p4="blu4a",p5="blu5a",p6="blu6a",p7="blu7a",p8="blu8a",p9="blu9a",p="blu0a",h1=true,dw=true,pso=3},
[4]={s=4,p1="blu1b",p2="blu2b",p3="blu3b",p4="blu4b",p5="blu5b",p6="blu6b",p7="blu7b",p8="blu8b",p9="blu9b",p="blu0a",pso=3},
[5]= {s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",pso=3},
[-3]={s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",h1=true,dw=true,pso=3},
[6]={s=7,p1="spear1",p2="spear2",p3="spear3",p4="spear4",p5="spear5",p6="spear6",p7="spear7",p8="spear8",p9="spear9",p="spear0",pso=2},
[-2]={s=7,p1="spear1a",p2="spear2a",p3="spear3a",p4="spear4a",p5="spear5a",p6="spear6a",p7="spear7a",p8="spear8a",p9="spear9a",p="spear0",h1=true,dw=true,pso=2},
[7]={s=6,p1="axe1a",p2="axe2a",p3="axe3a",p4="axe4a",p5="axe5a",p6="axe6a",p7="axe7a",p8="axe8a",p9="axe9a",p="axe0",h1=true,dw=true,pso=2},
[8]={s=6,p1="axe1b",p2="axe2b",p3="axe3b",p4="axe4b",p5="axe5b",p6="axe6b",p7="axe7b",p8="axe8b",p9="axe9b",p="axe0",pso=2},
[9]={s=23,p1="mark1a",p2="mark2a",p3="mark3a",p4="mark4a",p5="mark5a",p6="mark6a",p="mark0a"},
[10]={s=23,p1="mark1b",p2="mark2b",p3="mark3b",p4="mark4b",p5="mark5b",p6="mark6b",p="mark0b"},
[11]={s=23,p1="mark1c",p2="mark2c",p3="mark3c",p4="mark4c",p5="mark5c",p6="mark6c",p="mark0c",h1=true}}

local T = {T1 = timer, Fire = timer, Frost = timer, Shock = timer, Poison = timer, Vital = timer, Heal = timer, AUR = timer, DC = timer, Ray = timer, TS = timer, DET = timer, PCT = timer, MCT = timer, QST = timer, LEG = timer,
LI = timer, Dash = timer, Dod = timer, Kik = timer, CT = timer, CST = timer, Shield = timer, Comb = timer, DWB = timer, POT = timer, Run = timer, AoE = timer, Tot = timer, WaterB = timer, Arb = timer, Met = timer, Dom = timer}
local L = {ATR = {[0] = "strength", [1] = "intelligence", [2] = "willpower", [3] = "agility", [4] = "speed", [5] = "endurance", [6] = "personality", [7] = "luck"},
ATRIC = {[0] = "icons/k/attribute_strength.dds", [1] = "icons/k/attribute_int.dds", [2] = "icons/k/attribute_wilpower.dds", [3] = "icons/k/attribute_agility.dds", [4] = "icons/k/attribute_speed.dds",
[5] = "icons/k/attribute_endurance.dds", [6] = "icons/k/attribute_personality.dds", [7] = "icons/k/attribute_luck.dds"},
S = {"armorer", "mediumArmor", "heavyArmor", "bluntWeapon", "longBlade", "axe", "spear", "athletics", "enchant", "destruction", "alteration", "illusion", "conjuration", "mysticism", "restoration",
"alchemy", "unarmored", "security", "sneak", "acrobatics", "lightArmor", "shortBlade", "marksman", "mercantile", "speechcraft", "handToHand", [0] = "block"},
SK = {[4] = "skw", [5] = "skw", [6] = "skw", [7] = "skw", [22] = "skw", [23] = "skw", [26] = "skw", [0] = "skarm", [2] = "skarm", [3] = "skarm", [17] = "skarm", [21] = "skarm", [18] = "sksec",
[9] = "skmag", [10] = "skmag", [11] = "skmag", [12] = "skmag", [13] = "skmag", [14] = "skmag", [15] = "skmag"}, skmag = 1, skw = 1, skarm = 1, sksec = 1,
BS = {["Wombburned"] = "atronach", ["Fay"] = "mage", ["Beggar's Nose"] = "tower", ["Blessed Touch Sign"] = "ritual", ["Charioteer"] = "steed", ["Elfborn"] = "apprentice", ["Hara"] = "thief",
["Lady's Favor"] = "lady", ["Mooncalf"] = "lover", ["Moonshadow Sign"] = "shadow", ["Star-Cursed"] = "serpent", ["Trollkin"] = "lord", ["Warwyrd"] = "warrior"},
SA = {0,5,5,0,0,0,3,5,2,2,1,1,2,1,2,1,4,3,3,3,4,4,3,6,6,4,[0]=3}, SA2 = {3,3,0,5,3,5,0,4,1,1,2,2,1,2,1,3,2,1,4,4,3,3,0,1,1,0,[0]=5}, SS = {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,[0]=0},
RHP = {Orc = 20, Nord = 20, Argonian = 20, Imperial = 10, Redguard = 10},
PRL = {{"strength", "icons/k/attribute_strength.dds", 0}, {"endurance", "icons/k/attribute_endurance.dds", 5}, {"speed", "icons/k/attribute_speed.dds", 4}, {"agility", "icons/k/attribute_agility.dds", 3}, {"intelligence", "icons/k/attribute_int.dds", 1},
{"willpower", "icons/k/attribute_wilpower.dds", 2}, {"personality", "icons/k/attribute_personality.dds", 6}, {"luck", "icons/k/attribute_luck.dds", 7}, {"longBlade", "icons/k/combat_longblade.dds", 5}, {"axe", "icons/k/combat_axe.dds", 6},
{"bluntWeapon", "icons/k/combat_blunt.dds", 4}, {"spear", "icons/k/combat_spear.dds", 7}, {"mediumArmor", "icons/k/combat_mediumarmor.dds", 2}, {"heavyArmor", "icons/k/combat_heavyarmor.dds", 3}, {"block", "icons/k/combat_block.dds", 0},
{"athletics", "icons/k/combat_athletics.dds", 8}, {"armorer", "icons/k/combat_armor.dds", 1}, {"destruction", "icons/k/magic_destruction.dds", 10}, {"alteration", "icons/k/magic_alteration.dds", 11}, {"mysticism", "icons/k/magic_mysticism.dds", 14},
{"restoration", "icons/k/magic_restoration.dds", 15}, {"illusion", "icons/k/magic_illusion.dds", 12}, {"conjuration", "icons/k/magic_conjuration.dds", 13}, {"enchant", "icons/k/magic_enchant.dds", 9}, {"alchemy","icons/k/magic_alchemy.dds", 16},
{"unarmored", "icons/k/magic_unarmored.dds", 17}, {"shortBlade", "icons/k/stealth_shortblade.dds", 22}, {"marksman", "icons/k/stealth_marksman.dds", 23}, {"handToHand", "icons/k/stealth_handtohand.dds", 26}, {"lightArmor", "icons/k/stealth_lightarmor.dds", 21},
{"acrobatics", "icons/k/stealth_acrobatics.dds", 20}, {"sneak", "icons/k/stealth_sneak.dds", 19}, {"security", "icons/k/stealth_security.dds", 18}, {"mercantile", "icons/k/stealth_mercantile.dds", 24}, {"speechcraft", "icons/k/stealth_speechcraft.dds", 25}},




NSU = {["4as_atr4"] = {en = "Elemental triumvirate", ru = "Стихийный триумвират", c = 10, f = 4, d = 10, m = 10, ma = 20, {556}, {557}, {558}},
["4as_atr5"] = {en = "Elemental charge", ru = "Стихийный заряд", c = 20, d = 30, m = 8, ma = 12, {511}, {512}, {513}},
["4as_atr6"] = {en = "Elemental explode", ru = "Стихийный взрыв", c = 20, d = 30, m = 8, ma = 12, {531}, {532}, {533}},
["4as_atr7"] = {en = "Elemental spread", ru = "Стихийная шквал", c = 30, rt = 1, d = 1, m = 8, ma = 12, r = 5, {536}, {537}, {538}},
["4as_atr8"] = {en = "Elemental ray", ru = "Стихийный луч", c = 30, rt = 1, d = 1, m = 0, ma = 10, r = 3, {546}, {547}, {548}},
["4as_atr9"] = {en = "Elemental wave", ru = "Стихийная волна", c = 50, rt = 2, d = 1, m = 10, ma = 20, r = 20, {566}, {567}, {568}},
["4as_atr10"] = {en = "Elemental discharge", ru = "Стихийный разряд", c = 50, rt = 1, d = 1, m = 40, ma = 60, r = 15, {541}, {542}, {543}}},
PA = {atb1={117,5,"long01","Мастер меча","Sword master"}, atb2={117,5,"axe01","Мастер топора","Ax master"}, atb3={117,5,"blu01","Мастер булавы","Mace master"}, atb4={117,5,"spear01","Мастер копья","Spear master"},
atb5={117,5,"short01","Мастер ножа","Knife master"}, atb6={117,5,"mark01","Мастер стрельбы","Shooting master"}, atb7={117,5,"hand01","Мастер кулака","Fist master"}, atb8={117,5,"spd01","Быстрая атака","Fast attack"},
atb9={117,5,"agi01","Ловкая атака","Dexterous attack"}, atb10={117,5,"luc01","Удачная атака","Lucky attack"},
san1 = {42,5,"una01","Мастер без брони","Master without armor"}, san2 = {42,5,"lig01","Легкое уклонение","Easy evasion"}, san3 = {42,5,"bloc01","Парирование","Parry"}, san4 = {42,5,"short02","Воровской уворот","Thief evasion"}, 
san5 = {42,5,"hand02","Отклонение атак","Deflecting attacks"}, san6 = {42,5,"acr01","Боевая акробатика","Combat acrobatics"}, san7 = {42,5,"sec01","Чувство опасности","Sense of danger"},
san8 = {42,5,"spd02","Быстрое уклонение","Fast evasion"}, san9 = {42,5,"agi02","Ловкое уклонение","Dexterous evasion"}, san10 = {42,5,"luc02","Удачное уклонение","Lucky evasion"},
mag1 = {84,1,"res04","Мастер Восстановления","Master of Restoration"}, mag2 = {84,1,"des04","Мастер Разрушения","Master of Destruction"}, mag3 = {84,1,"alt04","Мастер Изменения","Master of Alteration"},
mag4 = {84,1,"ill04","Мастер Иллюзий","Illusion master"}, mag5 = {84,1,"con04","Мастер Колдовства","Master of Conjuration"}, mag6 = {84,1,"mys04","Мастер Мистицизма","Master of Mysticism"},
mag7 = {84,1,"enc01","Душа мага","Magician soul"}, mag8 = {84,1,"una02","Чистый разум","Clear mind"}, mag9 = {84,1,"int01","Разум мага","Magician mind"}, mag10 = {84,1,"wil01","Дух мага","Magician spirit"}, 
fea1 = {8,20,"med01","Привыкание к нагрузке","Addictive to encumrance"}, fea2 = {8,20,"hev01","Привыкание к перегрузке","Addictive to overload"}, fea3 = {8,20,"atl01","Тренированные мышцы","Trained muscles"},
fea4 = {8,20,"str01","Мул","Mule"}, fea5 = {8,20,"end01","Крепкий хребет","Strong ridge"},
stam1 = {77,2,"med02","Привыкание к доспехам","Addictive to armor"}, stam2 = {77,2,"hev02","Привыкание к броне","Addictive to heavy armor"}, stam3 = {77,2,"atl02","Тренировка дыхания","Breathing training"},
stam4 = {77,2,"str02","Сильные мышцы","Strong muscles"}, stam5 = {77,2,"end02","Источник сил","Source of strength"}, stam6 = {77,2,"axe02","Сила топорщика","Power of axeman"}, stam7 = {77,2,"blu02","Сила дубинщика","Power of clubman"},
stam8 = {77,2,"spear02","Сила копейщика","Power of spearman"}, stam9 = {77,2,"hand03","Сила бойца","Power of fighter"}, stam10 = {77,2,"arm01","Сила кузнеца","Power of blacksmith"},
mpr1 = {76,0,"mys05","Глубокая медитация","Deep meditation",m=1}, mpr2 = {76,0,"enc02","Душевная медитация","Soul meditation",m=1},
mpr3 = {76,0,"int02","Осознанная медитация","Mindful meditation",m=1}, mpr4 = {76,0,"wil02","Духовная медитация","Spiritual meditation",m=1},
hpr1 = {75,0,"res05","Бессмертие","Immortality",m=1}, hpr2 = {75,0,"end03","Источник жизни","Life source",m=1},
abs1 = {67,5,"alt05","Энерготрансформатор","Energy transformer"}, abs2 = {67,5,"mys06","Энергоабсорбатор","Energy absorber"}, ref1 = {68,5,"mys07","Энергореверсор","Energy reverser"},
dete = {65,100,"enc03","Магическое чутье","Magical sense"}, deta = {64,100,"sec03","Воровское чутье","Thief's instinct"}, detk = {66,100,"sec02","Жадность","Greed"}, nig = {43,20,"mark02","Глаз-алмаз","Diamond eye"}},
AA = {["4a_long"] = {p = "long00", s = 5}, ["4a_short"] = {p = "short00", s = 22}, ["4a_axe"] = {p = "axe00", s = 6}, ["4a_blu"] = {p = "blu00", s = 4}, ["4a_spear"] = {p = "spear00", s = 7}, ["4a_mark"] = {p = "mark00", s = 23},
["4a_hand"] = {p = "hand00", s = 26}, ["4a_lig"] = {p = "lig00", s = 21}, ["4a_med"] = {p = "med00", s = 2}, ["4a_hev"] = {p = "hev00", s = 3}, ["4a_una"] = {p = "una00", s = 17}, ["4a_bloc"] = {p = "bloc00", s = 0}, 
["4a_acr"] = {p = "acr00", s = 20}, ["4a_atl"] = {p = "atl00", s = 8}, ["4a_arm"] = {p = "arm00", s = 1}, ["4a_enc"] = {p = "enc00", s = 9}, ["4a_alc"] = {p = "alc00", s = 16}, ["4a_snek"] = {p = "snek00", s = 19},
["4a_sec"] = {p = "sec00", s = 18}, ["4a_spec"] = {p = "spec00", s = 25}, ["4a_merc"] = {p = "merc00", s = 24},
["4a_des1"] = {p = "des01"}, ["4a_des2"] = {p = "des02"}, ["4a_des3"] = {p = "des03"}, ["4a_alt1"] = {p = "alt01"}, ["4a_alt2"] = {p = "alt02"}, ["4a_alt3"] = {p = "alt03"},
["4a_res1"] = {p = "res01"}, ["4a_res2"] = {p = "res02"}, ["4a_res3"] = {p = "res03"}, ["4a_mys1"] = {p = "mys01", s = 14}, ["4a_mys2"] = {p = "mys02"}, ["4a_mys3"] = {p = "mys03"},
["4a_ill1"] = {p = "ill01"}, ["4a_ill2"] = {p = "ill02"}, ["4a_ill3"] = {p = "ill03", s = 12}, ["4a_con1"] = {p = "con01"}, ["4a_con2"] = {p = "con02", s = 13}, ["4a_con3"] = {p = "con03", s = 13},
["4a_str"] = {p = "str00"}, ["4a_end"] = {p = "end00"}, ["4a_agi"] = {p = "agi00"}, ["4a_spd"] = {p = "spd00"}, ["4a_int"] = {p = "int00"}, ["4a_wil"] = {p = "wil00"}, ["4a_per"] = {p = "per00"}},
STAR = {["4as_atr4"]=true,["4nm_star_apprentice1a"]=true,["4nm_star_lady1a"]=true, ["4nm_star_lord1a"]=true, ["4nm_star_lover1a"]=true, ["4nm_star_mage1a"]=true, ["4nm_star_steed1a"]=true, ["4nm_star_thief1a"]=true,
["4nm_star_warrior1a"]=true, ["4nm_star_ritual1a"]=true, ["4nm_star_ritual2a"]=true, ["4nm_star_ritual3a"]=true, ["4nm_star_serpent3a"]=true, ["4nm_star_shadow1a"]=true, ["4nm_star_shadow2a"]=true, ["4nm_star_shadow3a"]=true},
NEWSP = {{600,0,600,10,20,0,10,10,"Dash"},	{500,2,500,0,0,0,0,10,"Teleport"},
{501,0,501,5,10,0,5,30,"Recharge"},			{502,0,502,10,20,0,5,30,"Repair weapon"},	{503,0,503,20,30,0,5,30,"Repair armor"},		{504,2,504,8,12,0,60,5,"Lantern"},			{505,0,505,0,0,0,0,100,"Town teleport"},
{506,0,506,0,0,0,60,5,"Magic control"},		{507,0,507,5,10,0,30,20,"Reflect spells"},	{508,0,508,5,10,0,30,20,"Kinetic shield"},		{509,0,509,20,30,0,20,20,"Life leech"},		{510,0,510,20,30,0,10,20,"Time shift"},
{601,0,601,0,0,0,60,5,"Bound ammo"},		{602,2,602,20,30,20,0,10,"Kinetic strike"},	{603,0,603,0,0,0,60,30,"Bound weapon"},			{"504a",0,504,8,12,0,60,5,"Lantern (smart)"},
{511,0,511,8,12,0,30,10,"Charge fire"},		{512,0,512,8,12,0,30,10,"Charge frost"},	{513,0,513,8,12,0,30,10,"Charge lightning"},	{514,0,514,8,12,0,30,10,"Charge poison"},	{515,0,515,8,12,0,30,10,"Charge chaos"},
{516,0,516,8,12,0,30,10,"Aura fire"},		{517,0,517,8,12,0,30,10,"Aura frost"},		{518,0,518,8,12,0,30,10,"Aura lightning"},		{519,0,519,8,12,0,30,10,"Aura poison"},		{520,0,520,8,12,0,30,10,"Aura chaos"},
{521,2,521,8,12,20,10,30,"AoE fire"},		{522,2,522,8,12,20,10,30,"AoE frost"},		{523,2,523,8,12,20,10,40,"AoE lightning"},		{524,2,524,8,12,20,10,50,"AoE poison"},		{525,2,525,8,12,20,10,40,"AoE chaos"},
{526,2,526,40,60,15,1,15,"Rune fire"},		{527,2,527,40,60,15,1,15,"Rune frost"},		{528,2,528,40,60,15,1,20,"Rune lightning"},		{529,2,529,40,60,15,1,25,"Rune poison"},	{530,2,530,40,60,15,1,20,"Rune chaos"},
{531,0,531,8,12,0,30,10,"Explode fire"},	{532,0,532,8,12,0,30,10,"Explode frost"},	{533,0,533,8,12,0,30,10,"Explode lightning"},	{534,0,534,8,12,0,30,10,"Explode poison"},	{535,0,535,8,12,0,30,10,"Explode chaos"},
{536,1,536,10,30,10,1,30,"Spread fire"},	{537,1,537,10,30,10,1,30,"Spread frost"},	{538,1,538,10,30,10,1,40,"Spread lightning"},	{539,1,539,10,30,10,1,50,"Spread poison"},	{540,1,540,10,30,10,1,40,"Spread chaos"},
{541,1,541,50,100,15,1,30,"Discharge fire"},{542,1,542,50,100,15,1,30,"Discharge frost"}, {543,1,543,50,100,15,1,40,"Discharge lightning"}, {544,1,544,50,100,15,1,50,"Discharge poison"},{545,1,545,50,100,15,1,40,"Discharge chaos"},
{546,1,546,3,10,3,1,15,"Ray fire"},			{547,1,547,3,10,3,1,15,"Ray frost"},		{548,1,548,3,10,3,1,20,"Ray lightning"},		{549,1,549,3,10,3,1,25,"Ray poison"},		{550,1,550,3,10,3,1,20,"Ray chaos"},
{551,2,551,10,20,5,20,10,"Totem fire"},		{552,2,552,10,20,5,20,10,"Totem frost"},	{553,2,553,10,20,5,20,10,"Totem lightning"},	{554,2,554,10,20,5,20,10,"Totem poison"},	{555,2,555,10,20,5,20,10,"Totem chaos"},
{556,0,556,10,20,0,30,30,"Empower fire"},	{557,0,557,10,20,0,30,30,"Empower frost"},	{558,0,558,10,20,0,30,30,"Empower lightning"},	{559,0,559,10,20,0,30,30,"Empower poison"},	{560,0,560,10,20,0,30,30,"Empower chaos"},
{561,0,561,5,10,0,30,20,"Reflect fire"},	{562,0,562,5,10,0,30,20,"Reflect frost"},	{563,0,563,5,10,0,30,20,"Reflect lightning"},	{564,0,564,5,10,0,30,20,"Reflect poison"},	{565,0,565,5,10,0,30,20,"Reflect chaos"},
{566,2,566,10,30,20,1,30,"Wave fire"},		{567,2,567,10,30,20,1,30,"Wave frost"},		{568,2,568,10,30,20,1,40,"Wave lightning"},		{569,2,569,10,30,20,1,50,"Wave poison"},	{570,2,570,10,30,20,1,40,"Wave chaos"}},
SFS = {500,501,502,503,504,"504a",505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,
551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,600,601,602,603},
SSEL = {["marayn dren"] = {"firefist", "Fireball_large", "firebloom", "flamebolt", "frostfist", "Frostball_large", "frostbloom", "frost bolt", "stormhand", "shockball_large", "shockbloom", "lightning bolt",
"disintegrate armor", "disintegrate weapon", "weakness to fire", "fierce frost shield", "fierce fire shield", "fierce shock shield"},
["sharn gra-muzgob"] = {"stamina", "rilm's cure", "balyna's efficacious balm", "balyna's perfect balm", "veloth's benison", "veloth's grace", "rapid regenerate", "mother's kiss", "strong heal companion", "great heal companion",
"restore willpower", "restore endurance", "restore personality", "restore strength", "restore speed", "restore luck", "restore agility", "restore intelligence",
"balyna's antidote", "cure poison", "cure poison touch", "Cure Blight_Self", "Cure Blight Disease", "cure common disease", "cure common disease other", "free action"},
["masalinie merian"] = {"recall", "mark", "divine intervention", "almsivi intervention", "resist fire", "resist frost", "resist shock", "resist magicka", "resist poison", "resist common disease", "llivam's reversal"},
["estirdalin"] = {"deadly poison [ranged]", "potent poison [ranged]", "burden touch", "cruel earwig", "noise", "gash spirit [ranged]", "daedric bite"},
["onlyhestandsthere"] = {"daedric health", "daedric willpower", "daedric luck", "daedric intelligence", "daedric personality", "daedric endurance", "daedric speed", "daedric strength", "daedric agility",
"great resist fire", "great resist frost", "great resist shock", "great resist magicka", "greater resist poison", "great resist common disease",
"absorb spell points", "absorb spell points [ranged]", "absorb health", "absorb health [ranged]", "absorb fatigue", "absorb fatigue [ranged]",
"absorb intelligence", "absorb intelligence [ranged]", "absorb willpower", "absorb willpower [ranged]", "absorb endurance", "absorb endurance [ranged]", "absorb strength", "absorb strength [ranged]",
"absorb agility", "absorb agility [ranged]", "absorb speed", "absorb speed [ranged]", "absorb luck", "absorb luck [ranged]", "absorb personality", "absorb personality [ranged]"},
["uleni heleran"] = {"blessed touch", "blessed word", "frenzy humanoid", "frenzy creature", "demoralize humanoid"},
["arrille"] = {"flame", "fire bite", "fireball", "shard", "frostbite", "frostball", "spark", "shock", "shockball", "rest of st. merris", "balyna's soothing balm", "hearth heal", "regenerate", "heal companion"},
["erer darothril"] = {"burning touch", "fire storm", "cruel firebloom", "wizard's fire", "god's fire", "freezing touch", "frost storm", "brittlewind", "wizard rend", "god's frost",
"shocking touch", "lightning storm", "wild shockbloom", "dire shockball", "god's spark"},
["felen maryon"] = {"command beast", "commanding touch", "drain heavy armor", "drain illusion", "drain light armor", "drain long blade", "drain marksman", "drain medium armor", "drain mercantile"}},
ING = {["4nm"]=true, ["4nm_met"]=true, ["4nm_tet"]=true, ["Enchant_right"]=true, ["Enchant_left"]=true, ["Blur"]=true, ["Rally"]=true, ["Electroshock"]=true, ["KO"]=true, ["Spawn_buff"]=true, ["Summon"]=true,
["Dodge"]=true, ["Parry"]=true, ["Survival_instinct"]=true},
BREG = {"CW","RF","RFS","RAY","SG","PR","ElSh","AUR","RUN","TOT","AOE","DC","WAV","EXP","TS"},	--SREG = {"DC"},
BU = {{n="aureal",{2,13,20,30,10,1}}, {n="goldaura",{0,3,10,20,0,180}}, {n="elemaura",{0,4,10,20,0,180}, {0,556,10,20,0,180}, {0,561,10,20,0,180}},
{n="Fire_arrow",{2,14,5,10,1,1}},	{n="Fire_ball",{2,14,10,20,5,1}},	{n="Fire_bolt",{2,14,20,30,10,1}},	{n="Fire_touch",{1,14,5,10,1,1}},
{n="Frost_arrow",{2,16,5,10,1,1}},	{n="Frost_ball",{2,16,10,20,5,1}},	{n="Frost_bolt",{2,16,20,30,10,1}},	{n="Frost_touch",{1,16,5,10,1,1}},
{n="Shock_arrow",{2,15,5,10,1,1}},	{n="Shock_ball",{2,15,10,20,5,1}},	{n="Shock_bolt",{2,15,20,30,10,1}},	{n="Shock_touch",{1,15,5,10,1,1}},
{n="Poison_arrow",{2,27,1,2,1,5}},	{n="Poison_ball",{2,27,2,4,5,5}},	{n="Poison_bolt",{2,27,4,6,10,5}},
{n="Chaos_arrow",{2,23,5,10,1,1}},	{n="Chaos_ball",{2,23,10,20,5,1}},	{n="Chaos_bolt",{2,23,20,30,10,1}},	{n="Chaos_touch",{1,23,5,10,1,1}},
{n="Elemental_touch",{1,14,5,10,1,1},{1,16,5,10,1,1},{1,15,5,10,1,1}},	{n="Storm_touch",{1,15,5,10,1,1},{1,16,5,10,1,1}},	{n="Eerie_touch",{1,23,5,10,1,1},{1,16,5,10,1,1}}, {n="Filth_touch",{1,23,5,10,1,1},{1,27,5,10,1,1}},
{n="Poison_bite",{0,27,1,2,0,5},w=1}, {n="Spider_bite",{0,27,2,3,0,10},{0,45,1,1,0,3},w=1}},
CLEN = {500,500,500,1000,1000,1000,500,1000,1000,[0]=500}, AREN = {500,100,100,300,500,1000,1000,500,500,500,[0]=1000}, ARW = {6,2,2,3,3,1,1,5,[0]=2}, AltW = {2, 1, 4, 3, 3, 1, 8, 7},
AG = {[34] = "KO", [35] = "KO"}, ASN = {[1] = 1, [14] = 1, [15] = 1, [18] = 1, [19] = 1},
ASP = {[4] = 1, [5] = 2, [6] = 2, [7] = 2},
PSO = {{{1,4},{2,4},{2,4}}, {{2,4},{2,4},{3,3}}, {{2,4},{3,3},{3,3}}},
Traum = {"strength", "endurance", "agility", "speed", "intelligence"},	HealStat = {"endurance", "strength", "agility", "speed", "intelligence", "willpower", "personality", "fatigue"},
BW = {{"dagger", "tanto", "kris", "knife", "knuckle", "shortsword", "wakizashi", "machete"},
{"longsword", "broadsword", "sword", "katana", "saber", "scimitar", "shamshir", "rapier", "waraxe", "axe", "mace", "club"},
{"claymore", "bastard", "daikatana", "kreigmesser", "battleaxe", "grandaxe", "warhammer", "spear", "longspear", "halberd", "bardiche", "glaive", "warscythe", "pitchfork", "staff"},
{"longbow", "crossbow"}},
CStats = {"strength", "endurance", "agility", "speed", "intelligence", "willpower", "luck", "personality", "combat", "magic", "stealth"},
CrBlackList = {["BM_hircine_straspect"] = true,["BM_hircine_spdaspect"] = true,["BM_hircine_huntaspect"] = true,["BM_hircine"] = true,["vivec_god"] = true,["Almalexia_warrior"] = true,["almalexia"] = true,
["dagoth_ur_1"] = true,["dagoth_ur_2"] = true,["Imperfect"] = true,["lich_barilzar"] = true,["lich_relvel"] = true,["yagrum bagarn"] = true,["bm_frost_giant"] = true,["dagoth araynys"] = true,["dagoth endus"] = true,
["dagoth gilvoth"] = true,["dagoth odros"] = true,["dagoth tureynul"] = true,["dagoth uthol"] = true,["dagoth vemyn"] = true,["heart_akulakhan"] = true, ["mudcrab_unique"] = true, ["scamp_creeper"] = true,
["4nm_target"] = true},
CID = {["bonewalker"] = "zombirise", ["bonewalker_weak"] = "zombirise", ["Bonewalker_Greater"] = "zombirise", ["golden saint"] = "auril", ["golden saint_summon"] = "auril",
["BM_bear_black"] = "bear", ["BM_bear_brown"] = "bear", ["BM_bear_snow_unique"] = "bear", ["BM_wolf_grey"] = "wolf", ["BM_wolf_red"] = "wolf", ["BM_wolf_snow_unique"] = "wolf", ["BM_wolf_grey_lvl_1"] = "wolf",
["centurion_spider"] = "dwem", ["centurion_sphere"] = "dwem", ["centurion_steam"] = "dwem", ["centurion_projectile"] = "dwem", ["centurion_steam_advance"] = "dwem",
["centurion_spider_miner"] = "dwem", ["centurion_spider_tower"] = "dwem", ["centurion_sword"] = "dwem", ["centurion_weapon"] = "dwem", ["centurion_tank"] = "dwem",
},
CAR = {["atronach_flame"] = 20, ["atronach_flame_summon"] = 20, ["atronach_frost"] = 40, ["atronach_frost_summon"] = 40, ["atronach_storm"] = 60, ["atronach_storm_summon"] = 60, ["atronach_frost_BM"] = 50,
["atronach_flame_lord"] = 60, ["atronach_frost_lord"] = 100, ["atronach_storm_lord"] = 120,

["dremora"] = 50, ["dremora_summon"] = 50, ["dremora_lord"] = 80, ["dremora_mage"] = 10, ["dremora_mage_s"] = 10, ["xivkyn"] = 60, ["xivkyn_s"] = 60, ["skaafin"] = 40, ["skaafin_archer"] = 25, ["skaafin_archer_s"] = 25,
["golden saint"] = 40, ["golden saint_summon"] = 40, ["mazken"] = 30, ["mazken_s"] = 30,
["scamp"] = 3, ["clannfear"] = 15, ["clannfear_lesser"] = 10, ["clannfear_summon"] = 15, ["vermai"] = 10, ["hunger"] = 10, ["hunger_summon"] = 10, ["ogrim"] = 30, ["ogrim titan"] = 40, ["daedroth"] = 20, ["daedroth_summon"] = 20,
["winged twilight"] = 5, ["winged twilight_summon"] = 5, ["daedraspider"] = 5, ["daedraspider_s"] = 5, ["xivilai"] = 40, ["xivilai_s"] = 40,

["skeleton"] = 10, ["skeleton_summon"] = 10, ["skeleton entrance"] = 10, ["skeleton_weak"] = 5, ["skeleton archer"] = 15, ["skeleton_archer_s"] = 15, ["skeleton_mage"] = 10, ["skeleton_mage_s"] = 10, 
["skeleton warrior"] = 30, ["skeleton champion"] = 40, ["skeleton_knight"] = 50, ["bm skeleton champion gr"] = 60,
["bonewalker"] = 5, ["bonewalker_weak"] = 5, ["Bonewalker_Greater"] = 5, ["Bonewalker_Greater_summ"] = 5, ["bonewalker_summon"] = 5, ["bonelord"] = 15, ["bonelord_summon"] = 15,
["lich"] = 20, ["lich_elder"] = 30, ["BM_wolf_skeleton"] = 5, ["BM_wolf_bone_summon"] = 5,

["BM_draugr01"] = 15, ["draugr"] = 15, ["draugr_fem"] = 30, ["draugr_soldier"] = 40, ["draugr_warrior"] = 50, ["draugr_general"] = 70, ["draugr_priest"] = 30,

["corprus_stalker"] = 5, ["corprus_lame"] = 15, ["ash_slave"] = 10, ["ash_zombie"] = 5, ["ash_ghoul"] = 20, ["ash_ghoul_high"] = 25,
["ash_revenant"] = 40, ["ash_zombie_warrior"] = 40, ["ash_ghoul_warrior"] = 50, ["ascended_sleeper"] = 40,

["centurion_spider"] = 70, ["centurion_sphere"] = 80, ["centurion_sphere_summon"] = 80, ["centurion_steam"] = 90, ["centurion_projectile"] = 80, ["centurion_steam_advance"] = 100,
["centurion_spider_miner"] = 70, ["centurion_spider_tower"] = 70, ["centurion_sword"] = 90, ["centurion_weapon"] = 80, ["centurion_tank"] = 150,

["Rat"] = 3, ["rat_diseased"] = 3, ["rat_blighted"] = 3, ["nix-hound"] = 10, ["nix-hound blighted"] = 10, ["nix_mount"] = 15, ["guar"] = 10, ["guar_feral"] = 10, ["guar_pack"] = 20,
["alit"] = 10, ["alit_diseased"] = 10, ["alit_blighted"] = 10, ["dreugh"] = 30, ["dreugh_soldier"] = 50, ["dreugh_land"] = 40, ["slaughterfish"] = 3, ["Slaughterfish_Small"] = 3, ["slaughterfish_electro"] = 3,
["kagouti"] = 15, ["kagouti_diseased"] = 15, ["kagouti_blighted"] = 15, ["kagouti_dire"] = 20,
["kwama worker"] = 25, ["kwama worker diseased"] = 25, ["kwama worker blighted"] = 25, ["kwama worker entrance"] = 30, ["kwama warrior"] = 30, ["kwama warrior blighted"] = 30,
["kwama forager"] = 0, ["kwama forager blighted"] = 0, ["scrib"] = 5, ["scrib diseased"] = 5, ["scrib blighted"] = 5,
["mudcrab"] = 30, ["mudcrab-Diseased"] = 30, ["mudcrab_king"] = 40, ["mudcrab_rock"] = 60, ["mudcrab_titan"] = 50,
["netch_bull"] = 10, ["netch_bull_ranched"] = 10, ["netch_betty"] = 5, ["netch_betty_ranched"] = 5,
["shalk"] = 15, ["shalk_diseased"] = 15, ["shalk_blighted"] = 15,
["durzog_wild"] = 15, ["durzog_wild_weaker"] = 10, ["durzog_war"] = 20, ["durzog_war_trained"] = 20, ["durzog_diseased"] = 15,
["goblin_grunt"] = 5, ["goblin_footsoldier"] = 15, ["goblin_bruiser"] = 25, ["goblin_handler"] = 20, ["goblin_officer"] = 35, ["goblin_shaman"] = 5,
["fabricant_verminous"] = 40, ["fabricant_summon"] = 40, ["fabricant_hulking"] = 60,
["BM_wolf_grey"] = 10, ["BM_wolf_red"] = 10, ["BM_wolf_grey_lvl_1"] = 5, ["BM_wolf_snow_unique"] = 10, ["BM_wolf_grey_summon"] = 10,
["BM_bear_black"] = 20, ["BM_bear_brown"] = 20, ["BM_bear_snow_unique"] = 20, ["BM_bear_black_summon"] = 20,

["BM_riekling"] = 15, ["BM_riekling_berserk"] = 20, ["BM_riekling_hunter"] = 15, ["BM_riekling_warrior"] = 30, ["BM_riekling_heavy"] = 60, ["BM_riekling_chieftain"] = 40, ["BM_riekling_shaman"] = 15, 
["BM_riekling_mounted"] = 15, ["BM_riekling_mounted_war"] = 30, 
["BM_frost_boar"] = 15, ["BM_spriggan"] = 30, ["BM_ice_troll"] = 30, ["BM_ice_troll_tough"] = 40},

CDOD = {["atronach_flame"] = 1, ["atronach_flame_summon"] = 1, ["atronach_flame_lord"] = 1, ["scamp"] = 1, ["clannfear"] = 1, ["clannfear_lesser"] = 1, ["clannfear_summon"] = 1, ["vermai"] = 1,
["hunger"] = 1, ["hunger_summon"] = 1, ["winged twilight"] = 1, ["winged twilight_summon"] = 1, ["daedraspider"] = 1, ["daedraspider_s"] = 1,
["bonelord"] = 1, ["bonelord_summon"] = 1, ["BM_draugr01"] = 1, ["draugr"] = 1, ["ancestor_ghost"] = 1, ["ancestor_ghost_greater"] = 1, ["dwarven ghost"] = 1,
["centurion_sphere"] = 1, ["centurion_sphere_summon"] = 1, ["centurion_projectile"] = 1,
["goblin_bruiser"] = 1, ["fabricant_verminous"] = 1, ["fabricant_summon"] = 1,
["kwama forager"] = 1, ["kwama forager blighted"] = 1, ["Rat"] = 1, ["rat_diseased"] = 1, ["rat_blighted"] = 1, ["nix-hound"] = 1, ["nix-hound blighted"] = 1, ["nix_mount"] = 1,
["dreugh"] = 1, ["dreugh_soldier"] = 1, ["dreugh_land"] = 1, ["slaughterfish"] = 1, ["Slaughterfish_Small"] = 1, ["slaughterfish_electro"] = 1,
["BM_wolf_grey"] = 1, ["BM_wolf_red"] = 1, ["BM_wolf_grey_lvl_1"] = 1, ["BM_wolf_snow_unique"] = 1, ["BM_wolf_grey_summon"] = 1, ["BM_wolf_skeleton"] = 1, ["BM_wolf_bone_summon"] = 1, ["BM_spriggan"] = 1},


CDIS = {["corprus_lame"] = "black-heart blight", ["corprus_stalker"] = "ash-chancre", ["ash_ghoul"] = "ash woe blight", ["ash_slave"] = "ash woe blight", ["ash_zombie"] = "ash woe blight",
["ash_ghoul_high"] = "ash woe blight", ["ash_ghoul_warrior"] = "ash woe blight", ["ash_zombie_warrior"] = "ash woe blight", ["ascended_sleeper"] = "ash woe blight", ["ash_revenant"] = "ash-chancre", 
["alit_blighted"] = "black-heart blight", ["nix-hound blighted"] = "black-heart blight", ["rat_blighted"] = "black-heart blight", ["cliff racer_blighted"] = "ash-chancre", ["kagouti_blighted"] = "chanthrax blight",
["shalk_blighted"] = "ash woe blight",

["alit_diseased"] = "ataxia", ["cliff racer_diseased"] = "helljoint", ["kagouti_diseased"] = "yellow tick", ["mudcrab-Diseased"] = "swamp fever", ["rat_diseased"] = "witbane",
["scrib diseased"] = "droops", ["kwama worker diseased"] = "droops", ["shalk_diseased"] = "collywobbles",
["BM_wolf_red"] = "rattles", ["BM_bear_brown"] = "rust chancre", ["durzog_diseased"] = "rotbone",

["kagouti_dire"] = "rockjoint", ["nix_mount"] = "dampworm", ["dreugh_land"] = "wither", ["netch_bull"] = "serpiginous dementia", ["netch_betty"] = "serpiginous dementia", ["slaughterfish"] = "greenspore",
["bonewalker"] = "brown rot", ["Bonewalker_Greater"] = "brown rot", ["bonewalker_weak"] = "brown rot"},

CPOI = {["alit"] = {"Poison_bite",50}, ["alit_diseased"] = {"Poison_bite",80}, ["alit_blighted"] = {"Poison_bite",80},
["kwama forager"] = {"Poison_bite",30}, ["kwama forager blighted"] = {"Poison_bite",50}, ["netch_bull"] = {"Poison_bite",30},
["vermai"] = {"Poison_bite",30}, ["daedraspider"] = {"Spider_bite",30}, ["daedraspider_s"] = {"Spider_bite",10}, ["daedroth"] = {"Poison_bite",50}, ["daedroth_summon"] = {"Poison_bite",30}},

CMAG = {["atronach_flame"] = {"Fire_touch",100}, ["atronach_flame_summon"] = {"Fire_touch",100}, ["atronach_flame_lord"] = {"Fire_touch",100}, 
["atronach_frost"] = {"Frost_touch",100}, ["atronach_frost_summon"] = {"Frost_touch",100}, ["atronach_frost_lord"] = {"Frost_touch",100}, ["atronach_frost_BM"] = {"Frost_touch",100}, 
["atronach_storm"] = {"Shock_touch",100}, ["atronach_storm_summon"] = {"Shock_touch",100}, ["atronach_storm_lord"] = {"Shock_touch",100},
["winged twilight"] = {"Storm_touch",30}, ["winged twilight_summon"] = {"Storm_touch",20},
["dremora_mage"] = {"Elemental_touch",50}, ["dremora_mage_s"] = {"Elemental_touch",30}, ["golden saint"] = {"Elemental_touch",20}, ["golden saint_summon"] = {"Elemental_touch",20},
["skeleton_mage"] = {"Elemental_touch",20}, ["skeleton_mage_s"] = {"Elemental_touch",20},
["bonelord"] = {"Chaos_touch",100}, ["bonelord_summon"] = {"Chaos_touch",50}, ["lich"] = {"Filth_touch",100}, ["lich_elder"] = {"Eerie_touch",100}, ["draugr_priest"] = {"Chaos_touch",50},
["ancestor_ghost"] = {"Frost_touch",50}, ["ancestor_ghost_summon"] = {"Frost_touch",30}, ["ancestor_ghost_greater"] = {"Eerie_touch",50}, ["dwarven ghost"] = {"Frost_touch",80}, 
["shalk"] = {"Fire_touch",30}, ["shalk_diseased"] = {"Fire_touch",20}, ["shalk_blighted"] = {"Fire_touch",40}, ["netch_betty"] = {"Shock_touch",30},
["BM_wolf_snow_unique"] = {"Frost_touch",20}, ["BM_bear_snow_unique"] = {"Frost_touch",20}, ["slaughterfish_electro"] = {"Shock_touch",50}},

MAC = {[0] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow"},
["atronach_flame"] = {"Fire_ball","Fire_bolt"}, ["atronach_flame_summon"] = {"Fire_ball","Fire_bolt"}, ["atronach_flame_lord"] = {"Fire_bolt"},
["atronach_frost"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_summon"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_lord"] = {"Frost_bolt"}, ["atronach_frost_BM"] = {"Frost_ball","Frost_bolt"},
["atronach_storm"] = {"Shock_ball","Shock_bolt"}, ["atronach_storm_summon"] = {"Shock_ball","Shock_bolt"}, ["atronach_storm_lord"] = {"Shock_bolt"},
["dremora"] = {"Fire_arrow","Fire_ball"}, ["dremora_summon"] = {"Fire_arrow","Fire_ball"}, ["dremora_lord"] = {"Fire_ball","Fire_bolt"},
["golden saint"] = {"Fire_bolt","Frost_bolt","Shock_bolt"}, ["golden saint_summon"] = {"Fire_bolt","Frost_bolt","Shock_bolt"},
["mazken"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"}, ["mazken_s"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"},
["hunger"] = {"Chaos_arrow","Chaos_ball"}, ["hunger_summon"] = {"Chaos_arrow","Chaos_ball"},
["scamp"] = {"Fire_arrow"}, ["scamp_summon"] = {"Fire_arrow"}, ["daedroth"] = {"Poison_arrow","Poison_ball"}, ["daedroth_summon"] = {"Poison_arrow","Poison_ball"},
["winged twilight"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"}, ["winged twilight_summon"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"},
["dremora_mage"] = {"Fire_ball","Frost_ball","Shock_ball","Fire_bolt","Frost_bolt","Shock_bolt"}, ["dremora_mage_s"] = {"Fire_ball","Frost_ball","Shock_ball","Fire_bolt","Frost_bolt","Shock_bolt"},
["daedraspider"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"}, ["daedraspider_s"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"},
["xivilai"] = {"Fire_ball","Chaos_ball"}, ["xivilai_s"] = {"Fire_ball","Chaos_ball"},
["xivkyn"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"}, ["xivkyn_s"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"},

["ancestor_ghost"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_summon"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_greater"] = {"Chaos_arrow","Chaos_ball","Frost_arrow","Frost_ball"},
["Bonewalker_Greater"] = {"Chaos_arrow"}, ["Bonewalker_Greater_summ"] = {"Chaos_arrow"},
["bonelord"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"}, ["bonelord_summon"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"},
["skeleton_mage"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball"},
["skeleton_mage_s"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball"},
["lich"] = {"Frost_ball","Poison_ball","Chaos_ball","Frost_bolt","Poison_bolt","Chaos_bolt"}, ["lich_elder"] = {"Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"},
["ash_revenant"] = {"Poison_ball","Chaos_ball"}, ["draugr_priest"] = {"Frost_ball","Chaos_ball"},

["ash_slave"] = {"Fire_arrow","Frost_arrow","Shock_arrow"}, ["ash_ghoul"] = {"Chaos_ball","Chaos_bolt"}, ["ash_ghoul_warrior"] = {"Chaos_arrow","Chaos_ball"},
["ash_ghoul_high"] = {"Fire_bolt","Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"}, ["ascended_sleeper"] = {"Fire_bolt","Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"},

["centurion_spider_tower"] = {"Shock_arrow"}, ["centurion_spider_miner"] = {"Fire_arrow"},
["kwama warrior"] = {"Poison_arrow","Poison_ball"}, ["kwama warrior blighted"] = {"Poison_arrow","Poison_ball"},
["netch_bull"] = {"Poison_arrow","Poison_ball"}, ["netch_betty"] = {"Shock_arrow","Shock_ball"},
["goblin_handler"] = {"Fire_arrow"}, ["goblin_officer"] = {"Fire_arrow"}, ["goblin_shaman"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Fire_ball","Frost_ball","Shock_ball"},
["BM_riekling_shaman"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Fire_ball","Frost_ball","Shock_ball"},
["BM_spriggan"] = {"Frost_ball","Poison_ball"}},
Summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["daedraspider_s"] = true,["dremora_mage_s"] = true,["skaafin_archer_s"] = true,["xivkyn_s"] = true,["xivilai_s"] = true,["mazken_s"] = true,["skeleton_mage_s"] = true,["skeleton_archer_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true},
UndMinion = {"skeleton_weak", "bonewalker_weak", "skeleton", "bonewalker", "skeleton archer", "skeleton warrior", "skeleton champion", "Bonewalker_Greater"},
Blight = {"ash woe blight", "black-heart blight", "chanthrax blight", "ash-chancre"},
atrbot = {["atronach_flame"] = {4,556,561}, ["atronach_flame_summon"] = {4,556,561}, ["atronach_flame_lord"] = {4,556,561,114},
["atronach_frost"] = {6,557,562}, ["atronach_frost_summon"] = {6,557,562}, ["atronach_frost_lord"] = {6,557,562,115},
["atronach_storm"] = {5,558,563}, ["atronach_storm_summon"] = {5,558,563}, ["atronach_storm_lord"] = {5,558,563,116}},
BlackItem = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true},
BlackAmmo = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true, ["4nm_stone"] = true},
DurKF = {[14]=3,[15]=3,[16]=3,[23]=3,[27]=3,[22]=3,[24]=3,[25]=3,[26]=3,[37]=5,[38]=5,[74]=3,[75]=3,[76]=3,[77]=3,[78]=3,[86]=3,[87]=3,[88]=3},
nomag = {[39] = true, [45] = true, [46] = true, [69] = true, [70] = true, [72] = true, [73] = true},
--SID = {["4s_DC"] = "discharge", ["4s_CWT"] = "CWT", ["4s_rune1"] = "rune", ["4s_totem1"] = "totem", ["4s_totem2"] = "totem", ["4s_totemexp"] = "totem"},
CME = {[4] = "frost", [6] = "fire", [5] = "shock", [73] = "shock", [72] = "poison", [57] = "vital", [516] = "frost", [517] = "fire", [518] = "shock"},
ELSH = {[4] = {id = 14, ts = 0}, [5] = {id = 15, ts = 0}, [6] = {id = 16, ts = 0}},
LID = {[0] = {255,0,128}, [1] = {255,128,0}, [2] = {0,255,255}, [3] = {128,0,255}, [4] = {0,128,64}}, MEC = {3, 3, 4, 5, 4, [0] = 4},
RES = {[14] = "resistFire", [16] = "resistFrost", [15] = "resistShock", [27] = "resistPoison"},
UItcolor = {{0,0,0},{0,0,1},{0,1,0},{0,1,1},{1,0,0},{1,0,1},{1,1,0},{1,1,1}},
TPP = {{-23000, -15200, 700}, {-14300, 52400, 2300}, {30000, -77600, 2000}, {150300, 31800, 900}, {17800, -101900, 500}, {-11200, 20000, 1500}, {53800, -51000, 400}, {-86800, 92300, 1200},
{1900, -56800, 1700}, {125000, -105200, 1000}, {125200, 45200, 1800}, {109500, 116000, 600}, {-21600, 103200, 2200}, {109300, -62000, 2200}, {60200, 183300, 500}, {-11100, -71000, 500},
{-46600, -38100, 400}, {-60100, 26700, 400}, {-68400, 140400, 400}, {-85400, 125600, 1200}, {94600, 115800, 1800}, {87500, 118100, 3700}},
AoEmod = {[0] = "4nm_aoe_vitality", [1] = "4nm_aoe_fire", [2] = "4nm_aoe_frost", [3] = "4nm_aoe_shock", [4] = "4nm_aoe_poison"},
BotQ = {"bargain", "cheap", "standard", "quality", "exclusive"},
BotIc = {["m\\Tx_potion_bargain_01.tga"] = "bargain", ["m\\Tx_potion_cheap_01.tga"] = "cheap", ["m\\Tx_potion_fresh_01.tga"] = "cheap",
["m\\Tx_potion_standard_01.tga"] = "standard", ["m\\Tx_potion_quality_01.tga"] = "quality", ["m\\Tx_potion_exclusive_01.tga"] = "exclusive"},
BotMod = {["m\\misc_potion_bargain_01.nif"] = {"w\\4nm_bottle1.nif", "m\\Tx_potion_bargain_01.tga"}, ["m\\misc_potion_cheap_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_cheap_01.tga"},
["m\\misc_potion_fresh_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_fresh_01.tga"}, ["m\\misc_potion_standard_01.nif"] = {"w\\4nm_bottle3.nif", "m\\Tx_potion_standard_01.tga"},
["m\\misc_potion_quality_01.nif"] = {"w\\4nm_bottle4.nif", "m\\Tx_potion_quality_01.tga"}, ["m\\misc_potion_exclusive_01.nif"] = {"w\\4nm_bottle5.nif", "m\\Tx_potion_exclusive_01.tga"}},
Anvil = {furn_anvil00 = true, furn_t_fireplace_01 = true, furn_de_forge_01 = true, furn_de_bellows_01 = true, Furn_S_forge = true},
DWOBT = {[tes3.objectType.light] = true, [tes3.objectType.lockpick] = true, [tes3.objectType.probe] = true},
BartT = {bartersAlchemy = true, bartersApparatus = true, bartersArmor = true, bartersBooks = true, bartersClothing = true, bartersEnchantedItems = true, bartersIngredients = true,
bartersLights = true, bartersLockpicks = true, bartersMiscItems = true, bartersProbes = true, bartersRepairTools = true, bartersWeapons = true},
CF = {}, APP = {}}
local SP = {[0] = {s = 11, p1 = "alt1", p2 = "alt2", p3 = "alt3", p4 = "alt4"}, [1] = {s = 13, p1 = "con1", p2 = "con2", p3 = "con3", p4 = "con4"}, [2] = {s = 10, p1 = "des1", p2 = "des2", p3 = "des3", p4 = "des4"},
[3] = {s = 12, p1 = "ill1", p2 = "ill2", p3 = "ill3", p4 = "ill4"}, [4] = {s = 14, p1 = "mys1", p2 = "mys2", p3 = "mys3", p4 = "mys4"}, [5] = {s = 15, p1 = "res1", p2 = "res2", p3 = "res3", p4 = "res4"}}
local MEP = {[14] = {s = 11, p0 = "des1a", p = "alt0"}, [16] = {s = 11, p0 = "des1b", p = "alt0"}, [15] = {s = 11, p0 = "des1c", p = "alt0"}, [27] = {s = 15, p0 = "des1d"}, p = "res5",
[85] = {s = 15, p = "res7"}, [86] = {s = 15, p = "res7"}, [87] = {s = 15, p = "res7"}, [88] = {s = 15, p = "res7"}, [89] = {s = 15, p = "res7"}, [64] = {s = 12, p = "ill7"}, [65] = {s = 12, p = "ill7"}, [66] = {s = 12, p = "ill7"}}
local ME = {[102]=0,[103]=0,[104]=0,[105]=0,[106]=0,[107]=0,[108]=0,[109]=0,[110]=0,[111]=0,[112]=0,[113]=0,[114]=0,[115]=0,[116]=0,[134]=0,[137]=0,[138]=0,[139]=0,[140]=0,[141]=0,[142]=0,
[120]=3,[121]=3,[122]=3,[123]=3,[124]=3,[125]=3,[127]=3,[128]=3,[129]=3,[130]=3,[131]=3,[601]=3,[603]=3, [14]=1, [15]=1, [16]=1, [75]=2, [76]=2, [77]=2,
[79]=4, [80]=4, [81]=4, [82]=4, [83]=4, [84]=4, [117]=4, [90]=5, [91]=5, [92]=5, [93]=5, [94]=5, [95]=5, [97]=5, [98]=5, [99]=5,
[17]=6, [18]=6, [19]=6, [20]=6, [21]=6, [28]=7, [29]=7, [30]=7, [31]=7, [32]=7, [33]=7, [35]=7, [36]=7,
[3] = "shield", [4] = "shield", [5] = "shield", [6] = "shield", [61] = "teleport", [62] = "teleport", [63] = "teleport",
[511] = "charge", [512] = "charge", [513] = "charge", [514] = "charge", [515] = "charge", [516] = "aura", [517] = "aura", [518] = "aura", [519] = "aura", [520] = "aura",
[521] = "aoe", [522] = "aoe", [523] = "aoe", [524] = "aoe", [525] = "aoe", [526] = "rune", [527] = "rune", [528] = "rune", [529] = "rune", [530] = "rune",
[531] = "explode", [532] = "explode", [533] = "explode", [534] = "explode", [535] = "explode", [536] = "shotgun", [537] = "shotgun", [538] = "shotgun", [539] = "shotgun", [540] = "shotgun",
[541] = "discharge", [542] = "discharge", [543] = "discharge", [544] = "discharge", [545] = "discharge", [546] = "ray", [547] = "ray", [548] = "ray", [549] = "ray", [550] = "ray",
[551] = "totem", [552] = "totem", [553] = "totem", [554] = "totem", [555] = "totem", [556] = "empower", [557] = "empower", [558] = "empower", [559] = "empower", [560] = "empower",
[561] = "reflect", [562] = "reflect", [563] = "reflect", [564] = "reflect", [565] = "reflect", [566] = "wave", [567] = "wave", [568] = "wave", [569] = "wave", [570] = "wave"}
local MID = {[0] = 23, [1] = 14, [2] = 16, [3] = 15, [4] = 27, [5] = 23}
local EMP = {[14] = {e = 556, p = "des6a", p1 = "des5a", p2 = "wil9a", p3 = "end7a"}, [16] = {e = 557, p = "des6b", p1 = "des5b", p2 = "wil9b", p3 = "end7b"},
[15] = {e = 558, p = "des6c", p1 = "des5c", p2 = "wil9c", p3 = "end7c"}, [27] = {e = 559, p = "des6d", p1 = "des5d", p2 = "wil9d", p3 = "end7d"}, [23] = {e = 560, p = "des6e", p1 = "des5e", p2 = "wil9e"}}
local function adds(...) local splist = rf.object.spells	for i,s in ipairs{...} do splist:add(s) end end
local function rems(...) local splist = rf.object.spells	for i,s in ipairs{...} do splist:remove(s) end end
local function Mod(cost, m) local stat = (m or mp).magicka	stat.current = stat.current - cost 	if not m or m == mp then M.Mana.current = stat.current end end
local function Mag(id, r) return (tes3.getEffectMagnitude{reference = r or p, effect = id}) end
local function TFR(n, f) if n == 0 then f() else timer.delayOneFrame(function() TFR(n - 1, f) end) end end
local function Cpow(m, s1, s2, stam) return (100 + m.willpower.current/((m ~= mp or P.wil1) and 5 or 10) + m:getSkillValue(SP[s1].s)/((m ~= mp or P[SP[s1].p1]) and 5 or 10) + ((m ~= mp or P[SP[s2].p1]) and m:getSkillValue(SP[s2].s)/10 or 0))
* (stam and math.min(math.lerp(((m ~= mp or P.wil2) and 0.4 or 0.3) + ((m ~= mp or P[SP[s1].p3]) and 0.2 or 0), 1, m.fatigue.normalized*1.1), 1) or 1) end

L.SetGlobal = function()	local w = mp.readiedWeapon		w = w and w.object
G.stop = tes3.findGlobal("4nm_stoptraining")	G.leskoef = P.int0 and 5 or 3		if p.object.level * G.leskoef > D.L.les and G.stop.value == 1 then G.stop.value = 0 end
G.potlim = 50 + mp.endurance.base*(P.end9 and 0.7 or 0.5)		
G.spdodge = P.spd15 and 120 or 100
G.maxcomb = P.spd7 and 10 or 4
G.CombatAng = P.agi27 and 0.4 or 0.3		G.CombatAngleXY.value = G.CombatAng

tes3.findGMST("fMajorSkillBonus").value = P.int0 and 0.75 or 0.5
tes3.findGMST("fMinorSkillBonus").value = P.int0 and 1 or 0.75
tes3.findGMST("fMiscSkillBonus").value = P.int0 and 1.25 or 1

tes3.findGMST("fUnarmoredBase2").value = P.una0 and 0.02 or 0.01
G.HandReach.value = (P.hand11 or w or not mp.weaponDrawn) and 0.7 or 0.5

tes3.findGMST("fHoldBreathTime").value = (10 + mp.endurance.base/5 + mp.athletics.base/5) * (P.atl4 and 2 or 1)
tes3.findGMST("fSwimRunAthleticsMult").value = mp.athletics.base/(P.atl5 and 500 or 1000)

--tes3.findGMST("fJumpEncumbranceBase").value = P.atl6 and 0.1 or -0.2
--tes3.findGMST("fJumpEncumbranceMultiplier").value = P.atl6 and 0.4 or 0.7
--tes3.findGMST("fJumpAcroMultiplier").value = P.acr1 and 4 or 3
tes3.findGMST("fJumpMoveMult").value = P.acr3 and 0.5 or 0.2
tes3.findGMST("fFallDamageDistanceMin").value = P.acr5 and 500 or 400
tes3.findGMST("fFallAcroBase").value = P.acr7 and 0.5 or 1
tes3.findGMST("fFatigueJumpBase").value = P.acr2 and math.max(20 - mp.acrobatics.base/10, 10) or 20
tes3.findGMST("fFatigueJumpMult").value = P.atl6 and math.max(30 - mp.athletics.base/10, 20) or 30

tes3.findGMST("fMagicItemRechargePerSecond").value = mp.enchant.base/(P.enc12 and 1000 or 2000)
tes3.findGMST("iSoulAmountForConstantEffect").value = P.enc9 and 200 or 400
tes3.findGMST("fEnchantmentChanceMult").value = P.enc14 and 2 or 3
tes3.findGMST("fEnchantmentConstantChanceMult").value = P.luc9 and 1 or 0.5
tes3.findGMST("fWeaponDamageMult").value = P.arm3 and math.max(0.1 - mp.armorer.base/2000, 0.05) or 0.1

tes3.findGMST("fSneakSpeedMultiplier").value = P.snek2 and math.min(0.75 + mp.sneak.base/400, 1) or 0.75
tes3.findGMST("fPickLockMult").value = P.sec1 and -1 or -2
tes3.findGMST("fTrapCostMult").value = P.sec2 and -1 or -2

tes3.findGMST("iTrainingMod").value = P.merc1 and 10 or 20
tes3.findGMST("fRepairMult").value = P.merc6 and 1 or 2
tes3.findGMST("fSpellMakingValueMult").value = P.merc7 and 10 or 20
tes3.findGMST("fEnchantmentValueMult").value = P.merc8 and 100 or 200
tes3.findGMST("fBarterGoldResetDelay").value = P.merc5 and 12 or 24

tes3.findGMST("iBarterSuccessDisposition").value = P.spec2 and 3 or 1
tes3.findGMST("iBarterFailDisposition").value = P.spec2 and -1 or -3
tes3.findGMST("iPerMinChance").value = P.spec1 and 10 or 0
tes3.findGMST("iPerMinChange").value = P.spec1 and 10 or 0
tes3.findGMST("fPerDieRollMult").value = P.spec6 and 0.2 or 0.1
tes3.findGMST("fBribe10Mod").value = P.spec4 and 20 or 10
tes3.findGMST("fBribe100Mod").value = P.spec4 and 50 or 30
tes3.findGMST("fBribe1000Mod").value = P.spec4 and 100 or 50
tes3.findGMST("fCrimeGoldTurnInMult").value = P.spec7 and math.max(1 - mp.mercantile.base/200, 0.5) or 1
tes3.findGMST("fCrimeGoldDiscountMult").value = P.spec8 and math.max(0.5 - mp.mercantile.base*0.003, 0.2) or 0.5
tes3.findGMST("iCrimeThreshold").value = P.sec4 and 3000 or 1000

tes3.findGMST("fDispPersonalityBase").value = P.per1 and 50 or 100
tes3.findGMST("fDispPersonalityMult").value = P.per1 and 0.5 or 0.3
tes3.findGMST("fDispFactionMod").value = P.per2 and 5 or 2
tes3.findGMST("fDispRaceMod").value = P.per5 and 30 or 5
tes3.findGMST("fDispCrimeMod").value = P.per6 and 0 or 0.02

tes3.findGMST("fPersonalityMod").value = P.per4 and 5 or 10
tes3.findGMST("fLuckMod").value = P.per4 and 10 or 20
tes3.findGMST("fReputationMod").value = P.per8 and 1 or 0.5
tes3.findGMST("fLevelMod").value = P.spec9 and 5 or 2

tes3.findGMST("fSleepRandMod").value = P.luc6 and 0.1 or 0.5
tes3.findGMST("fDiseaseXferChance").value = math.max((P.luc7 and 10 or 20) - mp.luck.base/20, 1)
tes3.findGMST("fProjectileThrownStoreChance").value = P.luc8 and 100 or 75
tes3.findGlobal("WerewolfClawMult").value = 5
end
L.HPUpdate = function()	local Lord = mp.birthsign.id == "Trollkin"
	mp.shield = (P.end14 and mp.endurance.base/20 or 0) + (P.una2 and mp.unarmored.base/20 or 0) + (D.LEG[3] or 0) + (Lord and ((D.chimstar == 2 and 20) or (D.chimstar == 1 and 10) or 5) or 0)
	+ tes3.getEffectMagnitude{reference = p, effect = 3}
	tes3.setStatistic{reference = p, name = "health", base = math.max(mp.endurance.base*(P.end13 and 0.65 or 0.5) + mp.strength.base*(P.str10 and 0.4 or 0.25) + mp.willpower.base*(P.wil12 and 0.35 or 0.25)
	+ (P.atl9 and mp.athletics.base*0.1 or 0) - (D.LEG[1] or 0) + (D.LEG[2] or 0) + (L.RHP[p.object.race.id] or 0)
	+ (Lord and ((D.chimstar == 2 and 30) or (D.chimstar == 1 and 20) or 10) or 0) + tes3.getEffectMagnitude{reference = p, effect = 80}, 5)}
	if mp.health.normalized > 1 then mp.health.current = mp.health.base end
	TFR(2, function() mp.encumbrance.currentRaw = p.object.inventory:calculateWeight() + tes3.getEffectMagnitude{reference = p, effect = 7} - tes3.getEffectMagnitude{reference = p, effect = 8} end)
end

L.LegSelect = function()	local s = tes3.getObject("4nm_legend") or tes3spell.create("4nm_legend")	s.castType = 1		s.name = cf.en and "Legendary" or "Легендарность"	
local LEGT = {
{d = cf.en and "- Health" or "- Здоровье", c = -4, max = 50, lvl = 1, nolim = true, pic = "icons/k/health.dds"},
{d = cf.en and "+ Health" or "+ Здоровье", c = 4, max = 50, lvl = 1, nolim = true, id = 80},
{d = cf.en and "Armor" or "Броня", c = 5, max = 30, lvl = 1, nolim = true, id = 3},
{d = cf.en and "Stamina regen" or "Регенерация стамины", c = 10, max = 20, lvl = 2, id = 77},
{d = cf.en and "Mana regen" or "Регенерация маны", c = 100, max = 2, lvl = 20, id = 76},
{d = cf.en and "Health regen" or "Регенерация здоровья", c = 100, max = 1, lvl = 50, id = 75},
{d = cf.en and "Charge regen" or "Регенерация зарядов", c = 100, max = 1, lvl = 50, id = 501},
{d = cf.en and "Mana pool" or "Максимум маны", c = 10, max = 10, lvl = 5, id = 84},
{d = cf.en and "Attack bonus" or "Бонус атаки", c = 4, max = 50, lvl = 1, id = 117},
{d = cf.en and "Dodge bonus" or "Бонус уклонения", c = 4, max = 50, lvl = 1, id = 42},
{d = cf.en and "Lightness" or "Легкость", c = 1, max = 100, lvl = 0.5, id = 8},
{d = cf.en and "Jump" or "Прыжки", c = 20, max = 5, lvl = 10, id = 9},
{d = cf.en and "Dash" or "Дэш", c = 10, max = 10, lvl = 5, id = 600},
{d = cf.en and "Magic absorption" or "Поглощение магии", c = 20, max = 10, lvl = 5, id = 67},
{d = cf.en and "Magic reflection" or "Отражение магии", c = 20, max = 10, lvl = 5, id = 68},
{d = cf.en and "Resist fire" or "Сопротивление огню", c = 5, max = 20, lvl = 2, id = 90},
{d = cf.en and "Resist frost" or "Сопротивление морозу", c = 5, max = 20, lvl = 2, id = 91},
{d = cf.en and "Resist lightning" or "Сопротивление молнии", c = 5, max = 20, lvl = 2, id = 92},
{d = cf.en and "Resist magic" or "Сопротивление магии", c = 5, max = 20, lvl = 2, id = 93},
{d = cf.en and "Resist poison" or "Сопротивление яду", c = 5, max = 20, lvl = 2, id = 97},
{d = cf.en and "Resist paralysis" or "Сопротивление параличу", c = 5, max = 20, lvl = 2, id = 99}}


local LEGQ = {TR_SothaSil = 100, BM_WildHunt = 100, HH_WinCamonna = 100, HR_Archmaster = 100, HT_Archmagister = 100, TG_KillHardHeart = 100, FG_KillHardHeart = 100, MG_Guildmaster = 100,
IL_Grandmaster = 100, TT_Assarnibibi = 100, MT_Grandmaster = 100, IC29_Crusher = 50}
local LVL = p.object.level		local LP = LVL + p.object.factionIndex/5		if tes3.getJournalIndex{id = "C3_DestroyDagoth"} >= 50 then LP = LP + 30 end
for id, ind in pairs(LEGQ) do if tes3.getJournalIndex{id = id} >= ind then LP = LP + 10 end end	

local M = {}	M.M = tes3ui.createMenu{id = 402, fixedFrame = true}	M.M.minHeight = 1100	M.M.minWidth = 800		local bl
M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.A.flowDirection = "top_to_bottom" 
M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
L.LegCalc = function() local bonus = 0		for i, t in ipairs(LEGT) do bonus = bonus + M[i].widget.current * t.c end	M.F.widget.current = bonus	end

for i, t in ipairs(LEGT) do bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl.borderAllSides = 1
	bl:createImage{path = t.id and "icons\\" .. tes3.getMagicEffect(t.id).bigIcon or t.pic}
	M[i] = bl:createSlider{max = math.min(math.floor(LVL/t.lvl), t.max), step = 1, jump = 1, current = D.LEG[i] or 0}	M[i].width = 400	M[i].borderRight = 10	M[i].borderLeft = 10	M[i].borderTop = 5
	M[i]:register("PartScrollBar_changed", function() M[-i].text = M[i].widget.current .. "  " .. t.d	L.LegCalc() end)
	M[-i] = bl:createLabel{text = M[i].widget.current .. "  " .. t.d}
end
M.F = M.B:createFillBar{current = 0, max = math.min(LP,100)*3}	M.F.width = 300		M.F.height = 24		M.F.widget.fillColor = {1,0,1}		L.LegCalc()

if not T.LEG.timeLeft then	M.legend = M.B:createButton{text = cf.en and "Accept bonuses" or "Закрепить бонусы"}	M.legend:register("mouseClick", function()
	if M.F.widget.max >= M.F.widget.current then		local num = 0	local EFtab = {}
		for i, t in ipairs(LEGT) do if i > 3 and M[i].widget.current > 0 then num = num + 1		EFtab[num] = {id = t.id, mag = M[i].widget.current} end end
		if num < 9 then	tes3.removeSpell{reference = p, spell = s}		for i, t in ipairs(LEGT) do D.LEG[i] = M[i].widget.current end
			if num > 0 then T.LEG = timer.start{duration = 0.3, callback = function()
				for i, ef in ipairs(s.effects) do if EFtab[i] then ef.id = EFtab[i].id	ef.min = EFtab[i].mag	ef.max = EFtab[i].mag else ef.id = -1 end end
				tes3.addSpell{reference = p, spell = s}
			end} end
			tes3.playSound{sound = "skillraise"}	M.M:destroy()	tes3ui.leaveMenuMode()	L.HPUpdate()
		else tes3.messageBox(cf.en and "You have selected too many bonuses of different types" or "Вы набрали слишком много бонусов разных типов") end
	else tes3.messageBox(cf.en and "You have selected too many bonuses" or "Вы набрали слишком много бонусов") end
end) end
M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)
tes3ui.enterMenuMode(402)
end

L.PerkReset = function() local day = wc.daysPassed.value - (D.resetday or 0)	if day > 6 then D.resetday = wc.daysPassed.value
	for id, _ in pairs(L.PA) do tes3.removeSpell{reference = p, spell = "4p_"..id, updateGUI = false} end		for id, _ in pairs(L.AA) do tes3.removeSpell{reference = p, spell = id, updateGUI = false} end
	tes3.updateMagicGUI{reference = p, updateEnchantments = false}
	QS = nil	D.perks = {}	 P = D.perks	D.QSP = {}	DM.cpt = nil	DM.cpm = nil	DM.cp = nil		L.GetArmT()		L.GetWstat()	L.HPUpdate()	L.SetGlobal()
else tes3.messageBox(cf.en and "Too early - only %d days have passed since the last reset" or "Слишком рано - с последнего сброса прошло только %d дней", day) end end
L.PerkSpells = function() for id, t in pairs(L.PA) do if P[t[3]] then tes3.addSpell{reference = p, spell = "4p_"..id, updateGUI = false} end end
for id, t in pairs(L.AA) do if P[t.p] then tes3.addSpell{reference = p, spell = id, updateGUI = false} end end	tes3.updateMagicGUI{reference = p, updateEnchantments = false} end

L.KEY = function(k) if k < 8 then return ic:isMouseButtonDown(k) else return ic:isKeyDown(k) end end
L.GetRad = function(m) return (50 + m.willpower.current/2 + m:getSkillValue(11))/((m ~= mp or P.alt13) and 20 or 40) end
L.Rcol = function(x) local c = {{math.random(x,255),x,255}, {math.random(x,255),255,x}, {x,math.random(x,255),255}, {255,math.random(x,255),x}, {x,255,math.random(x,255)}, {255,x,math.random(x,255)}}	return c[math.random(6)] end
L.GetPCmax = function() return (mp.willpower.base + mp.enchant.base) * (P.enc6 and 5 or 3) * (1 - math.min(M.ENL.normalized,1)*(P.enc15 and 0.5 or 0.75)) end
L.CrimeAt = function(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end
L.durbonus = function(dur, koef)		if dur < 1 or not P.int9 then return 1 else return 1 + koef/100 * dur^0.5 end end

L.GetSGVec = function(a,b)
	Matr:toRotationZ(math.random(a,b)/200*G.ShotGunDiv)	local vec = crot * Matr
	Matr:toRotationX(math.random(-30,30)/200*G.ShotGunDiv)	vec = vec * Matr	return vec:transpose().y
end
L.GetArcVec = function(a,b)
	Matr:toRotationZ(math.random(-a,a)/200*G.ArcDiv)	local vec = crot * Matr
	Matr:toRotationX(math.random(-b,b)/200*G.ArcDiv)	vec = vec * Matr	return vec:transpose().y
end
L.Hitp = function(x) local pos = tes3.getPlayerEyePosition()	local vec = tes3.getPlayerEyeVector()	local hit = tes3.rayTest{position = pos, direction = vec, maxDistance = 4800, ignore = {p}}
return hit and hit.intersection - vec * (x or 60) or pos + vec*4800 end
L.Hitpr = function(pos,vec,x) local hit = tes3.rayTest{position = pos, direction = vec, maxDistance = 4800, ignore = {p}}
return hit and hit.intersection - vec * (x or 60) or pos + vec*4800 end

L.TPComp = function() if D.NoTPComp then return false else		local num = 0		local cost = 0		G.TPList = {}
	for m in tes3.iterate(mp.friendlyActors) do if m ~= mp then num = num + 1
		cost = cost + (L.Summon[m.object.baseObject.id] and 10 or 20)	G.TPList[m.reference] = true		--tes3.messageBox("Name = %s  num = %s  cost = %d", m.object.name, num, cost)
	end end
	if not P.mys22 then cost = cost * 3 end		
	if num > 0 then if mp.magicka.current >= cost then Mod(cost)	tes3.messageBox("Companions = %s  manacost = %d", num, cost) return true
		else tes3.messageBox("Not enough mana! Companions = %s  manacost = %d", num, cost)	return false end
	else return false end
end end
L.TownTP = function(e) if not e:trigger() then return end		if e.effectInstance.target == p and e.effectInstance.resistedPercent < 50 and not wc.flagTeleportingDisabled then -- Телепорт в город (505) 32 максимум, 22 щас
	tes3.messageBox{message = "Where to go?", buttons = {"Nothing", "Balmora", "Ald-ruhn", "Vivec", "Sadrith Mora", "Ebonheart", "Caldera", "Suran", "Gnisis",
	"Pelagiad", "Tel Branora", "Tel Aruhn", "Tel Mora", "Maar Gan", "Molag Mar", "Dagon Fel", "Seyda Neen", "Hla Oad", "Gnaar Mok", "Khuul", "Ald Velothi", "Vos", "Tel Vos"},
	callback = function(e) if e.button ~= 0 then tes3.positionCell{reference = p, teleportCompanions = false, position = L.TPP[e.button], cell = tes3.getCell{x = 0, y = 0}}
		if L.TPComp() then timer.start{duration = 0.1, callback = function() for r, _ in pairs (G.TPList) do tes3.positionCell{reference = r, position = pp, cell = p.cell} end end} end
	end end}
	e.effectInstance.state = tes3.spellState.retired
end end
L.GetOri = function(vec1, vec2) vec1 = vec1:normalized()	vec2 = vec2:normalized()	local axis = vec1:cross(vec2)	local norm = axis:length()
	if norm < 1e-5 then return ID33:toEulerXYZ() end
	local angle = math.asin(norm)	if vec1:dot(vec2) < 0 then angle = math.pi - angle end		axis:normalize()
	local m = ID33:copy()	m:toRotation(-angle, axis.x, axis.y, axis.z)	return m:toEulerXYZ()	--return m
end
L.Sector = function(t)	local p1, d, d1, dd, ref	local dd1 = t.lim or 2000		local pos = t.pos or tes3.getPlayerEyePosition()		local v = t.v or tes3.getPlayerEyeVector()
	for r, tab in pairs(N) do p1 = r.position:copy()	p1.z = p1.z + tab.m.height/2		d = pos:distance(p1)
		if d < t.d then dd = p1:distance(pos + v*d)
			if dd < dd1 and tes3.testLineOfSight{reference1 = p, reference2 = r} and tes3.getCurrentAIPackageId(tab.m) ~= 3 then ref = r	dd1 = dd	d1 = d end
		end
	end		--if ref then tes3.messageBox("%s  Dist = %d   Dif = %d", ref, d1, dd1) end
	return ref, d1
end
L.SectorDod = function()
	for r, tab in pairs(R) do
		local ang = mp:getViewToActor(tab.m)
		if math.abs(ang) < 20 then
			L.DodM(r, tab.m, ang > 0 and -1 or 1)
		end
	end
end


L.DodM = function(r,m,k)
if not L.ASN[m.actionData.animationAttackState] and not m.isFalling then
	local ch = m.agility.current + m.sanctuary		if ch + (N[r].dod and 30 or 0) > math.random(100) then	local vec
	local spd = math.min((50 + ch/2 + m.speed.current) * (1 - math.min(m.encumbrance.normalized,1)/2) * (0.5 + m.fatigue.normalized/2), k and 200 or 250) / 15			local rot = r.sceneNode.rotation
	if k then --(rot:transpose().x * k + rot:transpose().y):normalized() * spd		
		vec = rot:transpose().x * spd * k
	--	tes3.messageBox("Dodge %s   %d%%   spd = %d", r, ch, spd*15)
	else	--local wr = m.readiedWeapon		wr = wr and (wr.object.type < 9 and wr.object.reach or 10) or 0.5
		--vec = wr - W.ra > 0.2 and rot:transpose().y * -spd or
		vec = (rot:transpose().x * table.choice{1,-1} + rot:transpose().y):normalized() * spd
	--	tes3.messageBox("Dodge %s   %d%%   spd = %d   Dash = %s  %s", r, ch, spd*15, V.daf, G.CombatDistance.value)
	end
	DOM[m] = {v = vec, fr = 15}	
end end end

L.CF.atr = function(m) local r = m.reference	local d = r.data.spawn	if d ~= 0 and m.health.normalized < d/10 - 0.2 then	local id = r.baseObject.id
	B.elemaura.effects[1].id = L.atrbot[id][1]	B.elemaura.effects[1].min = d*2	B.elemaura.effects[1].max = d*3		B.elemaura.effects[2].id = L.atrbot[id][2]	B.elemaura.effects[2].min = d*2	B.elemaura.effects[2].max = d*3
	B.elemaura.effects[3].id = L.atrbot[id][3]	B.elemaura.effects[3].min = d	B.elemaura.effects[3].max = d*2		tes3.applyMagicSource{reference = r, source = B.elemaura}	r.data.spawn = 0
end end
L.CF.dremoralord = function(m) local r = m.reference	local ch = math.random(8 - r.data.spawn*0.3)	if ch == 1 then
	tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = table.choice{105,105,105,140}, duration = 30}}}
end end
L.CF.atrlord = function(m) local r = m.reference	local d = r.data.spawn + 10		local id = r.baseObject.id
	if d > 10 and m.health.normalized < d/20 then	
		B.elemaura.effects[1].id = L.atrbot[id][1]	B.elemaura.effects[1].min = d*2	B.elemaura.effects[1].max = d*3		B.elemaura.effects[2].id = L.atrbot[id][2]	B.elemaura.effects[2].min = d*2	B.elemaura.effects[2].max = d*3
		B.elemaura.effects[3].id = L.atrbot[id][3]	B.elemaura.effects[3].min = d	B.elemaura.effects[3].max = d*2		tes3.applyMagicSource{reference = r, source = B.elemaura}	r.data.spawn = 0
	end
	if d + 5 > math.random(100) then tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = L.atrbot[id][4], duration = 30}}} end
end
L.CF.auril = function(m) local r = m.reference	local d = r.data.spawn	if d ~= 0 and m.health.normalized < 0.5 then
	if d > 8 then B.goldaura.effects[1].id = 4 elseif d < 3 then B.goldaura.effects[1].id = 6 elseif d == 3 or d == 4 then B.goldaura.effects[1].id = 5 elseif d == 5 or d == 6 then B.goldaura.effects[1].id = 3 end
	B.goldaura.effects[1].min = math.random(5,10)		B.goldaura.effects[1].max = math.random(10,30)		tes3.applyMagicSource{reference = r, source = B.goldaura}	r.data.spawn = 0
end end
L.CF.lichelder = function(m) local r = m.reference	local ch = math.random(7 - r.data.spawn*0.3)
	if ch == 1 then for ref in tes3.iterate(r.cell.actors) do if ref.object.objectType == tes3.objectType.creature and ref.object.type == 2 and ref.mobile.isDead and r.position:distance(ref.position) < 1000 then
		if 100 - ref.object.level * 5 > math.random(100) then tes3.runLegacyScript{command = "resurrect", reference = ref}	tes3.playSound{sound = "conjuration hit", reference = ref} end end end
	elseif ch == 2 then for ref in tes3.iterate(r.cell.actors) do if ref.object.objectType == tes3.objectType.creature and ref.object.type == 2 and r.position:distance(ref.position) < 1000 then
		tes3.applyMagicSource{reference = ref, source = "p_restore_health_s"} end end
	elseif ch == 3 then tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = table.choice{108,108,109,110,142,142}, duration = 60}}} end
end
L.CF.lich = function(m) local r = m.reference	local ch = math.random(7 - r.data.spawn*0.3)	if ch == 1 then
	tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = table.choice{107,107,106,109,142}, duration = 30}}}
	--tes3.createReference{object = L.UndMinion[math.random(4)], position = (r.position + r.orientation*300), cell = r.cell}		tes3.playSound{sound = "conjuration hit", reference = r}
elseif ch == 2 then tes3.applyMagicSource{reference = r, source = "p_restore_health_c"} end end
L.CF.ashascend = function(m) if mwscript.getSpellEffects{reference = p, spell = "corprus immunity"} == false and m.position:distance(pp) < 1000 then local ch = math.random(6)
	if ch < 5 then mwscript.addSpell{reference = p, spell = L.Blight[ch]}	tes3.messageBox("The blight aura emitted by this creature has hit you!") end
end end
L.CFF = {["atronach_flame"] = L.CF.atr, ["atronach_flame_summon"] = L.CF.atr, ["atronach_frost"] = L.CF.atr, ["atronach_frost_summon"] = L.CF.atr, ["atronach_storm"] = L.CF.atr, ["atronach_storm_summon"] = L.CF.atr,
["atronach_flame_lord"] = L.CF.atrlord, ["atronach_frost_lord"] = L.CF.atrlord, ["atronach_storm_lord"] = L.CF.atrlord,	["dremora_lord"] = L.CF.dremoralord,
["golden saint"] = L.CF.auril, ["golden saint_summon"] = L.CF.auril, ["lich"] = L.CF.lich, ["lich_elder"] = L.CF.lichelder, ["ascended_sleeper"] = L.CF.ashascend}

L.TTAR = function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt.flowDirection = "top_to_bottom"
tt:createLabel{text = ("%s: %d  %s"):format(cf.en and "lightness:" or "Легкость:", math.max(-mp.encumbrance.currentRaw,0), cf.en and "Armor parts:" or "Части брони:")}
tt:createLabel{text = ("%s: %d"):format(cf.en and "Light" or "Легкие", D.AR.l)}
tt:createLabel{text = ("%s: %d"):format(cf.en and "Medium" or "Средние", D.AR.m)}
tt:createLabel{text = ("%s: %d"):format(cf.en and "Heavy" or "Тяжелые", D.AR.h)}
tt:createLabel{text = ("%s: %d"):format(cf.en and "Unarmored" or "Бездоспешные", D.AR.u)}
tt:createLabel{text = cf.en and "Speed:" or "Скорость:"}
tt:createLabel{text = ("%s: %d"):format(cf.en and "Base" or "База", (100 + mp.speed.current) * (mp.alwaysRun and (3 + mp:getSkillValue(8)/100) or 1))}
tt:createLabel{text = ("%s: %d%%"):format(cf.en and "Armor" or "Доспехи", math.min(D.AR.ms + math.max(-mp.encumbrance.currentRaw,0)/2000, 1)*100)}
tt:createLabel{text = ("%s: %d%%"):format(cf.en and "Encumbrance" or "Нагрузка", 100 * (1 - mp.encumbrance.normalized/2) * (P.atl3 and 1 or 1 - mp.encumbrance.normalized/3))}
tt:createLabel{text = ("%s: %d%%"):format(cf.en and "Fatigue" or "Усталость", 100 * (mp.alwaysRun and (1 - (1 - math.min(mp.fatigue.normalized,1)) * (P.atl2 and 0.25 or 0.5)) or 1))}
tt:createLabel{text = ("%s: %d%%"):format(cf.en and "Move type" or "Тип движения", 100
* (mp.alwaysRun and (ad.animationAttackState == 2 and (P.spd10 and 0.8 or 2/3) or 1) * (P.spd0 and mp.isMovingForward and not (mp.isMovingLeft or mp.isMovingRight) and 1 or 0.75) or 1)
* (mp.isMovingBack and (P.agi16 and math.min(0.5 + mp.agility.current/400, 0.75) or 0.5) or ((mp.isMovingLeft or mp.isMovingRight) and not mp.isMovingForward and 0.75 or 1))		)}
end
L.GetArStat = function()
local w = mp.readiedWeapon	w = w and w.object		local wt = W.wt		local WS = mp:getSkillValue(WT[wt].s)		--(W.wt < -1 and W.wt) or (w and w.type) or -1	
local agi = mp.agility.current	local enc = mp.encumbrance.normalized	local lig = math.max(-mp.encumbrance.currentRaw,0)/2000		local stam = math.min(mp.fatigue.normalized,1)
local sp = mp.currentSpell or tes3.getObject("flame")	local sc = sp.magickaCost and sp:getLeastProficientSchool(mp) or sp.effects[1].object.school	local MS = mp:getSkillValue(SP[sc].s)	local eid = sp.effects[1].id

M.ST11.text = ("%s/%s/%s/%s"):format(D.AR.l, D.AR.m, D.AR.h, D.AR.u)
M.ST12.text = math.ceil(	(100 + mp.speed.current) * math.min(D.AR.ms + lig, 1) * (1 - enc/2) * (P.atl3 and 1 or 1 - enc/3)
* (mp.alwaysRun and (3 + mp:getSkillValue(8)/100) * (1 - (1 - stam) * (P.atl2 and 0.25 or 0.5)) * (ad.animationAttackState == 2 and (P.spd10 and 0.8 or 2/3) or 1)
* (P.spd0 and mp.isMovingForward and not (mp.isMovingLeft or mp.isMovingRight) and 1 or 0.75) or 1)
* (mp.isMovingBack and (P.agi16 and math.min(0.5 + agi/400, 0.75) or 0.5) or ((mp.isMovingLeft or mp.isMovingRight) and not mp.isMovingForward and 0.75 or 1))		)


M.ST21.text = ("%d%%"):format( (100 + mp.strength.current * (P.str1 and 0.5 or 0.4) + mp.attackBonus/5 + WS * ((P[WT[wt].p1] and 0.2 or 0.1) + (P[WT[wt].h1 and "agi5" or "str2"] and 0.1 or 0.05)))
* math.min(math.lerp((P.end1 and 0.4 or 0.3) + (P[WT[wt].p2] and 0.2 or 0), 1, stam*1.1), 1)
* (w and w.weight == 0 and 1 + mp:getSkillValue(13)*(P.con8 and 0.003 or 0.002) or 1) )
M.ST22.text = ("%d%% / %d"):format(100 * (0.9 + mp.speed.current/(P.spd1 and 1000 or 2000) + mp:getSkillValue(WT[wt].s)/(P[WT[wt].p4] and 1000 or 2000)
- math.max(D.AR.as + enc * (P.atl12 and 0.1 or 0.2) - lig, 0) - (1 - stam) * (P.atl11 and 0.1 or 0.2)),
(P[WT[wt].pc] and 4 or 3) + math.floor(WS/50) + (P.spd14 and W.DWM and 1 or 0))


local Cfocus = mp.spellReadied and P.wil5 and 1 + mp.magicka.current/(100 + mp.magicka.current/10)/100 or 1
local Cstam = math.min(math.lerp((P.wil2 and 0.4 or 0.3) + (P[SP[sp.objectType == tes3.objectType.enchantment and "enc5" or SP[sc].p3]] and 0.2 or 0), 1, stam*1.1), 1)
local Cbonus = MS/(P[MEP[eid] and MEP[eid].p0 or SP[sc].p1] and 5 or 10) + (P[MEP[eid] and MEP[eid].p or "mys0"] and mp:getSkillValue(MEP[eid] and MEP[eid].s or 14)/10 or 0)
if sp.objectType == tes3.objectType.enchantment then Cbonus = Cbonus/3 + mp:getSkillValue(9)/(P.enc1 and 5 or 10) end
if ME[eid] == "shield" and P.una7 then Cbonus = Cbonus + D.AR.u * mp:getSkillValue(17)/100 end
Cbonus = Cbonus + mp.willpower.current/(P.wil1 and 5 or 10)

M.ST31.text = ("%d%%"):format((100 + Cbonus) * Cfocus * Cstam)
M.ST32.text = ("%d%%"):format(sp.alwaysSucceeds and 100 or 100 * math.max(1 - (P.int15 and math.max((0.5 - mp.magicka.normalized)*0.1, 0) or 0)
- MS/(P[SP[sc].p4] and 1000 or 2000) - (P.mys10 and 0.05 or 0) + (D.AR.mc > 0 and math.max(D.AR.mc - lig, 0) or D.AR.mc), 0.5))
M.ST33.text = math.ceil( (P[SP[sc].p2] and MS/5 or 0) + (P.int8 and mp.spellReadied and (mp.intelligence.current + MS)/10 or 0) + (P.int6 and mp.intelligence.current/10 or 0) + (P.luc13 and mp.luck.current/10 or 0)
- (P.wil10 and 0 or M.MCB.normalized*20) + (D.AR.cc > 0 and D.AR.cc or math.min(D.AR.cc + lig*2, 0)) - enc * (P.end17 and 10 or 20) )

--(2 + (mp.willpower.current + agi)/(P.wil15 and 100 or 200) - enc*(P.end15 and 0.5 or 1) + D.AR.cs) * 10		-- скорость зарядки спеллов

local sanct = mp.sanctuary/5 * (1+(P.una11 and D.AR.u*0.01 or 0))
M.ST41.text = ("%d/%d/%d"):format(math.min(stam * (D.AR.dk > 1 and D.AR.dk or math.min(D.AR.dk + lig*2, 1)) * (agi*(P.agi20 and 0.3 or 0.2) + (P.luc3 and mp.luck.current/10 or 0))
+ sanct + (P.acr6 and mp.isJumping and mp:getSkillValue(20)/5 or 0), 100),
(agi/(1+agi/400)/(P.agi2 and 8 or 16) + (P.lig2 and D.AR.l * mp:getSkillValue(21)/100 or 0) + (P.agi23 and W.DWM and 10 or 0) + sanct) * (P.spd2 and 2 or 1),
(P.agi4 and 40 or 50) * (1 + enc*(P.agi14 and 0.5 or 1) + (D.AR.dc < 0 and D.AR.dc or math.max(D.AR.dc - lig*2,0))))

M.ST42.text = ("%d/%d/%d"):format(10 + 10 * enc + (w and w.weight or 0) - (P[WT[wt].p3] and WS/20 or 0) - (P.end6 and math.min(mp.endurance.current/20, 5) or 0),
tes3.findGMST("fFatigueJumpBase").value + tes3.findGMST("fFatigueJumpMult").value * enc, 10 + 30 * enc)
end

L.GetWstat = function() local w = mp.readiedWeapon		w = w and w.object		local wt = w and w.type or -1		local wid = w and w.id		W.wt = wt		W.w = w
if w then	W.v = mp.readiedWeapon.variables	local en = w.enchantment		if not D.lw then D.lw = {id = wid, r = w.reach} end	
	if wid == D.lw.id then
		if wid:sub(1,2) == "4_" then local Old = tes3.getObject(wid:sub(3))	if Old then
			if wt == 1 then	if Old.type == 6 then wt = -2	W[wid] = -2 end		elseif wt == 3 then	if Old.type == 5 then wt = -3	W[wid] = -3 end end		W.wt = wt
		end end
		if wt < 9 then w.reach = D.lw.r + math.floor(((P.agi3 and mp.agility.base/2000 or 0) + (P[WT[wt].p7] and 0.05 or 0))*100)/100 end
		W.ra = wt < 9 and w.reach or 10
		if en and en.castType == 1 and wt < 11 then	W.ob = w		W.en = en		W.BAR.visible = true	W.bar.max = W.en.maxCharge	W.f = nil
			for i, eff in ipairs(W.en.effects) do if wt < 9 then if (eff.rangeType == 2 or ME[eff.id] == "shotgun" or ME[eff.id] == "ray") then W.f = 1 break end elseif eff.rangeType == 1 then W.f = 1 break end end
			if not W.f and wt > 8 then W.f = 2 end
		end
		if cf.m8 then tes3.messageBox("%s  Reach = %.2f (%.2f)   %s", w.name, W.ra, D.lw.r, W.f and (W.f == 2 and "Explode arrow!" or "Enchant strike!") or "") end
	end
else W.ra = 0.5 end
end

L.GetArmT = function() D.AR = {l=0,m=0,h=0,u=0}	for i, val in pairs(L.ARW) do	local s = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = i}
if (i == 6 or i == 7) and not s then s = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = i+3} end	s = AT[s and s.object.weightClass or 3].t		D.AR[s] = D.AR[s] + val end
local Sl, Sm, Sh, Su = mp.lightArmor.base, mp.mediumArmor.base, mp.heavyArmor.base, mp.unarmored.base
D.AR.ms = 1 - D.AR.m*0.005*(1 - Sm/(P.med2 and 200 or 400)) - D.AR.h*0.01*(1 - Sh/(P.hev2 and 200 or 400))
D.AR.as = D.AR.m*0.005*(1 - Sm/(P.med3 and 200 or 400)) + D.AR.h*0.01*(1 - Sh/(P.hev3 and 200 or 400))
D.AR.dk = 1 + D.AR.u*0.01*Su/(P.una5 and 100 or 200) - D.AR.l*0.02*(1 - Sl/(P.lig5 and 100 or 200)) - D.AR.m*0.02*(1 - Sm/(P.med5 and 200 or 400)) - D.AR.h*0.04*(1 - Sh/(P.hev5 and 200 or 400))
D.AR.dc = 0 - D.AR.u*0.01*Su/(P.una6 and 100 or 200) + D.AR.l*0.02*(1 - Sl/(P.lig6 and 100 or 200)) + D.AR.m*0.02*(1 - Sm/(P.med6 and 200 or 400)) + D.AR.h*0.04*(1 - Sh/(P.hev6 and 200 or 400))
D.AR.cs = D.AR.u*0.04*Su/(P.una4 and 100 or 200) - D.AR.l*0.02*(1 - Sl/(P.lig4 and 100 or 200)) - D.AR.m*0.03*(1 - Sm/(P.med4 and 100 or 200)) - D.AR.h*0.04*(1 - Sh/(P.hev4 and 100 or 200))
D.AR.cc = (P.una12 and D.AR.u > 19 and 25 or 0) + D.AR.u*Su/(P.una1 and 100 or 500) - D.AR.l*(1 - Sl/(P.lig1 and 100 or 200)) - D.AR.m*(1 - Sm/(P.med1 and 200 or 400)) - D.AR.h*2*(1 - Sh/(P.hev1 and 200 or 400))
D.AR.mc = 0 - (P.una12 and D.AR.u > 19 and 0.05 or 0) - (P.una3 and D.AR.u*Su/50000 or 0) + D.AR.l*0.002*(1 - Sl/(P.lig15 and 100 or 200)) + D.AR.m*0.004*(1 - Sm/(P.med15 and 200 or 400)) + D.AR.h*0.006*(1 - Sh/(P.hev15 and 200 or 400))
L.GetArStat()
end
L.UpdShield = function(sh)
	if T.Shield.timeLeft then T.Shield:reset() else T.Shield = timer.start{duration = 10, callback = function() M.SHbar.visible = false end} end
	M.SHbar.widget.max = sh.object.maxCondition		M.SHbar.widget.current = sh.variables.condition		M.SHbar.visible = true
end
L.M180 = tes3matrix33.new()		L.M180:toRotationX(math.rad(180))
L.MagefAdd = function()		p1 = tes3.player1stPerson.sceneNode
G.arm1 = p1:getObjectByName("Bip01 R Finger2")	G.arm1:attachChild(L.magef:clone())		G.arm1 = G.arm1:getObjectByName("magef")	G.arm1.appCulled = true
G.arm2 = p1:getObjectByName("Bip01 L Finger2")	G.arm2:attachChild(L.magef:clone())		G.arm2 = G.arm2:getObjectByName("magef")	G.arm2.appCulled = true		end
L.Cul = function(x) W.w1.appCulled = x	W.w3.appCulled = x	W.wl1.appCulled = not x		W.wl3.appCulled = not x		W.wr1.appCulled = not x		W.wr3.appCulled = not x	end
L.GetConEn = function(arm, en) local E = arm == 1 and "ER" or "EL"	if en and en.castType == 3 then W[E] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}}
	for i, ef in ipairs(en.effects) do W[E][i].id = ef.id	W[E][i].min = ef.min	W[E][i].max = ef.max	W[E][i].radius = ef.radius	W[E][i].duration = 36000	W[E][i].attribute = ef.attribute	W[E][i].skill = ef.skill end	
else W[E] = nil end end
L.DWNEW = function(o, od, left)	if left then
	W.wl1 = tes3.loadMesh(o.mesh):clone()	W.wl1.translation = W.w1.translation:copy()		W.wl1.translation.z = W.wl1.translation.z*-1	W.wl1.rotation = W.w1.rotation:copy() * L.M180	W.wl3 = W.wl1:clone()
	W.WL = o	W.DL = od	W.DL.tempData.DW = 2	L.GetConEn(2, o.enchantment)	if cf.m then tes3.messageBox("Left weapon remembered: %s", o.name)	end		if W.WR then L.DWMOD(true) end
else W.wr1 = tes3.loadMesh(o.mesh):clone()	W.wr1.translation = W.w1.translation:copy()		W.wr1.rotation = W.w1.rotation:copy()	W.wr3 = W.wr1:clone()
	W.WR = o	W.DR = od	W.DR.tempData.DW = 1	L.GetConEn(1, o.enchantment)	if W.WL then L.DWMOD(true) end
end end
L.ClearEn = function() local si	if D.DWER then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWER}	if si then si.state = 6 end D.DWER = nil end
if D.DWEL then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWEL}	if si then si.state = 6 end D.DWEL = nil end end
L.DWESound = function(e) if W.snd and (e.item == W.WR or e.item == W.WL) then W.snd = nil return false end end
L.DWMOD = function(st) if st then 
	if not W.DWM then if W.WR and W.WL and inv:contains(W.WR, W.DR) and W.DR.condition > 0 and inv:contains(W.WL, W.DL) and W.DL.condition > 0 then
		tes3.loadAnimation{reference = tes3.player1stPerson, file = "dw_merged.nif"}		L.MagefAdd()
		p1 = tes3.player1stPerson.sceneNode		W.l1 = p1:getObjectByName("Bip01 L Hand")	W.r1 = p1:getObjectByName("Bip01 R Hand")	W.w1 = p1:getObjectByName("Weapon Bone")
		local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object		mp:unequip{armorSlot = 8}	mp:unequip{type = tes3.objectType.light}	L.ClearEn()
		W.l1:attachChild(W.wl1)		W.wl1:updateNodeEffects()	W.l3:attachChild(W.wl3)		W.wl3:updateNodeEffects()	W.r1:attachChild(W.wr1)		W.wr1:updateNodeEffects()	W.r3:attachChild(W.wr3)		W.wr3:updateNodeEffects()
		L.Cul(true)		W.DWM = true	event.register("playItemSound", L.DWESound, {priority = 10000})		if cf.m then tes3.messageBox("Double weapons! %s and %s", W.WR, W.WL) end
		if W.ER then D.DWER = (tes3.applyMagicSource{reference = p, name = "Enchant_right", effects = W.ER}).serialNumber end
		if W.EL then D.DWEL = (tes3.applyMagicSource{reference = p, name = "Enchant_left", effects = W.EL}).serialNumber end
		if W.ER and w == W.WR and wd == W.DR then mp:equip{item = W.WL, itemData = W.DL} elseif W.EL and w == W.WL and wd == W.DL or (w ~= W.WR and w ~= W.WL) then mp:equip{item = W.WR, itemData = W.DR} end
	else if cf.m then tes3.messageBox("Weapons not prepared! %s and %s", W.WR, W.WL) end		W.WL = nil	 W.DL = nil	end end
elseif W.DWM then L.ClearEn()		tes3.loadAnimation{reference = tes3.player1stPerson, file = nil}		L.MagefAdd()
	W.l1:detachChild(W.wl1)		W.l3:detachChild(W.wl3)		W.r1:detachChild(W.wr1)		W.r3:detachChild(W.wr3)
	L.Cul(false)	W.DWM = false	event.unregister("playItemSound", L.DWESound, {priority = 10000})	if cf.m then tes3.messageBox("DW mod off") end
end end

local TSK = 1	--local function SIMTS() wc.deltaTime = wc.deltaTime * TSK end
L.UpdTSK = function() local pow = Mag(510)
if pow == 0 then TSK = 1 else TSK = math.max(1 - pow/(pow + 40), P.ill8 and 0.1 or 0.2) end
wc.simulationTimeScalar = TSK
--tes3.messageBox("TSK = %s ", wc.simulationTimeScalar)
end

local function DETERMINEACTION(e)	if e.session.selectedAction ~= 0 and L.CFF[e.session.mobile.reference.baseObject.id] then L.CFF[e.session.mobile.reference.baseObject.id](e.session.mobile)
--tes3.messageBox("ФУНКЦИЯ! %s  выбор = %s", e.session.mobile.reference, e.session.selectedAction)
end end		if cf.full then event.register("determineAction", DETERMINEACTION) end
local function COMBATSTART(e) if e.target == mp then
	if L.CID[e.actor.reference.baseObject.id] == "dwem" and tes3.isAffectedBy{reference = p, object = "summon_centurion_unique"} then return false end
end end		event.register("combatStart", COMBATSTART)
local function DEATH(e) local r = e.reference
	if L.CID[r.baseObject.id] == "zombirise" and r.data.spawn ~= 0 then 
		if r.object.level * 5 > math.random(100) then timer.start{duration = math.random(5,10), callback = function() if r.mobile.isDead then
			tes3.runLegacyScript{command = "resurrect", reference = r}		tes3.playSound{sound = "bonewalkerSCRM", reference = r}		r.data.spawn = 0
			e.mobile.health.current = e.mobile.health.base/2	e.mobile.magicka.current = e.mobile.magicka.base/2	e.mobile.fatigue.current = e.mobile.fatigue.base/2
		end end} end
	end
end		event.register("death", DEATH)




L.CWF = function(r, rt, k, pos)		k = r == p and (P.mys7e and k*0.8 or k) or k/3
	local M = {tes3.getEffectMagnitude{reference = r, effect = 511}, tes3.getEffectMagnitude{reference = r, effect = 512}, tes3.getEffectMagnitude{reference = r, effect = 513},
	tes3.getEffectMagnitude{reference = r, effect = 514}, (tes3.getEffectMagnitude{reference = r, effect = 515})}
	local mc = (M[1]*0.3 + M[2]*0.3 + M[3]*0.4 + M[4]*0.5 + M[5]*0.4) * k		local mob = r.mobile
	if mc == 0 then r.data.CW = nil elseif mob.magicka.current > mc then local rad = rt == 2 and L.GetRad(mob)		local E = B.CW.effects
		for i, m in ipairs(M) do if m > 0 then E[i].id = MID[i]  E[i].min = m   E[i].max = m	E[i].rangeType = rt		E[i].duration = 1	E[i].radius = rad or 0	else E[i].id = -1	E[i].rangeType = 0 end end
		if pos then MP[tes3.applyMagicSource{reference = r, source = B.CW}] = {pos = pos, exp = true} else tes3.applyMagicSource{reference = r, source = B.CW} end
		Mod(mc, mob)		if cf.m then tes3.messageBox("CW = %d + %d + %d + %d + %d   Manacost = %.1f (%d%%)", M[1], M[2], M[3], M[4], M[5], mc, k*100) end
	end
end

local BAM = {[9] = "4nm_boundarrow", [10] = "4nm_boundbolt", ["met"] = "4nm_boundstar", ["4nm_boundarrow"] = 9, ["4nm_boundbolt"] = 10, ["4nm_boundstar"] = true}		BAM.f = function() return P.con10 and 10 or 15 end
local DER = {}	local function DEDEL() for r, ot in pairs(DER) do if r.sceneNode then r.sceneNode:detachChild(r.sceneNode:getObjectByName("detect"))	r.sceneNode:update()	r.sceneNode:updateNodeEffects() end end		DER = {} end

local function CMSFrost(e) e.speed = e.speed * (FR[e.reference] or 1) end
local function ConstEnLim()	D.ENconst = 0
	for _, s in pairs(p.object.equipment) do if s.object.enchantment and s.object.enchantment.castType == 3 then
		if s.object.objectType == tes3.objectType.clothing then D.ENconst = D.ENconst + math.max(L.CLEN[s.object.slot] or 0, s.object.enchantCapacity)
		elseif s.object.objectType == tes3.objectType.armor then D.ENconst = D.ENconst + math.max(L.AREN[s.object.slot] or 0, s.object.enchantCapacity) end
	end end		M.ENL.current = D.ENconst		M.PC.max = L.GetPCmax()
end


L.METW = function(e) if not e:trigger() then return end		local si = e.sourceInstance		local sn = si.serialNumber	local dmg, wd	local r = e.effectInstance.target		local m = r.mobile
	if V.MET[sn] then dmg = V.MET[sn].dmg	wd = V.MET[sn].r.attachments.variables		V.MET[sn] = nil elseif si == W.TETsi then dmg = W.TETdmg * Cpow(mp,0,4,true)/100		W.TETsi = nil	W.TETmod = 3
		if M.MCB.normalized > 0 then dmg = dmg * (1 + M.MCB.normalized * (P.wil7 and 0.2 or 0.1))		M.MCB.current = 0 end	wd = W.TETR.object.hasDurability and W.TETR.attachments.variables
	end
	if dmg then local CritC = mp.attackBonus/5 + mp:getSkillValue(23)/(P.mark6c and 10 or 20) + mp.agility.current/(P.agi1 and 10 or 20) + (P.luc1 and mp.luck.current/20 or 0)
		+ (m.isMovingForward and 10 or 0) - (m.endurance.current + m.agility.current + m.luck.current)/20 - m.sanctuary/10 + math.max(1-m.fatigue.normalized,0)*(P.agi11 and 20 or 10) - 10
		local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + (P.agi8 and 10 or 0) + (P.mark5c and 20 or 0) end
		if Kcrit > 0 then dmg = dmg * (1 + Kcrit/100)		tes3.playSound{reference = r, sound = "critical damage"} end
		dmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}	--resistAttribute = not (w.enchantment or w.ignoresNormalWeaponResistance) and 12 or nil
		if wd then wd.condition = math.max(wd.condition - dmg * tes3.findGMST("fWeaponDamageMult").value, 0) end
		if cf.m3 then tes3.messageBox("Throw! %s  dmg = %d  Crit = %d%% (%d%%)", r.object.name, dmg, Kcrit, CritC) end
	end		e.effectInstance.state = tes3.spellState.retired
end

L.SimMET = function(e)
for r, t in pairs(V.METR) do if t.f then
	r.position = r.position:interpolate(pp, wc.deltaTime * (P.alt19 and 1500 or 1000))
	if pp:distance(r.position) < 150 then local ob = r.object	p:activate(r)		if not mp.readiedWeapon	then timer.delayOneFrame(function() mp:equip{item = ob} end) end	V.METR[r] = nil end
end end
if table.size(V.METR) == 0 then event.unregister("simulate", L.SimMET)	W.metflag = nil end
end

local function SIMTEL(e) if W.TETR then
	if W.TETmod == 1 then W.TETR.position = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*150 + tes3vector3.new(0,0,-30)		W.TETR.orientation = p.orientation
	elseif W.TETmod == 2 then W.TETR.position = W.TETP.position		W.TETR.orientation = p.orientation
	elseif W.TETmod == 3 then W.TETR.position = W.TETR.position:interpolate(pp, wc.deltaTime* (P.alt19 and 1500 or 1000))
		if pp:distance(W.TETR.position) < 150 then W.TETmod = 1	tes3.playSound{sound = "enchant fail"}		local ob = W.TETR.object		if ob.hasDurability and W.TETR.attachments.variables then
		W.TETdmg = math.max(math.max(ob.slashMax, ob.chopMax, ob.thrustMax) * math.max(W.TETR.attachments.variables.condition/ob.maxCondition, P.arm2 and 0.3 or 0.1), ob.weight/2) end end
	end
else event.unregister("simulate", SIMTEL) 	W.TETP = nil	W.TETmod = nil	end end

local function TELnew(r)
if W.TETmod then local hit = tes3.rayTest{position = W.TETR.position, direction = V.down}	if hit then W.TETR.position = hit.intersection + tes3vector3.new(0,0,5) end
if cf.m then tes3.messageBox("%s no longer under control", W.TETR.object.name) end		event.unregister("simulate", SIMTEL) 	W.TETmod = nil	W.TETR = nil	W.TETP = nil	W.TETsi = nil end		
if r.stackSize == 1 and tes3.isAffectedBy{reference = p, effect = 506} then	local ob = r.object		local wd = r.attachments.variables
	W.TETcost = 5 + ob.weight		W.TETR = r		W.TETmod = 1	event.register("simulate", SIMTEL)
	if not tes3.hasOwnershipAccess{target = r} then tes3.triggerCrime{value = ob.value, type = 5, victim = wd.owner} end
	W.TETdmg = (ob.objectType == tes3.objectType.weapon and (ob.type < 9 or ob.type > 10) or ob.objectType == tes3.objectType.ammunition) and
	math.max(math.max(ob.slashMax, ob.chopMax, ob.thrustMax) * (wd and math.max(wd.condition/ob.maxCondition, P.arm2 and 0.3 or 0.1) or 1), ob.weight/2) or math.max(ob.weight/2, 1)
	if cf.m then tes3.messageBox("%s under control!  weight = %.1f  dmg = %.1f", ob.name, ob.weight, W.TETdmg) end
end end


local LI = {R = {}}
LI.SIM = function()	if LI.r then if LI.r.cell ~= p.cell then LI.r:delete()	LI.New(T.LI.iterations, pp)
else local pos = pp:copy()	pos.z = pos.z + 200 + LI.l.radius/50	LI.r.position = LI.r.position:interpolate(pos, 5 + LI.r.position:distance(pos)/20) end end end
LI.New = function(dur, spos) if LI.r then LI.l.radius = Mag(504) else event.register("simulate", LI.SIM) end
	LI.r = tes3.createReference{object = "4nm_light", scale = math.min(1+LI.l.radius/1000, 9), position = spos, cell = p.cell}	LI.r.modified = false
	if not T.LI.timeLeft then T.LI = timer.start{duration = 1, iterations = dur, callback = function()
		if T.LI.iterations == 1 then event.unregister("simulate", LI.SIM)	LI.r:delete()	T.LI:cancel()	LI.r = nil else LI.r:disable()	LI.r:enable()	LI.r.modified = false end
	end} end
end

local function LightCollision(e) if e.sourceInstance.caster == p then -- Фонарь (504)
local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	local pos = e.collision.point:copy()	pos.z = pos.z + 5	local col = L.Rcol(cf.col)
LI.l.color[1] = col[1]		LI.l.color[2] = col[2]		LI.l.color[3] = col[3]		LI.l.radius = math.random(ef.min, ef.max) * Cpow(mp,0,0) * (SN[e.sourceInstance.serialNumber] or 1)
local LTR = tes3.createReference{object = "4nm_light", scale = math.min(1+LI.l.radius/1000, 9), position = pos, cell = p.cell}	LTR.modified = false	LI.R[LTR] = true
timer.start{duration = ef.duration, callback = function() LI.R[LTR] = nil	LTR:delete() end}
if cf.m then tes3.messageBox("Light active! Radius = %d   Time = %d	  Total = %d", LI.l.radius, ef.duration, table.size(LI.R)) end
end end


L.AuraTik = function()	local M = {tes3.getEffectMagnitude{reference = p, effect = 516}, tes3.getEffectMagnitude{reference = p, effect = 517}, tes3.getEffectMagnitude{reference = p, effect = 518},
tes3.getEffectMagnitude{reference = p, effect = 519}, (tes3.getEffectMagnitude{reference = p, effect = 520})}		local mc = (M[1]*0.3 + M[2]*0.3 + M[3]*0.4 + M[4]*0.5 + M[5]*0.4) * (P.mys7c and 2.5 or 3)
if mc > 0 then if not D.Aurdis then local E = B.AUR.effects		local MTab = {}		local rad = (50 + mp.willpower.current/2 + mp:getSkillValue(11)) * (P.alt12 and 3 or 2)
	for i, mag in ipairs(M) do if mag > 0 then E[i].id = MID[i]  E[i].min = mag		E[i].max = mag	E[i].duration = 3 else E[i].id = -1 end end
	for _, m in pairs(tes3.findActorsInProximity{reference = p, range = rad}) do if m ~= mp and (cf.agr or m.actionData.target == mp) and tes3.getCurrentAIPackageId(m) ~= 3 then MTab[m.reference] = m end end
	local num = table.size(MTab)
	if num > 0 then local mcs = mc * num/(1 + (num-1)/(P.alt5a and 3 or 5))		if mp.magicka.current > mcs then Mod(mcs)
		for r, m in pairs(MTab) do SNC[(tes3.applyMagicSource{reference = r, source = B.AUR}).serialNumber] = mp		L.CrimeAt(m) end
		if cf.m then tes3.messageBox("Aura = %d + %d + %d + %d + %d   Rad = %d  Cost = %.1f (%.1f  %d targets)", M[1], M[2], M[3], M[4], M[5], rad, mcs, mc, num) end
	end end
end else T.AUR:cancel()		D.AUR = nil end
end

L.ExpSpell = function()	local M = {tes3.getEffectMagnitude{reference = p, effect = 531}, tes3.getEffectMagnitude{reference = p, effect = 532}, tes3.getEffectMagnitude{reference = p, effect = 533},
tes3.getEffectMagnitude{reference = p, effect = 534}, (tes3.getEffectMagnitude{reference = p, effect = 535})}		local mc = (M[1]*0.3 + M[2]*0.3 + M[3]*0.4 + M[4]*0.5 + M[5]*0.4) * (P.mys7d and 1.2 or 1.5)
if mc > 0 then if mp.magicka.current > mc then	local rad = math.random(5) + L.GetRad(mp)
	for i, mag in ipairs(M) do if mag > 0 then G.EXP[i].id = MID[i]  G.EXP[i].min = mag   G.EXP[i].max = mag	G.EXP[i].radius = rad	G.EXP[i].duration = 1	G.EXP[i].rangeType = 2 else G.EXP[i].id = -1	G.EXP[i].rangeType = 0 end end
	Mod(mc)		if cf.m then tes3.messageBox("Explode = %d + %d + %d + %d + %d   Rad = %d   Cost = %.1f", M[1], M[2], M[3], M[4], M[5], rad, mc) end
end else D.Exp = nil end
end

L.RechargeTik = function() if G.REI then	local mag = Mag(501)	if mag == 0 then AF[p].T501:cancel()	AF[p].T501 = nil else		pow = mag * (1 + (P.enc4 and mp:getSkillValue(9)/400 or 0))
	if W.ob and W.v.charge < W.en.maxCharge then W.v.charge = math.min(W.v.charge + pow, W.en.maxCharge)
		if cf.m2 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s charges = %d/%d", pow, mag, W.ob.name, W.v.charge, W.en.maxCharge) end
	else	local cen = mp.currentEnchantedItem		local cida = cen and cen.itemData
		if cida and cida.charge < cen.object.enchantment.maxCharge then cida.charge = math.min(cida.charge + pow, cen.object.enchantment.maxCharge)
			if cf.m2 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s charges = %d/%d", pow, mag, cen.object.name, cida.charge, cen.object.enchantment.maxCharge) end
		else
			if not (G.REI.ob and inv:contains(G.REI.ob, G.REI.ida)) then	G.REI = {}
				for i, ri in pairs(wc.rechargingItems) do if inv:contains(ri.object, ri.itemData) then G.REI = {ob = ri.object, ida = ri.itemData, max = ri.enchantment.maxCharge}	break end end
			end
			if G.REI.ob then	G.REI.ida.charge = math.min(G.REI.ida.charge + pow, G.REI.max)
				if cf.m2 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s charges = %d/%d", pow, mag, G.REI.ob.name, G.REI.ida.charge, G.REI.max) end
				if G.REI.max == G.REI.ida.charge then G.REI = {} end
			else G.REI = nil end
		end
	end		--tes3.messageBox("Recharge Tick")
end end end

L.RechargeNPC = function(m, t) local mag = Mag(501,t)	if mag == 0 then AF[t].T501:cancel()	AF[t].T501 = nil else
	local w = m.readiedWeapon	local v = w and w.variables		local en = w and w.object.enchantment
	if v and en and v.charge < en.maxCharge then v.charge = math.min(v.charge + mag, en.maxCharge)
		if cf.m2 then tes3.messageBox("Pow = %.1f  %s charges = %d/%d", mag, w.object.name, v.charge, en.maxCharge) end
	else for _, st in pairs(t.object.equipment) do v = st.variables		en = st.object.enchantment	if v and en and v.charge < en.maxCharge then v.charge = math.min(v.charge + mag, en.maxCharge)
		if cf.m2 then tes3.messageBox("Pow = %.1f  %s charges = %d/%d", mag, st.object.name, v.charge, en.maxCharge) end break
	end end end	
end end
