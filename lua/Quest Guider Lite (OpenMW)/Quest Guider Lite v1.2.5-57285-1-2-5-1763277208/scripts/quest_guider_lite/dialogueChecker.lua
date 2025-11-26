
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")

local playerRef = world.players[1]

local myTypes = require("scripts.quest_guider_lite.types")

local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")
local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")

local this = {}


---@class questGuiderLite.dialogueChecker.isDialogueAvailable.options
---@field skipDisposition boolean?
---@field checkBlockOptions questGuider.requirementChecker.checkForBlock.params?

---@param diaId string should be lowercase
---@param options questGuiderLite.dialogueChecker.isDialogueAvailable.options
---@return boolean?
---@return string? infoId
function this.isDialogueTopicAvailable(ref, diaId, infoId, options)
    if not options then options = {} end

    local dia = core.dialogue.topic.records[diaId] or core.dialogue.greeting.records[diaId]
    if not dia then
        for _, list in pairs({core.dialogue.topic.records, core.dialogue.greeting.records}) do
            for _, d in pairs(list) do
                if d.id:lower() == diaId then
                    dia = d
                    goto tonext
                end
            end
        end
        ::tonext::
    end

    if not dia then return end

    -- if not this.isTopicAccessible(diaId, 1) then return false end

    local data = dataHandler.dialogueTopics[diaId] or {}

    local checkBlockOptions = options.checkBlockOptions or {}
    checkBlockOptions.reference = ref

    for i = #dia.infos, 1, -1 do
        local info = dia.infos[i]
        local res = this.checkDialogueRecordInfoRequirements(ref, info, options)
        if not res then goto continue end

        for _, infoData in ipairs(data) do
            if infoData.id == info.id then
                local r = requirementChecker.checkBlock(infoData.reqs, checkBlockOptions)

                if r then
                    return info.id == infoId, info.id
                end
                break
            end
        end

        if res then return info.id == infoId, info.id end

        ::continue::
    end
end


---@class questGuiderLite.dialogueChecker.checkDialogueRecordInfoRequirements.options
---@field skipDisposition boolean?

---@param options questGuiderLite.dialogueChecker.checkDialogueRecordInfoRequirements.options
---@return boolean?
function this.checkDialogueRecordInfoRequirements(ref, recordInfo, options)
    if not options then options = {} end

    local isNPC = types.NPC.objectIsInstance(ref)
    local refRecord = isNPC and types.NPC.record(ref) or types.Creature.record(ref)
    if not refRecord then return end

    if recordInfo.filterActorClass and refRecord.class ~= recordInfo.filterActorClass:lower() then
        return false
    end

    if not options.skipDisposition and isNPC and recordInfo.filterActorDisposition
            and refRecord.filterActorDisposition < types.NPC.getDisposition(ref, playerRef) then
        return false
    end

    if recordInfo.filterActorFaction and isNPC and types.NPC.getFactionRank(ref, recordInfo.filterActorFaction) == 0 then
        return false
    end

    if recordInfo.filterActorFactionRank and isNPC then
        local factions = types.NPC.getFactions(ref)
        local valid = false
        for _, factionId in pairs(factions) do
            if types.NPC.getFactionRank(ref, factionId) >= recordInfo.filterActorFactionRank then
                valid = true
                break
            end
        end
        if not valid then
            return false
        end
    end

    if recordInfo.filterActorGender and isNPC and ((recordInfo.filterActorGender == "male") ~= refRecord.isMale) then
        return false
    end

    if recordInfo.filterActorId and refRecord.id ~= recordInfo.filterActorId then
        return false
    end

    if recordInfo.filterActorRace and refRecord.race ~= recordInfo.filterActorRace then
        return false
    end

    if recordInfo.filterPlayerCell and string.sub(playerRef.cell.name, 1, #recordInfo.filterPlayerCell):lower() ~= recordInfo.filterPlayerCell:lower() then
        return false
    end

    if recordInfo.filterPlayerFaction and types.NPC.getFactionRank(playerRef, recordInfo.filterPlayerFaction) == 0 then
        return false
    end

    if recordInfo.filterPlayerFactionRank and isNPC then
        local factions = types.NPC.getFactions(playerRef)
        local valid = false
        for _, factionId in pairs(factions) do
            if types.NPC.getFactionRank(ref, factionId) >= recordInfo.filterPlayerFactionRank then
                valid = true
                break
            end
        end
        if not valid then
            return false
        end
    end


    return true
end


local function isTopicAccessible(topicId)
    local topic = types.Player.journal(playerRef).topics[topicId]
    if not topic then
        for _, tp in pairs(types.Player.journal(playerRef).topics) do
            if tp.id == topicId then
                topic = tp
                break
            end
        end
    end

    return topic ~= nil
end


---@return boolean?
---@return string[]? topics chain of topics to get to the target topic
function this.isTopicAccessible(topicName, searchDepth)
    if core.API_REVISION < 93 then return end

    local topicId = topicName:lower()

    if isTopicAccessible(topicId) then return true end

    local foundData = {}

    local function findParentDialogues(recId, parentId, depth, dataChain)
        if depth < 0 then return end

        if not dataChain then dataChain = {} end

        local diaTopicId = stringLib.convertDialogueName(recId)

        local recData = dataHandler.questObjects[recId]
        if not recData then return end

        if recData.type == 3 then
            if not isTopicAccessible(diaTopicId) then
                for _, linkInfo in pairs(recData.links or {}) do
                    local chainDepth, chain = findParentDialogues(linkInfo[1], recId, depth - 1)
                    if chainDepth then
                        table.insert(foundData, {chainDepth, chain})
                    end
                end
            else
                local chain = tableLib.copy(dataChain)
                table.insert(chain, {variable = parentId, value = recId})
                return depth, chain
            end
        elseif recData.type == 6 then
            for _, linkInfo in pairs(recData.links or {}) do
                local chainDepth, chain = findParentDialogues(linkInfo[1], parentId, depth - 1)
                if chainDepth then
                    table.insert(foundData, {chainDepth, chain})
                end
            end
        end
    end

    findParentDialogues("#dia: "..topicId, "#dia: "..topicId, (searchDepth or 0) * 2)

    if #foundData == 0 then return false end

    table.sort(foundData, function (a, b)
        return a[1] < b[1]
    end)

    local minDepth = foundData[1][1]
    local topics = {topicId}
    for _, dt in ipairs(foundData[1][2]) do
        table.insert(topics, stringLib.convertDialogueName(dt.value))
    end

    return true, topics
end


return this