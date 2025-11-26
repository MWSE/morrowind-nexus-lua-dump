--[[
    init.lua – Weighted Leveled List Picker (final: korrekte Luck, Nachtbonus ×1.50 für Kreaturen)
    Autor: Daniel & ChatGPT (2025)

    Features:
      - Alle Einträge (Items + Creatures) werden immer berücksichtigt (calculateFromAllLevels ignoriert)
      - Luck beeinflusst Items linear: Luck 0 -> -25%, Luck 50 -> 0%, Luck 100 -> +25%
      - Nachtbonus für Kreaturen: zwischen 22:00–04:00, 25% Chance -> Gewicht * 1.50
      - Verschachtelte Listen werden als Kandidaten gelistet und nur bei Auswahl rekursiv aufgelöst
      - Zyklus-Schutz (visited) und einmaliger Re-Pick falls Sub-List nichts liefert
      - Mindestwahrscheinlichkeit pro Eintrag (config.minChance)
]]

local tes3 = tes3
local event = event
local math_random = math.random

-- =========================
-- Konfiguration
-- =========================
local config = {
    enableLog = false,   -- true = Debug-Log an, false = aus
    maxDepth  = 50,      -- maximale Rekursionstiefe (Failsafe)
    minChance = 0.01,    -- minimale Chance pro Eintrag (1% = 0.01)
    rngSeed   = nil,     -- nil = automatisch, sonst Zahl
}

local function log(fmt, ...)
    if config.enableLog then
        mwse.log("[Deleveler] " .. fmt, ...)
    end
end

-- =========================
-- Luck multiplier (Items only)
-- returns multiplier, rawLuck
-- multiplier: 0.75 (luck=0) .. 1.0 (luck=50) .. 1.25 (luck=100)
-- =========================
local function getLuckMultiplier(isCreature)
    if isCreature then
        return 1.0, 50
    end

    local mobile = tes3.mobilePlayer
    if not mobile or not mobile.luck then
        return 1.0, 50
    end
    local luck = mobile.luck.current or 50

    if luck <= 50 then
        local factor = (50 - luck) / 50 -- 0..1
        return 1.0 - 0.25 * factor, luck -- maps 50->1.0, 0->0.75
    else
        local factor = (luck - 50) / 50 -- 0..1
        return 1.0 + 0.25 * factor, luck -- maps 50->1.0, 100->1.25
    end
end

-- =========================
-- Nachtzeit prüfen (22:00 - 04:00)
-- =========================
local function isNightTime()
    local hour = tes3.worldController.hour.value
    return (hour >= 22 or hour < 4)
end

-- =========================
-- Gewichtung nach Level (+ Luck für Items)
-- finalWeight = baseWeight * adjustment
-- =========================
local function getWeightForLevel(level, nodeObject)
    local lvl = level or 1
    local baseWeight = (lvl < 20) and (21 - lvl) or 1

    if nodeObject and nodeObject.objectType == tes3.objectType.leveledItem then
        local luckMult, luck = getLuckMultiplier(false)
        local levelFactor = math.min(lvl / 20, 1.0)
        -- adjustment: positive für hohe Level bei hohem Luck, negativ für niedrige Level
        local adjustment = 1.0 + (levelFactor - 0.5) * (luckMult - 1.0) * 2
        baseWeight = baseWeight * adjustment
        log("getWeightForLevel (Item): lvl=%d base=%.3f luck=%.1f mult=%.3f adj=%.3f -> final=%.3f",
            lvl, (21 - lvl), luck, luckMult, adjustment, baseWeight)
    else
        -- Kreaturen oder nil: kein Luck-Einfluss
        log("getWeightForLevel (Other): lvl=%d base=%.3f -> final=%.3f", lvl, (21 - lvl), baseWeight)
    end

    return baseWeight
end

-- =========================
-- resolveLeveledList(list, depth, visited)
-- - Liefert candidates: { object = <object>, weight = <float>, path = <string> }
-- - Ignoriert calculateFromAllLevels (wir nehmen immer alle nodes)
-- - Berücksichtigt chanceForNothing (Vanilla): sofortiger Abbruch wenn triggered
-- =========================
local function resolveLeveledList(list, depth, visited)
    depth = depth or 0
    visited = visited or {}

    if depth > config.maxDepth then
        log("Max recursion depth reached in list %s", list.id or "<list>")
        return {}
    end

    if list.id and visited[list.id] then
        log("Cyclic reference detected, skipping list %s", list.id)
        return {}
    end
    if list.id then
        visited[list.id] = true
    end

    local indent = string.rep("  ", depth)
    local results = {}

    -- ChanceForNothing (Vanilla)
    local chanceNone = list.chanceForNothing or 0
    if chanceNone > 0 then
        local roll = math_random(100)
        log("%s%s: Chance for nothing %d%%, rolled %d", indent, list.id or "<list>", chanceNone, roll)
        if roll <= chanceNone then
            log("%s%s: Result is nothing due to chanceForNothing", indent, list.id or "<list>")
            if list.id then visited[list.id] = nil end
            return results
        end
    end

    local nodes = list.list or {}

    -- KEIN Filter nach calculateFromAllLevels — alle Einträge berücksichtigen
    for _, node in ipairs(nodes) do
        local obj = node.object
        local nodeLevel = node.levelRequired or 1
        local weight = getWeightForLevel(nodeLevel, obj)
        local objId = (obj and obj.id) or "<nil>"

        -- Nachtbonus: nur für Kreaturen, 25% Chance nachts (22-04) -> weight * 1.50
        if obj and obj.objectType == tes3.objectType.leveledCreature then
            if isNightTime() and math_random() <= 0.25 then
                weight = weight * 1.50
                log("%s%s: Night boost applied (level=%d) -> weight=%.3f", indent, objId, nodeLevel, weight)
            end
        end

        table.insert(results, {
            object = obj,
            weight = weight,
            path = string.format("%s%s", indent, objId)
        })
    end

    if list.id then
        visited[list.id] = nil
    end

    return results
end

-- =========================
-- pickWeightedObject(results, listId, depth, visited, allowRetry)
-- - visited weiterreichen, damit Zyklus-Schutz korrekt ist
-- - allowRetry (default true): bei leerer Sub-List wird einmalig ohne diese Sub-List neu gewählt
-- =========================
local function pickWeightedObject(results, listId, depth, visited, allowRetry)
    depth = depth or 0
    visited = visited or {}
    if allowRetry == nil then allowRetry = true end

    if not results or #results == 0 then
        log("No candidates for list %s", listId or "<list>")
        return nil
    end

    -- Rohgewichte sammeln
    local raw = {}
    local sumRaw = 0.0
    for i, entry in ipairs(results) do
        local w = tonumber(entry.weight) or 0.0
        if w < 0 then w = 0 end
        raw[i] = w
        sumRaw = sumRaw + w
    end

    -- Falls Summe 0 -> gleiche Gewichte
    if sumRaw <= 0 then
        local n = #results
        for i = 1, n do raw[i] = 1.0 end
        sumRaw = n
    end

    -- Roh-Probabilities
    local probs = {}
    for i = 1, #raw do probs[i] = raw[i] / sumRaw end

    -- Mindestchance (config.minChance)
    local minP = config.minChance or 0.01
    local lowIndices = {}
    local highSum = 0.0
    for i = 1, #probs do
        if probs[i] < minP then
            table.insert(lowIndices, i)
        else
            highSum = highSum + probs[i]
        end
    end

    local finalProbs = {}
    local k = #lowIndices
    if k == 0 then
        for i = 1, #probs do finalProbs[i] = probs[i] end
    else
        local remaining = 1.0 - (k * minP)
        if remaining < 0 then
            local n = #results
            for i = 1, n do finalProbs[i] = 1.0 / n end
        else
            for _, idx in ipairs(lowIndices) do finalProbs[idx] = minP end
            if highSum > 0 then
                for i = 1, #probs do
                    if not finalProbs[i] then
                        finalProbs[i] = (probs[i] / highSum) * remaining
                    end
                end
            else
                local nHigh = #results - k
                local each = (nHigh > 0) and (remaining / nHigh) or 0
                for i = 1, #probs do
                    if not finalProbs[i] then finalProbs[i] = each end
                end
            end
        end
    end

    -- Rundungs-Korrektur
    local sumFinal = 0.0
    for _, p in ipairs(finalProbs) do sumFinal = sumFinal + p end
    if sumFinal <= 0 then
        local n = #results
        for i = 1, n do finalProbs[i] = 1.0 / n end
    else
        for i = 1, #finalProbs do finalProbs[i] = finalProbs[i] / sumFinal end
    end

    -- Debug-Log
    if config.enableLog then
        log("Selecting from %d candidates (list %s):", #results, listId or "<list>")
        for i, entry in ipairs(results) do
            local id = entry.object and entry.object.id or "<nil>"
            log("  %2d: %s  prob=%.3f  weight=%.3f  path=%s", i, id, finalProbs[i], raw[i], entry.path or "<no-path>")
        end
    end

    -- Ziehen
    local r = math_random()
    local cum = 0.0
    for i = 1, #finalProbs do
        cum = cum + finalProbs[i]
        if r <= cum then
            local chosen = results[i].object
            local chosenId = chosen and chosen.id or "<nil>"
            log("Picked %s (prob=%.3f roll=%.4f)", chosenId, finalProbs[i], r)

            -- Falls Sub-List (leveledCreature oder leveledItem), löse sie jetzt und picke rekursiv
            if chosen and (
                chosen.objectType == tes3.objectType.leveledCreature or
                chosen.objectType == tes3.objectType.leveledItem
            ) then
                -- resolve mit weitergereichtem visited & erhöhtem depth
                local subresults = resolveLeveledList(chosen, depth + 1, visited)
                local subpick = pickWeightedObject(subresults, chosen.id, depth + 1, visited, allowRetry)
                if subpick then
                    return subpick
                else
                    -- Wenn Sub-List nichts lieferte, versuchen wir einmalig einen Re-Pick ohne diese Sub-List
                    if allowRetry then
                        log("Sub-list %s returned nothing — retrying without it.", chosenId)
                        local newResults = {}
                        for j = 1, #results do
                            if j ~= i then table.insert(newResults, results[j]) end
                        end
                        return pickWeightedObject(newResults, listId, depth, visited, false)
                    end
                    -- kein Retry übrig: return nil (propagiert)
                    log("Sub-list %s returned nothing and no retry allowed.", chosenId)
                    return nil
                end
            end

            -- Normales Objekt (kein Sub-List)
            return chosen
        end
    end

    -- Fallback
    log("Fallback pick for %s", listId or "<list>")
    return results[#results].object
end

-- =========================
-- Event-Handler registrieren
-- =========================
local function onLeveledCreaturePicked(e)
    if not e.list then return end
    local visited = {}
    local candidates = resolveLeveledList(e.list, 0, visited)
    local pick = pickWeightedObject(candidates, e.list.id, 0, visited, true)
    if pick then e.pick = pick end
end

local function onLeveledItemPicked(e)
    if not e.list then return end
    local visited = {}
    local candidates = resolveLeveledList(e.list, 0, visited)
    local pick = pickWeightedObject(candidates, e.list.id, 0, visited, true)
    if pick then e.pick = pick end
end

event.register(tes3.event.leveledCreaturePicked, onLeveledCreaturePicked)
event.register(tes3.event.leveledItemPicked, onLeveledItemPicked)

-- =========================
-- RNG-Seed initialisieren
-- =========================
if config.rngSeed and type(config.rngSeed) == "number" then
    math.randomseed(config.rngSeed)
else
    math.randomseed(os.clock() * 100000)
end
