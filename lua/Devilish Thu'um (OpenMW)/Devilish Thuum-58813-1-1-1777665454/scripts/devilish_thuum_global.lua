-- scripts/devilish_thuum_global.lua

local world = require('openmw.world')
local types = require('openmw.types')

local THUUM_CUSTOM_SCRIPT_PATH = "scripts/devilish_thuum_custom.lua"
local FATIGUE_TARGET_SCRIPT_PATH = "scripts/devilish_thuum_fatigue_target.lua"

local CHECK_DT = 1.0
local FATIGUE_ATTACH_DISTANCE = 5000
local FATIGUE_ATTACH_DISTANCE_SQ = FATIGUE_ATTACH_DISTANCE * FATIGUE_ATTACH_DISTANCE

local DEBUG = false

local MIN_RANDOM_NORD_LEVEL = 20
local RANDOM_NORD_CHANCE = 50

local acc = 0.0

local knownThuumActors = {}
local knownFatigueActors = {}

local GUARANTEED_THUUM_IDS = {
    ["detd_testthuum"] = true,
}

local BLACKLIST_THUUM_IDS = {
    -- ["some_npc_id"] = true,
    ["skaal_guard"] = true,
    ["skaal_guard2"] = true,
    ["skaal_guard_a1"] = true,
    ["skaal_guard_a2"] = true,
    ["skaal_guard_a3"] = true,
    ["skaal_guard_a4"] = true,
    ["sky_guard_re"] = true,

}

local function debugPrint(...)
    if DEBUG then
        print("[detd thuum global]", ...)
    end
end

local function getPlayer()
    return world.players and world.players[1] or nil
end

local function getRecordId(actor)
    if not actor or not actor.recordId then return nil end
    return string.lower(actor.recordId)
end

local function getActorKey(actor)
    return tostring(actor.id or actor.recordId or actor)
end

local function isActorOrCreature(actor)
    return actor
        and actor:isValid()
        and (
            types.NPC.objectIsInstance(actor)
            or types.Creature.objectIsInstance(actor)
        )
end

local function isDead(actor)
    if not isActorOrCreature(actor) then
        return true
    end

    local dead = false
    pcall(function()
        dead = types.Actor.isDead(actor)
    end)

    return dead == true
end

local function distSq(a, b)
    if not a or not b then
        return math.huge
    end

    local d = a - b
    return d.x * d.x + d.y * d.y + d.z * d.z
end

local function actorNearPlayer(actor, player)
    if not actor or not actor:isValid() then return false end
    if not player or not player:isValid() then return false end
    if not actor.cell or not player.cell then return false end
    if not actor.cell:isInSameSpace(player) then return false end

    return distSq(actor.position, player.position) <= FATIGUE_ATTACH_DISTANCE_SQ
end

local function getNpcRecord(actor)
    local record = nil
    pcall(function()
        record = types.NPC.record(actor)
    end)
    return record
end

local function getNpcLevel(actor)
    local level = 1

    pcall(function()
        local levelStat = types.Actor.stats.level(actor)

        if levelStat and type(levelStat.base) == "number" then
            level = levelStat.base
        elseif levelStat and type(levelStat.current) == "number" then
            level = levelStat.current
        end
    end)

    return level
end

local function getNpcRace(actor)
    local record = getNpcRecord(actor)
    local race = record and record.race or ""

    if type(race) ~= "string" then
        race = ""
    end

    return string.lower(race)
end

local function isMaleNpc(actor)
    local record = getNpcRecord(actor)
    return record and record.isMale == true
end

local function isBlacklisted(actor)
    local id = getRecordId(actor)
    return id and BLACKLIST_THUUM_IDS[id] == true
end

local function isGuaranteedActor(actor)
    local id = getRecordId(actor)
    return id and GUARANTEED_THUUM_IDS[id] == true
end



local LOW_LEVEL_NORD_CHANCE = 5 -- 1%

local function isRandomHighLevelMaleNord(actor)
    if not actor or not actor:isValid() then
        return false, "invalid"
    end

    if not types.NPC.objectIsInstance(actor) then
        return false, "not_npc"
    end

    local level = getNpcLevel(actor)
    local race = getNpcRace(actor)
    local male = isMaleNpc(actor)
    local id = getRecordId(actor) or "no_id"

    debugPrint(
        "checking npc:",
        id,
        "level=", level,
        "race=", race,
        "male=", tostring(male)
    )

    if not male then
        return false, "not_male"
    end

    if race ~= "nord" then
        return false, "not_nord"
    end

    local roll = math.random(100)

    -- ❌ below 9 = NEVER
    if level < 9 then
        return false, "too_low_for_thuum"
    end

    -- 🔥 10 → threshold (rare case)
    if level < MIN_RANDOM_NORD_LEVEL then
        debugPrint(
            "mid-level rare roll for",
            id,
            "=",
            roll,
            "needed <=",
            LOW_LEVEL_NORD_CHANCE
        )

        if roll <= LOW_LEVEL_NORD_CHANCE then
            return true, "mid_level_rare_nord"
        end

        return false, "below_threshold"
    end

    -- 🔥 normal high-level case
    debugPrint(
        "roll for",
        id,
        "=",
        roll,
        "needed <=",
        RANDOM_NORD_CHANCE
    )

    if roll <= RANDOM_NORD_CHANCE then
        return true, "random_high_level_male_nord"
    end

    return false, "failed_roll"
end

local function shouldAttachThuumScript(actor)
    if not actor or not actor:isValid() or not actor.recordId then
        return false, "invalid_or_no_record"
    end

    if isBlacklisted(actor) then
        return false, "blacklisted"
    end

    if isGuaranteedActor(actor) then
        return true, "guaranteed_id"
    end

    return isRandomHighLevelMaleNord(actor)
end

local function attachThuumScript(actor, player, reason)
    if not actor:hasScript(THUUM_CUSTOM_SCRIPT_PATH) then
        actor:addScript(THUUM_CUSTOM_SCRIPT_PATH)
        debugPrint("ATTACHED", THUUM_CUSTOM_SCRIPT_PATH, "to", getRecordId(actor) or "no_id", "reason:", reason)
    end

    actor:sendEvent('DETD_ThuumPlayerRef', {
        player = player
    })
end

local function processThuumActor(actor, player)
    if not actor or not actor:isValid() or not actor.recordId then
        return
    end

    if isDead(actor) then
        return
    end

    local key = getActorKey(actor)

    if knownThuumActors[key] ~= nil then
        if knownThuumActors[key] == true then
            attachThuumScript(actor, player, "known_true")
        end
        return
    end

    local shouldAttach, reason = shouldAttachThuumScript(actor)
    knownThuumActors[key] = shouldAttach

    if shouldAttach then
        attachThuumScript(actor, player, reason)
    else
        debugPrint("skipped", getRecordId(actor) or "no_id", "reason:", reason)
    end
end

local function shouldHaveFatigueReceiver(actor, player)
    if not isActorOrCreature(actor) then
        return false
    end

    if actor == player then
        return false
    end

    if isDead(actor) then
        return false
    end

    return actorNearPlayer(actor, player)
end

local function attachFatigueReceiver(actor)
    local key = getActorKey(actor)

    if knownFatigueActors[key] == true then
        return
    end

    knownFatigueActors[key] = true

    if not actor:hasScript(FATIGUE_TARGET_SCRIPT_PATH) then
        actor:addScript(FATIGUE_TARGET_SCRIPT_PATH)
        debugPrint("attached fatigue receiver to", getRecordId(actor) or "no_id")
    end
end

local function detachFatigueReceiver(actor)
    local key = getActorKey(actor)

    if knownFatigueActors[key] ~= true then
        return
    end

    knownFatigueActors[key] = nil

    if actor and actor:isValid() and actor:hasScript(FATIGUE_TARGET_SCRIPT_PATH) then
        actor:sendEvent('DETD_ThuumFatigueCleanup')
        actor:removeScript(FATIGUE_TARGET_SCRIPT_PATH)
        debugPrint("removed fatigue receiver from", getRecordId(actor) or "no_id")
    end
end

local function processFatigueReceiver(actor, player)
    if shouldHaveFatigueReceiver(actor, player) then
        attachFatigueReceiver(actor)
    else
        detachFatigueReceiver(actor)
    end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            acc = acc + dt
            if acc < CHECK_DT then
                return
            end

            acc = 0.0

            local player = getPlayer()
            if not player or not player:isValid() then
                debugPrint("no valid player")
                return
            end

            for _, actor in ipairs(world.activeActors) do
                processFatigueReceiver(actor, player)
                processThuumActor(actor, player)
            end
        end
    }
}