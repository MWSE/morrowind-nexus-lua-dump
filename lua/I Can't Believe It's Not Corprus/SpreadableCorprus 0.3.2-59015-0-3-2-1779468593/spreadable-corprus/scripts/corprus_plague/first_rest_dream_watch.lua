local config = require('scripts.corprus_plague.config')
local firstRestDream = require('scripts.corprus_plague.first_rest_dream')
local debug = require('scripts.corprus_plague.first_rest_debug')

local M = {}

local function buildTriggerData(player)
    local cell = player.cell
    if not cell or cell.name == '' then
        return nil
    end
    local position = player.position
    return {
        cellName = cell.name,
        position = {
            x = position.x,
            y = position.y,
            z = position.z,
        },
        yaw = player.rotation:getYaw(),
    }
end

function M.resetSnapshots()
end

function M.onGameReady(player)
    if config.debugFirstRestDream and player and player:isValid() then
        player:sendEvent('ShowMessage', {
            message = '[Corprus] First-rest debug on (F9 = test indoors)',
        })
    end
    if config.debugTriggerDreamOnLoad then
        local data = buildTriggerData(player)
        if data then
            debug.log('debugTriggerDreamOnLoad')
            firstRestDream.trigger(data)
        end
    end
end

function M.onPlayerRestCompleted(data)
    debug.log('CorprusPlagueRestCompleted received')
    firstRestDream.trigger(data)
end

return M
