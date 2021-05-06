local cf = mwse.loadConfig("Bomberman", {msg = false, ded = false, minrad = 10, radmult = 10, powmult = 20})
local p, mp, wc		local KSR = {}		local V = {}		local ME = {[14]=1, [15]=1, [16]=1}

local function GetArmor(m) if m.actorType == 0 then return m.shield else local st = tes3.getEquippedItem{actor = m.reference, objectType = tes3.objectType.armor, slot = math.random(4) == 1 and 1 or math.random(0,8)}
return m.shield + (st and st.object:calculateArmorRating(m) or m:getSkillValue(17)*0.3) end end

V.BLAST = function(e)	local r = e.reference	if KSR[r] then e.mobile.impulseVelocity = KSR[r].v * (1/30/wc.deltaTime) * math.clamp(KSR[r].f/30,0.2,1)	KSR[r].f = KSR[r].f - 1		e.speed = 0
if KSR[r].f <= 0 then KSR[r] = nil 	if table.size(KSR) == 0 then event.unregister("calcMoveSpeed", V.BLAST) 	V.bcd = nil end end end end


local function PROJECTILEEXPIRE(e) if e.firingReference == p then	local si = e.mobile.spellInstance		if si then	local eff = si.source.effects	if ME[eff[1].id] then	
	local pos = e.mobile.reference.position		local rad = 0
	for i, ef in ipairs(eff) do if ME[ef.id] and ef.radius >= cf.minrad then rad = rad + math.random(ef.min, ef.max) * ef.radius end end
	if rad > 0 then rad = rad * (100 + mp.willpower.current + mp.destruction.current + mp.alteration.current)/2000 * cf.radmult		local dist, pow, m, mass
		for _, c in pairs(tes3.getActiveCells()) do
			for r in tes3.iterate(c.actors) do m = r.mobile		if m and not m.isDead then dist = pos:distance(r.position)		if dist < rad then
				mass = math.max(m.height, 50)		mass = mass * mass * ((m.actorType == 1 or m.object.biped) and 0.5 or 0.8) * (100 + GetArmor(m)/2)/5000
				pow = math.min((rad - dist) * 20 / mass * cf.powmult, 15000)
				tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}		local KO = pow/40 - m.agility.current
				KSR[r] = {v = ((r.position + tes3vector3.new(0, 0, m.height*0.8)) - pos):normalized() * pow, f = (KSR[r] and KSR[r].f/2 or 0) + 30}
				--if KO > math.random(100) then KSR[r].stam = m.fatigue.current	m.fatigue.current = -10		timer.start{duration = 1, callback = function() m.fatigue.current = KSR[r].stam end} end
				if KO > math.random(100) then tes3.applyMagicSource{reference = r, name = "KO", effects = {{id = 20, min = 1000, max = 1000, duration = 1}}} end
				if not V.bcd then event.register("calcMoveSpeed", V.BLAST)	V.bcd = 0 end			if cf.msg then tes3.messageBox("Blast! %s  Impuls = %d (%d - %d) mass = %d  KO chance = %d%%", r, pow, rad, dist, mass, KO) end
			end end end
		end
	end
end end end end		event.register("projectileExpire", PROJECTILEEXPIRE)


local function DEATH(e) local r = e.reference	local dow = tes3.rayTest{position = r.position, direction = tes3vector3.new(0,0,-1), ignore = {r}}
	if dow and dow.distance > 100 then if cf.msg then tes3.messageBox("%s extra landing", r) end	local vel = dow.distance/20		local int = dow.intersection
		timer.start{duration = 0.03, iterations = 20, callback = function() r.position = r.position:interpolate(int, vel) end}
	end
end		if cf.ded then event.register("death", DEATH) end

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		wc = tes3.worldController		KSR = {}
end		event.register("loaded", loaded)


local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Bomberman")	tpl:saveOnClose("Bomberman", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Minimum spell radius for the possibility of explosion", min = 0, max = 20, step = 1, jump = 5, variable = var{id = "minrad", table = cf}}
p0:createSlider{label = "Explosion radius multiplier", min = 5, max = 50, step = 1, jump = 5, variable = var{id = "radmult", table = cf}}
p0:createSlider{label = "Impulse power multiplier", min = 5, max = 100, step = 1, jump = 5, variable = var{id = "powmult", table = cf}}
p0:createYesNoButton{label = "Fix landing dead (Requires game restart)", variable = var{id = "ded", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)