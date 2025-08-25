local menu = require("openmw.menu")
local storage = require('openmw.storage')
local core = require('openmw.core')
local ui = require('openmw.ui')

MODNAME = "SealedFate"
TESTING = false


local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%01d:%02d:%02d", hours, minutes, secs)
end

-- Store current save directory
local function storeSaveDir()
	local playerSection = storage.playerSection(MODNAME)
    local currentSaveDir = menu.getCurrentSaveDir()
    if currentSaveDir then
        playerSection:set("DANGER_SAVE_DIR", currentSaveDir)
        print("SealedFate: Stored danger save dir: " .. currentSaveDir)
    end
end

local function checkDeletion(event)
	local playerSection = storage.playerSection(MODNAME)
	local settingsSection = storage.playerSection('Settings'..MODNAME)
    local abandonedSaveDir = playerSection:get("DANGER_SAVE_DIR")
    if abandonedSaveDir then
		if event == "onLoad" then
			print("SealedFate menu "..(event or "")..", Abandoned save detected:", abandonedSaveDir)
		else
			print("SealedFate menu: Deleting", abandonedSaveDir)
		end
		local success, saves = pcall(menu.getSaves, abandonedSaveDir)
		if success and saves then
			local deletedCount = 0
			local failedCount = 0
			local bestPlayTime = -1
			local bestLevel = 0
			local bestName
			for slotName, save in pairs(saves) do
				if save.timePlayed > bestPlayTime then
					bestLevel = save.playerLevel 	
					bestName = save.playerName 	
					bestPlayTime = save.timePlayed
				end
				local deleteSuccess, err= pcall(function()
					if not TESTING then
						menu.deleteGame(abandonedSaveDir, slotName)
						deletedCount = deletedCount + 1
					end
				end)
				if deleteSuccess then
					if not TESTING then
						print("SealedFate: Deleted " .. slotName)
					else
						print("SealedFate: Didn't delete " .. slotName)
					end
				else
					print("SealedFate: error ", err)
					failedCount = failedCount + 1
				end
			end
			
			if deletedCount > 0 then
				if failedCount > 0 then
					print("SealedFate: Permadeath "..(not TESTING and "" or "not").." executed - " .. deletedCount .. " save(s) deleted! "..failedCount.." failed")
					if not bestName then
						deletedText={abandonedSaveDir.." perished but "..failedCount.." saves could not be deleted",
							"ERROR: NO BEST SAVE FOUND?"}
					else
						deletedText = {
							bestName.." perished",
							"Level: "..bestLevel,
							"Playtime: "..formatTime(bestPlayTime),
							"Folder: "..abandonedSaveDir,
							"Error: "..failedCount.." saves could not be deleted",
						}
					end
					require("scripts.SealedFate.SF_deletedDialogue")
				else
					print("SealedFate: Permadeath "..(not TESTING and "" or "not").." executed - " .. deletedCount .. " save(s) deleted!")
					if not bestName then
						deletedText={abandonedSaveDir.." perished",
							"ERROR: NO BEST SAVE FOUND?"}
					else
						deletedText = {
							bestName.." perished",
							"Level: "..bestLevel,
							"Playtime: "..formatTime(bestPlayTime),
							"Folder: "..abandonedSaveDir,
						}
					end
					require("scripts.SealedFate.SF_deletedDialogue")
				end
			end
		else
			print("SealedFate: Could not access saves for directory: " .. abandonedSaveDir)
		end
		playerSection:set("DANGER_SAVE_DIR", nil)
		if event == "onLoad" then
			playerSection:set("FORCE_KILL_CHARACTER", true)
		end
	end
end





return {
    eventHandlers = {
        SealedFate_storeSaveDir = storeSaveDir,
        SealedFate_checkDeletion = checkDeletion,
    },
}