local cf = mwse.loadConfig("Ultra Bloom", {bloom = 0.7, radmult = 1, contrast = 0.5, saturation = 1.5, exposure = 1, intexp = 0.5, nigthexp = 1})
local S, wc, Hour, Tim		local hour = 12


local function GetExp()	hour = Hour.value		local bonus
    if hour > 6 and hour < 8 then bonus = math.lerp(cf.nigthexp, 0, (hour - 6)/2)
    elseif hour > 8 and hour < 18 then bonus = 0
    elseif hour > 18 and hour < 20 then bonus = math.lerp(0, cf.nigthexp, (hour - 18)/2)
    else bonus = cf.nigthexp end
	return cf.exposure + bonus
end

local function SetExp() if S then
	if tes3.player.cell.isOrBehavesAsExterior then S.exposure = GetExp()
	else S.exposure = cf.exposure + cf.intexp end
end end


local function registerModConfig() local tpl = mwse.mcm.createTemplate("Ultra Bloom")	tpl:saveOnClose("Ultra Bloom", cf)	tpl:register()		local p0 = tpl:createPage()		local var = mwse.mcm.createTableVariable
S = mge.shaders.find{name = "Ultra Bloom"}
p0:createDecimalSlider{label = "Bloom power", max = 1, variable = var{id = "bloom", table = cf}, callback = function() if S then S.sun = 1 - cf.bloom end end}
p0:createDecimalSlider{label = "Bloom radius mult", min = 0.1, max = 5, step = 0.05, jump = 0.1, variable = var{id = "radmult", table = cf}, callback = function() if S then S.radmult = cf.radmult end end}
p0:createDecimalSlider{label = "Contrast", max = 1, variable = var{id = "contrast", table = cf}, callback = function() if S then S.contrast = cf.contrast end end}
p0:createDecimalSlider{label = "Saturation", max = 3, step = 0.1, jump = 0.5, variable = var{id = "saturation", table = cf}, callback = function() if S then S.saturation = cf.saturation end end}
p0:createDecimalSlider{label = "Exposure", min = 0.5, max = 3, step = 0.05, jump = 0.1, variable = var{id = "exposure", table = cf}, callback = SetExp}
p0:createDecimalSlider{label = "Interior exposure bonus", min = -0.5, max = 2, step = 0.05, jump = 0.1, variable = var{id = "intexp", table = cf}, callback = SetExp}
p0:createDecimalSlider{label = "Night exposure bonus", min = -0.5, max = 2, step = 0.05, jump = 0.1, variable = var{id = "nigthexp", table = cf}, callback = SetExp}
end		event.register("modConfigReady", registerModConfig)


local function simulate()
	if S then S.exposure = GetExp() end
end


local function cellChanged(e)
	if e.cell.isOrBehavesAsExterior then
		if not event.isRegistered("simulate", simulate) then event.register("simulate", simulate) end
	else event.unregister("simulate", simulate)		if S then S.exposure = cf.exposure + cf.intexp end	end
end		event.register("cellChanged", cellChanged)


local function loaded(e)   Hour = tes3.worldController.hour		S = mge.shaders.find{name = "Ultra Bloom"}
	if S then	S.contrast = cf.contrast	S.saturation = cf.saturation	S.sun = 1 - cf.bloom	S.radmult = cf.radmult		SetExp()
	else Tim = timer.start{duration = 2, iterations = -1, callback = function()	S = mge.shaders.find{name = "Ultra Bloom"}
		if S then S.contrast = cf.contrast	S.saturation = cf.saturation	S.sun = 1 - cf.bloom	S.radmult = cf.radmult		SetExp()		Tim:cancel() end
	end} end
end		event.register("loaded", loaded)