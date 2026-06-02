local mSettings = require('scripts.UltimateLeveling.settings')

return function(message)
    if mSettings.globalStorage:get("showDebugMessages") then
        print("DEBUG: " .. message)
    end
end

