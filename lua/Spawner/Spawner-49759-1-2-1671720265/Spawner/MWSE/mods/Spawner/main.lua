local cf = mwse.loadConfig("Spawner", {KEY = {keyCode = 184}, msg = true, agr = true, ray = false, pos = 200, hp = 0, mana = 0, stam = 0, str = 0, endu = 0, spd = 0, agi = 0, int = 0, wil = 0, atb = 0, arm = 0,
firres = 0, frres = 0, elres = 0, poires = 0, magres = 0, parres = 0, extra = false, hpreg = 0, mreg = 0, streg = 0, abs = 0, refl = 0, firsh = 0, frosh = 0, elsh = 0})

local S1 = {[1] = {"atronach_flame", "atronach_frost", "atronach_storm", "atronach_flame_lord", "atronach_frost_lord", "atronach_storm_lord", 
"dremora", "dremora_archer", "dremora_lord", "dremora_mage", "skaafin", "skaafin_archer", "golden saint", "mazken", "xivkyn",
"scamp", "clannfear_lesser", "clannfear", "vermai", "daedroth", "hunger", "ogrim", "ogrim titan", "winged twilight", "daedraspider", "xivilai"},

[2] = {"skeleton", "skeleton_weak", "skeleton archer", "skeleton warrior", "skeleton_knight", "skeleton champion", "skeleton_mage", "bm skeleton champion gr",
"bonewalker_weak", "bonewalker", "Bonewalker_Greater", "ancestor_ghost", "ancestor_ghost_greater", "dwarven ghost", "bonelord", "ash_revenant", "lich", "lich_elder",
"BM_wolf_skeleton", "BM_draugr01", "draugr", "draugr_fem", "draugr_soldier", "draugr_warrior", "draugr_general", "draugr_priest"},

[3] = {"corprus_stalker", "corprus_lame", "ash_slave", "ash_zombie", "ash_zombie_warrior", "ash_ghoul_warrior", "ash_ghoul", "ash_ghoul_high", "ascended_sleeper",
"goblin_grunt", "goblin_footsoldier", "goblin_bruiser", "goblin_handler", "goblin_officer", "goblin_shaman",
"BM_riekling", "BM_riekling_berserk", "BM_riekling_warrior", "BM_riekling_hunter", "BM_riekling_heavy", "BM_riekling_chieftain", "BM_riekling_shaman", "BM_riekling_mounted", "BM_riekling_mounted_war",
 "centurion_spider", "centurion_spider_tower", "centurion_spider_miner", "centurion_sphere", "centurion_projectile", "centurion_steam", "centurion_steam_advance", "centurion_sword", "centurion_weapon", "centurion_tank",
 "fabricant_verminous", "fabricant_hulking", "BM_werewolf_wildhunt", "BM_werewolf_maze1"},

[4] = {"mudcrab", "mudcrab_king", "mudcrab_rock", "mudcrab_titan", "Rat", "scrib", "shalk", "kwama forager", "kwama worker", "kwama warrior", "nix-hound", "nix_mount", 
"guar", "alit", "kagouti", "kagouti_dire", "durzog_wild", "durzog_war", "cliff racer", "netch_betty", "netch_bull",
"dreugh", "dreugh_soldier", "dreugh_land", "slaughterfish", "slaughterfish_electro", "BM_frost_boar", "BM_bear_black", "BM_wolf_grey", "BM_horker", "BM_spriggan", "BM_ice_troll"},

[5] = {"db_assassin3a", "db_assassin3", "Imperial Guard", "imperial archer", "hlaalu guard", "redoran guard male", "telvanni guard", "ordinator wander",  "ordinator stationary", "ordinator_mournhold", "Guard_Helseth",
"BM_berserker_m3", "bm_frysehag_1", "bm_frysehag_2", "bm_frysehag_3", "bm_reaver_10", "bm_reaver_30", "bm_reaver_50", "bm_reaver_archer_10", "bm_reaver_archer_30", "bm_reaver_archer_50", "bm_smugglers_darkelf", 
"divayth fyr", "King Hlaalu Helseth", "Gaenor_b"},

[6] = {"player", "dagoth_ur_2", "Almalexia_warrior", "vivec_god", "lich_barilzar", "lich_relvel", "BM_hircine_huntaspect", "BM_hircine_spdaspect", "BM_hircine_straspect", "dagoth gilvoth", "Imperfect", "fargoth"}}

local S = {[1] = {"atronach_flame", "atronach_frost", "atronach_storm", "dremora", "dremora_lord", "golden saint",
"scamp", "clannfear", "daedroth", "hunger", "ogrim", "ogrim titan", "winged twilight"},
[2] = {"skeleton", "skeleton_weak", "skeleton archer", "skeleton warrior", "skeleton champion", "bonewalker_weak", "bonewalker", "Bonewalker_Greater", "ancestor_ghost", "ancestor_ghost_greater",
"dwarven ghost", "bonelord", "BM_draugr01", "BM_wolf_skeleton", "lich"},
[3] = {"corprus_stalker", "corprus_lame", "ash_slave", "ash_zombie", "ash_ghoul", "ascended_sleeper", 
"goblin_grunt", "goblin_footsoldier", "goblin_bruiser", "goblin_handler", "goblin_officer", "goblin_warchief1", "BM_riekling", "BM_riekling_mounted", "BM_werewolf_wildhunt", "BM_werewolf_maze1",
 "centurion_spider", "centurion_sphere", "centurion_projectile", "centurion_steam", "centurion_steam_advance", "fabricant_verminous", "fabricant_hulking"},
[4] = {"Rat", "mudcrab", "scrib", "shalk", "kwama forager", "kwama worker", "kwama warrior", "nix-hound", "guar", "alit", "kagouti", "durzog_wild", "durzog_war", "cliff racer", "netch_betty", "netch_bull",
"dreugh", "slaughterfish", "BM_frost_boar", "BM_bear_black", "BM_wolf_grey", "BM_horker", "BM_spriggan", "BM_ice_troll", "BM_udyrfrykte"},
[5] = {"Imperial Guard", "imperial archer", "hlaalu guard", "redoran guard male", "telvanni guard", "ordinator wander", "ordinator stationary", "ordinator_mournhold", "Guard_Helseth",
"db_assassin3", "db_assassin4a", "BM_berserker_m3", "bm_frysehag_2", "bm_reaver_50", "bm_reaver_archer_50", "bm_smugglers_darkelf", 
"divayth fyr", "King Hlaalu Helseth", "Gaenor_b"},
[6] = {"player", "dagoth_ur_2", "Almalexia_warrior", "vivec_god", "lich_barilzar", "lich_relvel", "BM_hircine_huntaspect", "BM_hircine_spdaspect", "BM_hircine_straspect", "dagoth gilvoth", "Imperfect", "fargoth"}}


local Num = 1	local CID = "Creature ID"

local function GOD()	tes3.playSound{sound = "Thunder0"}		local p = tes3.player	
tes3.setStatistic{reference = p, name = "strength", value = 200}		tes3.setStatistic{reference = p, name = "endurance", value = 200}	tes3.setStatistic{reference = p, name = "agility", value = 150}
tes3.setStatistic{reference = p, name = "intelligence", value = 200}	tes3.setStatistic{reference = p, name = "willpower", value = 150}	tes3.setStatistic{reference = p, name = "speed", value = 150}
--tes3.setStatistic{reference = tes3.player, name = "health", value = 10000}
--tes3.setStatistic{reference = tes3.player, name = "magicka", value = 10000}
end

local function Hero()	tes3.playSound{sound = "Thunder0"}		local p = tes3.player		--mp = tes3.mobilePlayer
for i = 0, 26 do tes3.setStatistic{reference = p, skill = i, value = 100} end
tes3.setStatistic{reference = p, name = "strength", value = 100}		tes3.setStatistic{reference = p, name = "endurance", value = 100}	tes3.setStatistic{reference = p, name = "agility", value = 100}
tes3.setStatistic{reference = p, name = "intelligence", value = 100}	tes3.setStatistic{reference = p, name = "speed", value = 100}		tes3.setStatistic{reference = p, name = "willpower", value = 100}
tes3.setStatistic{reference = p, name = "personality", value = 100}		tes3.setStatistic{reference = p, name = "luck", value = 100}
end

local function Noob()	local p = tes3.player		--mp = tes3.mobilePlayer
for i = 0, 26 do tes3.setStatistic{reference = p, skill = i, value = 30} end
tes3.setStatistic{reference = p, name = "strength", value = 50}		tes3.setStatistic{reference = p, name = "endurance", value = 50}	tes3.setStatistic{reference = p, name = "agility", value = 50}
tes3.setStatistic{reference = p, name = "intelligence", value = 50}	tes3.setStatistic{reference = p, name = "speed", value = 50}		tes3.setStatistic{reference = p, name = "willpower", value = 50}
tes3.setStatistic{reference = p, name = "personality", value = 50}		tes3.setStatistic{reference = p, name = "luck", value = 50}
end

local function SpawnN(id, pos, n)
	local r = pos and tes3.createReference{object = id, position = pos, cell = tes3.player.cell} or mwscript.placeAtPC{object = id, direction = 0}		local m = r.mobile
	if cf.pos > 0 then r.position.x = r.position.x + math.random(-cf.pos,cf.pos)		r.position.y = r.position.y + math.random(-cf.pos,cf.pos) end
	if cf.str ~= 0 then tes3.setStatistic{reference = r, name = "strength", value = m.strength.base + cf.str} end
	if cf.endu ~= 0 then tes3.setStatistic{reference = r, name = "endurance", value = m.endurance.base + cf.endu} end
	if cf.spd ~= 0 then tes3.setStatistic{reference = r, name = "speed", value = m.speed.base + cf.spd} end
	if cf.agi ~= 0 then tes3.setStatistic{reference = r, name = "agility", value = m.agility.base + cf.agi} end
	if cf.int ~= 0 then tes3.setStatistic{reference = r, name = "intelligence", value = m.intelligence.base + cf.int} end
	if cf.wil ~= 0 then tes3.setStatistic{reference = r, name = "willpower", value = m.willpower.base + cf.wil} end
	if cf.hp > 0 then tes3.setStatistic{reference = r, name = "health", value = m.health.base + cf.hp} end
	if cf.mana > 0 then tes3.setStatistic{reference = r, name = "magicka", value = m.magicka.base + cf.mana} end
	if cf.stam > 0 then tes3.setStatistic{reference = r, name = "fatigue", value = m.fatigue.base + cf.stam} end
	
	if cf.atb > 0 then m.attackBonus = m.attackBonus + cf.atb end
	if cf.arm > 0 then m.shield = m.shield + cf.arm end
	if cf.firres > 0 then m.resistFire = m.resistFire + cf.firres end
	if cf.frres > 0 then m.resistFrost = m.resistFrost + cf.frres end
	if cf.elres > 0 then m.resistShock = m.resistShock + cf.elres end
	if cf.poires > 0 then m.resistPoison = m.resistPoison + cf.poires end
	if cf.magres > 0 then m.resistMagicka = m.resistMagicka + cf.magres end
	if cf.parres > 0 then m.resistParalysis = m.resistParalysis + cf.parres end

	if cf.extra then
		tes3.applyMagicSource{reference = r, name = "Spawn_buff", effects = {{id = 75, min = cf.hpreg, max = cf.hpreg, duration = 36000}, {id = 76, min = cf.mreg, max = cf.mreg, duration = 36000},
		{id = 77, min = cf.streg, max = cf.streg, duration = 36000}, {id = 67, min = cf.abs, max = cf.abs, duration = 36000}, {id = 68, min = cf.refl, max = cf.refl, duration = 36000},
		{id = 4, min = cf.firsh, max = cf.firsh, duration = 36000}, {id = 6, min = cf.frosh, max = cf.frosh, duration = 36000}, {id = 5, min = cf.elsh, max = cf.elsh, duration = 36000}}}
	end
	
	if cf.agr then m:startCombat(tes3.mobilePlayer) end
	if cf.msg then tes3.messageBox("%s  %d hp  %d mana  %d stam  %d str  %d end  %d spd  %d agi  %d int  %d wil", r.object.name, m.health.base, m.magicka.base, m.fatigue.base,
	m.strength.current, m.endurance.current, m.speed.current, m.agility.current, m.intelligence.current, m.willpower.current) end
	
	if n > 1 then SpawnN(id, pos, n-1) end
end

local function Spawn(id)	local pos
	if cf.ray then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore={p}}
		if hit then pos = hit.intersection - tes3.getPlayerEyeVector()*100 + tes3vector3.new(0,0,30) end
	end
	SpawnN(id, pos, Num)
end



local function KEYDOWN(e) if not tes3ui.menuMode() then
local M = {}	M.M = tes3ui.createMenu{id = 401, fixedFrame = true}	M.M.minHeight = 1100	M.M.minWidth = 1240		local el
M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)
M.Hero = M.B:createButton{text = "Hero"}	M.Hero:register("mouseClick", Hero)
M.Noob = M.B:createButton{text = "Noob"}	M.Noob:register("mouseClick", Noob)
M.GOD = M.B:createButton{text = "GOD"}		M.GOD:register("mouseClick", GOD)
M.NS = M.B:createSlider{max = 50, step = 1, jump = 5, current = Num}	M.NS.width = 300	M.NS.borderRight = 10		M.NS.borderTop  = 5
M.NS:register("PartScrollBar_changed", function() Num = math.max(M.NS.widget.current,1)		M.num.text = ""..Num end)
M.num = M.B:createLabel{text = ""..Num}		M.num.borderRight = 10
M.IMP = M.B:createTextInput{}	M.IMP.text = CID		M.IMP.width = 400		tes3ui.acquireTextInput(M.IMP)		M.IMP.borderRight = 10
M.Spawn = M.B:createButton{text = "Spawn"}	M.Spawn:register("mouseClick", function() CID = M.IMP.text
if tes3.getObject(CID) then Spawn(CID)	M.M:destroy()	tes3ui.leaveMenuMode() else tes3.messageBox("%s - Not found", M.IMP.text) end end)

M.HS = M.B:createSlider{max = 5000, step = 100, jump = 500, current = cf.hp}	M.HS.width = 300	M.HS.borderRight = 10		M.HS.borderTop  = 5
M.HS:register("PartScrollBar_changed", function() cf.hp = M.HS.widget.current		M.hp.text = "hp + " .. cf.hp end)
M.hp = M.B:createLabel{text = "hp + " .. cf.hp}		M.hp.borderRight = 10

for i = 1, 6 do M[i] = M.A:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 5		M[i].flowDirection = "top_to_bottom" end
for i, l in ipairs(S) do for _, id in ipairs(l) do	el = M[i]:createLabel{text = id}		el.borderBottom = 2		el:register("mouseClick", function() Spawn(id)	M.M:destroy()	tes3ui.leaveMenuMode() end) end end
tes3ui.enterMenuMode(401)		--:updateLayout()
end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})



local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Spawner")	tpl:saveOnClose("Spawner", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Spawn Menu (requires restarting the game)"}
p0:createYesNoButton{label = "Aggressive mode", variable = var{id = "agr", table = cf}}
p0:createYesNoButton{label = "Spawn where you are looking", variable = var{id = "ray", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
p0:createSlider{label = "Random position", min = 0, max = 1000, step = 50, jump = 200, variable = var{id = "pos", table = cf}}

p0:createSlider{label = "Hp bonus", min = 0, max = 5000, step = 10, jump = 50, variable = var{id = "hp", table = cf}}
p0:createSlider{label = "Mana bonus", min = 0, max = 5000, step = 10, jump = 50, variable = var{id = "mana", table = cf}}
p0:createSlider{label = "Stamina bonus", min = 0, max = 5000, step = 10, jump = 50, variable = var{id = "stam", table = cf}}
p0:createSlider{label = "Strength bonus", min = -200, max = 1000, step = 10, jump = 50, variable = var{id = "str", table = cf}}
p0:createSlider{label = "Endurance bonus", min = -200, max = 1000, step = 10, jump = 50, variable = var{id = "endu", table = cf}}
p0:createSlider{label = "Speed bonus", min = -200, max = 1000, step = 10, jump = 50, variable = var{id = "spd", table = cf}}
p0:createSlider{label = "Agility bonus", min = -200, max = 1000, step = 10, jump = 50, variable = var{id = "agi", table = cf}}
p0:createSlider{label = "Intelligence bonus", min = -200, max = 1000, step = 10, jump = 50, variable = var{id = "int", table = cf}}
p0:createSlider{label = "Willpower bonus", min = -200, max = 1000, step = 10, jump = 50, variable = var{id = "wil", table = cf}}
p0:createSlider{label = "Attack bonus", min = 0, max = 1000, step = 10, jump = 50, variable = var{id = "atb", table = cf}}
p0:createSlider{label = "Armor bonus", min = 0, max = 1000, step = 10, jump = 50, variable = var{id = "arm", table = cf}}

p0:createSlider{label = "Fire resistance bonus", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "firres", table = cf}}
p0:createSlider{label = "Frost resistance bonus", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "frres", table = cf}}
p0:createSlider{label = "Shock resistance bonus", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "elres", table = cf}}
p0:createSlider{label = "Poison resistance bonus", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "poires", table = cf}}
p0:createSlider{label = "Magic resistance bonus", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "magres", table = cf}}
p0:createSlider{label = "Paralys resistance bonus", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "parres", table = cf}}

p0:createYesNoButton{label = "Give extra bonuses (regen, reflection...)", variable = var{id = "extra", table = cf}}
p0:createSlider{label = "Hp regeneration", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "hpreg", table = cf}}
p0:createSlider{label = "Mana regeneration", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "mreg", table = cf}}
p0:createSlider{label = "Stamina regeneration", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "streg", table = cf}}
p0:createSlider{label = "Spell absorb", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "abs", table = cf}}
p0:createSlider{label = "Spell reflect", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "refk", table = cf}}
p0:createSlider{label = "Fire shield", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "firsh", table = cf}}
p0:createSlider{label = "Frost shield", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "frosh", table = cf}}
p0:createSlider{label = "Shock shield", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "elsh", table = cf}}
end		event.register("modConfigReady", registerModConfig)