local time = require("openmw_aux.time")
local I = require("openmw.interfaces")

local idlespam = false


I.AnimationController.addPlayBlendedAnimationHandler(function (g, o)
  -- Block spamming of messages about playing idle animations every frame
	if g ~= "idle1h" and g ~= "idle2c" and g ~= "idlehh" then
		idlespam = false
	else
		if not idlespam then idlespam = true
		else return end
	end
	print(g)
end)


time.runRepeatedly(function() idlespam = false end, 5 * time.second)


return
