local mS = require('scripts.NCG.config.settings')

return function(str)
    if mS.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

