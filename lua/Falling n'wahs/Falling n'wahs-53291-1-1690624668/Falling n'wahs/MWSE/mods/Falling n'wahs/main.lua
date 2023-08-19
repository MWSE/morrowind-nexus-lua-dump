local cf = mwse.loadConfig("Falling n'wahs", {grav = 1000, maxg = 5000, dmgm = 100})
local p, mp, wc

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Falling n'wahs")	tpl:saveOnClose("Falling n'wahs", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Gravity force. Requires a save load", min = 200, max = 3000, step = 50, jump = 100, variable = var{id = "grav", table = cf}}
p0:createSlider{label = "Maximum free fall speed. Requires a save load", min = 1000, max = 20000, step = 200, jump = 1000, variable = var{id = "maxg", table = cf}}
p0:createSlider{label = "Fall damage multiplier", min = 20, max = 500, step = 5, jump = 10, variable = var{id = "dmgm", table = cf}}
end		event.register("modConfigReady", registerModConfig)



local function damage(e) if e.source == "fall" then	local t = e.mobile	local vel = -t.velocity.z		local skill = t:getSkillValue(20)
	local DMG = math.max((vel - 700 - skill * (t == mp and skill > 49 and 8 or 5)) * (t == mp and skill > 99 and 0.05 or 0.1) / (1 + t.agility.current/200), 0) * cf.dmgm/100
	
	--tes3.messageBox("Fall!  Vel = %d    DMG = %d  -->  %d", vel, e.damage, DMG)
	
	if t == mp then
		if DMG < 0.1 then timer.delayOneFrame(function() wc.hitFader:deactivate() end) end
	end
	e.damage = DMG
end	end		event.register("damage", damage)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer
wc.mobManager.gravity.z = -cf.grav		wc.mobManager.terminalVelocity.z = -cf.maxg
end		event.register("loaded", loaded)


local function initialized(e) wc = tes3.worldController
tes3.findGMST("fFallDistanceMult").value = 0.1			tes3.findGMST("fFallDamageDistanceMin").value = 400		tes3.findGMST("fFallAcroBase").value = 1
end		event.register("initialized", initialized)