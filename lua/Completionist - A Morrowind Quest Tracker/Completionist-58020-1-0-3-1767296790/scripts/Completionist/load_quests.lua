-- =============================================================================
-- QUEST PATCH REGISTRY
-- =============================================================================
-- To add a new quest pack (like Tamriel Rebuilt or other quest mod):
-- 1. Place the quest file in the scripts/Completionist/ folder.
-- 2. Add a new 'require' line below for that file.
-- 3. To disable a pack, simply add '--' at the start of the line.

require('scripts.Completionist.quests_mw')      -- Core Morrowind Quests (REQUIRED)

-- ADD YOUR PATCHES BELOW:
-- require('scripts.Completionist.quests_tr')   -- Example: Tamriel Rebuilt Addon
-- require('scripts.Completionist.quests_shotn') -- Example: Skyrim Home of the Nords

return true