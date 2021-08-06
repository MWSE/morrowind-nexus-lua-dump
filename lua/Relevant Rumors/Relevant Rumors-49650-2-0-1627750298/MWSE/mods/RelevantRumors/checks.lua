local this = {}
local QUEST_COMPLETED_INDEX = 100

local function checkCell(condition, actorCell)
    if (condition.comparator == '!=') then
        return not string.startswith(actorCell.id, condition.value)
    else
        return string.startswith(actorCell.id, condition.value)
    end
end

local function isGreatHouse(actorFaction)
    return (actorFaction == 'Telvanni') or (actorFaction == 'Redoran') or (actorFaction == 'Hlaalu')
end

local function checkFaction(condition, actorFaction)
    if (condition.comparator == '!=') then
        if (condition.value == 'NOT_GREAT_HOUSE') then
            return isGreatHouse(actorFaction)
        end

        return actorFaction ~= condition.value
    else
        if (condition.value == 'NOT_GREAT_HOUSE') then
            return not isGreatHouse(actorFaction)
        end

        return actorFaction == condition.value
    end
end

local function checkDead(condition)
    local actor = tes3.getReference(condition.value).mobile

    if (not actor) then
        return false
    end

    local isDead = not actor.health.current or actor.health.current == 0

    if (condition.comparator == "!=") then
        return not isDead
    end

    return isDead
end

local function checkQuestCompleted(condition)
    local completedIndex = condition.completedIndex
    if (not completedIndex) then
        completedIndex = QUEST_COMPLETED_INDEX
    end
    local journalIndex = tes3.getJournalIndex({
        id = condition.value
    })
    local isCompleted = journalIndex ~= nil and journalIndex >= completedIndex
    if (condition.comparator == "not_completed") then
        return not isCompleted
    else
        return isCompleted
    end
end

local function checkJournalStage(condition)
    local questStage = tes3.getJournalIndex({
        id = condition.questId
    })
    if (questStage == nil) then
        return false
    end
    if (condition.comparator == '<=') then
        return questStage <= condition.value
    elseif (condition.comparator == '>=') then
        return questStage >= condition.value
    else
        return questStage == condition.value
    end
end

local function checkPCSex(condition)
    return tes3.mobilePlayer.firstPerson.female == condition.value
end

local function checkPCRank(condition)
    local faction = tes3.getFaction(condition.faction)

    if (condition.comparator == '<') then
        return faction.playerRank < condition.value
    elseif (condition.comparator == '>') then
        return faction.playerRank > condition.value
    else
        return faction.playerRank == condition.value
    end
end

local function checkPCRankDifference(condition, actor)
    local faction = actor.faction

    if (not faction or not faction.playerJoined or faction.playerExpelled) then
        return false
    end

    local playerRank = faction.playerRank
    local actorRank = actor.baseObject.factionRank
    local difference = condition.value

    if (condition.comparator == '<') then
        return playerRank - actorRank < difference
    elseif (condition.comparator == '>') then
        return playerRank - actorRank > difference
    else
    end
end

local function checkRace(condition, actorRace)
    local matchesRace = actorRace.name == condition.value

    if (condition.comparator == "!=") then
        return not matchesRace
    end

    return matchesRace
end

local function checkRegion(condition, actorCell)
    if (actorCell.isInterior or not actorCell.region) then
        return false
    end

    return actorCell.region.name == condition.value
end

this.checkCell = checkCell
this.checkFaction = checkFaction
this.checkDead = checkDead
this.checkQuestCompleted = checkQuestCompleted
this.checkJournalStage = checkJournalStage
this.checkPCSex = checkPCSex
this.checkPCRank = checkPCRank
this.checkPCRankDifference = checkPCRankDifference
this.checkRace = checkRace
this.checkRegion = checkRegion

return this
