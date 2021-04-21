local function Activate(e)
	if (e.activator ~= tes3.player) then
		return
	end

	if (e.target.baseObject.objectType ~= tes3.objectType.door) then
		if (e.target.baseObject.objectType ~= tes3.objectType.container) then
			return
		end
	end

	if (e.target.lockNode ~= nil) and (e.target.lockNode.locked == true) then
		return
	end

	if (tes3.mobilePlayer.isSneaking == false) then
		return
	end

	if (tes3.player.object.inventory:contains("skeleton_key") == true) then
		local Level = tes3.getLockLevel({ reference = e.target }) or 10
		tes3.lock({ reference = e.target, level = Level })

		tes3.messageBox("You locked the object with The Skeleton Key")

		if (e.target.baseObject.objectType == tes3.objectType.door) then
			tes3.playSound({ sound = "LockedDoor" })
		elseif (e.target.baseObject.objectType == tes3.objectType.container) then
			tes3.playSound({ sound = "LockedChest" })
		end

		return false
	end

	if (e.target.lockNode == nil) then
		return
	end

	if (e.target.lockNode.key == nil) then
		return
	end

	if (tes3.player.object.inventory:contains(e.target.lockNode.key.id) == false) then
		return
	end

	tes3.lock({ reference = e.target })
	tes3.messageBox(("You locked the object with %s"):format(e.target.lockNode.key.name))

	if (e.target.baseObject.objectType == tes3.objectType.door) then
		tes3.playSound({ sound = "LockedDoor" })
	elseif (e.target.baseObject.objectType == tes3.objectType.container) then
		tes3.playSound({ sound = "LockedChest" })
	end

	return false
end

local function Init(e)
	event.register("activate", Activate)
	mwse.log("[LLLOHD] Initialized.")
end
event.register("initialized", Init)