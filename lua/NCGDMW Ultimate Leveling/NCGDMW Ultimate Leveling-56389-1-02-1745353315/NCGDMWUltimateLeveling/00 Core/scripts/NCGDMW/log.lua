local mSettings = require('scripts.NCGDMW.settings')

return function(str)
    if mSettings.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

