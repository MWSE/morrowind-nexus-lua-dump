local cf = mwse.loadConfig("Armor Rating", {max = 90})
local AT = {[0] = 21, [1] = 2, [2] = 3, [3] = 17}

local function CALCARMORRATING(e) local m = e.mobile	if m then local a = e.armor
	e.armorRating = a.armorRating * (1 + m:getSkillValue(AT[a.weightClass])/100) * (a.weight == 0 and 0.5 + m:getSkillValue(13)/200 or 1)		e.block = true
end end		event.register("calcArmorRating", CALCARMORRATING)


local function loaded(e)
	tes3.findGMST("fCombatArmorMinMult").value = 1 - cf.max/100
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Armor Rating")	tpl:saveOnClose("Armor Rating", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Maximum percentage of damage reduction with armor (save load required)", min = 50, max = 99, step = 1, jump = 5, variable = var{id = "max", table = cf}}
end		event.register("modConfigReady", registerModConfig)