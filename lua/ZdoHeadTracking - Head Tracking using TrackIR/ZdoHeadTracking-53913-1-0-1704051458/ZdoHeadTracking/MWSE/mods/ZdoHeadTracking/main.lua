--[[
    ZdoHeadTracking

    Source code based on the code from
    Steadicam v1.1 by Hrnchamd

	and on the OpenMW head bobbing logic written in Lua.
]]--

local config = require("ZdoHeadTracking.config")

local deg2rad = (1.0 / 180.0 * 3.1415)
local headTrackXPitch = 0
local headTrackYRoll = 0
local headTrackZYaw = 0
local headTrackXMove = 0
local headTrackYMove = 0
local headTrackZMove = 0

-- Trajectory of each step is a scaled arc of 60 degrees.
local halfArc = math.rad(30)
local sampleArc = function(x) return 1 - math.cos(x * halfArc) end
local arcHeight = sampleArc(1)
local effectWeight = 0
local totalMovement = 0

local function debugLog(fmt, ...)
	if config.debug then
		return mwse.log("[ZdoHeadTracking] " .. fmt, ...)
	end
end

local function clampHeadTrackMove(x)
    local maxValue = config.maxHeadOffset
    return math.max(math.min(x, maxValue), -maxValue)
end

local function cameraControl(e)
	if not config.enable then
		return
	end
	if e.animationController.vanityCamera then
		debugLog("Vanity camera, ignore")
		return
	end

	local animController = e.animationController
	local dt = tes3.worldController.deltaTime

	local r = e.cameraTransform.rotation:toQuaternion()
	local r_matrix = e.cameraTransform.rotation:copy()
    local rOld = r

    -- TODO: check whether seeking to the beginning works instead of reopening
    local htfile = io.open(config.file, "rb")
    local htfileData = htfile:read "*a"
    htfile:close();

    local htfileComponents = {}
    for w in htfileData:gmatch("[%d-.]+") do
        table.insert(htfileComponents, w)
    end

	-- file read/write race condition protection
    local isValid = tonumber(htfileComponents[1]) ~= nil
    if isValid then
        headTrackZYaw = -tonumber(htfileComponents[1]) * deg2rad
        headTrackXPitch = tonumber(htfileComponents[2]) * deg2rad
        headTrackYRoll = tonumber(htfileComponents[3]) * deg2rad
        headTrackXMove = tonumber(htfileComponents[4])
        headTrackYMove = tonumber(htfileComponents[5])
        headTrackZMove = tonumber(htfileComponents[6])
    end

	if config.debug then
		debugLog("%s", json.encode({headTrackZYaw, headTrackXPitch, headTrackYRoll, headTrackXMove, headTrackYMove, headTrackZMove}))
	end

	if config.yaw ~= 0 then
		local q = niQuaternion.new()
		q:fromAngleAxis(headTrackZYaw, tes3vector3.new(0, 0, 1)) --r_matrix:getUpVector())
		r = q * r
	end

	if config.pitch ~= 0 then
		local q = niQuaternion.new()
		q:fromAngleAxis(headTrackXPitch, r_matrix:getRightVector())
		r = q * r
	end

	if config.roll ~= 0 then
		local q = niQuaternion.new()
		q:fromAngleAxis(headTrackYRoll, r_matrix:getForwardVector())
		r = q * r
	end

    -- head bobbing
	local speed = 0
	local p = tes3.mobilePlayer
	if p.isMovingBack or p.isMovingForward or p.isMovingLeft or p.isMovingRight then
		if tes3.mobilePlayer.isRunning then
			speed = p.runSpeed
		elseif tes3.mobilePlayer.isWalking then
			speed = p.walkSpeed
		end
	end

	totalMovement = totalMovement + speed * dt
	if animController.is3rdPerson then
		effectWeight = 0
	end
	if tes3.mobilePlayer.isFlying or tes3.mobilePlayer.isFalling or tes3.mobilePlayer.isJumping then
		effectWeight = math.max(0, effectWeight - dt * 5)
	else
		effectWeight = math.min(1, effectWeight + dt * 5)
	end

	local doubleStepLength = config.stepLength * 2
	local stepHeight = config.stepHeight;
	local maxRoll = math.rad(config.maxRoll);

	local doubleStepState = totalMovement / doubleStepLength
	doubleStepState = doubleStepState - math.floor(doubleStepState)  -- from 0 to 1 during 2 steps
	local stepState = math.abs(doubleStepState * 4 - 2) - 1  -- from -1 to 1 on even steps and from 1 to -1 on odd steps
	local effect = sampleArc(stepState) / arcHeight  -- range from 0 to 1

	-- Smoothly reduce the effect to zero when the player stops
	local smoothedSpeed = speed
	local coef = math.min(smoothedSpeed / 300, 1) * effectWeight

	local zOffset = (0.5 - effect) * coef * stepHeight  -- range from -stepHeight/2 to stepHeight/2
	local roll = ((stepState > 0 and 1) or -1) * effect * coef * maxRoll  -- range from -maxRoll to maxRoll

	local headBobRollQ = niQuaternion.new()
	headBobRollQ:fromAngleAxis(roll, r_matrix:getForwardVector())
	r = headBobRollQ * r

	local tNew = e.cameraTransform.translation:copy()

	if config.x ~= 0 then
		local direction = r_matrix:getRightVector()
		tNew = tes3.player1stPerson.sceneNode.translation + direction:normalized() * clampHeadTrackMove(headTrackXMove) * config.x
	end
	if config.y ~= 0 then
		local direction = r_matrix:getForwardVector()
		tNew = tes3.player1stPerson.sceneNode.translation + direction:normalized() * clampHeadTrackMove(headTrackYMove) * config.y
	end
	if config.z ~= 0 then
		local direction = r_matrix:getUpVector()
		tNew = tes3.player1stPerson.sceneNode.translation + direction:normalized() * clampHeadTrackMove(headTrackZMove) * config.z
	end

	tNew.z = tes3.player1stPerson.sceneNode.translation.z + zOffset

    e.cameraTransform.translation = tNew
    e.cameraTransform.rotation = r:toRotation()

    tes3.player1stPerson.sceneNode.rotation = rOld:toRotation()
    --animController.groundPlaneRotation = rOld:toRotation()

	tes3.player1stPerson.sceneNode:update()

	-- Arm camera matches world camera
	e.armCameraTransform = e.cameraTransform

	debugLog("ZdoHeadTracking should be applied")
end

local function initialized()
	mwse.log("ZdoHeadTracking initialized")
	event.register(tes3.event.cameraControl, cameraControl)
end

event.register("initialized", initialized)

event.register("modConfigReady", function()
	require("ZdoHeadTracking.mcm")
end)
