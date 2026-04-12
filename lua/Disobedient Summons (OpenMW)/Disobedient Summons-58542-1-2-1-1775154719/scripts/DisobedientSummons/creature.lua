local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")

require("scripts.DisobedientSummons.logic.checks")

local settings = storage.globalSection("SettingsDisobedientSummons")
local l10n = core.l10n("DisobedientSummons")
local toScan = { nearby.actors, nearby.players }
local cooldown = 1

local summoner
local newSummonerCandidate
local newSummonerCandidateConj = 0
local deltaTime = 0
local pendingActors = {}

I.AI.forEachPackage(function(pkg)
    if (pkg.type == "Follow" or pkg.type == "Escort") and pkg.target and pkg.target:isValid() then
        summoner = pkg.target
    end
end)

if not IsDisobedient(summoner, self) then
    return
end

local function switchSummoner()
    I.AI.startPackage({
        type = "Follow",
        target = newSummonerCandidate,
        cancelOther = true,
    })
    summoner = newSummonerCandidate

    if settings:get("enableMessages") then
        local selfName = self.type.records[self.recordId].name
        local summonerName = summoner.type == types.Player
            and "you"
            or summoner.type.records[summoner.recordId].name
        local message = l10n(
            "msg_disobeyed",
            { summon = selfName, master = summonerName }
        )
        for _, player in ipairs(nearby.players) do
            player:sendEvent(
                "ShowMessage",
                { message = message }
            )
        end
    end
    

    newSummonerCandidate = nil
    newSummonerCandidateConj = 0
end

local function onUpdate(dt)
    deltaTime = deltaTime + dt
    if #pendingActors == 0 then
        if deltaTime < cooldown then
            return
        end

        deltaTime = 0

        if newSummonerCandidate then
            switchSummoner()
        end

        for _, objects in ipairs(toScan) do
            for _, obj in ipairs(objects) do
                pendingActors[#pendingActors + 1] = obj
            end
        end
    end

    local currActor = table.remove(pendingActors)

    if not ValidSummoner(currActor, summoner, self.position)
        or not SkillCheck(currActor, summoner)
    then
        return
    end

    local currActorConj = types.NPC.objectIsInstance(currActor)
        and currActor.type.stats.skills.conjuration(currActor).modified
        or settings:get("creatureConjurationSkill")
    if currActorConj > newSummonerCandidateConj then
        newSummonerCandidate = currActor
        newSummonerCandidateConj = currActorConj
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
