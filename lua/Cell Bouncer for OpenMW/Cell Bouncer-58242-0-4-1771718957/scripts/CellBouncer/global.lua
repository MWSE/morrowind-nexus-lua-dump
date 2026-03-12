local world   = require('openmw.world')
local util    = require('openmw.util')
local core    = require('openmw.core')
local vfs	  = require('openmw.vfs')
local markup  = require('openmw.markup')

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

-- Boundary message text
-- Will be used if all config files lack "boundaryMessage"
local BOUNDARY_MSG = "You can't go that way"

-- Boundary sound file
-- Will be used if all config files lack "boundarySound"
-- local BOUNDARY_SND = "Sound\\Vo\\Misc\\cb\\AzuraNotFinished.mp3"
local BOUNDARY_SND = ""

-- Fallback destination
-- Will be used if the player enters a blocked cell and no valid safe spot exists
local FALLBACK_MSG = "You have been returned to safety from parts unknown"
local FALLBACK_SND = "Sound\\Vo\\Misc\\chargendock1.mp3"
local FALLBACK_CELL_NAME = "Seyda Neen, Census and Excise Office"
local FALLBACK_POS = util.vector3(-74, -133, 225)

-- Cell Bouncer Mode
-- Will be used if all config files lack "mode"
-- Options: wall, flip
local BOUNCER_MODE = "flip"

-- How often to allow full onUpdate logic to run
-- 0.0 will minimize rubber-banding. Higher values may be better for performance.
local INTERVAL = 0.12

-- Folder containing YAML config files
local CONFIG_PREFIX = "scripts/CellBouncer/blocklists"

-- =============================================================================
-- INIT GLOBAL VARIABLES
-- =============================================================================

-- Store blocklists, allow lists, and per-blocklist behaviors
-- These are populated by loadAllYamlIntoLists()
local BLOCKED_NAMES    = {}
local BLOCKED_HASHES   = {}
local ALLOWED_RANGES   = {}
local BLOCKED_RANGES   = {}
local BLOCK_BEHAVIORS  = {}

-- Store the pre-calculated lengths of each range
-- These are populated by loadAllYamlIntoLists()
local numBlockedNames  = {}
local numAllowedRanges = {}
local numBlockedRanges = {}

-- Store safe coordinates and rotation for each player id
-- safeSpots[id] = { cellName = "...", pos = vec3, rot = quat }
local safeSpots = {}
for _, player in ipairs(world.players) do
	safeSpots[player.id] = { cellName = false, pos = false, rot = false }
end

-- Store the last known non-blocklisted exterior cell
local lastCellIds = {}

-- Timer used by onUpdate to avoid running the full check every frame
local timer = 0

-- =============================================================================
-- YAML FUNCTIONS
-- =============================================================================

-- Appends cell ranges (src) to a list (dst)
local function appendRangeList(dst, src)
	if type(src) ~= 'table' then return end
	for _, r in ipairs(src) do
		if type(r) == 'table' and r[1] and r[2] and r[3] and r[4] then
			table.insert(dst, { tonumber(r[1]), tonumber(r[2]), tonumber(r[3]), tonumber(r[4]) })
		end
	end
end

-- Appends cell name strings (src) to a list (dst)
local function appendStringList(dst, src)
	if type(src) ~= 'table' then return end
	for _, s in ipairs(src) do
		if type(s) == 'string' and s ~= '' then
			table.insert(dst, s)
		end
	end
end

-- Returns true if the supplied filename ends with the specified suffix
local function endsWith(str, suffix)
	return suffix == "" or str:sub(-#suffix) == suffix
end

-- Accepts blockedRanges or allowedRanges from YAML and returns a Lua table containing those ranges
-- Used when populating BLOCK_BEHAVIORS
local function copyRanges(src)
	local out = {}
	if type(src) ~= 'table' then return out end
	for _, r in ipairs(src) do
		if r[1] and r[2] and r[3] and r[4] then
			table.insert(out, { r[1], r[2], r[3], r[4] })
		end
	end
	return out
end

-- Accepts blockedCellNames from YAML and returns a Lua table containing those names
-- Used when populating BLOCK_BEHAVIORS
local function copyNames(src)
	local out = {}
	if type(src) ~= 'table' then return out end
	for _, n in ipairs(src) do
		if type(n) == "string" then
			table.insert(out, n)
		end
	end
	return out
end

-- Populates the following variables:
-- BLOCKED_NAMES, BLOCKED_HASHES, BLOCKED_RANGES, ALLOWED_RANGES, BLOCK_BEHAVIORS
local function loadAllYamlIntoLists()
	-- Clear variables in case function is called again so that new lists can be loaded
	BLOCKED_NAMES = {}
	BLOCKED_RANGES = {}
	ALLOWED_RANGES = {}
	
	for fileName in vfs.pathsWithPrefix(CONFIG_PREFIX) do
		if endsWith(fileName, ".yaml") or endsWith(fileName, ".yml") then
			local ok, data = pcall(markup.loadYaml, fileName)
			if ok and type(data) == 'table' then
				-- Merge all blocklists and allow lists from YAML configs into Lua tables
				-- These values are used by the isCellBlocked function
				appendStringList(BLOCKED_NAMES, data.blockedCellNames)
				appendRangeList(BLOCKED_RANGES, data.blockedRanges)
				appendRangeList(ALLOWED_RANGES, data.allowedRanges)
				
				-- Populate per-blocklist behaviors
				-- These values are used by the getBehaviorForCell function
				table.insert(BLOCK_BEHAVIORS, {
				  source = filename,
				  priority = tonumber(data.priority) or 0,
				  mode = data.mode or BOUNCER_MODE,
				  boundaryMessage = data.boundaryMessage,
				  boundarySound = data.boundarySound,
				  blockedRanges = copyRanges(data.blockedRanges),
				  blockedNames = copyNames(data.blockedCellNames),
				})
			else
				print("[CellBouncer] Failed to load YAML: " .. tostring(fileName))
			end
		end
	end
	
	-- Precalculate the length of each range
	numBlockedNames  = #BLOCKED_NAMES
	numAllowedRanges = #ALLOWED_RANGES
	numBlockedRanges = #BLOCKED_RANGES
	
	-- Convert BLOCKED_NAMES into BLOCKED_HASHES
	for i = 1, numBlockedNames do
		local name = BLOCKED_NAMES[i]
		BLOCKED_HASHES[name] = true
	end
	
	print(string.format("[CellBouncer] Loaded YAML: %d blocked names, %d blocked ranges, %d allowed ranges",
		numBlockedNames, numBlockedRanges, numAllowedRanges))
end

-- =============================================================================
-- CELL FUNCTIONS
-- =============================================================================

-- Return true if supplied cell is a blocked cell
-- Allow lists override blocklists, cells blocked by name override allow lists
local function isCellBlocked(cell)
	-- Early return if cell was not specified
	if not cell then return false end

	-- Check cell against blocked cell names
	if BLOCKED_HASHES[cell.name] then return true end

	-- Init local vars
	local x, y = cell.gridX, cell.gridY
	
	-- Override blocked grid ranges with allowed ranges
	for i = 1, numAllowedRanges do
		local range = ALLOWED_RANGES[i]
		if x >= range[1] and x <= range[2] and y >= range[3] and y <= range[4] then
			return false 
		end
	end

	-- Check cell against blocked grid ranges
	for i = 1, numBlockedRanges do
		local range = BLOCKED_RANGES[i]
		if x >= range[1] and x <= range[2] and y >= range[3] and y <= range[4] then
			return true
		end
	end

	return false
end

-- Get list of behaviors for the provided cell
-- Only called after isCellBlocked has returned true
-- Safe to assume that the supplied cell is either in BLOCKED_HASHES, or is both in BLOCKED_RANGES and not-in ALLOWED_RANGES
local function getBehaviorForCell(cell)
	local best = nil

	for _, cfg in ipairs(BLOCK_BEHAVIORS) do
		local matches = false
		
		if BLOCKED_HASHES[cell.name] then
			-- Cell exists in BLOCKED_HASHES
			-- Check if a match exists in BLOCK_BEHAVIORS
			for _, n in ipairs(cfg.blockedNames) do
				if cell.name == n then
					matches = true
					break
				end
			end
		else
			-- Cell was not in BLOCKED_HASHES, so we can assume it must be in BLOCKED_RANGES
			-- Check if a match exists in BLOCK_BEHAVIORS
			local x, y = cell.gridX, cell.gridY
			for _, r in ipairs(cfg.blockedRanges) do
				if x >= r[1] and x <= r[2] and y >= r[3] and y <= r[4] then
					matches = true
					break
				end
			end
		end

		if matches then
			-- Configuration priority decides which blocklist takes precedence
			-- If the configuration priority of two blocklists is the same, fall back to alphabetical order
			if not best or cfg.priority > best.priority or (cfg.priority == best.priority and tostring(cfg.source) > tostring(best.source)) then
				best = cfg
			end
		end
	end

	return best
end

-- =============================================================================
-- MAIN LOOP
-- =============================================================================

-- onUpdate logic
local function onUpdate()
	-- Iterate through all players. Should only be one, but multiplayer is technically supported.
	for _, player in ipairs(world.players) do
		
		-- Early return if player is not in an exterior cell
		local currentCell = player.cell
		if not currentCell.isExterior then return end
		
		-- Detect if new cell is a blocked cell on cell change
		local id = player.id
		if lastCellIds[id] ~= currentCell.id and isCellBlocked(currentCell) then
			-- Get most recent safe spot
			local spot = safeSpots[id]
			
			-- Populate variables with behaviors specified for the supplied cell
			local behavior = getBehaviorForCell(currentCell)
			local mode     = behavior and behavior.mode or BOUNCER_MODE
			local msg      = behavior and behavior.boundaryMessage or BOUNDARY_MSG
			local snd      = behavior and behavior.boundarySound or BOUNDARY_S
			
			if spot.cellName then
				-- Teleport to the last safe spot, and optionally rotate the player 180 degrees
				if mode == "flip" then
					local currentYaw = spot.rot:getYaw()
					local newYaw = currentYaw + math.pi
					local newRotation = util.transform.rotateZ(newYaw)
					player:sendEvent('ScreenFadeOut')
					player:teleport(spot.cellName, spot.pos, { rotation = newRotation, onGround = false })
					player:sendEvent('FlipCamera')
				else
					player:teleport(spot.cellName, spot.pos, { rotation = player.rotation, onGround = false })
				end
				
				if msg then player:sendEvent('DisplayBoundaryMessage', msg) end
				if snd then player:sendEvent('PlaySoundFile', snd)end
				-- Uncomment the below print statement if needed for testing.
				--print("[CellBouncer] Blocked cell entered. Teleporting to last safe location.")
			else
				-- Fallback if no history exists (e.g. game loaded inside a blocklisted cell)
				player:teleport(FALLBACK_CELL_NAME, FALLBACK_POS, { rotation = player.rotation, onGround = true })
				if FALLBACK_MSG then player:sendEvent('DisplayBoundaryMessage', FALLBACK_MSG) end
				if FALLBACK_SND then player:sendEvent('PlaySoundFile', FALLBACK_SND) end
				print("[CellBouncer] Blocked cell entered with no safe location recorded. Teleporting to fallback.")
				-- In case player id is new or unique, re-init safespots
				safeSpots[id] = { cellName = false, pos = false, rot = false }
			end

		else
			-- Update safeSpot for the current player id
			safeSpots[id] = {
				cellName = currentCell.name,
				pos = player.position,
				rot = player.rotation
			}
			
			-- Update currentCell for the current player id
			lastCellIds[id] = currentCell.id
		end
	end
end

-- Populate variables from YAML
loadAllYamlIntoLists()

return {
	engineHandlers = {
		onUpdate = function(dt)
			timer = timer + dt
			
			if timer >= INTERVAL then
				onUpdate()
				timer = 0
			end
		end
	}
}