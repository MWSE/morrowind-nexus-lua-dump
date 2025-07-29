local config = require("Click to Draw.config")

local log = mwse.Logger.new({
	name = "Click to Draw",
	logLevel = config.logLevel,
})

dofile("Click to Draw.mcm")

local hasSwiftCast = tes3.hasCodePatchFeature(tes3.codePatchFeature.swiftCasting)

---@param e mouseButtonDownEventData
local function onInput(e)
	if tes3.menuMode() then return end

	local weaponReady = tes3.mobilePlayer.weaponReady
	local spellReady = tes3.mobilePlayer.spellReadied
	if e.button == config.draw.mouseButton and not weaponReady and not spellReady then
		tes3.mobilePlayer.weaponReady = true
		return
	end

	if e.button == config.sheath.mouseButton and (weaponReady or spellReady) then
		tes3.mobilePlayer.weaponReady = false
		tes3.mobilePlayer.castReady = false
		return
	end

	if e.button == config.raiseHands.mouseButton and not hasSwiftCast and not spellReady then
		tes3.mobilePlayer.castReady = true
		return
	end
end

event.register(tes3.event.mouseButtonDown, onInput)
