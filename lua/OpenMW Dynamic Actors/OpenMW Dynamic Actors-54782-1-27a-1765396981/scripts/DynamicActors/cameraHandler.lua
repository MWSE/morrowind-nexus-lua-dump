local common = common
local self = common.openmw.self
local input = common.openmw.input
local core = common.openmw.core
local util = common.openmw.util
local camera = common.openmw.camera
local ui = common.openmw.ui
local I = common.openmw.interfaces

local MD = camera.MODE
local M = {}

function M.processControls(dt, dialogTarget)
	local p, anims = common.poseOpt, common.anims

	local yaw, pitch, dist, proc = camera.getYaw(), camera.getPitch(), camera.getThirdPersonDistance(), false
	local movex, movey = input.getMouseMoveX(), input.getMouseMoveY()
	local zoom = input.getNumberActionValue("Zoom3rdPerson")
	camera.showCrosshair(true)
	if dialogTarget then
		if movex ~= 0 or movey ~= 0 then
			proc = true
			yaw = yaw + 0.5 * movex * dt
			pitch = pitch + 0.5 * movey * dt
		end
		if zoom ~= 0 then
			proc = true
			dist = dist - zoom
		end
	end
	movex = input.getRangeActionValue("MoveForward") - input.getRangeActionValue("MoveBackward")
	movey = input.getRangeActionValue("MoveRight") - input.getRangeActionValue("MoveLeft")
	if p.choose then p.count = p.count - dt end
	if p.choose and math.abs(movey) > 0.7 and p.count < 1 then
		p.count = 1.25
--[[
		local old = p.save
		local new = old + movey		p.save = new
		old = util.round(old)		new = util.round(new)
--]]
		local new = p.save + (movey > 0 and 1 or -1)
		if new > #anims.poses then new = 1		end
		if new < 1 then new = #anims.poses		end
		p.save = new
--		if new ~= old then
			ui.showMessage(anims.poses[new].name.." ("..anims.poses[new].id..")")
--		end
	end
	if (movex ~= 0 or movey ~= 0) and not p.choose then
		proc = true
		p.offset3rd = util.vector2(p.offset3rd.x + 100*movey*dt, p.offset3rd.y + 100*movex*dt)
	end
	if not proc then return end
	camera.setFocalPreferredOffset(p.offset3rd)
	camera.setPreferredThirdPersonDistance(dist)
	camera.instantTransition()
	camera.setYaw(yaw)
	camera.setPitch(pitch)
end

--[[

local hexDofShader = I.DynamicCamera.shaders["hexDoFProgrammable"]
local blackBarsShader = I.DynamicCamera.shaders["blackBarsProgrammable"]

hexDofShader.u.uDepth = (actorPos - camPos):length()
hexDofShader.u.uAperture = 0.2
blackBarsShader.u.ratio = 2.2
--]]

function M.enableShaders(m)
	if not I.DynamicCamera or not I.DynamicCamera.shaders then	return		end
	local shaders = common.dialogCam.shaders
	if m and not shaders then
		common.dialogCam.shaders = {
			dof = I.DynamicCamera.shaders["hexDoFProgrammable"].u,
			bars = I.DynamicCamera.shaders["blackBarsProgrammable"].u
		}
	elseif not m and shaders then
		shaders.dof.uAperture = 0
		shaders.bars.ratio = 0
	end
end

function M.autoCam(dt)
	local zoom1st, dCam = common.zoom1st, common.dialogCam
	local ctrls = self.controls

	-- Force-set 1st person zoom every frame, to counter camera.lua resetting it
	local lerp
	if zoom1st.force then
		lerp = 1 - (zoom1st.level - 1) ^ 6
		camera.setFirstPersonOffset(zoom1st.vector["0xy"] * lerp)
	--	camera.setFirstPersonOffset(util.vector3(0, zoom1st.vector.x, zoom1st.vector.y) * lerp)
	end
	if zoom1st.offset ~= 0 then camera.setExtraYaw(zoom1st.offset) end
	ctrls.movement = 0
	ctrls.sideMovement = 0
	local turningToTarget = false

	local deltaPos = dCam.deltaPos
	deltaPos = deltaPos + util.transform.rotateZ(dCam.object.rotation:getYaw()):apply(dCam.head)
		- dCam.playerEyes
	local destVec = deltaPos.xy:rotate(camera.getYaw())
--	local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(camera.getYaw())
	local deltaYaw = math.atan2(destVec.x, destVec.y)
        if math.abs(deltaYaw) > math.rad(10) then
		turningToTarget = true
	end
	lerp = math.min((8 * math.abs(deltaYaw) / math.pi) ^ 2 + 0.005, 2)
--	local v = dt * 3.5 * util.clamp(lerp, math.rad(5), 1)
	local v = dt * 3.5 * lerp
	if dCam.instant then v = 3.5		end
        if math.abs(deltaYaw) > math.rad(1) then
            ctrls.yawChange = util.clamp(deltaYaw, -v, v)
        end

	local lengthXY = deltaPos.xy:length() - dCam.radius
	local deltaPitch = - math.atan2(deltaPos.z, math.max(lengthXY, dCam.radius))
		- self.rotation:getPitch()
        if math.abs(deltaPitch) > math.rad(10) then
		turningToTarget = true
        end
	lerp = (8 * math.abs(deltaPitch) / math.pi) ^ 2 + 0.001
	if dCam.instant then dCam.instant = false	else v = dt * 3.5 * lerp	end
        if math.abs(deltaPitch) > math.rad(1) then
		ctrls.pitchChange = util.clamp(deltaPitch, -v, v)
	end
	if turningToTarget or (not zoom1st.zoomIn) then	return		end

	local distance = (deltaPos:length() - dCam.radius) * zoom1st.scale
	destVec = util.vector2(lengthXY, deltaPos.z):normalize()
	destVec = destVec * util.clamp(distance - zoom1st.dist, -5, 300)
--	dCam.dDist = distance		dCam.destVec = destVec		dCam.lxy = lengthXY
	if not zoom1st.force then
		zoom1st.force = true
		zoom1st.vector = destVec
-- print(dCam.deltaPos:length(), distance, destVec:length(), math.max(distance - 300, zoom1st.dist))
	end
	if (destVec - zoom1st.vector):length() > 5 then zoom1st.vector = destVec	end
	if dCam.aperture > 0 and zoom1st.level > 0.4 then
		lerp = math.min(zoom1st.level - 0.4, 0.2) / 0.2
		local dof = dCam.shaders.dof
		dof.uDepth = dCam.radius / 3 + math.max(distance - 300, zoom1st.dist)
		dof.uAperture = dCam.aperture * lerp
	end
	if dCam.ratio > 0 and zoom1st.level > 0.2 then
		lerp = math.min(zoom1st.level - 0.2, 0.4) / 0.4
		dCam.shaders.bars.ratio = 1.8 + math.max(dCam.ratio - 1.8, 0) * lerp
	end
	if zoom1st.level == 1 then	return		end
	if zoom1st.level < 1 then zoom1st.level = zoom1st.level + (dt * zoom1st.speed) end
	zoom1st.level = math.min(zoom1st.level, 1)
end

function M.restoreCamera()
	local cam = common.camSave
--	if camera.getMode() == cam.mode then		return		end

--	print("Reset previous camera mode and view")
	-- directly switching 1stPerson-->Preview using setMode will glitch
	if cam.mode == MD.Preview then
		cam.mode = MD.ThirdPerson
	elseif cam.mode == MD.ThirdPerson and camera.getMode() == MD.Preview then
		camera.setPreferredThirdPersonDistance(cam.dist3rd)
		camera.setYaw(cam.yaw)
		camera.setPitch(cam.pitch)
--		camera.instantTransition()
	end
	camera.setMode(cam.mode)
end

function M.zoomOut1st(dt)
	local z = common.zoom1st	local cam = common.dialogCam
	local inFirst = camera.getMode() == MD.FirstPerson
	local lerp

	if inFirst then
		camera.setFirstPersonOffset(z.vector["0xy"] * z.level ^ 4)
	--	camera.setFirstPersonOffset(util.vector3(0, z.vector.x, z.vector.y) * z.level ^ 4)
		if cam.aperture > 0 and z.level > 0.5 then
			lerp = util.clamp(z.level - 0.6, 0, 0.4) / 0.4
			local dof = cam.shaders.dof
			dof.uDepth = z.dist	dof.uAperture = cam.aperture * lerp
		end
--[[
	if cam.ratio > 0 and z.level > 0.2 then
		lerp = math.min(z.level - 0.2, 0.7) / 0.7
		cam.shaders.bars.ratio = 1.8 + math.max(cam.ratio - 1.8, 0) * lerp
	end
--]]

	end
	z.level = z.level - (dt * z.speed)

	local floor = common.camSave.mode == MD.FirstPerson and 0.2 or 0.5
	if z.level > floor and inFirst then		return		end

--	print("Reset zoom and first person")
	camera.setFirstPersonOffset(common.camSave.offset1st)
	z.level, z.force = 0, false		z.zoomOut = false
	M.enableShaders(false)
	if inFirst then
		M.restoreCamera()
	end
end

return M
