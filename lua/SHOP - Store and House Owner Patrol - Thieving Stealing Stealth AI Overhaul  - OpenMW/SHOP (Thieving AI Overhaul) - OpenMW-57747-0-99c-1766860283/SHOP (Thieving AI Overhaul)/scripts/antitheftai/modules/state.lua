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
-- Runtime State Variables
----------------------------------------------------------------------

local state = {}

-- Guard state
state.guard = nil
state.guardPriority = 999
state.home = nil

-- Behavior flags
state.waiting = false
state.following = false
state.searching = false
state.returningHome = false

-- Timers
state.searchT = 0
state.tDelay = 0
state.tLOSCheck = 0
state.tHierarchyCheck = 0
state.tRefresh = 0
state.tBedCheck = 0  -- Timer for bed proximity checks (runs every 0.5s)

-- Position tracking
state.lastSeenPlayer = nil
state.lastPlayerCell = nil
state.lastPlayerPosition = nil

-- Dialog state
state.dialogueWasOpen = false

-- Sneak state tracking
state.wasSneaking = false

-- Hidden state tracking
state.wasHidden = false

-- Bed proximity voice state
state.bedFirstVoiceFired = false
state.bedSecondVoiceFired = false

-- Effect removal tracking
state.justRemovedInvisibility = false
state.justRemovedChameleon = false
state.invisMessageSent = false
state.stealthMessageSent = false

-- Cell state
state.lastCell = nil
state.cellInitialized = false

-- Force checks
state.forceLOSCheck = false

-- Sneak detection
state.wasSneakHidden = false

-- Spell teleport handling
state.pendingSpellTeleport = false
state.spellCastCell = nil

-- Combat state
state.inCombat = false
state.wasInCombatWithPlayer = false

-- Storage tables
state.leftBehindGuards = {}
state.npcOriginalData = {}
state.dismissedNPCs = {}
state.mustCompleteReturn = {}
state.returnInProgress = {}
state.doorLockStates = {}
state.npcHasWandered = {}
state.crossCellReturns = {}
state.pendingReturns = {}
state.realTimeWandering = {}
state.activeGuards = {}
state.disbandedGuards = {}  -- NPCs that were disbanded but should still detect effects, with combat memory (persistent across sessions)
state.guardsPerCell = {}  -- cellName -> {guard = npc, following = true/false}
state.postTeleportPositions = {}  -- npcId -> position where NPC was teleported to through doors
state.twoPhaseReturns = {}  -- npcId -> true if using two-phase return (travel to post-teleport pos then teleport home)
state.cellBeds = {}  -- Cache of bed positions per cell: cellName -> {positions = {pos1, pos2, ...}}



-- Hello value tracking
state.helloSet = {}
state.originalHelloValues = {}
state.pendingHelloRestorations = {}  -- Track NPCs that need hello restoration when player returns to cell

-- Alarm value tracking
state.alarmSet = {}
state.originalAlarmValues = {}
state.pendingAlarmRestorations = {}  -- Track NPCs that need alarm restoration when player returns to cell

-- Reset function
function state.reset()
    state.guard = nil
    state.guardPriority = 999
    state.home = nil
    state.waiting = false
    state.following = false
    state.searching = false
    state.returningHome = false
    state.searchT = 0
    state.tDelay = 0
    state.tLOSCheck = 0
    state.tHierarchyCheck = 0
    state.tRefresh = 0
    state.tBedCheck = 0
    state.lastSeenPlayer = nil
    state.dialogueWasOpen = false
    state.wasSneakHidden = false
    state.wasHidden = false
    state.invisMessageSent = false
    state.stealthMessageSent = false
    state.pendingSpellTeleport = false
    state.spellCastCell = nil
    state.justRecruitedAfterReturn = false
    state.bedFirstVoiceFired = false
    state.bedSecondVoiceFired = false
    -- Clear hello tracking on reset
    state.helloSet = {}
    state.pendingHelloRestorations = {}
    -- Clear alarm tracking on reset
    state.alarmSet = {}
    state.pendingAlarmRestorations = {}
    -- Clear guards per cell on reset
    state.guardsPerCell = {}
    -- Clear two-phase return state on reset
    state.postTeleportPositions = {}
    state.twoPhaseReturns = {}
end

return state