local cf = mwse.loadConfig("Runes and Totems", {agr = true, KEY = {keyCode = 44}, mb = 4, mct = 50, mcr = 100})
local p, mp, MB, Flag, MMana, Rune, Totem		local SOU = {}	local TOT = {}	local RUN = {}	local TotT = timer	local RunT = timer		local TotMod = true		local ID33 = tes3matrix33.new(1,0,0,0,1,0,0,0,1)

local function GetOri(vec1, vec2) vec1 = vec1:normalized()	vec2 = vec2:normalized()	local axis = vec1:cross(vec2)	local norm = axis:length()
	if norm < 1e-5 then return ID33:toEulerXYZ() end
	local angle = math.asin(norm)	if vec1:dot(vec2) < 0 then angle = math.pi - angle end		axis:normalize()
	local m = ID33:copy()	m:toRotation(-angle, axis.x, axis.y, axis.z)	return m:toEulerXYZ()	--return m
end

local function CrimeAt(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end


local function spellResist(e) if not e.caster and SOU[e.source] and e.resistAttribute ~= 28 then
	if e.target == p then e.resistedPercent = 100 else CrimeAt(e.target.mobile) end
end end		event.register("spellResist", spellResist)


local function mobileActivated(e)	local m = e.mobile	if m then	local si = m.spellInstance
	if si and si.caster.id == "4nm_totem" then SI[si] = true end
end	end		--event.register("mobileActivated", mobileActivated)



local function SPELLCASTED(e) if (Flag or MB[cf.mb] == 128) and e.caster == p then local s = e.source	if s.castType == 0 then	local ef = s.effects[1]
if ef.rangeType == 1 and ef.radius > 0 and mp.magicka.current > s.magickaCost * cf.mcr/100 then
local pos, ori	local maxd = math.min((100 + mp.willpower.current + mp:getSkillValue(11)) * 15, 4500)
local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore={p}, maxDistance = maxd}
if not hit then hit = tes3.rayTest{position = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() * maxd, direction = tes3vector3.new(0,0,-1)} end
if hit and not (hit.reference and hit.reference.mobile) then pos = hit.intersection		ori = GetOri(tes3vector3.new(0,0,1), hit.normal) end

if pos then		SOU[s] = 1		mp.magicka.current = mp.magicka.current - s.magickaCost * cf.mcr/100		MMana.current = mp.magicka.current		-- + tes3vector3.new(0,0,3)
	local r = tes3.createReference{object = Rune, position = pos, orientation = ori, cell = p.cell, scale = math.min(ef.radius * math.min(0.15 + mp:getSkillValue(11)/2000, 0.2), 9.99)}
	tes3.playSound{sound = ef.object.areaSoundEffect, reference = r}
	RUN[r] = {s = s, tim = (100 + mp.intelligence.current + mp:getSkillValue(11) + mp:getSkillValue(14))*0.3}
	local light = niPointLight.new()	light:setAttenuationForRadius(ef.radius/2)		light.diffuse = tes3vector3.new(ef.object.lightingRed, ef.object.lightingGreen, ef.object.lightingBlue)
	r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
	if not RunT.timeLeft then RunT = timer.start{duration = 1, iterations = -1, callback = function() local fin = true
		for run, t in pairs(RUN) do	t.tim = t.tim - 1	if t.tim > 0 then	fin = false
			for r in tes3.iterate(run.cell.actors) do if r.mobile and not r.mobile.isDead and run.position:distance(r.position) < 80 * run.scale then
				mwscript.explodeSpell{reference = run, spell = t.s}	run:deleteDynamicLightAttachment() 	run:disable()	run.modified = false	RUN[run] = nil
			end end
		else mwscript.explodeSpell{reference = run, spell = t.s}	run:deleteDynamicLightAttachment() 	run:disable()	run.modified = false	RUN[run] = nil	end end
		if fin then RunT:cancel() end
	end} end
end
end end end end		event.register("spellCasted", SPELLCASTED)


-- Если снаряд исчез в воздухе, то событие срабатывает но тотем НЕ создается из-за проверки на дальность
local function PROJECTILEEXPIRE(e) if (Flag or MB[cf.mb] == 128) and e.firingReference == p then	local si = e.mobile.spellInstance	if si then	local s = si.source
if s.objectType == tes3.objectType.spell and s.castType == 0 then		local pos = e.mobile.reference.position		if p.position:distance(pos) < 4800 then		local ef = s.effects[1]		SOU[s] = 2
	local r = tes3.createReference{object = Totem, position = pos + tes3vector3.new(0,0,60*(1 + ef.radius/50)), cell = p.cell, scale = 1 + ef.radius/50}
	TOT[r] = {s = s, cost = s.magickaCost * cf.mct/100, tim = (mp.intelligence.current + mp.willpower.current + mp.mysticism.current)/10}
	local light = niPointLight.new()	light:setAttenuationForRadius((1 + ef.radius/50)*3)		light.diffuse = tes3vector3.new(ef.object.lightingRed, ef.object.lightingGreen, ef.object.lightingBlue)
	r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
	if not TotT.timeLeft then local dur = math.max(2 - mp.alteration.current/200, 1.5)	TotT = timer.start{duration = dur, iterations = -1, callback = function()
		local fin = true	local tref, mindist, dist, m	local AC = {}	for _, cell in pairs(tes3.getActiveCells()) do AC[cell] = true end		local rad = (100 + mp.intelligence.current + mp.mysticism.current) * 20
		for tot, t in pairs(TOT) do t.tim = t.tim - dur		if t.tim > 0 then fin = false
			if TotMod and AC[tot.cell] and mp.magicka.current > t.cost then tref = nil		mindist = rad
				for c, _ in pairs(AC) do for r in tes3.iterate(c.actors) do m = r.mobile	if m and not m.isDead and (cf.agr or m.actionData.target == mp) and tes3.getCurrentAIPackageId(m) ~= 3 then
					dist = tot.position:distance(r.position)		if mindist > dist then mindist = dist	tref = r end
				end end end
				if tref then tes3.cast{reference = tot, spell = t.s, target = tref}		mp.magicka.current = mp.magicka.current - t.cost	MMana.current = mp.magicka.current end
			end
		else	tot:deleteDynamicLightAttachment()	tot:disable()	tot.modified = false	TOT[tot] = nil end end		
		if fin then TotT:cancel() end
	end} end
end end
end end end		event.register("projectileExpire", PROJECTILEEXPIRE)


local function KEYDOWN(e) if not tes3ui.menuMode() then
	if e.isShiftDown then 	TotMod = not TotMod	tes3.messageBox("Totem shooting = %s", TotMod)
	elseif e.isControlDown then	for run, t in pairs(RUN) do mwscript.explodeSpell{reference = run, spell = t.s}	run:deleteDynamicLightAttachment() 	run:disable()	run.modified = false	RUN = {} end
	elseif e.isAltDown then	for tot, t in pairs(TOT) do t.tim = 0 end
	else Flag = not Flag	tes3.messageBox("Rune/Totem creation mode = %s", Flag) end
end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		SOU = {}
	MMana = tes3ui.findMenu(-526):findChild(-865).widget
	for tot, t in pairs(TOT) do tot:deleteDynamicLightAttachment()	tot:disable()	tot.modified = false end		TOT = {}
	for run, t in pairs(RUN) do run:deleteDynamicLightAttachment()	run:disable()	run.modified = false end		RUN = {}
end		event.register("loaded", loaded)


local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Runes and Totems")	tpl:saveOnClose("Runes and Totems", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Key to switch rune/totem creation mode (requires game restart). Press with Shift to stop totem shooting. Press with Ctrl to explode all runes. Press with Alt to destroy all totems"}
p0:createSlider{label = "Mouse button to rune/totem creation mode (Hold to enable): 1 - left, 2 - right, 3 - middle", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mb", table = cf}}
p0:createYesNoButton{label = "Agressive mode", variable = var{id = "agr", table = cf}}
p0:createSlider{label = "Manacost multiplier for totem shooting", min = 20, max = 100, step = 1, jump = 5, variable = var{id = "mct", table = cf}}
p0:createSlider{label = "Manacost multiplier for rune creating", min = 50, max = 100, step = 1, jump = 5, variable = var{id = "mcr", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	MB = tes3.worldController.inputController.mouseState.buttons
	Totem = tes3.getObject("4nm_totem") or tes3.createObject{objectType = tes3.objectType.static, id = "4nm_totem", mesh = "e\\totem.nif"}
	Rune = tes3.getObject("4nm_rune") or tes3.createObject{objectType = tes3.objectType.static, id = "4nm_rune", mesh = "e\\rune.nif"}
end		event.register("initialized", initialized)