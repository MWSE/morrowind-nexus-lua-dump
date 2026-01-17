local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local crimes = require('openmw.interfaces').Crimes
local storage = require('openmw.storage')
local util = require("openmw.util")

local lctn = require('Scripts.TelvanniHospitality.location')
local msg = core.l10n('TelvanniHospitality', 'en')

local player = world.players[1]
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic


local telvanniCrime = false
local function punishTelvanni(data)
    if world.isWorldPaused() then return end
    local output
    if data.isCast then
        output = crimes.commitCrime(player, {
            --arg = 100,
            type = player.type.OFFENSE_TYPE.Trespassing,
        })
    end
    if not data.isCast and not telvanniCrime then
        output = crimes.commitCrime(player, {
            --arg = 100,
            type = player.type.OFFENSE_TYPE.Trespassing,
        })
        if data.seeYou then
            for _, actor in pairs(data.seeYou) do
                if actor.id ~= "gals arethi" then
                    actor:sendEvent('StartAIPackage', {type='Combat', target=player})
                end
            end
        end
        if output.wasCrimeSeen then telvanniCrime = true end
    end
end
local function resetTelvanniCrime()
    telvanniCrime = false
end

local telvanniWithoutPapersCrime = false
local function punishSadrithMora()
    if world.isWorldPaused() then return end
    if  not telvanniWithoutPapersCrime then
        local output = crimes.commitCrime(player, {
            --arg = 1000,
            type = player.type.OFFENSE_TYPE.Assault,
        })
        if output.wasCrimeSeen then
            telvanniWithoutPapersCrime = true
        end
    end
end
local function resetSadrithMora()
    telvanniWithoutPapersCrime = false
end

local function onActivate(door, actor)
    if door.type ~= types.Door then return end
    --print(door.id)
    if door.id == "0x1050e54" or door.id == "0x10034b6" or door.id == "0x100255e" then 
    --if door.recordId == "ex_t_door_stone_large" or door.recordId == "ex_t_door_02" then
        local inventory = types.Actor.inventory(actor)
        local telvanniRank = types.NPC.getFactionRank(player, "telvanni")
        if not inventory:find("bk_hospitality_papers") and telvanniRank < 2 then
            -- crimes.commitCrime(player, {
            --     arg = 1000,
            --     type = player.type.OFFENSE_TYPE.Assault,
            -- })
        else
            types.Lockable.unlock(door)    
        end
    end
end
local function onObjectActive(door)
    if door.type ~= types.Door then return end
    if door.id == "0x1050e54" or door.id == "0x10034b6" or door.id == "0x100255e" then 
    --if door.recordId == "ex_t_door_stone_large" or door.recordId == "ex_t_door_02" then
        local inventory = types.Actor.inventory(player)
        local telvanniRank = types.NPC.getFactionRank(player, "telvanni")
        if not inventory:find("bk_hospitality_papers") and telvanniRank < 2 then
            if door.recordId == "ex_t_door_stone_large" then
                types.Door.activateDoor(door, false)
            end
            types.Lockable.lock(door, 100)
        end
    else
        if door.recordId == "ex_t_door_stone_large" or door.recordId == "ex_t_door_02" then
            types.Lockable.unlock(door)
        end
    end
end

return {
    engineHandlers = {
        onActivate = onActivate,
        onObjectActive = onObjectActive,
    },

    eventHandlers = {
        punishTelvanni = punishTelvanni,
        resetTelvanniCrime = resetTelvanniCrime,

        punishSadrithMora = punishSadrithMora,
        resetSadrithMora = resetSadrithMora,

        thRemovePapers = function()
            local inventory = types.Actor.inventory(player)   
            local item = inventory:find("bk_hospitality_papers")
            if item then
                item:remove()
            end
        end,
        thTeleportTavern = function()
            player:teleport("sadrith mora, gateway inn", util.vector3(3996.634033203125, 4315.6171875, 518.36151123046875))   
        end        
    }

}
