local mS = require('scripts.MULE.settings')

return function(str)
    if mS.debugStorage:get("debugMode") then
        print("[MULE] " .. str)
    end
end
