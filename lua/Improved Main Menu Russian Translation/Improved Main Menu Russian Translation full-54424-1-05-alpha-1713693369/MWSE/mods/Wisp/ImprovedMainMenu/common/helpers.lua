local constants = require("Wisp.ImprovedMainMenu.common.constants")
local log       = require("Wisp.ImprovedMainMenu.common.debug").log
local config    = require("Wisp.ImprovedMainMenu.config").config

local this = {}

-- I/O --

function this.getMostRecentSaveFilePath(args)
	if not args then args = {} end

	local isExistentialCheck = args.existential or false

	local savesDirectory = "Saves"
	
	--[[
		Info: We performe a simple check to see if the Saves directory exists. If not we return.
	]]--
	if not lfs.directoryexists(savesDirectory) then
		log:warn(string.format("Could not access the %s directory.", savesDirectory))
		return false
	end

	local originalWorkingDirectoryPath = lfs.currentdir()

	-- Saves --

	local mostRecentSaveFile = {
		name = nil,
		modifiedTimestamp = 0
	}

	--[[
		Info: We iterate over all the save files and return the path to the most recent one.
	]]--
	for saveFileName in lfs.dir(table.concat({originalWorkingDirectoryPath, savesDirectory}, "/")) do
		local saveFilePath = table.concat({savesDirectory, saveFileName}, "/")

		--[[
			Info: We search among files with suffix ".ess" (case-insensitive).
		]]--
		if string.lower(string.sub(saveFileName, -4)) == ".ess" and lfs.fileexists(saveFilePath) then
			
			-- Save File --

			if isExistentialCheck then return true end

			local saveFileModifiedTimestamp = lfs.attributes(saveFilePath, "modification")

			if mostRecentSaveFile.modifiedTimestamp < saveFileModifiedTimestamp then

				mostRecentSaveFile = {
					name = saveFileName,
					modifiedTimestamp = saveFileModifiedTimestamp
				}

				log:debug(string.format(
					"New File: %s | Date Modified: %s",
					saveFileName,
					os.date("%c", saveFileModifiedTimestamp)
				))

			end

		end
	end

	if not mostRecentSaveFile.name then return false end

	--[[
		Warning: tes3.loadGame requires a relative path from the Saves direcotry and not a
		full-path.
	]]--
	return mostRecentSaveFile.name
end

function this.loadMostRecentSaveFile()

	local mostRecentSaveFilePath = this.getMostRecentSaveFilePath()

	if not mostRecentSaveFilePath then
		log:error{ text = "No save files found." }
		--[[
			Warning: We should not return a false value; otherwise, the subsequent handlers, if any,
			won't be called.
		]]--
		return 
	end

	tes3.loadGame(mostRecentSaveFilePath)

end

-- Flags --

--[[
	Info: An indicator of whether we are in a alive simulation, i.e., a game is loaded and the
	player is still alive.
]]--
function this.isSimulationAlive()
	return not (tes3.onMainMenu() or (tes3.mobilePlayer and tes3.mobilePlayer.isDead))
end

return this