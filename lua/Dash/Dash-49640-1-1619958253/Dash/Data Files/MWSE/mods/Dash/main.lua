local cf = mwse.loadConfig("Dash", {KEY = {keyCode = 42}, mult = 5, fat = 50, acr = 50})		local p, mp	 local Matr = tes3matrix33.new()	local V = {}

V.Dash = function(e) if e.reference == p then mp.impulseVelocity = V.d*(1/30/tes3.worldController.deltaTime)	V.dfr = V.dfr - 1		if V.dfr <= 0 then event.unregister("calcMoveSpeed", V.Dash)	V.dfr = nil end end end
local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer end		event.register("loaded", loaded)

local function KEYDOWN(e) if not tes3ui.menuMode() and not V.dfr and mp.hasFreeAction and mp.paralyze < 1 and mp.fatigue.current > cf.fat and (not mp.isJumping or mp.acrobatics.current >= cf.acr) then
	local ang	local DD = math.min(mp.speed.current + mp.agility.current, 400) * cf.mult		local stam = cf.fat
	if mp.isMovingForward then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end
	elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
	elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 end
	V.d = tes3.getPlayerEyeVector()		if ang then Matr:toRotationZ(math.rad(ang))		V.d = Matr * V.d end
	V.d.x = V.d.x/(1 - V.d.z^2)^0.5		V.d.y = V.d.y/(1 - V.d.z^2)^0.5		V.d.z = 0		if mp.isMovingBack then V.d = V.d * -1 end
	local dhit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = V.d, ignore={p}}		if dhit then dhit = dhit.distance/(DD*7/30)	if dhit < 1 then DD = DD * dhit		stam = stam * dhit end end
	V.d = V.d*DD	V.dfr = 7	event.register("calcMoveSpeed", V.Dash)		tes3.playSound{sound = math.random(2) == 1 and "FootBareLeft" or "FootBareRight"}		mp.fatigue.current = mp.fatigue.current - stam
end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Dash")	tpl:saveOnClose("Dash", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Dash key"}
p0:createSlider{label = "Dash speed multiplier", min = 3, max = 20, step = 1, jump = 1, variable = var{id = "mult", table = cf}}
p0:createSlider{label = "Stamina cost", min = 10, max = 100, step = 1, jump = 10, variable = var{id = "fat", table = cf}}
p0:createSlider{label = "Minimum acrobatics skill for jumping dash", min = 5, max = 100, step = 1, jump = 5, variable = var{id = "acr", table = cf}}
end		event.register("modConfigReady", registerModConfig)