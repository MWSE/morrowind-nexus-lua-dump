local config = require('scripts.corprus_plague.config')

local M = {}

local LOG_PREFIX = '[corprus_plague] dream: '

function M.log(message)
    if config.debugFirstRestDream and message and message ~= '' then
        print(LOG_PREFIX .. message)
    end
end

function M.logf(fmt, ...)
    if config.debugFirstRestDream and fmt and fmt ~= '' then
        print(LOG_PREFIX .. string.format(fmt, ...))
    end
end

function M.toast(message)
    if not config.debugFirstRestDream or not message or message == '' then
        return
    end
    local I = require('openmw.interfaces')
    if I.UI.showMessage then
        I.UI.showMessage(message)
    end
end

return M
