local cf = mwse.loadConfig("ManaShield", {msg = false, snd = true, mc = 100, mag = 10, max = 200})
local p, mp


local function DAMAGE(e) if e.mobile == mp and (e.source == "attack" or e.source == "fall") and mp.magicka.current > 1 then 
	local M = math.min(tes3.getEffectMagnitude{reference = p, effect = 3} * cf.mag/100, cf.max, mp.magicka.current * 100/cf.mc)
	if M > 0 then
		local Dred = math.min(e.damage, M)		e.damage = e.damage - Dred		local mc = Dred * cf.mc/100		tes3.modStatistic{reference = p, name = "magicka", current = -mc}
		if cf.snd and e.source == "attack" then tes3.playSound{reference = p, sound = "Spell Failure Destruction"} end
		if cf.msg then tes3.messageBox("Shield! %.1f damage   %.1f reduction   %.1f max   %.1f cost", e.damage, Dred, M, mc) end
	end
end end		event.register("damage", DAMAGE, {priority = -1000})


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		--ad = mp.actionData		--D = p.data
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("ManaShield")	tpl:saveOnClose("ManaShield", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Magnitude multiplier for your manashield", min = 5, max = 100, step = 1, jump = 5, variable = var{id = "mag", table = cf}}
p0:createSlider{label = "Manacost multiplier for your manashield", min = 50, max = 500, step = 1, jump = 5, variable = var{id = "mc", table = cf}}
p0:createSlider{label = "The maximum damage that your manashield will absorb in 1 hit (Set to 0 to disable manashield ability)", min = 0, max = 200, step = 1, jump = 5, variable = var{id = "max", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
p0:createYesNoButton{label = "Play manashield sound", variable = var{id = "snd", table = cf}}
end		event.register("modConfigReady", registerModConfig)