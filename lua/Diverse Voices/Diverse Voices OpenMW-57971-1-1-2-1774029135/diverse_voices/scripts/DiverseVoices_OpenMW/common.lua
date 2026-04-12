local M = {}

M.DEBUG = true

function M.log(fmt, ...)
    if not M.DEBUG then
        return
    end
    print(string.format('[DiverseVoices OpenMW] ' .. fmt, ...))
end

return M
