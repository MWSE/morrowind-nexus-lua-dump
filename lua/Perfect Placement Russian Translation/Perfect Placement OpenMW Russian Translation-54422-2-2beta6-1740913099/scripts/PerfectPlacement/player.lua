--[[
    Mod: Perfect Placement OpenMW
    Author: Hrnchamd
    Version: 2.2beta
]]--

local async = require('openmw.async')
local camera = require('openmw.camera')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local input = require('openmw.input')
local player = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local itemSound = require('scripts.PerfectPlacement.itemSound')
local gui = require('scripts.PerfectPlacement.gui')
local orientModule = require('scripts.PerfectPlacement.orient')
local config = require('scripts.PerfectPlacement.config')
local l10n = core.l10n('PerfectPlacement')

local this = {
    maxReach = 1.2,
    holdKeyTime = 0.75,
    rotateMode = false,
    snapMode = false,
    verticalMode = 0,
    freezeAlign = false,
    groundAlign = config.options.initialGroundAlign,
    wallAlign = config.options.initialWallAlign
}

local placeableTypes = {
    [types.Apparatus] = true,
    [types.Armor] = true,
    [types.Book] = true,
    [types.Clothing] = true,
    [types.Ingredient] = true,
    [types.Light] = true,
    [types.Lockpick] = true,
    [types.Miscellaneous] = true,
    [types.Potion] = true,
    [types.Probe] = true,
    [types.Repair] = true,
    [types.Weapon] = true,
}

local const_epsilon = 0.001



local function mutableVec3(v)
	return { x = v.x, y = v.y, z = v.z }
end

local function transformToAngles(t)
	local x, y, z

	--z, y, x = t:getAnglesZYX() -- Broken in OpenMW

	-- Temporary replacement code
	local forward = t * util.vector3(0, 1, 0)
	local up = t * util.vector3(0, 0, 1)
	forward = forward:normalize()
	up = up:normalize()

	if math.abs(up.z) < 1e-5 then
		x = -0.5 * math.pi
		y = math.atan2(-up.x, -up.y)
	else
		x = math.atan2(up.y, up.z)
		y = -math.asin(up.x)
	end
	local fz = (util.transform.rotateY(-y) * util.transform.rotateX(-x)) * forward
	z = math.atan2(fz.x, fz.y)

	return { x = x, y = y, z = z }
end

local function transformFromAngles(t)
	return util.transform.rotateX(t.x) * util.transform.rotateY(t.y) * util.transform.rotateZ(t.z)
end

local function showAngles(prefix, a)
	ui.showMessage(string.format("%s X %0.3f Y %0.3f Z %0.3f", prefix, a.x, a.y, a.z))
end

local function castRenderingRayInclLandscape(from, to, opt)
	-- Workaround for castRenderingRay not working with landscape geometry.
	local result = nearby.castRenderingRay(from, to, opt)
	if result.hit or not player.cell.isExterior then
		return result
	end
	
	local optLandscape = { collisionType = nearby.COLLISION_TYPE.HeightMap }
	if opt then
		optLandscape.ignore = opt.ignore
	end
	
	result = nearby.castRay(from, to, optLandscape)
	if result.hit and result.hitObject == nil then
		return result
	end

	return { hit = false }
end

local function cancelableTimer(delay, func)
	local data = {}
	async:newUnsavableSimulationTimer(delay, function()
		if not data.cancel then func() end
	end)
	return data
end

local function cancelPlayerTurning()
	player.controls.yawChange = 0
	player.controls.pitchChange = 0
end

local function castActivationRay()
	local v = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
	local dist = core.getGMST("iMaxActivateDist")
	local pos = camera.getPosition()
	return nearby.castRenderingRay(pos, pos + v * dist)
end

local endPlacement, endPlacementWithReset -- local functions

-- Set rotation frame and effective height for horizontal mode.
local function setHorizontalMode()
	this.orientation.x = 0
	this.orientation.y = 0
	this.orientation.z = transformToAngles(player.rotation).z
	this.height = -this.boundMin.z
end

-- Set rotation frame and effective height for vertical modes.
local function setVerticalMode(n)
	local half_pi = 0.5 * math.pi
    local prevHeight = this.height
    this.orientation.x = -half_pi
    this.orientation.y = player.rotation:getYaw()
	
    if (n == 1) then
        this.orientation.z = 0
        this.height = -this.boundMin.y
    elseif (n == 2) then
        this.orientation.z = -half_pi
        this.height = -this.boundMin.x
    elseif (n == 3) then
        this.orientation.z = math.pi
        this.height = this.boundMax.y
    elseif (n == 4) then
        this.orientation.z = half_pi
        this.height = this.boundMax.x
    end

    this.newPosition = this.activeObj.position + util.vector3(0, 0, this.height - prevHeight)
	this.newRotation = transformFromAngles(this.orientation)
	core.sendGlobalEvent("PerfectPlacement:Move", this)
end

-- Match vertical mode from an orientation.
local function matchVerticalMode(orient, boundMin, boundMax)
    local absOriX = math.abs(orient.x)
    if (absOriX > 1.55 and absOriX < 1.59) then
        local k = math.floor(0.5 + orient.z / (0.5 * math.pi))
        if (k == 0 or k == 4) then
            this.verticalMode = 1
            this.height = -boundMin.y
        elseif (k == -1 or k == 3) then
            this.verticalMode = 2
            this.height = -boundMin.x
        elseif (k == -2 or k == 2) then
            this.verticalMode = 3
            this.height = boundMax.y
        elseif (k == -3 or k == 1) then
            this.verticalMode = 4
            this.height = boundMax.x
        end
    else
        this.verticalMode = 0
        this.height = -boundMin.z
    end
end

-- Called to confirm final placement, drops item to ground if not attaching to wall.
local function finalPlacement()
	-- Read back possibly quantized rotation.
	this.orientation = transformToAngles(this.activeObj.rotation)
    this.lastItemOri = this.orientation

    if (not this.wallMount and not this.rotateMode) then
        -- Match vertical mode to get correct object height after arbitrary rotations.
        matchVerticalMode(this.orientation, this.boundMin, this.boundMax)

        -- Drop to ground.
        local from = this.activeObj.position + util.vector3(0, 0, -this.height + const_epsilon)
		local to = from + util.vector3(0, 0, -4096)
        local ray = castRenderingRayInclLandscape(from, to, { ignore = this.activeObj })

        if (ray.hit) then
            if (this.verticalMode == 0 and this.groundAlign and not this.freezeAlign) then
                this.orientation = orientModule.orientRef(this.activeObj, this.orientation, this.isTall, ray.hitNormal)
            end

			-- Global event data to send.
			local data = {
				activeObj = this.activeObj,
				newPosition = ray.hitPos + util.vector3(0, 0, this.height + const_epsilon),
				newRotation = transformFromAngles(this.orientation)
			}
			--showAngles("drop before", this.orientation)
			--showAngles("drop after", transformToAngles(data.newRotation))
	
			-- Place object at final position.
			core.sendGlobalEvent("PerfectPlacement:Drop", data)
        end
	end
    
	core.sendGlobalEvent("PerfectPlacement:End", this)
    endPlacement()
end

-- OpenMW changed bounding boxes to be world AABBs. Get the approximate bound of an unrotated object.
local function setInitialBound(target, orientation)
	local bbox = target:getBoundingBox()
	local localCenter = bbox.center - target.position
	local boundMin = localCenter - bbox.halfSize
	local boundMax = localCenter + bbox.halfSize

	-- This is a hacky workaround to approximately extract the base bbox from the world bbox.
	local absOriX = math.abs(orientation.x)
	if (absOriX > 1.55 and absOriX < 1.59) then
		local k = math.floor(0.5 + orientation.y / (0.5 * math.pi))
		if (k == 0 or k == 4) then
			this.boundMin = util.vector3(boundMin.x, boundMin.z, -boundMax.y)
			this.boundMax = util.vector3(boundMax.x, boundMax.z, -boundMin.y)
		elseif (k == -1 or k == 3) then
			this.boundMin = util.vector3(boundMin.y, boundMin.z, boundMin.x)
			this.boundMax = util.vector3(boundMax.y, boundMax.z, boundMax.x)
		elseif (k == -2 or k == 2) then
			this.boundMin = util.vector3(-boundMax.x, boundMin.z, boundMin.y)
			this.boundMax = util.vector3(-boundMin.x, boundMax.z, boundMax.y)
		elseif (k == -3 or k == 1) then
			this.boundMin = util.vector3(-boundMax.y, boundMin.z, -boundMax.x)
			this.boundMax = util.vector3(-boundMin.y, boundMax.z, -boundMin.x)
		end
	else
		this.boundMin = boundMin
		this.boundMax = boundMax
	end
	
	-- Tallness is used by the align-to-ground feature.
	local extent = this.boundMax - this.boundMin
	this.isTall = extent.z > extent.x or extent.z > extent.y
end

-- Copy orientation event handler.
local function copyLastOri()
    if (this.lastItemOri) then
        this.orientation = mutableVec3(this.lastItemOri)
        this.freezeAlign = true
        matchVerticalMode(this.orientation, this.boundMin, this.boundMax)
    end
end

-- On grabbing / dropping an item.
local function activatePlacement()
    local targetRay = castActivationRay()
	local target = targetRay.hitObject

    -- Do not operate in menu mode and during attacking/casting (no OpenMW anim support yet).
    if core.isWorldPaused() then
        return
    end
    
    if (this.activeObj) then
        -- Drop item.
        finalPlacement()
    elseif (target) then
        -- Filter by allowed object type.
        if (not placeableTypes[target.type]) then
            return
        end
		if target.type == types.Light and not types.Light.record(target).isCarriable then
			return
		end
        -- Ownership test.
		local owner = target.owner
        if (owner.recordId or owner.factionId) then
            if (owner.factionId and types.NPC.getFactionRank(player, owner.factionId) >= owner.factionRank and not types.NPC.isExpelled(player, owner.factionId)) then
                -- Player has sufficient faction rank.
            else
                ui.showMessage(l10n("OwnedItem"))
                return
            end
        end

        -- Put those hands away.
		if types.Actor.getStance(player) ~= types.Actor.STANCE.Nothing then
			types.Actor.setStance(player, types.Actor.STANCE.Nothing)
		end

		-- Calculate effective bounds including scale.
		local orientation = transformToAngles(target.rotation)
		--showAngles("activatePlacement", orientation)
		setInitialBound(target, orientation)
		matchVerticalMode(orientation, this.boundMin, this.boundMax)

        -- Get exact ray to selection point, relative to 1st person camera.
        local eye = camera.getPosition()
        local basePos = target.position - util.vector3(0, 0, this.height)

        -- Check if item is attached to a wall.
        if (this.verticalMode ~= 0) then
            local attachRay = util.vector3(math.sin(orientation.y), math.cos(orientation.y), 0)
            local attachPos = util.vector3(basePos.x + -this.boundMin.z * attachRay.x, basePos.y + -this.boundMin.z * attachRay.y, basePos.z)
			local from = attachPos + attachRay * -0.5
			local to = attachPos + attachRay * 0.5
            local wallRay = nearby.castRenderingRay(from, to, { ignore = target })

            if (wallRay.hit) then
                -- Adjust basePos to be on the model edge that is touching the wall.
                basePos = attachPos
            end
        end

        this.rayDir = camera.getViewTransform() * basePos

        -- Save initial placement.
        this.itemInitialPos = target.position
        this.itemInitialRot = target.rotation
        this.playerLastOri = transformToAngles(player.rotation)
        this.orientation = orientation
        this.freezeAlign = false

        this.activeObj = target
		core.sendGlobalEvent("PerfectPlacement:Begin", this)
        --#tes3ui.suppressTooltip(true)
        
        if (config.options.showGuide) then
            gui.showGuide(config.keybinds)
        end
    end
end

-- Called every simulation frame to reposition the item.
local function onFrame(deltaTime)
	if core.isWorldPaused() then return end
	if not this.activeObj then return end
	
    -- Stop if player takes the object.
    if (this.objRemoved or this.activeObj.cell == nil) then
        endPlacement()
		this.objRemoved = nil
        return
    -- Check for cell change.
    elseif (not this.activeObj.cell:isInSameSpace(player)) then
        ui.showMessage(l10n("CannotMoveBetweenCells"))
        endPlacementWithReset()
        return
    -- Drop item if player readies combat or casts a spell.
    elseif (types.Player.stance(player) ~= types.Player.STANCE.Nothing) then
        finalPlacement()
        return
    end

    -- Cast ray along initial pickup direction rotated by the 1st person camera.
    local eye = camera.getPosition()
    local rayDir = camera.getViewTransform():inverse() * this.rayDir - eye
    local ray = castRenderingRayInclLandscape(eye, eye + rayDir:normalize() * 800, { ignore = this.activeObj })
	local hitT = ray.hit and (ray.hitPos - eye):length() / rayDir:length()
    
    -- Limit holding distance to a maxReach * initial distance.
    local pos
    if (ray.hit and hitT <= this.maxReach) then
        pos = ray.hitPos
    else
        pos = eye + rayDir * this.maxReach
    end
    -- Add epsilon to ensure the intersection is not inside the model during to floating point precision.
    pos = pos + util.vector3(0, 0, const_epsilon)
	-- If the hit surface uses double-sided rendering, select a normal that faces the camera.
	local hitNormal = ray.hitNormal
	if rayDir:dot(hitNormal) > 0 then
		hitNormal = hitNormal * -1
	end

    -- Item orientation handling.
    this.wallMount = false
    if (this.verticalMode == 0) then
        if (not this.freezeAlign) then
            -- Ground mode. Check if item is directly touching something.
            if (ray.hit and hitT <= this.maxReach and this.groundAlign) then
                -- Orient item to match placement.
                this.orientation = orientModule.orientRef(this.activeObj, this.orientation, this.isTall, hitNormal)
            else
                -- Remove any tilt rotation, in an animated manner.
                local ease = math.max(0.5, 1 - 20 * deltaTime)
                this.orientation.x = ease * this.orientation.x
                this.orientation.y = ease * this.orientation.y
                if (math.abs(this.orientation.x) < 0.02) then
                    this.orientation.x = 0
                end
                if (math.abs(this.orientation.y) < 0.02) then
                    this.orientation.y = 0
                end
            end
        end
    else
        -- Vertical mode. Check if the bottom of the model is close to other geometry.
        local clearance = math.max(2, -this.boundMin.z)
        rayDir = util.vector3(clearance * math.sin(this.orientation.y), clearance * math.cos(this.orientation.y), 0)
		local from = pos + rayDir * -const_epsilon
        ray = castRenderingRayInclLandscape(from, from + rayDir * 2, { ignore = this.activeObj })
		hitT = ray.hit and (ray.hitPos - from):length() / clearance
        
        if (ray.hit and hitT < 1) then
            -- Place at minimum distance outside wall, and optionally align rotation with normal.
            pos = ray.hitPos - rayDir
            if (this.wallAlign and math.abs(hitNormal.z) < 0.2) then
                this.orientation.y = math.atan2(-hitNormal.x, -hitNormal.y)
            end
            this.wallMount = true
        end
    end

    -- Find drop position for shadow spot.
	--[[
    local dropPos = pos
    ray = castRenderingRayInclLandscape(pos, pos + util.vector3(0, 0, -2048), { ignore = this.activeObj })
    if (ray.hit) then
        dropPos = ray.hitPos
    end
	]]--

    -- Get object centre from base point
    pos = pos + util.vector3(0, 0, this.height)

    -- Incrementally rotate the same amount as the player, to keep relative alignment with player.
	local playerCurrentOri = transformToAngles(player.rotation)
    local d_theta = playerCurrentOri.z - this.playerLastOri.z
    this.playerLastOri = playerCurrentOri

    if (this.rotateMode) then
		-- View rotation freeze. Use custom input handling.
		cancelPlayerTurning()
		local controllerMoveX = 2 * input.getAxisValue(input.CONTROLLER_AXIS.LookLeftRight)
		local horizontalMove = controllerMoveX ~= 0 and controllerMoveX or input.getMouseMoveX()
        d_theta = 0.001 * config.options.sensitivity * horizontalMove
    end

    -- Apply rotation.
    if (this.verticalMode == 0) then
        -- Ground plane rotation.
        this.orientation.z = util.normalizeAngle(this.orientation.z + d_theta)
    elseif (this.wallMount and this.rotateMode) then
        -- Wall mount rotation.
        this.orientation.z = util.normalizeAngle(this.orientation.z + d_theta)
    else
        -- Vertical rotation.
        this.orientation.y = util.normalizeAngle(this.orientation.y + d_theta)
    end

    -- Rotation snap.
    local orient = mutableVec3(this.orientation)
    if (this.snapMode) then
        local quantizer = config.options.snapQuantizer
        if (this.verticalMode == 0 or this.wallMount) then
            orient.z = quantizer * math.floor(0.5 + orient.z / quantizer)
        else
            orient.y = quantizer * math.floor(0.5 + orient.y / quantizer)
        end
    end

    -- Update item.
	this.newPosition = pos
	this.newRotation = transformFromAngles(orient)
	--showAngles("orient", orient)
	core.sendGlobalEvent("PerfectPlacement:Move", this)
end

-- Clean up placement.
endPlacement = function()
	if (this.verticalHoldTimer) then
		this.verticalHoldTimer.cancel = true
		this.verticalHoldTimer = nil
	end
    
	core.sendGlobalEvent("PerfectPlacement:End", this)
    --#tes3ui.suppressTooltip(false)
    
    -- this.snapMode is persistent
    -- this.groundAlign is persistent
    -- this.wallAlign is persistent
    this.activeObj = nil
    this.rotateMode = nil
    this.verticalMode = 0
    
	gui.hideGuide()
end

endPlacementWithReset = function ()
	-- Global event data to send.
	local data = {
		activeObj = this.activeObj,
		newPosition = this.itemInitialPos,
		newRotation = this.itemInitialRot
	}
	-- Restore original item position.
	core.sendGlobalEvent("PerfectPlacement:Drop", data)

	endPlacement()
end

-- End placement on load game. this.activeObj would be invalid after load.
local function onLoad(e)
    if (this.activeObj) then
        endPlacement()
    end
end

-- Input

local function registerTrigger(key, name)
	input.registerTrigger({ key = key, l10n = 'PerfectPlacement', name = name, description = name })
end

registerTrigger('PerfectPlacement/Place', 'GrabDropItem')
registerTrigger('PerfectPlacement/RotateMode', 'RotateItem')
registerTrigger('PerfectPlacement/SnapMode', 'SnapRotation')
registerTrigger('PerfectPlacement/VerticalMode', 'VerticalMode')
registerTrigger('PerfectPlacement/SurfaceAlignMode', 'OrientToSurface')
registerTrigger('PerfectPlacement/RotateMode/Release', 'RotateItem')
registerTrigger('PerfectPlacement/VerticalMode/Release', 'VerticalMode')

input.registerTriggerHandler('PerfectPlacement/Place', async:callback(activatePlacement))
input.registerTriggerHandler('PerfectPlacement/RotateMode', async:callback(function()
	if (not this.activeObj) then return end

	this.rotateMode = true
end))
input.registerTriggerHandler('PerfectPlacement/SnapMode', async:callback(function()
	if (not this.activeObj) then return end

	this.snapMode = not this.snapMode
end))
input.registerTriggerHandler('PerfectPlacement/VerticalMode', async:callback(function()
	if (not this.activeObj) then return end

	this.verticalHoldTimer = cancelableTimer(this.holdKeyTime, copyLastOri)

	if (this.verticalMode == 0) then
		this.verticalMode = 1
		setVerticalMode(this.verticalMode)
	else
		this.verticalMode = 0
		setHorizontalMode()
	end
end))
input.registerTriggerHandler('PerfectPlacement/SurfaceAlignMode', async:callback(function()
	if (not this.activeObj) then return end

	if (this.verticalMode == 0) then
		this.groundAlign = not this.groundAlign
	else
		this.wallAlign = not this.wallAlign
	end
end))
input.registerTriggerHandler('PerfectPlacement/RotateMode/Release', async:callback(function()
	if (not this.activeObj) then return end

	this.rotateMode = false
end))
input.registerTriggerHandler('PerfectPlacement/VerticalMode/Release', async:callback(function()
	if (not this.activeObj) then return end

	if (this.verticalHoldTimer) then
		this.verticalHoldTimer.cancel = true
	end
end))

-- Manual dispatch here because access to the keybinds are required to display them/set defaults.
local function onKeyPress(e)
	local code, keybinds = e.code, config.keybinds

	if (code == keybinds.keybindPlace) then
		input.activateTrigger('PerfectPlacement/Place')
    elseif (code == keybinds.keybindRotate) then
		input.activateTrigger('PerfectPlacement/RotateMode')
	elseif (code == keybinds.keybindSnap) then
		input.activateTrigger('PerfectPlacement/SnapMode')
    elseif (code == keybinds.keybindVertical) then
		input.activateTrigger('PerfectPlacement/VerticalMode')
	elseif (code == keybinds.keybindSurfaceAlign) then
		input.activateTrigger('PerfectPlacement/SurfaceAlignMode')
    end
end

local function onKeyRelease(e)
	local code, keybinds = e.code, config.keybinds

    if (code == keybinds.keybindRotate) then
		input.activateTrigger('PerfectPlacement/RotateMode/Release')
    elseif (code == keybinds.keybindVertical) then
		input.activateTrigger('PerfectPlacement/VerticalMode/Release')
	end
end



return {
	eventHandlers = {
		["PerfectPlacement:ObjRemoved"] = function(e)
			this.objRemoved = true
		end
	},
    engineHandlers = {
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
		onLoad = onLoad,
		onFrame = onFrame,
    }
}