local bit = require("bit")

local BLANK_SLOT = 255

local ankleOverridesByBodyPart = {}
local ankleOverridesByObject = {}
local footParts = {}
local isBeastList = {}

local function onInitialized(e)
	if tes3.isModActive("Beast Boots.esp") then
		-- For boots with no ankle part, override the foot meshes with beast ankle meshes.
		ankleOverridesByBodyPart["a_boots_heavy_leather"] = tes3.getObject("a_boots_heavy_leather_beast")
		ankleOverridesByBodyPart["A_Ice_M_boots"] = tes3.getObject("A_Ice_M_boots_beast")
		ankleOverridesByBodyPart["A_Ice_F_boot"] = tes3.getObject("A_Ice_M_boots_beast")
		ankleOverridesByBodyPart["A_NordicMail_M_boots"] = tes3.getObject("A_NordicMail_M_boots_beast")
		ankleOverridesByBodyPart["A_NordicMail_F_boots"] = tes3.getObject("A_NordicMail_M_boots_beast")
		ankleOverridesByBodyPart["a_tenpaceboot"] = tes3.getObject("a_tenpaceboot_beast")
		
		-- Compatibility for Better Morrowind Armor.
		if tes3.isModActive("Better Morrowind Armor.esp") or tes3.isModActive("Better Morrowind Armor DeFemm(r).ESP") or tes3.isModActive("Better Morrowind Armor DeFemm(o).ESP") or tes3.isModActive("Better Morrowind Armor DeFemm(a).ESP") then
			ankleOverridesByBodyPart["bam_boots_heavy_leather_f"] = tes3.getObject("a_boots_heavy_leather_beast")
			ankleOverridesByBodyPart["bab_ice_boot_f"] = tes3.getObject("A_Ice_M_boots_beast")
			ankleOverridesByBodyPart["bab_nordicmail_boot_f"] = tes3.getObject("A_NordicMail_M_boots_beast")
			ankleOverridesByBodyPart["bam_tenpace_boot_f"] = tes3.getObject("a_tenpaceboot_beast")
		end
	else
		mwse.log("Beast Boots: Error - 'Beast Boots.esp' is not activated. Some boots will not be equippable by beasts.")
	end

	mwse.log("Beast Boots: v1.2 initialized.")
end
event.register("initialized", onInitialized)

local function isWearableBoot(object)
	if object.objectType == tes3.objectType.armor or object.objectType == tes3.objectType.clothing then
		local hasInvalid = false
		local hasOther = false
		-- Non-boot slot armor can use foot parts, so check every body part rather than checking that it is a boot.
		for _, wearablePart in pairs(object.parts) do
			if wearablePart.type == tes3.activeBodyPart.leftFoot or wearablePart.type == tes3.activeBodyPart.rightFoot then    -- Check for a body part in the foot slot.
				hasInvalid = true
				if (wearablePart.male and ankleOverridesByBodyPart[wearablePart.male.id]) or (wearablePart.female and ankleOverridesByBodyPart[wearablePart.female.id]) then
					hasOther = true
				end
			elseif (wearablePart.type ~= BLANK_SLOT and (wearablePart.male or wearablePart.female)) then    -- Check for another existing body part.
				hasOther = true
			end
			
			if hasInvalid and hasOther then     -- Allow equipping if the object has another existing body part.
				return true
			end
		end
	end
end

local function initialiseBoot(object)
	if isWearableBoot(object) then
		for _, wearablePart in ipairs(object.parts) do
			if wearablePart.type == tes3.activeBodyPart.leftFoot or wearablePart.type == tes3.activeBodyPart.rightFoot then

				-- Determine overridden ankle meshes by object ID.
				local newWearablePartMale = wearablePart.male and ankleOverridesByBodyPart[wearablePart.male.id]
				local newWearablePartFemale = wearablePart.female and ankleOverridesByBodyPart[wearablePart.female.id]
				if newWearablePartMale or newWearablePartFemale then
					local newWearablePartType
					if wearablePart.type == tes3.activeBodyPart.leftFoot then
						newWearablePartType = tes3.activeBodyPart.leftAnkle
					elseif wearablePart.type == tes3.activeBodyPart.rightFoot then
						newWearablePartType = tes3.activeBodyPart.rightAnkle
					end

					if ankleOverridesByObject[object.id] == nil then
						ankleOverridesByObject[object.id] = {}
					end
					ankleOverridesByObject[object.id][newWearablePartType] = {}

					if newWearablePartMale then
						ankleOverridesByObject[object.id][newWearablePartType]["male"] = newWearablePartMale
					end
					if newWearablePartFemale then
						ankleOverridesByObject[object.id][newWearablePartType]["female"] = newWearablePartFemale
					end
				end
				
				-- Store the foot part data separately.
				if footParts[object.id] == nil then
					footParts[object.id] = {}
				end
				footParts[object.id][wearablePart.type] = {}
				footParts[object.id][wearablePart.type]["male"] = wearablePart.male
				footParts[object.id][wearablePart.type]["female"] = wearablePart.female

				-- Erase the foot part from the object to allow beasts to equip it.
				wearablePart.type = BLANK_SLOT
				wearablePart.male = nil
				wearablePart.female = nil
			end
		end
	end
end

-- Use loaded instead of load to ensure that items stored in the save (eg. enchanted items) have loaded first
local function onLoaded(e)
	for object in tes3.iterateObjects(tes3.objectType.armor) do
		initialiseBoot(object)
	end
	for object in tes3.iterateObjects(tes3.objectType.clothing) do
		initialiseBoot(object)
	end

	-- bodyPartAssigned events have already occurred, so force an update.
	tes3.player:updateEquipment()
	tes3ui.updateInventoryCharacterImage()
	for _, cell in ipairs(tes3.getActiveCells()) do
		for reference in cell:iterateReferences(tes3.objectType.npc) do
			reference:updateEquipment()
		end
	end
end
event.register("loaded", onLoaded)

local function isBeastFlag(race)
	return bit.band(race.flags, 2) == 2
end

local function isBeast(race)
	return isBeastList[race] or isBeastFlag(race)
end

local function unBeast(race)
	-- Temporarily trick the game into thinking this is not a beast race to allow equipping.
	if isBeastFlag(race) then
		isBeastList[race] = true
		race.flags = bit.band(race.flags, 1)
	end
end

local function reBeast(race)
	-- Restore the original beast race's flags.
	if isBeastList[race] then
		race.flags = bit.bor(race.flags, 2)
	end
end

local function onBoundBootsEquipped()
	for race in pairs(isBeastList) do
		reBeast(race)
	end
	event.unregister("equipped", onBoundBootsEquipped)
end

local function onMagicCasted(e)
	-- Support the player casting Bound Boots. The usual method doesn't work, so temporarily remove the beast flag instead.
	local race = e.caster.object.race
	if e.caster == tes3.player and isBeastFlag(race) then
		for _, effect in ipairs(e.source.effects) do
			if effect.id == tes3.effect.boundBoots then
				unBeast(race)
				event.register("equipped", onBoundBootsEquipped)
			end
		end
	end
end
event.register("magicCasted", onMagicCasted)

local function onBodyPartAssigned(e)
	local isBeast = isBeast(e.reference.object.race)
	
	-- For non-beasts, display the foot part that was previously erased, using the cached foot part data.
	if not isBeast and e.object and footParts[e.object.id] and not (e.index == tes3.activeBodyPart.leftFoot or e.index == tes3.activeBodyPart.rightFoot) then
		for wearablePartType, wearablePart in pairs(footParts[e.object.id]) do
			local bodyPart
			if e.reference.object.female and wearablePart["female"] then
				bodyPart = wearablePart["female"]
			else
				bodyPart = wearablePart["male"]
			end
			e.manager:setBodyPartForObject(e.object, wearablePartType, bodyPart, false)
		end
	end
	
	-- For beasts, apply overridden meshes for ankles.
	if isBeast and e.object and ankleOverridesByObject[e.object.id] and ankleOverridesByObject[e.object.id][e.index] and (e.index == tes3.activeBodyPart.leftAnkle or e.index == tes3.activeBodyPart.rightAnkle) then
		local footAnkleOverride = e.reference.object.female and ankleOverridesByObject[e.object.id][e.index]["female"] or ankleOverridesByObject[e.object.id][e.index]["male"]
		if footAnkleOverride then
			e.bodyPart = footAnkleOverride
		end
	end
end
event.register("bodyPartAssigned", onBodyPartAssigned)

local function restoreFootPart(object, sourceObject)
	sourceObject = sourceObject or object
	if footParts[sourceObject.id] then
		for wearablePartType, wearablePartMap in pairs(footParts[sourceObject.id]) do
			-- Find the next blank slot and add the foot part back.
			for _, newWearablePart in ipairs(object.parts) do
				if newWearablePart.type == BLANK_SLOT then
					newWearablePart.type = wearablePartType
					newWearablePart.male = wearablePartMap["male"]
					newWearablePart.female = wearablePartMap["female"]
					break
				end
			end
		end
	end
end

local function onEnchantedItemCreated(e)
	restoreFootPart(e.object, e.baseObject)
	initialiseBoot(e.object)
end
event.register("enchantedItemCreated", onEnchantedItemCreated)

-- We don't want the deletion of the foot part to be persisted for modified objects, so restore them just before saving.
local function onPreSave(e)
	for object in tes3.iterateObjects(tes3.objectType.armor) do
		if object.modified then
			restoreFootPart(object)
		end
	end
	for object in tes3.iterateObjects(tes3.objectType.clothing) do
		if object.modified then
			restoreFootPart(object)
		end
	end
end
event.register(tes3.event.save, onPreSave)

local function onPostSave(e)
	for object in tes3.iterateObjects(tes3.objectType.armor) do
		if object.modified then
			initialiseBoot(object)
		end
	end
	for object in tes3.iterateObjects(tes3.objectType.clothing) do
		if object.modified then
			initialiseBoot(object)
		end
	end
end
event.register(tes3.event.saved, onPostSave)