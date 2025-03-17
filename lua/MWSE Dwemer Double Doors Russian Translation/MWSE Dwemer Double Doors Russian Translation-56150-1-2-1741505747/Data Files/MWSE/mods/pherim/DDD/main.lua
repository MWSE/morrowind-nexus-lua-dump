local configPath = "Dwemer Double Doors"

-- The config table
local config = mwse.loadConfig(configPath, {
	bPlaceFlippedDoors = true,
	bSyncOpen = true,
	swapDoorsKey = {keyCode = tes3.scanCode.p},
	bDebug = false,	
})

local activatedDoor -- the activated door
local nearestDoor -- the nearest door, this will be the opposite half

local function IsInRange(num, median, margin)
	if num > median - margin and num < median + margin then
		return true
	else
		return false
	end
end

local function CompareAngle(angle1, angle2, difference, margin) -- angle1, 2 in radians; difference, margin in degrees
	angle1, angle2 = math.deg(angle1) % 360, math.deg(angle2) % 360
	local angleDiff = math.abs(angle1 - angle2) - (difference % 360)
	
	return math.abs(angleDiff) < margin or 360 - math.abs(angleDiff) < margin
end

local function FindNearestDoor(door)
	
	local otherDoor
		
	-- look for the nearest door, this will be the other half
	for ref in door.cell:iterateReferences(tes3.objectType.door) do
		if ref ~= door and ref.disabled == false and ref.object.script == nil -- check if it is not the door itself, not disabled and has no script
		and (IsInRange(door.position:distanceXY(ref.position),  224, 4) -- check if it is approximately 224 units from door
		or IsInRange(door.position:distanceXY(ref.position),  0, 4)) -- or if it is in the same place (for DN GDI)
		and IsInRange(door.position.z, ref.position.z, 8) -- and if they are at the same height
		and (ref.object.mesh == "d\\door_dwrv_inner00.nif" or ref.object.mesh == "d\\door_dwrv_inner00_flipped.nif" or ref.object.id == "door_dwrv_inner00_dn")
		then
			otherDoor = ref
			break
		end
	end
	
	return otherDoor
end

local function TransferLockNode(door, otherDoor)
	if door.lockNode ~= nil then
		tes3.lock({reference = otherDoor, level = door.lockNode.level})
		otherDoor.lockNode.locked = door.lockNode.locked
		
		if door.lockNode.key ~= nil then
			otherDoor.lockNode.key = door.lockNode.key
		end
		
		if door.lockNode.trap ~= nil then
			otherDoor.lockNode.trap = door.lockNode.trap
		end
	end
end

local function ReplaceOtherDoor(door)
	local _orientation = tes3vector3.new(door.startingOrientation.x, door.startingOrientation.y, door.startingOrientation.z) -- get the startingOrientation of the door that should be replaced in case the original door is currently open (will be replaced with a closed door)
	_orientation.x = _orientation.x + math.pi
	_orientation.z = math.pi - _orientation.z
	local newRef = tes3.createReference({
		object = "door_dwrv_inner00_flipped",
		position = tes3vector3.new(door.startingPosition.x, door.startingPosition.y, door.startingPosition.z) ,
		orientation = _orientation,
		cell = door.cell,
		scale = door.scale
	})
	
	TransferLockNode(door, newRef)
	
	newRef:enable()
	door:disable()
end

-- Deletes all flipped doors and restores the original ones -- TO DO: Transfer lock/trap status
local function RestoreDoors(e)
	-- This corresponds to the first button
    --  of our message, which is "Yes"
    if e.button == 0 then	
		local doorsInCell = 0
		local doorsRestored = 0
		local cellsRestored = 0
		
		mwse.log("Restoring Doors...")
		
		for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
			for ref in cell:iterateReferences(tes3.objectType.door) do
				if ref.object.id == "door_dwrv_inner00_flipped" then
					for oRef in cell:iterateReferences(tes3.objectType.door) do
						if oRef.object.mesh == "d\\door_dwrv_inner00.nif" and oRef.disabled == true and ref.position:distance(oRef.position) < 1 then
						
							TransferLockNode(ref, oRef)
							
							oRef:enable()
							
							ref:delete()

							doorsInCell = doorsInCell + 1
							doorsRestored = doorsRestored + 1
							
							break
						end
					end
				end
			end
			
			if doorsInCell > 0 then
				mwse.log(doorsInCell .. " doors restored in " .. cell.id)
				doorsInCell = 0
				cellsRestored = cellsRestored + 1
			end
		end
		
		if doorsRestored > 0 then
			mwse.log(doorsRestored .. " total doors restored in " .. cellsRestored .. " cells.")
			tes3.messageBox({
				message = " В локации " .. cellsRestored .. " заменено " .. doorsRestored .. "дверей.",
				buttons = { "Закрыть" },
				showInDialog = false,
			})
		else
			mwse.log("No doors need to be restored.")
			tes3.messageBox({
				message = "Замена дверей не требуется",
				buttons = { "Закрыть" },
				showInDialog = false,
			})
		end
	end
end

local function ReplaceDoors(cell)
	-- skip if "Place flipped doors" is disabled in MCM
	if config.bPlaceFlippedDoors == false then
		return
	end
	
	for ref in cell:iterateReferences(tes3.objectType.door) do
		if ref.object.script == nil and ref.disabled == false
		 -- make sure the door is not tilted -- Does not work if not aligned with x and y axis
		and (CompareAngle(ref.orientation.x, 0, 0, 1) or CompareAngle(ref.orientation.x, math.pi, 0, 1))
		and (CompareAngle(ref.orientation.y, 0, 0, 1) or CompareAngle(ref.orientation.y, math.pi, 0, 1))
		then
			if ref.object.mesh == "d\\door_dwrv_inner00.nif" then
				nearestDoor = FindNearestDoor(ref)
				if nearestDoor ~= nil and nearestDoor.object.mesh == "d\\door_dwrv_inner00.nif" then -- only replace doors that are not already flipped
					ReplaceOtherDoor(nearestDoor)
				end
			end
		end
	end
end

local function DwemerDoorActivated(e)
	if config.bSyncOpen == true
	and activatedDoor == nil -- if this is nil, this was activated by the player and the other door can also be activated, else we can skip it to not activate is again
	and e.target.object.objectType == tes3.objectType.door and e.target.object.script == nil -- check if the activated object is a door and has no script and if it was activated by the player
	and ( e.target.lockNode == nil or ( e.target.lockNode.locked == false and not e.target.lockNode.trap )) -- check if  is is locked or trapped
	and (e.target.object.mesh == "d\\door_dwrv_inner00.nif" or e.target.object.id == "door_dwrv_inner00_flipped" or e.target.object.id == "door_dwrv_inner00_dn") -- check if it is a dwemer door
	then		
		activatedDoor = e.target
		
		nearestDoor = FindNearestDoor(e.target)
		
		if nearestDoor ~= nil and activatedDoor ~= nil then
			if config.bPlaceFlippedDoors == true then
				local doorAngles = activatedDoor.facing + nearestDoor.facing
				
				local openAmount = activatedDoor.facing - activatedDoor.startingOrientation.z -- calculate how far open the door is in degrees from 0 - pi/2				
				
				if ( CompareAngle( doorAngles, 2 * openAmount, 0, 2) ) -- only activate if they are both open or closed the same amount			
				then
					tes3.player:activate(nearestDoor) -- activate nearest Door
				end
			else
				local doorAngles = (activatedDoor.facing - activatedDoor.startingOrientation.z) - (nearestDoor.facing - nearestDoor.startingOrientation.z)
				if CompareAngle(doorAngles, 0, 0, 2) then
					tes3.player:activate(nearestDoor) -- activate nearest Door
				end
			end
		end
	elseif activatedDoor ~= nil then -- if not nil, this was activated by this script and we we don't want to activate the other door again - maybe this can be done better with Action Flag OnActivate
		activatedDoor = nil -- set it nil again after the other door was activated
	end	
end

-- Changes the opening direction of doors by pressing a key
local function SwapDoors(e)
	if config.bPlaceFlippedDoors == false or tes3.getPlayerTarget() == nil then
		return
	end
	
	local target = tes3.getPlayerTarget()
	local swapped = false
	if target.object.mesh == "d\\door_dwrv_inner00.nif" then
		nearestDoor = FindNearestDoor(target)
		if nearestDoor.object.id == "door_dwrv_inner00_flipped" then
			for ref in nearestDoor.cell:iterateReferences(tes3.objectType.door) do	
				if ref ~= nearestDoor and ref.disabled and ref.position:distance(nearestDoor.position) < 1 then
					ref:enable()
					TransferLockNode(nearestDoor, ref)
					nearestDoor:delete()
					ReplaceOtherDoor(target)
					swapped = true
					break
				end
			end
		else			
			if config.bDebug then
				mwse.log("None of the doors is flipped, cannot swap them.")
			end
			tes3.messageBox("Перевернутая дверь не обнаружена, замена невозможна.")
			return
		end
	elseif target.object.id == "door_dwrv_inner00_flipped" then
		nearestDoor = FindNearestDoor(target)
		if nearestDoor.object.mesh == "d\\door_dwrv_inner00.nif" then
			ReplaceOtherDoor(nearestDoor)
			for ref in target.cell:iterateReferences(tes3.objectType.door) do
				if ref ~= target and ref.disabled and ref.position:distance(target.position) < 1 then
					ref:enable()
					TransferLockNode(target, ref)
					target:delete()
					swapped = true
					break
				end
			end
		end
	end
	
	if swapped then
		tes3.messageBox("Направление открытия дверей изменено!")
		if config.bDebug then
			mwse.log("Doors successfully swapped!")
		end
	else -- this should never happen
		tes3.messageBox("Что-то пошло не так. Развернуть двери не удалось.")
		if config.bDebug then
			mwse.log("Something went wrong. Could not swap doors.")
		end
	end
end

local function OnCellChanged(e)
	ReplaceDoors(e.cell)
end

local function OnChangePlaceDoors(bPlaceFlippedDoors)
	if tes3.player ~= nil then -- only show if a game was loaded		
		if bPlaceFlippedDoors == false then
			tes3.messageBox({
				message = "Восстановить ранее установленные двери?",
				buttons = { "Да", "Нет" },
				showInDialog = false,
				callback = RestoreDoors,
			})
		else
			ReplaceDoors(tes3.player.cell)
		end
	else
		if bPlaceFlippedDoors == false then
			tes3.messageBox({
				message = "Чтобы восстановить уже замененные двери, загрузите игру и снова включите\\отключите эту функцию.",
				buttons = { "Закрыть" },
				showInDialog = false,
			})
		end
	end
end

-- DEBUG
local function ShowZRotation(e) -- Shows the rotation of the door the player is looking at
	if config.bDebug == true and e.current ~= nil
	and (e.current.object.mesh == "d\\door_dwrv_inner00.nif" or e.current.object.mesh == "d\\door_dwrv_inner00_flipped.nif") then
		tes3.messageBox("X: " .. math.deg(e.current.orientation.x) .. " Y: " .. math.deg(e.current.orientation.y) .. " Z: " .. math.deg(e.current.orientation.z))
	end
end

local function initialized()
	print("Initialized Dwemer Double Doors")
end

event.register("initialized", initialized)

event.register("keyDown", SwapDoors, { filter = config.swapDoorsKey.keyCode })
event.register(tes3.event.activate, DwemerDoorActivated)
event.register(tes3.event.cellChanged, OnCellChanged)

local function registerModConfig()
    -- Create the top level component Template
    -- The name will be displayed in the mod list on the lefthand pane
    local template = mwse.mcm.createTemplate({ name = "Двемерские двойные двери" })
	
	template.onClose = function (modConfigContainer)
        -- Save config options when the mod config menu is closed
        -- NOTE: you cant use `saveOnClose` with `onClose`, which is why 
        -- i'm putting `saveConfig` here
        mwse.saveConfig(configPath, config)
    end
	
	-- Create a simple container Page under Template
    local settings = template:createSideBarPage({ label = "Настройки" })
	
	settings:createOnOffButton({
		label = "Установить перевернутые двери",
		description = "Динамически заменяет одну из каждой пары дверей на перевернутый вариант. Если отключить эту функцию, все ранее замененные двери будут возвращены в исходное состояние.",
		variable = mwse.mcm.createTableVariable{ id = "bPlaceFlippedDoors", table = config },
		callback = function(self)
				OnChangePlaceDoors(self.variable.value)
			end,
	})
	
	settings:createYesNoButton({
        label = "Одновременное открытие дверей",
		description = "При активации двемерской двери, парная дверь открывается автоматически. Работает как с включенной опцией \"Установить перевернутые двери\", так и без нее.",
        variable = mwse.mcm:createTableVariable({ id = "bSyncOpen", table = config }),
    })	
	
	settings:createKeyBinder({
    label = "Клавиша разворота дверей",
    description = "Нажмите при взгляде на двемерскую дверь, чтобы изменить направление, в котором она открывается. Работает, только если включена опция \"Установить перевернутые двери\"",
    variable = mwse.mcm.createTableVariable{ id = "swapDoorsKey", table = config },
    allowCombinations = true,
	})
	
	settings:createYesNoButton({
        label = "Отладка",
		description = "Если включить эту функцию, при взгляде на двемерскую дверь будет отображаться ее ориентация в пространстве.",
        variable = mwse.mcm:createTableVariable{ id = "bDebug", table = config },
		callback = function(self)
			if self.variable.value == true then
				if event.isRegistered(tes3.event.activationTargetChanged, ShowZRotation) == false then
					event.register(tes3.event.activationTargetChanged, ShowZRotation)
				end
			else
				event.unregister(tes3.event.activationTargetChanged, ShowZRotation)
			end
		end,
    })	
	
	 -- Finish up.
    template:register()
end

if config.bDebug then
	event.register(tes3.event.activationTargetChanged, ShowZRotation)
end

event.register(tes3.event.modConfigReady, registerModConfig)
