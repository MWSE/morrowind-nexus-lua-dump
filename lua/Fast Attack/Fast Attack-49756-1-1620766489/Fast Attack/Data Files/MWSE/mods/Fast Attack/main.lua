
local cf = mwse.loadConfig("Fast Attack", {msg = true, spd = 10, dist = 5})
local p, mp, D
local WT = {[-1] = 26, [0] = 22, [1] = 5, [2] = 5, [3] = 4, [4] = 4, [5] = 4, [6] = 7, [7] = 6, [8] = 6, [9] = 23, [10] = 23, [11] = 23}

local function GetWstat() local w = mp.readiedWeapon and mp.readiedWeapon.object	local wt = w and w.type or -1		if w then
	if not D.lw then D.lw = {id = w.id, s = w.speed, r = w.reach} end
	if w.id == D.lw.id then
		w.speed = D.lw.s + math.floor((mp.speed.base + mp:getSkillStatistic(WT[wt]).base)/100 * cf.spd)/100
		if wt < 9 then w.reach = D.lw.r + math.floor((mp.agility.base + mp:getSkillStatistic(WT[wt]).base)/100 * cf.dist)/100 end
		if cf.msg then tes3.messageBox("%s  Speed = %.2f (%.2f base)  Reach = %.2f (%.2f base)", w.name, w.speed, D.lw.s, w.reach, D.lw.r) end
	end
end end


-- Во время события equipped mp.readiedWeapon == нил! Надо ждать фрейм
local function EQUIPPED(e) if e.reference == p and e.item.objectType == tes3.objectType.weapon then
	timer.delayOneFrame(function() GetWstat() end, timer.real)
end end		event.register("equipped", EQUIPPED)


local function UNEQUIPPED(e) if e.reference == p and e.item.objectType == tes3.objectType.weapon then
	if D.lw then local w = tes3.getObject(D.lw.id)	w.speed = D.lw.s	w.reach = D.lw.r	D.lw = nil end		GetWstat()
end end		event.register("unequipped", UNEQUIPPED)


local function LOAD(e) 
if p and D.lw then local w = tes3.getObject(D.lw.id)	w.speed = D.lw.s	w.reach = D.lw.r end 
end		event.register("load", LOAD)


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		D = p.data		GetWstat()
end		event.register("loaded", loaded)


local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Fast Attack")	tpl:saveOnClose("Fast Attack", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Weapon speed multiplier", min = 0, max = 50, step = 1, jump = 5, variable = var{id = "spd", table = cf}}
p0:createSlider{label = "Weapon range multiplier", min = 0, max = 25, step = 1, jump = 5, variable = var{id = "dist", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)