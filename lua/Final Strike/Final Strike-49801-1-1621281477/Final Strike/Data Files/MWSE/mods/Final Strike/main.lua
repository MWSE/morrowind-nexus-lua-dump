local cf = mwse.loadConfig("Final Strike", {auto = true, msg = true, mb = 2, min = 128, stc = 30, mult = 5, acr = 5, slamd = 1000})
local p, mp, ad, wc, ic, MB, arp	local V = {}

local AT = {[0] = {t="l",s=21,p="lig0",snd="Light Armor Hit"}, [1] = {t="m",s=2,p="med0",snd="Medium Armor Hit"}, [2] = {t="h",s=3,p="hev0",snd="Heavy Armor Hit"}, [3] = {t="u",s=17}}

local function TFR(n, f) if n == 0 then f() else timer.delayOneFrame(function() TFR(n - 1, f) end) end end
local function GetArmor(m) if m.actorType == 0 then arp = nil	return m.shield else local st = tes3.getEquippedItem{actor = m.reference, objectType = tes3.objectType.armor, slot = math.random(4) == 1 and 1 or math.random(0,8)}
arp = st and st.object.weightClass	return m.shield + (st and st.object:calculateArmorRating(m) or m:getSkillValue(17)*0.3) end end
local function CrimeAt(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end



V.Dash = function(e) if e.reference == p then mp.impulseVelocity = V.d*(1/30/wc.deltaTime)	V.dfr = V.dfr - 1		if V.dfr <= 0 then event.unregister("calcMoveSpeed", V.Dash)	V.dfr = nil end end end


local function MOUSEBUTTONUP(e) if not tes3ui.menuMode() and e.button == 0 and ad.animationAttackState == 2 then local w = mp.readiedWeapon		w = w and w.object		local dir = ad.attackDirection	if dir == 1 then
	if w then tes3.findGMST("fCombatAngleXY").value = w.isTwoHanded and 1 or 0.8		TFR(2, function() tes3.findGMST("fCombatAngleXY").value = 0.6 end) end
elseif (dir == 2 or dir == 3) and not V.dfr then local vec = tes3.getPlayerEyeVector()	local tip
	local acr = mp:getSkillValue(20)*cf.acr/2000		local wr = w and w.reach or tes3.findGMST("fHandToHandReach").value
	if mp.isJumping and vec.z < -1 + acr then
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vec, ignore = {p}}		local hitd = hit and hit.distance or 0
		if hitd > wr * cf.min and hitd < cf.slamd then	V.d = vec * hitd * 3.5		V.dfr = 7	event.register("calcMoveSpeed", V.Dash)
			tes3.findGMST("fCombatDistance").value = (hitd + 300)/wr	tes3.findGMST("fCombatAngleXY").value = math.clamp(150/hitd, 0.15, 0.5)
			TFR(2, function() tes3.findGMST("fCombatDistance").value = 128	tes3.findGMST("fCombatAngleXY").value = 0.6 end)
			if cf.msg then tes3.messageBox("Slam!  Dist = %d  Vect = %.2f", hitd, vec.z) end
			if hitd > 500 and w and w.type == 4 and dir == 2 and ad.attackSwing > 0.95 then
				local dmg = w.chopMax * (1 + mp.strength.current/200) * math.max(mp.readiedWeapon.variables.condition/w.maxCondition, 0.3) * (1 + hitd/cf.slamd) / 4		local arm, fdmg, m
				timer.start{duration = 0.2/w.speed, callback = function() tes3.playSound{sound = table.choice({"endboom1", "endboom2", "endboom3"})}
					for r in tes3.iterate(p.cell.actors) do m = r.mobile	if m and not m.isDead and 200 > hit.intersection:distance(r.position) and r ~= e.targetReference and tes3.getCurrentAIPackageId(m) ~= 3 then
						arm = GetArmor(m)	fdmg = dmg*dmg/(arm+dmg)	m:applyHealthDamage(fdmg)	CrimeAt(m)		if arp then tes3.playSound{reference = r, sound = AT[arp].snd} end
						if cf.msg then tes3.messageBox("Hammer Slam! Dist = %d   %s  Dmg = %.1f  (%d  Armor = %.1f)", hitd, r, fdmg, dmg, arm) end
					end end
				end}
			end
		end
	elseif vec.z < 0.5 + acr and mp.fatigue.current > cf.stc then		if MB[cf.mb] == 128 then tip = 1 end	if cf.auto or tip then	local max = math.min(cf.mult * mp.speed.current / (1 + mp.encumbrance.normalized), 1000)
			local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vec, ignore = {p}}		local hitd = hit and math.min(hit.distance, max) or max
			if (tip or (hit and hit.reference and hit.reference.mobile)) and hitd > wr * cf.min then
				V.d = vec * hitd * 4.3		V.dfr = 7	event.register("calcMoveSpeed", V.Dash)	-- hitd*30/7  -- 4.28
				tes3.playSound{sound = math.random(2) == 1 and "FootBareLeft" or "FootBareRight"}
				tes3.findGMST("fCombatDistance").value = (hitd + 300)/wr		tes3.findGMST("fCombatAngleXY").value = math.clamp(150/hitd, 0.15, 0.5)
				
				TFR(2, function() tes3.findGMST("fCombatDistance").value = 128		tes3.findGMST("fCombatAngleXY").value = 0.6 end)
				local stc = cf.stc * (1 + mp.encumbrance.normalized) * hitd/max		mp.fatigue.current = mp.fatigue.current - stc
				if cf.msg then tes3.messageBox("Charge!  Dist = %d/%d  Cost = %d   Vect = %.2f", hitd, max, stc, vec.z) end
			end
	end end
end end end		event.register("mouseButtonUp", MOUSEBUTTONUP)



local function mouseButtonUp(e) if not tes3ui.menuMode() and e.button == 0 and tes3.mobilePlayer.actionData.animationAttackState == 2 then
	tes3.findGMST("fCombatDistance").value = 3000
	timer.delayOneFrame(function() timer.delayOneFrame(function() tes3.findGMST("fCombatDistance").value = 128 end) end)
end end		--event.register("mouseButtonUp", mouseButtonUp)



local function ATTACK(e) if e.mobile == mp and ad.attackDirection == 1 and ad.attackSwing > 0.95 then	local w = mp.readiedWeapon	local ob = w and w.object	local wd = w.variables
	if ob and ob.isTwoHanded then local dist = 150 * ob.reach
		local dmg = ob.slashMax/2*(1 + mp.strength.current/200) * math.max(wd.condition/ob.maxCondition, 0.3)		local arm, fdmg, m
		timer.start{duration = 0.2/ob.speed, callback = function() for r in tes3.iterate(p.cell.actors) do m = r.mobile
		if m and not m.isDead and dist > p.position:distance(r.position) and r ~= e.targetReference and tes3.getCurrentAIPackageId(m) ~= 3 then
			arm = GetArmor(m)	fdmg = dmg*dmg/(arm+dmg)	m:applyHealthDamage(fdmg)	CrimeAt(m)		if arp then tes3.playSound{reference = r, sound = AT[arp].snd} end
			if cf.msg then tes3.messageBox("Round attack! %s  Dmg = %.1f  (%d  Armor = %.1f)", r, fdmg, dmg, arm) end
		end end end}
	end
end end		event.register("attack", ATTACK)



local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer	ad = mp.actionData
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Final Strike")	tpl:saveOnClose("Final Strike", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createYesNoButton{label = "Automatically do a charge attack if you are looking at an enemy", variable = var{id = "auto", table = cf}}
p0:createSlider{label = "Mouse button to charge attack (hold when attack to make charge): 1 - left, 2 - right, 3 - middle", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mb", table = cf}}
p0:createSlider{label = "Minimum range for charge/slam attack", min = 100, max = 500, step = 10, jump = 30, variable = var{id = "min", table = cf}}
p0:createSlider{label = "Range multiplier for charge attack", min = 2, max = 10, step = 1, jump = 1, variable = var{id = "mult", table = cf}}
p0:createSlider{label = "Stamina cost for charge attack", min = 10, max = 100, step = 5, jump = 10, variable = var{id = "stc", table = cf}}
p0:createSlider{label = "Acrobatics skill multiplier to increase the maximum angle of charge/slam attacks", min = 1, max = 10, step = 1, jump = 1, variable = var{id = "acr", table = cf}}
p0:createSlider{label = "Maximum slam distance", min = 500, max = 3000, step = 100, jump = 500, variable = var{id = "slamd", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
end		event.register("initialized", initialized)