local types = require("openmw.types")
local world = require("openmw.world")
local core = require("openmw.core")
if core.API_REVISION < 59 then
    return {}
end
local acti = require("openmw.interfaces").Activation
local util = require("openmw.util")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local calendar = require('openmw_aux.calendar')
local settings = require("scripts.VeilOfTheForgotten.settings")

local storedActors = {}
local controlledActors = {}
local dollActors = {}
local spokenToActor
local function getMyBall(actorId)
    if actorId == "tr_m2_darvon golaren" then
        return "zhac_ball_02"
    else
        return "zhac_ball_01"
    end
end
local darvonRecordId = nil
local function captureComplete(actor)
    local name = actor.type.records[actor.recordId].name
    local oldRecord = types.Weapon.records[getMyBall(actor.recordId)]
    local newRecordDraft = types.Weapon.createRecordDraft({
        template = oldRecord,
        name = oldRecord.name ..
            " (" .. name .. ")"
    })
    local newRecord = world.createRecord(newRecordDraft)
    local newItem = world.createObject(newRecord.id)
    if actor.recordId == "tr_m2_darvon golaren" then
        if  types.Player.quests(world.players[1])["ZHAC_MorianaQ_1"].stage < 70 then
            types.Player.quests(world.players[1])["ZHAC_MorianaQ_1"]:addJournalEntry(70)
        end
        darvonRecordId = newRecord.id

    end
    storedActors[newRecord.id] = actor.id
    table.insert(controlledActors, actor.id)
    newItem:moveInto(world.players[1])
    actor:teleport("ZHAC_BallStorage", actor.position)
end
local function releaseAtTarget(data)
    local weapon = data.weapon
    local pos = data.pos

    if storedActors[weapon] then
        for index, value in ipairs(world.getCellByName("ZHAC_BallStorage"):getAll()) do
            if value.id == storedActors[weapon] then
                --  async:newUnsavableSimulationTimer(3, function()

                value:teleport(world.players[1].cell, pos)
                value:sendEvent("onRelease")
                -- end)
                storedActors[weapon] = nil
                world.createObject(getMyBall(value.recordId)):moveInto(world.players[1])
                return
            end
        end
    end
end
local function returnItem(data)
    local item = data.itemId
    local actor = data.actor
    world.createObject(item):moveInto(actor)
end
local function npcActivation(actor, player)
    if dollActors[actor.id] then
        return false
    end
    for index, value in ipairs(controlledActors) do
        if value == actor.id then
            world.mwscript.getGlobalVariables(player)["zhac_speakingto_controlled"] = 1
            async:newUnsavableSimulationTimer(1, function()
                world.mwscript.getGlobalVariables(player)["zhac_speakingto_controlled"] = 0
            end)
            spokenToActor = actor
            return
        end
    end

    if actor.recordId == "zhac_shrinelady" and darvonRecordId then
        local val  = 0
        local item = types.Actor.inventory(player):countOf(darvonRecordId)
        if item > 0 then
            val = 1
        end
        world.mwscript.getGlobalVariables(player)["zhac_votf_carrydar"] = val
    end
end
I.Activation.addHandlerForType(types.NPC, npcActivation)
local function miscActivation(item, player)
    if item.recordId == ("T_Com_CrystalBallStand_01"):lower() then
        local weapon = types.Actor.getEquipment(player)[types.Actor.EQUIPMENT_SLOT.CarriedRight]
        if weapon and storedActors[weapon.recordId] then
            weapon:teleport(item.cell, item.position, item.rotation)
            return false
        end
    elseif storedActors[item.recordId] then
        for index, value in ipairs(world.getCellByName("ZHAC_BallStorage"):getAll()) do
            if value.id == storedActors[item.recordId] then
                --  async:newUnsavableSimulationTimer(3, function()
                types.Actor.spells(value):add("zhac_standability")
                local pz = world.players[1].rotation:getAnglesZYX()
                local rot = util.transform.rotateZ(pz - math.rad(180))
                value:teleport(world.players[1].cell,
                    util.vector3(item.position.x, item.position.y, item.position.z ),rot)
                value:sendEvent("makeIntoDoll",item.recordId)
                dollActors[value.id] = true
                -- end)
                value:setScale(0.1)
                return false
            end
        end
        return false
    end
end
local function putBackInCell(actor)
    actor:setScale(1)
    actor:teleport("ZHAC_BallStorage", actor.position)
    dollActors[actor.id] = nil
end
I.Activation.addHandlerForType(types.Miscellaneous, miscActivation)
I.Activation.addHandlerForType(types.Weapon, miscActivation)
--T_Com_CrystalBallStand_01
return {
    eventHandlers = {
        captureComplete = captureComplete,
        releaseAtTarget = releaseAtTarget,
        returnItem = returnItem,
        putBackInCell = putBackInCell,
        fixScale = function (data)
            data.actor:setScale(data.scale)
            
        end
    },
    engineHandlers = {
        onLoad = function(data)
            storedActors = data.storedActors or {}
            controlledActors = data.controlledActors or {}
            darvonRecordId = data.darvonRecordId
            dollActors = data.dollActors or {}
        end,
        onSave = function()
            return { storedActors = storedActors, controlledActors = controlledActors, darvonRecordId = darvonRecordId, dollActors = dollActors }
        end,
        onItemActive = function(item)
            if item.recordId == "zhac_marker_compshare" and spokenToActor then
                item:remove()
                world.players[1]:sendEvent("openCompShare", spokenToActor)
            elseif item.recordId == "zhac_marker_removedarv" and darvonRecordId then
             types.Actor.inventory(   world.players[1]):find(darvonRecordId):remove()
            elseif item.recordId == "zhac_marker_release" then
                for index, value in ipairs(controlledActors) do
                    if value == spokenToActor.id then
                        table.remove(controlledActors, index)
                    end
                end
            end
        end
    }
}
