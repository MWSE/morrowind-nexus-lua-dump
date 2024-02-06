local cf = mwse.loadConfig("Gamma", {gam = 1, sat = 1, lum = 1})
local GAM
local function registerModConfig() local tpl = mwse.mcm.createTemplate("Gamma")	tpl:saveOnClose("Gamma", cf)	tpl:register()		local p0 = tpl:createPage()		local var = mwse.mcm.createTableVariable
GAM = mge.shaders.find{name = "Gamma"}
p0:createDecimalSlider{label = "Gamma", max = 5, variable = var{id = "gam", table = cf}, callback = function() GAM.gamma = cf.gam end}
p0:createDecimalSlider{label = "Saturation", max = 5, variable = var{id = "sat", table = cf}, callback = function() GAM.saturation = cf.sat end}
p0:createDecimalSlider{label = "Luminance", max = 5, variable = var{id = "lum", table = cf}, callback = function() GAM.luminance = cf.lum end}
end		event.register("modConfigReady", registerModConfig)

local function loaded(e)
	GAM.gamma = cf.gam		GAM.saturation = cf.sat		GAM.luminance = cf.lum
end		event.register("loaded", loaded)