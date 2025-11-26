-- pre-alpha v4.1 — versión con exclusión de dwemer, personajes únicos y draugr

local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local async = require("openmw.async")
local nearby = require("openmw.nearby")
local aux_util = require("openmw_aux.util")

local FIGHT_THRESHOLD = 75
local RANGE_MULTIPLIER = 150
local ERRATIC_ATTACK_CHANCE = 0.5
local ERRATIC_GIVEUP_CHANCE = 0.3

local satiatedUntil = {}

-- 🚫 Exclusión de criaturas dwemer por leveled list o ID
local function isDwemerConstruct(actor)
    if not actor or not actor.recordId then return false end
    local id = actor.recordId:lower()

    -- Exclusión por nombre en el recordId
    if id:find("centurion") or id:find("dwemer") or id:find("steam") or id:find("sphere") then
        return true
    end

    return false
end

-- 🚫 Exclusión de personajes únicos
local excludedUniques = {
    ["almalexia"] = true,
    ["almalexia_warrior"] = true,
    ["vivec_god"] = true,
    ["yagrum bagarn"] = true,
}
local function isExcludedUnique(actor)
    if not actor or not actor.recordId then return false end
    local id = actor.recordId:lower()
    return excludedUniques[id] or false
end

-- 🚫 Exclusión de draugr (cualquier variante)
local function isExcludedDraugr(actor)
    if not actor or not actor.recordId then return false end
    local id = actor.recordId:lower()
    return id:find("draugr") ~= nil
end

-- ⏱️ Duración de saciedad aleatoria según fight value
local function getSatiationDuration(recordId)
    local fight = types.Actor.stats.ai.fight(self).modified
    local min, max = 50, 60
    if fight >= 90 then
        min, max = 25, 35
    elseif fight >= 75 then
        min, max = 35, 45
    elseif fight >= 60 then
        min, max = 45, 55
    elseif fight >= 45 then
        min, max = 55, 65
    elseif fight >= 30 then
        min, max = 65, 75
    else
        min, max = 75, 85
    end
    return math.random(min, max)
end

-- ☣️ Comportamiento patológico por variante textual
local function getPathologyBehavior(recordId)
    if not recordId then return {} end
    local id = recordId:lower()
    if id:find("blighted") or id:find("_b$") then
        return { ignoreHierarchy = true, alwaysFight = true }
    elseif id:find("diseased") or id:find("_dis") or id:find("_d$") then
        return { erraticFight = true, avoidHealthy = true }
    end
    return {}
end

-- Exclusiones por grupo (ejemplo kwama/scrib)
local exclusionGroups = {
    kwama = { "kwama", "scrib" },
    scrib = { "kwama" },
}

local function isExcludedByMovement(predator, prey)
    local predatorRec = types.Creature.record(predator)
    local preyRec = types.Creature.record(prey)
    if predatorRec.canSwim and preyRec.canFly then
        return true
    end
    return false
end

local function isForcedAggressionByMovement(predator, prey)
    local predatorRec = types.Creature.record(predator)
    local preyRec = types.Creature.record(prey)
    if predatorRec.canFly and preyRec.canSwim then
        return true
    end
    return false
end

local function isExcludedByGroup(predatorId, preyId)
    local predatorIdLower = predatorId:lower()
    local preyIdLower = preyId:lower()
    for group, exclusions in pairs(exclusionGroups) do
        if predatorIdLower:find(group) then
            for _, keyword in ipairs(exclusions) do
                if preyIdLower:find(keyword) then
                    return true
                end
            end
        end
    end
    return false
end

local function sharesSignificantWord(idA, idB)
    local wordsA = {}
    for word in idA:lower():gmatch("[a-z]+") do
        if #word >= 4 then wordsA[word] = true end
    end
    for word in idB:lower():gmatch("[a-z]+") do
        if #word >= 4 and wordsA[word] then
            return true
        end
    end
    return false
end

local function isSatiated(actor)
    local cooldown = satiatedUntil[actor.id]
    return cooldown and os.time() < cooldown
end

local function markSatiationIfKill(actor, target)
    async:newUnsavableSimulationTimer(3, function()
        if target and types.Actor.isDead(target) then
            local duration = getSatiationDuration(actor.recordId)
            satiatedUntil[actor.id] = os.time() + duration
        end
    end)
end

local function engageCombat(target)
    ai.startPackage({ type = "Combat", target = target, cancelOther = false })
    markSatiationIfKill(self, target)
end

local function isValidTarget(actor, selfFight, selfPathology)
    if actor.type ~= types.Creature then return false end
    if types.Creature.record(actor).type ~= 0 then return false end
    if types.Actor.isDead(actor) then return false end

    -- Exclusiones globales
    if isDwemerConstruct(actor) or isExcludedUnique(actor) or isExcludedDraugr(actor) then
        return false
    end

    if isForcedAggressionByMovement(self, actor) then
        return true
    end

    local targetId = actor.recordId
    local targetFight = types.Actor.stats.ai.fight(actor).modified
    local targetPathology = getPathologyBehavior(targetId)

    if not selfPathology.ignoreHierarchy and not selfPathology.erraticFight then
        if not targetPathology.ignoreHierarchy and not targetPathology.erraticFight then
            if sharesSignificantWord(self.recordId, targetId) then
                return false
            end
        end
    end

    if selfPathology.ignoreHierarchy then
        if targetPathology.alwaysFight then return false end
        return true
    end

    if isExcludedByGroup(self.recordId, targetId) or isExcludedByMovement(self, actor) then
        return false
    end

    if selfPathology.avoidHealthy and not targetPathology.ignoreHierarchy and not targetPathology.erraticFight then
        if math.random() > 0.5 then return false end
    end

    return selfFight >= targetFight
end

local function wildlifeAtk()
    async:newUnsavableSimulationTimer(3, wildlifeAtk)

    local health = types.Actor.stats.dynamic.health(self).current
    if health < 1 then return end
    if self.type ~= types.Creature then return end
    if types.Creature.record(self).type ~= 0 then return end

    -- Exclusiones globales
    if isDwemerConstruct(self) or isExcludedUnique(self) or isExcludedDraugr(self) then
        return end

    if isSatiated(self) then return end

    local selfFight = types.Actor.stats.ai.fight(self).modified
    if selfFight < FIGHT_THRESHOLD then return end

    local selfPathology = getPathologyBehavior(self.recordId)
    local selfPos = self.position

    local validNearbyCreatures = {}
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.Creature
           and types.Creature.record(actor).type == 0
           and not types.Actor.isDead(actor)
           and not isDwemerConstruct(actor)
           and not isExcludedUnique(actor)
           and not isExcludedDraugr(actor) then
            table.insert(validNearbyCreatures, actor)
        end
    end

    local targetCreature, distToTarget = aux_util.findMinScore(validNearbyCreatures, function(actor)
        return isValidTarget(actor, selfFight, selfPathology) and (selfPos - actor.position):length()
    end)

    if not targetCreature then return end

    if selfPathology.alwaysFight then
        local targetPathology = getPathologyBehavior(targetCreature.recordId)
        if not targetPathology.alwaysFight then
            local range = (selfFight - FIGHT_THRESHOLD) * RANGE_MULTIPLIER
            if distToTarget < range then engageCombat(targetCreature) end
        end
        return
    end

    local range = (selfFight - FIGHT_THRESHOLD) * RANGE_MULTIPLIER
    if distToTarget < range then
        if selfPathology.erraticFight and math.random() > ERRATIC_ATTACK_CHANCE then return end
        engageCombat(targetCreature)
    elseif selfPathology.erraticFight and math.random() < ERRATIC_GIVEUP_CHANCE then
        local duration = getSatiationDuration(self.recordId)
        satiatedUntil[self.id] = os.time() + duration
    end
end

-- ⏱️ Inicia el ciclo ecológico
async:newUnsavableSimulationTimer(1, wildlifeAtk)