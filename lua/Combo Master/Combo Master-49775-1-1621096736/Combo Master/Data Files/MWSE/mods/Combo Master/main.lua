
local cf = mwse.loadConfig("Combo Master", {min = 0})
local p, mp, ad, wc, ic, MB		local W = {}	local L = {AS = {[2]=0, [3]=0, [4]=0, [5]=1, [6]=1, [7]=1}}



L.WComb = function(d, one) local m1 = (mp.isMovingForward or mp.isMovingBack)	local m2 = (mp.isMovingLeft or mp.isMovingRight)		local mov = m1 and (m2 and 3 or 1) or (m2 and 2 or 0)
	if d == 1 then	-- Режущая
		if mov == 3 then if one then MB[1] = 0 end	ad.animationAttackState = 0									-- наискосок рубящая (отмена только с двуручем и возможно с кулаком)
		elseif mov == 0 then if one then MB[1] = 0 end	ad.animationAttackState = 0		ad.attackDirection = 2		-- стоять рубящая (отмена только с двуручем)
		elseif mov == 1 then MB[1] = 0		ad.animationAttackState = 0 end										-- вперед колющая, странная отмена только с кулаком
	elseif d == 3 then	-- Колющая
		if mov == 2 then ad.animationAttackState = 0	ad.attackDirection = 0					-- вбок режущая с отменой
		elseif mov == 3 then if one == 0 then MB[1] = 0 end		ad.animationAttackState = 0		-- наискосок рубящая с отменой кроме кулака
		elseif mov == 0 then if one == 0 then MB[1] = 0 end		ad.animationAttackState = 0		ad.attackDirection = one == 0 and 0 or 2 end	-- стоять рубящая с отменой (отмена только с оружием)
	elseif d == 2 then	-- Рубящая
		if mov == 2 then if not one then MB[1] = 0 end	ad.animationAttackState = 0		ad.attackDirection = 0		-- вбок режущая (отмена только с одноручем или кулаком)
		elseif mov == 1 then if one ~= 0 then MB[1] = 0	end		ad.animationAttackState = 0						-- вперед колющая (отмена только с кулаком)
		elseif mov == 0 then if one == 0 then ad.animationAttackState = 0		ad.attackDirection = 3 end end		-- стоять колющая только для кулака
	end
end
L.WSim = function(e) if mp.weaponDrawn and MB[1] == 128 then	--tes3.messageBox("AS = %s", ad.animationAttackState)
	if L.AS[ad.animationAttackState] == 1 then		--local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
		L.WComb(ad.attackDirection, not mp.readiedWeapon and 0 or mp.readiedWeapon.object.isOneHanded) 	event.unregister("simulate", L.WSim)	W.Wsim = nil
	end
else event.unregister("simulate", L.WSim)	W.Wsim = nil end end


local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() and e.button == 0 and mp.weaponDrawn then	local w = mp.readiedWeapon		w = w and w.object	local wt = w and w.type or -1
	if wt < 9 and ad.animationAttackState > 0 and ad.attackSwing >= cf.min/100 then
		if L.AS[ad.animationAttackState] == 1 then	L.WComb(ad.attackDirection, not w and 0 or w.isOneHanded)
		elseif not W.Wsim then event.register("simulate", L.WSim)	W.Wsim = 1 end
	end
end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer	ad = mp.actionData
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Combo Master")	tpl:saveOnClose("Combo Master", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Minimum swing for combo attacks", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "min", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
end		event.register("initialized", initialized)