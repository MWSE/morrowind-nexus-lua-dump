local cf = mwse.loadConfig("Fast Cast", {lvl = 1, min = 30, max = 100})
local mp, ad, ic

local function SPELLCAST(e) if e.source.castType == 0 or e.source.castType == 5 then	local m = e.caster.mobile
	if m == mp then 		
		if mp.speed.current >= cf.max then 
			if ad.animationAttackState == 11 then if ic:keybindTest(tes3.keybind.readyMagic) then timer.start{duration = 0.1, callback = function() ad.animationAttackState = 0 end} else ad.animationAttackState = 0 end end
		elseif mp.speed.current > cf.min then timer.start{duration = math.clamp((cf.max - mp.speed.current) / (cf.max - cf.min), 0.01, 0.99), callback = function()
			if ad.animationAttackState == 11 then if ic:keybindTest(tes3.keybind.readyMagic) then timer.start{duration = 0.1, callback = function() ad.animationAttackState = 0 end} else ad.animationAttackState = 0 end end
		end} end
	elseif (m.actorType == 1 or m.object.biped) and m.object.level >= cf.lvl and m.actionData.animationAttackState == 11 then m.actionData.animationAttackState = 0 end
end end		event.register("spellCast", SPELLCAST)


local function loaded(e)	mp = tes3.mobilePlayer		ad = mp.actionData		ic = tes3.worldController.inputController
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Fast Cast")	tpl:saveOnClose("Fast Cast", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "The minimum speed value from which your cast time will begin to decrease", min = 0, max = 200, step = 10, jump = 50, variable = var{id = "min", table = cf}}
p0:createSlider{label = "The speed value at which you will receive a maximum 50% reduction of cast time", min = 100, max = 500, step = 10, jump = 50, variable = var{id = "max", table = cf}}
p0:createSlider{label = "The level of NPCs, from which they will use fast cast", min = 1, max = 100, step = 1, jump = 5, variable = var{id = "lvl", table = cf}}
end		event.register("modConfigReady", registerModConfig)