--[[
Squeaky Wheel Gets The Kick!

Change Player Point Of View/Zoom by scrolling mouse wheel.

(State)>>[Action] sequences:
(3rd person view)>>[scroll up]>>(1st person view)>>[scroll up]>>(zoom in)

(zoomed in)>>[scroll down]>>(zoomed out)>>[scroll down]>>(3rd person view)
]]

local common = require('abot.SWGTK.common')

local modPrefix = common.modPrefix
local config = common.config or {}

--- local modEnabled
local minCameraDist, zoomStartRate, zoomEndRate, zoomInAmount
local zoomOutAmount, zoomInWheelSteps, zoomOutWheelSteps

---local mouse3rdSensivity -- nope for now
local logLevel
local logLevel1, logLevel2, logLevel3

local function updateFromConfig()
	if logLevel3 then
		mwse.log('%s: updateFromConfig()', modPrefix)
	end
	minCameraDist = config.minCameraDist
	zoomInWheelSteps = config.zoomInWheelSteps
	zoomStartRate = config.zoomStartRate
	zoomEndRate = config.zoomEndRate
	zoomInAmount = config.zoomInAmount
	zoomOutWheelSteps = config.zoomOutWheelSteps
	zoomOutAmount = config.zoomOutAmount
	---mouse3rdSensivity = config.mouse3rdSensivity
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
end
common.updateFromConfig = updateFromConfig
updateFromConfig()

--[[local function notify(str, ...)
	tes3.messageBox({message = tostring(str):format(...), showInDialog = false})
end]]

-- set in loaded()
local player, mobilePlayer

-- set in initialized()
local mge_camera ---, vanityCameraLock


--[[ -- nope
local tes3_keybind_togglePOV = tes3.keybind.togglePOV

local function keybindTested(e)
	if not (e.keybind == tes3_keybind_togglePOV) then
		return
	end
	if tes3.is3rdPerson() then
		if logLevel3 then
			mwse.log('%s: keybindTested(tes3.keybind.togglePOV)', modPrefix)
		end
	end
end
]]

local targetZoom

local simulateOn = false
local zoomingOut = false

local function stopZoom()
	if logLevel3 then
		mwse.log('%s: stopZoom()', modPrefix)
	end
	mge_camera.zoomEnable = true
	mge_camera.stopZoom()
end

local function resetZoom()
	if logLevel3 then
		mwse.log('%s: resetZoom()', modPrefix)
	end
	simulateOn = false
	zoomingOut = false
	targetZoom = nil
	stopZoom()
	mge_camera.zoom = 1
end

local function simulate()
	if not simulateOn then
		return
	end
	if not targetZoom then
		resetZoom()
		return
	end
	local stop = false
	if targetZoom > 1 then
		if mge_camera.zoom >= targetZoom then
			stop = true
		end
	else
		mge_camera.zoomOut({amount = zoomOutAmount})
		if mge_camera.zoom <= targetZoom then
			stop = true
			zoomingOut = false
		end
	end
	if stop then
		if logLevel3 then
			mwse.log('%s: simulate() targetZoom = %s',
				modPrefix, targetZoom)
		end
		stopZoom()
		mge_camera.zoom = targetZoom
		targetZoom = nil
		simulateOn = false
	end
end

local function zoomIn(amount)
	stopZoom()
	targetZoom = amount
	mge_camera.zoomContinuous({rate = zoomStartRate,
		targetRate = zoomEndRate})
	simulateOn = true
end

local function zoomOut()
	stopZoom()
	targetZoom = 1
	simulateOn = true
	zoomingOut = true
end

local wheelStepsCount = 0

local cameraTransform = tes3transform:new()
local armCameraTransform = tes3transform:new()


local camState = 0
local function cameraControl(e)
	if camState == 4 then -- try and fix QuickLoot keeping zooming...
		e.cameraTransform = e.previousCameraTransform:copy()
		e.armCameraTransform = e.previousArmCameraTransform:copy()
		camState = 0
		return
	end
	
	if tes3.is3rdPerson() then
		if camState == 1 then
			if logLevel1 then
				mwse.log('%s: cameraControl() 3rd person view, camState = %s, cameraTransform stored',
					modPrefix, camState)
			end
			cameraTransform = e.cameraTransform:copy()
			armCameraTransform = e.armCameraTransform:copy()
			camState = 2
			return
		end
		if camState == 3 then
			if logLevel1 then
				mwse.log('%s: cameraControl() 3rd person view, camState = %s, cameraTransform restored',
					modPrefix, camState)
			end
			e.cameraTransform = cameraTransform:copy()
			e.armCameraTransform = armCameraTransform:copy()
			camState = 0
		end
		return
	end
	
	-- 1st person view below
	if camState == 2 then
		if logLevel1 then
			mwse.log('%s: cameraControl() 1st person view, camState = %s, cameraTransform restored',
				modPrefix, camState)
		end
		e.cameraTransform = cameraTransform:copy()
		e.armCameraTransform = armCameraTransform:copy()
		camState = 3
	end
end


local idQuickLootMenu -- set in initialized()

local function zoomIsDefault()
	return math.abs(mge_camera.zoom - 1) < 0.01
end

local function mouseWheel(e)
--[[ -- nope
	local dy = math.floor( (mouse3rdSensivity * delta) + 0.5 )
	local cameraOffset = tes3.get3rdPersonCameraOffset()
mwse.log('>>> cameraOffset before: %s', cameraOffset)
	tes3.set3rdPersonCameraOffset({offset = cameraOffset + tes3vector3.new(0, dy, 0)})
	if tes3.menuMode() then
		return
	end
	cameraOffset = tes3.get3rdPersonCameraOffset()
mwse.log('>>> cameraOffset after: %s', cameraOffset)
]]
	if tes3.menuMode() then
		return
	end
	local quickLootMenu = tes3ui.findMenu(idQuickLootMenu)
	if quickLootMenu
	and quickLootMenu.visible then
		if (camState == 2)
		or (camState == 3) then
			e.cameraTransform = cameraTransform:copy()
			e.armCameraTransform = armCameraTransform:copy()
		end
		camState = 4
		return
	end
	
	-- Alt + Shift + Scroll Down = zoom reset
	local delta = e.delta
	local scrollUp = (delta > 0) -- mouse wheel forward / zoom in
	local scrollDown = (delta < 0) -- mouse wheel back / zoom out
	if e.isAltDown
	and scrollDown
	and ( not zoomIsDefault() ) then
		resetZoom()
		return
	end
	
	local cameraPos = tes3.getCameraPosition()
	local eyePos = tes3.getPlayerEyePosition()
	local cameraDist = cameraPos:distance(eyePos)
	if tes3.is3rdPerson() then
		if scrollUp
		and (
			(cameraDist < minCameraDist)
			or e.isAltDown
		)
		and (not mobilePlayer.animationController.vanityCamera) then
			if logLevel1 then
				tes3.messageBox('cameraDist %0d < minCameraDist %0d',
					cameraDist, minCameraDist)
				if logLevel2 then
					mwse.log('%s: mouseWheel() cameraDist %0d < minCameraDist %0d',
						modPrefix, cameraDist, minCameraDist)
				end
			end
			camState = 1
			tes3.force1stPerson()
			return
		end
	else -- in 1st person view
		if scrollDown then
			if not zoomingOut then
				zoomOut()
			end
			if wheelStepsCount < zoomOutWheelSteps then
				wheelStepsCount = wheelStepsCount + 1
			else
				wheelStepsCount = 0
				tes3.fadeOut({duration = 0.036})
				---restoreCamera = true
				tes3.force3rdPerson()
				tes3.fadeIn({duration = 0.18})
				return
			end
		elseif scrollUp then
			---mwse.log('>>> delta = %s, wheelStepsCount = %s', delta, wheelStepsCount)
			if wheelStepsCount < zoomInWheelSteps then
				wheelStepsCount = wheelStepsCount + 1
			else
				wheelStepsCount = 0
				zoomIn(zoomInAmount)
			end
		end
	end
	if logLevel2 then
		local cameraOffset = tes3.get3rdPersonCameraOffset()
		tes3.messageBox([[mouseWheel(e.delta = %s)
cameraDist = %s
cameraPos = %s
cameraOffset = %s]], delta, cameraDist, cameraPos, cameraOffset)
	end
end

local function mcmOnClose()
	--[[if not (config.modEnabled == modEnabled) then
		toggleEvents(config.modEnabled)
	end]]
	updateFromConfig()
	common.saveConfig()
end
common.mcmOnClose = mcmOnClose

local function cellChanged()
	--[[
	if e.cell.isOrBehavesAsExterior
	and e.previousCell
	and e.previousCell.isOrBehavesAsExterior then
		return
	end]]
	if zoomIsDefault() then
		return
	end
	resetZoom()
end

local loadedOnceDone = false
local function loadedOnce()
	if loadedOnceDone then
		return
	end
	loadedOnceDone = true
	---event.register('keybindTested', keybindTested)
	event.register('simulate', simulate)
	event.register('mouseWheel', mouseWheel)
	event.register('cameraControl', cameraControl)
	event.register('cellChanged', cellChanged)
end

local function loaded()
	---assert(mge_camera == mge.camera)
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	camState = 0
	---cameraTransform = tes3transform:new()
	---armCameraTransform = tes3transform:new()
	resetZoom()
	loadedOnce()
end

local function modConfigReady()
	common.modConfigReady()
end
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()
	idQuickLootMenu = tes3ui.registerID('QuickLoot:Menu')
	mge_camera = mge.camera
	---vanityCameraLock = tes3.hasCodePatchFeature(
		---tes3.codePatchFeature.vanityCameraLock)
	resetZoom()
	event.register('loaded', loaded)
end, {doOnce = true}
)
