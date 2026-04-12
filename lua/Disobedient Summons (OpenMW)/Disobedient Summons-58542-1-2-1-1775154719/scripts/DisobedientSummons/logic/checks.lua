local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")

require("scripts.DisobedientSummons.utils.consts")

local settings = storage.globalSection("SettingsDisobedientSummons")

function IsDisobedient(summoner, self)
    if not summoner then
        return false
    end

    local attrs = summoner.type.stats.attributes
    local luck = attrs.luck(summoner)
    local willpower = attrs.willpower(summoner)
    local disobedientChance = settings:get("baseChance")
        + luck.modified * settings:get("luckMod")
        + willpower.modified * settings:get("willpowerMod")

    -- obedience check
    if math.random() * 100 > disobedientChance then
        return false
    end

    if types.Creature.objectIsInstance(summoner)
        and not settings:get("ignoreCreatureSummoners")
    then
        local records = types.Creature.records
        local selfType = records[self.recordId].type
        local summonerType = records[summoner.recordId].type
        if selfType == summonerType then
            return false
        end
    end

    return true
end

local function isSummoner(currActor)
    local spells = currActor.type.spells(currActor)
    for _, spell in ipairs(spells) do
        local effects = core.magic.spells.records[spell.id].effects
        for _, effect in ipairs(effects) do
            if SummonSpells[effect.id] then
                return true
            end
        end
    end
    return false
end

function ValidSummoner(currActor, summoner, selfPos)
    if currActor == summoner
        or (selfPos - currActor.position):length() > settings:get("maxDistance")
    then
        return false
    end

    if currActor.type == types.NPC then
        return true
    else
        return isSummoner(currActor)
    end
end

function SkillCheck(currActor, summoner)
    local conjuration = types.NPC.stats.skills.conjuration
    local actorConj = types.NPC.objectIsInstance(currActor)
        and conjuration(currActor).modified
        or settings:get("creatureConjurationSkill")
    local summonerConj = types.NPC.objectIsInstance(summoner)
        and conjuration(summoner).modified
        or settings:get("creatureConjurationSkill")
    return actorConj - summonerConj > settings:get("conjurationDifference")
end
