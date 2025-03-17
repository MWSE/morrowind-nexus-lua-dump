local common = common
local self = common.openmw.self
local input = common.openmw.input
local core = common.openmw.core
local util = common.openmw.util
local camera = common.openmw.camera
local ui = common.openmw.ui
local I = common.openmw.interfaces


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
	if p.choose and math.abs(movey) > 0.5 and p.count < 1 then
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
		if new ~= old then
			ui.showMessage(anims.poses[new].name.." ("..anims.poses[new].id..")")
		end
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

function M.autoCam(dt)
	local zoom1st, dialogCam = common.zoom1st, common.dialogCam
	local ctrls = self.controls

	-- Force-set 1st person zoom every frame, to counter camera.lua resetting it
	local bezier
	if zoom1st.force then
		bezier = 1 - (zoom1st.level - 1) ^ 6
		camera.setFirstPersonOffset(util.vector3(0, zoom1st.vector.x, zoom1st.vector.y) * bezier)
	end
	if zoom1st.offset ~= 0 then camera.setExtraYaw(zoom1st.offset) end
	ctrls.movement = 0
        ctrls.sideMovement = 0
	local turningToTarget = false

        local deltaPos = dialogCam.pos - self.position
        local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(camera.getYaw())
        local deltaYaw = math.atan2(destVec.x, destVec.y)
        if math.abs(deltaYaw) > math.rad(10) then
            turningToTarget = true
        end
	bezier = (8 * math.abs(deltaYaw) / math.pi) ^ 2
--	local v = dt * 3.5 * util.clamp(bezier, math.rad(5), 1)
	local v = dt * 3.5 * bezier
	if dialogCam.instant then v = 3.5 end
        if math.abs(deltaYaw) > math.rad(2) then
            ctrls.yawChange = util.clamp(deltaYaw, -v, v)
        end

	local headPos = self.position + util.vector3(0, 0, dialogCam.playerHeight * 0.974)
	deltaPos = (dialogCam.pos + util.vector3(0, 0, dialogCam.height)) - headPos
	local lengthXY = util.vector2(deltaPos.x, deltaPos.y):length()
	local deltaPitch = - math.atan2(deltaPos.z, lengthXY) - self.rotation:getPitch()
--	local deltaPitch = - math.asin( deltaPos.z / deltaPos:length() ) - self.rotation:getPitch()
        if math.abs(deltaPitch) > math.rad(10) then
            turningToTarget = true
        end
	bezier = (8 * math.abs(deltaPitch) / math.pi) ^ 2
	if dialogCam.instant then dialogCam.instant = false else v = dt * 3.5 * bezier end
        if math.abs(deltaPitch) > math.rad(2) then
            ctrls.pitchChange = util.clamp(deltaPitch, -v, v)
        end
	if turningToTarget or (not zoom1st.enabled) then return end

	local distance = deltaPos:length() * zoom1st.scale
	destVec = util.vector2(lengthXY, deltaPos.z) * util.clamp((distance - zoom1st.dist), -5, 2000) / distance
	if not zoom1st.force then
		zoom1st.force = true
		zoom1st.vector = destVec
	end
	if (destVec - zoom1st.vector):length() > 5 then zoom1st.vector = destVec end
	if zoom1st.level == 1 then return end
	if zoom1st.level < 1 then zoom1st.level = zoom1st.level + (dt * zoom1st.speed) end	
	if zoom1st.level > 1 then zoom1st.level = 1 end
end


return M
