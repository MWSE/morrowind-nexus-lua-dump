--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
----------------------------------------------------------------------
-- Anti-Theft Guard AI  •  v0.9 PUBLIC TEST  •  OpenMW ≥ 0.49
----------------------------------------------------------------------
-- Configuration and Constants
----------------------------------------------------------------------

local config = {}



-- Timing (now configurable via settings)
local settings = require('scripts.antitheftai.SHOPsettings')
config.FACTION_IGNORE_RANK = settings.vars:get('factionIgnoreRank') or 5
config.ENTER_DELAY = settings.timing:get('enterDelay') or 1.5
config.UPDATE_PERIOD = settings.timing:get('updatePeriod') or 1.0
config.SEARCH_WTIME_MIN = settings.timing:get('searchWTimeMin') or 10.0
config.SEARCH_WTIME_MAX = settings.timing:get('searchWTimeMax') or 15.0
config.LOS_CHECK_INTERVAL = settings.timing:get('losCheckInterval') or 1.0
config.HIERARCHY_CHECK_INTERVAL = settings.timing:get('hierarchyCheckInterval') or 1.5
config.PATH_SAMPLE_INTERVAL = settings.timing:get('pathSampleInterval') or 1.0

-- Distances (now configurable via settings)
config.SEARCH_WDIST = settings.distances:get('searchWDist') or 1000
config.PICK_RANGE = settings.distances:get('pickRange') or 1000
config.DESIRED_DIST_MIN = settings.distances:get('desiredDistMin') or 80
config.DESIRED_DIST_MAX = settings.distances:get('desiredDistMax') or 250
config.DIST_TOLERANCE = 50
config.LOS_RANGE = settings.distances:get('losRange') or 1000
config.MIN_MOVEMENT_THRESHOLD = 10

-- Angles (now configurable via settings)
config.LOS_HALF_CONE = math.rad(settings.vars:get('losHalfCone') or 170)

-- Detection range (now configurable via settings)
config.DETECTION_RANGE = settings.distances:get('detectionRange') or 140.0

-- Magic (now configurable via settings)
config.EFFECT_INVIS = "invisibility"
config.EFFECT_CHAM = "chameleon"
config.CHAM_HIDE_LIMIT = settings.vars:get('chamHideLimit') or 1

-- Sneak
config.HIDDEN_TIMEOUT = 2.0

-- NPC behavior (now configurable via settings)
config.NPC_WALK_SPEED = 40 -- do not change unless you want the guard return script to be executed too fast, if you still want to change, try going lower maybe
config.MIN_WANDER_DELAY = settings.timing:get('minWanderDelay') or 10.0
config.MAX_WANDER_DELAY = settings.timing:get('maxWanderDelay') or 15.0
config.FIXED_SEARCH_TIME = settings.timing:get('fixedSearchTime') or 0.0
config.DISABLE_HELLO_WHILE_FOLLOWING = settings.vars:get('disableHelloWhileFollowing') or true
config.DISPOSITION_FOLLOWING_IGNORE = settings.vars:get('dispositionFollowingIgnore') or 100
config.SIMULATED_TRAVEL_SPEED = settings.vars:get('simulatedTravelSpeed') or 300.0

-- Messages
config.invisRemovalMessages = {
    "There you are, scum!",
    "Got you, thief",
    "Filthy s'wit",
    "You cannot hide from me!",
    "You fool!"
}

-- Filters
-- example: config.DISABLED_NPC_NAMES = {"caius cosades", "fargoth"}
config.DISABLED_NPC_NAMES = {"vasesius viciulus"}
-- example: config.DISABLED_CELL_NAMES = {"balmora, guild of fighters", "seyda neen, arrille's tradehouse"}
config.DISABLED_CELL_NAMES = {"imperial prison ship", "mournhold, godsreach", "mournhold, plaza brindisi dorom", "mournhold, great bazaar", "mournhold, temple courtyard", "mournhold temple: high chapel", "mournhold temple: reception area", "ghostgate, temple", "Molag Mar, Vasesius Viciulus: Trader", "Mournhold, Royal Palace: Courtyard", "Vivec, Library of Vivec", "Molag Mar, The Pilgrim's Rest", "dagon fel, The End of the World", "sadrith mora, Dirty Muriel's Cornerclub", "suran, Desele's House of Earthly Delights", "suran, Suran Tradehouse", "tel aruhn, plot and plaster", "Vivec, Elven Nations Cornerclub", "Vivec, No Name Club", "Ald-ruhn, The Rat In The Pot", "Sadrith Mora, Telvanni Council House", "Wavebreaker Keep, Great Hall"}
-- example: config.DISABLED_NPC_NAME_CONTAINS = {"farg", "cosad"} , disables every NPC name containing added words
config.DISABLED_NPC_NAME_CONTAINS = {}
-- example: config.DISABLED_CELL_NAME_CONTAINS = {"kogo", "adama"} , disables every cell name containing added words
config.DISABLED_CELL_NAME_CONTAINS = {"arena", "museum", "abecette", "canal", "plaza", "waistworks", "bath"}

-- Exterior cell whitelist - script ONLY runs in these exterior cells
-- By default, script is DISABLED in ALL exterior cells (for performance)
-- Add cell names here to enable script in specific exteriors
-- Example: ["Seyda Neen"] = true
-- Example: ["Vivec"] = true
config.ENABLED_EXTERIOR_CELLS = {
    -- Empty by default - add exterior cell names above to enable
}

-- Faction-based following (now dynamic based on NPC factions in cell)
-- No longer needed as we detect cell faction from NPCs


return config
