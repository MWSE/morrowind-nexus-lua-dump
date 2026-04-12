local mS = require('scripts.NCG.config.settings')

return function(str)
    if mS.debugStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

