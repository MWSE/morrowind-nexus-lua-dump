-- CompanionDialogueManager.lua (Player script)
-- Companion-only voiced comments and companion-to-companion conversations.
-- Audio + floating + built-in subtitles only; never moves NPCs.

local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local originalPrint = print
_G.print = function(...)
    if ScheduleConfig.DEBUG_MODE then
        originalPrint(...)
    end
end

local core = require("openmw.core")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local storage = require("openmw.storage")
local vfs = require("openmw.vfs")

local CompanionDialogueLoader = require("scripts.ProceduralChatter.CompanionDialogueLoader")
local ConversationManager = require("scripts.ProceduralChatter.ConversationManager")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")

local settingsCompanion = storage.playerSection("02_Settings_Companion_Dialogue")
local settingsGeneral = storage.playerSection("01_Settings_Chatter_General")

local QUEST_TRIGGER_DELAY = 1.5
local LINE_GAP = 0.15
local COMPANION_NEAR_DIST = 2500

local randomTimer = 0
local startupTimer = 0
local currentRandomInterval = math.random(
    settingsCompanion:get("02_CompanionIntervalMin") or 30,
    settingsCompanion:get("03_CompanionIntervalMax") or 90
)

-- Silent placeholder audio files for text-only / no-asset installations.
-- core.sound.say needs an audio file to trigger engine subtitles;
-- these let us show subtitles even when no voice assets are present.
local SILENCE_DURATIONS = {2, 4, 6, 8, 10, 12, 14, 16, 18, 20}
local SILENCE_BASE_PATH = "Sound/Vo/ProceduralChatter/Silence/silent_"

local function getSilenceFile(duration)
    local best = SILENCE_DURATIONS[1]
    local bestDiff = math.abs(best - duration)
    for _, d in ipairs(SILENCE_DURATIONS) do
        local diff = math.abs(d - duration)
        if diff < bestDiff then
            best = d
            bestDiff = diff
        end
    end
    local path = SILENCE_BASE_PATH .. string.format("%02d", best) .. ".mp3"
    if vfs.fileExists(path) then
        return path
    end
    return nil
end

local activePlayback = nil  -- { entry, lineIndex, waitTimer, actorsById }
local pendingTriggers = {}  -- { entry, ctx, fireAt }

local playedStore = storage.playerSection("PC_CompanionDialoguePlayed")
local cooldownStore = storage.playerSection("PC_CompanionDialogueCooldowns")
local cooldowns = nil

local function normalizeId(id)
    return id and string.lower(tostring(id)) or ""
end

local function isEnabled()
    return settingsCompanion:get("01_CompanionDialogueEnabled") ~= false
end

local function getSubtitleMode()
    local raw = settingsCompanion:get("04_CompanionSubtitleMode")
    if type(raw) ~= "string" then return "both" end
    local mode = string.lower(raw)
    if mode == "none" or mode == "regular" or mode == "floating" or mode == "both" then
        return mode
    end
    return "both"
end

local function estimateDuration(text)
    if not text or text == "" then return 3.0 end
    return (#text * 0.085) + 0.5
end

local function getLineDuration(line)
    if line.duration and line.duration > 0 then
        return line.duration
    end
    return estimateDuration(line.text)
end

local function getPlayedSet()
    local played = playedStore:get("ids")
    if type(played) ~= "table" then
        played = {}
        playedStore:set("ids", played)
    end
    return played
end

local function markPlayed(entryId)
    local played = getPlayedSet()
    played[entryId] = true
    playedStore:set("ids", played)
end

local function wasPlayed(entryId)
    return getPlayedSet()[entryId] == true
end

local function getCooldownKey(entryId)
    return "cd_" .. tostring(entryId)
end

local function getCooldownTable()
    if type(cooldowns) == "table" then
        return cooldowns
    end

    local stored = cooldownStore:get("entries")
    if type(stored) ~= "table" then
        stored = {}
        cooldownStore:set("entries", stored)
    end

    cooldowns = stored
    return cooldowns
end

local function getRepeatCooldownGameSeconds()
    local hours = settingsCompanion:get("05_CompanionRepeatCooldownHours")
    if type(hours) ~= "number" then
        hours = 24
    end
    if hours < 0 then hours = 0 end
    return hours * 3600
end

local function isOnCooldown(entryId)
    local key = getCooldownKey(entryId)
    local cooldownTable = getCooldownTable()
    local lastPlayed = cooldownTable[key]
    if not lastPlayed then
        return false
    end
    local cooldownGameSeconds = getRepeatCooldownGameSeconds()
    local elapsed = core.getGameTime() - lastPlayed
    local onCooldown = elapsed < cooldownGameSeconds
    print(string.format("[CompanionDialogue] COOLDOWN CHECK '%s' elapsed=%.0f/%d gameSeconds onCooldown=%s",
        tostring(entryId), elapsed, cooldownGameSeconds, tostring(onCooldown)))
    if not onCooldown then
        cooldownTable[key] = nil
        cooldownStore:set("entries", cooldownTable)
    end
    return onCooldown
end

local function setCooldown(entryId)
    local key = getCooldownKey(entryId)
    local t = core.getGameTime()
    local cooldownTable = getCooldownTable()
    cooldownTable[key] = t
    cooldownStore:set("entries", cooldownTable)
    print(string.format("[CompanionDialogue] COOLDOWN SET '%s' at gameTime=%.0f", tostring(entryId), t))
end

local function canPlayEntry(entry)
    if not entry or not entry.id then return false end
    if entry.repeatable == false and wasPlayed(entry.id) then return false end
    if isOnCooldown(entry.id) then return false end
    return true
end

local function resolveActor(recordId)
    local norm = normalizeId(recordId)
    if norm == "" then return nil end
    for _, actor in ipairs(nearby.actors) do
        if types.NPC.objectIsInstance(actor) and not types.Actor.isDead(actor) then
            if normalizeId(actor.recordId) == norm then
                return actor
            end
        end
    end
    return nil
end

local fduChecked = false

local function collectPresentCompanions()
    local list = {}
    local totalActors = 0
    local liveFollowerCount = 0
    for _, actor in ipairs(nearby.actors) do
        if types.NPC.objectIsInstance(actor) and not types.Actor.isDead(actor) then
            totalActors = totalActors + 1
            if CompanionDialogueLoader.isLiveFollower(actor) then
                liveFollowerCount = liveFollowerCount + 1
                local dist = (actor.position - self.position):length()
                if dist <= COMPANION_NEAR_DIST then
                    table.insert(list, actor)
                else
                    print(string.format("[CompanionDialogue] Live follower %s too far (%.1f > %d)", actor.recordId, dist, COMPANION_NEAR_DIST))
                end
            end
        end
    end
    if not fduChecked then
        fduChecked = true
        local I = require("openmw.interfaces")
        local fduAvail = I.FollowerDetectionUtil ~= nil
        local fduVersion = fduAvail and I.FollowerDetectionUtil.version or "nil"
        print(string.format("[CompanionDialogue] FDU available=%s version=%s totalNPCs=%d liveFollowers=%d nearEnough=%d",
            tostring(fduAvail), tostring(fduVersion), totalActors, liveFollowerCount, #list))
    else
        print(string.format("[CompanionDialogue] collectPresentCompanions: totalNPCs=%d liveFollowers=%d nearEnough=%d", totalActors, liveFollowerCount, #list))
    end
    return list
end

local function entryRequirementsPass(entry, primaryActor, secondaryActor)
    if not entry.requirements then return true end
    if not primaryActor then return false end
    return ConversationManager.checkRequirements(primaryActor, secondaryActor, entry.requirements)
end

local function questTriggerMatches(triggerQuest, questId, stage)
    if not triggerQuest or not triggerQuest.id then return false end
    if triggerQuest.id ~= questId then return false end
    if triggerQuest.stage ~= nil then
        return stage == triggerQuest.stage
    end
    if triggerQuest.min ~= nil and stage < triggerQuest.min then return false end
    if triggerQuest.max ~= nil and stage >= triggerQuest.max then return false end
    return true
end

local function cellTriggerMatches(triggerCell, cellName)
    if not triggerCell or triggerCell == "" then return false end
    if not cellName or cellName == "" then return false end
    return string.find(string.lower(cellName), string.lower(triggerCell), 1, true) ~= nil
end

local function triggerMatches(entry, ctx)
    if not entry or not entry.trigger or not ctx then return false end
    local trigger = entry.trigger
    local questOk = trigger.quest == nil
    local cellOk = trigger.cell == nil
    if trigger.quest then
        questOk = questTriggerMatches(trigger.quest, ctx.questId, ctx.stage)
    end
    if trigger.cell then
        cellOk = cellTriggerMatches(trigger.cell, ctx.cellName)
    end
    return questOk and cellOk
end

local function resolveConversationActors(entry)
    local actorsById = {}
    local participants = entry.participants or {}
    if #participants == 0 then return nil end
    for _, pid in ipairs(participants) do
        -- Every participant must be present AND actively in the party
        if not CompanionDialogueLoader.isLiveFollower(pid) then
            return nil
        end
        local actor = resolveActor(pid)
        if not actor then return nil end
        actorsById[normalizeId(pid)] = actor
    end
    return actorsById
end

local function playLine(actor, line)
    if not actor or not line then return 0 end
    local text = line.text or ""
    local sound = line.sound
    local duration = getLineDuration(line)
    local mode = getSubtitleMode()
    local audioEnabled = settingsGeneral:get("02_AudioEnabled") ~= false

    if mode == "floating" or mode == "both" then
        self:sendEvent("ProceduralChatter_ShowSubtitle", {
            actor = actor,
            text = text,
            duration = duration,
            companionDialogue = true,
        })
    end

    local subtitleText = text
    if mode == "floating" or mode == "none" then
        subtitleText = ""
    end

    local fileToPlay = nil
    if sound and audioEnabled and vfs.fileExists(sound) then
        fileToPlay = sound
    elseif mode == "regular" or mode == "both" then
        -- No real audio available, but engine subtitles are requested.
        -- Use a silent placeholder so core.sound.say still triggers subtitles.
        fileToPlay = getSilenceFile(duration)
        if not fileToPlay and sound and audioEnabled then
            print(string.format("[CompanionDialogue] Missing sound file: %s", sound))
        end
    elseif sound and audioEnabled then
        print(string.format("[CompanionDialogue] Missing sound file: %s", sound))
    end

    if fileToPlay then
        actor:sendEvent("PC_Say", { file = fileToPlay, text = subtitleText })
    end

    return duration
end

local function stopPlayback()
    activePlayback = nil
end

local function startPlayback(entry, actorsById)
    if not entry or not entry.lines or #entry.lines == 0 then return false end
    activePlayback = {
        entry = entry,
        lineIndex = 1,
        waitTimer = 0,
        actorsById = actorsById or {},
    }
    local line = entry.lines[1]
    local speaker = resolveActor(line.speaker)
        or actorsById[normalizeId(line.speaker)]
        or actorsById[normalizeId(entry.companionId)]
    if not speaker then
        stopPlayback()
        return false
    end
    activePlayback.waitTimer = playLine(speaker, line) + LINE_GAP
    if entry.repeatable == false then
        markPlayed(entry.id)
    end
    setCooldown(entry.id)
    print(string.format("[CompanionDialogue] Playing entry '%s' (line 1/%d)", entry.id, #entry.lines))
    return true
end

local function tryStartEntry(entry, ctx)
    print(string.format("[CompanionDialogue] tryStartEntry '%s' type=%s", tostring(entry and entry.id), tostring(entry and entry.type)))
    if not isEnabled() then
        print("[CompanionDialogue] tryStartEntry ABORT: disabled")
        return false
    end
    if activePlayback then
        print("[CompanionDialogue] tryStartEntry ABORT: activePlayback in progress")
        return false
    end
    if not canPlayEntry(entry) then
        print(string.format("[CompanionDialogue] tryStartEntry ABORT: entry '%s' not playable (played=%s)", tostring(entry.id), tostring(wasPlayed(entry.id))))
        return false
    end
    if ctx and entry.trigger and not triggerMatches(entry, ctx) then
        print("[CompanionDialogue] tryStartEntry ABORT: trigger mismatch")
        return false
    end

    local entryType = entry.type or "comment"
    local primaryActor = resolveActor(entry.companionId)
    local secondaryActor = nil
    local actorsById = {}

    -- Primary companion must be actively in the party
    if not CompanionDialogueLoader.isLiveFollower(entry.companionId) then
        print(string.format("[CompanionDialogue] tryStartEntry ABORT: companion '%s' is not a live follower", tostring(entry.companionId)))
        return false
    end

    if entryType == "conversation" then
        actorsById = resolveConversationActors(entry)
        if not actorsById then
            print("[CompanionDialogue] tryStartEntry ABORT: conversation actors missing")
            return false
        end
        primaryActor = actorsById[normalizeId(entry.companionId)] or resolveActor(entry.companionId)
        local parts = entry.participants or {}
        if #parts >= 2 then
            secondaryActor = actorsById[normalizeId(parts[2])]
        end
    else
        if not primaryActor then
            print(string.format("[CompanionDialogue] tryStartEntry ABORT: primary actor '%s' not resolved", tostring(entry.companionId)))
            return false
        end
        actorsById[normalizeId(entry.companionId)] = primaryActor
    end

    if not entryRequirementsPass(entry, primaryActor, secondaryActor) then
        print("[CompanionDialogue] tryStartEntry ABORT: requirements failed")
        return false
    end

    print(string.format("[CompanionDialogue] tryStartEntry SUCCESS: starting '%s'", entry.id))
    return startPlayback(entry, actorsById)
end

local function queueTrigger(entry, ctx)
    table.insert(pendingTriggers, {
        entry = entry,
        ctx = ctx,
        fireAt = core.getSimulationTime() + QUEST_TRIGGER_DELAY,
    })
end

local function processQuestTriggers(data)
    if not isEnabled() then return end
    for _, entry in ipairs(CompanionDialogueLoader.getAllEntries()) do
        if entry.trigger and entry.trigger.quest and canPlayEntry(entry) then
            if questTriggerMatches(entry.trigger.quest, data.questId, data.stage) then
                -- Only queue if the primary companion is present/loaded and actively in the party
                local primary = resolveActor(entry.companionId)
                if primary and CompanionDialogueLoader.isLiveFollower(entry.companionId) then
                    queueTrigger(entry, data)
                end
            end
        end
    end
end

local function processCellTriggers(data)
    if not isEnabled() or activePlayback then return end
    for _, entry in ipairs(CompanionDialogueLoader.getAllEntries()) do
        if entry.trigger and entry.trigger.cell and canPlayEntry(entry) then
            if cellTriggerMatches(entry.trigger.cell, data.cellName) then
                if tryStartEntry(entry, { cellName = data.cellName }) then
                    return
                end
            end
        end
    end
end

local function pickRandomEntry()
    local companions = collectPresentCompanions()
    if #companions == 0 then
        print("[CompanionDialogue] pickRandomEntry: no present companions")
        return nil
    end

    local companion = companions[math.random(#companions)]
    local normId = normalizeId(companion.recordId)
    print(string.format("[CompanionDialogue] Picked companion %s for random entry", normId))
    local candidates = {}

    local entries = CompanionDialogueLoader.getEntriesForCompanion(normId)
    print(string.format("[CompanionDialogue] %s has %d total entries", normId, #entries))
    for _, entry in ipairs(entries) do
        local hasTrigger = entry.trigger ~= nil
        local playable = canPlayEntry(entry)
        local reqsPass = entryRequirementsPass(entry, companion, nil)
        if not hasTrigger and playable and reqsPass then
            table.insert(candidates, entry)
        else
            print(string.format("[CompanionDialogue] SKIP entry %s (trigger=%s playable=%s reqs=%s)", tostring(entry.id), tostring(hasTrigger), tostring(playable), tostring(reqsPass)))
        end
    end

    print(string.format("[CompanionDialogue] %d candidates for %s", #candidates, normId))
    if #candidates == 0 then return nil end
    return candidates[math.random(#candidates)]
end

local startupCompleteLogged = false
local disabledCacheCleared = false

local function onRandomTick()
    print("[CompanionDialogue] onRandomTick fired")
    if not isEnabled() then
        print("[CompanionDialogue] onRandomTick ABORT: disabled")
        return
    end
    if activePlayback then
        print("[CompanionDialogue] onRandomTick ABORT: activePlayback in progress")
        return
    end
    local entry = pickRandomEntry()
    if entry then
        tryStartEntry(entry, nil)
    else
        print("[CompanionDialogue] onRandomTick: no entry picked")
    end
end

local statusLogTimer = 0

local function onUpdate(dt)
    if not isEnabled() then
        if activePlayback then
            stopPlayback()
        end
        pendingTriggers = {}
        startupCompleteLogged = false
        if not disabledCacheCleared then
            CompanionDialogueLoader.clearDeclaredCache()
            disabledCacheCleared = true
        end
        return
    end

    disabledCacheCleared = false
    CompanionDialogueLoader.ensureLoaded()
    startupTimer = startupTimer + dt
    if startupTimer < 3.0 then
        return
    end
    if not startupCompleteLogged then
        startupCompleteLogged = true
        print("[CompanionDialogue] Startup complete. Random dialogue active.")
    end
    local randomIntervalMin = settingsCompanion:get("02_CompanionIntervalMin") or 30
    local randomIntervalMax = settingsCompanion:get("03_CompanionIntervalMax") or 90
    randomTimer = randomTimer + dt

    statusLogTimer = statusLogTimer + dt
    if statusLogTimer >= 5.0 then
        statusLogTimer = 0
        print(string.format("[CompanionDialogue] status randomTimer=%.1f/%d activePlayback=%s pending=%d",
            randomTimer, currentRandomInterval, tostring(activePlayback ~= nil), #pendingTriggers))
    end

    if randomTimer >= currentRandomInterval then
        randomTimer = 0
        currentRandomInterval = math.random(randomIntervalMin, randomIntervalMax)
        print(string.format("[CompanionDialogue] Random tick interval reached (next in %ds)", currentRandomInterval))
        onRandomTick()
    end

    local now = core.getSimulationTime()
    for i = #pendingTriggers, 1, -1 do
        local pending = pendingTriggers[i]
        if now >= pending.fireAt then
            if not activePlayback then
                table.remove(pendingTriggers, i)
                tryStartEntry(pending.entry, pending.ctx)
            end
        end
    end

    if activePlayback then
        activePlayback.waitTimer = activePlayback.waitTimer - dt
        if activePlayback.waitTimer <= 0 then
            local entry = activePlayback.entry
            local nextIndex = activePlayback.lineIndex + 1
            if nextIndex > #entry.lines then
                stopPlayback()
            else
                activePlayback.lineIndex = nextIndex
                local line = entry.lines[nextIndex]
                local speaker = resolveActor(line.speaker)
                    or activePlayback.actorsById[normalizeId(line.speaker)]
                    or activePlayback.actorsById[normalizeId(entry.companionId)]
                if speaker then
                    activePlayback.waitTimer = playLine(speaker, line) + LINE_GAP
                else
                    stopPlayback()
                end
            end
        end
    end
end

local function onQuestUpdate(data)
    if not data or not data.questId then return end
    processQuestTriggers(data)
end

local function onCellEntered(data)
    if not data or not data.cellName then return end
    processCellTriggers(data)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        PC_CompanionQuestUpdate = onQuestUpdate,
        PC_CompanionCellEntered = onCellEntered,
    },
}
