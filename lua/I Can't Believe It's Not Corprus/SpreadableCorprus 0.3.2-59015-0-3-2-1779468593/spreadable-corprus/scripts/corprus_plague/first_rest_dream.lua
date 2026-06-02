local util = require('openmw.util')
local world = require('openmw.world')
local config = require('scripts.corprus_plague.config')
local storageApi = require('scripts.corprus_plague.storage')
local spawnCreature = require('scripts.corprus_plague.spawn_creature')
local debug = require('scripts.corprus_plague.first_rest_debug')

local M = {}

local DREAM_MESSAGE = table.concat({
    'You wake from a strange nightmare. You recall only one part, but in perfect detail, ',
    'as though it was not a dream at all.\n\n',
    'A tall figure with a golden mask leads you down the gangplank at Seyda Neen introducing you ',
    'to each Imperial officer as though you are a royal guest.\n\n',
    'You are asked many questions, and want to answer graciously. You stand tall and begin ',
    'to speak, but your words become ashes in your mouth, before spilling out into the air, ',
    'sending your hosts running for their lives.\n\n',
    'The tall figure watches approvingly, as the ash cloud swirls and dances at his delight. ',
    'You meet their gaze, your face locked in a rictus grin.',
})

local CREATURE_ID = 'corprus_stalker'
local SPAWN_DISTANCE = 160

local function safeRemoveCreature(creature)
    if creature and creature:isValid() then
        pcall(function()
            creature:remove()
        end)
    end
end

local function toVector3(position)
    if type(position) ~= 'table'
        or type(position.x) ~= 'number'
        or type(position.y) ~= 'number'
        or type(position.z) ~= 'number'
    then
        return nil
    end
    return util.vector3(position.x, position.y, position.z)
end

local function getSpawnPosition(playerPosition, yaw)
    -- OpenMW local +Y is forward; negative Y places the creature behind the player.
    local fromPlayer = util.transform.move(playerPosition) * util.transform.rotateZ(yaw or 0)
    return fromPlayer * util.vector3(0, -SPAWN_DISTANCE, 0)
end

local function getSpawnRotation(yaw)
    -- Face the player when they turn around.
    return util.transform.rotateZ((yaw or 0) + math.pi)
end

local function showDreamMessage()
    local player = world.players[1]
    if player and player:isValid() then
        -- Player script only: interactive OK box (prophecy uses built-in ShowMessage from global).
        player:sendEvent('CorprusPlagueFirstRestDreamMessage', { message = DREAM_MESSAGE })
    end
end

function M.trigger(data)
    if not config.enableStory then
        return
    end
    debug.log('trigger called')

    if storageApi.hasFirstRestDreamTriggered() and not config.debugIgnoreFirstRestDreamSave then
        debug.log('skipped: already triggered on save')
        return
    end

    local cellName = type(data) == 'table' and data.cellName or nil
    local playerPosition = type(data) == 'table' and toVector3(data.position) or nil
    local yaw = type(data) == 'table' and data.yaw or 0

    local player = world.players[1]
    if player and player:isValid() then
        playerPosition = util.vector3(player.position.x, player.position.y, player.position.z)
        yaw = player.rotation:getYaw()
        if type(cellName) ~= 'string' or cellName == '' then
            local cell = player.cell
            cellName = cell and cell.name or cellName
        end
    end

    if type(cellName) ~= 'string' or cellName == '' or not playerPosition then
        debug.log('skipped: invalid data')
        local player = world.players[1]
        if player and player:isValid() then
            player:sendEvent('CorprusPlagueFirstRestDreamFailed')
        end
        return
    end

    local creature
    local ok, err = pcall(function()
        creature = spawnCreature.create(CREATURE_ID, 'Corprus Stalker')
        if not creature or not creature:isValid() then
            creature = world.createObject(CREATURE_ID)
        end
        if not creature or not creature:isValid() then
            error('failed to create corprus stalker')
        end

        local spawnPosition = getSpawnPosition(playerPosition, yaw)
        creature.enabled = true
        creature:teleport(cellName, spawnPosition, { rotation = getSpawnRotation(yaw) })
        if not creature:isValid() then
            error('corprus stalker not in world after teleport')
        end
    end)

    if not ok then
        print('[corprus_plague] first rest dream spawn failed: ' .. tostring(err))
        safeRemoveCreature(creature)
        local player = world.players[1]
        if player and player:isValid() then
            player:sendEvent('CorprusPlagueFirstRestDreamFailed')
        end
        return
    end

    storageApi.markFirstRestDreamTriggered()
    pcall(function()
        local types = require('openmw.types')
        local player = world.players[1]
        if player and player:isValid() then
            local quests = types.Player.quests(player)
            quests[config.carrierJournalId]:addJournalEntry(config.carrierJournalNightmareStage)
            debug.log('journal ' .. config.carrierJournalId .. ' ' .. config.carrierJournalNightmareStage)
        end
    end)
    showDreamMessage()
    debug.log('success')
end

return M
