local playerQuests = include("diject.quest_guider.playerQuests")
local stringLib = include("diject.quest_guider.utils.string")
local types = include("diject.quest_guider.types")
local operator = types.operator

local this = {}


---@type table<string, fun(req:questDataGenerator.requirementData, obj:any, mobile:any, ref:tes3reference):boolean?>
local dataFuncs = {
    [types.requirementType.Journal] = function (req)
        if not req.variable then return end
        local plIndex = playerQuests.getCurrentIndex(req.variable) or 0
        return operator.check(plIndex, req.value, req.operator)
    end,

    [types.requirementType.CustomActorFaction] = function (req, obj)
        local faction = tes3.getFaction(req.value)
        if not faction then return end
        if not obj then return end
        if not obj.faction then return end
        return operator.check(obj.faction.id:lower(), req.value, req.operator)
    end,

    [types.requirementType.CustomPCFaction] = function (req)
        local faction = tes3.getFaction(req.value)
        if not faction then return end
        local factionId = ""
        if faction.playerJoined then
            factionId = faction.id:lower()
        end
        return operator.check(factionId, req.value, req.operator)
    end,

    [types.requirementType.RankRequirement] = function (req, obj)
        if not req.variable then return end
        local object = req.object and tes3.getObject(req.object) or obj
        if not object then return end

        if not object or not object.faction or not object.factionRank then return end
        if object.faction.id:lower() ~= req.variable then return false end
        return operator.check(object.factionRank, req.value, req.operator)
    end,

    [types.requirementType.CustomPCRank] = function (req)
        if not req.variable then return end
        local faction = tes3.getFaction(req.variable)
        if not faction then return end
        return operator.check(faction.playerRank, req.value, req.operator)
    end,

    [types.requirementType.Dead] = function (req)
        if not req.variable then return end
        local kilCount = tes3.getKillCount{ actor = req.variable }
        return operator.check(kilCount, req.value, req.operator)
    end,

    [types.requirementType.CustomOnDeath] = function (req, obj)
        if not req.object and not obj then return end
        local kilCount = tes3.getKillCount{ actor = obj and obj.id or req.object }
        return operator.check(kilCount, req.value, req.operator)
    end,

    [types.requirementType.Item] = function (req, obj, mobile)
        if not req.variable and not (req.object or mobile) then return end
        local itemCount
        if req.object == "player" then
            itemCount = tes3.getItemCount{ reference = tes3.mobilePlayer, item = req.variable }
        elseif mobile then
            itemCount = tes3.getItemCount{ reference = mobile, item = req.variable }
        end
        if not itemCount then return end
        return operator.check(itemCount, req.value, req.operator)
    end,

    [types.requirementType.CustomGlobal] = function (req)
        if req.object or not req.variable then return end
        local var = tes3.dataHandler.nonDynamicData:findGlobalVariable(req.variable)
        if not var then return end
        return operator.check(var.value, req.value, req.operator)
    end,

    [types.requirementType.CustomLocal] = function (req, obj, mobile, ref)
        if not req.variable or not ref then return end
        local baseObj = ref.baseObject
        if req.script and baseObj.script.id:lower() ~= req.script then return false end
        if req.object and baseObj.id:lower() ~= req.object then return false end
        if not ref.context then return end
        local val = ref.context[req.value]
        if not val then return false end

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.CustomNotLocal] = function (req, obj, mobile, ref)
        if not req.variable or not ref then return end
        local baseObj = ref.baseObject
        if req.script and baseObj.script.id:lower() ~= req.script then return false end
        if req.object and baseObj.id:lower() ~= req.object then return false end
        if not ref.context then return end
        local val = ref.context[req.value]
        if not val then return true end

        return false
    end,

    [types.requirementType.CustomActor] = function (req, obj, mobile, ref)
        if not req.object or not req.variable or not req.value or not ref then return end
        local dialogue = tes3.findDialogue{ topic = stringLib.convertDialogueName(req.variable) }
        if not dialogue then return end
        local dialogueInfo = tes3.getDialogueInfo{ dialogue = dialogue, id = req.value }
        if not dialogueInfo then return end

        return dialogueInfo:filter(ref.object, ref, 0, dialogue)
    end,

    [types.requirementType.CustomDialogue] = function (req)
        if not req.variable then return end
        if not tes3.mobilePlayer then return end
        local dialogueId = stringLib.convertDialogueName(req.variable)
        for _, dia in pairs(tes3.mobilePlayer.dialogueList) do
            if dialogueId == dia.id:lower() then
                return operator.check(true, true, req.operator)
            end
        end
        return operator.check(false, true, req.operator)
    end,
}


---@param req questDataGenerator.requirementData
---@param reference tes3reference?
---@param object tes3npc|tes3creature|nil
---@param mobile tes3mobilePlayer|tes3mobileNPC|tes3mobileActor|nil
---@return boolean?
function this.check(req, object, mobile, reference)
    local func = dataFuncs[req.type]
    if func then
        local status, res = pcall(func, req, object, mobile, reference)
        if not status then return end
        return res
    end
    return nil
end


---@class questGuider.requirementChecker.checkForBlock.params
---@field reference tes3reference?
---@field object tes3npc|tes3creature|nil
---@field mobile tes3mobilePlayer|tes3mobileNPC|tes3mobileActor|nil
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

        local r = this.check(req, params.object, params.mobile, params.reference)
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
            table.insert(outReqBlock, table.copy(req))
            count = count + 1
        end
    end
    if count == 0 then return nil, 0 end
    return outReqBlock, count
end

return this