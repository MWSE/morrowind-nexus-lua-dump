local config = require('scripts.corprus_plague.config')

local M = {}

function M.log(message)
    if config.debugCure and message and message ~= '' then
        print('[corprus_plague] cure: ' .. message)
    end
end

return M
