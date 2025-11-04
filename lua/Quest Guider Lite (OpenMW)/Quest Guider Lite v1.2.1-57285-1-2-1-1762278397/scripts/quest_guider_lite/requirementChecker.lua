local include = require("scripts.quest_guider_lite.utils.include")

local types = require('openmw.types')
local core = require("openmw.core")
local playerFunc = types.Player
local world = include("openmw.world")
local tes3 = include("scripts.quest_guider_lite.core.tes3")
local playerRef = include("openmw.self") or world.players[1] ---@diagnostic disable-line: need-check-nil

local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local reqTypes = require("scripts.quest_guider_lite.types")
local operator = reqTypes.operator
local killCounter = require("scripts.quest_guider_lite.killCounter")
local log = require("scripts.quest_guider_lite.utils.log")

local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local getObject = require("scripts.quest_guider_lite.core.getObject")

local this = {}


local skillFuncs = {
    types.NPC.stats.skills.block,
    types.NPC.stats.skills.armorer,
    types.NPC.stats.skills.mediumarmor,
    types.NPC.stats.skills.heavyarmor,
    types.NPC.stats.skills.bluntweapon,
    types.NPC.stats.skills.longblade,
    types.NPC.stats.skills.axe,
    types.NPC.stats.skills.spear,
    types.NPC.stats.skills.athletics,
    types.NPC.stats.skills.enchant,
    types.NPC.stats.skills.destruction,
    types.NPC.stats.skills.alteration,
    types.NPC.stats.skills.illusion,
    types.NPC.stats.skills.conjuration,
    types.NPC.stats.skills.mysticism,
    types.NPC.stats.skills.restoration,
    types.NPC.stats.skills.alchemy,
    types.NPC.stats.skills.unarmored,
    types.NPC.stats.skills.security,
    types.NPC.stats.skills.sneak,
    types.NPC.stats.skills.acrobatics,
    types.NPC.stats.skills.lightarmor,
    types.NPC.stats.skills.shortblade,
    types.NPC.stats.skills.marksman,
    types.NPC.stats.skills.merchantile,
    types.NPC.stats.skills.speechcraft,
    types.NPC.stats.skills.handtohand,
}

local attributeFuncs = {
    types.Actor.stats.attributes.strength,
    types.Actor.stats.attributes.intelligence,
    types.Actor.stats.attributes.willpower,
    types.Actor.stats.attributes.agility,
    types.Actor.stats.attributes.speed,
    types.Actor.stats.attributes.endurance,
    types.Actor.stats.attributes.personality,
    types.Actor.stats.attributes.luck,
}


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

    [reqTypes.requirementType.NotActorID] = function (req, ref)
        if not req.variable or not ref then return end
        return not operator.check(req.variable, ref.recordId, req.operator)
    end,

    [reqTypes.requirementType.PlayerExpelledFromNPCFaction] = function (req, ref)
        if not req.value or not ref then return end

        local factions = types.NPC.getFactions(ref)
        if not factions then return false end
        local res = 0

        for _, faction in pairs(factions) do
            res = types.NPC.isExpelled(playerRef, faction) and 1 or 0
            if res == 1 then break end
        end

        return operator.check(res, ref.value, req.operator)
    end,

    [reqTypes.requirementType.NPCSameFactionAsPlayer] = function (req, ref)
        if not req.value or not ref then return end

        local factions = types.NPC.getFactions(ref)
        if not factions then return false end
        local res = 0
        for _, faction in pairs(factions) do
            res = types.NPC.getFactionRank(playerRef, faction) and 1 or 0
            if res == 1 then break end
        end

        return operator.check(res, ref.value, req.operator)
    end,

    [reqTypes.requirementType.ValueFLTV] = function (req, ref)
        if not req.variable or not req.value or not ref or not world then return end

        local script = world.mwscript.getLocalScript(ref, playerRef)
        if not script then return  end

        local value
        for name, val in pairs(script.variables) do
            if name:lower() == req.variable then
                value = val
                break
            end
        end

        if not value then return false end

        return operator.check(value, req.value, req.operator)
    end,

    [reqTypes.requirementType.NotActorClass] = function (req, ref)
        if not req.variable or not req.value or not ref then return end
        if not types.NPC.objectIsInstance(ref) then return end

        local record = types.NPC.record(ref)
        if not record then return end

        local val = record.class:lower() ~= req.variable and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NotActorCell] = function (req, ref)
        if not req.variable or not req.value or not ref then return end

        local val = string.sub(ref.cell.name, 1, #req.value):lower() ~= req.value and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomActorCell] = function (req, ref)
        if not req.value or not ref then return end

        return string.sub(ref.cell.name, 1, #req.value):lower() == req.value and true or false
    end,

    [reqTypes.requirementType.CustomPCCell] = function (req)
        if not req.value or not req.variable then return end

        local val = string.sub(playerRef.cell.name, 1, #req.variable):lower() == req.variable and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCHealthPercent] = function (req, ref)
        if not req.value or not ref then return end

        local health = types.Actor.stats.dynamic.health(ref)
        local val = health.current / health.base * 100

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerRankMinusNPCRank] = function (req, ref)
        if not req.value or not ref then return end

        local val = 0
        local factions = types.NPC.getFactions(ref)
        if factions then
            for _, faction in pairs(factions) do
                local plRank = types.NPC.getFactionRank(ref, faction)
                local rank = types.NPC.getFactionRank(ref, faction)
                return operator.check(plRank - rank, req.value, req.operator)
            end
        end

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NotActorRace] = function (req, ref)
        if not req.variable or not req.value or not ref then return end
        if not types.NPC.objectIsInstance(ref) then return end

        local record = types.NPC.record(ref)
        if not record then return end

        local val = record.race:lower() ~= req.variable and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerHealthPercent] = function (req)
        if not req.value then return end

        local health = types.Actor.stats.dynamic.health(playerRef)
        local val = health.current / health.base * 100

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerIsVampire] = function (req)
        if not req.value or not world then return end
        local globals = world.mwscript.getGlobalVariables(playerRef)
        if not globals then return end

        local value = 0
        for name, val in pairs(globals) do
            if name:lower() == "pcvampire" then
                value = val
                break
            end
        end

        return operator.check(value, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerCrimeLevel] = function (req)
        if not req.value then return end
        return operator.check(types.Player.getCrimeLevel(playerRef), req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCSameGenderAsPlayer] = function (req, ref)
        if not req.value or not ref then return end
        if not types.NPC.objectIsInstance(ref) then return end

        local record = types.NPC.record(ref)
        if not record then return end
        local playerRecord = types.NPC.record(playerRef)

        local val = record.isMale == playerRecord.isMale and 1 or 0

        return operator.check(val, ref.value, req.operator)
    end,

    [reqTypes.requirementType.CustomSkill] = function (req, ref)
        if not req.value or not req.skill then return end
        if req.object == "player" then
            ref = playerRef
        end
        if not types.NPC.objectIsInstance(ref) then return end

        local skillFunc = skillFuncs[req.skill]
        if not skillFunc then return end

        return operator.check(skillFunc(ref).modified, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomAttribute] = function (req, ref)
        if not req.value or not req.attribute then return end
        if req.object == "player" then
            ref = playerRef
        end

        local attrFunc = attributeFuncs[req.attribute]
        if not attrFunc then return end

        return operator.check(attrFunc(ref).modified, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerClothingModifier] = function (req)
        if not req.value then return end

        local val = 0
        for slot, item in pairs(types.Actor.getEquipment(playerRef)) do
            val = val + (item.type.record(item.recordId).value or 0)
        end

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCSameRaceAsPlayer] = function (req, ref)
        if not req.value or not ref then return end
        if not types.NPC.objectIsInstance(ref) then return end

        local record = types.NPC.record(ref)
        if not record then return end
        local playerRecord = types.NPC.record(playerRef)

        local val = record.race == playerRecord.race and 1 or 0

        return operator.check(val, ref.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerGender] = function (req)
        if not req.value then return end

        local playerRecord = types.NPC.record(playerRef)
        local val = playerRecord.isMale and 0 or 1

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerLevel] = function (req)
        if not req.value then return end
        return operator.check(types.Actor.stats.level(playerRef).current, req.value, req.operator)
    end,

    [reqTypes.requirementType.Weather] = function (req, ref)
        if not req.value or not tes3 then return end

        local weatherId = tes3.weather[core.weather.getCurrent((ref or playerRef).cell).recordId]
        if not weatherId then return end

        return operator.check(weatherId, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCReputation] = function (req, ref)
        if not req.value or not req.object or not req then return end

        if ref.recordId ~= req.object then return false end
        local val = types.NPC.getDisposition(ref, playerRef)

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerHealth] = function (req)
        if not req.value then return end

        local health = types.Actor.stats.dynamic.health(playerRef)

        return operator.check(health.current, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCFlee] = function (req, ref)
        if not req.value or not ref then return end

        if req.object and ref.recordId ~= req.object then return false end
        local val = types.Actor.stats.ai.flee(req)

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCHello] = function (req, ref)
        if not req.value or not ref then return end

        if req.object and ref.recordId ~= req.object then return false end
        local val = types.Actor.stats.ai.hello(req)

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCAlarm] = function (req, ref)
        if not req.value or not ref then return end

        if req.object and ref.recordId ~= req.object then return false end
        local val = types.Actor.stats.ai.alarm(req)

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCFight] = function (req, ref)
        if not req.value or not ref then return end

        if req.object and ref.recordId ~= req.object then return false end
        local val = types.Actor.stats.ai.fight(req)

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCLevel] = function (req, ref)
        if not req.value or not ref then return end
        if req.object and ref.recordId ~= req.object then return false end

        return operator.check(types.Actor.stats.level(ref).current, req.value, req.operator)
    end,

    [reqTypes.requirementType.NPCIsWerewolf] = function (req, ref)
        if not req.value or not ref then return end
         if req.object == "player" then
            ref = playerRef
        end
        if req.object and ref.recordId ~= req.object then return false end

        local val = types.NPC.isWerewolf(ref) and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.NotActorFaction] = function (req, ref)
        if not req.value or not req.variable or not ref then return end
        local factionRank = types.NPC.getFactionRank(ref, req.variable)

        local val = factionRank == 0 and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerCommonDisease] = function (req)
        if not req.value then return end

        local val = 0
        for _, spell in pairs(types.Actor.spells(playerRef)) do
            val = spell.type == core.magic.SPELL_TYPE.Disease and 1 or 0
            if val == 1 then break end
        end

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerBlightDisease] = function (req)
        if not req.value then return end

        local val = 0
        for _, spell in pairs(types.Actor.spells(playerRef)) do
            val = spell.type == core.magic.SPELL_TYPE.Blight and 1 or 0
            if val == 1 then break end
        end

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.PlayerCorprus] = function (req)
        if not req.value then return end

        local eff = types.Actor.activeEffects(playerRef):getEffect(core.magic.EFFECT_TYPE.Corprus)
        local val = eff.magnitude > 0 and 1 or 0

        return not operator.check(val, req.value, req.operator)
    end,


    -- [reqTypes.requirementType.CustomActor] = function (req, ref)
    --     if not req.object or not req.variable or not req.value or not ref then return end
    --     local dialogue = tes3.findDialogue{ topic = stringLib.convertDialogueName(req.variable) }
    --     if not dialogue then return end
    --     local dialogueInfo = tes3.getDialogueInfo{ dialogue = dialogue, id = req.value }
    --     if not dialogueInfo then return end

    --     return dialogueInfo:filter(ref.object, ref, 0, dialogue)
    -- end,

    [reqTypes.requirementType.CustomDisposition] = function (req, ref)
        if not req.value or not req then return end

        if req.object and ref.recordId ~= req.object then return false end

        local val = types.NPC.getDisposition(ref, playerRef)

        return operator.check(val, req.value, req.operator)
    end,

    [reqTypes.requirementType.CustomDialogue] = function (req)
        if not req.variable then return end
        local dialogueId = stringLib.convertDialogueName(req.variable)
        if playerQuests.getTopicData(dialogueId) then
            return operator.check(true, true, req.operator)
        end
        return operator.check(false, true, req.operator)
    end,
}

this.dataFuncs = dataFuncs


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
---@field typeTruthTable table<string, boolean>?
---@field threatErrorsAs boolean?

---@param block questDataGenerator.requirementData[]
---@param params questGuider.requirementChecker.checkForBlock.params
---@return boolean?
---@return questDataGenerator.requirementData[]? ignoredRequirements
function this.checkBlock(block, params)
    if not params then params = {} end
    if not params.ignoredTypes then params.ignoredTypes = {} end

    -- don't forget to remove when this requirement type will be supported
    params.ignoredTypes[reqTypes.requirementType.CustomActor] = true

    local ignoredRequirements = {}
    local res = true
    for _, req in pairs(block) do
        if (params.ignoredTypes and params.ignoredTypes[req.type]) or
                (params.allowedTypes and not params.allowedTypes[req.type]) then
            table.insert(ignoredRequirements, req)
            goto continue
        end

        if params.typeTruthTable and params.typeTruthTable[req.type] then
            res = res and params.typeTruthTable[req.type]
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

    return res, ignoredRequirements
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