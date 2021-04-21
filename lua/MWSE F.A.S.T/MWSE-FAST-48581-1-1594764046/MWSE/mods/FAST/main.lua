local function onCalcMoveSpeed(e)
	local cfat = e.mobile.fatigue.current
	local bfat = e.mobile.fatigue.base
	local rfat = (cfat / bfat)
	if rfat < .4 then rfat = .4 end
	e.speed = e.speed * rfat
end
event.register("calcMoveSpeed", onCalcMoveSpeed)