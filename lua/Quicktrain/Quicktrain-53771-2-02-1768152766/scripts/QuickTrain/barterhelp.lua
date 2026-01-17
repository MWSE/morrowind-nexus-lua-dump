local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")

local function getFatigueTerm(actor)
    local max = types.Actor.stats.dynamic.fatigue(actor).base + types.Actor.stats.dynamic.fatigue(actor).modifier
    local current = types.Actor.stats.dynamic.fatigue(actor).current

    local normalised = math.floor(max) == 0 and 1 or math.max(0, current / max)

    local fFatigueBase = core.getGMST("fFatigueBase")
    local fFatigueMult = core.getGMST("fFatigueMult")

    return fFatigueBase - fFatigueMult * (1 - normalised)
end
local function getDerivedDisposition(npc, clamp)
    if npc.type == types.Creature then
        error("Invalid actor provided")
    end
    if clamp == nil then
        clamp = true
    end
    local currentDisposition = types.NPC.getDisposition(npc, self)
    local baseDisposition = types.NPC.records[npc.recordId].baseDisposition
    local playerDiseased = false
    local npcFact = types.NPC.getFactions(npc)[1]
    local x = currentDisposition --need  crime disposition modifier
    -- if types.Actor.activeEffects(self):getEffect("commondisease").magnitude > 0 or types.Actor.activeEffects(self):getEffect("blightdisease").magnitude > 0 then
    --    x = x + core.getGMST("fDispDiseaseMod")
    -- end
    local fDispPersonalityBase = core.getGMST("fDispPersonalityBase")
    local fDispFactionRankMult = core.getGMST("fDispFactionRankMult")
    local fDispFactionRankBase = core.getGMST("fDispFactionRankBase")
    local playerPers = types.Actor.stats.attributes.personality(self).modified
    x = x + (fDispFactionRankMult * (playerPers - fDispPersonalityBase))
    local fDispFactionMod = core.getGMST("fDispFactionMod")
    local fDispWeaponDrawn = core.getGMST("fDispWeaponDrawn")
    local reaction = 0
    local rank = 0
    if npcFact then
        local factionRecord = core.factions.records[npcFact]
        local playerIsInFact = false
        for index, factId in ipairs(types.NPC.getFactions(self)) do
            if factId == factionRecord.id then
                playerIsInFact = true
                if types.NPC.isExpelled(self, factId) then
                    break
                end
                reaction = core.factions.records[factId].reactions[factId]
                rank = types.NPC.getFactionRank(self, factId)
            end
        end
        if not playerIsInFact then
            for index, factId in ipairs(types.NPC.getFactions(self)) do
                if factId ~= factionRecord.id then
                    if not types.NPC.isExpelled(self, factId) then
                        local playerFactionRecord = core.factions.records[npcFact]
                        local freaction = core.factions.records[npcFact].reactions[factId]
                        if index == 1 or freaction < reaction then
                            rank = types.NPC.getFactionRank(self, factId)
                            reaction = freaction
                        end
                    end
                end
            end
        end
    end
    local sameRace = types.NPC.record(self).race == types.NPC.records[npc.recordId].race
    local fDispRaceMod = core.getGMST("fDispRaceMod")
    if not sameRace then
        x = x + fDispRaceMod
    end
    local weaponDrawn = types.Actor.getStance(self) == types.Actor.STANCE.Weapon
    local charmAmount = types.Actor.activeEffects(npc):getEffect("charm").magnitude
    x = x + charmAmount
    if weaponDrawn then
        x = x + fDispWeaponDrawn
    end
    x = x + (fDispFactionRankMult * rank + fDispFactionRankBase) * fDispFactionMod * reaction;

    local fDispCrimeMod = core.getGMST("fDispCrimeMod")
    local fDispDiseaseMod = core.getGMST("fDispDiseaseMod")
    x = x + fDispCrimeMod * types.Player.getCrimeLevel(self)
    if playerDiseased then
        x = x + fDispDiseaseMod
    end

    if clamp and x > 100 then
        return 100
    elseif clamp and x < 0 then
        return 0
    else
        return x
    end
end
local function getBarterOffer(npc, basePrice, buying)
    if basePrice == 0 or npc.type == types.Creature then
        return basePrice
    end
    local disposition = types.NPC.getDisposition(npc, self) --) getDerivedDisposition(npc, false)
    local player = self
    local playerMerc = types.NPC.stats.skills.mercantile(self).modified

    local playerLuck = types.Actor.stats.attributes.luck(self).modified
    local playerPers = types.Actor.stats.attributes.personality(self).modified

    local playerFatigueTerm = getFatigueTerm(self)
    local npcFatigueTerm = getFatigueTerm(npc)

    -- Calculate the remaining parts of the function using the provided variables/methods
    local clampedDisposition = disposition
    local a = math.min(playerMerc, 100)
    local b = math.min(0.1 * playerLuck, 10)
    local c = math.min(0.2 * playerPers, 10)
    local d = math.min(types.NPC.stats.skills.mercantile(npc).modified, 100)
    local e = math.min(0.1 * types.Actor.stats.attributes.luck(npc).modified, 10)
    local f = math.min(0.2 * types.Actor.stats.attributes.personality(npc).modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * playerFatigueTerm
    local npcTerm = (d + e + f) * npcFatigueTerm
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.floor(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end
local function getTrainingPrice(npc, skill)
    local skillBase = types.NPC.stats.skills[skill](self).base
    local price = (skillBase) * core.getGMST("iTrainingMod")

    price = math.max(1, price);
    --price = types.NPC.barterOffer(npc,price,true)
    price = getBarterOffer(npc, price, true);
    return price
end

return {
    getBarterOffer = getBarterOffer,
    getTrainingPrice = getTrainingPrice
}