local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local interfaces = require('openmw.interfaces')
local controls = interfaces.Controls
local uiModes = interfaces.UI
local ui = require('openmw.ui')
local camera = require('openmw.camera')

print("[pxm_airship][player] LOADED - MWSE style movement")

local flying = false

local horSpeed = 0
local vertSpeed = 0

local maxSpeed = 500
local horAcc = 300
local verticalAcc = 900
local maxVertSpeed = 18
local verticalScale = 0.22
local verticalDrag = 0.06
local fixmeBackDistance = 120
local fixmeUpDistance = 180
local suppressHorizontalFrames = 0
local verticalMode = false
local qWasPressed = false
local fixmeWasPressed = false
local visualUpdateTimer = 0
local visualUpdateInterval = 0.10
local shipYaw = 0
local turnSpeed = math.rad(60)
local rudderAngle = 0
local rudderMaxAngle = math.rad(22)
local rudderReturnSpeed = math.rad(90)
local visualYawOffset = math.rad(180)
local previousCameraMode = nil
local previousFocalOffset = nil
local updateFlightCamera = nil

local flightCameraDistance = 720
local flightCameraHeight = -20
local flightCameraPitch = math.rad(0)
local flightCameraPivotHeight = 190
local flightCameraBaseOrbitPitch = math.rad(10)

local visualBackOffset = 350
local visualZOffset = 450


-- Approximate vertical distance from the visual origin to the part of the ship
-- that should count as "touching ground" for manual descent and Q landing.
local landingContactZOffset = 420

-- Extra downward adjustment applied only when Q landing finalizes.
-- This lets the landed ship sit closer to the ground without weakening
-- the in-flight no-underground descent/collision checks.
local finalLandingGroundOffset = -35

local autoLanding = false
local autoLandingTargetZ = nil
local autoLandingYaw = nil
local autoLandingSpeed = 180

local pendingDismount = false
local pendingDismountTimer = 0
local dismountDelay = 0.20

-- Ship-local offset from visual origin to where the player should appear after landing.
-- Tune if needed.
local dismountForwardOffset = 0
local dismountSideOffset = 260
local dismountZOffset = 35

local visualCorrectionX = 0
local visualCorrectionY = 0
local visualCorrectionZ = 0
local movedSinceTakeoff = false

local visualAnchorX = nil
local visualAnchorY = nil
local visualAnchorZ = nil

local cameraRigOffsetX = 0
local cameraRigOffsetY = 0
local cameraRigOffsetZ = 0

local cameraAnchorForwardOffset = 170
local cameraAnchorZOffset = 20

local cameraYawOffset = 0

-- desiredCameraPitchOffset is raw mouse intent.
-- cameraPitchOffset is the smoothed value actually used by the camera.
local desiredCameraPitchOffset = 0
local cameraPitchOffset = 0

local smoothedCameraPos = nil
local smoothedCameraTargetPos = nil
local previousCameraShipYaw = nil
local previousCameraTargetPos = nil

local cameraSmoothStrength = 18
local cameraTargetSmoothStrength = 28
local cameraPitchSmoothStrength = 8

local mouseLookSensitivity = 0.0035
local maxCameraYawOffset = math.rad(70)

-- Vertical camera is not a free orbit.
-- 0 = normal behind-ship view.
-- 1 = high/close balloon-heavy view.
local cameraOverheadAmount = 0
local desiredCameraOverheadAmount = 0
local cameraOverheadSmoothStrength = 10

-- Mouse scale for the overhead rail. If direction is reversed, only flip the sign
-- in updateFlightCamera, not the camera geometry.
local cameraOverheadMouseSensitivity = 0.0024

-- Behind-ship camera rail.
-- Neutral: cabin straight ahead, lower balloon visible, no upward sky pitch.
local cameraRailNeutralDistance = 860
local cameraRailNeutralZ = 10
local cameraRailNeutralTargetZ = 65

-- Mouse-back view:
-- camera moves closer and a little higher, but the view pitch looks DOWN.
-- Do not aim at the top of the balloon/sky.
local cameraRailTopDistance = 760
local cameraRailTopZ = 430
local cameraRailTopTargetZ = 65

-- Explicit visual pitch. This is what controls up/down camera view.
-- In OpenMW camera.setPitch here, positive pitch looks down.
-- Neutral is almost horizontal; mouse-back progressively looks down.
local cameraRailNeutralPitch = math.rad(2)
local cameraRailTopPitch = math.rad(38)

local debugTimer = 0

local levitationApplied = false
local hideApplied = false

local function ensureLevitation()
    if levitationApplied then
        return
    end

    core.sendGlobalEvent("pxm_airship_set_levitation", {
        state = 1,
    })

    levitationApplied = true
    print("[pxm_airship] levitation add requested")
end

local function removeLevitation()
    if not levitationApplied then
        return
    end

    core.sendGlobalEvent("pxm_airship_set_levitation", {
        state = 2,
    })

    levitationApplied = false
    --print("[pxm_airship] levitation remove requested")
end

local function ensurePilotHidden()
    if hideApplied then
        return
    end

    core.sendGlobalEvent("pxm_airship_set_hide", {
        state = 1,
    })

    hideApplied = true
    --print("[pxm_airship] pilot hide add requested")
end

local function removePilotHidden()
    if not hideApplied then
        return
    end

    core.sendGlobalEvent("pxm_airship_set_hide", {
        state = 2,
    })

    hideApplied = false
    --print("[pxm_airship] pilot hide remove requested")
end

local function isShiftPressed()
    return input.isKeyPressed(input.KEY.LeftShift)
        or input.isKeyPressed(input.KEY.RightShift)
end

local function sendMove(dx, dy, dz)
    core.sendGlobalEvent("pxm_airship_move", {
        dx = dx,
        dy = dy,
        dz = dz,
    })
end

local function getBaseVisualPosition(dx, dy, dz, yaw)
    yaw = yaw or shipYaw

    local x = self.position.x + (dx or 0)
    local y = self.position.y + (dy or 0)
    local z = self.position.z + (dz or 0)

	x = x - math.sin(yaw) * visualBackOffset
	y = y - math.cos(yaw) * visualBackOffset
	z = z + visualZOffset

    return x, y, z
end

local function getVisualPosition(dx, dy, dz, yaw)
	if visualAnchorX and visualAnchorY and visualAnchorZ then
		return
			visualAnchorX + (dx or 0),
			visualAnchorY + (dy or 0),
			visualAnchorZ + (dz or 0)
	end

	local x, y, z = getBaseVisualPosition(dx, dy, dz, yaw)

	x = x + visualCorrectionX
	y = y + visualCorrectionY
	z = z + visualCorrectionZ

	return x, y, z
end

local function setVisualAnchor(x, y, z)
	visualAnchorX = tonumber(x)
	visualAnchorY = tonumber(y)
	visualAnchorZ = tonumber(z)
end

local function moveVisualAnchor(dx, dy, dz)
	if not visualAnchorX or not visualAnchorY or not visualAnchorZ then
		return
	end

	visualAnchorX = visualAnchorX + (dx or 0)
	visualAnchorY = visualAnchorY + (dy or 0)
	visualAnchorZ = visualAnchorZ + (dz or 0)
end

local function alignVisualCorrectionToAnchor(yaw)
	if not visualAnchorX or not visualAnchorY or not visualAnchorZ then
		return
	end

	local baseX, baseY, baseZ = getBaseVisualPosition(0, 0, 0, yaw)

	visualCorrectionX = visualAnchorX - baseX
	visualCorrectionY = visualAnchorY - baseY
	visualCorrectionZ = visualAnchorZ - baseZ
end

local function alignCameraRigToVisualAnchor()
	if not visualAnchorX or not visualAnchorY or not visualAnchorZ then
		return
	end

	cameraRigOffsetX = visualAnchorX - self.position.x
	cameraRigOffsetY = visualAnchorY - self.position.y
	cameraRigOffsetZ = visualAnchorZ - self.position.z
end

local function getCameraVisualPosition(yaw)
	if visualAnchorX and visualAnchorY and visualAnchorZ then
		return
			self.position.x + cameraRigOffsetX,
			self.position.y + cameraRigOffsetY,
			self.position.z + cameraRigOffsetZ
	end

	local x, y, z = getBaseVisualPosition(0, 0, 0, yaw)

	x = x + visualCorrectionX
	y = y + visualCorrectionY
	z = z + visualCorrectionZ

	return x, y, z
end

local function getCameraAnchorPosition(dx, dy, dz, yaw)
    local x, y, z = getCameraVisualPosition(yaw)

    -- Keep the camera pivot centered on the ship visual origin.
    -- Do not apply a yaw-based forward offset here, or the camera target
    -- orbits around the hidden player while the ship turns.
    z = z + cameraAnchorZOffset

    return x, y, z
end

local function sendVisualStart()
	local yaw = shipYaw
	local x, y, z = getVisualPosition(0, 0, 0, yaw)

	core.sendGlobalEvent("pxm_airship_visual_start", {
		x = x,
		y = y,
		z = z,
		yaw = yaw + visualYawOffset,
	})
end

local function getRotorSpin()
	local horizontalFactor = math.min(1, math.abs(horSpeed) / maxSpeed)

	-- Only climbing increases rotor speed.
	-- Descending should keep idle/horizontal rotor speed, not add thrust.
	local climbFactor = math.min(1, math.max(0, vertSpeed) / maxVertSpeed)

	-- MWScript Rotate value per frame.
	-- Rotor idles slowly while airborne, speeds up with forward movement and climb.
	local idleSpin = 5
	local spin = idleSpin + horizontalFactor * 100 + climbFactor * 30

	return spin
end

local function sendVisualUpdate(dx, dy, dz, yaw)
    yaw = yaw or shipYaw

    local x, y, z = getVisualPosition(dx, dy, dz, yaw)

    core.sendGlobalEvent("pxm_airship_visual_update", {
        x = x,
        y = y,
        z = z,
        yaw = yaw + visualYawOffset,
		rotorSpin = getRotorSpin(),
		rudderAngle = rudderAngle,
    })
end

local function sendVisualStop()
    core.sendGlobalEvent("pxm_airship_visual_stop", {})
end

local function sendVisualLand(data)
	data = data or {}

	if data.yaw ~= nil then
		local oldYaw = tonumber(data.yaw) or 0
		data.yaw = oldYaw + visualYawOffset

		print(string.format(
			"[pxm_airship][player] landing yaw converted shipYaw=%.3f visualYaw=%.3f",
			oldYaw,
			data.yaw
		))
	end

	core.sendGlobalEvent("pxm_airship_visual_land", data)
end

local function collisionAhead(dx, dy, yaw)

	yaw = yaw or shipYaw

	local visualX, visualY, visualZ = getVisualPosition(0, 0, 0, yaw)
	local contactZ = visualZ - landingContactZOffset

	local moveVec = util.vector3(dx, dy, 0)

	if moveVec:length() < 1 then
		return false
	end

	local dir = moveVec:normalize()
	local rayLen = math.max(220, moveVec:length() + 160)

	local collisionType =
		nearby.COLLISION_TYPE.World
		+ nearby.COLLISION_TYPE.Door
		+ nearby.COLLISION_TYPE.HeightMap

	local footprint = {
		{ forward = 360, side = 0, z = 120 },
		{ forward = 160, side = 0, z = 120 },
		{ forward = 0, side = 0, z = 120 },
		{ forward = 0, side = 180, z = 120 },
		{ forward = 0, side = -180, z = 120 },
		{ forward = -240, side = 0, z = 120 },
	}

	for _, sample in ipairs(footprint) do
		local sx =
			visualX
			+ math.sin(yaw) * sample.forward
			+ math.cos(yaw) * sample.side

		local sy =
			visualY
			+ math.cos(yaw) * sample.forward
			- math.sin(yaw) * sample.side

		local start = util.vector3(sx, sy, contactZ + sample.z)

		local res = nearby.castRay(
			start,
			start + dir * rayLen,
			{
				collisionType = collisionType,
			}
		)

		if res and res.hit then
			local obj = res.hitObject
			local id = obj and obj.recordId or nil

			if id == "pxm_airship_flying_visual"
				or id == "pxm_airship_flying_door"
				or id == "pxm_airship_rotor_visual"
				or id == "pxm_airship_rudder_visual"
				or id == "pp_airship_stage_03"
				or id == "PP_Airship_Stage_03"
				or id == "pp_airship_door_mwse"
				or id == "PP_Airship_Door_MWSE" then

				-- Ignore own airship refs, but keep checking other footprint rays.
			else
				--[[print(
					"[pxm_airship] blocked by visual collision: "
					.. tostring(id or "world/static")
				)]]
				return true
			end
		end
	end

	return false
end

local function setVerticalMode(enabled)

    if verticalMode == enabled then
        return
    end

    verticalMode = enabled

    if enabled then
        print("[pxm_airship] vertical mode ON")
    else
        print("[pxm_airship] vertical mode OFF")
    end
end

local enterFlightCamera
local exitFlightCamera

local function movePilotToLandingDismount(landingData)
	if not landingData or not landingData.x or not landingData.y or not landingData.z then
		return false
	end

	local yaw = tonumber(landingData.yaw) or shipYaw

	local visualX = tonumber(landingData.x)
	local visualY = tonumber(landingData.y)
	local visualZ = tonumber(landingData.z)

	-- Place player beside the landed ship, near ground/contact height.
	local targetX =
		visualX
		+ math.sin(yaw) * dismountForwardOffset
		+ math.cos(yaw) * dismountSideOffset

	local targetY =
		visualY
		+ math.cos(yaw) * dismountForwardOffset
		- math.sin(yaw) * dismountSideOffset

	local targetZ =
		visualZ
		- landingContactZOffset
		+ dismountZOffset

	sendMove(
		targetX - self.position.x,
		targetY - self.position.y,
		targetZ - self.position.z
	)

	pendingDismount = true
	pendingDismountTimer = dismountDelay

	--print("[pxm_airship][player] pilot dismount move requested")

	return true
end

local function exitFlight(landingData)
    flying = false

	autoLanding = false
	autoLandingTargetZ = nil
	autoLandingYaw = nil

	core.sendGlobalEvent("pxm_airship_set_flying_state", {
		state = 0,
	})

    horSpeed = 0
    vertSpeed = 0
    suppressHorizontalFrames = 0
    verticalMode = false

	controls.overrideMovementControls(false)
	exitFlightCamera()

	visualUpdateTimer = 0
	sendVisualLand(landingData)

	if not movePilotToLandingDismount(landingData) then
		removePilotHidden()
		removeLevitation()
	end

	--print("[pxm_airship][player] flight exited")
end

local function castGroundAt(x, y, z)

	local collisionType =
		nearby.COLLISION_TYPE.World
		+ nearby.COLLISION_TYPE.HeightMap

	local start = util.vector3(x, y, z + 600)
	local finish = util.vector3(x, y, z - 2500)

	local res = nearby.castRay(
		start,
		finish,
		{
			collisionType = collisionType,
		}
	)

	if not res or not res.hit or not res.hitPos then
		return nil
	end

	return res
end

local function castHeightMapAt(x, y, z)

	local collisionType = nearby.COLLISION_TYPE.HeightMap

	local start = util.vector3(x, y, z + 600)
	local finish = util.vector3(x, y, z - 2500)

	local res = nearby.castRay(
		start,
		finish,
		{
			collisionType = collisionType,
		}
	)

	if not res or not res.hit or not res.hitPos then
		return nil
	end

	return res
end

local function getCurrentCellWaterLevel()
	local cell = self.cell

	if not cell then
		return nil
	end

	if type(cell.waterLevel) == "number" then
		return cell.waterLevel
	end

	return nil
end

local function isLavaRecordId(id)
	if not id then
		return false
	end

	id = string.lower(tostring(id))

	return id:find("lava", 1, true) ~= nil
end

local function landingBlockedByWaterOrLava(yaw, groundZ, visualZ)

	-- Water is cell-level data, not a normal raycast object.
	local waterLevel = getCurrentCellWaterLevel()

	if waterLevel and groundZ <= waterLevel + 12 then
		return true, "water"
	end

	-- Lava is usually a placed object/static/activator, e.g. ids containing "lava".
	-- Probe close to the landing surface so we do not raycast into the airship itself.
	local collisionType =
		nearby.COLLISION_TYPE.World
		+ nearby.COLLISION_TYPE.Door

	local samples = {
		{ forward = 0, side = 0 },
		{ forward = 240, side = 0 },
		{ forward = -240, side = 0 },
		{ forward = 0, side = 180 },
		{ forward = 0, side = -180 },
		{ forward = 360, side = 0 },
		{ forward = -360, side = 0 },
	}

	local visualX, visualY = getVisualPosition(0, 0, 0, yaw)

	for _, sample in ipairs(samples) do
		local sx =
			visualX
			+ math.sin(yaw) * sample.forward
			+ math.cos(yaw) * sample.side

		local sy =
			visualY
			+ math.cos(yaw) * sample.forward
			- math.sin(yaw) * sample.side

		local start = util.vector3(sx, sy, groundZ + 350)
		local finish = util.vector3(sx, sy, groundZ - 96)

		local res = nearby.castRay(
			start,
			finish,
			{
				collisionType = collisionType,
			}
		)

		if res and res.hit then
			local obj = res.hitObject
			local id = obj and obj.recordId or nil

			if isLavaRecordId(id) then
				return true, "lava"
			end
		end
	end

	return false, nil
end

local function landingBlockedByLiquidWithoutGround(yaw)
	yaw = yaw or shipYaw

	local visualX, visualY, visualZ = getVisualPosition(0, 0, 0, yaw)

	-- This function is only called after heightmap landing ground was not found.
	-- In exterior water cells, that usually means the ship footprint is over water,
	-- so do not require the ship to be close to the water level.
	local waterLevel = getCurrentCellWaterLevel()

	if waterLevel then
		return true, "water"
	end

	local collisionType =
		nearby.COLLISION_TYPE.World
		+ nearby.COLLISION_TYPE.Door
		+ nearby.COLLISION_TYPE.HeightMap

	local samples = {
		{ forward = 0, side = 0 },
		{ forward = 240, side = 0 },
		{ forward = -240, side = 0 },
		{ forward = 0, side = 180 },
		{ forward = 0, side = -180 },
		{ forward = 360, side = 0 },
		{ forward = -360, side = 0 },
	}

	for _, sample in ipairs(samples) do
		local sx =
			visualX
			+ math.sin(yaw) * sample.forward
			+ math.cos(yaw) * sample.side

		local sy =
			visualY
			+ math.cos(yaw) * sample.forward
			- math.sin(yaw) * sample.side

		local start = util.vector3(sx, sy, visualZ + 600)
		local finish = util.vector3(sx, sy, visualZ - 5000)

		local res = nearby.castRay(
			start,
			finish,
			{
				collisionType = collisionType,
			}
		)

		if res and res.hit then
			local obj = res.hitObject
			local id = obj and obj.recordId or nil

			if isLavaRecordId(id) then
				return true, "lava"
			end
		end
	end

	return false, nil
end

local function getLandingGround(yaw)

	yaw = yaw or shipYaw

	local visualX, visualY, visualZ = getVisualPosition(0, 0, 0, yaw)

	-- Probe around the visible ship footprint, not only below the hidden player.
	-- This avoids "too high to land" when the ship is visibly touching uneven terrain.
	local samples = {
		{ forward = 0, side = 0 },
		{ forward = 240, side = 0 },
		{ forward = -240, side = 0 },
		{ forward = 0, side = 180 },
		{ forward = 0, side = -180 },
		{ forward = 360, side = 0 },
		{ forward = -360, side = 0 },
	}

	local best = nil

	for _, sample in ipairs(samples) do
		local sx =
			visualX
			+ math.sin(yaw) * sample.forward
			+ math.cos(yaw) * sample.side

		local sy =
			visualY
			+ math.cos(yaw) * sample.forward
			- math.sin(yaw) * sample.side

		local res = castHeightMapAt(sx, sy, visualZ)

		if res and res.hitPos then
			if not best or res.hitPos.z > best.hitPos.z then
				best = res
			end
		end
	end

	return best
end

local function isOwnAirshipRef(id)
	return id == "pxm_airship_flying_visual"
		or id == "pxm_airship_flying_door"
		or id == "pxm_airship_rotor_visual"
		or id == "pxm_airship_rudder_visual"
		or id == "pp_airship_stage_03"
		or id == "PP_Airship_Stage_03"
		or id == "pp_airship_door_mwse"
		or id == "PP_Airship_Door_MWSE"
end

local function descentBlockedByWorld(dx, dy, dz, yaw)

	if not dz or dz >= 0 then
		return false
	end

	yaw = yaw or shipYaw

	local visualX, visualY, visualZ = getVisualPosition(0, 0, 0, yaw)

	local proposedVisualX = visualX + (dx or 0)
	local proposedVisualY = visualY + (dy or 0)
	local proposedVisualZ = visualZ + dz

	local currentContactZ = visualZ - landingContactZOffset
	local proposedContactZ = proposedVisualZ - landingContactZOffset

	local collisionType =
		nearby.COLLISION_TYPE.World
		+ nearby.COLLISION_TYPE.Door

	local samples = {
		{ forward = 0, side = 0 },
		{ forward = 240, side = 0 },
		{ forward = -240, side = 0 },
		{ forward = 0, side = 180 },
		{ forward = 0, side = -180 },
		{ forward = 360, side = 0 },
		{ forward = -360, side = 0 },
	}

	for _, sample in ipairs(samples) do
		local sx =
			proposedVisualX
			+ math.sin(yaw) * sample.forward
			+ math.cos(yaw) * sample.side

		local sy =
			proposedVisualY
			+ math.cos(yaw) * sample.forward
			- math.sin(yaw) * sample.side

		local start = util.vector3(sx, sy, currentContactZ + 32)
		local finish = util.vector3(sx, sy, proposedContactZ - 32)

		local res = nearby.castRay(
			start,
			finish,
			{
				collisionType = collisionType,
			}
		)

		if res and res.hit then
			local obj = res.hitObject
			local id = obj and obj.recordId or nil

			if not isOwnAirshipRef(id) then
				print(
					"[pxm_airship][player] descent blocked by world: "
					.. tostring(id or "world/static")
				)

				return true
			end
		end
	end

	return false
end

local function wouldPutVisualBelowGround(dx, dy, dz, yaw)

	yaw = yaw or shipYaw

	local visualX, visualY, visualZ = getVisualPosition(0, 0, 0, yaw)

	local proposedVisualX = visualX + (dx or 0)
	local proposedVisualY = visualY + (dy or 0)
	local proposedVisualZ = visualZ + (dz or 0)

	local proposedContactZ = proposedVisualZ - landingContactZOffset

	-- Use the same footprint shape as Q landing, but heightmap-only.
	-- This prevents Q landing from later finding a higher terrain sample
	-- and popping the ship upward after manual descent.
	local samples = {
		{ forward = 0, side = 0 },
		{ forward = 240, side = 0 },
		{ forward = -240, side = 0 },
		{ forward = 0, side = 180 },
		{ forward = 0, side = -180 },
		{ forward = 360, side = 0 },
		{ forward = -360, side = 0 },
	}

	local highestGroundZ = nil

	for _, sample in ipairs(samples) do
		local sx =
			proposedVisualX
			+ math.sin(yaw) * sample.forward
			+ math.cos(yaw) * sample.side

		local sy =
			proposedVisualY
			+ math.cos(yaw) * sample.forward
			- math.sin(yaw) * sample.side

		local res = castHeightMapAt(sx, sy, proposedVisualZ)

		if res and res.hitPos then
			if not highestGroundZ or res.hitPos.z > highestGroundZ then
				highestGroundZ = res.hitPos.z
			end
		end
	end

	if not highestGroundZ then
		return false
	end

	local minGroundClearance = 2

	return proposedContactZ < highestGroundZ + minGroundClearance
end

local function updateAutoLanding(dt)
	if not autoLanding then
		return false
	end

	local yaw = autoLandingYaw or shipYaw
	local targetZ = autoLandingTargetZ

	if not targetZ then
		autoLanding = false
		return false
	end

	local _, _, visualZ = getVisualPosition(0, 0, 0, yaw)
	local remainingDz = targetZ - visualZ
	local maxStep = autoLandingSpeed * dt

	if math.abs(remainingDz) <= math.max(1, maxStep) then
		if math.abs(remainingDz) > 0.01 then
			sendMove(0, 0, remainingDz)
			moveVisualAnchor(0, 0, remainingDz)
		end

		local x, y, z = getVisualPosition(0, 0, 0, yaw)

		exitFlight({
			x = x,
			y = y,
			z = z,
			yaw = yaw,
		})

		return true
	end

	local dz = -maxStep

	if remainingDz > 0 then
		dz = maxStep
	end

	if dz < 0 and descentBlockedByWorld(0, 0, dz, yaw) then
		ui.showMessage("You cannot land here.")
		--print("[pxm_airship][player] auto landing blocked by world collision")

		autoLanding = false
		autoLandingTargetZ = nil
		autoLandingYaw = nil

		sendVisualUpdate(0, 0, 0, yaw)
		updateFlightCamera(0, 0, 0, yaw, dt)

		return true
	end

	sendMove(0, 0, dz)
	moveVisualAnchor(0, 0, dz)

	sendVisualUpdate(0, 0, 0, yaw)
	updateFlightCamera(0, 0, 0, yaw, dt)

	return true
end

local function startAutoLanding(yaw, targetZ)
	autoLanding = true
	autoLandingYaw = yaw
	autoLandingTargetZ = targetZ

	-- Freeze pilot input momentum during scripted landing.
	horSpeed = 0
	vertSpeed = 0
	suppressHorizontalFrames = 0
	verticalMode = false

	-- Prevent the static camera from visually hanging at the pre-landing height.
	smoothedCameraPos = nil
	smoothedCameraTargetPos = nil

	--print("[pxm_airship][player] auto landing started targetZ=" .. tostring(targetZ))
end

local function tryLand()

	local yaw = shipYaw

	if not movedSinceTakeoff then
		local x, y, z = getVisualPosition(0, 0, 0, yaw)

		exitFlight({
			x = x,
			y = y,
			z = z,
			yaw = yaw,
		})

		return
	end

	local ground = getLandingGround(yaw)

	if not ground then
		local blockedByLiquid, liquidType = landingBlockedByLiquidWithoutGround(yaw)

		if blockedByLiquid then
			if liquidType == "lava" then
				ui.showMessage("You cannot land on lava.")
				--print("[pxm_airship][player] landing failed: lava below ship footprint")
			else
				ui.showMessage("You cannot land on water.")
				--print("[pxm_airship][player] landing failed: water below ship footprint")
			end

			return
		end

		ui.showMessage("You are too high to land.")
		--print("[pxm_airship][player] landing failed: no ground below ship footprint")
		return
	end

	local anchorGroundZ = ground.hitPos.z
	local visualX, visualY, visualZ = getVisualPosition(0, 0, 0, yaw)
	local contactZ = visualZ - landingContactZOffset
	local zDist = contactZ - anchorGroundZ
	local normal = ground.hitNormal

	local blockedByLiquid, liquidType =
		landingBlockedByWaterOrLava(yaw, anchorGroundZ, visualZ)

	if blockedByLiquid then
		if liquidType == "lava" then
			ui.showMessage("You cannot land on lava.")
			--print("[pxm_airship][player] landing failed: lava below ship footprint")
		else
			ui.showMessage("You cannot land on water.")
			--print("[pxm_airship][player] landing failed: water below ship footprint")
		end

		return
	end

	local isHighSlope =
		normal
		and (math.abs(normal.x) > 0.3 or math.abs(normal.y) > 0.3)

	if isHighSlope then
		ui.showMessage("The slope is too steep to land.")
		--print("[pxm_airship][player] landing failed: steep slope")
		return
	end

	local targetVisualZ = anchorGroundZ + landingContactZOffset + finalLandingGroundOffset

	if math.abs(targetVisualZ - visualZ) <= 1 then
		local x, y, z = getVisualPosition(0, 0, 0, yaw)

		exitFlight({
			x = x,
			y = y,
			z = z,
			yaw = yaw,
		})

		return
	end

	startAutoLanding(yaw, targetVisualZ)
end

enterFlightCamera = function()
    previousCameraMode = camera.getMode()

    camera.setMode(camera.MODE.Static, true)
    camera.showCrosshair(false)
end

exitFlightCamera = function()
    camera.showCrosshair(true)

    if previousCameraMode then
        camera.setMode(previousCameraMode, true)
        previousCameraMode = nil
		desiredCameraPitchOffset = 0
		cameraPitchOffset = 0
		desiredCameraOverheadAmount = 0
		cameraOverheadAmount = 0
		smoothedCameraPos = nil
		smoothedCameraTargetPos = nil
		previousCameraShipYaw = nil
		previousCameraTargetPos = nil
    end
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function isMenuOpen()
    return uiModes.getMode() ~= nil
end

local function rotateVectorZ(v, angle)
	local s = math.sin(angle)
	local c = math.cos(angle)

	return util.vector3(
		v.x * c - v.y * s,
		v.x * s + v.y * c,
		v.z
	)
end

local function isOwnAirshipCameraHit(id)
	return id == "pxm_airship_flying_visual"
		or id == "pxm_airship_flying_door"
		or id == "pxm_airship_rotor_visual"
		or id == "pxm_airship_rudder_visual"
		or id == "pp_airship_stage_03"
		or id == "PP_Airship_Stage_03"
		or id == "pp_airship_door_mwse"
		or id == "PP_Airship_Door_MWSE"
end

local function clampCameraToTerrain(targetPos, desiredCamPos)

	local collisionType =
		nearby.COLLISION_TYPE.World
		+ nearby.COLLISION_TYPE.Door
		+ nearby.COLLISION_TYPE.HeightMap

	local dir = desiredCamPos - targetPos

	if dir:length() < 1 then
		return desiredCamPos
	end

	dir = dir:normalize()

	local safetyOffset = 72

	-- Start slightly away from the ship so the camera ray does not immediately
	-- hit the airship itself and then ignore real obstacles behind it.
	local startDistance = 180
	local start = targetPos + dir * startDistance

	if (desiredCamPos - start):length() < 1 then
		return desiredCamPos
	end

	local right = util.vector3(-dir.y, dir.x, 0)

	if right:length() < 0.1 then
		right = util.vector3(1, 0, 0)
	else
		right = right:normalize()
	end

	local up = util.vector3(0, 0, 1)

	-- Multiple rays make the camera behave more like a small volume instead
	-- of a single point, which helps with walls, arches, corners, and buildings.
	local offsets = {
		util.vector3(0, 0, 0),
		right * 48,
		right * -48,
		up * 48,
		up * -32,
		right * 32 + up * 32,
		right * -32 + up * 32,
	}

	local closestHitPos = nil
	local closestDist = nil

	for _, offset in ipairs(offsets) do
		local rayStart = start + offset
		local rayFinish = desiredCamPos + offset

		local res = nearby.castRay(
			rayStart,
			rayFinish,
			{
				collisionType = collisionType,
			}
		)

		if res and res.hit and res.hitPos then
			local obj = res.hitObject
			local id = obj and obj.recordId or nil

			if not isOwnAirshipCameraHit(id) then
				local hitDist = (res.hitPos - targetPos):length()

				if not closestDist or hitDist < closestDist then
					closestDist = hitDist
					closestHitPos = res.hitPos
				end
			end
		end
	end

	if not closestHitPos then
		return desiredCamPos
	end

	return closestHitPos - dir * safetyOffset
end

updateFlightCamera = function(dx, dy, dz, yaw, dt)
    yaw = yaw or shipYaw

	local mouseY = 0

	if not isMenuOpen() then
		-- Lock horizontal camera orbit behind the ship.
		-- A/D rotates the whole ship-camera line instead of showing the ship from the side.
		cameraYawOffset = 0

		mouseY = input.getMouseMoveY()

		-- Pull mouse back should increase overhead amount.
		-- If your mouse direction is reversed, change this "-" to "+" only.
		desiredCameraOverheadAmount = clamp(
			desiredCameraOverheadAmount + mouseY * cameraOverheadMouseSensitivity,
			0,
			1
		)
	else
		cameraYawOffset = 0
	end

	local overheadAlpha = 1

	if dt then
		overheadAlpha = 1 - math.exp(-cameraOverheadSmoothStrength * dt)
		overheadAlpha = clamp(overheadAlpha, 0.05, 0.35)
	end

	cameraOverheadAmount =
		cameraOverheadAmount
		+ (desiredCameraOverheadAmount - cameraOverheadAmount) * overheadAlpha

	local viewYaw = yaw

	local x, y, z = getCameraAnchorPosition(0, 0, 0, yaw)

	-- Smoothstep: soft movement at both ends of the rail.
	local overheadAmount =
		cameraOverheadAmount
		* cameraOverheadAmount
		* (3 - 2 * cameraOverheadAmount)

	local cameraDistance =
		cameraRailNeutralDistance
		+ (cameraRailTopDistance - cameraRailNeutralDistance) * overheadAmount

	local cameraZ =
		cameraRailNeutralZ
		+ (cameraRailTopZ - cameraRailNeutralZ) * overheadAmount

	local targetZ =
		cameraRailNeutralTargetZ
		+ (cameraRailTopTargetZ - cameraRailNeutralTargetZ) * overheadAmount

	local targetPos = util.vector3(
		x,
		y,
		z + targetZ
	)

	local yawDelta = 0

	if previousCameraShipYaw then
		yawDelta = yaw - previousCameraShipYaw
	end

	if smoothedCameraPos
		and previousCameraShipYaw
		and previousCameraTargetPos then

		if math.abs(yawDelta) > 0.0001 then
			local relativeCameraPos = smoothedCameraPos - previousCameraTargetPos
			smoothedCameraPos = targetPos + rotateVectorZ(relativeCameraPos, yawDelta)
		end
	end

	previousCameraShipYaw = yaw
	previousCameraTargetPos = targetPos

	local camX = targetPos.x - math.sin(viewYaw) * cameraDistance
	local camY = targetPos.y - math.cos(viewYaw) * cameraDistance
	local camZ = z + cameraZ

	local desiredCamPos = util.vector3(camX, camY, camZ)

	local camPos = clampCameraToTerrain(targetPos, desiredCamPos)

	if smoothedCameraPos == nil then
		smoothedCameraPos = camPos
	else
		local cameraAlpha = 0.35

		if dt then
			cameraAlpha = 1 - math.exp(-cameraSmoothStrength * dt)
			cameraAlpha = clamp(cameraAlpha, 0.06, 0.42)
		end

		smoothedCameraPos = smoothedCameraPos + (camPos - smoothedCameraPos) * cameraAlpha
	end

	-- Do not derive pitch from targetPos.
	-- Mouse-back should bend the view DOWN, not aim at whatever targetPos happens to be.
	local viewPitch =
		cameraRailNeutralPitch
		+ (cameraRailTopPitch - cameraRailNeutralPitch) * overheadAmount
		+ flightCameraPitch

	camera.setStaticPosition(smoothedCameraPos)
	camera.setYaw(viewYaw)
	camera.setPitch(viewPitch)
end

return {
	eventHandlers = {
		pxm_toggle_flight = function(data)
			data = data or {}

			flying = not flying

			core.sendGlobalEvent("pxm_airship_set_flying_state", {
				state = flying and 1 or 0,
			})

			horSpeed = 0
			vertSpeed = 0
			suppressHorizontalFrames = 0
			verticalMode = false

			controls.overrideMovementControls(flying)

			if flying then
				visualCorrectionX = 0
				visualCorrectionY = 0
				visualCorrectionZ = 0
				movedSinceTakeoff = false

				visualAnchorX = nil
				visualAnchorY = nil
				visualAnchorZ = nil

				if tonumber(data.hasVisual) == 1
					and tonumber(data.visualX)
					and tonumber(data.visualY)
					and tonumber(data.visualZ) then

					shipYaw = tonumber(data.shipYaw) or self.rotation:getYaw()

					setVisualAnchor(
						tonumber(data.visualX),
						tonumber(data.visualY),
						tonumber(data.visualZ)
					)

					alignCameraRigToVisualAnchor()

					--print("[pxm_airship][player] using stored visual as takeoff source of truth")
				else
					shipYaw = self.rotation:getYaw()

					local x, y, z = getBaseVisualPosition(0, 0, 0, shipYaw)
					setVisualAnchor(x, y, z)
					alignVisualCorrectionToAnchor(shipYaw)
					alignCameraRigToVisualAnchor()
				end

				cameraYawOffset = 0
				desiredCameraPitchOffset = 0
				cameraPitchOffset = 0
				desiredCameraOverheadAmount = 0
				cameraOverheadAmount = 0
				smoothedCameraPos = nil
				smoothedCameraTargetPos = nil
				previousCameraShipYaw = nil
				previousCameraTargetPos = nil
				enterFlightCamera()

				visualUpdateTimer = visualUpdateInterval
				sendVisualStart()
				updateFlightCamera(0, 0, 0, shipYaw)
			else
				visualUpdateTimer = 0
				sendVisualStop()
				exitFlightCamera()
			end

			--print("[pxm_airship][player] flying toggled: " .. tostring(flying))
		end,
	},
    engineHandlers = {
        onUpdate = function(dt)			
			core.sendGlobalEvent("pxm_check_flight_toggle", {})
			
			if not flying then
				verticalMode = false
				controls.overrideMovementControls(false)

				if pendingDismount then
					pendingDismountTimer = pendingDismountTimer - dt

					if pendingDismountTimer <= 0 then
						pendingDismount = false
						pendingDismountTimer = 0

						removePilotHidden()
						removeLevitation()
					end

					return
				end

				removePilotHidden()
				removeLevitation()
				return
			end

			ensureLevitation()
			ensurePilotHidden()
			
			if isMenuOpen() then
				updateFlightCamera(0, 0, 0, shipYaw, dt)
				return
			end

			if updateAutoLanding(dt) then
				return
			end

			local qPressed = input.isKeyPressed(input.KEY.Q)

			if qPressed and not qWasPressed then
				qWasPressed = true
				tryLand()
				return
			end

			if not qPressed then
				qWasPressed = false
			end

			local shift = isShiftPressed()

			local fixmePressed = shift and input.isKeyPressed(input.KEY.X)

			if fixmePressed and not fixmeWasPressed then
				fixmeWasPressed = true

				horSpeed = 0
				vertSpeed = 0
				suppressHorizontalFrames = 2
				verticalMode = false

				local yaw = shipYaw
				local dx = -math.sin(yaw) * fixmeBackDistance
				local dy = -math.cos(yaw) * fixmeBackDistance
				local dz = fixmeUpDistance

				sendMove(dx, dy, dz)
				moveVisualAnchor(dx, dy, dz)
				movedSinceTakeoff = true
				sendVisualUpdate(0, 0, 0, yaw)
				updateFlightCamera(0, 0, 0, yaw, dt)

				--print("[pxm_airship][player] FixMe unstuck nudge requested")

				return
			end

			if not fixmePressed then
				fixmeWasPressed = false
			end

			local forward = input.isKeyPressed(input.KEY.W)
			local back = input.isKeyPressed(input.KEY.S)

			local turnLeft = input.isKeyPressed(input.KEY.A)
			local turnRight = input.isKeyPressed(input.KEY.D)

			if turnLeft then
				shipYaw = shipYaw - turnSpeed * dt
			end

			if turnRight then
				shipYaw = shipYaw + turnSpeed * dt
			end

			if turnLeft and not turnRight then
				rudderAngle = -rudderMaxAngle
			elseif turnRight and not turnLeft then
				rudderAngle = rudderMaxAngle
			else
				if rudderAngle > 0 then
					rudderAngle = math.max(0, rudderAngle - rudderReturnSpeed * dt)
				elseif rudderAngle < 0 then
					rudderAngle = math.min(0, rudderAngle + rudderReturnSpeed * dt)
				end
			end

			local verticalInput = shift and (forward or back)

			setVerticalMode(verticalInput)

            -- MWSE behavior:
            -- Forward = accelerate horizontally
            -- Shift + Forward = climb
			if forward then

				if shift then
					vertSpeed = math.min(maxVertSpeed, vertSpeed + 1.2)

				else

					vertSpeed = 0

					horSpeed = math.min(maxSpeed, horSpeed + horAcc * dt)
				end
			end

            -- MWSE behavior:
            -- Back = brake
            -- Shift + Back = descend
			if back then

				if shift then
					vertSpeed = math.max(-maxVertSpeed, vertSpeed - 1.2)

				else

					vertSpeed = 0

					horSpeed = math.max(0, horSpeed - horAcc * 2 * dt)
				end
			end

            -- MWSE Drag(0.025)-style vertical damping
			if shift and (forward or back) then
				-- Do not kill fresh vertical thrust while actively climbing/descending.
				vertSpeed = vertSpeed - vertSpeed * verticalDrag
			else
				if math.abs(vertSpeed) < 2 then
					vertSpeed = 0
				else
					vertSpeed = vertSpeed - vertSpeed * verticalDrag
				end
			end

            local yaw = shipYaw
            local sin = math.sin(yaw)
            local cos = math.cos(yaw)

			local dx = 0
			local dy = 0

			if suppressHorizontalFrames > 0 then

				suppressHorizontalFrames = suppressHorizontalFrames - 1

			else

				dx = horSpeed * sin * dt
				dy = horSpeed * cos * dt
			end
			local dz = 0

			if shift and forward then
				dz = vertSpeed * verticalScale

			elseif shift and back then		
				dz = vertSpeed * verticalScale

			elseif shift then

				-- Shift alone should not stop propulsion.
				dz = 0

			else

				dz = 0
			end

			if dx ~= 0 or dy ~= 0 or dz ~= 0 then

				if dz < 0 and descentBlockedByWorld(0, 0, dz, yaw) then
					--print("[pxm_airship] blocked: visual ship would descend into world collision")
					dz = 0
				end

				if dz < 0 and wouldPutVisualBelowGround(0, 0, dz, yaw) then
					--print("[pxm_airship] blocked: visual ship would descend below ground")
					dz = 0
				end

				if dz < 0 then
					local waterLevel = getCurrentCellWaterLevel()

					if waterLevel then
						local _, _, proposedVisualZ = getVisualPosition(0, 0, dz, yaw)
						local proposedContactZ = proposedVisualZ - landingContactZOffset

						if proposedContactZ <= waterLevel + 12 then
							--print("[pxm_airship] blocked: visual ship would descend into water")
							dz = 0
						end
					end
				end

				if (math.abs(dx) > 0.5 or math.abs(dy) > 0.5)
					and collisionAhead(dx, dy, yaw) then

					-- block horizontal movement only
					dx = 0
					dy = 0
				end

				if dx ~= 0 or dy ~= 0 or dz ~= 0 then
					sendMove(dx, dy, dz)
					moveVisualAnchor(dx, dy, dz)

					if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 or math.abs(dz) > 0.01 then
						movedSinceTakeoff = true
					end
				end
			end

			-- Do not predict the visual/camera from this frame's requested MWScript move.
			-- The player position is moved by the MWScript bridge asynchronously, so using
			-- dx/dy/dz here can cause one-frame rubber-banding/jitter.
			sendVisualUpdate(0, 0, 0, yaw)
			updateFlightCamera(0, 0, 0, yaw, dt)

            debugTimer = debugTimer + dt
            if debugTimer >= 1 then
                debugTimer = 0
                --[[print(string.format(
                    "[pxm_airship][player] flying=%s horSpeed=%.2f vertSpeed=%.2f dx=%.2f dy=%.2f dz=%.2f shift=%s forward=%s back=%s left=%s right=%s yaw=%.2f",
                    tostring(flying),
                    horSpeed,
                    vertSpeed,
                    dx,
                    dy,
                    dz,
                    tostring(shift),
                    tostring(forward),
                    tostring(back),
					tostring(turnLeft),
					tostring(turnRight),
					shipYaw					
                ))]]
            end
        end,
    },
}