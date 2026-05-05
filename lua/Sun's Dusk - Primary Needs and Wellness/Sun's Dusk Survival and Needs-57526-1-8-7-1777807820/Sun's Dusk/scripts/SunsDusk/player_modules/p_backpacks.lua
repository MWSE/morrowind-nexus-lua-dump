local VFX_ID = "SD_backpackVfx"
local lastCameraMode
local hasSimplyMining = core.contentFiles.has('SimplyMining.omwscripts')

-- Define bone attachments for each backpack
local BACKPACK_BONES = {
	sd_pouch_eq = "Bip01 backpackSD",
	sd_backpack_eq = "Bip01 backpackSD",
	sd_backpack_traveler_eq = "Bip01 backpackWE",
	sd_backpack_adventurer_eq = "Bip01 backpackWE",
	sd_backpack_velvetblue_eq = "Bip01 backpackWE",
	sd_backpack_satchelbrown_eq = "Bip01 backpackWE",
	sd_backpack_adventurerblue_eq = "Bip01 backpackWE",
	sd_backpack_adventurergreen_eq = "Bip01 backpackWE",
	sd_backpack_velvetbrown_eq = "Bip01 backpackWE",
	sd_backpack_velvetgreen_eq = "Bip01 backpackWE",
	sd_backpack_velvetpink_eq = "Bip01 backpackWE",
	sd_backpack_satchelblue_eq = "Bip01 backpackWE",
	sd_backpack_satchelblack_eq = "Bip01 backpackWE",
	sd_backpack_satchelgreen_eq = "Bip01 backpackWE",
}

-- Define feather percentage for each backpack type (% of camping item weight negated)
local BACKPACK_FEATHER_PERCENT = {
	sd_pouch_eq = 55,
	sd_backpack_eq = 55,
	sd_backpack_traveler_eq = 70,
	sd_backpack_adventurer_eq = 70,
	sd_backpack_adventurerblue_eq = 70,
	sd_backpack_adventurergreen_eq = 70,
	sd_backpack_velvetblue_eq = 70,
	sd_backpack_velvetbrown_eq = 70,
	sd_backpack_velvetgreen_eq = 70,
	sd_backpack_velvetpink_eq = 70,
	sd_backpack_satchelbrown_eq = 40,
	sd_backpack_satchelblue_eq = 40,
	sd_backpack_satchelblack_eq = 40,
	sd_backpack_satchelgreen_eq = 40,
}

local simplyMiningOres = {
	["t_ingmine_oreiron_01"] = true,
	["t_ingmine_orecopper_01"] = true,
	["t_ingmine_coal_01"] = true,
	["t_ingmine_oresilver_01"] = true,
	["t_ingmine_oregold_01"] = true,
	["t_ingmine_oreorichalcum_01"] = true,
	["ingred_diamond_01"] = true,
	["ingred_adamantium_ore_01"] = true,
	["ingred_raw_glass_01"] = true,
	["ingred_raw_ebony_01"] = true,
}


local DEFAULT_BONE = "Bip01 backpackSD"

-- Binary-encoded ability IDs: sd_feather_f1 (1), sd_feather_f2 (2), sd_feather_f4 (4), etc.
-- Supports magnitudes 0-255 with 8 abilities
local FEATHER_BITS = {1, 2, 4, 8, 16, 32, 64, 128}

-- Updates feather magnitude by only adding/removing changed abilities
local function updateFeatherMagnitude(targetMagnitude)
	local currentMagnitude = saveData.featherMagnitude or 0
	targetMagnitude = targetMagnitude or 0
	
	if currentMagnitude == targetMagnitude then return end
	for i, bit in ipairs(FEATHER_BITS) do
		local hadBit = (currentMagnitude % (bit * 2)) >= bit
		local needsBit = (targetMagnitude % (bit * 2)) >= bit
		if hadBit and not needsBit then
			local abilityId = "sd_feather_f" .. i
			if core.magic.spells.records[abilityId] then
				typesActorSpellsSelf:remove(abilityId)
			end
		elseif needsBit and not hadBit then
			local abilityId = "sd_feather_f" .. i
			if core.magic.spells.records[abilityId] then
				typesActorSpellsSelf:add(abilityId)
			end
		end
	end
	
	saveData.featherMagnitude = targetMagnitude
end

local function refreshFeatherMagnitude()
	if not saveData.backpackId then
		updateFeatherMagnitude(0)
		return
	end
	
	local percent = BACKPACK_FEATHER_PERCENT[saveData.backpackId] or 0
	if percent == 0 then
		updateFeatherMagnitude(0)
		return
	end
	
	local campingWeight = 0
	local miningWeight = 0
	for _, item in ipairs(typesActorInventorySelf:getAll()) do
		local recordId = item.recordId
		if recordId:find("sd_wood") or recordId:find("sd_campingitem") then
			local record = item.type.record(item)
			if record and record.weight then
				campingWeight = campingWeight + record.weight * item.count
			end
		end
		if hasSimplyMining then
			if simplyMiningOres[recordId] then
				local record = item.type.record(item)
				miningWeight = miningWeight + record.weight * item.count
			elseif recordId:find("pick") and types.Weapon.objectIsInstance(item) then
				local record = item.type.record(item)
				miningWeight = miningWeight + record.weight * item.count
			end
		end
	end
	local magnitude = math.floor((campingWeight + miningWeight) * percent / 100)
	magnitude = math.min(magnitude, 255)
	updateFeatherMagnitude(magnitude)
end


local function refreshVfx(retries)
	animation.removeVfx(self, VFX_ID)
	if not saveData.backpackId then
		return
	end
	local boneName = BACKPACK_BONES[saveData.backpackId] or DEFAULT_BONE
	if not animation.hasBone(self, boneName) then
		log(3, "[SD Backpacks] bone not found:", boneName)
		if not retries then
			async:newUnsavableSimulationTimer(0.1, function()
				refreshVfx(1)
			end)
		end
		return 
	end
	
	local record = types.Miscellaneous.record(saveData.backpackId)
	if not record then
		log(3, "[SD Backpacks] no record for", saveData.backpackId)
		return
	end
	
	log(5, "[SD Backpacks] refreshVfx: adding VFX", "model=" .. tostring(record.model), "bone=" .. boneName)
	animation.addVfx(self, record.model, {
		vfxId = VFX_ID,
		boneName = boneName,
		loop = true,
		useAmbientLight = false,
	})
end

local function onBackpackEquipped(data)
	log(5, "[SD Backpacks] onBackpackEquipped", "newId=" .. tostring(data.backpackId), "oldId=" .. tostring(saveData.backpackId))
	
	-- Remove old base ability
	if saveData.backpackId then
		local oldAbility = saveData.backpackId:sub(1, -3) .. "ab"
		if core.magic.spells.records[oldAbility] then
			typesActorSpellsSelf:remove(oldAbility)
		end
	end
	
	-- Set new backpack
	saveData.backpackId = data.backpackId
	
	-- Update feather based on camping items
	refreshFeatherMagnitude()
	
	-- Add new base ability if it exists
	if saveData.backpackId then
		local newAbility = saveData.backpackId:sub(1, -3) .. "ab"
		if core.magic.spells.records[newAbility] then
			typesActorSpellsSelf:add(newAbility)
		end
	end
	
	refreshVfx()
end

local function onFrame()
	if not saveData.backpackId then return end
	
	if camera.getMode() ~= lastCameraMode then
		lastCameraMode = camera.getMode()
		if lastCameraMode ~= camera.MODE.FirstPerson then
			refreshVfx()
		end
	end
	
	-- Check if backpack still exists
	if not typesActorInventorySelf:find(saveData.backpackId) then
		-- Backpack was removed/dropped
		core.sendGlobalEvent("SunsDusk_convertInCell", self)
		
		local baseAbility = saveData.backpackId:sub(1, -3) .. "ab"
		if core.magic.spells.records[baseAbility] then
			typesActorSpellsSelf:remove(baseAbility)
		end
		updateFeatherMagnitude(0)
		saveData.backpackId = nil
		refreshVfx()
		return
	end
end

table.insert(G_onFrameJobsSluggish, onFrame)

G_onInventoryChangedJobs.backpack = function(gained, lost)
	if not saveData.backpackId then return end
	for id in pairs(gained) do
		if id:find("sd_wood") or id:find("sd_campingitem") then
			refreshFeatherMagnitude()
			return
		end
	end
	for id in pairs(lost) do
		if id:find("sd_wood") or id:find("sd_campingitem") then
			refreshFeatherMagnitude()
			return
		end
	end
end

local function onLoad()
	if saveData.backpackId then
		if not types.Miscellaneous.records[saveData.backpackId] then
			local baseAbility = saveData.backpackId:sub(1, -3) .. "ab"
			if core.magic.spells.records[baseAbility] then
				typesActorSpellsSelf:remove(baseAbility)
			end
			saveData.backpackId = nil
			updateFeatherMagnitude(0)
		elseif typesActorInventorySelf:find(saveData.backpackId) then
			G_onFrameJobs["refreshBackpackVfx"] = function()
				G_onFrameJobs["refreshBackpackVfx"] = nil
				refreshVfx()
				refreshFeatherMagnitude()
			end
		else
			local baseAbility = saveData.backpackId:sub(1, -3) .. "ab"
			if core.magic.spells.records[baseAbility] then
				typesActorSpellsSelf:remove(baseAbility)
			end
			updateFeatherMagnitude(0)
			saveData.backpackId = nil
		end
		lastCameraMode = camera.getMode()
	end
end

table.insert(G_onLoadJobs, onLoad)
G_eventHandlers.SunsDusk_backpackEquipped = onBackpackEquipped

local function UiModeChanged(data)
	if data.oldMode == "Rest" or data.oldMode == "Travel" then
		refreshVfx()
	end
end

table.insert(G_UiModeChangedJobs, UiModeChanged)