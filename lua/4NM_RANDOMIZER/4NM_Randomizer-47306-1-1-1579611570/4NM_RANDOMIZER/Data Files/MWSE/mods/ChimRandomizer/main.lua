local msg 	local r, m, d, id, ch

local Summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["4nm_daedraspider_s"] = true,["4nm_dremora_mage_s"] = true,["4nm_skaafin_s"] = true,["4nm_xivkyn_s"] = true,["4nm_mazken_s"] = true,["4nm_ogrim_s"] = true,["4nm_skeleton_mage_s"] = true,["4nm_lich_elder_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true}
local BlackList = {["BM_hircine_straspect"] = true,["BM_hircine_spdaspect"] = true,["BM_hircine_huntaspect"] = true,["BM_hircine"] = true,["vivec_god"] = true,["Almalexia_warrior"] = true,["almalexia"] = true,
["dagoth_ur_1"] = true,["dagoth_ur_2"] = true,["Imperfect"] = true,["lich_barilzar"] = true,["lich_relvel"] = true,["yagrum bagarn"] = true,["bm_frost_giant"] = true,["dagoth araynys"] = true,["dagoth endus"] = true,
["dagoth gilvoth"] = true,["dagoth odros"] = true,["dagoth tureynul"] = true,["dagoth uthol"] = true,["dagoth vemyn"] = true,["heart_akulakhan"] = true, ["mudcrab_unique"] = true, ["scamp_creeper"] = true,
["4nm_target"] = true}
local ID = {["bonewalker"] = "zombirise", ["bonewalker_weak"] = "zombirise", ["Bonewalker_Greater"] = "zombirise",
["BM_bear_black"] = "bear", ["BM_bear_brown"] = "bear", ["BM_bear_snow_unique"] = "bear", ["BM_wolf_grey"] = "wolf", ["BM_wolf_red"] = "wolf", ["BM_wolf_snow_unique"] = "wolf", ["BM_wolf_grey_lvl_1"] = "wolf",
["centurion_spider"] = "dwem", ["centurion_sphere"] = "dwem", ["centurion_steam"] = "dwem", ["centurion_projectile"] = "dwem", ["centurion_steam_advance"] = "dwem"}
local AR = {["atronach_flame"] = 20, ["atronach_flame_summon"] = 20, ["atronach_frost"] = 40, ["atronach_frost_summon"] = 40, ["atronach_storm"] = 60, ["atronach_storm_summon"] = 60, ["atronach_frost_BM"] = 50,
["dremora"] = 40, ["dremora_summon"] = 40, ["dremora_lord"] = 60, ["golden saint"] = 40, ["golden saint_summon"] = 40, ["4nm_mazken"] = 30, ["4nm_mazken_s"] = 30, ["hunger"] = 10, ["hunger_summon"] = 10,
["ogrim"] = 30, ["4nm_ogrim_s"] = 40, ["ogrim titan"] = 40, ["daedroth"] = 20, ["daedroth_summon"] = 20, ["winged twilight"] = 5, ["winged twilight_summon"] = 5, ["clannfear"] = 15, ["clannfear_summon"] = 15,
["4nm_dremora_mage"] = 10, ["4nm_dremora_mage_s"] = 10, ["4nm_skaafin_archer"] = 20, ["4nm_skaafin_s"] = 20, ["4nm_daedraspider"] = 5, ["4nm_daedraspider_s"] = 5, ["4nm_xivkyn"] = 50, ["4nm_xivkyn_s"] = 50,
["skeleton"] = 10, ["skeleton_summon"] = 10, ["skeleton entrance"] = 15, ["skeleton_weak"] = 5, ["skeleton archer"] = 10, ["skeleton warrior"] = 20, ["skeleton champion"] = 40, ["bm skeleton champion gr"] = 40,
["bonewalker"] = 5, ["bonewalker_weak"] = 5, ["Bonewalker_Greater"] = 5, ["Bonewalker_Greater_summ"] = 5, ["bonewalker_summon"] = 5, ["bonelord"] = 15, ["bonelord_summon"] = 15,
["4nm_skeleton_mage"] = 10, ["4nm_skeleton_mage_s"] = 10, ["lich"] = 20, ["4nm_lich_elder"] = 30, ["4nm_lich_elder_s"] = 30, ["BM_wolf_skeleton"] = 5, ["BM_wolf_bone_summon"] = 5, ["BM_draugr01"] = 15,
["corprus_stalker"] = 5, ["corprus_lame"] = 15, ["ash_slave"] = 10, ["ash_zombie"] = 5, ["ash_ghoul"] = 20, ["ascended_sleeper"] = 40,
["centurion_spider"] = 60, ["centurion_sphere"] = 70, ["centurion_sphere_summon"] = 70, ["centurion_steam"] = 80, ["centurion_projectile"] = 70, ["centurion_steam_advance"] = 90,
["alit"] = 10, ["alit_diseased"] = 10, ["alit_blighted"] = 10, ["dreugh"] = 30, ["guar"] = 10, ["guar_feral"] = 10, ["guar_pack"] = 20, ["kagouti"] = 15, ["kagouti_diseased"] = 15, ["kagouti_blighted"] = 15,
["kwama worker"] = 25, ["kwama worker diseased"] = 25, ["kwama worker blighted"] = 25, ["kwama worker entrance"] = 30, ["kwama warrior"] = 30, ["kwama warrior blighted"] = 30, ["mudcrab"] = 30, ["mudcrab-Diseased"] = 30,
["netch_bull"] = 10, ["netch_bull_ranched"] = 10, ["netch_betty"] = 5, ["netch_betty_ranched"] = 5, ["nix-hound"] = 5, ["nix-hound blighted"] = 5, ["shalk"] = 15, ["shalk_diseased"] = 15, ["shalk_blighted"] = 15,
["durzog_wild"] = 15, ["durzog_wild_weaker"] = 10, ["durzog_war"] = 20, ["durzog_war_trained"] = 20, ["durzog_diseased"] = 15,
["goblin_grunt"] = 15, ["goblin_footsoldier"] = 25, ["goblin_bruiser"] = 30, ["goblin_handler"] = 20, ["goblin_officer"] = 35, ["fabricant_verminous"] = 30, ["fabricant_summon"] = 30, ["fabricant_hulking"] = 50,
["BM_wolf_grey"] = 10, ["BM_wolf_red"] = 10, ["BM_wolf_snow_unique"] = 10, ["BM_wolf_grey_summon"] = 10, ["BM_bear_black"] = 20, ["BM_bear_brown"] = 20, ["BM_bear_snow_unique"] = 20, ["BM_bear_black_summon"] = 20,
["BM_frost_boar"] = 15, ["BM_riekling"] = 15, ["BM_riekling_mounted"] = 15, ["BM_spriggan"] = 20, ["BM_ice_troll"] = 30, ["BM_werewolf_default"] = 20}
--[""] = , [""] = , [""] = , [""] = , [""] = , [""] = , [""] = , [""] = , [""] = , [""] = , -- table.find


local function onMobileActivated(e) if e.reference.object.objectType == tes3.objectType.creature and BlackList[e.reference.baseObject.id] == nil and e.reference.mobile and e.reference.mobile.health.current > 0 and e.reference.data.spawn == nil then
	r = e.reference		m = r.mobile	r.data.spawn = math.random(10)		d = r.data.spawn	id = r.baseObject.id
	local koef = math.random(80,120)/100		local conj = Summon[id] and tes3.player.data.conjpower or 1
	tes3.setStatistic({reference = r, name = "health", value = (m.health.base * koef * conj)})
	if koef > 1 then koef = 1 + (koef - 1) * 0.75 else koef = 1 + (koef - 1) * 0.5 end		r.scale = r.scale * koef
	tes3.setStatistic({reference = r, name = "magicka", value = (m.magicka.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "fatigue", value = (m.fatigue.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "strength", value = (m.strength.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "endurance", value = (m.endurance.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "agility", value = (m.agility.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "speed", value = (m.speed.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "intelligence", value = (m.intelligence.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "willpower", value = (m.willpower.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "luck", value = (m.luck.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "personality", value = (m.personality.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "combat", value = (m.combat.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "magic", value = (m.magic.base * math.random(80,120) / 100 * conj)})
	tes3.setStatistic({reference = r, name = "stealth", value = (m.stealth.base * math.random(80,120) / 100 * conj)})
	if AR[id] then m.shield = (AR[id] * math.random(80,120) / 100 * conj) end
	if msg then tes3.messageBox("%s  activated! Скейл = %.2f  Сила = %d  AR = %d  Вар = %s", r, r.scale, m.strength.current, m.shield, d) end
end end

local function initialized(e)
	event.register("mobileActivated", onMobileActivated)
end
event.register("initialized", initialized)