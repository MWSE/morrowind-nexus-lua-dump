local objectCreator = {}

local common = require("Virnetch.enchantmentServicesRedone.common")

--[[
	Create an object that will be deleted when no longer used.

	Notes:
	 - Temporary enchantments can only be added to books that are also temporary.
]]
function objectCreator.createTemporaryObject(params)
	if not common.savedData or params.sourceless then
		common.log:error("Game not loaded yet or attemted to create a sourceless temporaryObject: %s", params.id)
		return
	end

	if not common.savedData.temporaryObjects[tostring(params.objectType)] then
		common.log:error("Attempted to createTemporaryObject with unmanaged objectType: %s",
			( table.find(tes3.objectType, params.objectType) or tostring(params.objectType) )
		)
		return
	end

	-- Wrye Mash Repair All will delete books not found in master plugins if id doesn't match the one created randomly when enchanting
	-- https://github.com/polemion/Wrye-Mash-Polemos/blob/master/Mopy/mash/mosh.py#L6624
	if params.objectType == tes3.objectType.book and params.id and not string.find(params.id, "^%d%d%d%d%d%d%d%d%d%d+$") then
		common.log:error("Attempted to createTemporaryObject book with unique id %s. Wrye Mash Repair All would delete this from the save file!", params.id)
		return
	end

	local object = tes3.createObject(params)
	table.insert(common.savedData.temporaryObjects[tostring(params.objectType)], object.id:lower())

	common.log:debug("Created temporaryObject: %s", object.id)
	return object
end

--- Deletes all temporaryObjects that are no longer used.
--- This should be called from a `save` event with the filename of the savefile
--- @param saveFilename string Filename of the save that triggered the deletion
local function deleteUnusedObjects(saveFilename)
	if not saveFilename then return end

	-- The objects to be deleted from save file
	local deletions = {}

	-- Add all created enchantments
	local temporaryEnchantments = common.savedData.temporaryObjects[tostring(tes3.objectType.enchantment)]
	for i=#temporaryEnchantments, 1, -1 do
		local id = temporaryEnchantments[i]
		local obj = tes3.getObject(id)
		if not obj then
			common.log:warn("Could not find temporaryEnchantment object %s, removing id from savedData", id)
			table.remove(temporaryEnchantments, i)
		else
			deletions[obj] = true
		end
	end

	-- Filter out enchantments that are used on books,
	-- add books without references or deciphered spells
	local temporaryBooks = common.savedData.temporaryObjects[tostring(tes3.objectType.book)]
	for i=#temporaryBooks, 1, -1 do
		local id = temporaryBooks[i]
		local obj = tes3.getObject(id)
		if not obj then
			common.log:warn("Could not find temporaryBook object %s, removing id from savedData", id)
			table.remove(temporaryBooks, i)
		else
			if obj.enchantment and deletions[obj.enchantment] then
				common.log:debug("ENCH %s still used by %s, not deleting.", obj.enchantment, obj)
				deletions[obj.enchantment] = nil
			end

			if common.savedData.decipheredScrolls[id:lower()] then
				common.log:debug("%s has been deciphered to spell %s, not deleting.", obj, common.savedData.decipheredScrolls[id:lower()])
			else
				local ref = tes3.getReference(obj.id)
				if ref == nil then
					deletions[obj] = true
				else
					common.log:debug("A reference of %s exists in cell %s, not deleting.", obj, ref.cell)
				end
			end
		end
	end
	if not next(deletions) then return end

	-- Filter out currently active projectiles' sources
	for _, projectile in pairs(tes3.worldController.mobController.projectileController.projectiles) do
		if projectile.spellInstance then
			local projectileSource = projectile.spellInstance.source
			if projectileSource then
				common.log:debug("%s has an active projectile, not deleting.", projectileSource)
				deletions[projectileSource] = nil
			end

			local projectileItem = projectile.spellInstance.item
			if projectileItem then
				common.log:debug("%s's enchantment has an active projectile, not deleting.", projectileItem)
				deletions[projectileItem] = nil
			end
		end
	end
	if not next(deletions) then return end

	-- Filter out objects stored in inventories, and
	-- enchantments that have an active effect on someone
	for owner in tes3.iterateObjects({
			tes3.objectType.container,
			tes3.objectType.creature,
			tes3.objectType.npc
		}) do
		-- Need to check baseObjects too. Player's baseObject will still have some items that are not on the PlayerSaveGame object
		-- TODO Might be enough to do if owner.isInstance or owner == tes3.player.baseObject then
		-- if owner.isInstance then
			for obj in pairs(deletions) do
				-- Don't delete items stored in inventories
				if #owner.inventory ~= 0 and owner.inventory:contains(obj) then
					common.log:debug("%s owns a copy of %s, not deleting.", owner, obj)
					deletions[obj] = nil
				end

				-- Don't delete active enchantments or the items using them
				if owner.mobile and owner.mobile.activeMagicEffectList then
					for _, activeMagicEffect in pairs(owner.mobile.activeMagicEffectList) do
						if activeMagicEffect.instance then
							local effectSource = activeMagicEffect.instance.source
							if effectSource and deletions[effectSource] then
								common.log:debug("%s has an activeMagicEffect on %s, not deleting.", effectSource, owner)
								deletions[effectSource] = nil
							end

							local effectItem = activeMagicEffect.instance.item
							if effectItem and deletions[effectItem] then
								common.log:debug("%s's enchantment has an activeMagicEffect on %s, not deleting.", effectItem, owner)
								deletions[effectItem] = nil
							end
						end
					end
				end
			end
		-- end
	end
	if not next(deletions) then return end

	-- Using tes3.deleteObject can be scary. Create a backup before saving.
	local deletionIds = {}
	for obj in pairs(deletions) do
		deletionIds[#deletionIds+1] = obj.id
	end
	common.log:debug("Deleting the following: %s", json.encode(deletionIds))

	-- Save the ids of objects that are about to be removed in the backup
	common.savedData.problematicDeletions = deletionIds

	-- Create the backup save
	event.register(tes3.event.save, function(e)
		-- Prevent other mods from blocking the save
		e.claim = true
		common.log:debug("Claimed esrBackup save event")
	end, { filter = "esrBackup", priority = 1000, doOnce = true })

	tes3.saveGame({ file = "esrBackup", name = "esrBackup" })

	-- These are only saved so they can be found in the backup save
	common.savedData.problematicDeletions = nil
	common.log:info("About to delete objects. Created a backup save 'esrBackup' in case the game crashes")

	-- Delete backup if the game doesn't crash and the original save is successfully created
	event.register(tes3.event.saved, function()
		common.log:info("Did not crash, deleting backup")
		if not os.remove("saves/esrBackup.ess") then
			common.log:warn("Failed to delete backup save")
		else
			common.log:debug("Backup deleted")
		end
	end, { filter = saveFilename, doOnce = true })

	-- Delete the objects
	for obj in pairs(deletions) do
		local removed = table.removevalue(common.savedData.temporaryObjects[tostring(obj.objectType)], obj.id:lower())
		if not removed then
			common.log:error(" Unable to remove %s from savedData, not deleting object", obj.id)
		else
			common.log:info(" Deleting object %s", obj.id)

			-- If the object is a transcription, remove it from the data
			if common.savedData.transcriptions[obj.id:lower()] then
				common.savedData.transcriptions[obj.id:lower()] = nil
			end

			assert(tes3.deleteObject(obj))
		end
	end
end

--- @param e saveEventData
local function onSave(e)
	if e.filename == "esrBackup" then return end
	if not common.config.transcription.requireScroll then
		common.log:debug("onSave, requiresScroll is disabled, returning")
		return
	end

	-- do cleaning only if 72 hours have passed
	local cleanupDay = common.savedData.temporaryObjects.cleanupDay or 0
	local daysPassed = tes3.worldController.daysPassed.value
	if (daysPassed - cleanupDay) < 3 then
		common.log:debug("onSave, not cleanupDay, returning")
		return
	end
	common.savedData.temporaryObjects.cleanupDay = daysPassed

	common.log:debug("onSave, deleting unused temporaryObjects")
	local before = os.clock()

	deleteUnusedObjects(e.filename)

	local timeTaken = os.clock() - before
	common.log:debug("onSave finished, time: %.3f", timeTaken)
end
event.register(tes3.event.save, onSave, { priority = -1000 })	-- low priority in case a mod blocks saving

local function onLoaded()
	-- These are only saved so they can be found in the backup save
	common.savedData.problematicDeletions = nil
end
event.register(tes3.event.loaded, onLoaded, { priority = -1 })

-- Show a message if the game crashed when last saving
if lfs.fileexists("saves/esrBackup.ess") then
	common.log:debug("Found backup save 'esrBackup', renaming and showing messageBox")
	-- Rename the file so the message isn't shown again
	os.remove("saves/esrBackup_.ess")
	os.rename("saves/esrBackup.ess", "saves/esrBackup_.ess")

	timer.delayOneFrame(function()
		timer.delayOneFrame(function()
			tes3.messageBox({
				message = common.i18n("experimental.transcription.requireScrollCrash"),
				buttons = { tes3.findGMST(tes3.gmst.sOK).value }
			})
		end, timer.real)
	end, timer.real)
end

return objectCreator