
local cf = mwse.loadConfig("Final Strike", {auto = true, msg = true, mb = 2, min = 140, stc = 30, mult = 5, acr = 5, slamd = 2000})
local p, mp, ad, wc, ic, MB, arp	local V = {}

local AT = {[0] = {t="l",s=21,p="lig0",snd="Light Armor Hit"}, [1] = {t="m",s=2,p="med0",snd="Medium Armor Hit"}, [2] = {t="h",s=3,p="hev0",snd="Heavy Armor Hit"}, [3] = {t="u",s=17}}

local function TFR(n, f) if n == 0 then f() else timer.delayOneFrame(function() TFR(n - 1, f) end) end end
local function GetArmor(m) if m.actorType == 0 then arp = nil	return m.shield else local st = tes3.getEquippedItem{actor = m.reference, objectType = tes3.objectType.armor, slot = math.random(4) == 1 and 1 or math.random(0,8)}
arp = st and st.object.weightClass	return m.shield + (st and st.object:calculateArmorRating(m) or m:getSkillValue(17)*0.3) end end
local function CrimeAt(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end

local function Sector(t)	local m, p1, d, d1, dd, ref	local dd1 = t.lim or 2000		local pos = t.pos or tes3.getPlayerEyePosition()		local v = t.v or tes3.getPlayerEyeVector()
	for _, c in pairs(tes3.getActiveCells()) do for r in tes3.iterate(c.actors) do m = r.mobile	if m and not m.isDead then
		p1 = r.position:copy()	p1.z = p1.z + m.height/2		d = pos:distance(p1)
		if d < t.d then dd = p1:distance(pos + v*d)
			if dd < dd1 and tes3.testLineOfSight{reference1 = p, reference2 = r} and (not t.fr or tes3.getCurrentAIPackageId(m) ~= 3) then ref = r	dd1 = dd	d1 = d end
		end	
	end end end		if ref then tes3.messageBox("%s  Dist = %d   Dif = %d", ref, d1, dd1) end
	return ref, d1
end


V.Dash = function(e) if e.reference == p then if V.djf then	mp.isJumping = true end			mp.impulseVelocity = V.d*(1/30/wc.deltaTime)	V.dfr = V.dfr - 1
if V.dfr <= 0 then event.unregister("calcMoveSpeed", V.Dash)	V.dfr = nil		if V.djf then V.djf = nil	mp.isJumping = false end		if V.daf then mp.animationController.weaponSpeed = V.daf	V.daf = nil end end end end


local function MOUSEBUTTONUP(e) if not tes3ui.menuMode() and e.button == 0 and ad.animationAttackState == 2 then	local dir = ad.attackDirection	if dir < 4 and not V.dfr then	local pass = MB[cf.mb] == 128
	if cf.auto or pass then		local w = mp.readiedWeapon		w = w and w.object		local vec = tes3.getPlayerEyeVector()	if vec.z < 0.9 then		local acr = mp:getSkillValue(20)*cf.acr/2000
		if math.abs(vec.z) < 0.15 then vec.z = 0	vec = vec:normalized() elseif vec.z > acr then vec.z = acr	vec = vec:normalized() end
		local wr = w and w.reach or tes3.findGMST("fHandToHandReach").value			
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vec, ignore = {p}}		local ref, hitd
		if hit and hit.reference and hit.reference.mobile and not hit.reference.mobile.isDead then ref = hit.reference end	
		if not ref then ref, hitd = Sector{d = 9000, lim = 500} end		hitd = hitd or (hit and hit.distance) or 20000
		
		if (pass or ref) and hitd > wr * cf.min then
			local DD = vec.z < -1 + acr and cf.slamd or math.min(cf.mult * mp.speed.current / (1 + mp.encumbrance.normalized), 2000)	local stc = cf.stc * (1 + mp.encumbrance.normalized)	
			local Dkoef = hitd/DD		if Dkoef < 1 then DD = DD * Dkoef	stc = stc * Dkoef end
			if mp.fatigue.current > stc then	local vk = math.max(-0.4 - vec.z, 0)/3
				V.d = vec*(DD*30/8 * (1 - vk))	V.dfr = 8	event.register("calcMoveSpeed", V.Dash)		tes3.playSound{sound = math.random(2) == 1 and "FootBareLeft" or "FootBareRight"}
				mp.animationController.weaponSpeed = dir == 3 and 0.4 or (dir == 1 and 0.5) or 0.6			V.daf = w and w.speed or 1		if not mp.isJumping then V.djf = true	mp.isJumping = true end
				tes3.findGMST("fCombatDistance").value = (DD + 50)/wr		tes3.findGMST("fCombatAngleXY").value = math.clamp(150/DD, 0.05, 0.5)
				TFR(2, function() tes3.findGMST("fCombatDistance").value = 128		tes3.findGMST("fCombatAngleXY").value = 0.6 end)
				mp.fatigue.current = mp.fatigue.current - stc
				if cf.msg then tes3.messageBox("Charge!  Dist = %d   StamCost = %d   Vect = %.2f / %.2f", DD, stc, vec.z, acr) end
				
				if hit and hitd > 500 and Dkoef < 1 and w and w.type == 4 and dir == 2 and ad.attackSwing > 0.95 and vec.z < -1 + acr and mp.velocity:length() > 0 then
					local dmg = w.chopMax * (1 + mp.strength.current/200) * math.max(mp.readiedWeapon.variables.condition/w.maxCondition, 0.3) * hitd/3000		local hitp = hit.intersection:copy()	local m
					timer.start{duration = 0.2/w.speed, callback = function() tes3.playSound{sound = table.choice({"endboom1", "endboom2", "endboom3"})}	--"fabBossLeft", "fabBossRight"
						for _, m in pairs(tes3.findActorsInProximity{position = hitp, range = 250}) do if m ~= mp then
							dmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}		CrimeAt(m)
							if cf.msg then tes3.messageBox("Hammer Slam! Height = %d   %s  Dmg = %.1f  Dist = %d", hitd, m.object.name, dmg, hitp:distance(m.position)) end
						end end
					end}
				end
			end
		end
	end end
	if w and dir == 1 and P.agi15 and not V.daf then tes3.findGMST("fCombatAngleXY").value = w.isTwoHanded and 1 or 0.8		TFR(2, function() tes3.findGMST("fCombatAngleXY").value = 0.6 end) end
end end end		event.register("mouseButtonUp", MOUSEBUTTONUP)


local function ATTACK(e) if e.mobile == mp and ad.attackDirection == 1 and ad.attackSwing > 0.95 then	local w = mp.readiedWeapon	local ob = w and w.object	local wd = w.variables
	if ob and ob.isTwoHanded then local dist = 150 * ob.reach
		local dmg = ob.slashMax/2*(1 + mp.strength.current/200) * math.max(wd.condition/ob.maxCondition, 0.3)
		timer.start{duration = 0.2/ob.speed, callback = function() for _, m in pairs(tes3.findActorsInProximity{reference = p, range = dist}) do if m ~= mp and m ~= e.targetMobile and tes3.getCurrentAIPackageId(m) ~= 3 then
			dmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}		CrimeAt(m)		if cf.msg then tes3.messageBox("Round attack! %s  Dmg = %.1f", m.reference, dmg) end
		end end end}
	end
end end		event.register("attack", ATTACK)



local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer	ad = mp.actionData
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Final Strike")	tpl:saveOnClose("Final Strike", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createYesNoButton{label = "Automatically do a charge attack if you are looking at an enemy", variable = var{id = "auto", table = cf}}
p0:createSlider{label = "Mouse button to charge attack (hold when attack to make charge): 1 - left, 2 - right, 3 - middle", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mb", table = cf}}
p0:createSlider{label = "Minimum range for charge/slam attack", min = 100, max = 500, step = 10, jump = 30, variable = var{id = "min", table = cf}}
p0:createSlider{label = "Range multiplier for charge attack", min = 3, max = 20, step = 1, jump = 1, variable = var{id = "mult", table = cf}}
p0:createSlider{label = "Stamina cost for charge attack", min = 10, max = 100, step = 5, jump = 10, variable = var{id = "stc", table = cf}}
p0:createSlider{label = "Acrobatics skill multiplier to increase the maximum angle of charge/slam attacks", min = 1, max = 10, step = 1, jump = 1, variable = var{id = "acr", table = cf}}
p0:createSlider{label = "Maximum slam distance", min = 500, max = 9000, step = 100, jump = 500, variable = var{id = "slamd", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
end		event.register("initialized", initialized)