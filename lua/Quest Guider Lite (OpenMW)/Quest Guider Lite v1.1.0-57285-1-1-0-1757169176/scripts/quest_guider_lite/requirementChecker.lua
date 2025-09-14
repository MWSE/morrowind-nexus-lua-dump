local include = require("scripts.quest_guider_lite.utils.include")

local types = require('openmw.types')
local playerFunc = types.Player
local world = include("openmw.world")
local playerRef = include("openmw.self")

local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local reqTypes = require("scripts.quest_guider_lite.types")
local operator = reqTypes.operator
local killCounter = require("scripts.quest_guider_lite.killCounter")

local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local getObject = require("scripts.quest_guider_lite.core.getObject")

local this = {}


---@type table<string, fun(req:questDataGenerator.requirementData, obj:any, mobile:any, ref:tes3reference):boolean?>
local dataFuncs = {
    [reqTypes.requirementType.Journal] = function (req)
        if not req.variable then return end
        local qData = playerFunc.quests(playerRef)[req.variable]
        local plIndex = qData and qData.stage or 0
        return operator.check(plIndex, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomActorFaction] = function (req, ref)
        if not ref then return end
        local factions = types.NPC.getFactions(ref)
        if not factions then return end
        local res = false
        for _, faction in pairs(factions) do
            res = res or operator.check(faction:lower(), req.value, req.operator)
        end
        return res
    end,

    [reqTypes.requirementType.CustomPCFaction] = function (req)
        local ref = world and world.players[1] or playerRef
        local factions = types.NPC.getFactions(ref)
        if not factions then return end
        local res = false
        for _, faction in pairs(factions) do
            res = res or operator.check(faction:lower(), req.value, req.operator)
        end
        return res
    end,

    [reqTypes.requirementType.RankRequirement] = function (req, ref)
        if not req.variable or not ref then return end

        local rank = types.NPC.getFactionRank(ref, req.variable)
        return operator.check(rank, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomPCRank] = function (req)
        if not req.variable then return end
        local rank = types.NPC.getFactionRank(world and world.players[1] or playerRef, req.variable)
        return operator.check(rank, req.value, req.operator)
    end,

    [reqTypes.requirementType.Dead] = function (req)
        if not req.variable then return end
        local kilCount = killCounter.getKillCount(req.variable)
        return operator.check(kilCount, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomOnDeath] = function (req)
        if not req.object then return end
        local kilCount = killCounter.getKillCount(req.object)
        return operator.check(kilCount, req.value, req.operator)
    end,

    [reqTypes.requirementType.Item] = function (req, ref)
        if not req.variable and not ref then return end
        local inventory = types.Actor.inventory(ref)
        local itemCount = inventory:countOf(req.variable)

        return operator.check(itemCount, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomGlobal] = function (req)
        if req.object or not req.variable then return end
        local globals = world and world.mwscript.getGlobalVariables(world.players[1])
        if not globals then return end
        local value
        for name, val in pairs(globals) do
            if name:lower() == req.variable then
                value = val
                break
            end
        end
        if not value then return end
        return operator.check(value, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomLocal] = function (req, ref)
        if not req.variable or not ref then return end
        local script = world and world.mwscript.getLocalScript(ref, world.players[1])
        if not script then return end
        local variables = script.variables

        if req.script and script.recordId:lower() ~= req.script then return false end
        if req.object and script.object.recordId ~= req.object then return false end

        local value
        for name, val in pairs(variables) do
            if name:lower() == req.variable then
                value = val
                break
            end
        end
        if not value then return end

        return operator.check(value, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomNotLocal] = function (req, ref)
        if not req.variable or not ref then return end

        local script = world and world.mwscript.getLocalScript(ref, world.players[1])
        if not script then return true end

        for name, val in pairs(script.variables) do
            if name:lower() == req.variable then
                return false
            end
        end

        return true
    end,

    -- [reqTypes.requirementType.CustomActor] = function (req, ref)
    --     if not req.object or not req.variable or not req.value or not ref then return end
    --     local dialogue = tes3.findDialogue{ topic = stringLib.convertDialogueName(req.variable) }
    --     if not dialogue then return end
    --     local dialogueInfo = tes3.getDialogueInfo{ dialogue = dialogue, id = req.value }
    --     if not dialogueInfo then return end

    --     return dialogueInfo:filter(ref.object, ref, 0, dialogue)
    -- end,

    [reqTypes.requirementType.CustomDialogue] = function (req)
        if not req.variable then return end
        local dialogueId = stringLib.convertDialogueName(req.variable)
        if playerQuests.getTopicData(dialogueId) then
            return operator.check(true, true, req.operator)
        end
        return operator.check(false, true, req.operator)
    end,
}


---@param req questDataGenerator.requirementData
---@param reference tes3reference?
---@return boolean?
function this.check(req, reference)
    local func = dataFuncs[req.type]
    if func then
        local status, res = pcall(func, req, reference)
        if not status then return end
        return res
    end
    return nil
end


---@class questGuider.requirementChecker.checkForBlock.params
---@field reference tes3reference?
---@field ignoredTypes table<string, any>?
---@field allowedTypes table<string, any>?
---@field threatErrorsAs boolean?

---@param block questDataGenerator.requirementData[]
---@param params questGuider.requirementChecker.checkForBlock.params
---@return boolean?
function this.checkBlock(block, params)
    local res = true
    for _, req in pairs(block) do
        if (params.ignoredTypes and params.ignoredTypes[req.type]) or
                (params.allowedTypes and not params.allowedTypes[req.type]) then
            goto continue
        end

        local ref
        if req.object == "player" then
            ref = world and world.players[1] or playerRef
        else
            ref = params.reference
        end

        local r = this.check(req, ref)
        if r == nil and params.threatErrorsAs ~= nil then
            r = params.threatErrorsAs
        end

        res = res and r

        if not res then break end

        ::continue::
    end

    return res
end


---@param reqBlock questDataGenerator.requirementBlock
---@param  filter table<string, any>? by requirement type id
---@return questDataGenerator.requirementBlock?
---@return integer count
function this.getFilterredRequirementBlock(reqBlock, filter)
    local outReqBlock = {}
    local count = 0
    for _, req in pairs(reqBlock) do
        if not filter or filter[req.type] then
            table.insert(outReqBlock, tableLib.copy(req))
            count = count + 1
        end
    end
    if count == 0 then return nil, 0 end
    return outReqBlock, count
end

return this