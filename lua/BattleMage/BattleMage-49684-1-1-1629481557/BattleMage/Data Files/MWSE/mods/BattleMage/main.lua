local cf = mwse.loadConfig("BattleMage", {KEY = {keyCode = 44}, mc = 150, cast = 50})
local p, mp, ad, D, Bar, MMana, B, S		local MP = {}
local MT = {__index = function(t, k) t[k] = {} return t[k] end}		local SS = setmetatable({}, MT)		local BS = setmetatable({}, MT)

local function SPELLRESIST(e)	if e.caster == p then	local si		local tid = e.target.id		local s = e.source		local sid = s.id		local sn = e.sourceInstance.serialNumber
	if s.objectType == tes3.objectType.spell and s.castType == 0 then
		if BS[tid][sid] then si = tes3.getMagicSourceInstanceBySerial{serialNumber = BS[tid][sid]}	if si then si.state = 6 end		BS[tid][sid] = nil end
		SS[tid][sid] = sn
	elseif s.name == "4b_AS" then if SS[tid][S.id] and SS[tid][S.id] ~= sn then si = tes3.getMagicSourceInstanceBySerial{serialNumber = SS[tid][S.id]}	if si then si.state = 6 end end
		SS[tid][S.id] = sn		BS[tid][S.id] = sn
	end
end end		event.register("spellResist", SPELLRESIST)


local function ATTACK(e) if e.mobile == mp then		local w = mp.readiedWeapon	local ob = w and w.object	local en = ob and ob.enchantment
	if en and en.castType == 1 and ob.type < 9 and en.effects[1].rangeType == 2 then tes3.applyMagicSource{reference = p, source = en, fromStack = w} end
	
	if D.Acast then local s = mp.currentSpell		if s and s.objectType == tes3.objectType.spell and s.castType == 0 and (s.flags == 4 or Bar.current - cf.cast > math.random(100)) then
		if s ~= S then S = s
			for i, eff in ipairs(s.effects) do B.effects[i].id = eff.id		B.effects[i].min = eff.min		B.effects[i].max = eff.max		B.effects[i].duration = eff.duration
				B.effects[i].radius = eff.radius		B.effects[i].rangeType = eff.rangeType		B.effects[i].attribute = eff.attribute		B.effects[i].skill = eff.skill
			end
		end
		local mc = s.magickaCost * cf.mc/100		local stc = mc * (0.5 + 0.5 * mp.encumbrance.normalized)
		if mp.magicka.current > mc and mp.fatigue.current > stc then
			mp.magicka.current = mp.magicka.current - mc		MMana.current = mp.magicka.current		mp.fatigue.current = mp.fatigue.current - stc
			timer.delayOneFrame(function() tes3.applyMagicSource{reference = p, source = B} end)
		end
	end end
end end		event.register("attack", ATTACK)


local function MOBILEACTIVATED(e) local m = e.mobile	if m and m.firingMobile == mp then	local si = m.spellInstance
	if si then local t = MP[si]
		if t then timer.delayOneFrame(function() m.position = t.pos 	if t.exp then m:explode() elseif t.vel then m.velocity = t.vel * m.initialSpeed end		MP[si] = nil end) return end
	end
end end		event.register("mobileActivated", MOBILEACTIVATED)


local function PROJECTILEEXPIRE(e) if e.firingReference == p then local m = e.mobile	if not m.spellInstance then	local fw = m.firingWeapon	local en = fw.enchantment	local rw = mp.readiedWeapon
	if en and en.castType == 1 and en.effects[1].rangeType == 2 and fw.type < 11 and rw and fw == rw.object then
		MP[tes3.applyMagicSource{reference = p, source = en, fromStack = rw}] = {pos = m.reference.position:copy(), exp = true}
	end
end end end		event.register("projectileExpire", PROJECTILEEXPIRE)


local function KEYDOWN(e) if not tes3ui.menuMode() then D.Acast = not D.Acast	tes3.messageBox("Swing cast mode = %s", D.Acast) end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		ad = mp.actionData		D = p.data
	Bar = tes3ui.findMenu(-526):findChild(-546).widget		MMana = tes3ui.findMenu(-526):findChild(-865).widget
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("BattleMage")	tpl:saveOnClose("BattleMage", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Key to switch the casting mode when attacking (requires restarting the game)"}
p0:createSlider{label = "Manacost multiplier for casting spells when attacking", min = 100, max = 200, step = 1, jump = 5, variable = var{id = "mc", table = cf}}
p0:createSlider{label = "Penalty to the chance of casting a spell when attacking", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "cast", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	--wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
	B = tes3alchemy.create{id = "4b_AS", name = "4b_AS", icon = "s\\b_tx_s_sun_dmg.dds"} 	B.sourceless = true
end		event.register("initialized", initialized)