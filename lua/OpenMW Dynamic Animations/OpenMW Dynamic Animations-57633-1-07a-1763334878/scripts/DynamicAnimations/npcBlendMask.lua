local self = require("openmw.self")
local I = require("openmw.interfaces")
local ctrls = self.controls

I.ODAR.addPlayBlendedAnimationHandler(function (g, o)
	if g:find("^walkforward") or g:find("^runforward") then
		if o.blendMask == 1 then
			o.blendMask = 3
		--	print("FIXBLEND")
		end
	elseif g == "idlestorm" then
		if o.blendMask == 10 then
			o.blendMask = 8
		--	print("FIXBLEND")
		end
	elseif g:find("spellcast$") and ctrls.movement > 0 then
		o.blendMask = 12
	end
end)

return
