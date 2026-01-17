local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')
local util = require('openmw.util')

local log = require("scripts.BMS.util.log")
local mDef = require('scripts.BMS.config.definition')
local mS = require('scripts.BMS.config.settings')
local mC = require("scripts.BMS.common")
local mH = require("scripts.BMS.util.helpers")

local L = core.l10n(mDef.MOD_NAME)

local Skills = core.stats.Skill.records
local Attributes = core.stats.Attribute.records

local record
local hasBarter
local player
local mods
local state

local function initStats(pc)
    record = self.type.record(self)
    hasBarter = record.servicesOffered["Barter"]
    player = pc
    mods = {
        npc = mC.getMods(self),
        pc = mC.getMods(player),
    }
end

local function npcStat(statId)
    return state.bases.npc[statId] + mods.npc[statId]
end

local function pcStat(statId)
    return state.bases.pc[statId] + mods.pc[statId]
end

local function getMinMaxPriceBarterMercantile(minPercent, maxPercent)
    local a = math.min(pcStat(Skills.mercantile.id), 100)
    local b = math.min(0.1 * pcStat(Attributes.luck.id), 10)
    local c = math.min(0.2 * pcStat(Attributes.personality.id), 10)
    local e = math.min(0.1 * npcStat(Attributes.luck.id), 10)
    local f = math.min(0.2 * npcStat(Attributes.personality.id), 10)

    local common = state.disposition - 50 + a + b + c - e - f
    local minMercantile = maxPercent < 0.75 and (common + 100 * (1 - 2 * maxPercent) / mC.GMSTs.fFatigueBase) or 0
    local maxMercantile = minPercent > 0 and (common + 100 * (1 - 2 * minPercent) / mC.GMSTs.fFatigueBase) or math.huge
    return minMercantile, maxMercantile
end

local function computeStats()
    state = {
        bases = { npc = mC.getBases(self), pc = mC.getBases(player) },
        disposition = math.max(0, math.min(100, T.NPC.getDisposition(self, player))),
        skills = {},
    }

    local npcLevel = mC.npcLevelOverrides[self.recordId]
    if not npcLevel then
        npcLevel = T.NPC.stats.level(self).current
    else
        log(string.format("Level override to %d", npcLevel))
    end

    local baseSkill = mDef.baseSkill(npcLevel)

    local playerLevel = T.Player.stats.level(player).current
    local serviceDifficulty = mS.globalStorage:get("serviceDifficulty")
    local hagglingDifficulty = mS.globalStorage:get("hagglingDifficulty")
    local persuasionDifficulty = mS.globalStorage:get("persuasionDifficulty")
    local serviceDifficultyPercent = mDef.difficultyPercent(serviceDifficulty, playerLevel) / 100
    local hagglingDifficultyPercent = mDef.difficultyPercent(hagglingDifficulty, playerLevel) / 100
    local persuasionDifficultyPercent = mDef.difficultyPercent(persuasionDifficulty, playerLevel) / 100

    local baseServiceSkills = baseSkill * serviceDifficultyPercent + mods.npc.mercantile
    local baseHagglingSkills = baseSkill * hagglingDifficultyPercent + mods.npc.mercantile
    local basePersuasionSkills = baseSkill * persuasionDifficultyPercent + mods.npc.speechcraft
    local capMinSkills = mS.globalStorage:get("preventSkillsBelowOriginalValues")

    local baseGold, goldBasedMercantile, barterMercantile = 0, 0, 0
    local minPriceMercantile, maxPriceMercantile = 0, 0
    local barterDispDiff = 0
    if hasBarter then
        baseGold = self.type.record(self).baseGold or 0
        goldBasedMercantile = mDef.minSkill + serviceDifficultyPercent * (100 - mDef.minSkill) * (baseGold / (5000 - mDef.minSkill)) ^ 0.5
        minPriceMercantile, maxPriceMercantile = getMinMaxPriceBarterMercantile(
                mS.globalStorage:get("minItemSalePricePercent") / 100,
                mS.globalStorage:get("maxItemSalePricePercent") / 100)
        barterMercantile = (baseServiceSkills + goldBasedMercantile) / 2

        local barterDispFactor = mS.globalStorage:get("dispositionImpactOnPricesPercent") / 100
        barterDispDiff = (1 - barterDispFactor) * (state.disposition - 50)
        barterMercantile = barterMercantile + barterDispDiff

        if barterMercantile < minPriceMercantile then
            barterMercantile = minPriceMercantile
        elseif barterMercantile > maxPriceMercantile then
            barterMercantile = maxPriceMercantile
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

    state.skills.mercantile = {
        [mC.buffType.service] = baseServiceSkills,
        [mC.buffType.barter] = barterMercantile,
        [mC.buffType.haggling] = baseHagglingSkills,
        [mC.buffType.persuasion] = basePersuasionSkills,
    }
    state.skills.speechcraft = {
        [mC.buffType.persuasion] = basePersuasionSkills,
    }

    log(string.format("Level %s, mercantile %d, speechcraft %d\n"
            .. "\tservice skills %d * difficulty %.2f + mod %d = %.2f\n"
            .. "\tbarter skills ( base %.2f + gold %.2f ) / 2 + disp %.2f = %.2f\n"
            .. "\t\tmin for max price %d\n"
            .. "\t\tmax for min price %d\n"
            .. "\t\tbase bolg %d\n"
            .. "\thaggling skills %d * difficulty %.2f = %.2f\n"
            .. "\tpersuasion skills %d + difficulty %.2f = %.2f\n"
            .. "\tdisposition %d",
            npcLevel, state.bases.npc.mercantile, state.bases.npc.speechcraft,
            baseSkill, serviceDifficultyPercent, mods.npc.mercantile, baseServiceSkills,
            baseServiceSkills, goldBasedMercantile, barterDispDiff, (baseServiceSkills + goldBasedMercantile) / 2 - barterDispDiff,
            minPriceMercantile,
            maxPriceMercantile,
            baseGold,
            baseSkill, hagglingDifficultyPercent, baseHagglingSkills,
            baseSkill, persuasionDifficultyPercent, basePersuasionSkills,
            state.disposition))
end

local function getNewMods(kind)
    local newMods = { npc = mH.copyMap(mods.npc), pc = mH.copyMap(mods.pc) }
    if kind == mC.buffType.persuasion then
        newMods.npc[Skills.mercantile.id] = util.round(state.skills.mercantile[kind] - npcStat(Skills.mercantile.id))
        newMods.npc[Skills.speechcraft.id] = util.round(state.skills.speechcraft[kind] - npcStat(Skills.speechcraft.id))
        newMods.npc[Attributes.luck.id] = util.round(mods.npc.luck)
        newMods.pc[Skills.mercantile.id] = util.round(mods.pc.mercantile)
        newMods.pc[Skills.speechcraft.id] = util.round(mods.pc.speechcraft)
        newMods.pc[Attributes.luck.id] = util.round(mods.pc.luck)
        return newMods
    end

    newMods.npc[Skills.speechcraft.id] = util.round(mods.npc.speechcraft)
    newMods.pc[Skills.speechcraft.id] = util.round(mods.pc.speechcraft)

    -- Initial expected skill value
    local npcSkillModded = state.skills.mercantile[kind]

    -- Compute the max luck mod diffs (capped at 100 for bartering)
    local npcLuckModDiff = math.max(0, 100 - npcStat(Attributes.luck.id))
    local pcLuckModDiff = math.max(0, 100 - pcStat(Attributes.luck.id))
    -- Compensate those luck mods on the NPC modded skill
    npcSkillModded = npcSkillModded - npcLuckModDiff / 10 + pcLuckModDiff / 10

    local npcMerc = npcStat(Skills.mercantile.id)
    local pcMerc = pcStat(Skills.mercantile.id)
    local npcSkillModDiff = 0
    local pcSkillModDiff = 0

    -- Bartering caps PC's mercantile at 100
    -- Reduce the final value to 100, and compensate with luck points above 100
    if pcMerc > 100 then
        pcSkillModDiff = 100 - pcMerc
        pcLuckModDiff = pcLuckModDiff - (100 - pcMerc) * 10
    end

    -- If the skill goes above 100 or below 0, apply the opposite excess on the player's skill mod
    -- Because values above 100 are capped for bartering, and negative are not supported
    if npcSkillModded > 100 then
        npcSkillModDiff = 100 - npcMerc
        pcSkillModDiff = pcSkillModDiff + 100 - npcSkillModded
        local pcSkillModded = pcSkillModDiff + pcMerc
        -- If the PC would get a skill value below 0, then prefer increasing the NPC skill above 100 to preserve the haggling formula
        if pcSkillModded < 0 then
            npcSkillModDiff = npcSkillModDiff - pcSkillModded
            pcSkillModDiff = pcSkillModDiff - pcSkillModded
        end
    elseif npcSkillModded < 0 then
        npcSkillModDiff = -npcMerc
        pcSkillModDiff = pcSkillModDiff - npcSkillModded
    else
        npcSkillModDiff = npcSkillModded - npcMerc
    end

    -- Set skill mods
    newMods.npc[Skills.mercantile.id] = util.round(mods.npc.mercantile + npcSkillModDiff)
    newMods.pc[Skills.mercantile.id] = util.round(mods.pc.mercantile + pcSkillModDiff)

    local npcHagglingModDiff, pcHagglingDispTerm = 0, 0
    if kind == mC.buffType.barter then
        -- Mods for haggling
        local dispFactor = mS.globalStorage:get("dispositionImpactOnHagglingPercent") / 100
        pcHagglingDispTerm = mC.GMSTs.fDispositionMod * (state.disposition - 50) * (1 - dispFactor)
        npcHagglingModDiff = state.skills.mercantile[mC.buffType.haggling] + pcHagglingDispTerm - state.skills.mercantile[kind]
        if npcHagglingModDiff > 0 then
            npcLuckModDiff = npcLuckModDiff + npcHagglingModDiff * 10
        else
            pcLuckModDiff = pcLuckModDiff - npcHagglingModDiff * 10
        end
    end

    -- Set luck mods
    newMods.npc[Attributes.luck.id] = util.round(mods.npc.luck + npcLuckModDiff)
    newMods.pc[Attributes.luck.id] = util.round(mods.pc.luck + pcLuckModDiff)

    log(string.format("Modifiers for %s:\n"
            .. "npcLuckMod %d, pcLuckMod %d\n"
            .. "npcSkillMod %.2f, pcSkillMod %.2f\n"
            .. "npcHagglingMod %.2f, pcHagglingDispTerm %.2f",
            kind,
            npcLuckModDiff, pcLuckModDiff,
            npcSkillModDiff, pcSkillModDiff,
            npcHagglingModDiff, pcHagglingDispTerm))
    return newMods
end

local function modStats(op)
    if op.restoreStats then
        mC.modStats(mods.npc)
        mods.pc = op.restoreStats.pcMods
    end
    if op.saveStats then
        initStats(op.player)
    end
    if op.computeStats then
        computeStats()
    end

    if op.mod.type == mC.operationType.buff then
        local newMods = getNewMods(op.mod.kind)
        mC.modStats(newMods.npc)
        player:sendEvent(mDef.events.modPcStats, { pcMods = newMods.pc, npcSkills = state.skills })
    elseif op.mod.type == mC.operationType.restore then
        if mods then
            mC.modStats(mods.npc)
            log("Restored stats")
        else
            log("We won't restore unset stats")
        end
        core.sendGlobalEvent(mDef.events.removeNpcScript, self)
    else
        error("Error: Invalid operation type " .. op.mod.type)
    end
end

local function modDisp(disp, _player, notify, progDiff)
    T.NPC.setBaseDisposition(self, _player, math.floor(disp))
    if not notify then return end
    local newDisp = T.NPC.getDisposition(self, player)
    local localeKey
    if progDiff > 0 then
        progDiff = util.round(progDiff * 1000) / 1000
        localeKey = "dispScalingNotifGain"
    else
        progDiff = util.round(-progDiff * 1000) / 1000
        localeKey = "dispScalingNotifLoss"
    end
    newDisp = newDisp + disp % 1
    player:sendEvent(mDef.events.notify, L(localeKey, { npc = record.name, prog = progDiff, disp = newDisp }))
end

return {
    eventHandlers = {
        [mDef.events.modStats] = modStats,
        [mDef.events.modDisp] = function(data) modDisp(data.disp, data.player, data.notify, data.progDiff) end,
    },
}