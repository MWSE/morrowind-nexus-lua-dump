local core = require("openmw.core")
local self = require("openmw.self")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")

I.AnimationController.addPlayBlendedAnimationHandler(function (g, options)
	if g ~= "shield" then return end
	anim.addVfx(self, "meshes/e/impact/shieldBlock.nif", {boneName="Shield Bone"})
end)

local function cleaner()
	core.sendGlobalEvent("impactPurgeLocal", self)
end

return { engineHandlers = { onInactive = cleaner }, eventHandlers = { Died = cleaner } }
