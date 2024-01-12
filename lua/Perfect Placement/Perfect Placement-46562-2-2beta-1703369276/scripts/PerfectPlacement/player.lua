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
local config = require('scripts.PerfectPlacement.settings')
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
	y = -math.asin(up.x)
	x = math.atan2(up.y, up.z)
	local fz = (util.transform.rotateY(-y) * util.transform.rotateX(-x)) * forward
	z = math.atan2(fz.x, fz.y)

	return { x = x, y = y, z = z }
end

local function transformFromAngles(t)
	return util.transform.rotateX(t.x) * util.transform.rotateY(t.y) * util.transform.rotateZ(t.z)
end

local function showAngles(prefix, a)
	ui.showMessage(string.format("%s X %.2f Y %.2f Z %.2f", prefix, a.x, a.y, a.z))
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

-- Set rotation frame and effective height for vertical modes.
local function setVerticalMode(n)
    local prevHeight = this.height
    this.orientation.x = -0.5 * math.pi
    this.orientation.y = player.rotation:getYaw()
	
    if (n == 1) then
        this.orientation.z = 0
        this.height = -this.boundMin.y
    elseif (n == 2) then
        this.orientation.z = -0.5 * math.pi
        this.height = -this.boundMin.x
    elseif (n == 3) then
        this.orientation.z = math.pi
        this.height = this.boundMax.y
    elseif (n == 4) then
        this.orientation.z = 0.5 * math.pi
        this.height = this.boundMax.x
    end

    this.newPosition = this.active.position + util.vector3(0, 0, this.height - prevHeight)
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
	this.orientation = transformToAngles(this.active.rotation)
    this.lastItemOri = this.orientation

    if (not this.wallMount and not this.rotateMode) then
        -- Match vertical mode to get correct object height after arbitrary rotations.
        matchVerticalMode(this.orientation, this.boundMin, this.boundMax)

        -- Drop to ground.
        --#this.active.sceneNode.appCulled = true
        local from = this.active.position + util.vector3(0, 0, -this.height + const_epsilon)
		local to = from + util.vector3(0, 0, -4096)
        local ray = nearby.castRenderingRay(from, to)
        --#this.active.sceneNode.appCulled = false

        if (ray.hit) then
            if (this.verticalMode == 0 and this.groundAlign and not this.freezeAlign) then
                this.orientation = orientModule.orientRef(this.active, this.orientation, ray)
            end

			-- Buffer data because `this` will be reset in endPlacement().
			local data = {
				active = this.active,
				newPosition = ray.hitPos + util.vector3(0, 0, this.height + const_epsilon),
				newRotation = transformFromAngles(this.orientation)
			}
			--showAngles("drop before", this.orientation)
			--showAngles("drop after", transformToAngles(data.newRotation))
	
			-- Send a different event to avoid multiple item teleports in the same frame.
			core.sendGlobalEvent("PerfectPlacement:Drop", data)
        end
    end
    
	core.sound.playSound3d(itemSound.getDropSound(this.active), this.active)
    endPlacement()
end

-- onInputAction event while holding an item.
local function onInputAction(id)
    -- Prevent player from activating anything.
	if this.active and id == input.ACTION.Activate then
		--Doesn't work.
		--#return false
	end
end

-- Copy orientation event handler.
local function copyLastOri()
    if (this.matchTimer and this.lastItemOri) then
        this.orientation = mutableVec3(this.lastItemOri)
        this.freezeAlign = true
        matchVerticalMode(this.orientation, this.boundMin, this.boundMax)
    end
end

-- On grabbing / dropping an item.
local function activatePlacement(e)
    local targetRay = castActivationRay()
	local target = targetRay.hitObject

    -- Do not operate in menu mode and during attacking/casting (no OpenMW anim support yet).
    if core.isWorldPaused() then
        return
    end
    
    if (this.active) then
        -- Drop item.
        finalPlacement()
    elseif (target) then
        -- Filter by allowed object type.
        if (not placeableTypes[target.type]) then
            return
        end
        -- Ownership test.
        if (target.ownerRecordId or target.ownerFactionId) then
            if (target.ownerFactionId and types.NPC.getFactionRank(player, target.ownerFactionId) >= target.ownerFactionRank and not types.NPC.isExpelled(player, target.ownerFactionId)) then
                -- Player has sufficient faction rank.
            else
                ui.showMessage(l10n("OwnedItem"))
                return
            end
        end

        -- Put those hands away.
		--[[
        if (tes3.mobilePlayer.weaponReady) then
            tes3.mobilePlayer.weaponReady = false
        elseif (tes3.mobilePlayer.castReady) then
            tes3.mobilePlayer.castReady = false
        end
		]]--

        -- Calculate effective bounds including scale.
		local orientation = transformToAngles(target.rotation)
		--showAngles("activatePlacement", orientation)
		local bbox = target:getBoundingBox()
        this.boundMin = bbox.center - bbox.halfSize
        this.boundMax = bbox.center + bbox.halfSize
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
            local wallRay = nearby.castRay(from, to, {ignore = target})

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

        this.active = target
		core.sound.playSound3d(itemSound.getPickupSound(this.active), this.active)
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
	if not this.active then return end
	
    -- Stop if player takes the object.
    if (not this.active.cell) then
        endPlacement()
        return
    -- Check for cell change.
    elseif (not this.active.cell:isInSameSpace(player)) then
        ui.showMessage(l10n("CannotMoveBetweenCells"))
        endPlacementWithReset()
        return
    -- Drop item if player readies combat or casts a spell.
    elseif (types.Player.stance(player) ~= types.Player.STANCE.Nothing) then
        finalPlacement()
        return
    end

    -- Cast ray along initial pickup direction rotated by the 1st person camera.
    --#this.active.sceneNode.appCulled = true
    local eye = camera.getPosition()
    local rayDir = camera.getViewTransform():inverse() * this.rayDir - eye
    local ray = nearby.castRay(eye, eye + rayDir:normalize() * 800, {ignore = this.active})
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

    -- Item orientation handling.
    this.wallMount = false
    if (this.verticalMode == 0) then
        if (not this.freezeAlign) then
            -- Ground mode. Check if item is directly touching something.
            if (ray.hit and hitT <= this.maxReach and this.groundAlign) then
                -- Orient item to match placement.
                this.orientation = orientModule.orientRef(this.active, this.orientation, ray)
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
        ray = nearby.castRay(from, from + rayDir * 2, {ignore = this.active})
		hitDistance = ray.hit and (ray.hitPos - from):length()
        
        if (ray.hit and hitDistance < 1) then
            -- Place at minimum distance outside wall, and optionally align rotation with normal.
            pos = ray.hitPos - rayDir
            if (this.wallAlign and math.abs(ray.hitNormal.z) < 0.2) then
                this.orientation.y = math.atan2(-ray.hitNormal.x, -ray.hitNormal.y)
            end
            this.wallMount = true
        end
    end

    -- Find drop position for shadow spot.
	--[[
    local dropPos = pos
    ray = nearby.castRenderingRay(pos, pos + util.vector3(0, 0, -2048))
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
        local quantizer = (0.5 / config.options.snapN) * math.pi
        if (this.verticalMode == 0 or this.wallMount) then
            orient.z = quantizer * math.floor(0.5 + orient.z / quantizer)
        else
            orient.y = quantizer * math.floor(0.5 + orient.y / quantizer)
        end
    end

    -- Update item.
    --#this.active.sceneNode.appCulled = false
	this.newPosition = pos
	this.newRotation = transformFromAngles(orient)
	core.sendGlobalEvent("PerfectPlacement:Move", this)
end

-- Clean up placement.
endPlacement = function()
    if (this.matchTimer) then
        this.matchTimer = nil
    end
    
	core.sendGlobalEvent("PerfectPlacement:End", this)
    --#tes3ui.suppressTooltip(false)
    
    -- this.snapMode is persistent
    -- this.groundAlign is persistent
    -- this.wallAlign is persistent
    this.active = nil
    this.rotateMode = nil
    this.verticalMode = 0
    
	gui.hideGuide()
end

endPlacementWithReset = function ()
	-- Buffer data because `this` will be reset in endPlacement().
	local data = {
		active = this.active,
		newPosition = this.itemInitialPos,
		newRotation = this.itemInitialRot
	}
	-- Send a different event to avoid multiple item teleports in the same frame.
	core.sendGlobalEvent("PerfectPlacement:Drop", data)

	endPlacement()
end

-- End placement on load game. this.active would be invalid after load.
local function onLoad(e)
    if (this.active) then
        endPlacement()
    end
end

local function modeKeyDown(e)
   if (e.code == config.keybinds.keybind) then
        activatePlacement(e)
    elseif (this.active) then
        if (e.code == config.keybinds.keybindRotate) then
            this.rotateMode = true
        elseif (e.code == config.keybinds.keybindSnap) then
            this.snapMode = not this.snapMode
        elseif (e.code == config.keybinds.keybindVertical) then
            async:newUnsavableSimulationTimer(this.holdKeyTime, copyLastOri)
			this.matchTimer = true

            if (this.verticalMode == 0) then
                this.verticalMode = 1
                setVerticalMode(this.verticalMode)
            else
				this.orientation.x = 0
				this.orientation.y = 0
                this.orientation.z = transformToAngles(player.rotation).z
                this.height = -this.boundMin.z
                this.verticalMode = 0
            end
        elseif (e.code == config.keybinds.keybindWallAlign) then
            if (this.verticalMode == 0) then
                this.groundAlign = not this.groundAlign
            else
                this.wallAlign = not this.wallAlign
            end
        end
    end
end

local function modeKeyUp(e)
    if (this.active) then
        if (e.code == config.keybinds.keybindVertical) then
            this.matchTimer = nil
        elseif (e.code == config.keybinds.keybindRotate) then
            this.rotateMode = false
        end
    end
end



return {
    engineHandlers = {
        onKeyPress = modeKeyDown,
		onKeyRelease = modeKeyUp,
		onLoad = onLoad,
		onInputAction = onInputAction,
		onFrame = onFrame,
    }
}