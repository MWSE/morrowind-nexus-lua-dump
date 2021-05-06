local cf = mwse.loadConfig("N'wah Shooter", {Proj = true, grav = 20, shake = 10, fatshake = 20, arcaut = false, sklim = 100, fatmult = 20})
local p, mp, ad, wc, ic, MB, Sim		local PRR = {}		local CPR = {}		local W = {}
local L = {BlackAmmo = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true, ["4nm_stone"] = true,
["her dart"] = true, ["bm_ebonyarrow_s"] = true, ["carmine dart"] = true, ["fine carmine dart"] = true, ["black dart"] = true, ["fine black dart"] = true, ["bleeder dart"] = true, ["fine bleeder dart"] = true,},
Summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["4nm_daedraspider_s"] = true,["4nm_dremora_mage_s"] = true,["4nm_skaafin_s"] = true,["4nm_xivkyn_s"] = true,["4nm_xivilai_s"] = true,["4nm_mazken_s"] = true,["4nm_ogrim_s"] = true,["4nm_skeleton_mage_s"] = true,["4nm_lich_elder_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true}}


local function ArcherSim(e) if ad.animationAttackState == 2 then local dt = wc.deltaTime
	if (cf.arcaut or MB[2] == 128) and mp.fatigue.current > 10 then mp.fatigue.current = mp.fatigue.current - dt * cf.fatshake		dt = -dt end	W.artim = math.clamp((W.artim or 0) + dt,0,4)
	if W.artim > 0 then	local MS = ic.mouseState	local x = (5 + mp.readiedWeapon.object.weight/2) * (1 - (math.min(mp.agility.current + mp:getSkillValue(23),200)/250)) * W.artim/4 * cf.shake/10
		MS.x = MS.x + math.random(-2*x,2*x)		MS.y = MS.y + math.random(-x,x)
	end
else W.artim = nil end end
local function ArcherStart(e) if e.button == 0 then W.artim = nil	event.unregister("simulate", ArcherSim)		event.unregister("mouseButtonUp", ArcherStart) end end


local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() then if e.button == 0 then
	if mp.weaponDrawn then	local w = mp.readiedWeapon	w = w and w.object
		if w and w.type == 9 then
			if not W.artim then event.register("simulate", ArcherSim)	event.register("mouseButtonUp", ArcherStart) end
			if mp:getSkillValue(23) >= cf.sklim and ad.animationAttackState == 5 and mp.fatigue.current > cf.fatmult then
				ad.animationAttackState = 0		mp.fatigue.current = mp.fatigue.current - cf.fatmult	tes3.playSound{sound = "Item Ammo Up"}
			end
		end
	end
end end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)


local function SimulateCP(e)	local dt = wc.deltaTime	
	for r, t in pairs(CPR) do t.liv = t.liv + dt		t.m.impulseVelocity = tes3vector3.new(0,0,-100 * cf.grav * t.liv) end
	if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	Sim = nil end
end


local function MOBILEACTIVATED(e) local m = e.mobile		if m and m.firingMobile and not m.spellInstance then	local r = e.reference
	r.position = r.position - r.sceneNode.velocity:normalized()*100
	if m.firingMobile == mp then CPR[r] = {mod = 10, m = m, liv = 0}		if not Sim then event.register("simulate", SimulateCP)	Sim = 0 end end
end end		event.register("mobileActivated", MOBILEACTIVATED)



local function onProj(e) if not L.BlackAmmo[e.mobile.reference.object.id] and e.firingReference and not L.Summon[e.firingReference.baseObject.id] then
	local hit = tes3.rayTest{position = e.collisionPoint - e.velocity:normalized()*10, direction = e.velocity}
	local ref = tes3.createReference{object = e.mobile.reference.object, cell = p.cell, orientation = e.mobile.reference.sceneNode.worldTransform.rotation:toEulerXYZ(),
	position = hit and hit.intersection:distance(e.collisionPoint) < 200 and hit.intersection or e.collisionPoint + e.velocity * 0.7 * wc.deltaTime}		ref.modified = false	PRR[ref] = true
end end		if cf.Proj then event.register("projectileHitObject", onProj)	event.register("projectileHitTerrain", onProj) end


local function OBJECTINVALIDATED(e) local ob = e.object
	if CPR[ob] then CPR[ob] = nil end
	if PRR[ob] then PRR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		ad = mp.actionData		W = {}
	for ref, _ in pairs(PRR) do ref:disable()	mwscript.setDelete{reference = ref} end		PRR = {}
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("N'wah Shooter")	tpl:saveOnClose("N'wah Shooter", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Gravity power", min = 5, max = 40, step = 1, jump = 5, variable = var{id = "grav", table = cf}}
p0:createSlider{label = "Hand shaking multiplier when archery", min = 0, max = 30, step = 1, jump = 1, variable = var{id = "shake", table = cf}}
p0:createYesNoButton{label = "Automatically hold your breath when archery to reduce hand shake (right mouse button)", variable = var{id = "arcaut", table = cf}}
p0:createSlider{label = "Stamina consumption per second of breath holding when archery", min = 5, max = 50, step = 1, jump = 5, variable = var{id = "fatshake", table = cf}}
p0:createSlider{label = "Marksman skill, upon reaching which you will have access to a multi-shot with a bow", min = 50, max = 150, step = 1, jump = 10, variable = var{id = "sklim", table = cf}}
p0:createSlider{label = "Stamina consumption per multi-shot", min = 10, max = 50, step = 1, jump = 5, variable = var{id = "fatmult", table = cf}}
p0:createYesNoButton{label = "Arrows get stuck on hit. Requires game restart", variable = var{id = "Proj", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
	tes3.findGMST("fProjectileMinSpeed").value = 1000		tes3.findGMST("fProjectileMaxSpeed").value = 5000		tes3.findGMST("fThrownWeaponMinSpeed").value = 1000		tes3.findGMST("fThrownWeaponMaxSpeed").value = 3000
	tes3.findGMST("fProjectileThrownStoreChance").value = 100
end		event.register("initialized", initialized)