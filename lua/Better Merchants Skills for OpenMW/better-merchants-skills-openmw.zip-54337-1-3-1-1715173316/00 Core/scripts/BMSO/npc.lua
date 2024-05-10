local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')

local S = require('scripts.BMSO.settings')
local C = require("scripts.BMSO.common")

local npc = T.NPC.record(self)
local merchantStats = { skills = {}, attributes = {} }

local function computeStats(player)
    local npcLevel = C.npcLevelOverrides[npc.id]
    if npcLevel == nil then
        npcLevel = T.NPC.stats.level(self).current
    else
        C.debugPrint("'%s' level override to %s", npc.name, npcLevel)
    end
    local npcMercantile = T.NPC.stats.skills.mercantile(self).base
    local npcSpeechcraft = T.NPC.stats.skills.speechcraft(self).base

    local usePlayerLevel = S.globalStorage:get("playerLevelBasedSkillsBoost")
    if usePlayerLevel ~= "no" then
        local playerLevel = T.Player.stats.level(player).current
        if playerLevel > npcLevel then
            local factor = S.getPlayerLevelBasedSkillsBoost(usePlayerLevel)
            npcLevel = playerLevel * factor + npcLevel * (1 - factor)
            C.debugPrint("Base used level changed to %s, player level %s, factor %s",
                    npcLevel, playerLevel, factor)
        end
    end

    local maxSkill = math.max(math.min(npcLevel * 4 + 20, 100), 30)
    local newMercantile = math.max(npcMercantile, maxSkill)
    local newSpeechcraft = math.max(npcSpeechcraft, maxSkill)

    newMercantile = math.min(newMercantile, T.Player.stats.skills.mercantile(player).base + S.globalStorage:get("maxMercantileDifference"))

    merchantStats = { skills = {}, attributes = {} }
    if (newMercantile ~= npcMercantile) then
        merchantStats.skills.mercantile = { old = npcMercantile, new = newMercantile }
    end
    if (newSpeechcraft ~= npcSpeechcraft) then
        local personalityBoost = (newSpeechcraft - npcSpeechcraft) * core.getGMST("fPersonalityMod")
        merchantStats.attributes.personality = { old = T.NPC.stats.attributes.personality(self).base, new = T.NPC.stats.attributes.personality(self).base + personalityBoost }
    end

    C.debugPrint("'%s', level %s, max skill boost %s, mercantile %s->%s, speechcraft %s->%s",
            npc.name, npcLevel, maxSkill, npcMercantile, newMercantile, npcSpeechcraft, newSpeechcraft)
end

local function handleStats(data)
    for _, op in ipairs(data) do
        if op.type == "computeStats" then
            computeStats(op.player)
        else
            local values = merchantStats[op.kind][op.statId]
            if op.type == "boost" then
                if values == nil then
                    C.debugPrint("NPC '%s': No %s (%s) boost required", npc.name, op.statId, op.kind)
                else
                    C.debugPrint("NPC '%s': Increase %s (%s) from %s to %s", npc.name, op.statId, op.kind, values.old, values.new)
                    T.NPC.stats[op.kind][op.statId](self).base = values.new
                end
            elseif op.type == "restore" then
                if values == nil then
                    C.debugPrint("NPC '%s': No %s (%s) restore required", npc.name, op.statId, op.kind)
                else
                    C.debugPrint("NPC '%s': Restore %s (%s) from %s to %s", npc.name, op.statId, op.kind, values.new, values.old)
                    T.NPC.stats[op.kind][op.statId](self).base = values.old
                end
            else
                print("Error: Invalid operation type ", op.type)
            end
        end
    end
end

return {
    eventHandlers = {
        handleStats = handleStats,
    },
}