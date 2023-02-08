--[[
	Mod: Steadicam
	Author: Hrnchamd
	Version: 1.1
]]--

local this = {}
local config = {}

local mcm = require("hrnchamd.steadicam.mcm")
mcm.config = config

local function getRotationDampingTerm(animController, dt)
	local damping

	-- Select damping by camera mode
	if animController.is3rdPerson then
		damping = config.thirdPersonLookDamping
	elseif this.freeLookMode then
		damping = config.freeLookDamping
	else
		damping = config.firstPersonLookDamping
	end

	-- Make a smoother transition between cancelling free-look and the regular forward camera
	if this.freeLookResetDamping then
		local t = math.min(1, 15 * dt)
		damping = t * damping + (1 - t) * this.freeLookResetDamping

		if math.abs(this.freeLookResetDamping - damping) > 0.1 then
			this.freeLookResetDamping = damping
		else
			this.freeLookResetDamping = nil
		end
	end

	return 10000 / damping
end

local function getFollowDampingTerm()
	return 1000 / config.thirdPersonFollowDamping
end

local function getQuatAngleDifference(q0, q1)
	return math.acos(math.min(1, math.abs(q0:dot(q1))))
end

local function steadicam(e)
	-- Ignore vanity camera
	if not config.enabled then return end
	if e.animationController.vanityCamera then
		return
	end

	local animController = e.animationController
	local dt = tes3.worldController.deltaTime

	local r_matrix = e.cameraTransform.rotation:copy()
	local r_prev = e.previousCameraTransform.rotation:toQuaternion()
	local r = e.cameraTransform.rotation:toQuaternion()

	if this.freeLookMode then
		-- Free look mode needs horizontal rotation to be tracked separately, vertical look is handled by the game
		-- That rotation is then added to the standard player camera
		local dz = -tes3.worldController.inputController.mouseState.x * tes3.worldController.mouseSensitivityX
		this.freeLookRotateZ = this.freeLookRotateZ + dz

		local q = niQuaternion.new()
		q:fromAngleAxis(this.freeLookRotateZ, tes3vector3.new(0, 0, 1))
		r = q * r
	end

	-- Camera rotation smoothing
	local k = getRotationDampingTerm(animController, dt)
	local delta_angle = getQuatAngleDifference(r_prev, r) + 1e-3
	local speed = k * delta_angle * delta_angle
	speed = math.max(0.01, speed)

	local m = r_prev:rotateTowards(r, speed * dt):toRotation()
	e.cameraTransform.rotation = m

	-- Camera position smoothing (chase cam behaviour)
	if animController.is3rdPerson then
		if this.freeLookMode then
			-- Lock relative camera height during free-look
			e.cameraTransform.translation.z = tes3.player.position.z + this.savedCameraRelativePosition.z
		end

		local speedChase = getFollowDampingTerm()
		e.cameraTransform.translation = e.previousCameraTransform.translation:lerp(e.cameraTransform.translation, math.min(1, speedChase * dt))
	end

	-- First person arms control
	local firstPersonNode = tes3.player1stPerson.sceneNode

	if this.freeLookMode then
		-- First + third person free-look

		-- Free-look mode freezes player visual rotation and movement controller rotation
		firstPersonNode.rotation = this.saved1stPersonRotation
		animController.groundPlaneRotation = this.savedGroundPlaneRotation
	elseif not animController.is3rdPerson then
		-- First person view no free-look

		-- Lock first person Z axis rotation to smoothed camera while keeping gameplay procedural rotation
		-- This removes jitter from the unsmoothed movement controller
		local armRotation = e.armCameraTransform.rotation:copy()
		local proceduralRot = (firstPersonNode.rotation:transpose() * armRotation):transpose()

		if tes3.mobilePlayer.hasFreeAction then
			firstPersonNode.rotation = m * proceduralRot
		end

		-- Arms smoothing modes
		if this.saved1stPersonRotation then
			-- First person arms smooth return after ending free-look
			local p_prev = this.saved1stPersonRotation:toQuaternion()
			local p = (r_matrix * proceduralRot):toQuaternion()
			local speed_arms = 20 * getQuatAngleDifference(p_prev, p)

			m = p_prev:rotateTowards(p, speed_arms * dt):toRotation()
			firstPersonNode.rotation = m
			this.saved1stPersonRotation = m

			-- Cancel smoothing on convergence
			if speed_arms < 0.001 and delta_angle < 0.003 then
				this.saved1stPersonRotation = nil
				this.lastBodyInertiaRotation = m:copy()
			end
		elseif config.bodyInertia then
			-- Body inertia converges on calculated rotation
			if not this.lastBodyInertiaRotation then
				this.lastBodyInertiaRotation = firstPersonNode.rotation:copy()
			end

			local p_prev = this.lastBodyInertiaRotation:toQuaternion()
			local p = firstPersonNode.rotation:toQuaternion()
			local speed_arms = (1000 / config.bodyInertiaDamping) * getQuatAngleDifference(p_prev, p)

			m = p_prev:rotateTowards(p, speed_arms * dt):toRotation()
			firstPersonNode.rotation = m
			this.lastBodyInertiaRotation = m
		end
	end

	firstPersonNode:update()

	-- Arm camera matches world camera
	e.armCameraTransform = e.cameraTransform
end

local function freeLookToggle()
	this.freeLookMode = not this.freeLookMode

	if this.freeLookMode then
		-- Free-look mode freezes player visual position and movement controller rotation
		this.saved1stPersonRotation = tes3.player1stPerson.sceneNode.rotation:copy()
		this.savedGroundPlaneRotation = tes3.mobilePlayer.animationController.groundPlaneRotation:copy()
		this.savedCameraRelativePosition = tes3.worldController.worldCamera.cameraRoot.translation - tes3.player.position
		this.freeLookRotateZ = 0

		-- Cancel transition state and body inertia
		this.freeLookResetDamping = nil
		this.lastBodyInertiaRotation = nil
	else
		-- Transition back to forward look with initial heavy damping
		this.freeLookResetDamping = 10000
	end
end

local function keyEvent(e)
	if tes3.menuMode() then return end
	if not config.enabled then return end

	if tes3.isKeyEqual{expected = config.freeLookKeybind, actual = e} then
		freeLookToggle()
	end
end

event.register(tes3.event.modConfigReady, function()
	mcm.registerModConfig()
	event.register(tes3.event.cameraControl, steadicam)
	event.register(tes3.event.keyDown, keyEvent)
end)