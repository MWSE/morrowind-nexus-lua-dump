local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local previousSoulgems
local soulgemRecords = {}
local soulgemBlacklist = {
	["misc_soulgem_azura"] = true,
	-- black soul gems https://www.nexusmods.com/morrowind/mods/45902
	["misc_soulgem_black"] = true,
	["misc_soulgem_blackempty"] = true,
	-- worthless soul gems (has visually filled soulgems) https://www.nexusmods.com/morrowind/mods/57073
	["misc_soulgem_cosmic_de"] = true,
	["misc_soulgem_ultimate_de"] = true,
	["misc_soulgem_titanic_de"] = true,
	["misc_soulgem_giant_de"] = true,
	["Misc_SoulGem_Petty_worthless"] = true,
	["misc_soulgem_lesser_worthless"] = true,
	["misc_soulgem_common_worthless"] = true,
	["misc_soulgem_greater_worthless"] = true,
	["misc_soulgem_grand_worthless"] = true,
	-- Visually Filled Soul Gems for OpenMW https://www.nexusmods.com/morrowind/mods/54100
	["misc_soulgem_petty_svnr"] = true,
	["misc_soulgem_lesser_svnr"] = true,
	["misc_soulgem_common_svnr"] = true,
	["misc_soulgem_greater_svnr"] = true,
	["misc_soulgem_grand_svnr"] = true,
}


for _, record in pairs(types.Miscellaneous.records) do
	local recordId = record.id
	if recordId:sub(1,13) == "misc_soulgem_" and not soulgemBlacklist[recordId] and record.value > 1 then
		table.insert(soulgemRecords, {id = recordId, value = record.value})
	end
end

table.sort(soulgemRecords, function(a,b) return a.value < b.value end)


local settings = {
	{
		key = "SOULGEM_SPLITTING",
		name = "Soulgem Splitting",
		description = "Split soulgems into smaller ones\n(otherwise they will just get flushed)",
		default = true,
		renderer = "checkbox",
	},
}
	
local soulgemRecordMap = {}
print("[FittingSoulgems] Registered Soulgems:")
for i,rec in pairs(soulgemRecords)do
	print(rec.id,rec.value*core.getGMST("fSoulGemMult"))
	soulgemRecordMap[rec.id] = i
	if i > 1 then
		local currentRecord = types.Miscellaneous.record(soulgemRecords[i].id)
		local nextLowerRecord = types.Miscellaneous.record(soulgemRecords[i-1].id)
		table.insert(settings, {
			key = "SPLITTING_"..i,
			name = "Split "..currentRecord.name.." -> "..nextLowerRecord.name ,
			description = currentRecord.value.."g -> ".. nextLowerRecord.value.."g",
			default = currentRecord.value / nextLowerRecord.value,
			renderer = "number",
		})
	end
end

local MOD_NAME = "FittingSoulgems"
local playerSection = storage.playerSection("Settings"..MOD_NAME)
I.Settings.registerGroup {
	key = "Settings" .. MOD_NAME,
	l10n = MOD_NAME,
	name = "Settings",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = settings
}

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = MOD_NAME,
	description = "This mod prevents small souls from going into big soulgems"
}

--local updateSettings = function (_,setting)
--end
--playerSection:subscribe(async:callback(updateSettings))
-- Improved soulgem splitting logic that reuses already split gems and handles multiple souls
local function checker()
	local currentSoulgems = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
		local recordId = item.recordId
		if soulgemRecordMap[recordId] then
			currentSoulgems[recordId.."-"..(types.Item.itemData(item).soul or "")] = {id = recordId, soul = types.Item.itemData(item).soul, count = item.count, ref = item}
		end
	end
	
	if previousSoulgems then
		local query = {player = self, remove = {}, add = {}, addWithSouls = {}}
		local hasQuery = false
		local neededGems = {} -- {targetIndex = {count = total_count, souls = {soul1 = count1, soul2 = count2, ...}}}
		
		-- Pass 1: Detect oversized gems, remove them, and gather requirements
		for customId, itemTbl in pairs(currentSoulgems) do
			local previousFilledCount = previousSoulgems[customId] and previousSoulgems[customId].count or 0
			local currentFilledCount = currentSoulgems[customId] and currentSoulgems[customId].count or 0
			
			if itemTbl.soul and currentFilledCount > previousFilledCount then -- a filled soulgem appeared!
				local previousUnfilledCount = previousSoulgems[itemTbl.id.."-"] and previousSoulgems[itemTbl.id.."-"].count or 0
				local currentUnfilledCount = currentSoulgems[itemTbl.id.."-"] and currentSoulgems[itemTbl.id.."-"].count or 0
				
				if currentUnfilledCount < previousUnfilledCount then -- unfilled count has decreased
					local soulgemIndex = soulgemRecordMap[itemTbl.id] or "??????"
					print("caught: "..itemTbl.soul.." in "..itemTbl.id)--.." ["..soulgemIndex.."]" )
					--print("tier "..soulgemIndex.." unfilled decreased", previousUnfilledCount, currentUnfilledCount)
					local count = currentFilledCount - previousFilledCount
					local soulgemRecord = soulgemRecords[soulgemIndex]

					local creatureRecord = types.Creature.record(itemTbl.soul)
					if not soulgemRecord or not creatureRecord then
						previousSoulgems = currentSoulgems
						print("[FittingSoulgems] ERROR: INVALID "..tostring(itemTbl.id)..", "..tostring(itemTbl.soul))
						ui.showMessage("[FittingSoulgems] ERROR: INVALID "..tostring(itemTbl.id)..", "..tostring(itemTbl.soul))
						return
					end
					
					if soulgemIndex > 1 then
						local fSoulGemMult = core.getGMST("fSoulGemMult")
						local soulgemCapacity = soulgemRecord.value * fSoulGemMult
						local soulSize = creatureRecord.soulValue
						
						-- Find the appropriate target index for this soul size
						local targetIndex = soulgemIndex-1
						while targetIndex > 1 and soulgemRecords[targetIndex-1].value * fSoulGemMult > soulSize do
							targetIndex = targetIndex - 1
						end
						
						local nextSoulgemCapacity = soulgemRecords[targetIndex].value * fSoulGemMult
						print("soul/currentGem/nextSmallerGem:",soulSize,soulgemCapacity,nextSoulgemCapacity)
						
						if soulSize <= nextSoulgemCapacity then
							if playerSection:get("SOULGEM_SPLITTING") then
								hasQuery = true
								
								-- Remove the oversized filled gem
								table.insert(query.remove, {item = itemTbl.ref, count = count})
								
								-- Add empty gems of the same type back to inventory
								query.add[soulgemRecord.id] = (query.add[soulgemRecord.id] or 0) + count
								
								-- Remember what we need to create
								if not neededGems[targetIndex] then
									neededGems[targetIndex] = {count = 0, souls = {}}
								end
								neededGems[targetIndex].count = neededGems[targetIndex].count + count
								neededGems[targetIndex].souls[itemTbl.soul] = (neededGems[targetIndex].souls[itemTbl.soul] or 0) + count
							else
								core.sendGlobalEvent("fittingSoulgems_flushSoulgem", {player = self, item = itemTbl.ref, count = count})
							end
						end
					end
				end
			end
		end
		
		-- Pass 2: Split gems to create the needed smaller gems
		for targetIndex, gemInfo in pairs(neededGems) do
			local totalNeeded = gemInfo.count
			
			-- Recursive function to split gems and provide needed count
			local function cascadeSplit(fromIndex, needed)
				-- splitting fromIndex -> toIndex (-1)
				if needed <= 0 or fromIndex <= targetIndex or fromIndex > #soulgemRecords then
					return 0 -- Can't split further or no more needed
				end
				
				-- Start with what we already have at this level
				local availableToSplit = query.add[soulgemRecords[fromIndex].id] or 0
				local totalProduced = 0
				
				-- Keep trying until we have enough or exhaust all possibilities
				while totalProduced < needed do
					-- If we don't have gems to split at this level, try to get more from higher levels
					if availableToSplit <= 0 and fromIndex < #soulgemRecords then
						local avgSplitResult = playerSection:get("SPLITTING_"..fromIndex)
						local neededFromHigher = math.ceil((needed - totalProduced) / math.max(1, avgSplitResult))
						local gotFromHigher = cascadeSplit(fromIndex + 1, neededFromHigher)
						availableToSplit = availableToSplit + gotFromHigher
						query.add[soulgemRecords[fromIndex].id] = (query.add[soulgemRecords[fromIndex].id] or 0) + gotFromHigher
					end
					
					-- If we still don't have gems to split, we're done
					if availableToSplit <= 0 then
						break
					end
					
					-- Split one gem with individual random roll
					local splitResult = playerSection:get("SPLITTING_"..fromIndex)
					if math.random() < splitResult%1 then
						splitResult = splitResult + 1
					end
					splitResult = math.floor(splitResult)
					-- Use one gem (even if it produces 0 smaller gems)
					availableToSplit = availableToSplit - 1
					totalProduced = totalProduced + splitResult
				end
				
				-- Update gem counts
				local nextIndex = fromIndex - 1
				local actualProduced = totalProduced
				if actualProduced > 0 then
					query.add[soulgemRecords[nextIndex].id] = (query.add[soulgemRecords[nextIndex].id] or 0) + actualProduced
				end
				query.add[soulgemRecords[fromIndex].id] = availableToSplit -- What's left after splitting
				
				return actualProduced
			end
			
			-- Start splitting from the smallest gem larger than target
			cascadeSplit(targetIndex + 1, totalNeeded)
			
			local available = query.add[soulgemRecords[targetIndex].id]
			
			-- Create filled gems with souls
			for soul, soulCount in pairs(gemInfo.souls) do
				local actualCount = math.min(soulCount, available)
				if actualCount > 0 then
					table.insert(query.addWithSouls, {id = soulgemRecords[targetIndex].id, count = actualCount, soul = soul})
					query.add[soulgemRecords[targetIndex].id] = query.add[soulgemRecords[targetIndex].id] - actualCount
					available = available - actualCount
				end
				
				if actualCount < soulCount then
					print("[FittingSoulgems] Warning: Could only provide", actualCount, "of", soulCount, "gems for soul", soul)
				end
			end
		end
		
		if hasQuery then
			core.sendGlobalEvent("fittingSoulgems_inventoryChanges", query)
		end
	end
	previousSoulgems = currentSoulgems
end
	
	
local function onLoad(data)
	--saveData = data or {}
	
	stopTimerFn = time.runRepeatedly(checker, 0.489 * time.second, {
		type = time.SimulationTime,
		initialDelay = 0.489 * time.second
	})
end
local function UiModeChanged(data)
	if data.newMode == "Interface" then
		checker()
	end
end
	
return {
	engineHandlers = { 
		onLoad = onLoad,
		onInit = onInit,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
	}
}