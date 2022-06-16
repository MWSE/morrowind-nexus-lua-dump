return function (str, ...)
    local config = require 'robocroque.factionalbounties.config'
    if config.debugMode then
        mwse.log('[FactionalBounties] ' .. tostring(str), ...)
    end
end
