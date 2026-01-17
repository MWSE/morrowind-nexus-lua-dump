local clicks = 0
local constants = require("zhac.DualPortalSpell.constants")

local function getBluePortal()
	if not tes3.player.data.portals then
		tes3.player.data.portals = {}
	end
	if not tes3.player.data.portals[constants.defaultSet] then
		tes3.player.data.portals[constants.defaultSet] = {}
	end
	return tes3.getReference(tes3.player.data.portals[constants.defaultSet].portal2Obj)
end

local function getBlueRecord()
	if 1 == 2 then
		local newDoor = tes3.createObject{
			objectType = tes3.objectType["door"],
			name = "Portal",
			mesh = [[portal_fire_blue.nif]]
		}
		if not tes3.player.data.createdRecs then
			tes3.player.data.createdRecs = {}
		end
		tes3.player.data.createdRecs[newDoor.id] = true
		return newDoor
	end

	return tes3.getObject("zhac_portal_doorobj_blue2")
end

local function getOrangeRecord()
	if 1 == 2 then
		local newDoor = tes3.createObject{
			objectType = tes3.objectType["door"],
			name = "Portal",
			mesh = [[oaab/e/portal_fire.nif]],
		}
		if not tes3.player.data.createdRecs then
			tes3.player.data.createdRecs = {}
		end
		tes3.player.data.createdRecs[newDoor.id] = true
		return newDoor
	end
	return tes3.getObject("zhac_portal_doorobj")
end

local function getOrangePortal()
	if not tes3.player.data.portals then
		tes3.player.data.portals = {}
	end
	if not tes3.player.data.portals[constants.defaultSet] then
		tes3.player.data.portals[constants.defaultSet] = {}
	end
	return tes3.getReference(tes3.player.data.portals[constants.defaultSet].portal1Obj)
end

local function getPositionBehind(pos, rot, distance, direction)
	local currentRotation = -rot
	local angleOffset = 0

	if direction == "north" then
		angleOffset = math.rad(90)
	elseif direction == "south" then
		angleOffset = math.rad(-90)
	elseif direction == "east" then
		angleOffset = 0
	elseif direction == "west" then
		angleOffset = math.rad(180)
	else
		error("Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
	end

	currentRotation = currentRotation - angleOffset
	local obj_x_offset = distance * math.cos(currentRotation)
	local obj_y_offset = distance * math.sin(currentRotation)
	local obj_x_position = pos.x + obj_x_offset
	local obj_y_position = pos.y + obj_y_offset
	return tes3vector3.new(obj_x_position, obj_y_position, pos.z)
end

local newPortal
local function scaleUp()
	newPortal.scale = newPortal.scale + constants.scaleMultiplier
	if newPortal.scale < constants.baseScale then
		timer.start{ duration = constants.scaleDelay, callback = scaleUp }
	end
end

local oldPortal1
local function scaleDown1()
	oldPortal1.scale = oldPortal1.scale - constants.scaleMultiplier
	if oldPortal1.scale > 0.1 then
		timer.start{ duration = constants.scaleDelay, callback = scaleDown1 }
	else
		oldPortal1:delete()
	end
end

local oldPortal2
local function scaleDown2()
	oldPortal2.scale = oldPortal2.scale - constants.scaleMultiplier
	if oldPortal2.scale > 0.1 then
		timer.start{ duration = constants.scaleDelay, callback = scaleDown2 }
	else
		oldPortal2:delete()
	end
end

local function getExteriorPos()
	if not tes3.player.cell.isInterior then
		return tes3.player.position
	end
	for ref in tes3.player.cell:iterateReferences(tes3.objectType["door"]) do
		if ref.destination then
			if not ref.destination.cell.isInterior then
				return ref.destination.marker.position
			else
				for subRef in ref.cell:iterateReferences(tes3.objectType["door"]) do
					if subRef.destination and not subRef.destination.cell.isInterior then
						return subRef.destination.marker.position
					end
				end
			end
		end
	end
	return nil
end

local function destroyPortal(isBlue)
	local oldObj = getOrangePortal()
	if isBlue then
		oldObj = getBluePortal()
	end
	if oldObj then
		if oldObj.cell == tes3.player.cell then
			if isBlue then
				oldPortal1 = oldObj
				scaleDown1()
			else
				oldPortal2 = oldObj
				scaleDown2()
			end
		else
			oldObj:delete()
		end
		if isBlue then
			tes3.player.data.portals[constants.defaultSet].portal2Obj = nil
		else
			tes3.player.data.portals[constants.defaultSet].portal1Obj = nil
		end
	end
end

local function createPortal(isBlue)
	local newPos = getPositionBehind(tes3.player.position, tes3.player.orientation.z, constants.placeDistance, "south")
	newPos.z = newPos.z + ((constants.heightOffset / 2) * constants.baseScale)
	local newObjectId = getOrangeRecord().id
	if isBlue then
		newObjectId = getBlueRecord().id
	end
	local newOrinetation = tes3vector3.new(0, 0, tes3.player.orientation.z - math.rad(180))
	local extPos = getExteriorPos()

	local cost = 0
	local dist = 0
	if extPos then
		if isBlue and getOrangePortal() then
			if tes3.player.data.portals[constants.defaultSet].portal1ExtPos then
				dist = extPos:distance(tes3.player.data.portals[constants.defaultSet].portal1ExtPos)
			end
		elseif not isBlue and getBluePortal() then
			if tes3.player.data.portals[constants.defaultSet].portal2ExtPos then
				dist = extPos:distance(tes3.player.data.portals[constants.defaultSet].portal2ExtPos)
			end
		end
		cost = dist / constants.magicDivider
	else
		cost = 100
	end
	if tes3.player.mobile.magicka.current < cost then
		tes3.messageBox(constants.notEnoughMagicMessage)
		return
	else
		tes3.modStatistic{
			reference = tes3.mobilePlayer,
			name = "magicka",
			current = -cost,
		}
	end
	newPortal = tes3.createReference{
		scale = 0.01,
		cell = tes3.player.cell,
		object = newObjectId,
		position = newPos,
		orientation = newOrinetation,
	}
    newPortal.persistent = true
	tes3.playSound{ sound = constants.openPortalSound }
	local exitPosition = getPositionBehind(newPos, newOrinetation.z, constants.exitDistance, "south")
	timer.start{ duration = constants.scaleDelay, callback = scaleUp }

	destroyPortal(isBlue)
	if isBlue then
		tes3.player.data.portals[constants.defaultSet].portal2Obj = newPortal.id
		tes3.player.data.portals[constants.defaultSet].portal2Exit = exitPosition
		tes3.player.data.portals[constants.defaultSet].portal2ExtPos = extPos
	else
		tes3.player.data.portals[constants.defaultSet].portal1Obj = newPortal.id
		tes3.player.data.portals[constants.defaultSet].portal1Exit = exitPosition
		tes3.player.data.portals[constants.defaultSet].portal1ExtPos = extPos
	end
	if getOrangePortal() and getBluePortal() then
		local portal1Obj = getOrangePortal()
		local portal2Obj = getBluePortal()
		tes3.setDestination{
			reference = portal1Obj,
			position = tes3.player.data.portals[constants.defaultSet].portal2Exit,
			orientation = portal2Obj.orientation,
			cell = portal2Obj.cell,
		}
		tes3.setDestination{
			reference = portal2Obj,
			position = tes3.player.data.portals[constants.defaultSet].portal1Exit,
			orientation = portal1Obj.orientation,
			cell = portal1Obj.cell,
		}
	end
end

local function spellCastedCallback(e)
	if e.source.id == "zhac_portal_alpha" then
		if clicks == 0 then
			createPortal(false)
		elseif clicks == 1 then
			createPortal(true)
		elseif clicks > 1 then
			destroyPortal(true)
			destroyPortal(false)
			tes3.playSound{ sound = constants.closePortalSound }
		end
	end
end
event.register(tes3.event.spellCasted, spellCastedCallback)

local function activateCallback(e)
	if e.target.baseObject.id == "zhac_portal_doorobj" or e.target.baseObject.id == "zhac_portal_doorobj_blue2" then
		if getOrangePortal() and getBluePortal() then
			tes3.playSound{ sound = constants.openPortalSound }
		else
			return false
		end
	end
end
event.register(tes3.event.activate, activateCallback)

local function mouseButtonDownCallback(e)
	if e.button == 0 then
		if tes3.player and tes3.player.mobile.isAttackingOrCasting then
			clicks = clicks + 1
		else
			clicks = 0
		end
	end
end
event.register(tes3.event.mouseButtonDown, mouseButtonDownCallback)

local function portalScript(params)
	local distance = params.reference.position:distance(tes3.player.position)
	if distance < 120 then
		tes3.player:activate(params.reference)
	end
end

event.register(tes3.event.initialized, function()
	mwse.overrideScript("zhac_portalscr", portalScript)
end)