local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')

local D = require('scripts.BMSO.definition')
local S = require('scripts.BMSO.settings')
local C = require("scripts.BMSO.common")

local Skills = core.stats.Skill.records
local Attributes = core.stats.Attribute.records
local fFatigueBase = core.getGMST("fFatigueBase")
local fDispositionMod = core.getGMST("fDispositionMod")

local hasBarter
local player
local mods
local state

local function getMods(actor)
    local actorStats = {}
    for statId, type in pairs(C.statTypes) do
        actorStats[statId] = C.getMod(T.NPC.stats[type][statId](actor))
    end
    return actorStats
end

local function getBases(actor)
    local actorStats = {}
    for statId, type in pairs(C.statTypes) do
        actorStats[statId] = T.NPC.stats[type][statId](actor).base
    end
    return actorStats
end

local function initStats(pc)
    hasBarter = self.type.record(self).servicesOffered["Barter"]
    player = pc
    mods = {
        npc = getMods(self),
        pc = getMods(player),
    }
end

local function npcStat(statId)
    return state.bases.npc[statId] + mods.npc[statId]
end

local function pcStat(statId)
    return state.bases.pc[statId] + mods.pc[statId]
end

local function getMinPriceBarterMercantile(minPercent, maxPercent)
    local a = math.min(pcStat(Skills.mercantile.id), 100)
    local b = math.min(0.1 * pcStat(Attributes.luck.id), 10)
    local c = math.min(0.2 * pcStat(Attributes.personality.id), 10)
    local e = math.min(0.1 * npcStat(Attributes.luck.id), 10)
    local f = math.min(0.2 * npcStat(Attributes.personality.id), 10)

    local common = state.disposition - 50 + a + b + c - e - f
    local minMercantile = maxPercent < 0.75 and (common + 100 * (1 - 2 * maxPercent) / fFatigueBase) or 0
    local maxMercantile = minPercent > 0 and (common + 100 * (1 - 2 * minPercent) / fFatigueBase) or math.huge
    return minMercantile, maxMercantile
end

local function computeBuffs()
    state = {
        bases = { npc = getBases(self), pc = getBases(player) },
        disposition = math.max(0, math.min(100, T.NPC.getDisposition(self, player))),
        buffs = {},
    }

    local npcLevel = C.npcLevelOverrides[self.recordId]
    if not npcLevel then
        npcLevel = T.NPC.stats.level(self).current
    else
        C.log(string.format("\"%s\" level override to %d", self.recordId, npcLevel))
    end

    local baseSkill = D.baseSkill(npcLevel)

    local playerLevel = T.Player.stats.level(player).current
    local serviceDifficulty = S.storage:get("serviceDifficulty")
    local hagglingDifficulty = S.storage:get("hagglingDifficulty")
    local persuasionDifficulty = S.storage:get("persuasionDifficulty")
    local serviceDifficultyPercent = D.difficultyPercent(serviceDifficulty, playerLevel) / 100
    local hagglingDifficultyPercent = D.difficultyPercent(hagglingDifficulty, playerLevel) / 100
    local persuasionDifficultyPercent = D.difficultyPercent(persuasionDifficulty, playerLevel) / 100

    local baseServiceSkills = baseSkill * serviceDifficultyPercent + mods.npc.mercantile
    local baseHagglingSkills = baseSkill * hagglingDifficultyPercent + mods.npc.mercantile
    local basePersuasionSkills = baseSkill * persuasionDifficultyPercent + mods.npc.speechcraft
    local capMinSkills = S.storage:get("preventSkillsBelowOriginalValues")

    local barterMercantile, baseGold, goldBasedMercantile, minMercantilePrice, maxMercantilePrice = 0, 0, 0, 0, 0
    if hasBarter then
        baseGold = self.type.record(self).baseGold or 0
        goldBasedMercantile = D.minSkill + serviceDifficultyPercent * (100 - D.minSkill) * (baseGold / (5000 - D.minSkill)) ^ 0.5
        minMercantilePrice, maxMercantilePrice = getMinPriceBarterMercantile(
                S.storage:get("minItemSalePricePercent") / 100,
                S.storage:get("maxItemSalePricePercent") / 100)
        barterMercantile = (baseServiceSkills + goldBasedMercantile) / 2
        if barterMercantile < minMercantilePrice then
            barterMercantile = minMercantilePrice
        elseif barterMercantile > maxMercantilePrice then
            barterMercantile = maxMercantilePrice
        end
        if capMinSkills then
            barterMercantile = math.max(npcStat(Skills.mercantile.id), barterMercantile)
        end
    end

    if capMinSkills then
        baseServiceSkills = math.max(npcStat(Skills.mercantile.id), baseServiceSkills)
        baseHagglingSkills = math.max(npcStat(Skills.mercantile.id), baseHagglingSkills)
        basePersuasionSkills = math.max(npcStat(Skills.speechcraft.id), basePersuasionSkills)
    end

    state.buffs.mercantile = {
        [C.buffType.service] = baseServiceSkills,
        [C.buffType.barter] = barterMercantile,
        [C.buffType.haggling] = baseHagglingSkills,
        [C.buffType.persuasion] = basePersuasionSkills,
    }
    state.buffs.speechcraft = {
        [C.buffType.persuasion] = basePersuasionSkills,
    }

    C.log(string.format("\"%s\": Level %s, mercantile %d, speechcraft %d\n"
            .. "\tservice skills %d * difficulty %.2f = %.2f\n"
            .. "\tbarter skills ( %.2f + %.2f ) / 2 = %.2f\n"
            .. "\t\tmin for max price %d\n"
            .. "\t\tmax for min price %d\n"
            .. "\t\tbase bolg %d\n"
            .. "\thaggling skills %d * difficulty %.2f = %.2f\n"
            .. "\tpersuasion skills %d + difficulty %.2f = %.2f",
            self.recordId, npcLevel, state.bases.npc.mercantile, state.bases.npc.speechcraft,
            baseSkill, serviceDifficultyPercent, baseServiceSkills,
            baseServiceSkills, goldBasedMercantile, (baseServiceSkills + goldBasedMercantile) / 2,
            minMercantilePrice,
            maxMercantilePrice,
            baseGold,
            baseSkill, hagglingDifficultyPercent, baseHagglingSkills,
            baseSkill, persuasionDifficultyPercent, basePersuasionSkills))
end

local function capBuff(buff, stat)
    if buff > 0 then
        return math.min(buff, math.max(0, 100 - stat))
    else
        return math.max(buff, -stat)
    end
end

local function getBuffs(kind)
    if kind == C.buffType.persuasion then
        return {
            npc = {
                { statId = Skills.mercantile.id, value = state.buffs.mercantile[kind] - npcStat(Skills.mercantile.id) },
                { statId = Skills.speechcraft.id, value = state.buffs.speechcraft[kind] - npcStat(Skills.speechcraft.id) },
                { statId = Attributes.luck.id, value = mods.npc.luck },
            },
            pc = {
                { statId = Skills.mercantile.id, value = mods.pc.mercantile },
                { statId = Skills.speechcraft.id, value = mods.pc.speechcraft },
                { statId = Attributes.luck.id, value = mods.pc.luck },
            },
        }
    end

    local buffs = {
        npc = {
            { statId = Skills.speechcraft.id, value = mods.npc.speechcraft },
        },
        pc = {
            { statId = Skills.speechcraft.id, value = mods.pc.speechcraft },
        }
    }

    -- set merchant's luck at max (capped at 100)
    local npcLuckBuff = math.max(0, 100 - npcStat(Attributes.luck.id))
    -- set player's luck at max (capped at 100)
    local pcLuckBuff = math.max(0, 100 - pcStat(Attributes.luck.id))

    -- skill buff (capped at 100)
    local npcSkillBuff = state.buffs.mercantile[kind] - math.min(100, npcStat(Skills.mercantile.id))
    local npcInitialSkillBuff = npcSkillBuff
    -- compensate the NPC's luck buff
    npcSkillBuff = npcSkillBuff - npcLuckBuff / 10
    -- compensate the player's luck buff
    local pcSkillBuff = -pcLuckBuff / 10
    local pcSkillCappedBuff = 0

    -- limit the buff to prevent a value below 0 or above 100
    local npcSkillCappedBuff = capBuff(npcSkillBuff, npcStat(Skills.mercantile.id))
    if npcSkillCappedBuff ~= 0 then
        npcSkillBuff = npcSkillBuff - npcSkillCappedBuff
    end

    -- skill buff is not enough
    -- alter the player's skill to apply the NPC's remaining buff
    pcSkillBuff = pcSkillBuff - npcSkillBuff
    pcSkillCappedBuff = capBuff(pcSkillBuff, pcStat(Skills.mercantile.id))
    if pcSkillCappedBuff ~= 0 then
        pcSkillBuff = pcSkillBuff - pcSkillCappedBuff
    end

    -- apply skill buffs
    table.insert(buffs.npc, {
        statId = Skills.mercantile.id,
        value = mods.npc.mercantile + npcSkillCappedBuff - pcSkillBuff
    })
    table.insert(buffs.pc, {
        statId = Skills.mercantile.id,
        value = mods.pc.mercantile + pcSkillCappedBuff
    })

    local npcHagglingBuff, pcHagglingDispTerm = 0, 0
    if kind == C.buffType.barter then
        local dispFactor = S.storage:get("dispositionImpactOnHagglingPercent") / 100
        pcHagglingDispTerm = fDispositionMod * (state.disposition - 50) * (1 - dispFactor)
        -- buffs for haggling
        npcHagglingBuff = state.buffs.mercantile[C.buffType.haggling] - npcStat(Skills.mercantile.id) - npcInitialSkillBuff + pcHagglingDispTerm
        if npcHagglingBuff > 0 then
            npcLuckBuff = npcLuckBuff + npcHagglingBuff * 10
        else
            pcLuckBuff = pcLuckBuff - npcHagglingBuff * 10
        end
    end

    -- apply luck buffs
    table.insert(buffs.npc, {
        statId = Attributes.luck.id,
        value = mods.npc.luck + npcLuckBuff
    })
    table.insert(buffs.pc, {
        statId = Attributes.luck.id,
        value = mods.pc.luck + pcLuckBuff
    })

    C.log(string.format("\"%s\" and player's buffs for %s:\n"
            .. "npcLuckBuff %d, pcLuckBuff %d\n"
            .. "npcInitialSkillBuff %.2f, npcSkillBuff %.2f, npcSkillCappedBuff %.2f, pcSkillBuff %.2f, pcSkillCappedBuff %.2f\n"
            .. "npcHagglingBuff %.2f, pcHagglingDispTerm %.2f",
            self.recordId, kind,
            npcLuckBuff, pcLuckBuff,
            npcInitialSkillBuff, npcSkillBuff, npcSkillCappedBuff, pcSkillBuff, pcSkillCappedBuff,
            npcHagglingBuff, pcHagglingDispTerm))
    return buffs
end

local function restoreStats()
    local modifiers = {}
    for statId, mod in pairs(mods.npc) do
        if C.statsToRestore[statId] then
            table.insert(modifiers, { statId = statId, value = mod })
        end
    end
    C.buffStats(self, modifiers)
    modifiers = {}
    for statId, mod in pairs(mods.pc) do
        if C.statsToRestore[statId] then
            table.insert(modifiers, { statId = statId, value = mod })
        end
    end
    player:sendEvent(D.events.modStats, modifiers)
    C.log(string.format("\"%s\": Restored stats", self.recordId))
end

local function handleStats(operations)
    for _, op in ipairs(operations) do
        if op.type == C.operationType.saveStats then
            initStats(op.player)
        elseif op.type == C.operationType.computeStats then
            computeBuffs(op.barter)
        elseif op.type == C.operationType.buff then
            local buffs = getBuffs(op.kind)
            C.buffStats(self, buffs.npc)
            player:sendEvent(D.events.modStats, buffs.pc)
        elseif op.type == C.operationType.restore then
            restoreStats()
            hasBarter = nil
            player = nil
            mods = nil
            state = nil
        else
            error("Error: Invalid operation type " .. op.type)
        end
    end
end

return {
    eventHandlers = {
        [D.events.handleStats] = handleStats,
    },
}