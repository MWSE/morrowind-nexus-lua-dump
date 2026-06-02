-- ancestor_ghost/content_register.lua
-- LOAD script: runs once when ancestor_ghost.omwscripts is loaded.
-- Required entry point for .omwscripts; validates OpenMW API revision.
-- The playable race comes from ancestor_ghost.omwaddon (RACE + BODY records).

local core = require('openmw.core')

if core.API_REVISION < 67 then
  error('Ancestor Ghost Race requires OpenMW 0.51 (API revision 67+)')
end

-- Nothing else to register at load time for this mod.
-- The RACE record in ancestor_ghost.omwaddon is sufficient for
-- character creation to expose the race.
