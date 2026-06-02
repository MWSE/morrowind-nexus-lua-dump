local types = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')
local time = require('openmw_aux.time')
local util = require('openmw.util')

local cure = require('Scripts.drnerev.cure_s')

local msg = core.l10n('drnerev', 'en')
local player = world.players[1]

local function drnrReward(data)
    --print("drnrReward", data.reward)
    local reward = world.createObject(data.reward, data.count)
    if reward then

        
        if data.type == "food" then
            reward:setScale(1.5)
        else
            reward:setScale(3.0)
        end
        reward:teleport(data.cell, data.pos, {
            onGround = true
        })

        if data.message then
            player:sendEvent("drnrShowMessage", {
                message = data.message
            })
        end
    end
end

local function getGratitude(healfyId, cell, pos)
    local path = cure.soundCure[healfyId]
    local message

    if math.random() > 0.25 then
        player:sendEvent("drnrShowMessage", {
            message = msg("drnrGratitude")
        })
    else
        local reward = nil
        local count = 1
        local type = cure.rewards_type[math.random(1, #cure.rewards_type)]

        if type == "gold" then
            reward = "gold_001"
            message = msg("drnrGold")
        elseif type == "key" then
            reward = cure.rewards_key[math.random(1, #cure.rewards_key)]
            message = msg("drnrKey")
        elseif type == "food" then
            reward = cure.reward_food[healfyId]
            message = msg("drnrFood")
        end

        if reward then
            drnrReward({
                type = type,
                reward = reward,
                count = count,
                cell = cell,
                pos = pos,
                message = message
            })
        end
    end

    if path then
        core.sound.playSoundFile3d(path, player)
    end

end

local function drnrReplaceCreature(data)

    local oldCreature = data.ill
    local oldCreatureId = oldCreature.id
    if not oldCreature or not oldCreature:isValid() then
        return
    end

    local callback = time.registerTimerCallback("drnrReplaceCreatureTimer" .. oldCreature.id .. "_" ..
                                                    math.random(1, 100000), function()
        if not oldCreature or not oldCreature:isValid() then
            return
        end

        local pos = oldCreature.position
        local rot = oldCreature.rotation
        local cell = oldCreature.cell
        local newCreatureId = data.healfy

        local success = pcall(function()
            oldCreature:remove()
        end)
        if success then
            local newCreature = world.createObject(newCreatureId, 1)
            newCreature:teleport(cell, pos, rot)

            --print("cured ", newCreatureId)

            time.newSimulationTimer(0.1,
                time.registerTimerCallback("drnrCalmDelay" .. newCreature.id .. "_" .. math.random(1, 100000),
                    function()
                        if newCreature:isValid() then
                            newCreature:sendEvent('drnrCalm')
                        end
                        getGratitude(newCreatureId, player.cell, player.position)
                        core.sendGlobalEvent("drnrCure", {ill = oldCreatureId, cured = newCreatureId, diseases = data.diseases})
                    end))
        end
    end)

    time.newSimulationTimer(1.0, callback)
end

return {
    eventHandlers = {
        drnrReplaceCreature = drnrReplaceCreature
    }
}
