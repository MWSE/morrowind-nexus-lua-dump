local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local originalPrint = print
_G.print = function(...)
    if ScheduleConfig.DEBUG_MODE then
        originalPrint(...)
    end
end

local core = require("openmw.core")
print("[ProceduralChatter] DEBUG: player.lua LOADED")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local util = require("openmw.util")
local storage = require("openmw.storage")
local input = require("openmw.input")
local camera = require("openmw.camera")
local anim = require('openmw.animation')
local ConversationManager = require("scripts.ProceduralChatter.ConversationManager")
local VoiceManager = require("scripts.ProceduralChatter.VoiceManager")
local I = require("openmw.interfaces")
local SittingLogic = require("scripts.ProceduralChatter.SittingLogic") -- Require SittingLogic check
local SittingGlobal = require("scripts.ProceduralChatter.SittingGlobal")
local NPCState = require("scripts.ProceduralChatter.NPCState")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")
-- Relocator is a global-only module (requires openmw.world); safe-require from local scripts.
local Relocator = nil
pcall(function() Relocator = require("scripts.ProceduralChatter.schedule.Relocator") end)

-- Register Settings
require("scripts.ProceduralChatter.settings")
local settingsGeneral = storage.playerSection("01_Settings_Chatter_General")
local settingsActivities = storage.playerSection("04_Settings_Chatter_Activities")
local settingsDebug = storage.playerSection("03_Settings_Chatter_Debug")

local SCAN_INTERVAL = 2.0

local lastScanTime = 0
local globalCooldown = 0
local wasActive = false

-- Pairs that have already conversed this cycle (blocked until others are exhausted).
local recentPairs = {}

local function getPairKey(id1, id2)
    local a = tostring(id1 or "")
    local b = tostring(id2 or "")
    if a < b then
        return a .. "|" .. b
    end
    return b .. "|" .. a
end

local function isPairRecent(id1, id2)
    return recentPairs[getPairKey(id1, id2)] == true
end

local function clearPairHistory()
    recentPairs = {}
    print("[ProceduralChatter] Pair history cleared.")
end

local function addToHistory(id1, id2)
    recentPairs[getPairKey(id1, id2)] = true
    local count = 0
    for _ in pairs(recentPairs) do count = count + 1 end
    print(string.format("[ProceduralChatter] History updated: %s <-> %s (blocked pairs: %d)",
        tostring(id1), tostring(id2), count))
end

local function removeFromHistory(id1, id2)
    if not id1 or not id2 then return end
    local key = getPairKey(id1, id2)
    if recentPairs[key] then
        recentPairs[key] = nil
        print(string.format("[ProceduralChatter] History removed for unplayed pair: %s <-> %s",
            tostring(id1), tostring(id2)))
    end
end

-- Settings Cache
local lastMin = -1
local lastMax = -1
local lastEnabled = nil

-- Debug toggle cache
local lastSleepEnabled      = nil
local lastSittingEnabled    = nil
local lastActivitiesEnabled = nil
local lastScheduleMovementEnabled = nil

-- Cell change tracking for schedule system
local lastCell = nil
local cellCheckTimer = 0
local CELL_CHECK_RATE = 1.0

local systemStartupTimer = 0

-- Wait/Rest menu detection: pause volatile systems while open; wrap up only when
-- game time actually advances (not on open-and-cancel without waiting).
local WAIT_TIME_EPS = 30 -- game seconds (~30s in-world)
local waitActive = false
local dialogueActive = false
local waitStartGameTime = nil
local wrappedThisWait = false
local skipPostWaitConversationCooldown = false

local function isWaitRestMode(mode)
    return mode == "Wait" or mode == "Rest"
end

local function isDialogueMode(mode)
    return mode == "Dialogue"
end

local function clearAllSubtitles()
    pcall(function() self:sendEvent("ProceduralChatter_ClearSubtitle", {}) end)
end

local function triggerWaitWrapUp()
    if wrappedThisWait then return end
    wrappedThisWait = true
    print("[ProceduralChatter] Wait time elapsed — instant wrap-up of conversations/activities.")
    clearAllSubtitles()
    skipPostWaitConversationCooldown = true
    ConversationManager.wrapUpInstant("wait")
    core.sendGlobalEvent("PC_WaitTimeElapsed", {})
end

local function setWaitActive(active)
    if waitActive == active then return end
    waitActive = active
    if active then
        waitStartGameTime = core.getGameTime()
        wrappedThisWait = false
        print("[ProceduralChatter] Wait/Rest menu opened — pausing conversations/activities/sitting assignment.")
    else
        print("[ProceduralChatter] Wait/Rest menu closed.")
        if not wrappedThisWait and waitStartGameTime then
            if core.getGameTime() - waitStartGameTime > WAIT_TIME_EPS then
                triggerWaitWrapUp()
            end
        end
        waitStartGameTime = nil
    end
    core.sendGlobalEvent("PC_WaitMenuState", { active = active })
end

local function setDialogueActive(active)
    if dialogueActive == active then return end
    dialogueActive = active
    if active then
        print("[ProceduralChatter] Dialogue menu opened — pausing new conversation/activity/sitting/sleep scans.")
    else
        print("[ProceduralChatter] Dialogue menu closed.")
    end
    core.sendGlobalEvent("PC_DialogueMenuState", { active = active })
    if ConversationManager.setDialogueMenuActive then
        ConversationManager.setDialogueMenuActive(active)
    end
end

local function pollWaitMenuState()
    local mode = I.UI.getMode()
    setWaitActive(isWaitRestMode(mode))
end

local function pollDialogueMenuState()
    local mode = I.UI.getMode()
    setDialogueActive(isDialogueMode(mode))
end

local function checkWaitTimeElapsed()
    if not waitActive or wrappedThisWait or not waitStartGameTime then return end
    if core.getGameTime() - waitStartGameTime > WAIT_TIME_EPS then
        triggerWaitWrapUp()
    end
end

local function onUpdate(dt)
    -- SETTINGS SYNC — must run FIRST and unconditionally, before any chatter
    -- enable check or startup delay. Subsystem toggles (sleep/sitting/schedule)
    -- need to work even when chatter is off.
    -- Sync debug toggles to global script.  The global script now also reads
    -- these directly from storage as an authoritative fallback, but we keep
    -- the event for low-latency updates.
    local curSleep      = settingsDebug:get("01_SleepEnabled")
    local curSitting    = settingsDebug:get("02_SittingEnabled")
    local curActivities = settingsDebug:get("03_ActivitiesEnabled")
    local curScheduleMovement = settingsDebug:get("04_ScheduleMovementEnabled")
    if curSleep ~= lastSleepEnabled or curSitting ~= lastSittingEnabled
       or curActivities ~= lastActivitiesEnabled or curScheduleMovement ~= lastScheduleMovementEnabled then
        lastSleepEnabled      = curSleep
        lastSittingEnabled    = curSitting
        lastActivitiesEnabled = curActivities
        lastScheduleMovementEnabled = curScheduleMovement
        core.sendGlobalEvent("PC_UpdateDebugToggles", {
            sleepEnabled      = curSleep,
            sittingEnabled    = curSitting,
            activitiesEnabled = curActivities,
            scheduleEnabled   = curScheduleMovement,
            scheduleMovementEnabled = curScheduleMovement,
        })
    end

    -- Cell change detection: notify global when player enters a new cell so
    -- the schedule system can materialise disabled NPCs inside interiors.
    -- CRITICAL: Compare by cell identifier, not object identity, because
    -- OpenMW returns a new cell userdata every frame.
    cellCheckTimer = cellCheckTimer + dt
    if cellCheckTimer >= CELL_CHECK_RATE then
        cellCheckTimer = 0
        local cur = self.cell
        local function getCellId(cell)
            if not cell then return nil end
            local ok, isExt = pcall(function() return cell.isExterior end)
            if ok and isExt then
                local gx, gy = 0, 0
                pcall(function() gx = cell.gridX; gy = cell.gridY end)
                return string.format("ext_%d_%d", gx, gy)
            else
                return cell.name or ""
            end
        end
        local curId = getCellId(cur)
        local lastId = getCellId(lastCell)
        if curId ~= lastId then
            local prev = lastCell
            lastCell = cur
            if cur then
                systemStartupTimer = 0
                clearPairHistory()
                ConversationManager.cancelAll("cell_change")
                local curName = cur.name or ''
                core.sendGlobalEvent("PC_PlayerEnteredCell", {
                    cellName     = curName,
                    prevCellName = prev and (prev.name or '') or '',
                    isExterior   = cur.isExterior,
                })
                self:sendEvent("PC_CompanionCellEntered", { cellName = curName })
            end
        end
    end

    -- Wait/Rest menu: always poll (even when chatter disabled) so global systems gate correctly.
    pollWaitMenuState()
    pollDialogueMenuState()
    checkWaitTimeElapsed()

    -- Check Enable Setting
    if not settingsGeneral:get("01_ChatterEnabled") then return end
    
    -- System Startup Delay (5 seconds)
    if systemStartupTimer < 5.0 then
        systemStartupTimer = systemStartupTimer + dt
        if systemStartupTimer % 1.0 < dt then -- Print once per second
             print(string.format("[ProceduralChatter] Startup Delay: %.1f / 5.0", systemStartupTimer))
        end
        if systemStartupTimer >= 5.0 then
            print("[ProceduralChatter] System Ready. Starting logic.")
        else
            return -- STRICT RETURN
        end
    end

    -- Activity cooldown settings sync (conversation subsystem only)
    local currentMin = settingsActivities:get("01_ActivityCooldownMin") or 10
    local currentMax = settingsActivities:get("02_ActivityCooldownMax") or 30
    local currentEnabled = true -- Already checked above
    
    if currentMin ~= lastMin or currentMax ~= lastMax or currentEnabled ~= lastEnabled then
        lastMin = currentMin
        lastMax = currentMax
        lastEnabled = currentEnabled
        
        print(string.format("[ProceduralChatter] Syncing Settings to Global: Min=%d, Max=%d", currentMin, currentMax))
        core.sendGlobalEvent("PC_UpdateSettings", {
            min = currentMin,
            max = currentMax,
            enabled = currentEnabled
        })
    end

    -- Update active conversations (freeze stepping while wait menu or dialogue is open)
    if not waitActive and not dialogueActive then
        ConversationManager.update(dt)
    end
    
    -- Check activity state for cooldown logic
    local isActive = ConversationManager.hasActive()
    if wasActive and not isActive then
        local unplayed = ConversationManager.consumeLastEndedWithoutPlayback
            and ConversationManager.consumeLastEndedWithoutPlayback()
        if unplayed then
            skipPostWaitConversationCooldown = false
            removeFromHistory(unplayed.initiatorId, unplayed.targetId)
            print("[ProceduralChatter] Conversation ended before playback; skipping scan cooldown.")
        elseif skipPostWaitConversationCooldown then
            skipPostWaitConversationCooldown = false
            print("[ProceduralChatter] Conversation ended via wait wrap-up; skipping post-wait scan cooldown.")
        else
            local minTime = settingsGeneral:get("11_MinTimer") or 10
            local maxTime = settingsGeneral:get("12_MaxTimer") or 30
            local cd = math.random(minTime, maxTime)
            print(string.format("[ProceduralChatter] Conversation ended. Cooldown: %.1fs", cd))
            globalCooldown = cd
        end
    end
    wasActive = isActive
    
    -- Handle cooldown
    if globalCooldown > 0 then
        globalCooldown = globalCooldown - dt
        return
    end
    
    -- Limit to 1 conversation at a time
    if isActive then return end

    -- Do not start new conversations while the wait/rest menu is open
    if waitActive then return end

    -- Do not start new conversations while the dialogue window is open
    if dialogueActive then return end

    local currentTime = core.getSimulationTime()
    if currentTime - lastScanTime < SCAN_INTERVAL then
        return
    end
    lastScanTime = currentTime

    -- Helper: Check if NPC is a Guard (Class or Name)
    local function isGuard(npc)
        local ok, result = pcall(function()
            local record = types.NPC.record(npc)
            if not record then return false end
            local cls = string.lower(record.class or "")
            local name = string.lower(record.name or "")
            if cls == "guard" or string.find(name, "guard") then return true end
            return false
        end)
        if not ok then return false end
        return result
    end

    -- Get nearby NPCs
    local actors = nearby.actors
    local npcs = {}
    local npcDistToPlayer = {}  -- cache: actor.id → distance to player
    local scanRadius = settingsGeneral:get("17_ConversationScanRadius") or 800
    for _, actor in ipairs(actors) do
        if actor.type == types.NPC and actor ~= self and not types.Actor.isDead(actor)
                and not Blacklist.isConversationBlacklisted(actor) then
            local d = (actor.position - self.position):length()
            if d <= scanRadius then
                table.insert(npcs, actor)
                npcDistToPlayer[actor.id] = d
            end
        end
    end
    
    -- Debug: Print status
    print(string.format("[ProceduralChatter] Scan: Found %d NPCs. Cooldown: %.1f", #npcs, math.max(0, globalCooldown)))

    -- Sort by distance to player to prioritize closest pairs
    table.sort(npcs, function(a, b)
        local distA = npcDistToPlayer[a.id] or 99999
        local distB = npcDistToPlayer[b.id] or 99999
        return distA < distB
    end)
    
    -- Optimization: Cap at 10 closest NPCs to limit combinatorial load in crowded areas
    local MAX_NPCS_TO_SCAN = 10
    if #npcs > MAX_NPCS_TO_SCAN then
        local capped = {}
        for i = 1, MAX_NPCS_TO_SCAN do
            table.insert(capped, npcs[i])
        end
        npcs = capped
    end

    -- Pair finding: skip pairs already in history until all other valid pairs are exhausted.
    print(string.format("[ProceduralChatter] Scanning %d NPCs...", #npcs))
    
    local possiblePairs = {}
    local seatedFallbackPairs = {}
    local validPairCount = 0
    local walkArrivalDist = settingsGeneral:get("07_WalkingArrivalDist") or settingsGeneral:get("WalkingArrivalDist") or 200
    local staticDist = settingsGeneral:get("08_StaticArrivalDist") or settingsGeneral:get("StaticArrivalDist") or 800

    local function isActorSitting(actor)
        return SittingGlobal and SittingGlobal.isSitting and SittingGlobal.isSitting(actor)
    end

    local function isActorStatic(actor)
        if isActorSitting(actor) then return true end
        if ConversationManager.isWalkBlacklisted(actor) then return true end
        return false
    end

    local function collectPairs(applyHistoryFilter)
        local normal = {}
        local seated = {}
        local validCount = 0
        for i, npc1 in ipairs(npcs) do
            if not ConversationManager.isActive(npc1)
                    and ConversationManager.canStartConversation(npc1) then
                local isStatic1 = isActorStatic(npc1)
                local isSitting1 = isActorSitting(npc1)

                for j = i + 1, #npcs do
                    local npc2 = npcs[j]
                    if not ConversationManager.isActive(npc2)
                            and ConversationManager.canStartConversation(npc2) then
                        local skip = NPCState.isInTransit(npc2.id) or NPCState.isInTransit(npc1.id)
                              or NPCState.isArrivalCooldownActive(npc2.id) or NPCState.isArrivalCooldownActive(npc1.id)
                        if not skip then
                            local isStatic2 = isActorStatic(npc2)
                            local isSitting2 = isActorSitting(npc2)
                            local isValid = false
                            local isSeatedFallback = false
                            local dist = 0
                            local score = 0

                            if isStatic1 and isStatic2 then
                                -- Neither can move → actual distance required
                                local delta = npc1.position - npc2.position
                                local weightedZ = delta.z * 4.0
                                dist = math.sqrt(delta.x * delta.x + delta.y * delta.y + weightedZ * weightedZ)
                                score = dist  -- closer static pairs preferred

                                if dist < staticDist then
                                    isValid = true
                                elseif (isSitting1 and isSitting2) and dist < scanRadius then
                                    -- Seated fallback: beyond staticDist but within scanRadius, one can stand
                                    if not ConversationManager.isWalkBlacklisted(npc1)
                                            or not ConversationManager.isWalkBlacklisted(npc2) then
                                        isValid = true
                                        isSeatedFallback = true
                                    end
                                end
                            else
                                -- At least one mobile → both in player radius & cap list → valid
                                isValid = true
                                local d1 = npcDistToPlayer[npc1.id] or 0
                                local d2 = npcDistToPlayer[npc2.id] or 0
                                score = (d1 + d2) * 0.5  -- prefer pairs closer to player
                            end

                            if isValid then
                                local g1 = isGuard(npc1)
                                local g2 = isGuard(npc2)
                                if (g1 or g2) and not ConversationManager.hasGuardSpecificConversation(npc1, npc2) then
                                    isValid = false
                                end
                            end

                            if isValid then
                                validCount = validCount + 1
                                local inHistory = applyHistoryFilter and isPairRecent(npc1.id, npc2.id)
                                if inHistory then
                                    print(string.format("[ProceduralChatter] SKIP recent pair: %s <-> %s (inHistory=true)",
                                        npc1.recordId, npc2.recordId))
                                else
                                    local pair = {
                                        npc1 = npc1,
                                        npc2 = npc2,
                                        isStatic1 = isStatic1,
                                        isStatic2 = isStatic2,
                                        dist = dist,  -- 0 for mobile pairs (not used for gating or scoring)
                                        score = score,
                                        inHistory = false,
                                        seatedFallback = isSeatedFallback
                                    }
                                    if isSeatedFallback then
                                        table.insert(seated, pair)
                                    else
                                        table.insert(normal, pair)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return normal, seated, validCount
    end

    possiblePairs, seatedFallbackPairs, validPairCount = collectPairs(true)
    if #possiblePairs == 0 and #seatedFallbackPairs == 0 and validPairCount > 0 then
        print(string.format("[ProceduralChatter] All %d valid nearby pairs in history; resetting.", validPairCount))
        clearPairHistory()
        possiblePairs, seatedFallbackPairs = collectPairs(false)
    end

    local selectedPairs = possiblePairs
    local usingSeatedFallback = false
    if #selectedPairs == 0 and #seatedFallbackPairs > 0 then
        selectedPairs = seatedFallbackPairs
        usingSeatedFallback = true
        print("[ProceduralChatter] Normal conversation candidates exhausted; allowing seated fallback.")
    end

    -- Sort possible pairs by final score (lowest score first)
    if #selectedPairs > 0 then
        -- Diagnostics: Print candidates before sorting
        print(string.format("[ProceduralChatter] Candidates BEFORE sorting (%d total):", #selectedPairs))
        for idx, pair in ipairs(selectedPairs) do
            print(string.format("  [%d] %s <-> %s | dist=%.1f | inHistory=%s | score=%.1f",
                idx, pair.npc1.recordId, pair.npc2.recordId, pair.dist, tostring(pair.inHistory), pair.score))
        end

        table.sort(selectedPairs, function(a, b) return a.score < b.score end)
        
        -- Diagnostics: Print candidates after sorting
        print(string.format("[ProceduralChatter] Candidates AFTER sorting (best is index 1):"))
        for idx, pair in ipairs(selectedPairs) do
            print(string.format("  [%d] %s <-> %s | dist=%.1f | inHistory=%s | score=%.1f",
                idx, pair.npc1.recordId, pair.npc2.recordId, pair.dist, tostring(pair.inHistory), pair.score))
        end

        local best = selectedPairs[1]
        local npc1 = best.npc1
        local npc2 = best.npc2
        local isStatic1 = best.isStatic1
        local isStatic2 = best.isStatic2

        print(string.format("[ProceduralChatter] Starting conversation: %s <-> %s (dist=%.1f, inHistory=%s)",
            npc1.recordId, npc2.recordId, best.dist, tostring(best.inHistory)))
        
        local started = false
        if usingSeatedFallback or best.seatedFallback then
             started = ConversationManager.startConversation(npc1, npc2, walkArrivalDist, {
                 allowSeatedMover = true,
                 staticDistance = staticDist,
             })
        elseif isStatic1 and isStatic2 then
             started = ConversationManager.startConversation(npc1, npc2, nil, { staticDistance = staticDist })
        elseif isStatic1 then
             started = ConversationManager.startConversation(npc2, npc1, walkArrivalDist, { staticDistance = staticDist })
        else
             started = ConversationManager.startConversation(npc1, npc2, walkArrivalDist, { staticDistance = staticDist })
        end

        if started then
            addToHistory(npc1.id, npc2.id)
        end
        return
    end
    
    -- If no conversation started this scan, set a five second cooldown to prevent log spam
    if not ConversationManager.hasActive() then
        globalCooldown = 5.0
    end
end

local function onSave()
    return {}
end

local function onLoad(data)
    -- No data to restore for now
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onKeyPress = function(key)
            -- Debug: Press 'O' to stop activity / unequip props on targeted NPC
            if key.code == input.KEY.O then
                local pos = camera.getPosition()
                local res = nearby.castRay(pos, pos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 500)
                if res.hitObject and res.hitObject.type == types.NPC then
                    print(string.format("[ProceduralChatter] O-key stop activity on %s", res.hitObject.recordId))
                    res.hitObject:sendEvent("PC_TestUnequip", {})
                else
                    print("[ProceduralChatter] O-key raycast hit no NPC.")
                end
            end
        end,
        onQuestUpdate = function(questId, stage)
            -- Forward quest updates to the global scheduler so quest-locked NPCs
            -- are not displaced during active quest stages.
            core.sendGlobalEvent("PC_QuestUpdated", {})
            self:sendEvent("PC_CompanionQuestUpdate", {
                questId = questId,
                stage = stage or 0,
            })
        end,
    },
    eventHandlers = {
        PC_Arrived = ConversationManager.onArrived,
        PC_CancelAllConversations = function(data)
            ConversationManager.cancelAll(data and data.reason or "event")
        end,
        PC_ConversationWalkRejected = function(data)
            if ConversationManager.onConversationWalkRejected then
                ConversationManager.onConversationWalkRejected(data)
            end
        end,
        PC_ScheduleInterruptConversation = function(data)
            if not data or not data.npcId or not data.requestId then return end
            print(string.format("[ProceduralChatter] PC_ScheduleInterruptConversation npc=%s request=%s",
                tostring(data.npcId), tostring(data.requestId)))
            local started = ConversationManager.interruptForSchedule(data.npcId, data.requestId)
            if not started then
                print(string.format("[ProceduralChatter] schedule interrupt: no conversation, completing request=%s",
                    tostring(data.requestId)))
                core.sendGlobalEvent("PC_ScheduleInterruptComplete", {
                    npcId = data.npcId,
                    requestId = data.requestId,
                    immediate = true,
                })
            end
        end,
        PC_RequestNavmeshSnap = function(data)
            if not data or not data.requestId or not data.position then return end
            local snapped = nil
            pcall(function()
                snapped = nearby.findNearestNavMeshPosition(data.position, {
                    searchAreaHalfExtents = util.vector3(1500, 1500, 128),
                })
            end)
            core.sendGlobalEvent("PC_NavmeshSnapResolved", {
                requestId = data.requestId,
                snappedPosition = snapped or data.position,
            })
        end,
        PC_CombatStarted = function(data)
            if not data then return end
            local actor = data.actor
            local npcId = data.npcId or (actor and actor.id)
            print("Received PC_CombatStarted for: " .. tostring(actor and actor.recordId or npcId))
            ConversationManager.abortHostile(actor or npcId, npcId)
        end,
        PC_HostilityStarted = function(data)
            if not data then return end
            local actor = data.actor
            local npcId = data.npcId or (actor and actor.id)
            print("Received PC_HostilityStarted for: " .. tostring(actor and actor.recordId or npcId))
            ConversationManager.abortHostile(actor or npcId, npcId)
        end,
        UiModeChanged = function(data)
            if data and data.newMode then
                setWaitActive(isWaitRestMode(data.newMode))
                setDialogueActive(isDialogueMode(data.newMode))
            end
        end,
    }
}
