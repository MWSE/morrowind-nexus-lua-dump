local storage = require('openmw.storage')
local core = require('openmw.core')
local util = require('openmw.util')
local world = require('openmw.world')
local I = require('openmw.interfaces')
local types = require('openmw.types')

local conjData = storage.globalSection('SaneMagicConjuration')
local conj = require('Scripts.SaneMagic.conjuration_s')
local msg = core.l10n('SaneMagic', 'en')

local player = world.players[1]
local summons = {}
local messageShown = false

local function cleanupOldSummons()
    local currentTime = core.getSimulationTime()
    local timeLimit = currentTime - 43200 -- 12 часов

    for i = #summons, 1, -1 do
        if summons[i].time < timeLimit then
            table.remove(summons, i)
        end
    end
end

local function nearbySummons(playerPos, playerCell)
    local nearbySummons = {}
    for _, summon in ipairs(summons) do
        -- if summon.cell == playerCell then
        if playerCell.isExterior and playerCell.region == summon.cell or not playerCell.isExterior and playerCell ==
            summon.cell then
            local pos = summon.pos
            local distance = (playerPos - pos):length2()
            if distance < 15000 * 1500 then
                table.insert(nearbySummons, summon)
            end
        end
    end
    return nearbySummons
end

local function spawnDaedra(cell, pos)
    -- local nearbySummons = nearbySummons(player.position, playerCell)

    -- local avgX, avgY, avgZ = 0, 0, 0
    -- for _, summon in ipairs(nearbySummons) do
    --     local pos = summon.pos
    --     avgX = avgX + pos.x
    --     avgY = avgY + pos.y
    --     avgZ = avgZ + pos.z
    -- end
    -- avgX = avgX / #nearbySummons
    -- avgY = avgY / #nearbySummons
    -- avgZ = avgZ / #nearbySummons
    -- local newPos = util.vector3(avgX, avgY, avgZ)

    local chosen = conj.daedraCreatures[math.random(#conj.daedraCreatures)]

    local newCreature = world.createObject(chosen, 1)
    newCreature:teleport(cell, pos, {
        onGround = true,
    })
end

local function newSummon(data)
    local mode = conjData:get('smConjurationMode')

    if mode == "Disabled" or mode == "DamageShare" then
        return
    end

    if conj.triggersCreatures[data.summon] or conj.triggersItem[data.summon] then
        local pos = data.pos

        local new_summon = {
            time = core.getSimulationTime(),
            pos = pos,
            cell = data.cell
        }
        table.insert(summons, new_summon)

        local playerCell = player.cell.name
        local playerPos = player.position

        local summonCount = #nearbySummons(playerPos, playerCell)

        if summonCount >= 3 then
            if not messageShown then
                messageShown = true
                player:sendEvent("smShowMessage", {
                    message = msg("smConjurationRift")
                })
            end
        else
            messageShown = false
        end

        -- Спавн даэдры при каждом призыве, если суммарно 3+ призывов за 12 часов
        if summonCount >= 3 then
            local chance = (summonCount - 2) * 10
            chance = math.min(chance, 90)

            if math.random(1, 100) <= chance then
                spawnDaedra(data.ownerCell, data.ownerPos)
            end
        end
    end
end

local function onUpdate(dt)
    if core.isWorldPaused() then
        return
    end
    cleanupOldSummons()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = function()
            local saveSummons = {}
            for _, summon in ipairs(summons) do
                table.insert(saveSummons, {
                    time = summon.time,
                    pos = {
                        x = summon.pos.x,
                        y = summon.pos.y,
                        z = summon.pos.z
                    },
                    cell = summon.cell
                })
            end
            return {
                summons = saveSummons,
                messageShown = messageShown
            }
        end,
        onLoad = function(data)
            summons = {}
            if data and data.summons then
                for _, savedSummon in ipairs(data.summons) do
                    local posVector = util.vector3(savedSummon.pos.x, savedSummon.pos.y, savedSummon.pos.z)
                    table.insert(summons, {
                        time = savedSummon.time,
                        pos = posVector,
                        cell = savedSummon.cell
                    })
                end
            end
            messageShown = data and data.messageShown or false
        end
    },

    eventHandlers = {
        smNewSummonConjuration = newSummon,
        smSetConjurationData = function(data)
            conjData:set(data.key, data.value)
        end
    }
}
