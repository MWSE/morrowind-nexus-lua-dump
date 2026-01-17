local common = common
local self = common.omw.self
local input = common.omw.input
local core = common.omw.core
local util = common.omw.util
local camera = common.omw.camera
local ui = common.omw.ui
local I = common.omw.interfaces

local Anim = common.Anim
local MD = common.MD

local M = {}

function M.processControls(dt, dialogTarget)
	local p = common.poseOpt

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
		if new > #Anim.poses then new = 1		end
		if new < 1 then new = #Anim.poses		end
		p.save = new
		ui.showMessage(Anim.poses[new].name.." ("..Anim.poses[new].id..")")
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

local FullBlackBG = {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture { path = 'white' },
		color = util.color.rgb(0, 0, 0),
	},
}
	
local blackBars = ui.create {
	layer = "FadeToBlack",
	props = {
		relativeSize = util.vector2(1, 1),
		visible = false
	},
	content = ui.content {
		{
			template = FullBlackBG,
			props = {
				relativeSize = util.vector2(1, 0.1),
			},
		},
		{
			template = FullBlackBG,
			props = {
				relativePosition = util.vector2(0, 1),
				relativeSize = util.vector2(1, 0.1),
				anchor = util.vector2(0, 1),
			},
		},
	},
}

local Bars = {
	screenRatio = 1.8,
	size = 0,
	props = blackBars.layout.props,
	propsB1 = blackBars.layout.content[1].props,
	propsB2 = blackBars.layout.content[2].props,
}

local function setBarsRatio(ratio)
	local vec = util.vector2(1, (1 - Bars.screenRatio / (ratio or Bars.screenRatio)) / 2)
	Bars.propsB1.relativeSize = vec
	Bars.propsB2.relativeSize = vec
	blackBars:update()
end

M.bars = {
	ratio = setBarsRatio,
	enable = function(m)
		Bars.props.visible = m
		blackBars:update()
	end,
	element = function()	return blackBars		end,
}

function M.enableShaders(m)
	Bars.screenRatio = ui.screenSize().x / ui.screenSize().y
	local targetRatio = math.max(common.dialogCam.barsRatio, Bars.screenRatio)
--	Bars.size = util.vector2(1, (1 - Bars.screenRatio / targetRatio) / 2)
	Bars.size = (1 - Bars.screenRatio / targetRatio) / 2
	if Bars.size < 0.01 then
		Bars.size = nil
	end
	if m and Bars.size then
		Bars.props.visible = true
	else
		Bars.props.visible = false
		blackBars:update()
	--	print("BLACK BARS OFF")
	end

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
	local z, d = common.zoom1st, common.dialogCam
	local ctrls = self.controls

	-- Force-set 1st person zoom every frame, to counter camera.lua resetting it
	local lerp
	if z.force then
		lerp = 1 - (z.level - 1) ^ 6
		camera.setFirstPersonOffset(z.vector["0xy"] * lerp)
	--	camera.setFirstPersonOffset(util.vector3(0, z.vector.x, z.vector.y) * lerp)
	end
	if z.offset ~= 0 then camera.setExtraYaw(z.offset) end
	ctrls.movement = 0
	ctrls.sideMovement = 0
	local turningToTarget = false

--	local deltaPos = d.deltaPos
--	deltaPos = deltaPos + util.transform.rotateZ(d.target.rotation:getYaw()):apply(d.head)
--		- d.playerEyes
	local deltaPos = d.vecEyeToHead
	local destVec = deltaPos.xy:rotate(camera.getYaw())
--	local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(camera.getYaw())
	local deltaYaw = math.atan2(destVec.x, destVec.y)
	if math.abs(deltaYaw) > math.rad(10) then
		turningToTarget = true
	end
	lerp = math.min((8 * math.abs(deltaYaw) / math.pi) ^ 2 + 0.005, 2)
--	local v = dt * 3.5 * util.clamp(lerp, math.rad(5), 1)
	local v = dt * 3.5 * lerp
	if d.instant then v = 3.5		end
	if math.abs(deltaYaw) > math.rad(1) then
		ctrls.yawChange = util.clamp(deltaYaw, -v, v)
	end

	local lengthXY = deltaPos.xy:length() - d.radius
	local deltaPitch = - math.atan2(deltaPos.z, math.max(lengthXY, d.radius))
		- self.rotation:getPitch()
	if math.abs(deltaPitch) > math.rad(10) then
		turningToTarget = true
	end
	lerp = (8 * math.abs(deltaPitch) / math.pi) ^ 2 + 0.001
	if d.instant then d.instant = false	else v = dt * 3.5 * lerp	end
	if math.abs(deltaPitch) > math.rad(1) then
		ctrls.pitchChange = util.clamp(deltaPitch, -v, v)
	end
	if turningToTarget or (not z.zoomIn) then	return		end

	local distance = (deltaPos:length() - d.radius) * z.scale
	destVec = util.vector2(lengthXY, deltaPos.z):normalize()
	destVec = destVec * util.clamp(distance - z.dist, -5, 300)
--	d.dDist = distance		d.destVec = destVec		d.lxy = lengthXY
	if not z.force then
		z.force = true
		z.vector = destVec
-- print(d.deltaPos:length(), distance, destVec:length(), math.max(distance - 300, z.dist))
	end
	if (destVec - z.vector):length() > 5 then	z.vector = destVec	end
	if z.level >= 1 then	return		end

	z.level = z.level + (dt * z.speed)		z.level = math.min(1, z.level)
	if d.aperture > 0 and z.level > 0.4 then
		lerp = math.min(z.level - 0.4, 0.2) / 0.2
		local dof = d.shaders.dof
		dof.uDepth = d.radius / 3 + math.max(distance - 300, z.dist)
		dof.uAperture = d.aperture * lerp
	end
--	if d.barsRatio > 0 and z.level > 0.2 then
	if Bars.size and z.level > 0.2 then
		lerp = math.min(z.level - 0.2, 0.4) / 0.4
	--	d.shaders.bars.ratio = 1.8 + math.max(d.barsRatio - 1.8, 0) * lerp
		local barSize = util.vector2(1, Bars.size * lerp)
		Bars.propsB1.relativeSize = barSize
		Bars.propsB2.relativeSize = barSize
		blackBars:update()
	end
end

function M.autoCamUpdate(dt)
	local d = common.dialogCam
	d.counter = d.counter - dt	if d.counter > 0 then	return		end
	d.counter = d.interval

	local npc = d.target
	if d.adjust then
	--	d.pos = npc.position
		d.deltaPos = npc.position - self.position
	end
	local keys, focal = d.animKeys
	if keys then
		local isPlaying = Anim.getActiveGroup(npc, 0)
		for _, v in ipairs(keys) do 
			if isPlaying == v then
				focal = d.headPosAnim
			end
		end
		focal = focal or keys[Anim.getActiveGroup(npc, 0)] or keys.default
		focal = focal and d.npcSizeRatios:apply(focal) * npc.scale
		if common.logging then print(isPlaying)		end
	end
	focal = focal or d.vecFocalDefault
	d.vecEyeToHead = d.deltaPos + util.transform.rotateZ(npc.rotation:getYaw()):apply(focal)
		- d.playerEyesVec
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
		if cam.aperture > 0 and z.level > 0.5 then
			lerp = util.clamp(z.level - 0.6, 0, 0.4) / 0.4
			local dof = cam.shaders.dof
			dof.uDepth = z.dist	dof.uAperture = cam.aperture * lerp
		end

	--	if cam.barsRatio > 0 and z.level > 0.2 then
		if Bars.size then
			lerp = util.remap(z.level, 0.5, 1, 0, 1)
		--	setBarsRatio(1.8 + math.max(cam.barsRatio - 1.8, 0) * lerp)
			local barSize = util.vector2(1, Bars.size * lerp)
			Bars.propsB1.relativeSize = barSize
			Bars.propsB2.relativeSize = barSize
			blackBars:update()
		end

	end
	z.level = z.level - (dt * z.speed)

	local floor = common.camSave.mode == MD.FirstPerson and 0.2 or 0.5
	if z.level > floor and inFirst then		return		end

--	print("Reset zoom and first person")
	camera.setFirstPersonOffset(common.camSave.offset1st)
	z.level, z.force = 0, false		z.zoomOut = false
	M.enableShaders(false)
	if inFirst then		M.restoreCamera()		end
end


return M
