local cf = mwse.loadConfig("Frenzy n'wahs", {msg = false, rad = 3, minp = 50})

local function SPELLRESIST(e)	local ef = e.effect		if ef.id == 51 or ef.id == 52 then		local t = e.target	local m = t.mobile	local mag = math.random(ef.min, ef.max) * ef.duration
	local pow = mag * (1 - e.resistedPercent/100)	local minp = (10 + t.object.level) * cf.minp		local rad = mag * cf.rad
	if pow > minp then	m.actionData.aiBehaviorState = 3
		for _, c in pairs(tes3.getActiveCells()) do for r in tes3.iterate(c.actors) do if r.mobile and not r.mobile.isDead and r ~= t and rad > t.position:distance(r.position) then m:startCombat(r.mobile) end end end
	end
	if cf.msg then tes3.messageBox("%s Frenzy %s    power = %d/%d  rad = %d", pow > minp and "worked" or "did not work", t, pow, minp, rad) end
end end		event.register("spellResist", SPELLRESIST, {priority = -1000})

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Frenzy n'wahs")	tpl:saveOnClose("Frenzy n'wahs", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
p0:createSlider{label = "The ability of enemies to resist frenzy", min = 10, max = 300, step = 10, jump = 50, variable = var{id = "minp", table = cf}}
p0:createSlider{label = "Radius multiplier within which frenzied will seek targets", min = 1, max = 10, step = 1, jump = 1, variable = var{id = "rad", table = cf}}
end		event.register("modConfigReady", registerModConfig)