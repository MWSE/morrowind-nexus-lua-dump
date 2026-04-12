-- =============================================================================
-- VAIN.runtime
-- A small shared table holding references to game-world state that operators
-- need but that aren't available at require-time. main.lua populates these
-- fields during the `loaded` event.
--
-- Why a separate module: operators need `mobilePlayer` (to call startCombat
-- on it) and `activeEnemies` (to remove themselves on give-up). Threading
-- these through every operator's signature would be ugly. A shared table
-- module is the lightest-weight DI container that works.
-- =============================================================================
return {
	player = nil, ---@type tes3reference?
	mobilePlayer = nil, ---@type tes3mobilePlayer?
	playerPos = nil, ---@type tes3vector3?
	activeEnemies = {}, ---@type table<tes3reference, table>
}
