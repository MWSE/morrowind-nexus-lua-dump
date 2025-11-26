local mS = require('scripts.skill-evolution.config.settings')

return function(str)
    if mS.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end