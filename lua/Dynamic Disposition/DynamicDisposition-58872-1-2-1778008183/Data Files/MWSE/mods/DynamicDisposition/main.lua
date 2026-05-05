local config = require("DynamicDisposition.config")
local data = require("DynamicDisposition.data")

local cachedPlayerFactions = {}
local lastFactionUpdate = 0

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

local function getPlayerRaceId()
    local race = tes3.player.object.race
    return race and race.id:lower() or nil
end

local function safeStat(stat)
    local mp = tes3.mobilePlayer
    local s = mp and mp[stat]
    return (s and s.current) or nil
end

local function getPlayerFactions()
    local list = {}

    for _, faction in ipairs(tes3.dataHandler.nonDynamicData.factions) do
        if faction.playerJoined and not faction.playerExpelled then
            table.insert(list, {
                faction = faction,
                rank = faction.playerRank or 0
            })
        end
    end

    return list
end

local function updatePlayerFactions()
    cachedPlayerFactions = {}

    for _, faction in ipairs(tes3.dataHandler.nonDynamicData.factions) do
        if faction.playerJoined and not faction.playerExpelled then
            cachedPlayerFactions[#cachedPlayerFactions+1] = {
                faction = faction,
                rank = faction.playerRank or 0
            }
        end
    end

    lastFactionUpdate = os.clock()
end
event.register("loaded", updatePlayerFactions)
event.register("initialized", updatePlayerFactions)

local function getRaceReaction(raceA, raceB)
    local aliasA = data.raceAlias and data.raceAlias[raceA] or raceA
    local aliasB = data.raceAlias and data.raceAlias[raceB] or raceB

    local row = data.raceReactions[aliasA]
    if not row then
        return 0
    end

    return row[aliasB] or 0
end

local function dbg(msg, ...)
    if not config.enableDebug then
        return
    end
    local out = string.format("[DD DEBUG] " .. msg, ...)
    mwse.log(out)
end

------------------------------------------------------------
-- Attribute Modifiers
------------------------------------------------------------
local function speechcraftModifier()
    local sc = safeStat("speechcraft") or 0

    local missing = (100 - sc*0.9) / 100
    missing = missing ^ 1.1

    local floor = 0.266 + 0.40 * (1 - (sc / 100) ^ 2.2)
    missing = math.max(missing, floor)

    return -math.round(15 * missing * config.speechcraftScale)
end

local function personalityModifier()
    local p = safeStat("personality") or 0

    local delta = (40 - p) / 50
    delta = math.max(delta, 0)
    local missing = delta ^ 1.1

    local floor = 0.266 + 0.40 * (1 - (p / 100) ^ 2.2)
    missing = math.max(missing, floor)

    return -math.round(15 * missing * config.personalityScale)
end

------------------------------------------------------------
-- Race Modifiers
------------------------------------------------------------
local function raceModifier(npc)
    local playerRace = getPlayerRaceId()
    if not playerRace then
        return 0
    end

    local npcRace = npc.race and npc.race.id:lower()
    if not npcRace then
        return 0
    end

    local reaction = getRaceReaction(npcRace, playerRace)
    return math.floor(reaction * config.raceScale)
end

------------------------------------------------------------
-- Faction Modifiers
------------------------------------------------------------
local function factionModifier(npc)
    local npcFaction = npc.faction
    if not npcFaction then
        return 0
    end

    if os.clock() - lastFactionUpdate > 1.0 then
        updatePlayerFactions()
    end

    local playerFactions = cachedPlayerFactions
    local npcFactionId = npcFaction.id:lower()
    local mod = 0
    
    -- Same faction bonus
    for _, entry in ipairs(playerFactions) do
        if entry.faction.id:lower() == npcFactionId then
            local raw = 5 + entry.rank
            mod = mod + raw * config.factionScale
        end
    end

    -- Inter-faction relationships
    local reactions = data.factionReactions[npcFactionId]
    if reactions then
        for _, entry in ipairs(playerFactions) do
            local pfId = entry.faction.id:lower()
            local reaction = reactions[pfId]
            if reaction then
                mod = mod + reaction * config.factionScale
            end
        end
    end

    return mod
end

--------------------------------------------------------
-- Player fame modifier
--------------------------------------------------------
local function fameModifier()
    local rep = tes3.player.object.reputation or 0
    return math.floor(math.min(math.sqrt(rep), 10) * config.fameScale)
end

------------------------------------------------------------
-- Final modifier calculation
------------------------------------------------------------
local function calculateDispositionModifier(npc)
    local sc = speechcraftModifier()
    local pe = personalityModifier()
    local ra = raceModifier(npc)
    local fa = factionModifier(npc)
    local fm = fameModifier()

    local total = sc + pe + ra + fa + fm

    dbg(
        "Modifiers for %s → SC:%d PE:%d RA:%d FA:%d FM:%d | TOTAL:%d",
        npc.id, sc, pe, ra, fa, fm, total
    )

    return total
end


local function onDispositionCalc(e)
    dbg("CALLED")
    if not e.mobile or e.mobile.actorType ~= tes3.actorType.npc then
        dbg("RETURN")
        return
    end

    local npc = e.reference.object

    -- Engine-calculated disposition
    local vanilla = e.disposition

    -- The modifier we slap ontop
    local mod = calculateDispositionModifier(npc)

    -- Final disposition
    local final = clamp(vanilla + mod, 0, 100)

    dbg(
        "NPC:%s | Vanilla:%d | Mod:%d | Final:%d",
        npc.id, vanilla, mod, final
    )
    e.disposition = final
end

event.register("disposition", onDispositionCalc)

local function registerModConfig()
    require("DynamicDisposition.mcm")
end
event.register("modConfigReady", registerModConfig)
