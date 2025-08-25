local config = require("Click to Draw.config")

local log = mwse.Logger.new({
	name = "Click to Draw",
	logLevel = config.logLevel,
})

dofile("Click to Draw.mcm")

local hasSwiftCast = tes3.hasCodePatchFeature(tes3.codePatchFeature.swiftCasting)
local hasStrikeBinds

event.register(tes3.event.initialized, function()
	hasStrikeBinds = tes3.isLuaModActive("Strike Binds")
end)

local function isSomethingReady()
	return tes3.mobilePlayer.weaponReady or tes3.mobilePlayer.spellReadied
end

---@param e mouseButtonDownEventData
local function onMouseDown(e)
	if tes3.menuMode() then return end

	local somethingReady = isSomethingReady()
	if e.button == config.draw.mouseButton and not hasStrikeBinds and not somethingReady then
		tes3.mobilePlayer.weaponReady = true
		return
	end

	if e.button == config.sheath.mouseButton and somethingReady then
		tes3.mobilePlayer.weaponReady = false
		tes3.mobilePlayer.castReady = false
		return
	end

	if e.button == config.raiseHands.mouseButton and not hasSwiftCast and not somethingReady then
		tes3.mobilePlayer.castReady = true
		return
	end
end

event.register(tes3.event.mouseButtonDown, onMouseDown)


--- Strike Binds compatibility
---@param e keyDownEventData
local function onKeyDown(e)
	if not hasStrikeBinds then return end
	if tes3.menuMode() then return end

	if not isSomethingReady() then
		tes3.mobilePlayer.weaponReady = true
	end
end

event.register(tes3.event.keyDown, onKeyDown, { priority = -50, filter = tes3.scanCode.apps })
