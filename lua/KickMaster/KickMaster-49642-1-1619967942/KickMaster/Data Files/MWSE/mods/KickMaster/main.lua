local cf = mwse.loadConfig("KickMaster", {KEY = {keyCode = 29}, mb = 2, fat = 30, mult1 = 100, mult2 = 10, mult3 = 100, msg = false})		local V = {}	local KSR = {}	local T = timer
local p, mp	 local Matr = tes3matrix33.new()

local function GetArmor(m) if m.actorType == 0 then return m.shield else local st = tes3.getEquippedItem{actor = m.reference, objectType = tes3.objectType.armor, slot = math.random(4) == 1 and 1 or math.random(0,8)}
return m.shield + (st and st.object:calculateArmorRating(m) or m:getSkillValue(17)*0.3) end end
local function CrimeAt(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end
local function Nokout(ag) return ag == 34 or ag == 35 end

V.BLAST = function(e)	local r = e.reference	if KSR[r] then e.mobile.impulseVelocity = KSR[r].v*(1/30/tes3.worldController.deltaTime) * math.clamp(KSR[r].f/30,0.2,1)	KSR[r].f = KSR[r].f - 1		e.speed = 0
if KSR[r].f <= 0 then KSR[r] = nil 	if table.size(KSR) == 0 then event.unregister("calcMoveSpeed", V.BLAST) end end end end

V.KIK = function() if not T.timeLeft and mp.fatigue.current > cf.fat and mp.hasFreeAction and mp.paralyze < 1 then		local s = mp:getSkillValue(26)
local maxd = 50 + math.min(mp.agility.current/2, 50) + s/2
local vdir = tes3.getPlayerEyeVector()		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vdir, maxDistance = 150, ignore={p}}
local dist, r, m		if hit then dist = hit.distance 	r = hit.reference	m = r and r.mobile else dist = 10000 end
if dist > maxd then  local ori = p.orientation		Matr:fromEulerXYZ(ori.x, ori.y, ori.z)
	hit = tes3.rayTest{position = p.position + tes3vector3.new(0,0,15), direction = Matr:transpose().y, maxDistance = 150, ignore={p}}
	if hit then dist = hit.distance 	r = hit.reference	m = r and r.mobile or m else dist = 10000 end
	if dist > maxd then hit = mp.isMovingLeft and 1 or (mp.isMovingRight and -1)		if hit then Matr:fromEulerXYZ(ori.x, ori.y, ori.z)		vdir = Matr:transpose().x * hit
		hit = tes3.rayTest{position = p.position + tes3vector3.new(0,0,10), direction = vdir, ignore={p}}	if hit then dist = hit.distance 	r = hit.reference	m = r and r.mobile or m end
	end end
end
if m and m.isDead == false and dist < maxd then		vdir.z = math.min(vdir.z + 0.5, 1)		local arm = GetArmor(m)		local ko = Nokout(m.actionData.currentAnimationGroup)
	local cd = math.max(1.5 - mp.speed.current/100 + mp.encumbrance.normalized, 0.5)		T = timer.start{duration = cd, callback = function() end}
	local Koef = 100 + mp.attackBonus/5 + mp.strength.current + s/2 - 50 * (1 - math.min(mp.fatigue.normalized,1))
	local dmg = (5 + mp:getBootsWeight()/5) * Koef/100 * (ko and 1.5 or 1) * cf.mult1/100		local fdmg = dmg*dmg/(arm + dmg)		if dmg > 0 then m:applyHealthDamage(fdmg) end
	local sdmg = cf.mult2 * Koef/100		if not ko and sdmg > 0 then m.fatigue.current = m.fatigue.current - sdmg end
	CrimeAt(m)		mp.fatigue.current = mp.fatigue.current - cf.fat
	local mass = math.max(m.height, 50)		mass = mass * mass * ((m.actorType == 1 or m.object.biped) and 0.5 or 0.8) * (100 + arm/2)/5000
	local imp = math.min((Koef * cf.mult3/100 - m.endurance.current) * 1000/mass, 10000)
	if imp > 100 then if table.size(KSR) == 0 then event.register("calcMoveSpeed", V.BLAST) end
	tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}		KSR[r] = {v = vdir * imp, f = 30} end
	if cf.msg then tes3.messageBox("Kick! dmg = %d (%d / %d arm) + %d stam  K = %d%%   impuls = %d   mass = %d  dist = %d  cd = %.1f  up = %.2f", fdmg, dmg, arm, sdmg, Koef, imp, mass, dist, cd, vdir.z) end
end
end end


local function KEYDOWN(e) if not tes3ui.menuMode() then V.KIK() end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})
local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() and e.button == cf.mb then V.KIK() end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer 
	if table.size(KSR) ~= 0 then event.unregister("calcMoveSpeed", V.BLAST)		KSR = {} end
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("KickMaster")	tpl:saveOnClose("KickMaster", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Kick key"}
p0:createSlider{label = "Kick mouse button: 1 - right, 2 - middle", min = 1, max = 6, step = 1, jump = 1, variable = var{id = "mb", table = cf}}
p0:createSlider{label = "Damage multiplier", min = 0, max = 500, step = 10, jump = 50, variable = var{id = "mult1", table = cf}}
p0:createSlider{label = "Stamina damage multiplier", min = 0, max = 50, step = 1, jump = 5, variable = var{id = "mult2", table = cf}}
p0:createSlider{label = "Impuls multiplier", min = 50, max = 500, step = 10, jump = 50, variable = var{id = "mult3", table = cf}}
p0:createSlider{label = "Stamina cost", min = 10, max = 100, step = 1, jump = 10, variable = var{id = "fat", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)