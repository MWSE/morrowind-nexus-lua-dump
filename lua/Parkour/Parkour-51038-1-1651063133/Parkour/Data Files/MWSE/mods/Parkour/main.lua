
local cf = mwse.loadConfig("Parkour", {m = false, KEY = {keyCode = 18}})
local p, mp, pp, wc		local L = {}		local V = {up = tes3vector3.new(0,0,1), down = tes3vector3.new(0,0,-1), nul = tes3vector3.new(0,0,0)}		local Matr = tes3matrix33.new()	


L.Dash = function(e) if e.reference == p then		mp.impulseVelocity = V.d*(1/wc.deltaTime)	V.dfr = V.dfr - 1
if V.dfr <= 0 then event.unregister("calcMoveSpeed", L.Dash)	V.dfr = nil end
end end


L.KIK = function() if mp.hasFreeAction and mp.paralyze < 1 and mp.velocity:length()~=0 and not V.dfr then
local maxd = 70 + math.min(mp.agility.current/2, 50)		local foot		local climb
local vdir = tes3.getPlayerEyeVector()		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vdir, maxDistance = maxd, ignore={p}}
if hit then climb = true else foot = true
	hit = tes3.rayTest{position = pp + tes3vector3.new(0,0,5), direction = p.sceneNode.rotation:transpose().y, maxDistance = maxd, ignore={p}}
	if hit then climb = true else hit = mp.isMovingLeft and 1 or (mp.isMovingRight and -1)
		if hit then vdir = p.sceneNode.rotation:transpose().x * hit
			hit = tes3.rayTest{position = pp + tes3vector3.new(0,0,5), direction = vdir, maxDistance = maxd, ignore={p}}
			if hit then climb = true end
		end
	end
end

if climb then
	local s = mp:getSkillValue(20)		stc = math.max(20 + mp.encumbrance.normalized*(30 - mp:getSkillValue(8)/10) - s/10, 10)
	if mp.fatigue.current > stc then local ang = 0
		if mp.isMovingForward then if foot then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end else V.d = V.up end
		elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
		elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 else V.d = V.up end
		if V.d ~= V.up then Matr:toRotationZ(math.rad(ang))		V.d = Matr * tes3.getPlayerEyeVector()
			if mp.isMovingBack then V.d = V.d*-1 elseif ang == 90 or ang == 270 then V.d.x = V.d.x/(1 - V.d.z^2)^0.5		V.d.y = V.d.y/(1 - V.d.z^2)^0.5 end		V.d.z = 1
		end
		local imp = math.min(100 + mp.strength.current/2 + s/2, 200) * (0.5 + math.min(mp.fatigue.normalized,1)/2)		if s > 50 then mp.velocity = V.nul end		mp.isSwimming = false
		V.d = V.d * (imp/8)		V.dfr = 8	event.register("calcMoveSpeed", L.Dash)		mp.fatigue.current = mp.fatigue.current - stc		mp:exerciseSkill(20,0.2)
		tes3.playSound{sound = math.random(2) == 1 and "LeftS" or "LeftM"}
		if cf.m then tes3.messageBox("Climb-jump! impuls = %d  cost = %d", imp, stc) end
	end
end
end end


local function KEYDOWN(e) if not tes3ui.menuMode() then L.KIK() end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})

local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		pp = p.position		wc = tes3.worldController 	end		event.register("loaded", loaded)

local function registerModConfig()		local tpl = mwse.mcm.createTemplate("Parkour")	tpl:saveOnClose("Parkour", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Climb button - it is recommended to assign the same button as for the jump. Changing the button requires restarting the game."}
p0:createYesNoButton{label = "Show messages", variable = var{id = "m", table = cf}}
end		event.register("modConfigReady", registerModConfig)