local core = require("openmw.core")
local types = require("openmw.types")
-- VoiceManager requires openmw.self, so it fails in Global scripts. Use pcall.
local VoiceManager
pcall(function() VoiceManager = require("scripts.ProceduralChatter.VoiceManager") end)
local Library = require("scripts.ProceduralChatter.data.ConversationLibrary")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local RegionResolver = require("scripts.ProceduralChatter.RegionResolver")
local TimeService = require("scripts.ProceduralChatter.TimeService")
local NPCState = require("scripts.ProceduralChatter.NPCState")
local Relocator -- Lazy required below
local SittingGlobal -- Lazy required below

local ConversationManager = {}

-- Configuration
ConversationManager.ServiceNPCsStatic = true -- Toggle: Service providers don't walk

local storage = require("openmw.storage")
-- playerSection is only available in player scripts; guard for global script safety.
local okSettings, settingsGroup = pcall(function()
    return storage.playerSection("01_Settings_Chatter_General")
end)
if not okSettings or not settingsGroup then
    settingsGroup = { get = function(_) return false end }
end

local okLineCooldownStore, lineCooldownStore = pcall(function()
    return storage.playerSection("PC_ProceduralChatterLineCooldowns")
end)
if not okLineCooldownStore then
    lineCooldownStore = nil
end
local lineCooldowns = nil

-- Helper: Verbose Log
local function verboseLog(msg)
    if settingsGroup:get("VerboseLogging") then
        print(msg)
    end
end

local function getLineCooldownTable()
    if type(lineCooldowns) == "table" then
        return lineCooldowns
    end

    if lineCooldownStore then
        local stored = lineCooldownStore:get("entries")
        if type(stored) == "table" then
            lineCooldowns = stored
            return lineCooldowns
        end
    end

    lineCooldowns = {}
    if lineCooldownStore then
        lineCooldownStore:set("entries", lineCooldowns)
    end
    return lineCooldowns
end

local function getLineCooldownKey(line)
    if not line then return nil end
    local id = line.id or line.lineId or line.text
    if not id or id == "" then return nil end
    return "line_" .. tostring(id)
end

local function getLineRepeatCooldownGameSeconds()
    local hours = settingsGroup:get("13_LineRepeatCooldownHours")
    if type(hours) ~= "number" then hours = 24 end
    if hours < 0 then hours = 0 end
    return hours * 3600
end

local function copyAnimationSpec(spec)
    if type(spec) ~= "table" then return nil end
    local copy = {}
    for k, v in pairs(spec) do copy[k] = v end
    return copy
end

local function resolveAnimationSpec(line, defaultTemplate)
    local spec = line and line.animation
    if type(spec) ~= "table" and defaultTemplate then
        spec = { template = defaultTemplate }
    end
    if type(spec) ~= "table" then return nil end

    if spec.anim then
        return copyAnimationSpec(spec)
    end

    local templateName = spec.template
    if type(templateName) ~= "string" or templateName == "" then return nil end

    local templates = Library.AnimationTemplates or {}
    local pool = templates[templateName]
    if type(pool) ~= "table" or #pool == 0 then
        print(string.format("[ConversationManager] WARNING: animation template '%s' not found", templateName))
        return nil
    end

    return copyAnimationSpec(pool[math.random(#pool)])
end

local function playConversationAnimation(actor, line, defaultTemplate)
    if not actor then return end
    local spec = resolveAnimationSpec(line, defaultTemplate)
    if not spec or not spec.anim then return end

    pcall(function()
        actor:sendEvent("PC_PlayConversationAnimation", {
            anim = spec.anim,
            mask = spec.mask,
            priority = spec.priority,
            loops = spec.loops,
            forceLoop = spec.forceLoop,
            blendDuration = spec.blendDuration,
        })
    end)
end

local function isLineOnCooldown(line)
    local key = getLineCooldownKey(line)
    if not key then return false end

    local cooldownSeconds = getLineRepeatCooldownGameSeconds()
    if cooldownSeconds <= 0 then return false end

    local cooldownTable = getLineCooldownTable()
    local lastPlayed = cooldownTable[key]
    if not lastPlayed then return false end

    local elapsed = core.getGameTime() - lastPlayed
    local onCooldown = elapsed < cooldownSeconds
    if not onCooldown then
        cooldownTable[key] = nil
        if lineCooldownStore then
            lineCooldownStore:set("entries", cooldownTable)
        end
    end
    return onCooldown
end

local function setLineCooldown(line)
    local key = getLineCooldownKey(line)
    if not key then return end

    local cooldownTable = getLineCooldownTable()
    cooldownTable[key] = core.getGameTime()
    if lineCooldownStore then
        lineCooldownStore:set("entries", cooldownTable)
    end
end

local function pickAvailableLine(candidates)
    local available = {}
    for _, line in ipairs(candidates) do
        if not isLineOnCooldown(line) then
            table.insert(available, line)
        end
    end
    if #available == 0 then return nil end
    local picked = available[math.random(#available)]
    setLineCooldown(picked)
    return picked
end

-- State storage
local activeConversations = {}
local lastEndedWithoutPlayback = nil
local dialogueMenuActive = false
local SIT_STAND_COOLDOWN_SECONDS = 60
local CONVERSATION_HEARTBEAT_INTERVAL = 5.0
local MOVING_CONVERSATION_TIMEOUT = 12.0

local function sendConversationHeartbeat(conv, force)
    if not conv or not conv.initiatorId or not conv.targetId then return end
    local now = core.getSimulationTime()
    if not force and conv.lastHeartbeatTime and (now - conv.lastHeartbeatTime) < CONVERSATION_HEARTBEAT_INTERVAL then
        return
    end
    conv.lastHeartbeatTime = now
    core.sendGlobalEvent("PC_ConversationHeartbeat", {
        initiatorId = conv.initiatorId,
        targetId = conv.targetId,
    })
end

local function isSeatingInProgress(actor)
    if not actor or not actor.id then return false end
    if not SittingGlobal then
        pcall(function() SittingGlobal = require("scripts.ProceduralChatter.SittingGlobal") end)
    end
    return SittingGlobal and SittingGlobal.isSeatingInProgress
        and SittingGlobal.isSeatingInProgress(actor.id)
end

local function getRelocator()
    if not Relocator then
        pcall(function() Relocator = require("scripts.ProceduralChatter.schedule.Relocator") end)
    end
    return Relocator
end

local function isActorValid(actor)
    local ok, valid = pcall(function()
        return actor and actor:isValid()
    end)
    return ok and valid == true
end

local function isActorEnabled(actor)
    local ok, enabled = pcall(function()
        return actor and actor.enabled
    end)
    return ok and enabled == true
end

local function isRelocating(actor)
    if not actor or not actor.id then return false end
    if NPCState.isInTransit(actor.id) then return true end
    local relocator = getRelocator()
    if not relocator then return false end
    if relocator.isInTransit and relocator.isInTransit(actor.id) then return true end
    if relocator.isQueued and relocator.isQueued(actor.id) then return true end
    if relocator.isDeparting and relocator.isDeparting(actor.id) then return true end
    if relocator.hasPendingArrivalWalk and relocator.hasPendingArrivalWalk(actor.id) then return true end
    if relocator.isFinishingArrival and relocator.isFinishingArrival(actor.id) then return true end
    return false
end

-- Player script cannot write global storage; route clears through global.lua.
local function releaseConversationNpcState(npcId)
    if not npcId then return end
    core.sendGlobalEvent("PC_ClearConversationState", { npcId = npcId })
end

local function canStartConversation(actor)
    return isActorValid(actor)
        and isActorEnabled(actor)
        and not isRelocating(actor)
        and not Blacklist.isConversationBlacklisted(actor)
        and NPCState.canConverse(actor.id)
end

local function abortIfHostile(conv, context)
    if not conv then return true end
    local initHostile = conv.initiatorId and NPCState.isHostile(conv.initiatorId)
    local targetHostile = conv.targetId and NPCState.isHostile(conv.targetId)
    if not initHostile and not targetHostile then return false end

    print(string.format("[ConversationManager] Aborting %s conversation because participant became hostile (initiator=%s target=%s)",
        tostring(context or "active"), tostring(initHostile), tostring(targetHostile)))
    local skipReturnIds = {}
    if initHostile and conv.initiatorId then skipReturnIds[conv.initiatorId] = true end
    if targetHostile and conv.targetId then skipReturnIds[conv.targetId] = true end
    ConversationManager.endConversation(conv, { skipReturnIds = skipReturnIds })
    return true
end

function ConversationManager.setDialogueMenuActive(active)
    dialogueMenuActive = active
end

function ConversationManager.canStartConversation(actor)
    return canStartConversation(actor)
end

function ConversationManager.consumeLastEndedWithoutPlayback()
    local ended = lastEndedWithoutPlayback
    lastEndedWithoutPlayback = nil
    return ended
end

local function canSendConversationCleanup(actor)
    return isActorValid(actor)
        and isActorEnabled(actor)
        and not isRelocating(actor)
        and not NPCState.isPendingSleep(actor.id)
        and not NPCState.isSleeping(actor.id)
end

local function actorLooksSitting(actor)
    if not actor then return false end
    if actor.id and NPCState.isSitting(actor.id) then return true end
    local okAnim, anim = pcall(function() return require('openmw.animation') end)
    if not okAnim or not anim then return false end
    local ok, sitting = pcall(function()
        return anim.isPlaying(actor, 'sdpvasitting6')
            or anim.isPlaying(actor, 'pcdbssit5')
            or anim.isPlaying(actor, 'dbssit5')
            or anim.isPlaying(actor, 'dbssit6')
            or anim.isPlaying(actor, 'sitidle1')
            or anim.isPlaying(actor, 'IdleSit')
            or anim.isPlaying(actor, 'ChairSit01')
    end)
    return ok and sitting == true
end

-- IDs that should never walk to another NPC for conversation.
-- Use conversationTravelBanIds in Blacklist JSON for travel-bans;
-- this table is for IDs that should not initiate walk-to at all.
local BLACKLIST_IDS = {
}

-- Helper: Guard Check
local function isGuardActor(actor)
    if not actor then return false end
    local ok, result = pcall(function()
        local record = types.NPC.record(actor)
        if not record then return false end
        local cls = string.lower(record.class or "")
        local name = string.lower(record.name or "")
        if cls == "guard" or string.find(name, "guard") then return true end
        return false
    end)
    if not ok then return false end
    return result
end

local function hasUniqueConversationBetween(actor1, actor2)
    if not Library or not Library.UniqueConversations or not actor1 or not actor2 then return false end
    local id1 = string.lower(actor1.recordId or "")
    local id2 = string.lower(actor2.recordId or "")
    if Library.UniqueConversations[id1] and Library.UniqueConversations[id1][id2] then return true end
    if Library.UniqueConversations[id2] and Library.UniqueConversations[id2][id1] then return true end
    return false
end

-- Guard exclusion: guards can only speak snippets that explicitly allow guards.
-- Unique conversations are exempt (identified by their ID in Library.UniqueSnippets).
-- This should ONLY be called at snippet-selection time (findBestSnippet), not
-- at line-selection time, because lines inherit the snippet's guard permission.
local function guardCheckAllowed(snippetId, actor, reqs)
    if not snippetId then return true end
    local isUnique = Library.UniqueSnippets and Library.UniqueSnippets[snippetId]
    if isUnique then return true end
    if not isGuardActor(actor) then return true end
    if reqs and reqs.class then
        if type(reqs.class) == "string" and string.lower(reqs.class) == "guard" then
            return true
        elseif type(reqs.class) == "table" then
            for _, c in ipairs(reqs.class) do
                if string.lower(tostring(c)) == "guard" then
                    return true
                end
            end
        end
    end
    return false
end

local function guardPairCheckAllowed(snippetId, speaker, listener, reqs)
    if not guardCheckAllowed(snippetId, speaker, reqs) then return false end
    if not guardCheckAllowed(snippetId, listener, reqs and reqs.target) then return false end
    return true
end

-- Helper: Faction Leader Check (Ported from SittingLogic)
local function isFactionLeader(actor)
    -- Requires access to core.factions (available in player/global scripts usually)
    if not (core.factions and core.factions.records) then return false end

    local factionIds = types.NPC.getFactions(actor)
    if not factionIds then return false end

    for _, factionId in ipairs(factionIds) do
        local factionRec = core.factions.records[factionId] or core.factions.records[string.lower(factionId)]
        if factionRec and factionRec.ranks then
            local maxRank = #factionRec.ranks
            -- types.NPC.getFactionRank requires object? Yes, actor.
            local ok, rank = pcall(types.NPC.getFactionRank, actor, factionId)
            if ok and rank == maxRank and rank > 0 then
                return true
            end
        end
    end
    return false
end

-- Helper: Check Player Quest Stage (works in player or global script context)
local function getPlayerQuestStage(questId)
    local ok, stage = pcall(function()
        local world = require("openmw.world")
        local player = world.players[1]
        local quests = types.Player.quests(player)
        local q = quests and quests[questId]
        return q and q.stage or 0
    end)
    if ok then return stage end
    
    local ok2, stage2 = pcall(function()
        local self = require("openmw.self")
        local quests = types.Player.quests(self)
        local q = quests and quests[questId]
        return q and q.stage or 0
    end)
    if ok2 then return stage2 end
    
    return nil
end

-- Helper: Walk Blacklist Check (Ported from SittingLogic + Request)
function ConversationManager.isWalkBlacklisted(actor)
    if not actor then return false end
    local rec = types.NPC.record(actor)
    if not rec then return false end

    -- 0. NPCs that cannot walk to a target are walk-blacklisted.
    if not NPCState.canWalkTo(actor.id) then return true end

    -- 1. Explicit ID Check
    if BLACKLIST_IDS[string.lower(rec.id)] then return true end

    -- 2. Class Check + Conversation Travel Ban
    local cls = string.lower(rec.class)
    if cls == "publican" or cls == "trainer" or cls == "finer clothier" or cls == "monk" then return true end

    local Blacklist = require("scripts.ProceduralChatter.Blacklist")
    if Blacklist.isConversationTravelBanned(actor) then return true end

    -- 3. Services Check
    if rec.servicesOffered then
        local offersServices = rec.servicesOffered.Travel or 
                               rec.servicesOffered.Barter or 
                               rec.servicesOffered.Training or 
                               rec.servicesOffered.Enchanting or 
                               rec.servicesOffered.Spellmaking or 
                               rec.servicesOffered.Repair
        
        if offersServices then
            verboseLog(string.format("[ProceduralChatter] Blacklisting merchant/service-provider '%s' from traveling to converse (Train=%s, Barter=%s, TravelService=%s)",
                rec.name, tostring(rec.servicesOffered.Training), tostring(rec.servicesOffered.Barter), tostring(rec.servicesOffered.Travel)))
            return true
        end
    end

    -- 4. Travel Destinations (Caravaners/Shipmasters)
    if rec.travelDestinations and #rec.travelDestinations > 0 then return true end

    -- 5. Faction Leader Check
    if isFactionLeader(actor) then return true end

    return false
end



-- Helper: Check Requirements
function ConversationManager.checkRequirements(actor, target, reqs, debugId, forceLog)
    if not reqs then return true end
    local debugPrefix = debugId and ("[DEBUG] Checking " .. debugId .. ": ") or ""
    
    local function logReq(msg)
        if forceLog or settingsGroup:get("VerboseLogging") then
            print(msg)
        end
    end

    local actorRecord = types.NPC.record(actor)

    -- Blacklist (per-snippet NPC exclusion)
    if reqs.blacklist then
        local actorId = string.lower(actor.recordId or "")
        local blList = type(reqs.blacklist) == "table" and reqs.blacklist or {reqs.blacklist}
        for _, blEntry in ipairs(blList) do
            if actorId == string.lower(blEntry) then
                logReq(debugPrefix .. "Rejected (Blacklist): " .. tostring(actor.recordId))
                return false
            end
        end
    end
    
    -- Race (supports ! prefix for negation, e.g., "!dark elf" means NOT dark elf)
    -- Also supports arrays for OR logic: {"dark elf", "wood elf"} or {"!imperial"}
    if reqs.race then
        local reqRaces = type(reqs.race) == "table" and reqs.race or {reqs.race}
        local actorRace = string.lower(actorRecord.race)
        local hasPositive = false
        local matchedPositive = false

        for _, reqRace in ipairs(reqRaces) do
            local negate = false
            if reqRace:sub(1,1) == "!" then
                negate = true
                reqRace = reqRace:sub(2)
            else
                hasPositive = true
            end

            local targetRace = string.lower(reqRace)
            local matches = (actorRace == targetRace)

            if negate then
                if matches then
                    logReq(debugPrefix .. "Rejected (Race Negation Match): " .. tostring(actorRecord.race) .. " is excluded by !" .. reqRace)
                    return false
                end
            else
                if matches then
                    matchedPositive = true
                end
            end
        end

        if hasPositive and not matchedPositive then
            logReq(debugPrefix .. "Rejected (Race Mismatch): " .. tostring(actorRecord.race) .. " vs " .. table.concat(reqRaces, ", "))
            return false
        end
    end
    
    -- Gender
    local isMale = actorRecord.isMale
    if reqs.gender == "m" and not isMale then 
        logReq(debugPrefix .. "Rejected (Gender Mismatch: Expected Male)")
        return false 
    end
    if reqs.gender == "f" and isMale then 
        logReq(debugPrefix .. "Rejected (Gender Mismatch: Expected Female)")
        return false 
    end

    -- Race/Sex Pairs (OR logic: actor must match at least one pair)
    -- e.g. raceSexPairs = { {race = "dark elf"}, {race = "imperial", gender = "m"} }
    if reqs.raceSexPairs then
        local actorRace = string.lower(actorRecord.race)
        local matched = false
        for _, pair in ipairs(reqs.raceSexPairs) do
            local raceMatch = true
            local genderMatch = true
            if pair.race then
                raceMatch = (actorRace == string.lower(pair.race))
            end
            if pair.gender then
                if pair.gender == "m" then
                    genderMatch = isMale
                elseif pair.gender == "f" then
                    genderMatch = not isMale
                end
            end
            if raceMatch and genderMatch then
                matched = true
                break
            end
        end
        if not matched then
            logReq(debugPrefix .. "Rejected (Race/Sex Pair Mismatch): " .. tostring(actorRecord.race) .. " " .. (isMale and "m" or "f"))
            return false
        end
    end
    
    -- Class Check
    if reqs.class then
        -- Normalize Actor Class: Lowercase and Trim
        local actorClass = string.lower(actorRecord.class):gsub("^%s*(.-)%s*$", "%1")
        
        local requiredClasses = type(reqs.class) == "table" and reqs.class or {reqs.class}
        local passed = false
        
        for _, rawReq in ipairs(requiredClasses) do
            -- Normalize Req Class: Lowercase and Trim
            local reqClass = string.lower(rawReq):gsub("^%s*(.-)%s*$", "%1")
            
            -- User Request: "Commoner" tag acts as Generic/Fallback
            if reqClass == "commoner" then
                passed = true
                break
            
            -- User Request: "Thief" requirement satisfied by "Thieves Guild" membership
            elseif reqClass == "thief" and actorRecord.factions and actorRecord.factions["Thieves Guild"] then
                 passed = true
                 break
            
            elseif actorClass == reqClass then
                passed = true
                break
            end
        end
        
        if not passed then 
            local reqStr = table.concat(requiredClasses, ", ")
            logReq(debugPrefix .. "Rejected (Class Mismatch): Actor='" .. actorClass .. "' vs Required='" .. reqStr .. "'")
            return false 
        end
    end
    
    -- Faction Check
    if reqs.faction then
        local factionList = reqs.faction
        local isArray = type(factionList) == "table"
        if not isArray then
            factionList = { factionList }
        end

        local actorFactions = types.NPC.record(actor).factions
        local hasPositive = false
        local matchedPositive = false

        for _, fEntry in ipairs(factionList) do
            local targetFaction = fEntry
            local invert = false
            if string.sub(targetFaction, 1, 1) == "!" then
                targetFaction = string.sub(targetFaction, 2)
                invert = true
            else
                hasPositive = true
            end

            -- Check if actor is in this faction
            local rank = nil
            if actorFactions and actorFactions[targetFaction] then
                rank = actorFactions[targetFaction]
            else
                if actorFactions then
                    local targetLower = string.lower(targetFaction)
                    for fId, fRank in pairs(actorFactions) do
                        if string.lower(fId) == targetLower then
                            rank = fRank
                            break
                        end
                    end
                end
            end

            local effectiveRank = rank or -1
            if effectiveRank == -1 then
                local name = string.lower(types.NPC.record(actor).name)
                local id = string.lower(actor.recordId)
                local targetLower = string.lower(targetFaction)
                if string.find(name, targetLower, 1, true) or string.find(id, targetLower, 1, true) then
                    effectiveRank = 0
                end
            end

            if invert then
                -- Must NOT be in this faction
                if effectiveRank >= 0 then
                    logReq(debugPrefix .. "Rejected (Faction Mismatch: Invert " .. targetFaction .. ")")
                    return false
                end
            else
                -- Must be in this faction (OR logic for arrays)
                if effectiveRank >= 0 then
                    matchedPositive = true
                end
            end
        end

        -- For arrays with positive entries, fail if none matched
        if hasPositive and not matchedPositive then
            logReq(debugPrefix .. "Rejected (Faction Mismatch: none of required factions)")
            return false
        end
    end
    
    -- Location Check (city / settlement / specific cell name)
    if reqs.location then
        local cell = actor.cell.name or ""
        local cellNorm = string.lower(cell):gsub("'", "-")
        local requiredLocs = type(reqs.location) == "table" and reqs.location or {reqs.location}
        local found = false

        for _, loc in ipairs(requiredLocs) do
            local locNorm = string.lower(loc):gsub("'", "-")
            if string.find(cellNorm, locNorm, 1, true) then found = true; break end
        end

        if not found then
            logReq(debugPrefix .. "Rejected (Location Mismatch): User in '" .. cell .. "', Needed '" .. table.concat(requiredLocs, ",") .. "'")
            return false
        end
    end

    -- Region Check (province or geographic region — uses real cell.region + coordinate boxes)
    if reqs.region then
        local requiredRegions = type(reqs.region) == "table" and reqs.region or {reqs.region}
        local hasPositive = false
        local matchedPositive = false

        for _, reg in ipairs(requiredRegions) do
            local targetRegion = reg
            local invert = false
            if string.sub(targetRegion, 1, 1) == "!" then
                targetRegion = string.sub(targetRegion, 2)
                invert = true
            else
                hasPositive = true
            end

            local matches = RegionResolver.matches(actor, targetRegion)
            if invert then
                if matches then
                    logReq(debugPrefix .. "Rejected (Region Negation Match): " .. targetRegion)
                    return false
                end
            else
                if matches then
                    matchedPositive = true
                end
            end
        end

        if hasPositive and not matchedPositive then
            local specificRegion, province = RegionResolver.getActorRegionInfo(actor)
            logReq(debugPrefix .. "Rejected (Region Mismatch): Actor region='" .. tostring(specificRegion) .. "', province='" .. tostring(province) .. "', Needed '" .. table.concat(requiredRegions, ",") .. "'")
            return false
        end
    end
    
    -- Weather Check
    if reqs.weather then
        local weatherRecord = nil
        local ok, result = pcall(function() return core.weather.getCurrent(actor.cell) end)
        if ok then weatherRecord = result end

        if not weatherRecord then
            -- No weather data — actor is in an interior cell
            logReq(debugPrefix .. "Rejected (Weather: no weather data, likely interior)")
            return false
        end

        local required = string.lower(reqs.weather)
        local current  = string.lower(weatherRecord.recordId)
        if current ~= required then
            logReq(debugPrefix .. "Rejected (Weather: current='" .. current .. "', required='" .. required .. "')")
            return false
        end
    end

    -- Time of Day Check  (reqs.time = { min = hour, max = hour }, 0-24 scale)
    if reqs.time then
        local hour = TimeService.getHour()
        local minH = reqs.time.min
        local maxH = reqs.time.max
        if hour < minH or hour >= maxH then
            logReq(debugPrefix .. string.format("Rejected (Time: hour=%.1f, required=[%s,%s))", hour, tostring(minH), tostring(maxH)))
            return false
        end
    end
    
    -- Dual-Actor Checks (Recursive)
    if reqs.target then
        if not target then
            logReq(debugPrefix .. "Rejected (Target Req but no Target)")
            return false
        end
        if not ConversationManager.checkRequirements(target, nil, reqs.target, debugId, forceLog) then
            logReq(debugPrefix .. "Rejected (Target Condition Failed)")
            return false
        end
    end

    if reqs.initiator then
        if not ConversationManager.checkRequirements(actor, target, reqs.initiator, debugId, forceLog) then
             logReq(debugPrefix .. "Rejected (Initiator Condition Failed)")
             return false
        end
    end
    
    -- Quest Stage Check
    if reqs.quest then
        local questList = reqs.quest
        -- Support both single object {id=...,min=...} and array [{id=...}, ...]
        if type(questList) == "table" and questList.id then
            questList = { questList }
        end
        for _, qreq in ipairs(questList) do
            local stage = getPlayerQuestStage(qreq.id)
            if stage == nil then
                logReq(debugPrefix .. string.format("Rejected (Quest '%s' not found)", qreq.id))
                return false
            end
            if qreq.min and stage < qreq.min then
                logReq(debugPrefix .. string.format("Rejected (Quest '%s' stage=%d, required >= %d)", qreq.id, stage, qreq.min))
                return false
            end
            if qreq.max and stage > qreq.max then
                logReq(debugPrefix .. string.format("Rejected (Quest '%s' stage=%d, required <= %d)", qreq.id, stage, qreq.max))
                return false
            end
        end
    end

    return true
end

-- DEPRECATED: Handled by Blacklist

-- Helper: Check Service Provider
function ConversationManager.isServiceProvider(actor)
    local services = types.NPC.record(actor).services
    if not services then return false end
    for _, v in pairs(services) do
        if v then return true end
    end
    return false
end

-- Helper: Select Line from Pool (Weighted for Generics)
function ConversationManager.selectLine(pool, speaker, listener)
    local validLines = {}
    local genericEntry = nil
    
    -- print("[DEBUG] Selecting Line from Pool of " .. #pool)
    for i, line in ipairs(pool) do
        if line.type == "Generic" then
            genericEntry = line
            -- print(string.format("  Line %d [Generic]: Saved as fallback", i))
        else
            -- Check Requirements (Force Verbose Log)
            if ConversationManager.checkRequirements(speaker, listener, line, "Line " .. i, true) then
                -- print(string.format("  Line %d [Specific]: Passed Checks (Race: %s, Faction: %s)", i, tostring(line.race), tostring(line.faction)))
                table.insert(validLines, line)
            end
        end
    end
    
    if #validLines > 0 then
        -- Pick random valid line
        local picked = pickAvailableLine(validLines)
        if picked then
            print("[DEBUG] Selected Specific Line: " .. (picked.id or "Unknown"))
            return picked
        end
        print("[DEBUG] All specific lines in pool are on cooldown; checking generic fallback.")
    end
    
    -- Helper to resolve generic (local function)
    local function resolveGeneric(entry)
        local genericPool = Library.Generics[entry.pool]
        if genericPool then
            local resolved = genericPool[math.random(#genericPool)]
            return resolved
        else
            print(string.format("[ProceduralChatter] ERROR: Generic pool '%s' not found!", entry.pool))
            return nil
        end
    end
    
    if genericEntry then
        print("[DEBUG] Selected Generic Fallback")
        return resolveGeneric(genericEntry)
    end
    
    print("[DEBUG] No valid lines found.")
    return nil
end

local function getSnippetStartChunk(snippet)
    if not snippet or type(snippet.chunks) ~= "table" then return nil end
    local preferred = { "Intro", "Line_1" }
    for _, name in ipairs(preferred) do
        if snippet.chunks[name] then
            return snippet.chunks[name], name
        end
    end
    for name, chunk in pairs(snippet.chunks) do
        return chunk, name
    end
    return nil
end

local function linePoolHasAvailableLine(pool, speaker, listener)
    if type(pool) ~= "table" then return false end
    for i, line in ipairs(pool) do
        if line.type == "Generic" then
            local genericPool = Library.Generics and Library.Generics[line.pool]
            if type(genericPool) == "table" and #genericPool > 0 then
                return true
            end
        elseif ConversationManager.checkRequirements(speaker, listener, line, "Line " .. i)
                and not isLineOnCooldown(line) then
            return true
        end
    end
    return false
end

local function uniqueSnippetCanStart(snippet, actor1, actor2)
    local startChunk, startChunkId = getSnippetStartChunk(snippet)
    if not startChunk then return false end

    local initiator = actor1
    local target = actor2
    if snippet.initiator then
        local expected = string.lower(tostring(snippet.initiator))
        local id1 = string.lower(actor1 and actor1.recordId or "")
        local id2 = string.lower(actor2 and actor2.recordId or "")
        if expected == id2 and expected ~= id1 then
            initiator = actor2
            target = actor1
        end
    end

    local speaker = (startChunk.speaker == 1) and initiator or target
    local listener = (startChunk.speaker == 1) and target or initiator
    local canStart = linePoolHasAvailableLine(startChunk.lines, speaker, listener)
    if not canStart then
        print(string.format(
            "[ConversationManager] Unique snippet '%s' unavailable: starting chunk '%s' has no playable lines",
            tostring(snippet.id or "unknown"),
            tostring(startChunkId)))
    end
    return canStart
end

local function getPlayableUniqueSnippet(actor1, actor2)
    if not Library.UniqueConversations or not Library.UniqueSnippets or not actor1 or not actor2 then
        return nil
    end

    local id1 = string.lower(actor1.recordId or "")
    local id2 = string.lower(actor2.recordId or "")
    local uniqueId = Library.UniqueConversations[id1] and Library.UniqueConversations[id1][id2]
    if not uniqueId then
        uniqueId = Library.UniqueConversations[id2] and Library.UniqueConversations[id2][id1]
    end
    if not uniqueId then return nil end

    local snippet = Library.UniqueSnippets[uniqueId]
    if not snippet then return nil end
    snippet.id = uniqueId
    if not uniqueSnippetCanStart(snippet, actor1, actor2) then return nil end
    return snippet, uniqueId
end

-- Core: Find Best Snippet
function ConversationManager.findBestSnippet(speaker, listener, category, usedSnippets)
    local sId = string.lower(speaker.recordId or "")
    local lId = string.lower(listener.recordId or "")

    -- 1. Check Unique Conversations (Speaker -> Listener)
    if Library.UniqueConversations and Library.UniqueSnippets then
        if Library.UniqueConversations[sId] and Library.UniqueConversations[sId][lId] then
            local uniqueId = Library.UniqueConversations[sId][lId]
            if not usedSnippets or not usedSnippets[uniqueId] then
                local snippet = Library.UniqueSnippets[uniqueId]
                if snippet then
                    snippet.id = uniqueId
                    -- Unique conversations also check requirements (quest conditions, etc.)
                    if ConversationManager.checkRequirements(speaker, listener, snippet.conditions or {}, uniqueId)
                            and uniqueSnippetCanStart(snippet, speaker, listener) then
                        return snippet
                    end
                end
            end
        end
    end

    -- 1b. Check reverse Unique Conversation direction (Listener -> Speaker)
    if Library.UniqueConversations and Library.UniqueSnippets then
        if Library.UniqueConversations[lId] and Library.UniqueConversations[lId][sId] then
            local uniqueId = Library.UniqueConversations[lId][sId]
            if not usedSnippets or not usedSnippets[uniqueId] then
                local snippet = Library.UniqueSnippets[uniqueId]
                if snippet then
                    snippet.id = uniqueId
                    if ConversationManager.checkRequirements(speaker, listener, snippet.conditions or {}, uniqueId)
                            and uniqueSnippetCanStart(snippet, speaker, listener) then
                        return snippet
                    end
                end
            end
        end
    end

    -- 2. Check Blacklist (for generic categories)
    if category == "SmallTalk" then
        if Blacklist.isConversationBlacklisted(speaker) or Blacklist.isConversationBlacklisted(listener) then
            return nil
        end
    end

    local libraries = {}
    
    -- Support multiple libraries based on category
    if category == "SmallTalk" then
        table.insert(libraries, Library.SmallTalk)
    elseif category == "DjangoRumors" or category == "Django" then
        table.insert(libraries, Library.DjangoRumors)
    elseif category == "GenericRumors" or category == "Rumor" or category == "Rumors" or category == "Tidbits" then
        table.insert(libraries, Library.GenericRumors)
    end
    
    if #libraries == 0 then 
        -- print("[DEBUG] No library found for category: " .. tostring(category))
        return nil 
    end
    
    local candidates = {}
    local checkedCount = 0
    local usedCount = 0
    local rejectedCount = 0

    for _, library in ipairs(libraries) do
        for id, snippet in pairs(library.Snippets) do
            checkedCount = checkedCount + 1
            local isUsed = usedSnippets and usedSnippets[id]
            if isUsed then
                usedCount = usedCount + 1
            elseif guardPairCheckAllowed(id, speaker, listener, snippet.conditions) and ConversationManager.checkRequirements(speaker, listener, snippet.conditions, id) then
                snippet.id = id
                snippet.effectivePriority = snippet.priority or 1
                table.insert(candidates, snippet)
            else
                rejectedCount = rejectedCount + 1
            end
        end
    end

    print(string.format("[DEBUG findBestSnippet] category=%s checked=%d used=%d rejected=%d candidates=%d", category, checkedCount, usedCount, rejectedCount, #candidates))
    
    -- Weighted Random Selection
    if #candidates > 0 then
        local totalWeight = 0
        for _, c in ipairs(candidates) do
            totalWeight = totalWeight + (c.effectivePriority or 1)
        end
        
        local pick = math.random() * totalWeight
        local current = 0
        for _, c in ipairs(candidates) do
            current = current + (c.effectivePriority or 1)
            if current >= pick then
                return c
            end
        end
        return candidates[#candidates] -- Fallback
    end
    
    return nil
end

-- Core: Start Conversation
function ConversationManager.startConversation(initiator, target, stopDistance, opts)
    if dialogueMenuActive then return false end
    if not initiator or not target then return false end
    opts = opts or {}

    -- Block NPCs that cannot converse, including disabled grace-table actors
    -- and actors currently walking/queued for schedule relocation.
    if not canStartConversation(initiator) or not canStartConversation(target) then
        print(string.format("[ConversationManager] BLOCKED: initiator=%s target=%s (cannot converse)",
            initiator.recordId, target.recordId))
        return false
    end
    if isSeatingInProgress(initiator) or isSeatingInProgress(target) then
        print(string.format("[ConversationManager] BLOCKED: initiator=%s target=%s (seating in progress)",
            initiator.recordId, target.recordId))
        return false
    end

    -- Walk blacklist: only applies when someone actually has to walk.
    -- Static conversations (stopDistance nil/0) let service NPCs talk if they're already close.
    -- Unique conversations bypass walk-blacklist so scripted NPC pairs can always talk.
    local guardInvolved = isGuardActor(initiator) or isGuardActor(target)
    local hasUnique = hasUniqueConversationBetween(initiator, target)
    local hasGuardSpecific = hasUnique or (guardInvolved and ConversationManager.hasGuardSpecificConversation(initiator, target))

    if stopDistance and stopDistance > 0 and not hasGuardSpecific then
        local initiatorWalkBlacklisted = ConversationManager.isWalkBlacklisted(initiator)
        local targetWalkBlacklisted = ConversationManager.isWalkBlacklisted(target)
        if initiatorWalkBlacklisted and targetWalkBlacklisted then
            print(string.format("[ConversationManager] BLOCKED: initiator=%s target=%s (both walk-blacklisted)",
                initiator.recordId, target.recordId))
            return false
        end
    end

    local npc1 = initiator
    local npc2 = target
    
    -- Create Conversation State
    local conv = {
        initiator = initiator,
        target = target,
        initiatorId = initiator.id,
        targetId = target.id,
        initiatorRecordId = initiator.recordId,
        targetRecordId = target.recordId,
        state = "Moving", -- Default state, but might skip if Static
        snippet = nil,
        chunk = nil,
        waitTimer = 0,
        startTime = core.getSimulationTime(),
        preventFace = false, -- New Flag: Prevent facing if sitting logic dictates
        usedSnippets = {}, -- Restoration: Initialized to empty table
        stepIndex = 0,
        flow = nil,
        seatedConversationMovers = nil
    }
    
    -- Pick snippet early (needed for movement overrides below)
    conv.snippet = ConversationManager.findBestSnippet(initiator, target, "SmallTalk", conv.usedSnippets)
    if guardInvolved and not conv.snippet then
        print(string.format("[ConversationManager] BLOCKED: initiator=%s target=%s (no guard-specific dialogue)",
            initiator.recordId, target.recordId))
        return false
    end
    
    -- For unique conversations, ensure the expected initiator speaks first.
    -- The snippet's 'initiator' field stores the NPC who should be speaker 1.
    if conv.snippet and conv.snippet.initiator then
        local expected = string.lower(tostring(conv.snippet.initiator))
        local actual = string.lower(initiator.recordId or "")
        if expected ~= actual then
            -- Swap so the correct NPC is the initiator
            local temp = initiator
            initiator = target
            target = temp
            conv.initiator = initiator
            conv.target = target
            conv.initiatorId = initiator.id
            conv.targetId = target.id
            conv.initiatorRecordId = initiator.recordId
            conv.targetRecordId = target.recordId
            print(string.format("[ProceduralChatter] Unique conversation: swapped initiator to %s", initiator.recordId))
        end
    end
    
    -- Initialize Flow (must happen before static path calls playNextStep)
    -- Unique conversations are self-contained: only SmallTalk, no greeting/rumors/goodbye
    local isUniqueConv = false
    if conv.snippet and conv.snippet.id and Library.UniqueConversations then
        local sId = string.lower(initiator.recordId or "")
        local lId = string.lower(target.recordId or "")
        if (Library.UniqueConversations[sId] and Library.UniqueConversations[sId][lId] == conv.snippet.id)
        or (Library.UniqueConversations[lId] and Library.UniqueConversations[lId][sId] == conv.snippet.id) then
            isUniqueConv = true
        end
    end
    
    if isUniqueConv or guardInvolved then
        conv.flow = { "SmallTalk" }
        if isUniqueConv then
            print("[ProceduralChatter] Selected Flow: UniqueExchange (self-contained)")
        else
            print("[ProceduralChatter] Selected Flow: GuardExchange (self-contained)")
        end
    else
        local availableFlows = {}
        for bind, flow in pairs(Library.Flows) do
            table.insert(availableFlows, flow)
        end
        if #availableFlows > 0 then
            conv.flow = availableFlows[math.random(#availableFlows)]
            print("[ProceduralChatter] Selected Flow: " .. tostring(conv.flow))
        else
            print("[ProceduralChatter] ERROR: No flows found in Library! Fallback to Greeting only.")
            conv.flow = { "Greeting", "Goodbye" }
        end
    end
    conv.stepIndex = 0

    -- Capture current position and AI package before any face/hold/walk/stop command
    -- can replace the NPC's native or current wander package.
    pcall(function() initiator:sendEvent("PC_SaveBehavior", { reason = "conversation" }) end)
    pcall(function() target:sendEvent("PC_SaveBehavior", { reason = "conversation" }) end)

    local bothSitting = actorLooksSitting(initiator) and actorLooksSitting(target)
    if bothSitting then
        local sitDist = (initiator.position - target.position):length()
        local staticDistance = opts.staticDistance or 800
        if (not stopDistance or stopDistance <= 0) and sitDist >= staticDistance then
            if opts.allowSeatedMover then
                stopDistance = 200
            else
                print(string.format("[ConversationManager] BLOCKED: seated static conversation too far (%s <-> %s dist=%.1f)",
                    initiator.recordId, target.recordId, sitDist))
                return false
            end
        end
    end

    -- Pre-register movement validation (avoids registering then immediately tearing down).
    if stopDistance and stopDistance > 0 then
        local preSit1 = actorLooksSitting(initiator)
        local preSit2 = actorLooksSitting(target)
        local preDist = (initiator.position - target.position):length()
        if preSit1 and preSit2 then
            if opts.allowSeatedMover then
                local canMove = not ConversationManager.isWalkBlacklisted(npc1)
                    or not ConversationManager.isWalkBlacklisted(npc2)
                if not canMove and preDist >= 180 then
                    print("[ProceduralChatter] Sitting Logic: both sitters cannot walk.")
                    return false
                end
            elseif preDist >= 800 then
                print("[ProceduralChatter] Sitting Logic: Too Far to chat.")
                return false
            end
        end
    end
    
    conv.stopDistance = stopDistance
    conv.opts = opts
    conv.isPending = true
    conv.pendingTimer = 1.0

    activeConversations[initiator.id] = conv
    activeConversations[target.id] = conv

    -- Mark state in NPCState via global event (player script cannot write storage)
    core.sendGlobalEvent("PC_StateChanged", { npcId = initiator.id, state = "pending_conversation" })
    core.sendGlobalEvent("PC_StateChanged", { npcId = target.id, state = "pending_conversation" })

    core.sendGlobalEvent("PC_SetBusy", { npc = initiator, busy = true })
    core.sendGlobalEvent("PC_SetBusy", { npc = target, busy = true })
    initiator:sendEvent("PC_StopActivity", { silent = true, forceClearAll = true })
    target:sendEvent("PC_StopActivity", { silent = true, forceClearAll = true })

    return true
end

local function executeConversationStart(conv)
    local initiator = conv.initiator
    local target = conv.target
    local stopDistance = conv.stopDistance
    local opts = conv.opts or {}
    local npc1 = initiator
    local npc2 = target

    local bothSitting = actorLooksSitting(initiator) and actorLooksSitting(target)
    if bothSitting then
        local sitDist = (initiator.position - target.position):length()
        local staticDistance = opts.staticDistance or 800
        if (not stopDistance or stopDistance <= 0) and sitDist >= staticDistance then
            if opts.allowSeatedMover then
                stopDistance = 200
            else
                print(string.format("[ConversationManager] BLOCKED (Late): seated static conversation too far (%s <-> %s dist=%.1f)",
                    initiator.recordId, target.recordId, sitDist))
                ConversationManager.endConversation(conv)
                return
            end
        end
    end

    -- Pre-register movement validation (avoids registering then immediately tearing down).
    if stopDistance and stopDistance > 0 then
        local preSit1 = actorLooksSitting(initiator)
        local preSit2 = actorLooksSitting(target)
        local preDist = (initiator.position - target.position):length()
        if preSit1 and preSit2 then
            if opts.allowSeatedMover then
                local canMove = not ConversationManager.isWalkBlacklisted(initiator)
                    or not ConversationManager.isWalkBlacklisted(target)
                if not canMove and preDist >= 180 then
                    print("[ProceduralChatter] Sitting Logic: both sitters cannot walk.")
                    ConversationManager.endConversation(conv)
                    return
                end
            elseif preDist >= 800 then
                print("[ProceduralChatter] Sitting Logic: Too Far to chat.")
                ConversationManager.endConversation(conv)
                return
            end
        end
    end

    if stopDistance and stopDistance > 0 then
        print(string.format("[ProceduralChatter] Starting Walking Conversation: %s -> %s (StopDist: %s)", types.NPC.record(initiator).name, types.NPC.record(target).name, stopDistance))
    else
        print(string.format("[ProceduralChatter] Starting Static Conversation: %s <-> %s", types.NPC.record(initiator).name, types.NPC.record(target).name))

        -- Explicit Facing for Static Mode
        initiator:sendEvent("PC_Face", { target = target })
        target:sendEvent("PC_Face", { target = initiator })
        initiator:sendEvent("PC_StartConversation", { target = target })
        target:sendEvent("PC_StartConversation", { target = initiator })
        conv.state = "Starting"
        conv.startTimer = 0.15
    end

    -- DEBUG: Dump Actor Info
    local function dumpActor(actor, label)
        local rec = types.NPC.record(actor)
        print(string.format("[ProceduralChatter] START %s: ID='%s', Class='%s'", label, actor.recordId, rec.class))
    end
    dumpActor(initiator, "Initiator")
    dumpActor(target, "Target")

    -- Movement Logic (only for walking conversations)
    if stopDistance and stopDistance > 0 then
        local p1 = initiator.position
        local p2 = target.position
        local midpoint = (p1 + p2) / 2
        local dist = (p1 - p2):length()
        local stopDist = 60 -- Closer (approx 1m)
        
        local move1 = true
        local move2 = true
        local target1 = nil
        local target2 = nil
        local requiredWalk1 = false
        local requiredWalk2 = false

        -- Walk blacklist: don't send walk events to blacklisted NPCs
        if ConversationManager.isWalkBlacklisted(npc1) then move1 = false end
        if ConversationManager.isWalkBlacklisted(npc2) then move2 = false end

        -- SITTING LOGIC INTEGRATION
        local sit1 = actorLooksSitting(npc1)
        local sit2 = actorLooksSitting(npc2)
        local preventFace = false
        
        -- A. Sitting Interactions
        if sit1 and sit2 then
            move1 = false
            move2 = false

            if opts.allowSeatedMover then
                if not ConversationManager.isWalkBlacklisted(npc1) then
                    move1 = true
                    target1 = p2
                    conv.seatedConversationMovers = { [npc1.id] = true }
                    print(string.format("[ProceduralChatter] Sitting Logic: %s stands to talk to %s", npc1.recordId, npc2.recordId))
                elseif not ConversationManager.isWalkBlacklisted(npc2) then
                    move2 = true
                    target2 = p1
                    conv.seatedConversationMovers = { [npc2.id] = true }
                    print(string.format("[ProceduralChatter] Sitting Logic: %s stands to talk to %s", npc2.recordId, npc1.recordId))
                elseif dist < 180 then
                    print("[ProceduralChatter] Sitting Logic: both sitters cannot walk; preserving facing")
                    preventFace = true
                else
                    print("[ProceduralChatter] Sitting Logic: both sitters cannot walk.")
                    ConversationManager.endConversation(conv)
                    return
                end
            elseif dist < 180 then
                 print("[ProceduralChatter] Sitting Logic: Close (Preserve Facing)")
                 preventFace = true
            elseif dist < 800 then
                 print("[ProceduralChatter] Sitting Logic: Medium (Turn to Face)")
            else
                 print("[ProceduralChatter] Sitting Logic: Too Far to chat.")
                 ConversationManager.endConversation(conv)
                 return
            end
        elseif sit1 and not sit2 then
            move1 = false
            move2 = not ConversationManager.isWalkBlacklisted(npc2)
            requiredWalk2 = move2
            target2 = p1
        elseif not sit1 and sit2 then
            move1 = not ConversationManager.isWalkBlacklisted(npc1)
            requiredWalk1 = move1
            move2 = false
            target1 = p2
        else
            -- Both Standing (Default)
            if ConversationManager.ServiceNPCsStatic then
                if ConversationManager.isServiceProvider(npc1) then move1 = false end
                if ConversationManager.isServiceProvider(npc2) then move2 = false end
            end
        end

        -- B. Snippet Override (Apply only if allowed by sitting status)
        if conv.snippet and conv.snippet.movement then
            if not sit1 and not requiredWalk1 then
                if conv.snippet.movement.initiator == "wait" then move1 = false end
                if conv.snippet.movement.initiator == "walk" then move1 = true end
            end
            if not sit2 and not requiredWalk2 then
                if conv.snippet.movement.target == "wait" then move2 = false end
                if conv.snippet.movement.target == "walk" then move2 = true end
            end
        end
        
        -- Default targets to midpoint if not set by sitting logic
        if not target1 then target1 = midpoint end
        if not target2 then target2 = midpoint end
        
        if not move1 and move2 then
            target2 = p1 -- NPC 2 walks to NPC 1
        elseif move1 and not move2 then
            target1 = p2 -- NPC 1 walks to NPC 2
        end
        
        -- Store preventFace in conv for update loop
        conv.preventFace = preventFace
        
        if move1 then
            npc1:sendEvent("PC_WalkTo", {
                target = target1,
                stopDistance = stopDist,
                conversationWalk = true,
                forceStandForConversation = conv.seatedConversationMovers and conv.seatedConversationMovers[npc1.id] == true
            })
        end
        if move2 then
            npc2:sendEvent("PC_WalkTo", {
                target = target2,
                stopDistance = stopDist,
                conversationWalk = true,
                forceStandForConversation = conv.seatedConversationMovers and conv.seatedConversationMovers[npc2.id] == true
            })
        end
        
        conv.state = "Moving"
        conv.movingTimer = 0
        conv.movingStartDist = (initiator.position - target.position):length()
    end
    sendConversationHeartbeat(conv, true)
end

--- Local npc.lua rejected PC_WalkTo for a walking conversation (schedule relocation).
function ConversationManager.onConversationWalkRejected(ev)
    if not ev or not ev.npcId then return end
    local conv = activeConversations[ev.npcId]
    if not conv then return end
    if conv.isPending or conv.state == "Moving" or conv.state == "Starting" or ev.reason == "hostile" or ev.reason == "combat" then
        print(string.format(
            "[ConversationManager] Conversation rejected during %s (%s); aborting conversation",
            conv.isPending and "pending" or tostring(conv.state),
            tostring(ev.reason or "unknown")))
        local skipReturnIds = { [ev.npcId] = true }
        if ev.reason == "schedule_relocation" or ev.reason == "in_transit"
                or ev.reason == "hostile" or ev.reason == "combat" then
            if conv.initiator and conv.initiator.id then skipReturnIds[conv.initiator.id] = true end
            if conv.target and conv.target.id then skipReturnIds[conv.target.id] = true end
        end
        ConversationManager.endConversation(conv, { skipReturnIds = skipReturnIds })
    end
end

function ConversationManager.abortHostile(actorOrId, npcId)
    if not actorOrId and not npcId then return end
    local actor = type(actorOrId) == "table" and actorOrId or nil
    local hostileId = npcId or (actor and actor.id) or actorOrId
    if not hostileId then return end
    local label = actor and actor.recordId or tostring(hostileId)
    print("[ProceduralChatter] Aborting conversation for hostile actor: " .. tostring(label))

    -- Collect unique conversations from activeConversations (same deduplication as update())
    local toAbort = {}
    for _, conv in pairs(activeConversations) do
        toAbort[conv] = true
    end

    for conv, _ in pairs(toAbort) do
        if conv.initiatorId == hostileId or conv.targetId == hostileId then
            print("[ProceduralChatter] Interrupted conversation ID: " .. tostring(conv))
            local skipReturnIds = { [hostileId] = true }
            ConversationManager.endConversation(conv, { skipReturnIds = skipReturnIds })
        end
    end
end

function ConversationManager.abortCombatant(actor)
    ConversationManager.abortHostile(actor)
end

function ConversationManager.playNextStep(conv)
    if abortIfHostile(conv, "playback") then return end

    -- Only advance stepIndex if we are NOT in the middle of a multi-stage action
    if not conv.chunk and not conv.greetingStage and not conv.goodbyeStage and not conv.scheduleGoodbyeActive then
        conv.stepIndex = conv.stepIndex + 1
        local step = conv.flow[conv.stepIndex]
        print(string.format("[ProceduralChatter] Advancing to Step %d: %s", conv.stepIndex, tostring(step)))
        
        if not step then
            -- End of Flow
            print("[ProceduralChatter] End of Flow. Stopping.")
            print("[ProceduralChatter] End of Flow. Stopping.")
            ConversationManager.endConversation(conv)
            return
        end
        conv.state = step
    else
        print(string.format("[ProceduralChatter] Continuing Step %d (%s) - Chunk: %s, GStage: %s, BStage: %s", 
            conv.stepIndex, conv.state, tostring(conv.chunk), tostring(conv.greetingStage), tostring(conv.goodbyeStage)))
    end
    
    if conv.state == "Greeting" then
        -- Play Greeting
        local greeting = nil
        
        -- Select Greeting based on role (Initiator vs Responder)
        -- For now, we assume Initiator starts
        if not conv.greetingStage then
            -- Stage 1: Initiator speaks
            local candidates = {}
            for id, g in pairs(Library.Greetings) do
                if (g.type == "Initiator" or g.type == "Both") and ConversationManager.checkRequirements(conv.initiator, conv.target, g.requirements) then
                    table.insert(candidates, g)
                end
            end
            if #candidates > 0 then
                greeting = candidates[math.random(#candidates)]
                conv.hasPlayback = true
                print(string.format("[%s]: %s", types.NPC.record(conv.initiator).name, greeting.text))
                -- Pass ID if available
                if VoiceManager then VoiceManager.playVoice(conv.initiator, greeting.text, nil, nil, greeting.id) end
                playConversationAnimation(conv.initiator, greeting)
            end
            conv.greetingStage = 2
            -- Schedule next step (Response)
            -- Do NOT decrement stepIndex, we handle that at the top of playNextStep 
            
            -- Calculate delay
            local duration = (greeting and VoiceManager and VoiceManager.getDuration(conv.initiator, greeting.id, greeting.text)) or 2.0
            conv.waitTimer = duration + 0.15 -- Buffer reduced to 0.15s
            return
        elseif conv.greetingStage == 2 then
            -- Stage 2: Target responds
            local candidates = {}
            for id, g in pairs(Library.Greetings) do
                if (g.type == "Responder" or g.type == "Both") and ConversationManager.checkRequirements(conv.target, conv.initiator, g.requirements) then
                    table.insert(candidates, g)
                end
            end
            if #candidates > 0 then
                greeting = candidates[math.random(#candidates)]
                conv.hasPlayback = true
                print(string.format("[%s]: %s", types.NPC.record(conv.target).name, greeting.text))
                if VoiceManager then VoiceManager.playVoice(conv.target, greeting.text, nil, nil, greeting.id) end
                playConversationAnimation(conv.target, greeting)
            end
            conv.greetingStage = nil
            -- Done with Greeting step, next call will advance stepIndex
            local duration = (greeting and VoiceManager and VoiceManager.getDuration(conv.target, greeting.id, greeting.text)) or 2.0
            conv.waitTimer = duration + 0.15
            return
        end
        
    elseif conv.state == "Rumor" or conv.state == "Rumors" or conv.state == "SmallTalk" or conv.state == "Tidbits" or conv.state == "Django" or conv.state == "DjangoRumors" or conv.state == "GenericRumors" then
        if conv.chunk then
            -- Continue existing snippet
            ConversationManager.playChunk(conv)
        else
            -- Pick Snippet
            conv.snippet = ConversationManager.findBestSnippet(conv.initiator, conv.target, conv.state, conv.usedSnippets)
            
            if conv.snippet then
                if conv.snippet.id then 
                    conv.usedSnippets[conv.snippet.id] = true 
                end
                -- Determine starting chunk (native uses "Intro", DC uses "Line_1", etc.)
                local startChunk = nil
                local preferred = { "Intro", "Line_1" }
                for _, name in ipairs(preferred) do
                    if conv.snippet.chunks[name] then
                        startChunk = name
                        break
                    end
                end
                if not startChunk then
                    for key, _ in pairs(conv.snippet.chunks) do
                        startChunk = key
                        break
                    end
                end
                conv.chunk = startChunk
                ConversationManager.playChunk(conv)
            else
                -- Skip to next step if no snippet found
                print("[ProceduralChatter] No valid snippet found for " .. conv.state .. ". Skipping.")
                ConversationManager.playNextStep(conv)
            end
        end

        

        
    elseif conv.state == "Goodbye" then
        -- Play Goodbye
        local goodbye = nil
        
        if not conv.goodbyeStage then
            -- Stage 1: Initiator says goodbye
            local candidates = {}
            for id, g in pairs(Library.Goodbyes) do
                if (g.type == "Initiator" or g.type == "Both") and ConversationManager.checkRequirements(conv.initiator, conv.target, g.requirements) then
                    table.insert(candidates, g)
                end
            end
            if #candidates > 0 then
                goodbye = candidates[math.random(#candidates)]
                conv.hasPlayback = true
                print(string.format("[%s]: %s", types.NPC.record(conv.initiator).name, goodbye.text))
                if VoiceManager then VoiceManager.playVoice(conv.initiator, goodbye.text, nil, nil, goodbye.id) end
            else
                print("[ProceduralChatter] WARNING: No Initiator Goodbye candidates found!")
            end
            conv.goodbyeStage = 2
            local duration = (goodbye and VoiceManager and VoiceManager.getDuration(conv.initiator, goodbye.id, goodbye.text)) or 2.0
            conv.waitTimer = duration + 0.15
            return
        elseif conv.goodbyeStage == 2 then
            -- Stage 2: Target responds
            local candidates = {}
            for id, g in pairs(Library.Goodbyes) do
                if (g.type == "Responder" or g.type == "Both") and ConversationManager.checkRequirements(conv.target, conv.initiator, g.requirements) then
                    table.insert(candidates, g)
                end
            end
            if #candidates > 0 then
                goodbye = candidates[math.random(#candidates)]
                conv.hasPlayback = true
                print(string.format("[%s]: %s", types.NPC.record(conv.target).name, goodbye.text))
                if VoiceManager then VoiceManager.playVoice(conv.target, goodbye.text, nil, nil, goodbye.id) end
            else
                print("[ProceduralChatter] WARNING: No Responder Goodbye candidates found!")
            end
            
            -- End via centralized teardown so busy locks always clear.
            conv.scheduleGoodbyeActive = nil
            ConversationManager.endConversation(conv)
            return
        end
    end
end

--- Jump an active conversation to Goodbye lines, then end without return-walk for
--- NPCs that must relocate on schedule. Returns true if a goodbye sequence started.
function ConversationManager.interruptForSchedule(npcId, requestId)
    if not npcId or not requestId then return false end
    local conv = activeConversations[npcId]
    if not conv then return false end

    if conv.scheduleInterrupt and conv.scheduleInterrupt.requestId == requestId then
        return true
    end

    conv.scheduleInterrupt = {
        requestId = requestId,
        relocatingNpcIds = { [npcId] = true },
    }

    if conv.isPending then
        print(string.format("[ConversationManager] Schedule interrupt (pending): ending %s immediately",
            tostring(conv.initiatorRecordId or npcId)))
        ConversationManager.endConversation(conv, { scheduleInterrupt = conv.scheduleInterrupt })
        return true
    end

    print(string.format("[ConversationManager] Schedule interrupt: jumping to Goodbye for npc=%s request=%s",
        tostring(npcId), tostring(requestId)))

    conv.chunk = nil
    conv.greetingStage = nil
    conv.goodbyeStage = nil
    conv.snippet = nil
    conv.waitTimer = 0
    conv.isPending = nil
    conv.pendingTimer = nil
    conv.state = "Goodbye"
    conv.scheduleGoodbyeActive = true

    local hasGoodbye = false
    for _, step in ipairs(conv.flow or {}) do
        if step == "Goodbye" then hasGoodbye = true; break end
    end
    if not hasGoodbye then
        conv.flow = conv.flow or {}
        table.insert(conv.flow, "Goodbye")
    end

    pcall(function() conv.initiator:sendEvent("PC_Stop") end)
    pcall(function() conv.target:sendEvent("PC_Stop") end)
    if conv.initiator and conv.target then
        pcall(function() conv.initiator:sendEvent("PC_Face", { target = conv.target }) end)
        pcall(function() conv.target:sendEvent("PC_Face", { target = conv.initiator }) end)
    end

    ConversationManager.playNextStep(conv)
    return true
end

function ConversationManager.playChunk(conv)
    local snippet = conv.snippet
    local chunkId = conv.chunk
    local chunk = snippet.chunks[chunkId]
    
    if not chunk then
        conv.state = "Goodbye"
        ConversationManager.playNextStep(conv)
        return
    end
    
    -- Determine Speaker
    local speaker = (chunk.speaker == 1) and conv.initiator or conv.target
    local listener = (chunk.speaker == 1) and conv.target or conv.initiator
    
    -- DEBUG: Print Speaker Details to verify Randoms (Disable later)
    -- local rec = types.NPC.record(speaker)
    -- print(string.format("[DEBUG_NPC] Name: %s | Race: %s | Class: %s", rec.name, rec.race, rec.class))
    
    -- Select Line
    local line = ConversationManager.selectLine(chunk.lines, speaker, listener)
    
    if line then
        conv.hasPlayback = true
        print(string.format("[%s]: %s", types.NPC.record(speaker).name, line.text))
        -- Pass line.id to VoiceManager for dynamic path resolution
        if VoiceManager then VoiceManager.playVoice(speaker, line.text, line.race, line.gender, line.id) end
        playConversationAnimation(speaker, line, "talk")
        
        -- Determine next step (Line overrides Chunk)
        local nextStep = line.next or chunk.next
        
        -- VALIDATION: Ensure nextStep exists in the snippet (if not "End")
        if nextStep ~= "End" and conv.snippet and not conv.snippet.chunks[nextStep] then
            print(string.format("[ProceduralChatter] WARNING: Chunk '%s' missing in snippet '%s'. Defaulting to End.", nextStep, conv.snippet.id or "Unknown"))
            nextStep = "End"
        end
        
        if nextStep == "End" then
            -- End of Snippet
            conv.chunk = nil
            conv.snippet = nil
            local duration = (line and VoiceManager and VoiceManager.getDuration(speaker, line.id, line.text)) or 2.0
            print(string.format("[DEBUG] End Chunk Duration: %.3f | WaitTimer: %.3f", duration, duration + 0.15))
            conv.waitTimer = duration + 0.15
        else
            -- Continue to next chunk
            conv.chunk = nextStep
            local duration = (line and VoiceManager and VoiceManager.getDuration(speaker, line.id, line.text)) or 2.0
            print(string.format("[DEBUG] Next Chunk Duration: %.3f | WaitTimer: %.3f", duration, duration + 0.15))
            conv.waitTimer = duration + 0.15
        end
    else
        -- No valid line found in this chunk — skip to next chunk or end snippet
        print(string.format("[ProceduralChatter] WARNING: No valid line in chunk '%s' of snippet '%s'. Skipping.", chunkId, conv.snippet.id or "Unknown"))
        local nextStep = chunk.next
        if nextStep and nextStep ~= "End" and conv.snippet and conv.snippet.chunks[nextStep] then
            conv.chunk = nextStep
            conv.waitTimer = 0.5
        else
            conv.chunk = nil
            conv.snippet = nil
            conv.waitTimer = 0.5
        end
    end
end

function ConversationManager.endConversation(conv, opts)
    if not conv then return end
    opts = opts or {}
    local scheduleInterrupt = opts.scheduleInterrupt or conv.scheduleInterrupt

    local initName = conv.initiatorRecordId or "Unknown"
    local targetName = conv.targetRecordId or "Unknown"
    print(string.format("[ProceduralChatter] Conversation Ended: %s <-> %s", initName, targetName))

    -- Activity Manager: Release Busy (Sets Cooldown)
    local initiatorId = conv.initiatorId
    local targetId = conv.targetId
    if conv.hasPlayback then
        lastEndedWithoutPlayback = nil
    else
        lastEndedWithoutPlayback = {
            initiatorId = initiatorId,
            targetId = targetId,
        }
    end

    if initiatorId then
        local isValidInit = false
        pcall(function() isValidInit = conv.initiator and conv.initiator:isValid() end)
        core.sendGlobalEvent("PC_SetBusy", {
            npc = isValidInit and conv.initiator or nil,
            npcId = initiatorId,
            busy = false
        })
        releaseConversationNpcState(initiatorId)
    end
    if targetId then
        local isValidTarget = false
        pcall(function() isValidTarget = conv.target and conv.target:isValid() end)
        core.sendGlobalEvent("PC_SetBusy", {
            npc = isValidTarget and conv.target or nil,
            npcId = targetId,
            busy = false
        })
        releaseConversationNpcState(targetId)
    end

    local skipReturnIds = opts.skipReturnIds or {}
    if scheduleInterrupt and scheduleInterrupt.relocatingNpcIds then
        for rid in pairs(scheduleInterrupt.relocatingNpcIds) do
            skipReturnIds[rid] = true
        end
    end

    local function cleanupActor(actor, actorId, skipReturn)
        if not actorId or skipReturn then return end
        if not opts.skipActorEvents and canSendConversationCleanup(actor) then
            if conv.seatedConversationMovers and conv.seatedConversationMovers[actorId] then
                core.sendGlobalEvent("PC_SetSitCooldown", {
                    npc = actor,
                    npcId = actorId,
                    seconds = SIT_STAND_COOLDOWN_SECONDS,
                    reason = "seated_conversation"
                })
            end
            pcall(function() actor:sendEvent("PC_Stop") end)
            pcall(function() actor:sendEvent("PC_Return", {
                instant = opts.instant,
                afterForcedSeatedConversation = conv.seatedConversationMovers
                    and conv.seatedConversationMovers[actorId] == true
            }) end)
            core.sendGlobalEvent("PC_ConversationReset", { npc = actor })
        end
    end

    local function cleanupRelocatingActor(actor, actorId)
        if not actorId then return end
        if opts.skipActorEvents then return end
        local ok, valid = pcall(function() return actor and actor:isValid() end)
        if not ok or not valid then return end
        pcall(function() actor:sendEvent("PC_Stop") end)
        core.sendGlobalEvent("PC_ConversationReset", { npc = actor })
    end

    if scheduleInterrupt and scheduleInterrupt.relocatingNpcIds then
        if scheduleInterrupt.relocatingNpcIds[initiatorId] then
            cleanupRelocatingActor(conv.initiator, initiatorId)
        else
            cleanupActor(conv.initiator, initiatorId, skipReturnIds[initiatorId])
        end
        if scheduleInterrupt.relocatingNpcIds[targetId] then
            cleanupRelocatingActor(conv.target, targetId)
        else
            cleanupActor(conv.target, targetId, skipReturnIds[targetId])
        end
    else
        if not opts.skipActorEvents and canSendConversationCleanup(conv.initiator) and not skipReturnIds[initiatorId] then
            if conv.seatedConversationMovers and conv.seatedConversationMovers[initiatorId] then
                core.sendGlobalEvent("PC_SetSitCooldown", {
                    npc = conv.initiator,
                    npcId = initiatorId,
                    seconds = SIT_STAND_COOLDOWN_SECONDS,
                    reason = "seated_conversation"
                })
            end
            pcall(function() conv.initiator:sendEvent("PC_Stop") end)
            pcall(function() conv.initiator:sendEvent("PC_Return", {
                instant = opts.instant,
                afterForcedSeatedConversation = conv.seatedConversationMovers and conv.seatedConversationMovers[initiatorId] == true
            }) end)
            core.sendGlobalEvent("PC_ConversationReset", { npc = conv.initiator })
        end

        if not opts.skipActorEvents and canSendConversationCleanup(conv.target) and not skipReturnIds[targetId] then
            if conv.seatedConversationMovers and conv.seatedConversationMovers[targetId] then
                core.sendGlobalEvent("PC_SetSitCooldown", {
                    npc = conv.target,
                    npcId = targetId,
                    seconds = SIT_STAND_COOLDOWN_SECONDS,
                    reason = "seated_conversation"
                })
            end
            pcall(function() conv.target:sendEvent("PC_Stop") end)
            pcall(function() conv.target:sendEvent("PC_Return", {
                instant = opts.instant,
                afterForcedSeatedConversation = conv.seatedConversationMovers and conv.seatedConversationMovers[targetId] == true
            }) end)
            core.sendGlobalEvent("PC_ConversationReset", { npc = conv.target })
        end
    end

    local scheduleRequestId = scheduleInterrupt and scheduleInterrupt.requestId

    if initiatorId then activeConversations[initiatorId] = nil end
    if targetId then activeConversations[targetId] = nil end
    core.sendGlobalEvent("PC_ConversationEnded", {
        initiatorId = initiatorId,
        targetId = targetId,
        scheduleRequestId = scheduleRequestId,
    })

    if scheduleRequestId then
        core.sendGlobalEvent("PC_ScheduleInterruptComplete", {
            requestId = scheduleRequestId,
            npcId = initiatorId,
            targetId = targetId,
        })
    end
end

function ConversationManager.update(dt)
    -- Fix: activeConversations contains two references per conversation (one per NPC).
    -- Iterating pairs() updates the SAME timer twice, causing 2x speed countdown.
    -- We must collect unique conversations first.
    local uniqueConvs = {}
    for _, conv in pairs(activeConversations) do
        uniqueConvs[conv] = true -- Use table as key to deduplicate
    end

    for conv, _ in pairs(uniqueConvs) do
        if conv.isPending then
            conv.pendingTimer = conv.pendingTimer - dt
            if conv.pendingTimer <= 0 then
                conv.isPending = nil
                
                -- CONFLICT RE-VALIDATION
                -- Re-check eligibility: state may have changed from pending_conversation to a
                -- compatible state (e.g. sitting) during the delay. Only abort if the actor is
                -- now invalid, relocating, blacklisted, or in a non-conversable state.
                local initOk = canStartConversation(conv.initiator)
                local targetOk = canStartConversation(conv.target)

                if initOk and targetOk then
                    if abortIfHostile(conv, "pending promotion") then goto continue end
                    -- Transition to active conversation state!
                    core.sendGlobalEvent("PC_StateChanged", { npcId = conv.initiator.id, state = "conversation" })
                    core.sendGlobalEvent("PC_StateChanged", { npcId = conv.target.id, state = "conversation" })
                    executeConversationStart(conv)
                else
                    -- Conflict detected! Abort conversation safely skipping overridden actors
                    local skipReturnIds = {}
                    if not initOk then
                        skipReturnIds[conv.initiator.id] = true
                    end
                    if not targetOk then
                        skipReturnIds[conv.target.id] = true
                    end
                    print(string.format("[ConversationManager] Conflict detected during 1s delay (initiator state=%s, target state=%s). Aborting pending conversation.",
                        tostring(conv.initiator and NPCState.get(conv.initiator.id)),
                        tostring(conv.target and NPCState.get(conv.target.id))))
                    ConversationManager.endConversation(conv, { skipReturnIds = skipReturnIds })
                end
            end
            goto continue
        end

        sendConversationHeartbeat(conv, false)

        -- Safety Check: Ensure actors are valid
        local isValidInit = false
        local isValidTarget = false
        pcall(function() isValidInit = conv.initiator and conv.initiator:isValid() end)
        pcall(function() isValidTarget = conv.target and conv.target:isValid() end)

        local initEnabled = isActorEnabled(conv.initiator)
        local targetEnabled = isActorEnabled(conv.target)
        local initRelocating = isRelocating(conv.initiator)
        local targetRelocating = isRelocating(conv.target)
        local initInTransit = NPCState.isInTransit(conv.initiator.id)
        local targetInTransit = NPCState.isInTransit(conv.target.id)
        local initHostile = NPCState.isHostile(conv.initiator.id)
        local targetHostile = NPCState.isHostile(conv.target.id)
        local scheduleGoodbye = conv.scheduleInterrupt ~= nil or conv.scheduleGoodbyeActive

        if not scheduleGoodbye and (not isValidInit or not isValidTarget or not initEnabled or not targetEnabled
                or initRelocating or targetRelocating
                or initInTransit or targetInTransit
                or initHostile or targetHostile) then
            print(string.format("[ProceduralChatter] Safety check failed: initiator valid=%s enabled=%s relocating=%s hostile=%s, target valid=%s enabled=%s relocating=%s hostile=%s. Cleaning up stale conversation.",
                tostring(isValidInit), tostring(initEnabled), tostring(initRelocating), tostring(initHostile),
                tostring(isValidTarget), tostring(targetEnabled), tostring(targetRelocating), tostring(targetHostile)))
            local skipReturnIds = {}
            if initHostile then skipReturnIds[conv.initiator.id] = true end
            if targetHostile then skipReturnIds[conv.target.id] = true end
            ConversationManager.endConversation(conv, { skipReturnIds = skipReturnIds })
            goto continue
        end

        if conv.state == "Starting" then
            conv.startTimer = (conv.startTimer or 0) - dt
            if conv.startTimer <= 0 then
                conv.startTimer = nil
                local initOk = canStartConversation(conv.initiator)
                local targetOk = canStartConversation(conv.target)
                if initOk and targetOk then
                    conv.state = "Greeting"
                    ConversationManager.playNextStep(conv)
                else
                    local skipReturnIds = {}
                    if not initOk and conv.initiator and conv.initiator.id then
                        skipReturnIds[conv.initiator.id] = true
                    end
                    if not targetOk and conv.target and conv.target.id then
                        skipReturnIds[conv.target.id] = true
                    end
                    print(string.format("[ConversationManager] Start handshake failed (initiator state=%s, target state=%s). Aborting conversation.",
                        tostring(conv.initiator and NPCState.get(conv.initiator.id)),
                        tostring(conv.target and NPCState.get(conv.target.id))))
                    ConversationManager.endConversation(conv, { skipReturnIds = skipReturnIds })
                end
            end
        elseif conv.waitTimer and conv.waitTimer > 0 then
            conv.waitTimer = conv.waitTimer - dt
            if conv.waitTimer <= 0 then
                conv.waitTimer = nil
                ConversationManager.playNextStep(conv)
            end
        elseif conv.state == "Moving" then
            conv.movingTimer = (conv.movingTimer or 0) + dt
            local dist = (conv.initiator.position - conv.target.position):length()
            if dist < 200 then
                print(string.format("[ProceduralChatter] NPCs arrived (Dist: %.2f). Starting dialogue.", dist))

                if not conv.preventFace then
                     conv.initiator:sendEvent("PC_Face", { target = conv.target })
                     conv.target:sendEvent("PC_Face", { target = conv.initiator })
                end
                conv.initiator:sendEvent("PC_StartConversation", { target = conv.target })
                conv.target:sendEvent("PC_StartConversation", { target = conv.initiator })

                conv.state = "Starting"
                conv.startTimer = 0.15
            elseif conv.movingTimer >= MOVING_CONVERSATION_TIMEOUT then
                print(string.format(
                    "[ConversationManager] Moving conversation timed out (dist=%.1f start=%.1f); aborting",
                    dist, conv.movingStartDist or -1))
                ConversationManager.endConversation(conv)
            elseif isRelocating(conv.initiator) or isRelocating(conv.target) then
                print("[ConversationManager] Schedule relocation during Moving; aborting conversation")
                local skipReturnIds = {}
                if isRelocating(conv.initiator) then skipReturnIds[conv.initiator.id] = true end
                if isRelocating(conv.target) then skipReturnIds[conv.target.id] = true end
                ConversationManager.endConversation(conv, { skipReturnIds = skipReturnIds })
            end
        end
        
        ::continue::
    end
end

function ConversationManager.isActive(npc)
    return activeConversations[npc.id] ~= nil
end

function ConversationManager.hasActive()
    for _, _ in pairs(activeConversations) do return true end
    return false
end

function ConversationManager.cancelAll(reason)
    local uniqueConvs = {}
    for _, conv in pairs(activeConversations) do
        uniqueConvs[conv] = true
    end
    for conv, _ in pairs(uniqueConvs) do
        print(string.format("[ConversationManager] Cancelling conversation for %s",
            tostring(reason or "cancel_all")))
        if reason == "cell_change" then
            ConversationManager.endConversation(conv, { instant = true })
        else
            ConversationManager.endConversation(conv, { skipActorEvents = true })
        end
    end
end

--- Cut audio and teleport-resolve all active conversations (e.g. after wait time elapses).
function ConversationManager.wrapUpInstant(reason)
    local uniqueConvs = {}
    for _, conv in pairs(activeConversations) do
        uniqueConvs[conv] = true
    end
    local count = 0
    for conv, _ in pairs(uniqueConvs) do
        count = count + 1
        local initName = conv.initiatorRecordId or "Unknown"
        local targetName = conv.targetRecordId or "Unknown"
        print(string.format("[ConversationManager] Instant wrap-up (%s): %s <-> %s",
            tostring(reason or "instant"), initName, targetName))
        pcall(function() conv.initiator:sendEvent("PC_StopVoice") end)
        pcall(function() conv.target:sendEvent("PC_StopVoice") end)
        ConversationManager.endConversation(conv, { instant = true })
    end
    if count > 0 then
        print(string.format("[ConversationManager] wrapUpInstant done: %d conversation(s)", count))
    end
end

function ConversationManager.forceEndForNpc(npc)
    if not npc then return end
    ConversationManager.forceEndForNpcId(npc.id, npc, "eviction")
end

function ConversationManager.forceEndForNpcId(npcId, npc, reason)
    if not npcId then return end
    local conv = activeConversations[npcId]
    if conv then
        local label = npc and npc.recordId or tostring(npcId)
        print(string.format("[ConversationManager] Force-ending conversation for %s (%s)", label, tostring(reason or "cleanup")))
        local skipReturnIds = nil
        if reason == "eviction" or reason == "schedule_eviction" then
            skipReturnIds = { [npcId] = true }
        end
        ConversationManager.endConversation(conv, {
            skipActorEvents = reason == "disabled"
                or reason == "stale_handle",
            skipReturnIds = skipReturnIds,
        })
    end
end

function ConversationManager.onArrived(data)
    local actor = data.actor
    if not actor then return end
    
    local conv = activeConversations[actor.id]
    if conv and conv.state == "Moving" then
        print(string.format("[ProceduralChatter] Actor %s arrived. Forcing start.", types.NPC.record(actor).name))
        
        -- Face each other now that we arrived (Unless prevented)
        if not conv.preventFace then
            conv.initiator:sendEvent("PC_Face", { target = conv.target })
            conv.target:sendEvent("PC_Face", { target = conv.initiator })
        end
        conv.initiator:sendEvent("PC_StartConversation", { target = conv.target })
        conv.target:sendEvent("PC_StartConversation", { target = conv.initiator })
        
        conv.state = "Greeting"
        ConversationManager.playNextStep(conv)
    end
end

-- Helper: Check if two NPCs have a unique conversation defined.
-- Used by player.lua to allow guards as candidates only for their unique pairs.
function ConversationManager.hasUniqueConversation(npc1, npc2)
    return hasUniqueConversationBetween(npc1, npc2)
end

function ConversationManager.hasGuardSpecificConversation(npc1, npc2)
    if not npc1 or not npc2 then return false end
    if getPlayableUniqueSnippet(npc1, npc2) then return true end
    if not (isGuardActor(npc1) or isGuardActor(npc2)) then return false end

    if ConversationManager.findBestSnippet(npc1, npc2, "SmallTalk", {}) then return true end
    if ConversationManager.findBestSnippet(npc2, npc1, "SmallTalk", {}) then return true end
    return false
end

return ConversationManager
